const std = @import("std");

pub fn isNum(char: u8) bool {
    return char >= '0' and char <= '9';
}

const nums = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

pub fn parseNum(buf: []const u8) i32 {
    var res: u16 = 0b111111111;
    var end = if (buf.len > 5) 5 else buf.len;
    for (0..end) |i| {
        for (0..nums.len) |j| {
            if (i < nums[j].len) {
                if (buf[i] != nums[j][i]) {
                    var tmp: u4 = @intCast(j);
                    res = res & ~(@as(u16, @intCast(1)) << tmp);
                }
            }
        }
    }
    var num: i32 = 1;
    while (res != 0 and num < 10) {
        if (res & 0b1 == 0b1 and nums[@as(usize, @intCast(num)) - 1].len <= buf.len) {
            return num;
        }
        res = res >> 1;
        num += 1;
    }
    return -1;
}

pub fn parseNumRev(buf: []const u8) i32 {
    var res: u16 = 0b111111111;
    var i: usize = if (buf.len > 5) 4 else buf.len - 1;
    while (i > 0) {
        i -= 1;
        for (0..nums.len) |j| {
            if (nums[j].len > i) {
                if (buf[buf.len - i - 1] != nums[j][nums[j].len - i - 1]) {
                    var tmp: u4 = @intCast(j);
                    res = res & ~(@as(u16, @intCast(1)) << tmp);
                }
            }
        }
    }
    var num: i32 = 1;
    while (res != 0 and num < 10) {
        if (res & 0b1 == 0b1 and nums[@as(usize, @intCast(num)) - 1].len <= buf.len) {
            return num;
        }
        res = res >> 1;
        num += 1;
    }
    return -1;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var sum: i32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var chars = [_]u8{ 0, 0 };
        var i: usize = 0;
        // Find first num
        var k: usize = 0;
        for (line) |char| {
            if (isNum(char)) {
                chars[i] = char;
                i += 1;
                break;
            } else if (line.len >= 3 and k < line.len - 3) {
                var end: usize = line.len;
                if (end - k > 5)
                    end = k + 5;
                var p = parseNum(line[k..(end)]);
                if (p > 0) {
                    var tmp: u8 = @intCast(p);
                    chars[i] = '0' + tmp;
                    i += 1;
                    break;
                }
            }
            k += 1;
        }

        var j: usize = line.len;
        // Find last num
        if (i != 0) {
            while (j > 0) {
                j -= 1;
                if (isNum(line[j])) {
                    chars[i] = line[j];
                    i += 1;
                    break;
                } else if (j >= 3) {
                    var start: usize = 0;
                    if (j - start > 5)
                        start = j - 5;
                    var p = parseNumRev(line[(start)..(j + 1)]);
                    if (p > 0) {
                        var tmp: u8 = @intCast(p);
                        chars[i] = '0' + tmp;
                        i += 1;
                        break;
                    }
                }
            }
        }

        // Found 2 nums
        if (i == 2) {
            var num = try std.fmt.parseInt(i32, &chars, 10);
            sum += num;
        }
    }
    std.debug.print("{}\n", .{sum});
}
