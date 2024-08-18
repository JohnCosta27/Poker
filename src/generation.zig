const std = @import("std");
const Combo = @import("./combinations.zig");
const Cards = @import("./cards.zig");

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const print = std.debug.print;

fn bitmask_as_cards(mask: u16) [5]Cards.Rank {
    var cards: [5]Cards.Rank = undefined;
    var index: usize = 0;

    inline for (Cards.reversed_array) |c| {
        if (mask & c > 0) {
            cards[index] = @enumFromInt(c);
            index += 1;
        }
    }

    return cards;
}

//
// This includes
// - Straight flushes (including royal flush)
// - flushes
// - straights
// - high cards
//
fn unique5() []const u16 {
    return Combo.combinations(&Cards.array, 5);
}

fn generate_flushes() []u16 {
    const unique_hands = unique5();
    @compileLog(unique_hands.len);
    var flushes: [unique_hands[0] + 1]u16 = std.mem.zeroes([unique_hands[0] + 1]u16);

    // Do straight flushes seperately
    flushes[@truncate(Cards.ace | Cards.king | Cards.queen | Cards.jack | Cards.ten)] = 1;
    flushes[@truncate(Cards.king | Cards.queen | Cards.jack | Cards.ten | Cards.nine)] = 2;
    flushes[@truncate(Cards.queen | Cards.jack | Cards.ten | Cards.nine | Cards.eight)] = 3;
    flushes[@truncate(Cards.jack | Cards.ten | Cards.nine | Cards.eight | Cards.seven)] = 4;
    flushes[@truncate(Cards.ten | Cards.nine | Cards.eight | Cards.seven | Cards.six)] = 5;
    flushes[@truncate(Cards.nine | Cards.eight | Cards.seven | Cards.six | Cards.five)] = 6;
    flushes[@truncate(Cards.eight | Cards.seven | Cards.six | Cards.five | Cards.four)] = 7;
    flushes[@truncate(Cards.seven | Cards.six | Cards.five | Cards.four | Cards.three)] = 8;
    flushes[@truncate(Cards.six | Cards.five | Cards.four | Cards.three | Cards.two)] = 9;
    flushes[@truncate(Cards.five | Cards.four | Cards.three | Cards.two | Cards.ace)] = 10;

    var flushes_values = 10 + (13 * 12) + (13 * 12) + 1;

    for (unique_hands) |hand| {
        if (flushes[hand] > 0) {
            continue;
        }

        flushes[hand] = flushes_values;
        flushes_values += 1;
    }

    return &flushes;
}

fn generate_unique() []u16 {
    const unique_hands = unique5();

    var unique: [unique_hands[0] + 1]u16 = std.mem.zeroes([unique_hands[0] + 1]u16);

    const UNIQUE_HANDS = unique_hands.len;

    // UNIQUE_HANDS = straight flushes + flushes + quads + boats
    var unique_values = UNIQUE_HANDS + (13 * 12) + (13 * 12) + 1;

    // Do straights seperately
    unique[@truncate(Cards.ace | Cards.king | Cards.queen | Cards.jack | Cards.ten)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.king | Cards.queen | Cards.jack | Cards.ten | Cards.nine)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.queen | Cards.jack | Cards.ten | Cards.nine | Cards.eight)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.jack | Cards.ten | Cards.nine | Cards.eight | Cards.seven)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.ten | Cards.nine | Cards.eight | Cards.seven | Cards.six)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.nine | Cards.eight | Cards.seven | Cards.six | Cards.five)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.eight | Cards.seven | Cards.six | Cards.five | Cards.four)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.seven | Cards.six | Cards.five | Cards.four | Cards.three)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.six | Cards.five | Cards.four | Cards.three | Cards.two)] = unique_values;
    unique_values += 1;

    unique[@truncate(Cards.five | Cards.four | Cards.three | Cards.two | Cards.ace)] = unique_values;
    unique_values += 1;

    for (unique_hands) |hand| {
        if (unique[hand] > 0) {
            continue;
        }

        unique[hand] = unique_values;
        unique_values += 1;
    }

    return &unique;
}

fn generate_rest() []usize {
    @setEvalBranchQuota(100000);

    const NUM_OF_QUADS = 156;
    const NUM_OF_BOATS = 156;

    const NUM_OF_SETS = 13 * Combo.ncr(12, 2);
    const NUM_OF_TWO_PAIR = 13 * Combo.ncr(12, 2);

    const NUM_OF_PAIR = 13 * Combo.ncr(12, 3);

    var rest: [NUM_OF_QUADS + NUM_OF_BOATS + NUM_OF_SETS + NUM_OF_TWO_PAIR + NUM_OF_PAIR]usize = undefined;

    var index: usize = 0;

    // Quads + Boats
    for (Cards.prime_array) |card| {
        for (Cards.prime_array) |kicker| {
            if (card == kicker) {
                continue;
            }

            rest[index] = card * card * card * card * kicker;
            rest[index + NUM_OF_QUADS] = card * card * card * kicker * kicker;

            index += 1;
        }
    }

    index += NUM_OF_BOATS;

    // Sets + Two pair
    for (Cards.prime_array) |card| {
        for (Cards.prime_array) |kicker| {
            if (card == kicker) {
                continue;
            }

            for (Cards.prime_array) |second_kicker| {
                if (card == second_kicker or second_kicker >= kicker) {
                    continue;
                }

                rest[index] = card * card * card * kicker * second_kicker;
                rest[index + NUM_OF_SETS] = card * card * kicker * kicker * second_kicker;

                index += 1;
            }
        }
    }

    index += NUM_OF_SETS;

    // Pairs
    for (Cards.prime_array) |card| {
        for (Cards.prime_array) |kicker| {
            if (card == kicker) {
                continue;
            }

            for (Cards.prime_array) |second_kicker| {
                if (card == second_kicker or second_kicker >= kicker) {
                    continue;
                }

                for (Cards.prime_array) |third_kicker| {
                    if (card == third_kicker or third_kicker >= second_kicker) {
                        continue;
                    }

                    rest[index] = card * card * kicker * second_kicker * third_kicker;

                    index += 1;
                }
            }
        }
    }

    return &rest;
}

test "Bitmask to cards" {
    const hand: u16 = Cards.ace | Cards.king | Cards.queen | Cards.jack | Cards.ten;
    const ranks = bitmask_as_cards(hand);

    try expectEqualSlices(Cards.Rank, &ranks, &[_]Cards.Rank{ Cards.Rank.ten, Cards.Rank.jack, Cards.Rank.queen, Cards.Rank.king, Cards.Rank.ace });
}

// test "Generate flushes array" {
//     @setEvalBranchQuota(1000000);
//
//     const flushes = comptime generate_flushes();
//     const unique = comptime generate_unique();
//
//     @compileLog(flushes);
//     @compileLog(unique);
// }

test "Perfect hash" {
    const allocator = std.testing.allocator;

    const rest = comptime generate_rest();

    const p = 5047573;

    const a = 327892;
    const b = 287232;

    var seen_numbers = std.AutoHashMap(usize, bool).init(allocator);

    defer seen_numbers.deinit();

    inline for (rest) |hand| {
        const hash = (a * hand + b) % p;
        _ = hash;

        print("{}\n", .{hand});

        if (seen_numbers.get(hand) != null) {
            // just fail.
            try expectEqual(true, false);
        }

        try seen_numbers.put(hand, true);
    }

    // we're all good;
    try expectEqual(true, true);
}
