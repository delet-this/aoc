const std = @import("std");

pub fn isNum(char: u8) bool {
    return char >= '0' and char <= '9';
}

pub fn isAlpha(char: u8) bool {
    return char >= 'a' and char <= 'z';
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var sum: i32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var id: i32 = 0;
        const ID_MAX_LEN = 3;
        var idChars = [_]u8{0} ** ID_MAX_LEN;
        var idDigits: usize = 0;

        var iChar: usize = 0;
        // Find id
        while (iChar < line.len) {
            const char: u8 = line[iChar];
            defer iChar += 1;
            if (isNum(char)) {
                idChars[idDigits] = char;
                idDigits += 1;
            } else if (char == ':') {
                break;
            }
        }

        id = try std.fmt.parseInt(i32, idChars[0..idDigits], 10);

        const colors = [_]u8{ 'r', 'g', 'b' };
        var color_mins = [_]i32{0} ** 3;
        const CUBE_VAL_MAX_LEN = 3;
        var valChars = [_]u8{0} ** CUBE_VAL_MAX_LEN;
        var valDigits: usize = 0;

        // Find rgb mins
        var skipToDelim: bool = false;
        while (iChar < line.len) {
            const char: u8 = line[iChar];
            defer iChar += 1;
            if (skipToDelim) {
                skipToDelim = char != ',' and char != ';';
            } else if (isNum(char)) {
                valChars[valDigits] = char;
                valDigits += 1;
            } else if (isAlpha(char)) {
                skipToDelim = true;
                for (colors, 0..) |color, iCol| {
                    if (color == char) {
                        const parsed = try std.fmt.parseInt(i32, valChars[0..valDigits], 10);
                        if (color_mins[iCol] < parsed)
                            color_mins[iCol] = parsed;
                        break;
                    }
                }
                valDigits = 0;
            }
        }

        sum += color_mins[0] * color_mins[1] * color_mins[2];
    }
    std.debug.print("{}\n", .{sum});
}
