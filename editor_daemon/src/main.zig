const std = @import("std");
const GlobalContext = @import("GlobalContext.zig");
const DirScan = @import("DirScan.zig");
const FileNotify = @import("FileNotify.zig").FileNotify;

const EventLoop = @import("el.zig").EventLoop;
const ssh = @import("ssh.zig");

pub fn main() !void {
    try ssh.connect();
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var el = try EventLoop.init(alloc);
    defer el.deinit();
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
    try el.add(.{ .fileNotify = &notify }, notify.fd);

    try el.run();
}

const DirCallback = struct {
    notify: *FileNotify,
    pub fn callback(self: DirCallback, file: DirScan.DirItem) !void {
        try self.notify.add_watch(file.full);
        std.log.info("File:`{s}` `{s}`", .{ file.dir_name, file.part });
    }
};
