const std = @import("std");

const generation = @import("./generation/generation.zig");
const cards = @import("./cards/cards.zig");

pub const Card = cards.Card;
pub const Suit = cards.Suit;
pub const Rank = cards.Rank;
pub const CardFactory = cards.CardFactory;

const flushes: generation.ArrayLengths = generation.GenerateFlushes();
const unique: generation.ArrayLengths = generation.GenerateUniques();
const rest: generation.GenerateRestReturn = generation.GenerateRest();

fn flush_mask(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) u16 {
    return @truncate(c1.Mask & c2.Mask & c3.Mask & c3.Mask & c4.Mask & c5.Mask & 0xF000);
}

fn unique_mask(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) u16 {
    return @truncate((c1.Mask | c2.Mask | c3.Mask | c3.Mask | c4.Mask | c5.Mask) >> 16);
}

fn unique_prime(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) usize {
    return c1.get_prime() * c2.get_prime() * c3.get_prime() * c4.get_prime() * c5.get_prime();
}

// ========================================

pub fn Evaluator() type {
    return struct {
        const self = @This();

        fn evaluate_flushes(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) ?u16 {
            const mask = flush_mask(c1, c2, c3, c4, c5);
            if (mask == 0) {
                return undefined;
            }

            const unique_ranks = unique_mask(c1, c2, c3, c4, c5);

            return flushes[unique_ranks];
        }

        fn evaluate_uniques(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) ?u16 {
            const unique_ranks = unique_mask(c1, c2, c3, c4, c5);
            if (unique_ranks == 0) {
                return undefined;
            }

            return unique[unique_ranks];
        }

        fn evaluate_rest(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) u16 {
            const hand = unique_prime(c1, c2, c3, c4, c5);

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

        pub fn evaluate(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card) u16 {
            return self.evaluate_flushes(c1, c2, c3, c4, c5) orelse self.evaluate_uniques(c1, c2, c3, c4, c5) orelse self.evaluate_rest(c1, c2, c3, c4, c5);
        }
    };
}

// ========================================

const expect = std.testing.expect;

test "Simple hands" {
    const c1 = cards.CardFactory(cards.Rank.ace, cards.Suit.heart);
    const c2 = cards.CardFactory(cards.Rank.king, cards.Suit.heart);
    const c3 = cards.CardFactory(cards.Rank.queen, cards.Suit.heart);
    const c4 = cards.CardFactory(cards.Rank.jack, cards.Suit.heart);
    const c5 = cards.CardFactory(cards.Rank.ten, cards.Suit.heart);

    const c6 = cards.CardFactory(cards.Rank.ace, cards.Suit.heart);
    const c7 = cards.CardFactory(cards.Rank.king, cards.Suit.diamond);
    const c8 = cards.CardFactory(cards.Rank.queen, cards.Suit.heart);
    const c9 = cards.CardFactory(cards.Rank.jack, cards.Suit.heart);
    const c10 = cards.CardFactory(cards.Rank.ten, cards.Suit.heart);

    const evaluator = Evaluator();

    try expect(evaluator.evaluate(c1, c2, c3, c4, c5) < evaluator.evaluate(c6, c7, c8, c9, c10));
}
