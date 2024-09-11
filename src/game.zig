const std = @import("std");
const print = std.debug.print;

const evaluator = @import("./evaluator/evaluator.zig");

const Evaluator = evaluator.Evaluator();

const SMALL_BLIND_OFFSET = 1;
const BIG_BLIND_OFFSET = 2;

const Player = struct {
    name: []const u8,

    stack: f64,

    current_bet: f64,
    is_out: bool,
    has_acted: bool,

    pub fn bet(self: *Player, amount: f64) void {
        self.*.current_bet += amount;
        self.*.stack -= amount;
        self.*.has_acted = true;
    }
};

const Round = enum { preflop, flop, turn, river, over };
const Move = enum { fold, check, call, raise };

pub const Game = struct {
    blind: f64,

    players: []*Player,

    players_acted: usize,
    dealer_index: usize,

    pot_size: f64,
    highest_bet: f64,

    round: Round,
    current_player_index: usize,

    fn get_next_index(self: *Game) usize {
        self.*.players_acted += 1;

        if (self.players_acted == self.players.len) {
            self.*.players_acted = 0;
        }

        while (self.players[self.*.players_acted].is_out) {
            self.*.players_acted += 1;
        }

        return self.*.players_acted;
    }

    fn get_next_player(self: *Game) *Player {
        return self.players[self.get_next_index()];
    }

    fn check_round_over(self: *Game) void {
        var players_in: usize = 0;
        var player_in_index: usize = 0;

        //
        // Check that we still have players in the game.
        // And if not, start a new round.
        //

        for (self.players, 0..) |player, index| {
            if (!player.is_out) {
                players_in += 1;
                player_in_index = index;
            }
        }

        // Everyone folded.
        if (players_in == 1) {
            self.setup_round(Round.over);
            print("All players folded\n", .{});
            return;
        }

        var players_acted: usize = 0;
        for (self.players) |player| {
            if (player.has_acted) {
                players_acted += 1;
            }
        }

        // All players must act at least once.
        if (players_acted < self.players.len) {
            print("not enough players acted\n", .{});
            return;
        }

        // If all players have acted.
        // 1. If the bet sizes are all the same, we move on.
        const first_player = top: {
            for (self.players) |player| {
                if (player.is_out) {
                    continue;
                }

                break :top player;
            }

            unreachable;
        };

        for (self.players[1..]) |player| {
            if (player.is_out) {
                continue;
            }

            if (player.current_bet != first_player.current_bet) {
                print("not matched bets\n", .{});
                return;
            }
        }

        switch (self.round) {
            Round.preflop => self.setup_round(Round.flop),
            Round.flop => self.setup_round(Round.turn),
            Round.turn => self.setup_round(Round.river),
            Round.river => self.setup_round(Round.over),
            else => unreachable,
        }
    }

    pub fn fold(self: *Game) void {
        const player = self.get_next_player();
        print("{s} folded\n", .{player.name});

        player.*.is_out = true;
        player.*.has_acted = true;

        print("{s} {}\n", .{ player.name, player.is_out });

        self.check_round_over();
    }

    pub fn check(self: *Game) void {
        const player = self.get_next_player();
        print("{s} checked \n", .{player.name});

        if (player.current_bet != self.highest_bet) {
            unreachable;
        }

        player.*.has_acted = true;

        self.check_round_over();
    }

    pub fn call(self: *Game) void {
        self.raise(self.highest_bet);
    }

    pub fn raise(self: *Game, amount: f64) void {
        const player = self.get_next_player();

        const difference: f64 = amount - player.current_bet;
        if (amount != self.highest_bet) {
            print("{s} raised to {}\n", .{ player.name, amount });
        } else {
            print("{s} called \n", .{player.name});
        }

        if (difference < 0.0) {
            unreachable;
        }

        player.bet(difference);

        print("{s} stack: {}\n", .{ player.name, player.stack });

        self.*.highest_bet = amount;
        self.*.pot_size += difference;

        self.check_round_over();
    }

    pub fn setup_round(self: *Game, round: Round) void {
        for (self.players) |player| {
            player.*.has_acted = false;
            player.*.current_bet = 0.0;
        }

        self.*.round = round;
        self.*.highest_bet = 0;

        switch (round) {
            Round.preflop => {
                print("New round!\n", .{});
                for (self.players) |player| {
                    player.*.is_out = false;
                }

                const small_blind: f64 = self.blind * 0.5;

                self.*.pot_size += self.blind + small_blind;

                var small_blind_player = self.get_next_player();
                var big_blind_player = self.get_next_player();

                small_blind_player.bet(small_blind);
                big_blind_player.bet(self.blind);

                self.*.highest_bet = self.blind;
            },
            Round.over => {
                print("Round is over!\n", .{});
                // actually figure out who wins the rounds.
                var players_in: usize = 0;
                var player_in_index: usize = 0;
                for (self.players, 0..) |player, index| {
                    if (!player.is_out) {
                        players_in += 1;
                        player_in_index = index;
                    }
                }

                if (players_in == 1) {
                    print("Winner is: {s}\n", .{self.players[player_in_index].name});
                    print("Pot size: {} | Players stack: {}\n", .{ self.pot_size, self.players[player_in_index].stack });
                    self.players[player_in_index].*.stack += self.pot_size;
                } else {
                    @panic("showdown not implemented yet.");
                }
            },
            else => {
                print("---- {} ----\n", .{round});
                print("Pot size: {}\n", .{self.pot_size});
                print("-------------------------\n", .{});
            },
        }
    }
};

