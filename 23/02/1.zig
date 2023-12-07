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
        var idChars = [_]u8{ 0, 0, 0 };
        var idDigits: usize = 0;

        // Find id
        var c: usize = 0;
        while (c < line.len) {
            var char: u8 = line[c];
            c += 1;
            if (isNum(char)) {
                idChars[idDigits] = char;
                idDigits += 1;
            } else if (char == ':') {
                break;
            }
        }

        id = try std.fmt.parseInt(i32, idChars[0..idDigits], 10);

        const colors = [_]u8{ 'r', 'g', 'b' };
        const color_maxes = [_]i32{ 12, 13, 14 };
        var valChars = [_]u8{ 0, 0, 0 };
        var valDigits: usize = 0;

        // Check if game possible
        var possible: bool = true;
        var skipTilDelim: bool = false;
        while (c < line.len and possible) {
            var char: u8 = line[c];
            c += 1;
            if (skipTilDelim) {
                if (char == ',' or char == ';')
                    skipTilDelim = false;
            } else if (isNum(char)) {
                valChars[valDigits] = char;
                valDigits += 1;
            } else if (isAlpha(char)) {
                skipTilDelim = true;
                for (0..colors.len) |colori| {
                    if (colors[colori] == char) {
                        var parsed = try std.fmt.parseInt(i32, valChars[0..valDigits], 10);
                        if (color_maxes[colori] < parsed) {
                            possible = false;
                            break;
                        }
                    }
                }
                valDigits = 0;
            }
        }

        if (possible)
            sum += id;
    }
    std.debug.print("{}\n", .{sum});
}
