const std = @import("std");

const Item = struct {
    name: []const u8,
};

pub const DirItem = struct {
    full: []const u8,
    dir_name: []const u8,
    part: []const u8,
    dir: std.fs.Dir,
    kind: std.fs.File.Kind,
};

pub fn dir_scan(dir: std.fs.Dir, alloc: std.mem.Allocator, callable: anytype) !void {
    var stack = std.ArrayList(Item).init(alloc);
    defer {
        for (stack.items) |i| {
            alloc.free(i.name);
        }
        stack.deinit();
    }
    {
        const name = try alloc.dupe(u8, ".");
        errdefer alloc.free(name);
        try stack.append(Item{ .name = name });
    }
    {
        try callable.callback(.{
            .full = ".",
            .dir_name = ".",
            .part = ".",
            .dir = dir,
            .kind = .directory,
        });
    }
    var name_buf = std.ArrayList(u8).init(alloc);
    defer name_buf.deinit();
    while (stack.pop()) |item| {
        defer alloc.free(item.name);

        const sub_dir = try dir.openDir(item.name, .{ .iterate = true });
        var iter = sub_dir.iterate();
        while (try iter.next()) |dir_item| {
            name_buf.clearRetainingCapacity();
            try name_buf.writer().print("{s}/{s}", .{ item.name, dir_item.name });
            switch (dir_item.kind) {
                .directory => {
                    const name = try alloc.dupe(u8, name_buf.items);
                    errdefer alloc.free(name);
                    try stack.append(.{ .name = name });
                },
                else => {},
            }
            try callable.callback(.{
                .full = name_buf.items,
                .dir_name = item.name,
                .part = dir_item.name,
                .dir = dir,
                .kind = dir_item.kind,
            });
        }
    }
}
