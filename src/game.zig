const std = @import("std");
const print = std.debug.print;

const evaluator = @import("./evaluator/evaluator.zig");

const Evaluator = evaluator.Evaluator();

const SMALL_BLIND_OFFSET = 1;
const BIG_BLIND_OFFSET = 2;

const MIN_PLAYERS = 2;

const Player = struct {
    name: []const u8,

    stack: f64,
    current_bet: ?f64,

    pub fn get_current_bet(self: Player) f64 {
        return if (self.current_bet) |current_bet| current_bet else 0;
    }

    // TODO: consider betting all-ins.
    pub fn bet(self: *Player, amount: f64) f64 {
        if (self.*.current_bet == null) {
            self.*.current_bet = 0;
        }

        if (self.stack < amount) {
            assert(self.stack > 0);

            self.*.current_bet = self.stack;
            self.*.stack = 0;

            return self.current_bet.?;
        } else {
            self.*.current_bet.? += amount;
            self.*.stack -= amount;

            return amount;
        }
    }
};

const Round = enum { preflop, flop, turn, river, over };
const Move = enum { fold, check, call, raise };

fn assert(condition: bool) void {
    if (!condition) {
        unreachable;
    }
}

pub const Game = struct {
    allocator: std.mem.Allocator,

    blind: f64,

    // Dealer starts at 0th index.
    // The array is then shifted such that the next player becomes dealer.
    players: []*Player,

    // The players still participating in this round.
    current_round_players: []*Player,

    current_round_left_to_act: std.ArrayList(*Player),
    current_round_acted: std.ArrayList(*Player),

    current_action: f64,

    round: Round,
    pot_size: f64,

    /// Factory method with a brand new game state.
    pub fn create(allocator: std.mem.Allocator, blind: f64, players: []*Player) Game {
        return Game{
            .allocator = allocator,
            .blind = blind,
            .players = players,
            .current_round_players = players,
            .current_round_left_to_act = std.ArrayList(*Player).init(allocator),
            .current_round_acted = std.ArrayList(*Player).init(allocator),
            .round = Round.preflop,
            .pot_size = 0,
            .current_action = 0,
        };
    }

    /// Start by adding the blinds to the pot and correctly setting up our work-queue
    pub fn start(game: *Game) void {
        assert(game.round == Round.preflop);
        assert(game.current_round_players.len >= MIN_PLAYERS);

        const player_num = game.current_round_players.len;

        game.*.pot_size += game.current_round_players[1].*.bet(game.blind / 2);

        // In a heads-up game, we need to wrap around because there are only two players.
        game.*.pot_size += game.current_round_players[2 % player_num].*.bet(game.blind);

        for (0..player_num) |i| {
            game.*.current_round_left_to_act.append(game.current_round_players[(i + 3) % player_num]) catch unreachable;
        }

        game.*.current_action = game.blind;
    }

    pub fn check_end_round(game: *Game) void {
        if (game.*.current_round_left_to_act.items.len > 0) {
            return;
        }

        switch (game.*.round) {
            Round.preflop => {
                game.*.round = Round.flop;
            },
        }
    }

    pub fn fold(game: *Game) void {
        assert(game.current_round_left_to_act.items.len > 0);

        _ = game.*.current_round_left_to_act.orderedRemove(0);
    }

    pub fn check(game: *Game) void {
        assert(game.current_round_left_to_act.items.len > 0);

        game.*.pot_size += game.*.current_round_left_to_act.items[0].*.bet(0);

        const player = game.*.current_round_left_to_act.orderedRemove(0);
        game.*.current_round_acted.append(player) catch unreachable;
    }

    pub fn call(game: *Game) void {
        assert(game.current_round_left_to_act.items.len > 0);

        const player_to_act = game.*.current_round_left_to_act.items[0];

        const left_to_bet = game.current_action - player_to_act.get_current_bet();
        assert(left_to_bet > 0);

        game.*.pot_size += player_to_act.*.bet(left_to_bet);

        const player = game.*.current_round_left_to_act.orderedRemove(0);
        game.*.current_round_acted.append(player) catch unreachable;
    }

    pub fn raise(game: *Game, amount: f64) void {
        assert(game.current_round_left_to_act.items.len > 0);

        const player_to_act = game.*.current_round_left_to_act.items[0];

        const left_to_bet = amount - player_to_act.get_current_bet();
        assert(left_to_bet > 0);

        game.*.pot_size += player_to_act.*.bet(left_to_bet);

        const player = game.*.current_round_left_to_act.orderedRemove(0);

        // Raising causes other players to need to act again.
        game.*.current_round_left_to_act.appendSlice(game.current_round_acted.items) catch unreachable;

        game.*.current_round_acted.clearRetainingCapacity();
        game.*.current_round_acted.append(player) catch unreachable;

        game.*.current_action = amount;
    }
};

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Setting up the game with correct blind sizes and left to act players" {
    const allocator = std.heap.page_allocator;
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 4;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .current_bet = null };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .current_bet = null };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .current_bet = null };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game.create(allocator, BIG_BLIND, &players);

    game.start();

    try expectEqual(game.pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);

    // The 0th index is the dealer.
    // Therefore:
    // P2 = Small blind
    // P3 = Big blind
    // P1 = Next to act (but also dealer)
    try expectEqual(game.current_round_left_to_act.items.len, 3);
    try expect(std.mem.eql(u8, game.current_round_left_to_act.items[0].name, "P1"));
    try expect(std.mem.eql(u8, game.current_round_left_to_act.items[1].name, "P2"));
    try expect(std.mem.eql(u8, game.current_round_left_to_act.items[2].name, "P3"));

    try expectEqual(game.current_action, BIG_BLIND);
}

