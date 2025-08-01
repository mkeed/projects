const std = @import("std");

pub const Exec = struct {
    pub fn deinit(self: Exec) void {
        _ = self;
    }
};

pub fn compile(eq: []const u8, alloc: std.mem.Allocator) !Exec {
    _ = eq;
    _ = alloc;

    return error.TODO;
}
