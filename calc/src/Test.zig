const std = @import("std");
const tokenize = @import("tokenize.zig");
const AST = @import("ast.zig");
const Token = tokenize.Token;

const TestCase = struct {
    input: []const u8,
    tokens: []const Token,
    ast: AST.AST,
};

const tcs = [_]TestCase{
    .{
        .input = "1 + 2;",
        .tokens = &.{
            .{ .number = .{ .whole = "1", .frac = null } },
            .{ .operator = .add },
            .{ .number = .{ .whole = "2", .frac = null } },
            .{ .syntax = .semiColon },
        },
        .ast = .{
            .parent = .{
                .action = .{ .operation = .add },
                .nodes = &.{
                    .{
                        .action = .{ .constant = .{ .number = 1 } },
                        .nodes = &.{},
                    },
                    .{
                        .action = .{ .constant = .{ .number = 2 } },
                        .nodes = &.{},
                    },
                },
            },
        },
    },
    .{
        .input = "const len 1.123 + 2.321;",
        .tokens = &.{
            .{ .decl = .@"const" },
            .{ .identifier = "len" },
            .{ .number = .{ .whole = "1", .frac = "123" } },
            .{ .operator = .add },
            .{ .number = .{ .whole = "2", .frac = "321" } },
            .{ .syntax = .semiColon },
        },
        .ast = .{
            .parent = .{
                .action = .{ .operation = .add },
                .nodes = &.{
                    .{
                        .action = .{ .constant = .{ .number = 1 } },
                        .nodes = &.{},
                    },
                    .{
                        .action = .{ .constant = .{ .number = 2 } },
                        .nodes = &.{},
                    },
                },
            },
        },
    },
};

test {
    var token_list = std.ArrayList(Token).init(std.testing.allocator);
    defer token_list.deinit();
    for (tcs) |tc| {
        token_list.clearRetainingCapacity();
        {
            try tokenize.tokenize(tc.input, &token_list);
            errdefer {
                for (tc.tokens, 0..) |i, idx| {
                    std.log.err("Expected[{}] => ({f})", .{ idx, i });
                }
                for (token_list.items, 0..) |i, idx| {
                    std.log.err("Found[{}] => ({f})", .{ idx, i });
                }
            }
            try std.testing.expectEqualDeep(tc.tokens, token_list.items);
        }
        const ast = try AST.gen_ast(token_list.items, std.testing.allocator);
        defer ast.deinit();
        //
    }
}
