pub const constants = @import("./constants.zig");

pub const Suit = enum(u2) {
    club = 0,
    diamond,
    heart,
    spade,
    pub fn name(self: Suit) []const u8 {
        return switch (self) {
            Suit.club => "Clubs",
            Suit.diamond => "Diamonds",
            Suit.heart => "Hearts",
            Suit.spade => "Spades",
        };
    }
};

pub const Rank = enum(u4) {
    ace = 12,
    two = 0,
    three = 1,
    four = 2,
    five = 3,
    six = 4,
    seven = 5,
    eight = 6,
    nine = 7,
    ten = 8,
    jack = 9,
    queen = 10,
    king = 11,
    pub fn name(self: Rank) []const u8 {
        return switch (self) {
            Rank.ace => "Ace",
            Rank.two => "Two",
            Rank.three => "Three",
            Rank.four => "Four",
            Rank.five => "Five",
            Rank.six => "Six",
            Rank.seven => "Seven",
            Rank.eight => "Eight",
            Rank.nine => "Nine",
            Rank.ten => "Ten",
            Rank.jack => "Jack",
            Rank.queen => "Queen",
            Rank.king => "King",
        };
    }
};

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

pub const Card = struct {
    Suit: Suit,
    Rank: Rank,

    Mask: u32,

    pub fn get_suit(self: Card) Suit {
        _ = self;
    }

    pub fn get_prime(self: Card) usize {
        return self.Mask & 0xFF;
    }
};

pub fn CardFactory(rank: Rank, suit: Suit) Card {
    return Card{ .Rank = rank, .Suit = suit, .Mask = get_rank_mask(rank) | get_suit_mask(suit) };
}
