const std = @import("std");
const print = std.debug.print;

const evaluator = @import("./evaluator/evaluator.zig");

const Evaluator = evaluator.Evaluator();

const Player = struct {
    stack: f64,

    current_bet: f64,
    is_out: bool,

    acted: bool,

    pub fn act(self: *Player) void {
        self.acted = true;
    }

    pub fn bet(self: *Player, amount: f64) void {
        self.*.current_bet += amount;
        self.*.stack -= amount;
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
        var previous_bet: f64 = 0.0;
        var is_set = false;

        var players_in: u8 = 0;
        var player_in_index: usize = 0;

        for (self.players, 0..) |player, i| {
            if (!player.acted) {
                return;
            }

            if (!player.is_out) {
                players_in += 1;
                player_in_index = i;
            }

            if (!is_set and !player.is_out) {
                previous_bet = player.current_bet;
                is_set = true;
                continue;
            }

            if (previous_bet != player.current_bet and players_in > 1) {
                return;
            }
        }

        // Everyone folded.
        if (players_in == 1) {
            self.players[player_in_index].*.stack += self.pot_size;

            self.setup_round(Round.over);
            return;
        }

        switch (self.round) {
            Round.preflop => self.*.round = Round.flop,
            Round.flop => self.*.round = Round.turn,
            Round.turn => self.*.round = Round.river,
            else => unreachable,
        }
    }

    pub fn fold(self: *Game) void {
        var player = self.get_next_player();
        player.*.is_out = true;
        player.act();

        self.check_round_over();
    }

    pub fn check(self: *Game) !void {
        const player = self.get_next_player();

        if (player.current_bet != self.highest_bet) {
            unreachable;
        }

        player.act();
        self.check_round_over();
    }

    pub fn call(self: *Game) void {
        self.raise(self.highest_bet);
    }

    pub fn raise(self: *Game, amount: f64) void {
        const player = self.get_next_player();

        const difference: f64 = amount - player.current_bet;
        if (difference < 0.0) {
            unreachable;
        }

        player.bet(difference);
        player.act();

        self.*.highest_bet = amount;
        self.*.pot_size += difference;

        self.check_round_over();
    }

    pub fn setup_round(self: *Game, round: Round) void {
        switch (round) {
            Round.over => {
                self.*.round = round;
            },
            Round.preflop => {
                for (self.players) |player| {
                    player.*.is_out = false;
                    player.*.acted = false;
                    player.*.current_bet = 0.0;
                }

                const small_blind: f64 = self.blind * 0.5;

                self.*.pot_size += self.blind + small_blind;

                var small_blind_player = self.get_next_player();
                var big_blind_player = self.get_next_player();

                small_blind_player.bet(small_blind);
                big_blind_player.bet(self.blind);

                self.*.highest_bet = self.blind;
            },
            else => unreachable,
        }
    }
};

const expectEqual = std.testing.expectEqual;

test "Preflop - Fold, Call, Check" {
    const PLAYER_STACK: f64 = 100;
    const BIG_BLIND: f64 = 4;

    var p1 = Player{
        .stack = PLAYER_STACK,
        .is_out = false,
        .current_bet = 0,
        .acted = false,
    };
    var p2 = Player{ .stack = PLAYER_STACK, .is_out = false, .current_bet = 0, .acted = false };
    var p3 = Player{ .stack = PLAYER_STACK, .is_out = false, .current_bet = 0, .acted = false };

    var players = [_]*Player{ &p1, &p2, &p3 };

    var game = Game{ .blind = BIG_BLIND, .players = &players, .round = Round.preflop, .pot_size = 0, .dealer_index = 0, .players_acted = 0, .current_player_index = 0, .highest_bet = 0 };

    game.setup_round(Round.preflop);

    try expectEqual(game.pot_size, game.blind * 1.5);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND / 2);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);
    try expectEqual(game.players_acted, 2);

    game.fold();
    game.call();
    try game.check();

    try expectEqual(game.pot_size, BIG_BLIND * 2);
    try expectEqual(game.round, Round.flop);
    try expectEqual(game.players[0].stack, PLAYER_STACK);
    try expectEqual(game.players[1].stack, PLAYER_STACK - BIG_BLIND);
    try expectEqual(game.players[2].stack, PLAYER_STACK - BIG_BLIND);
}

test "Preflop - Fold, Raise, Raise, Call" {
    const PLAYER_STACK: f64 = 100.0;
    const BIG_BLIND: f64 = 4.0;

    var p1 = Player{
        .stack = PLAYER_STACK,
        .is_out = false,
        .current_bet = 0,
        .acted = false,
    };
    var p2 = Player{ .stack = PLAYER_STACK, .is_out = false, .current_bet = 0, .acted = false };
    var p3 = Player{ .stack = PLAYER_STACK, .is_out = false, .current_bet = 0, .acted = false };

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

    var p1 = Player{
        .stack = PLAYER_STACK,
        .is_out = false,
        .current_bet = 0,
        .acted = false,
    };
    var p2 = Player{ .stack = PLAYER_STACK, .is_out = false, .current_bet = 0, .acted = false };
    var p3 = Player{ .stack = PLAYER_STACK, .is_out = false, .current_bet = 0, .acted = false };

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
