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
    const MAX_WIDTH = 250;
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
    _ = total_timer;
    var aa = true;
    // while (total_timer.read() <= RUN_TIME) {
    while (aa) {
        aa = false;
        // Keeps track of how many copies of each card there are
        var nums = [_]u64{0} ** 20;
        var nums_i: usize = 0;
        var num_chars = [_]u8{0} ** 10;
        var num_chars_i: usize = 0;
        var got_seeds = false;
        var mapped = StaticBitSet(25).initEmpty();
        for (input, 0..) |line, i| {
            _ = i;
            if (line.len <= 2 or line[0] == '\n')
                continue;

            // Skip to "Card 1: ..."
            //                ^
            var char_i: usize = 0;
            if (!isDigit(line[0])) {
                mapped = StaticBitSet(25).initEmpty();
                // if (i > 3)
                //     total_mapped = mapped_this_map;
                // mapped_this_map = StaticBitSet(20).initEmpty();
                // std.debug.print("{s}\n", .{line});
                // std.debug.print("{c}\n", .{line[char_i]});
                // std.debug.print("{}\n", .{i});
                while (char_i < line.len and line[char_i] != ':') {
                    // std.debug.print("skipping {}\n", .{line[char_i]});
                    char_i += 1;
                }
                if (char_i == line.len) continue;
                char_i += 1;
            }

            // Find seeds
            if (!got_seeds) {
                std.debug.print("yea\n", .{});
                while (char_i < line.len) {
                    defer char_i += 1;
                    const char = line[char_i];
                    if (isDigit(char)) {
                        num_chars[num_chars_i] = char;
                        num_chars_i += 1;
                    } else {
                        if (num_chars_i > 0) {
                            nums[nums_i] = parseUnsignedUnsafe(u32, num_chars[0..num_chars_i]);
                            std.debug.print("adding seed {}\n", .{nums[nums_i]});
                            nums_i += 1;
                            num_chars_i = 0;
                        }
                    }
                }
                got_seeds = true;
            } else {
                // Map seeds
                var source_start: u64 = 0;
                var source_found = false;
                var dest_start: u64 = 0;
                var dest_found = false;
                var range: u64 = 0;
                var range_found = false;
                while (char_i < line.len) {
                    defer char_i += 1;
                    const char = line[char_i];
                    if (isDigit(char)) {
                        num_chars[num_chars_i] = char;
                        num_chars_i += 1;
                    } else {
                        if (num_chars_i > 0) {
                            const new_num = parseUnsignedUnsafe(u64, num_chars[0..num_chars_i]);
                            if (!dest_found) {
                                dest_start = new_num;
                                dest_found = true;
                            } else if (!source_found) {
                                source_start = new_num;
                                source_found = true;
                            } else if (!range_found) {
                                range = new_num;
                                range_found = true;
                            }
                            num_chars_i = 0;
                        }
                    }
                }
                if (source_found and dest_found and range_found) {
                    for (nums[0..nums_i], 0..) |n, n_i| {
                        if (n >= source_start and n <= source_start + range - 1 and !mapped.isSet(n_i)) {
                            mapped.set(n_i);
                            const dest = dest_start + (n - source_start);
                            std.debug.print("src {} dest {} range {}\n", .{ source_start, dest_start, range });
                            std.debug.print("Mapping {} to {}\n", .{ nums[n_i], dest });
                            nums[n_i] = dest;
                        }
                    }
                }
            }
        }

        var min: u64 = nums[0];
        for (nums[1..nums_i]) |n| {
            if (n < min) {
                min = n;
            }
        }
        std.debug.print("First part: {}\n", .{min});

        // std.debug.print("First part: {}\n", .{sum_a});
        // std.debug.print("Second part: {}\n", .{sum_b});
        runs += 1;
        time_i += 1;
    }

    const avg = RUN_TIME / runs;
    const run_time_secs = @as(f32, @floatFromInt(RUN_TIME)) / MS_IN_SEC;
    std.debug.print("{} runs in {d:.1} s: avg {d:.4} ns\n", .{ runs, run_time_secs, avg });
}
