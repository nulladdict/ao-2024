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
    const map = try lines.toOwnedSlice();

    std.debug.print("part1: {}\n", .{try part1(allocator, map)});
    std.debug.print("part2: {}\n", .{try part2(allocator, map)});
}

fn part1(allocator: std.mem.Allocator, map: [][]u8) !u32 {
    var walker = Walker.init(map);
    var grid = try Grid.init(allocator, map);
    var sum: u32 = 0;

    while (true) {
        if (grid.get(walker.x, walker.y) != 'x') {
            sum += 1;
            grid.set(walker.x, walker.y, 'x');
        }
        while (grid.ahead(&walker) == '#') {
            walker.turn();
        }
        if (grid.ahead(&walker) == null) {
            break;
        }
        walker.move();
    }

    return sum;
}

fn part2(allocator: std.mem.Allocator, map: [][]u8) !u32 {
    var arena: std.heap.ThreadSafeAllocator = .{ .child_allocator = allocator };
    defer arena.deinit();
    const alloc = arena.allocator();

    const cpus = std.Thread.getCpuCount() catch 1;
    var pool: std.Thread.Pool = undefined;
    try pool.init(std.Thread.Pool.Options{ .allocator = alloc, .n_jobs = @as(u32, @intCast(cpus)) });
    defer pool.deinit();

    var group: std.Thread.WaitGroup = undefined;
    group.reset();

    var sum = std.atomic.Value(u32).init(0);
    const shard_size = std.math.divCeil(usize, map.len, cpus) catch unreachable;
    var start: usize = 0;
    while (start < map.len) : (start += shard_size) {
        const end = start + shard_size;
        try pool.spawn(checkRangeY, .{ &group, &alloc, map, start, end, &sum });
    }
    pool.waitAndWork(&group);

    return sum.load(.seq_cst);
}

fn checkRangeY(group: *std.Thread.WaitGroup, allocator: *const std.mem.Allocator, map: [][]u8, start: usize, end: usize, sum: *std.atomic.Value(u32)) void {
    group.start();
    defer group.finish();

    for (start..end) |y| {
        for (0..map[0].len) |x| {
            var walker = Walker.init(map);
            var grid = Grid.init(allocator.*, map) catch unreachable;
            const xi = @as(i32, @intCast(x));
            const yi = @as(i32, @intCast(y));

            if (grid.get(xi, yi) != '.') continue;
            grid.set(xi, yi, '#');

            if (loops(allocator.*, &walker, &grid) catch unreachable) {
                _ = sum.fetchAdd(1, .seq_cst);
            }
        }
    }
}

fn loops(allocator: std.mem.Allocator, walker: *Walker, grid: *Grid) !bool {
    var seen = std.AutoHashMap(Walker, void).init(allocator);
    try seen.put(walker.*, {});

    while (true) {
        while (grid.ahead(walker) == '#') {
            walker.turn();
            if (seen.contains(walker.*)) return true;
            try seen.put(walker.*, {});
        }
        if (grid.ahead(walker) == null) {
            return false;
        }
        walker.move();
        if (seen.contains(walker.*)) return true;
        try seen.put(walker.*, {});
    }
}

const Grid = struct {
    map: [][]u8,
    len_x: usize,
    len_y: usize,

    pub fn init(allocator: std.mem.Allocator, map: [][]u8) !Grid {
        var lines = std.ArrayList([]u8).init(allocator);
        for (map) |line| {
            const owned = try allocator.dupe(u8, line);
            try lines.append(owned);
        }
        const copy = try lines.toOwnedSlice();

        return Grid{
            .map = copy,
            .len_y = copy.len,
            .len_x = copy[0].len,
        };
    }

    pub fn get(self: *Grid, x: i32, y: i32) ?u8 {
        if (y >= 0 and y < self.len_y and x >= 0 and x < self.len_x) {
            return self.map[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
        }
        return null;
    }

    pub fn set(self: *Grid, x: i32, y: i32, val: u8) void {
        if (y >= 0 and y < self.len_y and x >= 0 and x < self.len_x) {
            self.map[@as(usize, @intCast(y))][@as(usize, @intCast(x))] = val;
        } else {
            @panic("set out of bounds");
        }
    }

    pub fn ahead(self: *Grid, walker: *Walker) ?u8 {
        return self.get(walker.x + walker.dx, walker.y + walker.dy);
    }
};

const Walker = struct {
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,

    pub fn start(grid: [][]const u8) struct { x: i32, y: i32 } {
        const len_y = grid.len;
        const len_x = grid[0].len;
        for (0..len_y) |y| {
            for (0..len_x) |x| {
                if (grid[y][x] == '^') {
                    return .{ .x = @intCast(x), .y = @intCast(y) };
                }
            }
        }
        unreachable;
    }

    pub fn init(grid: [][]const u8) Walker {
        const s = Walker.start(grid);
        return Walker{ .x = s.x, .y = s.y, .dx = 0, .dy = -1 };
    }

    pub fn turn(self: *Walker) void {
        const tmp = self.dx;
        self.dx = -self.dy;
        self.dy = tmp;
    }

    pub fn move(self: *Walker) void {
        self.x += self.dx;
        self.y += self.dy;
    }
};
