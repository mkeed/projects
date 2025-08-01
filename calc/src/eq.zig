const std = @import("std");
const ast = @import("ast.zig");
const tokenize = @import("tokenize.zig");

pub const Exec = struct {
    pub fn deinit(self: Exec) void {
        _ = self;
    }
};

pub fn compile(eq: []const u8, alloc: std.mem.Allocator) !Exec {
    var tokens = std.ArrayList(tokenize.Token).init(alloc);
    defer tokens.deinit();
    try tokenize.tokenize(eq, &tokens);
    const tree = try ast.gen_ast(tokens.items, alloc);
    defer tree.deinit();
    std.log.err("{f}", .{tree});
    return error.TODO;
}
