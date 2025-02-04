const std = @import("std");
const TexasHoldem = @import("./texas-hold-em.zig");
const Game = @import("./game.zig");

pub fn main() !void {
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
    var p5 = Game.Player{
        .name = "Player 5",
        .stack = 100,
        .current_bet = null,
    };
    var p6 = Game.Player{
        .name = "Player 6",
        .stack = 100,
        .current_bet = null,
    };

    var players = [_]*Game.Player{ &p1, &p2, &p3, &p4, &p5, &p6 };

    var holdem = TexasHoldem.TexasHoldEm.create(allocator, 1, &players);

    holdem.setup();
    holdem.print_player_cards();

    holdem.game.start();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer().any();

    var previous_round: ?Game.Round = null;

    while (holdem.game.round != Game.Round.over) {
        const player_name = holdem.game.current_round_left_to_act.items[0].name;

        if (holdem.game.round != previous_round) {
            try stdout.print("Round {any}\n", .{holdem.game.round});

            switch (holdem.game.round) {
                Game.Round.preflop => {},
                Game.Round.flop => {
                    holdem.flop();

                    try holdem.flop1.?.print(stdout);
                    try holdem.flop2.?.print(stdout);
                    try holdem.flop3.?.print(stdout);
                },
                Game.Round.turn => holdem.flop(),
                Game.Round.river => holdem.flop(),
                else => unreachable,
            }
        }

        previous_round = holdem.game.round;

        try stdout.print("Pot: {d}\n", .{holdem.game.pots.items[0].pot_size});
        try stdout.print("Player {s} to act: F, X, C, R: ", .{player_name});

        const player_choice = try stdin.readUntilDelimiterAlloc(allocator, '\n', 9999);
        defer allocator.free(player_choice);

        if (std.mem.eql(u8, player_choice, "F")) {
            holdem.game.fold();
        } else if (std.mem.eql(u8, player_choice, "X")) {
            holdem.game.check();
        } else if (std.mem.eql(u8, player_choice, "C")) {
            holdem.game.call();
        } else if (std.mem.eql(u8, player_choice, "R")) {
            const raise_amount = try stdin.readUntilDelimiterAlloc(allocator, '\n', 9999);
            defer allocator.free(raise_amount);

            const amount = try std.fmt.parseFloat(f64, raise_amount);
            holdem.game.raise(amount);
        }
    }
}
