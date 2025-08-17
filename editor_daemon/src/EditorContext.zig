const std = @import("std");
const String = @import("String.zig").String;
const GapBufer = @import("Buffer.zig").GapBuffer;

pub const BufferMode = struct {
    read_only: bool = false,
};

pub const Buffer = struct {
    data: GapBuffer,
    backing_file: ?String,
    mode: BufferMode,
};

pub const EditorContext = struct {
    alloc: std.mem.Allocator,
    dir: std.fs.Dir,
    buffers: std.ArrayList(Buffer),

    pub fn init(alloc: std.mem.Allocator, dir_path: []const u8) !EditorContext {
        const dir = try std.fs.openDirAbsolute(dir_path, .{});

        return EditorContext{
            .alloc = alloc,
            .dir = dir,
            .buffers = std.ArrayList(Buffer).init(alloc),
        };
    }
    pub fn deinit(self: EditorContext) void {
        self.dir.close();
        for (self.buffers.items) |i| i.deinit();
        self.buffers.deinit();
    }

    pub fn openFile(self: EditorContext, path: []const u8) !void {
        const file = self.dir.openFile(path, .{});
    }
};
