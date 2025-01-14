const std = @import("std");
const print = std.debug.print;

const evaluator = @import("./evaluator/evaluator.zig");

const Evaluator = evaluator.Evaluator();

const SMALL_BLIND_OFFSET = 1;
const BIG_BLIND_OFFSET = 2;

const MIN_PLAYERS = 2;

pub const Player = struct {
    name: []const u8,

    stack: f64,
    current_bet: ?f64,

    pub fn get_current_bet(self: Player) f64 {
        return if (self.current_bet) |current_bet| current_bet else 0;
    }

    /// Bet a specific amount _more_.
    /// Note: This method also considers all-ins, when you bet more
    /// than you have in your stack, and returns the adjusted value.
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

const Pot = struct {
    pot_size: f64,
    players_involved: []*Player,

    pub fn increase(self: *Pot, amount: f64) void {
        assert(amount >= 0);

        self.*.pot_size += amount;
    }
};

const Round = enum {
    preflop,
    flop,
    turn,
    river,
    over,
    pub fn get_next(self: Round) Round {
        return switch (self) {
            Round.preflop => Round.flop,
            Round.flop => Round.turn,
            Round.turn => Round.river,
            Round.river => unreachable,
            Round.over => unreachable,
        };
    }
};
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

    // A list of players that have acted (but not folderd).
    // This is used in case a player raises, which causes other
    // players to have to act again.
    current_round_acted: std.ArrayList(*Player),

    current_action: f64,

    round: Round,
    pots: std.ArrayList(*Pot),

    /// Factory method with a brand new game state.
    pub fn create(allocator: std.mem.Allocator, blind: f64, players: []*Player) Game {
        var pots = std.ArrayList(*Pot).init(allocator);
        const initial_pot = allocator.create(Pot) catch unreachable;

        initial_pot.*.pot_size = 0;
        initial_pot.*.players_involved = players;

        pots.append(initial_pot) catch unreachable;

        return Game{
            .allocator = allocator,
            .blind = blind,
            .players = players,
            .current_round_players = players,
            .current_round_left_to_act = std.ArrayList(*Player).init(allocator),
            .current_round_acted = std.ArrayList(*Player).init(allocator),
            .round = Round.preflop,
            .pots = pots,
            .current_action = 0,
        };
    }

    /// Start by adding the blinds to the pot and correctly setting up our work-queue
    pub fn start(game: *Game) void {
        assert(game.current_round_players.len >= MIN_PLAYERS);

        game.*.round = Round.preflop;

        const player_num = game.current_round_players.len;

        game.*.pots.getLast().*.increase(game.current_round_players[1].*.bet(game.blind / 2));

        // In a heads-up game, we need to wrap around because there are only two players.
        game.*.pots.getLast().*.increase(game.current_round_players[2 % player_num].*.bet(game.blind));

        for (0..player_num) |i| {
            game.*.current_round_left_to_act.append(game.current_round_players[(i + 3) % player_num]) catch unreachable;
        }

        game.*.current_action = game.blind;
    }

    fn print_players_to_act(game: *Game) void {
        for (game.current_round_left_to_act.items) |player| {
            std.debug.print("Player: {s}\n", .{player.name});
        }
        std.debug.print("Pot size: {}\n", .{game.pots.getLast().pot_size});
    }

    /// Checks who the winner is and adds the pot to his stack.
    /// TODO: multi-pots should also be handled.
    fn end_round(game: *Game) void {
        const acted_length = game.current_round_acted.items.len;
        assert(acted_length > 0);

        if (acted_length == 1) {
            // All folded except one.
            const winning_player = game.current_round_acted.items[0];

            winning_player.*.stack += game.pots.getLast().pot_size;
        } else {
            // Showdown.
            unreachable;
        }
    }

    fn check_end_round(game: *Game) void {
        // game.print_players_to_act();
        if (game.*.current_round_left_to_act.items.len > 0) {
            return;
        }

        const acted_length = game.current_round_acted.items.len;
        assert(acted_length > 0);

        if (acted_length == 1 or game.round == Round.river) {
            game.*.end_round();
            return;
        }

        var remaining_players = std.ArrayList(*Player).init(game.allocator);
        defer remaining_players.clearAndFree();

        for (game.current_round_acted.items) |p| {
            assert(p.stack >= 0);

            if (p.stack == 0) {
                continue;
            }

            remaining_players.append(p) catch unreachable;
        }

        game.*.round = game.round.get_next();

        // Because preflop the UTG player acts first
        // we need to shift the array a few places so the SB acts first in
        // the flop.
        if (game.round == Round.preflop) {
            // TODO: I'm pretty sure we can do this without another alloc.
            const copied_left_to_act = game.allocator.alloc(*Player, remaining_players.items.len) catch unreachable;
            defer game.allocator.free(copied_left_to_act);

            std.mem.copyForwards(*Player, copied_left_to_act, remaining_players.items);

            for (0..acted_length) |i| {
                game.current_round_left_to_act.items[(2 + i) % copied_left_to_act.len] = copied_left_to_act[i];
            }
        }

        for (game.current_round_acted.items) |player| {
            player.*.current_bet = null;
        }

        game.*.current_round_left_to_act.appendSlice(remaining_players.items) catch unreachable;
        game.*.current_round_acted.clearRetainingCapacity();
    }

    pub fn fold(game: *Game) void {
        assert(game.current_round_left_to_act.items.len > 0);

        _ = game.*.current_round_left_to_act.orderedRemove(0);
        game.check_end_round();
    }

    pub fn check(game: *Game) void {
        assert(game.current_round_left_to_act.items.len > 0);

        game.*.pots.getLast().*.increase(game.*.current_round_left_to_act.items[0].*.bet(0));

        const player = game.*.current_round_left_to_act.orderedRemove(0);
        game.*.current_round_acted.append(player) catch unreachable;

        game.check_end_round();
    }

    fn check_side_pot(game: *Game) void {
        const last_player = game.current_round_acted.getLast();

        if (last_player.stack > 0) {
            return;
        }

        // They must have jammed their last turn, and therefore
        // we now have a sidepot.

        const pot_players_involved = game.pots.getLast().players_involved;

        var side_pot_players = game.allocator.alloc(*Player, pot_players_involved.len - 1) catch unreachable;

        var index: usize = 0;
        for (pot_players_involved, 0..) |player, old_pot_index| {
            if (player == last_player) {
                continue;
            }

            side_pot_players[index] = pot_players_involved[old_pot_index];
            index += 1;
        }

        const side_pot = game.allocator.create(Pot) catch unreachable;

        side_pot.*.pot_size = 0;
        side_pot.*.players_involved = side_pot_players;

        game.*.pots.append(side_pot) catch unreachable;
    }

    /// TODO: when a player is put into an all-in situation.
    /// The correct action is so call (not raise).
    pub fn call(game: *Game) void {
        assert(game.current_round_left_to_act.items.len > 0);

        const player_to_act = game.*.current_round_left_to_act.items[0];

        const left_to_bet = game.current_action - player_to_act.get_current_bet();
        assert(left_to_bet > 0);

        game.*.pots.getLast().*.increase(player_to_act.*.bet(left_to_bet));

        const player = game.*.current_round_left_to_act.orderedRemove(0);
        game.*.current_round_acted.append(player) catch unreachable;

        game.check_side_pot();
        game.check_end_round();
    }

    pub fn raise(game: *Game, amount: f64) void {
        assert(game.current_round_left_to_act.items.len > 0);

        const player_to_act = game.*.current_round_left_to_act.orderedRemove(0);

        const left_to_bet = amount - player_to_act.get_current_bet();
        assert(left_to_bet > 0);

        game.*.pots.getLast().*.increase(player_to_act.*.bet(left_to_bet));

        game.*.current_action = amount;

        // Raising causes other players to need to act again.
        for (game.current_round_acted.items) |p| {
            if (p == player_to_act or p.stack == 0) {
                continue;
            }

            game.*.current_round_left_to_act.append(p) catch unreachable;
        }

        game.*.current_round_acted.clearRetainingCapacity();
        game.*.current_round_acted.append(player_to_act) catch unreachable;

        game.check_side_pot();
        game.check_end_round();
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

    try expectEqual(game.pots.getLast().pot_size, game.blind * 1.5);
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

test "Side pots" {
    const allocator = std.heap.page_allocator;
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 4;

    var p1 = Player{ .name = "P1", .stack = 10, .current_bet = null };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .current_bet = null };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .current_bet = null };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game.create(allocator, BIG_BLIND, &players);

    game.start();

    try expectEqual(game.pots.getLast().pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);

    game.raise(10); // P3 jams.

    game.raise(20); // P1 re-raises.
    game.call(); // P2 calls.

    try expectEqual(game.pots.items.len, 2);
    try expectEqual(game.round, Round.flop);

    game.check(); // P1 checks.
    game.check(); // P2 checks.

    // We shouldn't need P3 to act, as they have jammed.

    try expectEqual(game.round, Round.turn);
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

    try expectEqual(game.pots.getLast().pot_size, game.blind * 1.5);
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

    try expectEqual(game.pots.getLast().pot_size, game.blind / 2 + 2);
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

    try expectEqual(game.pots.getLast().pot_size, SMALL_BLIND + 8 * BIG_BLIND);
    try expectEqual(game.round, Round.flop);

    try expectEqual(p1.stack, PLAYER_STACK - 4 * BIG_BLIND);
    try expectEqual(p2.stack, PLAYER_STACK - 0.5 * BIG_BLIND);
    try expectEqual(p3.stack, PLAYER_STACK - 4 * BIG_BLIND);
}

