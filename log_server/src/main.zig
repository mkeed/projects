const std = @import("std");
const log_server = @import("log_server");
const Config = @import("Config.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    const file = try std.fs.cwd().readFileAlloc(alloc, "config.json", 100_000);
    defer alloc.free(file);
    const config = try std.json.parseFromSlice(Config.Config, alloc, file, .{});
    defer config.deinit();
}
