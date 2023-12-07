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
    const MS_IN_SEC = 1_000_000_000;
    const RUN_TIME = MS_IN_SEC * 10;

    var total_timer = try Timer.start();
    while (total_timer.read() <= RUN_TIME) {
        const MAX_SEED_RANGES = 600;
        var s_ranges = [_]SeedRange{.{ .start = 0, .end = 0 }} ** MAX_SEED_RANGES;
        var s_i: usize = 0;
        var num_chars = [_]u8{0} ** 10;
        var num_chars_i: usize = 0;
        // Inidices of seed ranges already mapped for the current map
        var mapped = StaticBitSet(MAX_SEED_RANGES).initEmpty();

        // Get seeds
        {
            var range_length = false;
            for (input[0]) |char| {
                if (isDigit(char)) {
                    num_chars[num_chars_i] = char;
                    num_chars_i += 1;
                } else if (num_chars_i > 0) {
                    const n = parseUnsignedUnsafe(u64, num_chars[0..num_chars_i]);
                    // Range length
                    if (range_length) {
                        s_ranges[s_i].end = s_ranges[s_i].start + n - 1;
                        s_i += 1;
                    }
                    // Range start
                    else {
                        s_ranges[s_i].start = n;
                    }
                    num_chars_i = 0;
                    range_length = !range_length;
                }
            }
        }

        assert(s_i != 0);

        for (input[1..input.len]) |line| {
            if (line.len <= 2 or line[0] == '\n') continue;

            // Map header row
            if (!isDigit(line[0])) {
                // New map, reset 'mapped' ranges
                mapped = StaticBitSet(MAX_SEED_RANGES).initEmpty();
                continue;
            }

            // Map seeds
            var mapping: [3]u64 = undefined;
            var map_i: usize = 0;
            var char_i: usize = 0;
            while (char_i < line.len and map_i != 3) : (char_i += 1) {
                const char = line[char_i];
                if (isDigit(char)) {
                    num_chars[num_chars_i] = char;
                    num_chars_i += 1;
                } else if (num_chars_i > 0) {
                    mapping[map_i] = parseUnsignedUnsafe(u64, num_chars[0..num_chars_i]);
                    map_i += 1;
                    num_chars_i = 0;
                }
            }

            const dest_start: u64 = mapping[0];
            const source_start: u64 = mapping[1];
            const range_len: u64 = mapping[2];
            var n_i: usize = 0;
            while (n_i < s_i) : (n_i += 1) {
                // Already mapped using this map
                if (mapped.isSet(n_i)) continue;
                const seed = s_ranges[n_i];
                const seed_end = seed.end;
                const source_end = source_start + range_len - 1;
                // Seed equal or subset of src
                if (source_start <= seed.start and source_end >= seed_end) {
                    s_ranges[n_i].map(source_start, dest_start);
                    mapped.set(n_i);
                }
                // Leftover seeds on left
                else if (seed.start < source_start and source_start <= seed.end and seed.end <= source_end) {
                    s_ranges[n_i].start = source_start;
                    s_ranges[n_i].end = seed.end;
                    s_ranges[n_i].map(source_start, dest_start);
                    mapped.set(n_i);
                    s_ranges[s_i].start = seed.start;
                    s_ranges[s_i].end = source_start - 1;
                    s_i += 1;
                }
                // Leftover seeds on right
                else if (source_start <= seed.start and seed.start <= source_end and source_end < seed.end) {
                    s_ranges[n_i].start = seed.start;
                    s_ranges[n_i].end = source_end;
                    s_ranges[n_i].map(source_start, dest_start);
                    mapped.set(n_i);
                    s_ranges[s_i].start = source_end + 1;
                    s_ranges[s_i].end = seed.end;
                    s_i += 1;
                }
                // Both
                else if (seed.start < source_start and source_start <= source_end and source_end <= seed.end) {
                    s_ranges[n_i].start = source_start;
                    s_ranges[n_i].end = source_end;
                    s_ranges[n_i].map(source_start, dest_start);
                    mapped.set(n_i);
                    s_ranges[s_i].start = seed.start;
                    s_ranges[s_i].end = source_start - 1;
                    s_i += 1;
                    s_ranges[s_i].start = source_end + 1;
                    s_ranges[s_i].end = seed.end;
                    s_i += 1;
                }
            }
        }

        var min: u64 = s_ranges[0].start;
        for (s_ranges[1..s_i]) |s| {
            if (s.start < min) {
                min = s.start;
            }
        }
        // print("Second part: {}\n", .{min});
        runs += 1;
    }

    const avg = RUN_TIME / runs;
    const run_time_secs = @as(f32, @floatFromInt(RUN_TIME)) / MS_IN_SEC;
    print("{} runs in {d:.1} s: avg {d:.4} ns\n", .{ runs, run_time_secs, avg });
}
