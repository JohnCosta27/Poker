const std = @import("std");
const Combo = @import("./combinations.zig");
const Cards = @import("./cards.zig");

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const print = std.debug.print;

fn bitmask_as_cards(mask: u16) [5]Cards.Rank {
    var cards: [5]Cards.Rank = undefined;
    var index: usize = 0;

    inline for (Cards.array) |c| {
        if (mask & c > 0) {
            cards[index] = @enumFromInt(c);
            index += 1;
        }
    }

    return cards;
}

fn unique5() []const u16 {
    return Combo.combinations(&Cards.reversed_array, 5);
}

test "Bitmask to cards" {
    const hand: u16 = Cards.ace | Cards.king | Cards.queen | Cards.jack | Cards.ten;
    const ranks = bitmask_as_cards(hand);

    try expectEqualSlices(Cards.Rank, &ranks, &[_]Cards.Rank{ Cards.Rank.ten, Cards.Rank.jack, Cards.Rank.queen, Cards.Rank.king, Cards.Rank.ace });
}

test "stuff" {
    const unique_hands = comptime unique5();

    inline for (unique_hands) |hand| {
        print("{any}\n", .{bitmask_as_cards(hand)});
    }
}
