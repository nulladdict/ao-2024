const std = @import("std");
const input = @embedFile("input.txt");

const Rule = std.meta.Tuple(&.{ usize, usize });

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = std.mem.tokenizeSequence(u8, input, "\n\n");

    var rules = std.ArrayList(Rule).init(allocator);
    var ri = std.mem.tokenizeScalar(u8, it.next().?, '\n');
    while (ri.next()) |r| {
        var i = std.mem.tokenizeScalar(u8, r, '|');
        const left = try std.fmt.parseInt(usize, i.next().?, 10);
        const right = try std.fmt.parseInt(usize, i.next().?, 10);
        try rules.append(.{ left, right });
    }

    var updates = std.ArrayList([]usize).init(allocator);
    var ui = std.mem.tokenizeScalar(u8, it.next().?, '\n');
    while (ui.next()) |u| {
        var i = std.mem.tokenizeScalar(u8, u, ',');
        var nums = std.ArrayList(usize).init(allocator);
        while (i.next()) |n| {
            const num = try std.fmt.parseInt(usize, n, 10);
            try nums.append(num);
        }
        try updates.append(try nums.toOwnedSlice());
    }

    std.debug.print("part1: {}\n", .{try part1(&rules, &updates)});
    std.debug.print("part2: {}\n", .{try part2(&rules, &updates)});
}

fn part1(rules: *const std.ArrayList(Rule), updates: *const std.ArrayList([]usize)) !usize {
    var sum: usize = 0;

    for (updates.items) |update| {
        if (!isCorrect(rules, update)) continue;
        sum += middle(usize, update);
    }

    return sum;
}

fn isCorrect(rules: *const std.ArrayList(Rule), update: []usize) bool {
    for (rules.items) |rule| {
        const l = rule[0];
        const r = rule[1];
        const li = std.mem.indexOfScalar(usize, update, l) orelse continue;
        const ri = std.mem.indexOfScalar(usize, update, r) orelse continue;
        if (li > ri) return false;
    }
    return true;
}

fn middle(T: type, items: []const T) T {
    const index = if (items.len % 2 == 0) items.len / 2 - 1 else items.len / 2;
    return items[index];
}

fn part2(rules: *const std.ArrayList(Rule), updates: *const std.ArrayList([]usize)) !usize {
    var sum: usize = 0;

    for (updates.items) |update| {
        if (isCorrect(rules, update)) continue;
        var buffer = try std.BoundedArray(usize, 100).init(0);
        try buffer.appendSlice(update);
        std.sort.block(usize, buffer.slice(), rules, lessThan);
        sum += middle(usize, buffer.constSlice());
    }

    return sum;
}

fn lessThan(rules: *const std.ArrayList(Rule), a: usize, b: usize) bool {
    for (rules.items) |rule| {
        if (rule[0] == a and rule[1] == b) return true;
    }
    return false;
}