const expectEqual = std.testing.expectEqual;

test "Preflop - Fold, Call, Check" {
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 4;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game{ .blind = BIG_BLIND, .players = &players, .round = Round.preflop, .pot_size = 0, .dealer_index = 0, .players_acted = 0, .current_player_index = 0, .highest_bet = 0 };

    game.setup_round(Round.preflop);

    try expectEqual(game.pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);
    try expectEqual(game.players_acted, 2);

    game.fold();
    game.call();
    game.check();

    try expectEqual(game.pot_size, BIG_BLIND * 2);
    try expectEqual(game.round, Round.flop);
    try expectEqual(game.players[0].stack, PLAYER_STACK);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);
}

test "Preflop - Fold, Raise, Raise, Call" {
    const PLAYER_STACK: f64 = 100.0;
    const BIG_BLIND: f64 = 4.0;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game{ .blind = BIG_BLIND, .players = &players, .round = Round.preflop, .pot_size = 0, .dealer_index = 0, .players_acted = 0, .current_player_index = 0, .highest_bet = 0 };

    game.setup_round(Round.preflop);

    try expectEqual(game.pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);
    try expectEqual(game.players_acted, 2);

    game.fold();
    game.raise(10.0);
    game.raise(20.0);
    game.call();

    try expectEqual(game.pot_size, 40);
    try expectEqual(game.round, Round.flop);
    try expectEqual(game.players[0].stack, PLAYER_STACK);
    try expectEqual(game.players[1].stack, PLAYER_STACK - 20);
    try expectEqual(game.players[2].stack, PLAYER_STACK - 20);
}

test "Preflop - Fold, Raise, Raise, Fold" {
    const PLAYER_STACK: f64 = 100.0;
    const BIG_BLIND: f64 = 4.0;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game{ .blind = BIG_BLIND, .players = &players, .round = Round.preflop, .pot_size = 0, .dealer_index = 0, .players_acted = 0, .current_player_index = 0, .highest_bet = 0 };

    game.setup_round(Round.preflop);

    try expectEqual(game.pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);
    try expectEqual(game.players_acted, 2);

    game.fold();
    game.raise(10.0);
    game.raise(20.0);

    try expectEqual(game.pot_size, 30);

    game.fold();

    try expectEqual(game.round, Round.over);
    try expectEqual(game.players[0].stack, PLAYER_STACK);
    try expectEqual(game.players[1].stack, PLAYER_STACK - 10.0);
    try expectEqual(game.players[2].stack, PLAYER_STACK + 10.0);
}

test "Folding on the river" {
    const PLAYER_STACK: f64 = 100.0;
    const BIG_BLIND: f64 = 4.0;

    var p1 = Player{ .name = "P1", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p2 = Player{ .name = "P2", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };
    var p3 = Player{ .name = "P3", .stack = PLAYER_STACK, .is_out = false, .has_acted = false, .current_bet = 0 };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game{ .blind = BIG_BLIND, .players = &players, .round = Round.preflop, .pot_size = 0, .dealer_index = 0, .players_acted = 0, .current_player_index = 0, .highest_bet = 0 };

    game.setup_round(Round.preflop);

    try expectEqual(game.pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);
    try expectEqual(game.players_acted, 2);

    game.raise(10);
    game.call();
    game.call();

    try expectEqual(game.pot_size, 30);
    try expectEqual(game.round, Round.flop);

    game.check();
    game.check();
    game.check();

    try expectEqual(game.pot_size, 30);
    try expectEqual(game.round, Round.turn);

    game.raise(20);
    game.fold();
    game.raise(40);
    game.call();

    try expectEqual(game.pot_size, 110);
    try expectEqual(game.round, Round.river);

    game.raise(40);
    game.fold();

    try expectEqual(game.round, Round.over);
    try expectEqual(game.players[0].stack, PLAYER_STACK - 50);
    try expectEqual(game.players[1].stack, PLAYER_STACK - 10);
    try expectEqual(game.players[2].stack, PLAYER_STACK + 60);
}
