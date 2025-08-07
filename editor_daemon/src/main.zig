const std = @import("std");
const GlobalContext = @import("GlobalContext.zig");
const DirScan = @import("DirScan.zig");
pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const dc = DirCallback{
        .ion = try std.posix.inotify_init1(0),
    };
    defer std.posix.close(dc.ion);
    try DirScan.dir_scan(
        std.fs.cwd(),
        alloc,
        dc,
    );
}

const DirCallback = struct {
    ion: i32,
    pub fn callback(self: DirCallback, file: DirScan.DirItem) !void {
        try std.posix.inotify_add_watch(self.ion, file.full, 
        std.log.info("File:`{s}` `{s}`", .{ file.dir_name, file.part });
    }
};
