const std = @import("std");
const Token = @import("tokenize.zig");

pub const Constant = union(enum) {
    number: i64,
};

pub const Variable = struct {
    name: []const u8,
};

pub const Operation = enum {
    add,
    subtract,
    multiple,
    divide,
};

pub const Action = union(enum) {
    constant: Constant,
    variable: Variable,
    operation: Operation,
};

pub const AST = struct {
    parent: Node,
    pub const Node = struct {
        action: Action,
        nodes: []const Node,
    };
    pub fn deinit(_: AST) void {}
};

const Test = AST{
    .parent = .{
        .action = .{ .operation = .add },
        .nodes = &.{},
    },
};

pub fn gen_ast(tokens: []const Token.Token, alloc: std.mem.Allocator) !AST {
    var count: usize = 0;
    while (count < tokens.len) : (count += 1) {
        const t = tokens[count];
        switch (t) {
            .number => |n| {
                std.log.err("{}", .{n});
            },
            else => {},
        }
    }
    _ = alloc;
    return error.TODO;
}
