const std = @import("std");
const combo = @import("./combinations.zig");
const cards = @import("../cards/cards.zig");

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const print = std.debug.print;

const NUM_OF_STRAIGHT_FLUSHES = 10;

const NUM_OF_QUADS = 156;

const NUM_OF_FLUSHES = 1277;
const NUM_OF_STRAIGHTS = 10;

const NUM_OF_BOATS = 156;

const NUM_OF_SETS = 13 * combo.ncr(12, 2);
const NUM_OF_TWO_PAIR = 13 * combo.ncr(12, 2);

const NUM_OF_PAIR = 13 * combo.ncr(12, 3);

const REST_SIZE = NUM_OF_QUADS + NUM_OF_BOATS + NUM_OF_SETS + NUM_OF_TWO_PAIR + NUM_OF_PAIR;

pub const RestWithPosition = struct {
    rest: [REST_SIZE]usize,
    strength: [REST_SIZE]u16,
};

pub const ArrayLengths = [HIGHEST_BIT_PATTERN]u16;

//
// This includes
// - Straight flushes (including royal flush)
// - flushes
// - straights
// - high cards
//
fn unique5() []const u16 {
    return combo.combinations(&cards.constants.array, 5);
}

const HIGHEST_BIT_PATTERN = (cards.constants.ace | cards.constants.king | cards.constants.queen | cards.constants.jack | cards.constants.ten) + 1;

pub fn generate_flushes() [HIGHEST_BIT_PATTERN]u16 {
    @setEvalBranchQuota(100000);

    const unique_hands = unique5();
    var flushes: [HIGHEST_BIT_PATTERN]u16 = std.mem.zeroes([HIGHEST_BIT_PATTERN]u16);

    // Do straight flushes seperately
    flushes[@truncate(cards.constants.ace | cards.constants.king | cards.constants.queen | cards.constants.jack | cards.constants.ten)] = 1;
    flushes[@truncate(cards.constants.king | cards.constants.queen | cards.constants.jack | cards.constants.ten | cards.constants.nine)] = 2;
    flushes[@truncate(cards.constants.queen | cards.constants.jack | cards.constants.ten | cards.constants.nine | cards.constants.eight)] = 3;
    flushes[@truncate(cards.constants.jack | cards.constants.ten | cards.constants.nine | cards.constants.eight | cards.constants.seven)] = 4;
    flushes[@truncate(cards.constants.ten | cards.constants.nine | cards.constants.eight | cards.constants.seven | cards.constants.six)] = 5;
    flushes[@truncate(cards.constants.nine | cards.constants.eight | cards.constants.seven | cards.constants.six | cards.constants.five)] = 6;
    flushes[@truncate(cards.constants.eight | cards.constants.seven | cards.constants.six | cards.constants.five | cards.constants.four)] = 7;
    flushes[@truncate(cards.constants.seven | cards.constants.six | cards.constants.five | cards.constants.four | cards.constants.three)] = 8;
    flushes[@truncate(cards.constants.six | cards.constants.five | cards.constants.four | cards.constants.three | cards.constants.two)] = 9;
    flushes[@truncate(cards.constants.five | cards.constants.four | cards.constants.three | cards.constants.two | cards.constants.ace)] = 10;

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
    @setEvalBranchQuota(100000);

    const unique_hands = unique5();

    var unique: [HIGHEST_BIT_PATTERN]u16 = std.mem.zeroes([HIGHEST_BIT_PATTERN]u16);

    const UNIQUE_HANDS = unique_hands.len;

    // UNIQUE_HANDS = straight flushes + flushes + quads + boats
    var unique_values = UNIQUE_HANDS + (13 * 12) + (13 * 12) + 1;

    // Do straights seperately
    unique[@truncate(cards.constants.ace | cards.constants.king | cards.constants.queen | cards.constants.jack | cards.constants.ten)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.king | cards.constants.queen | cards.constants.jack | cards.constants.ten | cards.constants.nine)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.queen | cards.constants.jack | cards.constants.ten | cards.constants.nine | cards.constants.eight)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.jack | cards.constants.ten | cards.constants.nine | cards.constants.eight | cards.constants.seven)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.ten | cards.constants.nine | cards.constants.eight | cards.constants.seven | cards.constants.six)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.nine | cards.constants.eight | cards.constants.seven | cards.constants.six | cards.constants.five)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.eight | cards.constants.seven | cards.constants.six | cards.constants.five | cards.constants.four)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.seven | cards.constants.six | cards.constants.five | cards.constants.four | cards.constants.three)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.six | cards.constants.five | cards.constants.four | cards.constants.three | cards.constants.two)] = unique_values;
    unique_values += 1;

    unique[@truncate(cards.constants.five | cards.constants.four | cards.constants.three | cards.constants.two | cards.constants.ace)] = unique_values;
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

pub fn generate_rest() RestWithPosition {
    @setEvalBranchQuota(1000000);

    var rest: [REST_SIZE]usize = undefined;
    var absolute_strength: [REST_SIZE]usize = undefined;

    var index: usize = 0;
    var strength_index: u16 = NUM_OF_STRAIGHT_FLUSHES + 1;

    // Quads + Boats
    for (cards.constants.prime_array) |card| {
        for (cards.constants.prime_array) |kicker| {
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
    for (cards.constants.prime_array) |card| {
        for (cards.constants.prime_array) |kicker| {
            if (card == kicker) {
                continue;
            }

            for (cards.constants.prime_array) |second_kicker| {
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
    for (cards.constants.prime_array) |card| {
        for (cards.constants.prime_array) |kicker| {
            if (kicker >= card) {
                continue;
            }

            for (cards.constants.prime_array) |second_kicker| {
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
    for (cards.constants.prime_array) |card| {
        for (cards.constants.prime_array) |kicker| {
            if (card == kicker) {
                continue;
            }

            for (cards.constants.prime_array) |second_kicker| {
                if (card == second_kicker or second_kicker >= kicker) {
                    continue;
                }

                for (cards.constants.prime_array) |third_kicker| {
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

    var index_to_strength: [REST_SIZE]u16 = undefined;

    for (rest_with_index, 0..) |sorted, i| {
        const product: usize = @truncate(sorted >> 64);
        const strength: usize = @truncate(sorted);

        rest[i] = product;
        index_to_strength[i] = strength;
    }

    return RestWithPosition{ .rest = rest, .strength = index_to_strength };
}
