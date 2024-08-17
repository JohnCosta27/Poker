const std = @import("std");
const print = std.debug.print;

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

const rand = std.crypto.random;

const Suit = enum(u2) { club = 0, diamond, heart, spade };
const Rank = enum(u4) { ace = 12, two = 0, three = 1, four = 2, five = 3, six = 4, seven = 5, eight = 6, nine = 7, ten = 8, jack = 9, queen = 10, king = 11 };

const HIGHEST_RANK_VALUE = 11;
const HIGHEST_SUIT_VALUE = 3;

fn get_suit_mask(suit: Suit) u32 {
    return switch (suit) {
        .club => 0x00008000,
        .diamond => 0x00004000,
        .heart => 0x00002000,
        .spade => 0x00001000,
    };
}

fn get_rank_mask(rank: Rank) u32 {
    return switch (rank) {
        .ace => 0x10000C29,
        .king => 0x08000B25,
        .queen => 0x04000A1F,
        .jack => 0x0200091D,
        .ten => 0x01000817,
        .nine => 0x00800713,
        .eight => 0x00400611,
        .seven => 0x0020050D,
        .six => 0x0010040B,
        .five => 0x00080407,
        .four => 0x00040205,
        .three => 0x00200103,
        .two => 0x00010002,
    };
}

fn get_card(rank: Rank, suit: Suit) Card {
    return Card{ .Rank = rank, .Suit = suit, .Mask = get_rank_mask(rank) | get_suit_mask(suit) };
}

fn flush_mask(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) u32 {
    return c1.Mask & c2.Mask & c3.Mask & c3.Mask & c4.Mask & c5.Mask & 0xF000;
}

fn unique_mask(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) u32 {
    return c1.Mask | c2.Mask | c3.Mask | c3.Mask | c4.Mask | c5.Mask >> 16;
}

const Card = struct {
    Suit: Suit,
    Rank: Rank,
    Mask: u32,

    pub fn get_suit(self: Deck) Suit {
        _ = self;
    }
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
            cards[index] = get_card(try std.meta.intToEnum(Rank, rank.value), try std.meta.intToEnum(Suit, suit.value));
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

test "Using mask, if we have a flush" {
    const card1 = get_card(Rank.ace, Suit.heart);
    const card2 = get_card(Rank.king, Suit.heart);
    const card3 = get_card(Rank.queen, Suit.heart);
    const card4 = get_card(Rank.jack, Suit.heart);
    const card5 = get_card(Rank.ten, Suit.heart);

    var mask = flush_mask(card1, card2, card3, card4, card5);
    try expect(mask > 0);

    const card6 = get_card(Rank.ten, Suit.club);

    mask = flush_mask(card1, card2, card3, card4, card6);
    try expect(mask == 0);
}

test "Unique cards" {}
