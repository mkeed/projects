const std = @import("std");
const ast = @import("ast.zig");
const tokenize = @import("tokenize.zig");
const VM = @import("VM.zig").VM;

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
    const file = try std.fs.cwd().createFile("Nodes.dot", .{ .truncate = true });
    defer file.close();
    try tree.toGraphViz(file.deprecatedWriter());
    var vm = VM.init(alloc);
    defer vm.deinit();
    const value = try tree.walk(&vm, tree.parent orelse return error.BadParent);
    std.log.err("{}", .{value});
    return error.TODO;
}
