const std = @import("std");
const mecha = @import("mecha");
const input = @embedFile("input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("part1: {}\n", .{try part1(allocator, input)});
    std.debug.print("part2: {}\n", .{try part2(allocator, input)});
}

const int3 = mecha.int(u32, .{
    .parse_sign = false,
    .base = 10,
    .max_digits = 3,
});
const mul = mecha.string("mul").discard();
const lparen = mecha.ascii.char('(').discard();
const rparen = mecha.ascii.char(')').discard();
const comma = mecha.ascii.char(',').discard();
const multiply = mecha.combine(.{ mul, lparen, int3, comma, int3, rparen });
const do = mecha.string("do()").discard();
const dont = mecha.string("don't()").discard();

fn part1(allocator: std.mem.Allocator, memory: []const u8) !u32 {
    var sum: u32 = 0;
    var rest = memory;

    while (true) {
        if (rest.len == 0) return sum;

        if (multiply.parse(allocator, rest)) |result| {
            rest = result.rest;
            sum += result.value[0] * result.value[1];
        } else |_| {
            rest = rest[1..];
        }
    }
}

fn part2(allocator: std.mem.Allocator, memory: []const u8) !u32 {
    var sum: u32 = 0;
    var enabled = true;
    var rest = memory;

    while (true) {
        if (rest.len == 0) return sum;

        if (multiply.parse(allocator, rest)) |result| {
            rest = result.rest;
            if (enabled) {
                sum += result.value[0] * result.value[1];
            }
            continue;
        } else |_| {}

        if (do.parse(allocator, rest)) |result| {
            rest = result.rest;
            enabled = true;
            continue;
        } else |_| {}

        if (dont.parse(allocator, rest)) |result| {
            rest = result.rest;
            enabled = false;
            continue;
        } else |_| {}

        rest = rest[1..];
    }
}
