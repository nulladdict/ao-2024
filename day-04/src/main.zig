const std = @import("std");
const input = @embedFile("input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var grid = Grid.init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var row = std.ArrayList(u8).init(allocator);
        try row.appendSlice(line);
        try grid.append(row);
    }

    std.debug.print("part1: {}\n", .{try part1(allocator, &grid)});
    std.debug.print("part2: {}\n", .{try part2(&grid)});
}

const Grid = std.ArrayList(std.ArrayList(u8));
const Point = std.meta.Tuple(&.{ i64, i64 });
const Word = [4]u8;
const XMAS: Word = .{ 'X', 'M', 'A', 'S' };
const SAMX: Word = .{ 'S', 'A', 'M', 'X' };

fn part1(allocator: std.mem.Allocator, grid: *Grid) !u32 {
    var count: u32 = 0;
    const width = grid.items[0].items.len;
    const height = grid.items.len;

    for (0..height) |y| {
        for (0..width) |x| {
            const p: Point = .{ @intCast(y), @intCast(x) };
            const words = try checkDimensions(allocator, grid, p);
            for (words.items) |word| {
                if (std.mem.eql(u8, &word, &XMAS) or std.mem.eql(u8, &word, &SAMX)) {
                    count += 1;
                }
            }
        }
    }

    return count;
}

fn get(T: anytype, slice: []T, index: i64) ?T {
    if (index >= 0 and index < slice.len) return slice[@intCast(index)];
    return null;
}

fn checkDimensions(allocator: std.mem.Allocator, grid: *Grid, p: Point) !std.ArrayList(Word) {
    const dimensions: [4][3]Point = .{
        .{ .{ 0, 1 }, .{ 0, 2 }, .{ 0, 3 } },
        .{ .{ 1, 0 }, .{ 2, 0 }, .{ 3, 0 } },
        .{ .{ 1, 1 }, .{ 2, 2 }, .{ 3, 3 } },
        .{ .{ -1, 1 }, .{ -2, 2 }, .{ -3, 3 } },
    };
    var res = std.ArrayList(Word).init(allocator);
    for (dimensions) |dimension| {
        var check = std.ArrayList(u8).init(allocator);
        try check.append(grid.items[@intCast(p[0])].items[@intCast(p[1])]);
        for (dimension) |d| {
            const dp: Point = .{ p[0] + d[0], p[1] + d[1] };
            if (get(std.ArrayList(u8), grid.items, dp[0])) |row| {
                if (get(u8, row.items, dp[1])) |cell| {
                    try check.append(cell);
                }
            }
        }
        if (check.items.len == 4) {
            const word: Word = check.items[0..4].*;
            try res.append(word);
        }
    }
    return res;
}

fn part2(grid: *Grid) !u32 {
    var count: u32 = 0;
    const check: u8 = 'M' + 'S';
    const width = grid.items[0].items.len;
    const height = grid.items.len;

    for (0..height - 2) |y| {
        for (0..width - 2) |x| {
            if (grid.items[y + 1].items[x + 1] != 'A') continue;
            const d1 = grid.items[y].items[x] + grid.items[y + 2].items[x + 2];
            const d2 = grid.items[y + 2].items[x] + grid.items[y].items[x + 2];
            if (d1 == check and d2 == check) {
                count += 1;
            }
        }
    }

    return count;
}
