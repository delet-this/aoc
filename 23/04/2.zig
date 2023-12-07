const std = @import("std");
const Timer = std.time.Timer;
const StaticBitSet = std.bit_set.StaticBitSet;
const isDigit = std.ascii.isDigit;

fn parseUnsignedUnsafe(comptime T: type, buf: []const u8) T {
    var res: T = 0;
    for (buf) |char| {
        res *= 10;
        res += char - '0';
    }
    return res;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    const MAX_WIDTH = 116;
    const MAX_HEIGHT = 211;

    const input: [MAX_HEIGHT][MAX_WIDTH]u8 = blk: {
        var width: usize = 0;
        var height: usize = 0;
        var tmp: [MAX_HEIGHT][MAX_WIDTH]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            for (line, 0..) |char, i| {
                tmp[height][i] = char;
            }
            if (height == 0) width = line.len;
            height += 1;
        }
        break :blk tmp;
    };

    var runs: u64 = 0;
    var time_i: usize = 0;
    const MS_IN_SEC = 1_000_000_000;
    const RUN_TIME = MS_IN_SEC * 10;

    var total_timer = try Timer.start();
    while (total_timer.read() <= RUN_TIME) {
        var sum_a: i32 = 0;
        var sum_b: i32 = 0;
        // Keeps track of how many copies of each card there are
        var copies_table = [_]i32{0} ** 250;
        for (input, 0..) |line, card_i| {
            var card_points: i32 = 0;

            // Skip to "Card 1: ..."
            //                ^
            var char_i: usize = 6;
            while (line[char_i] != ':')
                char_i += 1;

            var winningNums = StaticBitSet(100).initEmpty();
            var cur_num: [2]u8 = undefined;
            var cur_num_i: usize = 0;
            var copy_i: usize = card_i + 1;

            sum_b += 1;

            while (char_i < line.len) {
                defer char_i += 1;
                const char: u8 = line[char_i];
                if (char == '|') break;
                if (isDigit(char)) {
                    cur_num[cur_num_i] = char;
                    cur_num_i += 1;
                    if (cur_num_i == 2 or !isDigit(line[char_i + 1])) {
                        winningNums.set(parseUnsignedUnsafe(u8, cur_num[0..cur_num_i]));
                        cur_num_i = 0;
                    }
                }
            }
            cur_num_i = 0;

            while (char_i < line.len) {
                defer char_i += 1;
                const char: u8 = line[char_i];
                if (isDigit(char)) {
                    cur_num[cur_num_i] = char;
                    if (cur_num_i == 1 or char_i == line.len - 1 or !isDigit(line[char_i + 1])) {
                        if (winningNums.isSet(parseUnsignedUnsafe(u8, cur_num[0 .. cur_num_i + 1]))) {
                            const reward = 1 + copies_table[card_i];
                            copies_table[copy_i] += reward;
                            sum_b += reward;
                            copy_i += 1;
                            card_points = if (card_points == 0) 1 else card_points * 2;
                        }
                        cur_num_i = 0;
                    } else {
                        cur_num_i += 1;
                    }
                }
            }
            sum_a += card_points;
        }
        // std.debug.print("First part: {}\n", .{sum_a});
        // std.debug.print("Second part: {}\n", .{sum_b});
        runs += 1;
        time_i += 1;
    }

    const avg = RUN_TIME / runs;
    const run_time_secs = @as(f32, @floatFromInt(RUN_TIME)) / MS_IN_SEC;
    std.debug.print("{} runs in {d:.1} s: avg {d:.4} ns\n", .{ runs, run_time_secs, avg });
}
