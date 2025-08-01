const std = @import("std");
const Token = @import("tokenize.zig");

pub const Constant = union(enum) {
    number: i64,
};

pub const Variable = struct {
    name: []const u8,
    constant: bool,
};

pub const Action = union(enum) {
    constant: Constant,
    variable: Variable,
    operation: Token.Operator,
};

pub const AST = struct {
    parent: Node,
    pub const Node = struct {
        action: Action,
        nodes: []const Node,
    };
    pub fn deinit(_: AST) void {}
};

pub const ASTGen = struct {
    pub const Node = struct {
        action: Action,
        childNodes: ?[]const u64 = null,
    };
    arena: std.heap.ArenaAllocator,
    nodes: std.ArrayList(Node),
    parent: ?usize,
    pub fn init(alloc: std.mem.Allocator) ASTGen {
        return .{
            .arena = std.heap.ArenaAllocator.init(alloc),
            .nodes = std.ArrayList(Node).init(alloc),
            .parent = null,
        };
    }
    pub fn addNode(self: *ASTGen, node: Node) !usize {
        const id = self.nodes.items.len;
        try self.nodes.append(node);
        return id;
    }
    pub fn allocList(self: *ASTGen, comptime T: type, len: u64) ![]T {
        const alloc = self.arena.allocator();
        return try alloc.alloc(T, len);
    }
    pub fn deinit(self: ASTGen) void {
        self.arena.deinit();
        self.nodes.deinit();
    }
    pub fn format(self: ASTGen, writer: *std.Io.Writer) !void {
        if (self.parent) |p| {
            try writer.print("Parent:[{}]", .{p});
        }
        for (self.nodes.items, 0..) |i, idx| {
            try writer.print("[{}]{}\n", .{ idx, i });
        }
    }
};

const Test = AST{
    .parent = .{
        .action = .{ .operation = .add },
        .nodes = &.{},
    },
};

const Iter = struct {
    tokens: []const Token.Token,
    idx: usize = 0,
    pub fn next(self: *Iter) ?Token.Token {
        if (self.idx >= self.tokens.len) return null;
        defer self.idx += 1;
        return self.tokens[self.idx];
    }
    pub fn peek(self: Iter) ?Token.Token {
        if (self.idx >= self.tokens.len) return null;

        return self.tokens[self.idx];
    }
};

fn number(ast: *ASTGen, iter: *Iter, n: Token.NumberToken) !void {
    const node_id = try ast.addNode(.{
        .action = .{
            .constant = .{ .number = try std.fmt.parseInt(i64, n.whole, 0) },
        },
    });
    std.log.err("{f}", .{n});
    if (iter.next()) |p| {
        switch (p) {
            .operator => |o| {
                if (iter.next()) |pp| {
                    switch (pp) {
                        .number => |nn| {
                            const nnode_id = try ast.addNode(.{
                                .action = .{
                                    .constant = .{ .number = try std.fmt.parseInt(i64, nn.whole, 0) },
                                },
                            });
                            var list = try ast.allocList(u64, 2);
                            list[0] = node_id;
                            list[1] = nnode_id;
                            ast.parent = try ast.addNode(.{
                                .action = .{ .operation = o },
                                .childNodes = list,
                            });
                        },
                        else => {
                            return error.TODO;
                        },
                    }
                }
            },
            else => {
                return error.TODO;
            },
        }
    }
}

fn operator(ast: *ASTGen, iter: *Iter, t: Token.Operator) !void {
    if (iter.next()) |n| {
        switch (n) {
            .number => |num| {
                const parent = ast.parent orelse return error.ExpectedParent;
                const nnode_id = try ast.addNode(.{
                    .action = .{
                        .constant = .{ .number = try std.fmt.parseInt(i64, num.whole, 0) },
                    },
                });
                var list = try ast.allocList(u64, 2);
                list[0] = parent;
                list[1] = nnode_id;
                ast.parent = try ast.addNode(.{
                    .action = .{ .operation = t },
                    .childNodes = list,
                });
            },
            else => {
                return error.UnexpectedSymbol;
            },
        }
    } else {
        return error.UnexpectedEnd;
    }
}

pub fn gen_ast(tokens: []const Token.Token, alloc: std.mem.Allocator) !ASTGen {
    var iter = Iter{ .tokens = tokens };
    var ast = ASTGen.init(alloc);
    errdefer ast.deinit();
    errdefer std.log.err("{f}", .{ast});
    var parent: ?u64 = null;
    while (iter.next()) |t| {
        errdefer std.log.err("TODO {f}", .{t});
        switch (t) {
            .number => |n| {
                try number(&ast, &iter, n);
            },
            .decl => |d| {
                switch (d) {
                    .@"var", .@"const" => {
                        const is_const = d == .@"const";
                        const ident = switch (iter.next() orelse return error.InvalidSyntax) {
                            .identifier => |i| i,
                            else => return error.ExpectedIdentifier,
                        };
                        switch (iter.next() orelse return error.InvalidSntax) {
                            .syntax => |s| switch (s) {
                                .equal => {},
                                else => return error.ExpectedEqual,
                            },
                            else => {
                                std.log.err("{f}", .{iter.tokens[iter.idx]});
                                return error.BadSyntax;
                            },
                        }
                        _ = try ast.addNode(.{
                            .action = .{ .variable = .{
                                .name = ident,
                                .constant = is_const,
                            } },
                        });
                    },
                    .fun => {
                        return error.TODO;
                    },
                    .@"struct" => return error.UnexpectedStruct,
                    .@"union" => return error.UnexpectedUnion,
                }
            },
            .syntax => |s| {
                switch (s) {
                    .semiColon => parent = null,
                    .equal => return error.TODO,
                }
            },
            .operator => |o| try operator(&ast, &iter, o),
            else => {
                return error.TODO;
            },
        }
    }
    return ast;
}
