const std = @import("std");

pub const RunInfo = struct {
    in: *std.Io.Reader,
    err: *std.Io.Writer,
    out: *std.Io.Writer,
    args: []const [:0]const u8,
    alloc: std.mem.Allocator,
};

pub const Program = struct {
    name: []const u8,

    func: *const fn (info: RunInfo) anyerror!void,
};
