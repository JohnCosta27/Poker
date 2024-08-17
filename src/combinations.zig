const std = @import("std");
const print = std.debug.print;

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

fn factorial(n: usize) usize {
    if (n == 0) {
        return 1;
    }

    var f = n;

    for (1..f) |i| {
        f *= i;
    }

    return f;
}

fn ncr(n: usize, r: usize) usize {
    return factorial(n) / (factorial(r) * factorial(n - r));
}

pub fn combinations(comptime n: []const u16, comptime k: usize) []const u16 {
    @setEvalBranchQuota(10000);

    if (k == 1) {
        return n;
    }

    const combos_length = ncr(n.len, k);

    var combos: [combos_length]u16 = undefined;
    var index: usize = 0;

    for (0..n.len - k + 1) |i| {
        const head = n[i];
        const tail = combinations(n[i + 1 ..], k - 1);

        for (tail) |t| {
            const combo = head | t;
            combos[index] = combo;

            index += 1;
        }
    }

    return &combos;
}

test "Factorial" {
    try expectEqual(factorial(1), 1);
    try expectEqual(factorial(2), 2);
    try expectEqual(factorial(3), 6);
    try expectEqual(factorial(4), 24);
    try expectEqual(factorial(5), 120);
}

test "nCr" {
    try expectEqual(ncr(2, 1), 2);
    try expectEqual(ncr(4, 2), 6);
    try expectEqual(ncr(13, 5), 1287);
}

test "Base case" {
    const n = comptime [_]u16{ 0x1, 0x2, 0x4 };
    const combos = comptime combinations(&n, 1);

    comptime try expectEqualSlices(u16, &n, combos);
}

test "Simple cases" {
    const n = comptime [_]u16{ 0x1, 0x2, 0x4 };
    const combos = comptime combinations(&n, 2);

    // 011, 101, 110
    const expected_combos = comptime [_]u16{ 0x0003, 0x0005, 0x0006 };

    comptime try expectEqualSlices(u16, &expected_combos, combos);
}

test "Harder cases" {
    const n = comptime [_]u16{ 0x10, 0x8, 0x4, 0x2, 0x1 };
    const combos = comptime combinations(&n, 3);

    // 11111 C 3 = 00111, 01011, 01101, 01110, 10011, 10101, 10110, 11001, 11010, 11100
    const expected_combos = comptime [_]u16{ 28, 26, 25, 22, 21, 19, 14, 13, 11, 7 };

    comptime try expectEqualSlices(u16, &expected_combos, combos);
}
