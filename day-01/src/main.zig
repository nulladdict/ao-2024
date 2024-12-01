const std = @import("std");
const input = @embedFile("input.txt");

pub fn main() !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var xs = std.ArrayList(i32).init(allocator);
    defer xs.deinit();
    var ys = std.ArrayList(i32).init(allocator);
    defer ys.deinit();

    while (lines.next()) |line| {
        var nums = std.mem.tokenizeScalar(u8, line, ' ');
        try xs.append(try std.fmt.parseInt(i32, nums.next().?, 10));
        try ys.append(try std.fmt.parseInt(i32, nums.next().?, 10));
    }
    std.mem.sort(i32, xs.items[0..], {}, std.sort.asc(i32));
    std.mem.sort(i32, ys.items[0..], {}, std.sort.asc(i32));

    std.debug.print("part1: {}\n", .{try part1(&xs, &ys)});
    std.debug.print("part2: {}\n", .{try part2(&xs, &ys)});
}

fn part1(xs: *std.ArrayList(i32), ys: *std.ArrayList(i32)) !u32 {
    var sum: u32 = 0;
    for (xs.items, ys.items) |x, y| {
        sum += @abs(x - y);
    }
    return sum;
}

fn part2(xs: *std.ArrayList(i32), ys: *std.ArrayList(i32)) !u32 {
    var sum: u32 = 0;
    for (xs.items) |x| {
        var count: u32 = 0;
        for (ys.items) |y| {
            if (x == y) {
                count += 1;
            }
        }
        sum += @as(u32, @intCast(x)) * count;
    }
    return sum;
}
