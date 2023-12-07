const std = @import("std");
const Timer = std.time.Timer;
const StaticBitSet = std.bit_set.StaticBitSet;
const isDigit = std.ascii.isDigit;
const isUpper = std.ascii.isUpper;
const isLower = std.ascii.isLower;
const isAlphanumeric = std.ascii.isAlphanumeric;
const charToDigit = std.fmt.charToDigit;
const print = std.debug.print;
const assert = std.debug.assert;
const sort = std.sort;

const Hand = struct {
    cards: [5]u8,
    bid: u32,
    type: Type,
};

const Type = enum(u8) {
    high_card = 0,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,
};

fn charToDigitUnsafe(comptime T: type, char: u8) T {
    const res: T = char - '0';
    return res;
}

fn hands_cmp(_: void, a: Hand, b: Hand) bool {
    const aType = @intFromEnum(a.type);
    const bType = @intFromEnum(b.type);
    if (aType != bType) return aType < bType;
    for (0..a.cards.len) |i| {
        const sA = strength(a.cards[i]);
        const sB = strength(b.cards[i]);
        if (sA != sB) {
            // print("{s} < {s} {}\n", .{ a.cards, b.cards, sA < sB });
            return sA < sB;
        }
    }
    unreachable;
}

fn strength(card: u8) u8 {
    // print("char do be {c}\n", .{card});
    return switch (card) {
        // 2 => 0, 3 => 1...
        '2'...'9' => charToDigitUnsafe(u8, card) - 2,
        'T' => 8,
        'J' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => unreachable,
    };
}

// Bit faster than std lib's error checked one
fn parseUnsignedUnsafe(comptime T: type, buf: []const u8) T {
    var res: T = 0;
    for (buf) |char| {
        res *= 10;
        res += charToDigitUnsafe(T, char);
    }
    return res;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    const MAX_WIDTH = 250;
    const MAX_HEIGHT = 1001;
    var width: usize = 0;
    var height: usize = 0;

    const k = [_]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };
    for (k) |i| {
        for (k) |j| {
            if (i == j) continue;
            assert(strength(i) != strength(j));
        }
    }

    for (k, 0..) |p, i| {
        for (k[i + 1 .. k.len]) |c| {
            assert(strength(c) != strength(p));
        }
    }

    const input: [MAX_HEIGHT][MAX_WIDTH]u8 = blk: {
        var tmp: [MAX_HEIGHT][MAX_WIDTH]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            for (line, 0..) |char, char_i| {
                tmp[height][char_i] = char;
            }
            width = @max(width, line.len);
            height += 1;
        }
        break :blk tmp;
    };

    var runs: u64 = 0;
    const MS_IN_SEC = 1_000_000_000;
    const RUN_TIME = MS_IN_SEC * 10;

    var w: u64 = 0;
    var total_timer = try Timer.start();
    while (total_timer.read() <= RUN_TIME) {
        var hands: [MAX_HEIGHT]Hand = undefined;
        var hands_i: usize = 0;
        var cards: StaticBitSet(256) = undefined;

        for (input[0..height]) |line| {
            cards = StaticBitSet(256).initEmpty();
            var char_i: usize = 0;

            var cur_str: [5]u8 = undefined;
            var cur_str_i: usize = 0;

            // Map of counts of each card
            var card_counts = [_]u8{0} ** 256;

            while (char_i < width) {
                defer char_i += 1;
                const char: u8 = line[char_i];
                cur_str[cur_str_i] = char;
                cur_str_i += 1;
                cards.set(char);
                card_counts[char] += 1;
                // eol, create card
                assert(isAlphanumeric(char));
                if (char_i == width - 1 or line[char_i + 1] == ' ') {
                    assert(cur_str_i == 5);
                    @memcpy(&hands[hands_i].cards, cur_str[0..cur_str_i]);
                    var c_type: Type = .high_card;
                    var two_same = false;
                    var three_same = false;
                    var ci = cards.iterator(.{ .kind = .set, .direction = .forward });
                    var c: ?usize = ci.next();
                    // check card counts to determine type
                    while (c != null) : (c = ci.next()) {
                        const card_char = @as(u8, @intCast(c.?));
                        const count = card_counts[card_char];
                        assert(count != 0);
                        assert(count <= 5);
                        assert(!isLower(card_char));
                        assert(isAlphanumeric(card_char));
                        if (count == 2) {
                            // found another 2 same cards
                            if (two_same) {
                                c_type = .two_pair;
                                break;
                            }
                            two_same = true;
                        } else if (count == 3) {
                            three_same = true;
                        } else if (count == 5) {
                            c_type = .five_of_a_kind;
                            break;
                        } else if (count == 4) {
                            c_type = .four_of_a_kind;
                            break;
                        }
                    }
                    if (c_type == .high_card) {
                        if (three_same) {
                            if (two_same) {
                                c_type = .full_house;
                            } else {
                                c_type = .three_of_a_kind;
                            }
                        } else if (two_same) {
                            c_type = .one_pair;
                        }
                    }
                    hands[hands_i].type = c_type;
                    break;
                }
            }
            char_i += 1;
            cur_str_i = 0;
            assert(line[char_i - 1] == ' ');

            while (char_i < width) : (char_i += 1) {
                const char = line[char_i];
                cur_str[cur_str_i] = char;
                cur_str_i += 1;
                assert(isDigit(char));
                if (char_i == width - 1 or !isDigit(line[char_i + 1])) {
                    const n = parseUnsignedUnsafe(u32, cur_str[0..cur_str_i]);
                    hands[hands_i].bid = n;
                    break;
                }
            }
            hands_i += 1;
        }
        sort.heap(Hand, hands[0..hands_i], {}, hands_cmp);

        const total_winnings: u64 = blk: {
            var tmp: u64 = 0;
            for (hands[0..hands_i], 1..) |*hand, rank| {
                // print("{s}: {} * {} = {}, {}\n", .{ hand.cards, hand.bid, rank, rank * hand.bid, hand.type });
                tmp += hand.bid * rank;
            }
            break :blk tmp;
        };

        // 248179786
        w = total_winnings;

        runs += 1;
    }

    print("Second part: {}\n", .{w});

    const avg = RUN_TIME / runs;
    const run_time_secs = @as(f64, @floatFromInt(RUN_TIME)) / MS_IN_SEC;
    print("{} runs in {d:.1} s: avg {d:.4} ns\n", .{ runs, run_time_secs, avg });
}
