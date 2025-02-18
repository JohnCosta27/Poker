const std = @import("std");
const Game = @import("game.zig");

const Cards = @import("./evaluator/cards/cards.zig");
const Deck = @import("./evaluator/cards/deck.zig");

const TexasHoldEmPlayer = struct {
    player: *Game.Player,

    c1: Cards.Card,
    c2: Cards.Card,
};

pub const TexasHoldEm = struct {
    allocator: std.mem.Allocator,

    players: []*TexasHoldEmPlayer,
    game: Game.Game,

    flop1: ?Cards.Card,
    flop2: ?Cards.Card,
    flop3: ?Cards.Card,
    turn: ?Cards.Card,
    river: ?Cards.Card,

    pub fn create(allocator: std.mem.Allocator, blinds: f64, game_players: []*Game.Player) TexasHoldEm {
        var players = allocator.alloc(*TexasHoldEmPlayer, game_players.len) catch unreachable;

        for (0..players.len) |index| {
            players[index] = allocator.create(TexasHoldEmPlayer) catch unreachable;

            players[index].player = game_players[index];
            players[index].c1 = undefined;
            players[index].c2 = undefined;
        }

        const game = Game.Game.create(allocator, blinds, game_players);

        return TexasHoldEm{
            .allocator = allocator,
            .game = game,
            .players = players,

            .flop1 = null,
            .flop2 = null,
            .flop3 = null,
            .turn = null,
            .river = null,
        };
    }

    pub fn print_player_cards(holdem: TexasHoldEm) void {
        for (holdem.players) |player| {
            std.debug.print("{s}. Stack: {d} - {s} of {s}, {s} of {s}\n", .{
                player.player.name,

                player.player.stack,

                player.c1.Rank.name(),
                player.c1.Suit.name(),

                player.c2.Rank.name(),
                player.c2.Suit.name(),
            });
        }
    }
};
