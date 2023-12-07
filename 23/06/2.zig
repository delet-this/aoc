const std = @import("std");
const Timer = std.time.Timer;
const StaticBitSet = std.bit_set.StaticBitSet;
const isDigit = std.ascii.isDigit;
const print = std.debug.print;
const assert = std.debug.assert;

/// Maps a seed range from src to dest
const SeedRange = struct {
    start: u64,
    end: u64,
    pub fn map(self: *SeedRange, src: u64, dest: u64) void {
        const a = src < dest;
        self.start = if (a) self.start + (dest - src) else self.start - (src - dest);
        self.end = if (a) self.end + (dest - src) else self.end - (src - dest);
    }
};

// Bit faster than std lib's error checked one
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
    var width: usize = 0;
    var height: usize = 0;

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
    // const RUN_TIME = MS_IN_SEC * 10;
    const RUN_TIME = MS_IN_SEC * 10;

    var total_timer = try Timer.start();
    var w: f64 = 0;
    while (total_timer.read() <= RUN_TIME) {
        var in_race_dur: i64 = undefined;
        var in_dist_record: i64 = undefined;
        for (input[0..height], 0..) |line, line_i| {
            var char_i: usize = 0;
            while (line[char_i] != ':') {
                char_i += 1;
            }

            var cur_num: [255]u8 = undefined;
            var cur_num_i: usize = 0;

            while (char_i < width) {
                defer char_i += 1;
                const char: u8 = line[char_i];
                if (isDigit(char)) {
                    cur_num[cur_num_i] = char;
                    cur_num_i += 1;
                }
            }
            const n = parseUnsignedUnsafe(i64, cur_num[0..cur_num_i]);
            // Race durations row
            if (line_i == 0) {
                in_race_dur = n;
            }
            // Dists row
            else if (line_i == 1) {
                in_dist_record = n;
            }
        }

        // for (1..in_race_dur) |elapsed| {
        //     const mm_per_ms = elapsed;
        //     const race_left = in_race_dur - elapsed;
        //     const run_dist = race_left * mm_per_ms;
        //     if (run_dist > dist_record) {
        //         ways_to_win += 1;
        //     }
        // }

        {
            @setFloatMode(std.builtin.FloatMode.Optimized);
            // x: elapsed time
            // t: race duration
            // d: distance record
            // Solve `f(x) = x*t - x^2 = d` for x to get the limits for winning
            const r = @as(f64, @floatFromInt(in_dist_record));
            const d = @as(f64, @floatFromInt(in_race_dur));
            const root = @sqrt(d * d - 4 * r);
            var left_limit: f64 = (d - root) / 2;
            var right_limit: f64 = (d + root) / 2;
            // the limits are exclusive
            // round towards 'inside' the range, + 1 for integers
            right_limit = if (right_limit == @floor(right_limit)) right_limit - 1 else @floor(right_limit);
            left_limit = if (left_limit == @ceil(left_limit)) left_limit + 1 else @ceil(left_limit);
            w = right_limit - left_limit + 1;
        }
        runs += 1;
    }

    print("Second part: {d:.01}\n", .{@as(f64, @floatCast(w))});

    const avg = RUN_TIME / runs;
    const run_time_secs = @as(f64, @floatFromInt(RUN_TIME)) / MS_IN_SEC;
    print("{} runs in {d:.1} s: avg {d:.4} ns\n", .{ runs, run_time_secs, avg });
}
