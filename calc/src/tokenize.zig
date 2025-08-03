const std = @import("std");
pub const Operator = enum { add, sub, div, mul, shl, shr };
pub const Decl = enum { @"const", @"var", fun, @"struct", @"union" };
pub const Syntax = enum { semiColon, equal };
pub const NumberToken = struct {
    whole: []const u8,
    frac: ?[]const u8,
    pub fn format(self: NumberToken, writer: *std.Io.Writer) !void {
        try writer.print("({s}", .{self.whole});
        if (self.frac) |f| {
            try writer.print(",{s}", .{f});
        }
        try writer.print(")", .{});
    }
};

pub const Token = union(enum) {
    operator: Operator,
    decl: Decl,
    syntax: Syntax,
    number: NumberToken,
    identifier: []const u8,
    string: []const u8,

    pub fn format(self: Token, writer: *std.Io.Writer) !void {
        switch (self) {
            .operator => |o| try writer.print("(Op: {}", .{o}),
            .decl => |d| try writer.print("(Decl :{})", .{d}),
            .syntax => |s| try writer.print("(Syntax :{})", .{s}),
            .number => |n| {
                try writer.print("(Num: {s}", .{n.whole});
                if (n.frac) |frac| {
                    try writer.print(".{s}", .{frac});
                }
                try writer.print(")", .{});
            },
            .string => |s| try writer.print("(string `{s}`)", .{s}),
            .identifier => |i| try writer.print("(identifier `{s}`)", .{i}),
        }
    }
};

const ops = [_]struct { val: []const u8, op: Operator }{
    .{ .val = "+", .op = .add },
    .{ .val = "-", .op = .sub },
    .{ .val = "/", .op = .div },
    .{ .val = "*", .op = .mul },
};

const decls = [_]struct { val: []const u8, decl: Decl }{
    .{ .val = "const", .decl = .@"const" },
    .{ .val = "var", .decl = .@"var" },
    .{ .val = "fun", .decl = .fun },
    .{ .val = "union", .decl = .@"union" },
    .{ .val = "struct", .decl = .@"struct" },
};

const syntax = [_]struct { val: []const u8, syntax: Syntax }{
    .{ .val = ";", .syntax = .semiColon },
    .{ .val = "=", .syntax = .equal },
};

fn tokenize_number(val: []const u8) ?struct { len: usize, num: NumberToken } {
    if (val.len == 0) return null;
    if (std.mem.indexOfScalar(u8, "0123456789", val[0]) != null) {
        var offset: usize = 0;
        while (offset < val.len and std.mem.indexOfScalar(u8, "0123456789", val[offset]) != null) {
            offset += 1;
            //
        }
        const whole_offset = offset;
        if (offset < val.len and val[offset] == '.') {
            offset += 1;
            while (offset < val.len and std.mem.indexOfScalar(u8, "0123456789", val[offset]) != null) {
                offset += 1;
                //
            }
            return .{ .len = offset, .num = .{ .whole = val[0..whole_offset], .frac = val[whole_offset + 1 .. offset] } };
        } else {
            return .{ .len = offset, .num = .{ .whole = val[0..whole_offset], .frac = null } };
        }
    }
    return null;
}

fn tokenize_identifier(val: []const u8) ?struct { len: usize, val: []const u8 } {
    if (val.len == 0) return null;

    if (std.mem.indexOfScalar(u8, std.ascii.letters ++ "0123456789", val[0]) != null) {
        var offset: usize = 0;
        while (offset < val.len and std.mem.indexOfScalar(u8, std.ascii.letters ++ "0123456789", val[offset]) != null) {
            offset += 1;
        }
        return .{ .len = offset, .val = val[0..offset] };
    }
    return null;
}

pub const iterator = struct {
    data: []const u8,
    idx: usize = 0,
    fn matchString(self: iterator, val: []const u8) bool {
        if (val.len > self.data[self.idx..].len) return false;
        return std.mem.eql(u8, self.data[self.idx..][0..val.len], val);
    }
    pub fn next(self: *iterator) !?Token {
        while (self.idx < self.data.len and std.mem.indexOfScalar(u8, &std.ascii.whitespace, self.data[self.idx]) != null) {
            std.log.info("skip whitespace {}:[{}]", .{ self.idx, self.data.len });
            self.idx += 1;
            //
        }
        if (self.idx >= self.data.len) return null;
        for (ops) |o| {
            if (self.matchString(o.val)) {
                self.idx += o.val.len;
                return .{ .operator = o.op };
            }
        }
        for (decls) |d| {
            if (self.matchString(d.val)) {
                self.idx += d.val.len;
                return .{ .decl = d.decl };
            }
        }
        for (syntax) |s| {
            if (self.matchString(s.val)) {
                self.idx += s.val.len;
                return .{ .syntax = s.syntax };
            }
        }
        if (tokenize_number(self.data[self.idx..])) |num| {
            self.idx += num.len;
            return .{ .number = num.num };
        }
        if (tokenize_identifier(self.data[self.idx..])) |val| {
            self.idx += val.len;
            return .{ .identifier = val.val };
        }

        return error.InvalidToken;
    }
};

pub fn tokenize(input: []const u8, al: *std.ArrayList(Token)) !void {
    var iter = iterator{ .data = input };
    while (try iter.next()) |token| {
        std.log.info("Token:[{f}]", .{token});
        try al.append(token);
    }
}

test {
    _ = @import("Test.zig");
    //try tokenize("const len = 1 + 2;");
}
