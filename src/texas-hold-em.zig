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

    deck: Deck.Deck,

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
            .deck = Deck.Deck.create(),
        };
    }

    pub fn print_player_cards(holdem: TexasHoldEm) void {
        for (holdem.players) |player| {
            std.debug.print("{s} - {s} of {s}, {s} of {s}\n", .{
                player.player.name,

                player.c1.Rank.name(),
                player.c1.Suit.name(),

                player.c2.Rank.name(),
                player.c2.Suit.name(),
            });
        }
    }

    pub fn setup(holdem: *TexasHoldEm) void {
        holdem.*.deck.shuffle();

        for (0..holdem.players.len) |player_index| {
            // You deal to the small blind first.
            holdem.players[(player_index + 1) % holdem.players.len].*.c1 = holdem.*.deck.deal();
        }

        for (0..holdem.players.len) |player_index| {
            // You deal to the small blind first.
            holdem.players[(player_index + 1) % holdem.players.len].*.c2 = holdem.*.deck.deal();
        }
    }
};
