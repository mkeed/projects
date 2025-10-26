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
    var input = std.ArrayList(u8).empty;
    defer input.deinit(alloc);
    const use_rl = false;
    const exp = blk: {
        if (use_rl) {
            try rl.read(&input);
            return input.items;
        } else {
            break :blk "thing(123)";
        }
    };
    std.log.info("Input: [{s}]", .{exp});
    const val = try vm.exec(exp);
    std.log.err("{}", .{val});
}
