const std = @import("std");
const calc = @import("calc");
const VM = @import("VM.zig");
const ReadLine = @import("read_line.zig").ReadLine;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var vm = VM.VM.init(alloc);
    defer vm.deinit();
    try vm.set("thing", .{ .int = 123 });

    var rl = ReadLine.init(alloc);
    defer rl.deinit();
    var input = std.ArrayList(u8).init(alloc);
    defer input.deinit();

    try rl.read(&input);
    std.log.info("Input: [{s}]", .{input.items});
    const val = try vm.exec(input.items);
    std.log.err("{}", .{val});
}
