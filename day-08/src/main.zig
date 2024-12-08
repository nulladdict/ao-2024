const std = @import("std");
const input = @embedFile("input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.ArrayList([]u8).init(allocator);
    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (iter.next()) |line| {
        const owned = try allocator.dupe(u8, line);
        try lines.append(owned);
    }
    const grid = try lines.toOwnedSlice();

    std.debug.print("part1: {}\n", .{try part1(allocator, grid)});
    std.debug.print("part2: {}\n", .{try part2(allocator, grid)});
}

fn part1(allocator: std.mem.Allocator, grid: [][]u8) !u32 {
    const rows = grid.len;
    const cols = grid[0].len;
    const antennas = try getAntennas(allocator, grid);
    var antinodes = std.AutoHashMap(Point, void).init(allocator);

    for (antennas.items) |first| {
        for (antennas.items) |second| {
            if (std.meta.eql(first, second) or first.v != second.v) continue;

            const dr = second.r - first.r;
            const dc = second.c - first.c;

            const antinode: Point = .{
                .r = second.r + dr,
                .c = second.c + dc,
            };

            if ((antinode.r >= 0 and antinode.r < rows) and (antinode.c >= 0 and antinode.c < cols)) {
                try antinodes.put(antinode, {});
            }
        }
    }

    return antinodes.count();
}

const Antenna = struct {
    r: i32,
    c: i32,
    v: u8,
};

const Point = struct {
    r: i32,
    c: i32,
};

fn getAntennas(allocator: std.mem.Allocator, grid: [][]u8) !std.ArrayList(Antenna) {
    const rows = grid.len;
    const cols = grid[0].len;
    var antennas = std.ArrayList(Antenna).init(allocator);

    for (0..rows) |r| {
        for (0..cols) |c| {
            const v = grid[r][c];
            if (v != '.' and v != '#') {
                try antennas.append(
                    Antenna{
                        .r = @intCast(r),
                        .c = @intCast(c),
                        .v = grid[r][c],
                    },
                );
            }
        }
    }

    return antennas;
}

fn part2(allocator: std.mem.Allocator, grid: [][]u8) !u32 {
    const rows = grid.len;
    const cols = grid[0].len;
    const antennas = try getAntennas(allocator, grid);
    var antinodes = std.AutoHashMap(Point, void).init(allocator);

    for (antennas.items) |antenna| {
        try antinodes.put(Point{ .r = antenna.r, .c = antenna.c }, {});
    }

    for (antennas.items) |first| {
        for (antennas.items) |second| {
            if (std.meta.eql(first, second) or first.v != second.v) continue;

            const dr = second.r - first.r;
            const dc = second.c - first.c;

            var antinode: Point = .{
                .r = second.r + dr,
                .c = second.c + dc,
            };

            while (true) {
                if ((antinode.r >= 0 and antinode.r < rows) and (antinode.c >= 0 and antinode.c < cols)) {
                    try antinodes.put(antinode, {});
                    antinode.r += dr;
                    antinode.c += dc;
                } else {
                    break;
                }
            }
        }
    }

    return antinodes.count();
}
