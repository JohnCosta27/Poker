const std = @import("std");
const print = std.debug.print;

const rand = std.crypto.random;

const Suit = enum(u2) { heart = 0, diamond, spade, club };
const Rank = enum(u4) { ace = 12, two = 0, three = 1, four = 2, five = 3, six = 4, seven = 5, eight = 6, nine = 7, ten = 8, jack = 9, queen = 10, king = 11 };

const Card = struct {
    Suit: Suit,
    Rank: Rank,
};

const Deck = struct {
    Cards: [52]Card,

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

    pub fn deal(self: *Deck) Card {
        const card = self.Cards[self.dealt_index];
        self.dealt_index += 1;

        return card;
    }
};

fn generate_cards() ![52]Card {
    var cards = std.mem.zeroes([52]Card);

    var index: usize = 0;

    inline for (std.meta.fields(Suit)) |suit| {
        inline for (std.meta.fields(Rank)) |rank| {
            cards[index] = Card{ .Rank = try std.meta.intToEnum(Rank, rank.value), .Suit = try std.meta.intToEnum(Suit, suit.value) };
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

pub fn main() !void {
    var shuffled_deck = generate_deck();

    const card1 = shuffled_deck.deal();
    const card2 = shuffled_deck.deal();
    const card3 = shuffled_deck.deal();
    const card4 = shuffled_deck.deal();

    print("Card 1: {any}\n", .{card1});
    print("Card 2: {any}\n", .{card2});
    print("Card 3: {any}\n", .{card3});
    print("Card 4: {any}\n", .{card4});
}
