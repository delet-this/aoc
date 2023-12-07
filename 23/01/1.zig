const std = @import("std");

pub fn isNum(char: u8) bool {
    return char >= '0' and char <= '9';
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
        for (line) |char| {
            if (isNum(char)) {
                chars[i] = char;
                i += 1;
                break;
            }
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
