const std = @import("std");
const TexasHoldem = @import("./texas-hold-em.zig");
const Game = @import("./game.zig");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

const MessageToCard = @import("./message-to-card.zig");
const get_card = MessageToCard.get_card;

const Context = struct {
    userName: []const u8,
    channel: []const u8,
    // we need to hold on to them and just re-use them for every incoming
    // connection
    subscribeArgs: WebsocketHandler.SubscribeArgs,
    settings: WebsocketHandler.WebSocketSettings,

    lock: *std.Thread.Mutex,
    condition: *std.Thread.Condition,
};

const ContextList = std.ArrayList(*Context);

const ContextManager = struct {
    allocator: std.mem.Allocator,
    channel: []const u8,
    usernamePrefix: []const u8,
    contexts: ContextList = undefined,

    lock: std.Thread.Mutex = .{},

    lastMessage: ?[]const u8,
    gameLock: std.Thread.Mutex = .{},
    condition: std.Thread.Condition,

    const Self = @This();

    pub fn init(
        allocator: std.mem.Allocator,
        channelName: []const u8,
        usernamePrefix: []const u8,
    ) Self {
        return .{
            .allocator = allocator,
            .channel = channelName,
            .usernamePrefix = usernamePrefix,
            .contexts = ContextList.init(allocator),
            .condition = std.Thread.Condition{},
            .lastMessage = null,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.contexts.items) |ctx| {
            self.allocator.free(ctx.userName);
        }
        self.contexts.deinit();
    }

    pub fn newContext(self: *Self) !*Context {
        self.lock.lock();
        defer self.lock.unlock();

        const ctx = try self.allocator.create(Context);
        const userName = try std.fmt.allocPrint(
            self.allocator,
            "{s}{d}",
            .{ self.usernamePrefix, self.contexts.items.len },
        );
        ctx.* = .{
            .userName = userName,
            .channel = self.channel,
            // used in subscribe()
            .subscribeArgs = .{
                .channel = self.channel,
                .force_text = true,
                .context = ctx,
            },
            // used in upgrade()
            .settings = .{
                .on_open = on_open_websocket,
                .on_close = on_close_websocket,
                .on_message = handle_websocket_message,
                .context = ctx,
            },
            .lock = &self.gameLock,
            .condition = &self.condition,
        };
        try self.contexts.append(ctx);
        return ctx;
    }
};

//
// Websocket Callbacks
//
fn on_open_websocket(context: ?*Context, handle: WebSockets.WsHandle) void {
    if (context) |ctx| {
        _ = WebsocketHandler.subscribe(handle, &ctx.subscribeArgs) catch |err| {
            std.log.err("Error opening websocket: {any}", .{err});
            return;
        };

        std.log.info("new websocket opened", .{});
    }
}

fn on_close_websocket(context: ?*Context, uuid: isize) void {
    _ = uuid;
    if (context) |_| {
        std.log.info("websocket closed", .{});
    }
}

fn handle_websocket_message(
    context: ?*Context,
    handle: WebSockets.WsHandle,
    message: []const u8,
    is_text: bool,
) void {
    _ = is_text;
    _ = handle;
    if (context == null) {
        unreachable;
    }

    std.log.info("{s}", .{message});

    GlobalContextManager.lastMessage = message;
    context.?.condition.signal();
}

fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("received illegal protocol: {s}", .{target_protocol});
        r.setStatus(.bad_request);
        r.sendBody("400 - BAD REQUEST") catch unreachable;
        return;
    }

    var context = GlobalContextManager.newContext() catch |err| {
        std.log.err("Error creating context: {any}", .{err});
        return;
    };

    WebsocketHandler.upgrade(r.h, &context.settings) catch |err| {
        std.log.err("Error in websocketUpgrade(): {any}", .{err});
        return;
    };
    std.log.info("connection upgrade OK", .{});
}

fn on_request(r: zap.Request) void {
    r.setHeader("Server", "zap.example") catch unreachable;
    r.sendBody("bruh") catch return;
}

// global variables, yeah!
var GlobalContextManager: ContextManager = undefined;
const WebsocketHandler = WebSockets.Handler(Context);

fn game_thread() void {
    const allocator = std.heap.page_allocator;

    var p1 = Game.Player{
        .name = "Player 1",
        .stack = 100,
        .current_bet = null,
    };
    var p2 = Game.Player{
        .name = "Player 2",
        .stack = 100,
        .current_bet = null,
    };
    var p3 = Game.Player{
        .name = "Player 3",
        .stack = 100,
        .current_bet = null,
    };
    var p4 = Game.Player{
        .name = "Player 4",
        .stack = 100,
        .current_bet = null,
    };

    var players = [_]*Game.Player{ &p1, &p2, &p3, &p4 };

    var holdem = TexasHoldem.TexasHoldEm.create(allocator, 1, &players);

    GlobalContextManager.gameLock.lock();

    while (true) {
        inline for (0..4) |index| {
            GlobalContextManager.condition.wait(&GlobalContextManager.gameLock);

            var card = GlobalContextManager.lastMessage.?;
            holdem.players[index].c1 = get_card(card);
            GlobalContextManager.condition.wait(&GlobalContextManager.gameLock);

            card = GlobalContextManager.lastMessage.?;
            holdem.players[index].c2 = get_card(card);
        }

        holdem.print_player_cards();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();

    GlobalContextManager = ContextManager.init(allocator, "chatroom", "user-");
    defer GlobalContextManager.deinit();

    var listener = zap.HttpListener.init(
        .{
            .port = 3010,
            .on_upgrade = on_upgrade,
            .on_request = on_request,
            .max_clients = 1000,
            .max_body_size = 1 * 1024,
            .log = true,
        },
    );

    const thread = try std.Thread.spawn(.{}, game_thread, .{});
    _ = thread;

    try listener.listen();

    std.log.info("", .{});
    std.log.info("Connect with browser to http://localhost:3010.", .{});
    std.log.info("Connect to websocket on ws://localhost:3010.", .{});
    std.log.info("Terminate with CTRL+C", .{});

    zap.start(.{
        .threads = 1,
        .workers = 1,
    });
}
