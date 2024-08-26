pub const two = 0x1;
pub const three = 0x2;
pub const four = 0x4;
pub const five = 0x8;
pub const six = 0x10;
pub const seven = 0x20;
pub const eight = 0x40;
pub const nine = 0x80;
pub const ten = 0x100;
pub const jack = 0x200;
pub const queen = 0x400;
pub const king = 0x800;
pub const ace = 0x1000;

pub const prime_two = 2;
pub const prime_three = 3;
pub const prime_four = 5;
pub const prime_five = 7;
pub const prime_six = 11;
pub const prime_seven = 13;
pub const prime_eight = 17;
pub const prime_nine = 19;
pub const prime_ten = 23;
pub const prime_jack = 29;
pub const prime_queen = 31;
pub const prime_king = 37;
pub const prime_ace = 41;

pub const Rank = enum(u16) { two = two, three = three, four = four, five = five, six = six, seven = seven, eight = eight, nine = nine, ten = ten, jack = jack, queen = queen, king = king, ace = ace };

pub const array = [13]u16{ ace, king, queen, jack, ten, nine, eight, seven, six, five, four, three, two };
pub const reversed_array = [13]u16{ two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace };

pub const prime_array = [13]usize{ prime_ace, prime_king, prime_queen, prime_jack, prime_ten, prime_nine, prime_eight, prime_seven, prime_six, prime_five, prime_four, prime_three, prime_two };
