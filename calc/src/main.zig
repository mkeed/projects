const std = @import("std");
const calc = @import("calc");
const VM = @import("VM.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var vm = VM.VM.init(alloc);
    defer vm.deinit();
    try vm.set("thing", .{ .int = 123 });

    const val = try vm.exec("1 + 1 + 2 + 3 + 4 + 4");
    std.log.err("{}", .{val});
}
