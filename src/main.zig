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
}
