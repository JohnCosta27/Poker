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

const HIGHEST_BIT_PATTERN = (Cards.ace | Cards.king | Cards.queen | Cards.jack | Cards.ten) + 1;

pub fn generate_flushes() [HIGHEST_BIT_PATTERN]u16 {
    const unique_hands = unique5();
    var flushes: [HIGHEST_BIT_PATTERN]u16 = std.mem.zeroes([HIGHEST_BIT_PATTERN]u16);

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

    return flushes;
}

pub fn generate_unique() [HIGHEST_BIT_PATTERN]u16 {
    const unique_hands = unique5();

    var unique: [HIGHEST_BIT_PATTERN]u16 = std.mem.zeroes([HIGHEST_BIT_PATTERN]u16);

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

    return unique;
}

const NUM_OF_STRAIGHT_FLUSHES = 10;

const NUM_OF_QUADS = 156;

const NUM_OF_FLUSHES = 1277;
const NUM_OF_STRAIGHTS = 10;

const NUM_OF_BOATS = 156;

const NUM_OF_SETS = 13 * Combo.ncr(12, 2);
const NUM_OF_TWO_PAIR = 13 * Combo.ncr(12, 2);

const NUM_OF_PAIR = 13 * Combo.ncr(12, 3);

const REST_SIZE = NUM_OF_QUADS + NUM_OF_BOATS + NUM_OF_SETS + NUM_OF_TWO_PAIR + NUM_OF_PAIR;

const RestWithPosition = struct {
    rest: [REST_SIZE]usize,
    strength: [REST_SIZE]usize,
};

pub fn generate_rest() RestWithPosition {
    @setEvalBranchQuota(1000000);

    var rest: [REST_SIZE]usize = undefined;
    var absolute_strength: [REST_SIZE]usize = undefined;

    var index: usize = 0;
    var strength_index: usize = NUM_OF_STRAIGHT_FLUSHES + 1;

    // Quads + Boats
    for (Cards.prime_array) |card| {
        for (Cards.prime_array) |kicker| {
            if (card == kicker) {
                continue;
            }

            rest[index] = card * card * card * card * kicker;
            rest[index + NUM_OF_QUADS] = card * card * card * kicker * kicker;

            absolute_strength[index] = strength_index;
            absolute_strength[index + NUM_OF_QUADS] = strength_index + NUM_OF_QUADS;

            strength_index += 1;
            index += 1;
        }
    }

    index += NUM_OF_BOATS;
    strength_index += NUM_OF_BOATS + NUM_OF_FLUSHES + NUM_OF_STRAIGHTS;

    // Sets
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

                absolute_strength[index] = strength_index;

                index += 1;
                strength_index += 1;
            }
        }
    }

    // Two pairs
    for (Cards.prime_array) |card| {
        for (Cards.prime_array) |kicker| {
            if (kicker >= card) {
                continue;
            }

            for (Cards.prime_array) |second_kicker| {
                if (card == second_kicker or kicker == second_kicker) {
                    continue;
                }

                rest[index] = card * card * kicker * kicker * second_kicker;

                absolute_strength[index] = strength_index;

                index += 1;
                strength_index += 1;
            }
        }
    }

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

                    absolute_strength[index] = strength_index;

                    index += 1;
                    strength_index += 1;
                }
            }
        }
    }

    var rest_with_index: [REST_SIZE]u128 = undefined;
    for (rest, absolute_strength, 0..) |r, s, i| {
        rest_with_index[i] = @as(u128, r) << 64 | @as(u128, s);
    }

    std.mem.sort(u128, &rest_with_index, {}, comptime std.sort.asc(u128));

    var index_to_strength: [REST_SIZE]usize = undefined;

    for (rest_with_index, 0..) |sorted, i| {
        const product: usize = @truncate(sorted >> 64);
        const strength: usize = @truncate(sorted);

        rest[i] = product;
        index_to_strength[i] = strength;
    }

    return RestWithPosition{ .rest = rest, .strength = index_to_strength };
}

pub fn rest_strength(rest: RestWithPosition, hand: usize) usize {
    var head: usize = 0;
    var tail: usize = rest.rest.len - 1;

    while (head <= tail) {
        const middle = (head + tail) / 2;

        if (rest.rest[middle] == hand) {
            return rest.strength[middle];
        }

        if (rest.rest[middle] < hand) {
            head = middle + 1;
            continue;
        }

        if (rest.rest[middle] > hand) {
            tail = middle - 1;
            continue;
        }
    }

    unreachable;
}

test "Bitmask to cards" {
    const hand: u16 = Cards.ace | Cards.king | Cards.queen | Cards.jack | Cards.ten;
    const ranks = bitmask_as_cards(hand);

    try expectEqualSlices(Cards.Rank, &ranks, &[_]Cards.Rank{ Cards.Rank.ten, Cards.Rank.jack, Cards.Rank.queen, Cards.Rank.king, Cards.Rank.ace });
}

test "Binary search for hand strength" {
    const rest = generate_rest();

    const AAAAK: usize = Cards.prime_ace * Cards.prime_ace * Cards.prime_ace * Cards.prime_ace * Cards.prime_king;
    try expectEqual(rest_strength(rest, AAAAK), 11);

    const KKKKA: usize = Cards.prime_king * Cards.prime_king * Cards.prime_king * Cards.prime_king * Cards.prime_ace;
    try expectEqual(rest_strength(rest, KKKKA), 23);
}