test "Setting up the game in a heads-up format" {
    const allocator = std.heap.page_allocator;
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 4;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .current_bet = null };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .current_bet = null };

    var players = [_]*Player{ &p1, &p2 };

    var game = Game.create(allocator, BIG_BLIND, &players);

    game.start();

    try expectEqual(game.pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    // Wraps around to player 0
    try expectEqual(game.players[0].stack, PLAYER_STACK - BIG_BLIND);

    try expectEqual(game.current_round_left_to_act.items.len, 2);
    try expect(std.mem.eql(u8, game.current_round_left_to_act.items[0].name, "P2"));
    try expect(std.mem.eql(u8, game.current_round_left_to_act.items[1].name, "P1"));

    try expectEqual(game.current_action, BIG_BLIND);
}

test "Setup when a player doesnt have enough to cover the blinds" {
    const allocator = std.heap.page_allocator;
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 4;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .current_bet = null };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .current_bet = null };
    var p3 = Player{ .name = "P3", .stack = 2, .current_bet = null };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game.create(allocator, BIG_BLIND, &players);

    game.start();

    try expectEqual(game.pot_size, game.blind / 2 + 2);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, 0);

    try expectEqual(game.current_action, BIG_BLIND);
}

test "Reaches flop when action has been settled" {
    const allocator = std.heap.page_allocator;
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 1;
    const SMALL_BLIND = BIG_BLIND / 2;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .current_bet = null };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .current_bet = null };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .current_bet = null };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game.create(allocator, BIG_BLIND, &players);

    game.start();

    game.raise(BIG_BLIND * 2); // P1
    game.fold(); // P2
    game.raise(BIG_BLIND * 4); // P3
    game.call(); // P1 (putting 2BB more in)

    try expectEqual(game.current_round_left_to_act.items.len, 0);
    try expectEqual(game.pot_size, SMALL_BLIND + 8 * BIG_BLIND);

    try expectEqual(p1.stack, PLAYER_STACK - 4 * BIG_BLIND);
    try expectEqual(p2.stack, PLAYER_STACK - 0.5 * BIG_BLIND);
    try expectEqual(p3.stack, PLAYER_STACK - 4 * BIG_BLIND);
}
