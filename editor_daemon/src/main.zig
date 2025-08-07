const std = @import("std");
const GlobalContext = @import("GlobalContext.zig");
const DirScan = @import("DirScan.zig");
pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    try DirScan.dir_scan(
        std.fs.cwd(),
        alloc,
        DirCallback{},
    );
}

const DirCallback = struct {
    pub fn callback(self: DirCallback, file: []const u8) !void {
        _ = self;
        std.log.info("File:{s}", .{file});
    }
};
