const std = @import("std");

const FileRef = struct {
    ref: i32,
    fileName: std.ArrayList(u8),
};

pub const FileNotify = struct {
    fd: i32,
    //dir: std.fs.Dir,
    files: std.ArrayList(FileRef),
    alloc: std.mem.Allocator,
    pub fn init(
        alloc: std.mem.Allocator,
        //dir: ?std.fs.Dir,
        //path: []const u8,
    ) !FileNotify {
        return .{
            .fd = try std.posix.inotify_init1(0),
            //.dir = if (dir) |d| try d.openDir(path, .{}) else try std.fs.openDirAbsolute(path, .{}),
            .files = std.ArrayList(FileRef).init(alloc),
            .alloc = alloc,
        };
    }
    pub fn deinit(self: *FileNotify) void {
        std.posix.close(self.fd);
        for (self.files.items) |i| i.fileName.deinit();
        self.files.deinit();
    }
    pub fn add_watch(self: *FileNotify, path: []const u8) !void {
        std.log.info("Path:[{s}]", .{path});
        var name = std.ArrayList(u8).init(self.alloc);
        errdefer name.deinit();
        const ref = std.posix.inotify_add_watch(self.fd, path, std.os.linux.IN.ALL_EVENTS) catch |err| {
            std.log.err("{}", .{err});
            return;
        };
        try name.appendSlice(path);
        try self.files.append(.{
            .ref = ref,
            .fileName = name,
        });
        std.log.info("Path:[{s}]|{}", .{ path, ref });
    }
    pub fn handle(self: *FileNotify) !void {
        var buf: [4096]u8 align(@alignOf(std.os.linux.inotify_event)) = std.mem.zeroes([4096]u8);
        const len = try std.posix.read(self.fd, &buf);
        var count: usize = 0;
        while (count <= len) {
            const ev: *std.os.linux.inotify_event = @alignCast(@ptrCast(buf[count..]));
            count += ev.len + @sizeOf(std.os.linux.inotify_event);
            if (ev.wd == 0) continue;
            const file = blk: {
                for (self.files.items) |*i| {
                    if (i.ref == ev.wd) {
                        break :blk i;
                    }
                }
                continue;
            };
            const et = @as(EventType, @bitCast(ev.mask));

            std.log.info("[{s}][{}]{}|{s}|{} |{f} ", .{
                file.fileName.items,
                ev.len,
                ev.*,
                ev.getName() orelse "none",
                len,
                et,
            });
            if (et.create) {
                if (ev.getName()) |n| {
                    try self.add_watch(n);
                }
            }
        }
    }
};

const EventType = packed struct(u32) {
    access: bool,
    modify: bool,
    atrib: bool,
    close_write: bool,
    close_nowrite: bool,
    open: bool,
    moved_from: bool,
    moved_to: bool,
    create: bool,
    delete: bool,
    delete_self: bool,
    move_self: bool,
    ignore: bool,
    unmount: bool,
    overflow: bool,
    ignored: bool,
    extra: u12,
    mask_create: bool,
    mask_add: bool,
    is_dir: bool,
    one_shot: bool,
    pub fn format(self: EventType, writer: *std.Io.Writer) !void {
        if (self.access) try writer.print("access ", .{});
        if (self.modify) try writer.print("modify ", .{});
        if (self.atrib) try writer.print("atrib ", .{});
        if (self.close_write) try writer.print("close_write ", .{});
        if (self.close_nowrite) try writer.print("close_nowrite ", .{});
        if (self.open) try writer.print("open ", .{});
        if (self.moved_from) try writer.print("moved_from ", .{});
        if (self.moved_to) try writer.print("moved_to ", .{});
        if (self.create) try writer.print("create ", .{});
        if (self.delete) try writer.print("delete ", .{});
        if (self.delete_self) try writer.print("delete_self ", .{});
        if (self.move_self) try writer.print("move_self ", .{});
        if (self.ignore) try writer.print("ignore ", .{});
        if (self.unmount) try writer.print("unmount ", .{});
        if (self.overflow) try writer.print("overflow ", .{});
        if (self.ignored) try writer.print("ignored ", .{});
        if (self.mask_add) try writer.print("mask_add ", .{});
        if (self.mask_create) try writer.print("mask_create ", .{});
        if (self.is_dir) try writer.print("is_dir ", .{});
        if (self.one_shot) try writer.print("oneshot ", .{});
        if (self.extra != 0) try writer.print("extra:{} ", .{self.extra});
    }
};
