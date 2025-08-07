const std = @import("std");
const EditorContext = @import("EditorContext.zig");
const concurrent = @import("concurrent.zig");

pub const GlobalContext = struct {
    alloc: std.mem.Allocator,
    editors: concurrent.List(EditorContext),

    pub fn init(alloc: std.mem.Allocator) GlobalContext {
        return .{
            .alloc = alloc,
            .editors = concurrent.List(EditorContext).init(alloc),
        };
    }
};
