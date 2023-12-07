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
        _ = id;
        var idChars = [_]u8{ 0, 0, 0 };
        _ = idChars;
        var idDigits: usize = 0;
        _ = idDigits;

        // Find id
        var c_i: usize = 0;
        while (c_i < line.len) {
            var char: u8 = line[c_i];
            c_i += 1;
            if (char == ':') {
                break;
            }
        }

        var winningNums = [_]u8{0} ** 10;
        var winningNums_i: usize = 0;
        var cardPoints: i32 = 0;
        var curNum: [2]u8 = undefined;
        var curNumI: usize = 0;

        var results = true;
        // Check if game possible
        while (c_i < line.len) {
            defer c_i += 1;
            const char: u8 = line[c_i];
            if (results) {
                if (char == '|') {
                    results = false;
                    curNumI = 0;
                    continue;
                } else if (isNum(char)) {
                    curNum[curNumI] = char;
                    curNumI += 1;
                    if (curNumI == 2 or !isNum(line[c_i + 1])) {
                        const w = try std.fmt.parseInt(u8, curNum[0..curNumI], 10);
                        std.debug.print("winning: {}\n", .{w});
                        winningNums[winningNums_i] = w;
                        winningNums_i += 1;
                        curNumI = 0;
                    }
                }
            } else {
                if (isNum(char)) {
                    curNum[curNumI] = char;
                    curNumI += 1;
                    var testt: bool = c_i == line.len - 1;
                    if (!testt)
                        testt = !isNum(line[c_i + 1]);
                    if (curNumI == 2 or testt) {
                        const t = try std.fmt.parseInt(u8, curNum[0..curNumI], 10);
                        for (winningNums[0..winningNums_i]) |w| {
                            // std.debug.print("{} vs {}\n", .{ w, t });
                            if (w == t) {
                                cardPoints = if (cardPoints == 0) 1 else cardPoints * 2;
                                std.debug.print("cp {}\n", .{cardPoints});
                                break;
                            }
                        }
                        curNumI = 0;
                    }
                }
            }
        }

        sum += cardPoints;
    }
    std.debug.print("{}\n", .{sum});
}
