const std = @import("std");

const cards = @import("./cards/cards.zig");
const evaluator = @import("./evaluator/evaluator.zig");

const print = std.debug.print;

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

const rand = std.crypto.random;

const Deck = struct {
    Cards: [52]cards.Card,

    dealt_index: usize,

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
            print("{any}\n", .{card});
        }
    }

    pub fn deal(self: *Deck) cards.Card {
        const card = self.Cards[self.dealt_index];
        self.dealt_index += 1;

        return card;
    }
};

fn generate_cards() ![52]cards.Card {
    var c = std.mem.zeroes([52]cards.Card);

    var index: usize = 0;

    inline for (std.meta.fields(cards.Suit)) |suit| {
        inline for (std.meta.fields(cards.Rank)) |rank| {
            c[index] = cards.CardFactory(try std.meta.intToEnum(cards.Rank, rank.value), try std.meta.intToEnum(cards.Suit, suit.value));
            index += 1;
        }
    }

    return cards;
}

const DEFAULT_DECK = generate_cards() catch unreachable;

fn generate_deck() Deck {
    var new_deck = Deck{ .Cards = DEFAULT_DECK, .dealt_index = 0 };

    new_deck.shuffle();

    return new_deck;
}

const eval = evaluator.Evaluator();

pub fn main() !void {
    const c1 = cards.CardFactory(cards.Rank.ace, cards.Suit.heart);
    const c2 = cards.CardFactory(cards.Rank.king, cards.Suit.heart);
    const c3 = cards.CardFactory(cards.Rank.queen, cards.Suit.heart);
    const c4 = cards.CardFactory(cards.Rank.jack, cards.Suit.heart);
    const c5 = cards.CardFactory(cards.Rank.ten, cards.Suit.heart);

    const x = eval.evaluate(c1, c2, c3, c4, c5);
    _ = x;
}
