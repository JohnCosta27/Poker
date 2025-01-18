const std = @import("std");
const cards = @import("cards.zig");

const rand = std.crypto.random;

pub const Deck = struct {
    Cards: [52]cards.Card,

    dealt_index: usize,

    pub fn create() Deck {
        var c = std.mem.zeroes([52]cards.Card);

        var index: usize = 0;

        inline for (std.meta.fields(cards.Suit)) |suit| {
            inline for (std.meta.fields(cards.Rank)) |rank| {
                c[index] = cards.CardFactory(std.meta.intToEnum(cards.Rank, rank.value) catch unreachable, std.meta.intToEnum(cards.Suit, suit.value) catch unreachable);
                index += 1;
            }
        }

        return Deck{
            .Cards = c,
            .dealt_index = 0,
        };
    }

    pub fn shuffle(self: *Deck) void {
        for (0..self.Cards.len - 1) |i| {
            const random_index = rand.intRangeAtMost(usize, 0, self.Cards.len - 1);

            const temp = self.Cards[i];
            self.Cards[i] = self.Cards[random_index];
            self.Cards[random_index] = temp;
        }
    }

    pub fn print_deck(self: Deck) void {
        for (self.Cards) |card| {
            std.debug.print("{any}\n", .{card});
        }
    }

    pub fn deal(self: *Deck) cards.Card {
        const card = self.Cards[self.dealt_index];
        self.dealt_index += 1;

        return card;
    }
};
