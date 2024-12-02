const std = @import("std");
const input = @embedFile("input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var reports = std.ArrayList(std.ArrayList(i32)).init(allocator);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }
        reports.deinit();
    }

    while (lines.next()) |line| {
        var levels = std.mem.tokenizeScalar(u8, line, ' ');
        var report = std.ArrayList(i32).init(allocator);
        while (levels.next()) |level| {
            try report.append(try std.fmt.parseInt(i32, level, 10));
        }
        try reports.append(report);
    }

    std.debug.print("part1: {}\n", .{try part1(&reports)});
    std.debug.print("part2: {}\n", .{try part2(&reports)});
}

fn part1(reports: *const std.ArrayList(std.ArrayList(i32))) !u32 {
    var count: u32 = 0;

    for (reports.items) |report| {
        if (isSafe(report.items)) {
            count += 1;
        }
    }

    return count;
}

fn isSafe(levels: []const i32) bool {
    const sign = std.math.sign(levels[1] - levels[0]);
    for (0..levels.len - 1) |i| {
        const diff = levels[i + 1] - levels[i];
        const s = std.math.sign(diff);
        const abs = @abs(diff);
        if (s != sign or abs > 3 or abs == 0) {
            return false;
        }
    }
    return true;
}

fn part2(reports: *const std.ArrayList(std.ArrayList(i32))) !u32 {
    var count: u32 = 0;

    for (reports.items) |report| {
        if (try isSafeWithoutOne(report)) {
            count += 1;
        }
    }

    return count;
}

fn isSafeWithoutOne(report: std.ArrayList(i32)) !bool {
    if (isSafe(report.items)) {
        return true;
    }

    for (0..report.items.len) |at| {
        const fixed = try without(&report, at);
        defer fixed.deinit();
        if (isSafe(fixed.items)) {
            return true;
        }
    }

    return false;
}

fn without(report: *const std.ArrayList(i32), at: usize) !std.ArrayList(i32) {
    var copy = try report.clone();
    _ = copy.orderedRemove(at);
    return copy;
}
