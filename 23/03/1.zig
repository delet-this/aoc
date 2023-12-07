const std = @import("std");
const IntegerBitSet = std.bit_set.IntegerBitSet;

fn Coords(comptime T: type, comptime size: usize) type {
    return struct {
        x: [size]T,
        y: [size]T,
    };
}

pub fn isNum(char: u8) bool {
    return char >= '0' and char <= '9';
}

pub fn main() anyerror!void {
    const ENGINE_MAX_WIDTH = 140;
    const ENGINE_MAX_HEIGHT = 140;
    var height: usize = 0;
    var width: usize = 0;
    var schematic: [ENGINE_MAX_WIDTH][ENGINE_MAX_HEIGHT]u8 = undefined;
    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();
        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            defer height += 1;
            for (line, 0..) |char, i| {
                if (height == 0)
                    width += 1;
                schematic[height][i] = char;
            }
        }
    }

    const Coord = struct {
        x: i16,
        y: i16,
    };

    const neighbour_offsets = comptime Coords(i16, 8){
        .x = .{ -1, 0, 1, -1, 1, -1, 0, 1 },
        .y = .{ -1, -1, -1, 0, 0, 1, 1, 1 },
    };

    // xx
    // x123
    // xx
    const start_mask = comptime blk: {
        var tmp = IntegerBitSet(8).initEmpty();
        tmp.set(0);
        tmp.set(1);
        tmp.set(3);
        tmp.set(5);
        tmp.set(6);
        break :blk tmp;
    };

    //   x
    //  123
    //   x
    const mid_mask = comptime blk: {
        var tmp = IntegerBitSet(8).initEmpty();
        tmp.set(1);
        tmp.set(6);
        break :blk tmp;
    };

    //    xx
    //  123x
    //    xx
    const end_mask = comptime blk: {
        var tmp = IntegerBitSet(8).initEmpty();
        tmp.set(1);
        tmp.set(2);
        tmp.set(4);
        tmp.set(6);
        tmp.set(7);
        break :blk tmp;
    };

    const RUN_COUNT = 10_000;

    var times: [RUN_COUNT]u64 = undefined;
    var times_i: usize = 0;
    var timer = try std.time.Timer.start();
    for (0..RUN_COUNT) |_| {
        timer.reset();
        var num_digits: [3]u8 = undefined;
        var num_len: u8 = 0;
        var sum_b: i32 = 0;
        var sum_a: i32 = 0;
        var part_nums = comptime [_]u16{0} ** (ENGINE_MAX_WIDTH * ENGINE_MAX_HEIGHT);
        // Ids to tell numbers apart when they have the same value,
        // though the input data doesn't seem to have such a case...
        var part_num_ids = comptime [_]u16{0} ** (ENGINE_MAX_WIDTH * ENGINE_MAX_HEIGHT);
        var part_num_index: usize = 1;

        // Find part numbers
        for (schematic[0..height], 0..) |line, i| {
            var valid = false;
            for (line[0..width], 0..) |c, j| {
                if (isNum(line[j])) {
                    const is_end = (j == width - 1) or !isNum(line[j + 1]);
                    const is_start: bool = num_len == 0;
                    const is_mid = !is_start and !is_end;
                    for (neighbour_offsets.x, neighbour_offsets.y, 0..) |off_x, off_y, n_i| {
                        const p: Coord = Coord{ .x = @as(i16, @intCast(j)) + off_x, .y = @as(i16, @intCast(i)) + off_y };
                        // Out of bounds
                        if (p.x < 0 or p.x >= width or p.y < 0 or p.y >= height) continue;
                        if ((is_mid and mid_mask.isSet(n_i)) or (is_start and start_mask.isSet(n_i)) or (is_end and end_mask.isSet(n_i))) {
                            const neighbour_char = schematic[@intCast(p.y)][@intCast(p.x)];
                            if (!isNum(neighbour_char) and neighbour_char != '.') {
                                valid = true;
                                break;
                            }
                        }
                    }
                    num_digits[num_len] = c;
                    num_len += 1;

                    if (valid and is_end) {
                        const part_num = try std.fmt.parseInt(u16, num_digits[0..num_len], 10);
                        var x: isize = @intCast(j);
                        while (x >= j - (num_len - 1)) : (x -= 1) {
                            part_num_ids[i * width + @as(usize, @intCast(x))] = @as(u16, @intCast(part_num_index));
                            part_nums[i * width + @as(usize, @intCast(x))] = part_num;
                        }
                        part_num_index += 1;
                        sum_a += part_num;
                        num_len = 0;
                        valid = false;
                    }
                } else {
                    num_len = 0;
                    valid = false;
                }
            }
        }

        // Calculate gear ratios
        for (schematic[0..height], 0..) |line, i| {
            for (line[0..width], 0..) |c, j| {
                if (c == '*') {
                    var to_multiply: [2]i32 = undefined;
                    var mul_ids: [2]u16 = undefined;
                    var mul_len: usize = 0;
                    for (neighbour_offsets.x, neighbour_offsets.y) |off_x, off_y| {
                        const p: Coord = Coord{ .x = @as(i16, @intCast(j)) + off_x, .y = @as(i16, @intCast(i)) + off_y };
                        // Out of bounds
                        if (p.x < 0 or p.x >= width or p.y < 0 or p.y >= height) continue;
                        const p_id = part_num_ids[@as(usize, @intCast(p.y)) * width + @as(usize, @intCast(p.x))];
                        if (p_id != 0 and mul_ids[0] != p_id and mul_ids[1] != p_id) {
                            to_multiply[mul_len] = part_nums[@as(usize, @intCast(p.y)) * width + @as(usize, @intCast(p.x))];
                            mul_ids[mul_len] = p_id;
                            mul_len += 1;
                            if (mul_len == 2) {
                                sum_b += to_multiply[0] * to_multiply[1];
                                break;
                            }
                        }
                    }
                }
            }
        }
        times[times_i] = timer.read();
        times_i += 1;
        // std.debug.print("{}\n", .{sum_a});
        // std.debug.print("{}\n", .{sum_b});
    }

    var sum: u64 = 0;
    for (times) |time| {
        sum += time;
    }
    const avg = sum / 10000;
    std.debug.print("{} runs: avg {d:.3} ms, total {d:.3} ms\n", .{ RUN_COUNT, @as(f32, @floatFromInt(avg)) / 1_000_000, @as(f32, @floatFromInt(sum)) / 1_000_000 });
}
