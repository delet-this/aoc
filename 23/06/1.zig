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
    var in_times: [4]u32 = undefined;
    var times_i: usize = 0;
    var in_distances: [4]u32 = undefined;
    var dists_i: usize = 0;
    var ways_to_win = [_]u64{0} ** 4;

    const input: [MAX_HEIGHT][MAX_WIDTH]u8 = blk: {
        var width: usize = 0;
        var height: usize = 0;
        var tmp: [MAX_HEIGHT][MAX_WIDTH]u8 = undefined;
        var line_i: usize = 0;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            defer line_i += 1;
            var char_i: usize = 0;
            while (line[char_i] != ':')
                char_i += 1;

            var cur_num: [5]u8 = undefined;
            var cur_num_i: usize = 0;

            while (char_i < line.len) {
                defer char_i += 1;
                const char: u8 = line[char_i];
                if (char == '|') break;
                if (isDigit(char)) {
                    cur_num[cur_num_i] = char;
                    cur_num_i += 1;
                    if (char_i == line.len - 1 or !isDigit(line[char_i + 1])) {
                        const n = parseUnsignedUnsafe(u32, cur_num[0..cur_num_i]);
                        if (line_i == 0) {
                            in_times[times_i] = n;
                            times_i += 1;
                        } else if (line_i == 1) {
                            print("dist {}\n", .{n});
                            in_distances[dists_i] = n;
                            dists_i += 1;
                        }
                        cur_num_i = 0;
                    }
                }
            }
            cur_num_i = 0;

            if (height == 0) width = line.len;
            height += 1;
        }
        break :blk tmp;
    };
    _ = input;

    var runs: u64 = 0;
    const MS_IN_SEC = 1_000_000_000;
    const RUN_TIME = MS_IN_SEC * 10;

    var total_timer = try Timer.start();
    _ = total_timer;
    // while (total_timer.read() <= RUN_TIME) {
    for (0..times_i) |i| {
        print("Race {}\n", .{i});
        var mm_per_ms: u64 = 0;
        const dist_record = in_distances[i];
        for (0..in_times[i]) |elapsed| {
            if (elapsed >= 1)
                mm_per_ms += 1;
            const race_left = in_times[i] - elapsed;
            const run_dist = race_left * mm_per_ms;
            if (run_dist > dist_record) {
                print("win: {} * {} = {}\n", .{ race_left, mm_per_ms, run_dist });
                ways_to_win[i] += 1;
            }
        }
    }

    runs += 1;
    // }
    var res: u64 = 1;
    for (ways_to_win[0..times_i]) |w| {
        print("w: {}\n", .{w});
        res *= w;
    }
    print("Second part: {}\n", .{res});

    const avg = RUN_TIME / runs;
    const run_time_secs = @as(f32, @floatFromInt(RUN_TIME)) / MS_IN_SEC;
    print("{} runs in {d:.1} s: avg {d:.4} ns\n", .{ runs, run_time_secs, avg });
}