test "Raising battle" {
    const allocator = std.heap.page_allocator;
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 1;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .current_bet = null };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .current_bet = null };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .current_bet = null };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game.create(allocator, BIG_BLIND, &players);

    game.start();

    game.fold(); // P1
    game.raise(BIG_BLIND * 2); // P2
    game.raise(BIG_BLIND * 4); // P3
    game.raise(BIG_BLIND * 8); // P2
    game.raise(BIG_BLIND * 16); // P3
    game.raise(BIG_BLIND * 32); // P2
    game.call(); // P3

    try expectEqual(game.pots.getLast().pot_size, 32 * 2 * BIG_BLIND);
    try expectEqual(game.round, Round.flop);

    try expectEqual(p1.stack, PLAYER_STACK);
    try expectEqual(p2.stack, PLAYER_STACK - 32 * BIG_BLIND);
    try expectEqual(p3.stack, PLAYER_STACK - 32 * BIG_BLIND);
}

test "Folding on the river" {
    const allocator = std.heap.page_allocator;
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 1;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .current_bet = null };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .current_bet = null };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .current_bet = null };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game.create(allocator, BIG_BLIND, &players);

    game.start();

    game.fold(); // P1
    game.raise(BIG_BLIND * 2); // P2
    game.raise(BIG_BLIND * 4); // P3
    game.call(); // P2

    try expectEqual(game.pots.items.len, 1);
    try expectEqual(game.round, Round.flop);
    try expectEqual(game.pots.getLast().pot_size, 4 * 2 * BIG_BLIND);

    game.raise(BIG_BLIND * 16); // P2
    game.raise(BIG_BLIND * 32); // P3
    game.call(); // P2

    try expectEqual(game.pots.items.len, 1);
    try expectEqual(game.round, Round.turn);
    try expectEqual(game.pots.getLast().pot_size, 4 * 2 * BIG_BLIND + 32 * 2 * BIG_BLIND);

    game.check(); // P2
    game.check(); // P3

    try expectEqual(game.pots.items.len, 1);
    try expectEqual(game.round, Round.river);
    try expectEqual(game.pots.getLast().pot_size, 4 * 2 * BIG_BLIND + 32 * 2 * BIG_BLIND);

    game.raise(BIG_BLIND * 20); // P2
    game.fold(); // P3

    try expectEqual(p1.stack, PLAYER_STACK);
    try expectEqual(p2.stack, PLAYER_STACK + (4 + 32) * BIG_BLIND);
    try expectEqual(p3.stack, PLAYER_STACK - (4 + 32) * BIG_BLIND);
}
