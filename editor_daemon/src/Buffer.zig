const std = @import("std");

pub const Action = union(enum) {
    insert: struct { pos: usize, data: []const u8 },
    delete: struct { pos: usize, len: usize },
    pub fn format(self: Action, io: *std.Io.Writer) !void {
        switch (self) {
            .insert => |i| try io.print("(Insert `{s}` @ {}", .{ i.data, i.pos }),
            .delete => |d| try io.print("(Delete {} @ {}", .{ d.len, d.pos }),
        }
    }
};

pub const GapBuffer = struct {
    data: std.ArrayList(u8),
    gap: struct { pos: usize, len: usize },
    const gap_size = 16;
    pub fn init(alloc: std.mem.Allocator) GapBuffer {
        return .{
            .data = std.ArrayList(u8).init(alloc),
            .gap = .{ .pos = 0, .len = 0 },
        };
    }

    pub fn deinit(self: GapBuffer) void {
        self.data.deinit();
    }
    pub fn size(self: GapBuffer) usize {
        return (self.data.len - self.gap_size);
    }

    fn move_gap(self: *GapBuffer, new_pos: usize) void {
        if (new_pos > self.gap.pos) {
            const move_len = (new_pos) - (self.gap.pos);
            const src = self.data.items[self.gap.pos + self.gap.len ..][0..move_len];
            const dest = self.data.items[self.gap.pos..][0..move_len];
            @memmove(dest, src);
        } else if (new_pos < self.gap.pos) {
            const move_len = self.gap.pos - new_pos;

            const src = self.data.items[new_pos..][0..move_len];
            const dest = self.data.items[self.gap.pos + self.gap.len - move_len ..][0..move_len];

            @memmove(dest, src);
        }

        self.gap.pos = new_pos;
    }

    pub fn do_action(self: *GapBuffer, action: Action) !void {
        switch (action) {
            .insert => |i| {
                if (i.data.len > self.gap.len) {
                    const needed_bytes = (i.data.len - self.gap.len) + gap_size;
                    try self.data.appendNTimes('x', needed_bytes);
                    //for (0..needed_bytes) |idx| {
                    //try self.data.append('A' + @as(u8, @intCast(idx % 26)));
                    //}
                    const src = self.data.items[self.gap.pos + self.gap.len ..][0..needed_bytes];
                    const dest = self.data.items[self.data.items.len - needed_bytes ..];
                    @memmove(
                        dest,
                        src,
                    );
                    self.gap.len += needed_bytes;
                }
                if (i.pos != self.gap.pos) {
                    self.move_gap(i.pos);
                }

                defer {
                    self.gap.pos += i.data.len;
                    self.gap.len -= i.data.len;
                }
                @memmove(self.data.items[self.gap.pos..][0..i.data.len], i.data);
            },
            .delete => |d| {
                const dest = self.data.items[d.pos .. self.data.items.len - d.len];
                const src = self.data.items[d.pos + d.len ..];
                @memmove(dest, src);
                self.data.shrinkRetainingCapacity(self.data.items.len - d.len);
            },
        }
    }
    pub fn format(self: GapBuffer, io: *std.Io.Writer) !void {
        try io.print("par1:[{}=>{}] part2:[{}=>{}]", .{
            0,
            self.gap.pos,
            self.gap.pos + self.gap.len,
            self.data.items.len,
        });
        try io.print("fmt (len:{} gap:{}=>{}", .{
            self.data.items.len,
            self.gap.pos,
            self.gap.len + self.gap.pos,
        });
        try io.print("{s}|{s})", .{
            self.data.items[0..self.gap.pos],
            self.data.items[self.gap.pos + self.gap.len ..],
        });
    }
};

test {
    var buf = GapBuffer.init(std.testing.allocator);
    defer buf.deinit();
    try buf.do_action(.{
        .insert = .{ .pos = 0, .data = "Hello World" },
    });

    try buf.do_action(.{
        .insert = .{ .pos = 5, .data = "Hello World" },
    });
    //try buf.do_action(.{ .delete = .{ .pos = 5, .len = 5 } });
    try buf.do_action(.{
        .insert = .{ .pos = 16, .data = "abcd" },
    });
}
