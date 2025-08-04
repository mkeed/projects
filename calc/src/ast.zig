const std = @import("std");
const Token = @import("tokenize.zig");
const Value = @import("Value.zig").Value;
const VM = @import("VM.zig").VM;

pub const Constant = union(enum) {
    number: i64,
};

pub const Variable = struct {
    name: []const u8,
};

pub const Action = union(enum) {
    constant: Constant,
    variable: Variable,
    operation: Token.Operator,
    pub fn format(self: Action, writer: anytype) !void {
        switch (self) {
            .constant => |c| {
                try writer.print("(Constant:{})", .{c.number});
            },
            .variable => |v| {
                try writer.print("(Var:{s})", .{v.name});
            },
            .operation => |o| {
                try writer.print("({})", .{o});
            },
        }
    }
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
    pub fn toGraphViz(self: ASTGen, writer: anytype) !void {
        try writer.print("digraph mygraph {{", .{});
        for (self.nodes.items, 0..) |item, idx| {
            try writer.print("node_{}  [label = \"{f}\"]", .{ idx, item.action });
        }
        for (self.nodes.items, 0..) |item, idx| {
            if (item.childNodes) |children| {
                for (children) |c| {
                    try writer.print("node_{} -> node_{}\n", .{ idx, c });
                }
            }
        }
        try writer.print("}}", .{});
    }
    pub const Result = struct {
        value: Value,
    };
    pub fn walk(self: ASTGen, vm: *VM, node: usize) !Result {
        switch (self.nodes.items[node].action) {
            .constant => |c| return .{ .value = .{ .int = c.number } },
            .variable => |v| return .{
                .value = vm.get(v.name) orelse return error.InvalidVar,
            },
            .operation => |o| {
                const children = self.nodes.items[node].childNodes orelse return error.NeedChildren;
                if (children.len != 2) return error.ExpectedTwoChildren;
                const val1 = switch ((try self.walk(vm, children[0])).value) {
                    .int => |i| i,
                    else => return error.TODO,
                };
                const val2 = switch ((try self.walk(vm, children[1])).value) {
                    .int => |i| i,
                    else => return error.TODO,
                };

                return .{
                    .value = .{
                        .int = switch (o) {
                            .add => val1 + val2,
                            .sub => val1 - val2,
                            .div => @divTrunc(val1, val2),
                            .mul => val1 * val2,
                            .shl => val1 << @intCast(val2),
                            .shr => val1 >> @intCast(val2),
                        },
                    },
                };
            },
        }
    }
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
                    const nnode_id = switch (pp) {
                        .number => |nn| try ast.addNode(.{
                            .action = .{
                                .constant = .{ .number = try std.fmt.parseInt(i64, nn.whole, 0) },
                            },
                        }),
                        .identifier => |nn| try ast.addNode(.{
                            .action = .{
                                .variable = .{ .name = nn },
                            },
                        }),
                        else => {
                            return error.TODO;
                        },
                    };
                    var list = try ast.allocList(u64, 2);
                    list[0] = node_id;
                    list[1] = nnode_id;
                    ast.parent = try ast.addNode(.{
                        .action = .{ .operation = o },
                        .childNodes = list,
                    });
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
        const parent = ast.parent orelse return error.ExpectedParent;
        const nnode_id = switch (n) {
            .number => |nn| try ast.addNode(.{
                .action = .{
                    .constant = .{ .number = try std.fmt.parseInt(i64, nn.whole, 0) },
                },
            }),
            .identifier => |nn| try ast.addNode(.{
                .action = .{
                    .variable = .{ .name = nn },
                },
            }),
            else => {
                return error.TODO;
            },
        };
        var list = try ast.allocList(u64, 2);
        list[0] = parent;
        list[1] = nnode_id;
        ast.parent = try ast.addNode(.{
            .action = .{ .operation = t },
            .childNodes = list,
        });
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
