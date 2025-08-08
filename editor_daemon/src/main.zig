const std = @import("std");
const GlobalContext = @import("GlobalContext.zig");
const DirScan = @import("DirScan.zig");
const FileNotify = @import("FileNotify.zig").FileNotify;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var notify = try FileNotify.init(
        alloc,
        //std.fs.cwd(),
        //".",
    );
    defer notify.deinit();

    try DirScan.dir_scan(
        std.fs.cwd(),
        alloc,
        DirCallback{ .notify = &notify },
    );
    for (0..20) |_| {
        var p = [1]std.posix.pollfd{
            .{ .fd = notify.fd, .events = std.posix.system.POLL.IN, .revents = 0 },
        };
        _ = try std.posix.poll(p[0..], -1);
        try notify.handle();
    }
}

const DirCallback = struct {
    notify: *FileNotify,
    pub fn callback(self: DirCallback, file: DirScan.DirItem) !void {
        try self.notify.add_watch(file.full);
        std.log.info("File:`{s}` `{s}`", .{ file.dir_name, file.part });
    }
};
