const std = @import("std");
const xmlOpenToken = "<?";
const xmlCloseToken = "?>";

const commentOpen = "<!--";
const commentClose = "-->";

const cdataOpen = "<![CDATA[";
const cdataClose = "]]>";

const openTag = "<";
const openCloseTag = "</";

pub const Version = enum { v1_0, v1_1 };
pub const Encoding = enum { utf8 };
pub const Attribute = struct {
    name: []const u8,
    value: []const u8,
};

const arg_iter = struct {
    data: []const u8,
    idx: usize = 0,
    pub fn next(self: *arg_iter) !?Attribute {
        errdefer std.log.err("Value `{s}`|`{s}`", .{ self.data, self.data[self.idx..] });
        if (self.idx >= self.data.len) return null;
        const start = self.idx;
        const mid = std.mem.findPos(u8, self.data, self.idx, "=") orelse return error.Invalid;
        const name = self.data[start..mid];

        self.idx = mid + 2;
        const value_pos = std.mem.findPos(u8, self.data, self.idx, "\"") orelse return error.Invalid;
        defer self.idx = value_pos + 1;
        return .{
            .name = std.mem.trim(u8, name, &std.ascii.whitespace),
            .value = self.data[mid + 2 .. value_pos],
        };
    }
};

pub const XMLDoc = struct {
    version: ?Version,
    encoding: ?Encoding,
    alloc: std.mem.Allocator,
    elements: []Element,
    pub const ElementIdx = u32;
    pub const Element = union(enum) {
        sub: SubElem,
        text: []const u8,
    };
    pub const SubElem = struct {
        name: []const u8,
        sub_elements: std.ArrayList(u32),
        attrs: []const Attribute,
        parent: ?u32,
    };
    pub fn deinit(self: XMLDoc) void {
        for (self.elements) |*e| {
            switch (e.*) {
                .sub => |*s| {
                    self.alloc.free(s.attrs);
                    s.sub_elements.deinit(self.alloc);
                },
                else => {},
            }
        }
        self.alloc.free(self.elements);
    }
    pub fn search(self: XMLDoc, id: u32, names: []const []const u8, elements: *std.array_list.Managed(*Element)) !void {
        if (names.len == 0) return;
        switch (self.elements[id]) {
            .text => {},
            .sub => |sub_elem| {
                for (sub_elem.sub_elements.items) |s| {
                    switch (self.elements[s]) {
                        .text => {},
                        .sub => |sub| {
                            if (std.mem.eql(u8, sub.name, names[0])) {
                                if (names.len == 1) {
                                    try elements.append(&self.elements[id]);
                                } else {
                                    std.log.err("Name:[{s}]", .{sub.name});
                                    try self.search(s, names[1..], elements);
                                }
                            }
                        },
                    }
                }
            },
        }
    }
};

const XMLBuilder = struct {
    alloc: std.mem.Allocator,
    elements: std.ArrayList(XMLDoc.Element),
    arg_builder: std.ArrayList(Attribute),
    cur_node: u32 = 0,
    pub fn init(alloc: std.mem.Allocator) !XMLBuilder {
        var elems = std.ArrayList(XMLDoc.Element){};
        errdefer elems.deinit(alloc);
        try elems.append(alloc, .{
            .sub = .{
                .name = "root",
                .sub_elements = .{},
                .attrs = &.{},
                .parent = null,
            },
        });
        return .{
            .alloc = alloc,
            .elements = elems,
            .arg_builder = .{},
        };
    }
    pub fn deinit(self: *XMLBuilder) void {
        self.arg_builder.deinit(self.alloc);
        for (self.elements.items) |*e| {
            switch (e.*) {
                .sub => |*s| {
                    self.alloc.free(s.attrs);
                    s.sub_elements.deinit(self.alloc);
                },
                else => {},
            }
        }
        self.elements.deinit(self.alloc);
    }

    pub fn tag(self: *XMLBuilder, opt: enum { push, empty }, val: Token.TagDef) !void {
        if (val.args) |arg| {
            self.arg_builder.clearRetainingCapacity();
            var iter = arg_iter{ .data = std.mem.trim(u8, arg, &std.ascii.whitespace) };
            while (try iter.next()) |n| {
                try self.arg_builder.append(self.alloc, n);
            }
        }

        const node_id: u32 = @intCast(self.elements.items.len);
        try self.elements.append(
            self.alloc,
            .{ .sub = .{
                .name = val.name,
                .sub_elements = .{},
                .attrs = try self.alloc.dupe(Attribute, self.arg_builder.items),
                .parent = self.cur_node,
            } },
        );
        try self.elements.items[self.cur_node].sub.sub_elements.append(self.alloc, node_id);
        if (opt == .push) self.cur_node = node_id;
    }
    pub fn push_text(self: *XMLBuilder, text: []const u8) !void {
        const node_id: u32 = @intCast(self.elements.items.len);
        try self.elements.append(
            self.alloc,
            .{ .text = text },
        );
        try self.elements.items[self.cur_node].sub.sub_elements.append(self.alloc, node_id);
    }
    pub fn pop_tag(self: *XMLBuilder, name: []const u8) !void {
        switch (self.elements.items[self.cur_node]) {
            .sub => |sub| {
                if (std.mem.eql(u8, sub.name, name) == false) {
                    std.log.err("{s} != {s}", .{ sub.name, name });
                    return error.MisMatchTag;
                }
                if (sub.parent) |p| {
                    self.cur_node = p;
                } else {
                    return error.Mismatch;
                }
            },
            else => return error.InvalidState,
        }
    }
};

pub fn parseXML(alloc: std.mem.Allocator, data: []const u8) !XMLDoc {
    var elements = std.ArrayList(XMLDoc.Element){};
    defer elements.deinit(alloc);
    const version: ?Version = null;
    const encoding: ?Encoding = null;
    var builder = try XMLBuilder.init(alloc);
    defer builder.deinit();
    var iter = TokenIter{ .data = data };
    var count: usize = 0;
    while (try iter.next()) |token| {
        defer count += 1;

        std.log.info("{f}", .{token});
        switch (token) {
            .start_tag => |st| {
                try builder.tag(.push, st);
            },
            .end_tag => |name| {
                try builder.pop_tag(name);
            }, // []const u8,
            .empty_tag => |et| {
                try builder.tag(.empty, et);
            }, // TagDef,
            .version_tag => {}, // []const u8,
            .text => |t| {
                try builder.push_text(t);
            }, // []const u8,
            .cdata => |t| {
                try builder.push_text(t);
            }, // []const u8,
            .comment => {}, // []const u8,
        }
    }

    return .{
        .version = version,
        .encoding = encoding,
        .alloc = alloc,
        .elements = try builder.elements.toOwnedSlice(alloc),
    };
}

test {
    const name = "/usr/share/wayland/wayland.xml";
    const alloc = std.testing.allocator;
    const file = try std.fs.cwd().readFileAlloc(name, alloc, .unlimited);
    //std.log.err("{s}", .{file});
    defer alloc.free(file);

    const doc = try parseXML(alloc, file);
    defer doc.deinit();
    var list = std.array_list.Managed(*XMLDoc.Element).init(alloc);
    defer list.deinit();
    try doc.search(0, &.{ "protocol", "interface" }, &list);
    for (list.items) |i| {
        switch (i.*) {
            .sub => |s| std.log.err("[{s}]", .{s.name}),
            else => {},
        }
    }
}

const Token = union(enum) {
    const TagDef = struct { name: []const u8, args: ?[]const u8 };
    start_tag: TagDef,
    end_tag: []const u8,
    empty_tag: TagDef,
    version_tag: []const u8,
    text: []const u8,
    cdata: []const u8,
    comment: []const u8,
    pub fn format(self: Token, writer: *std.Io.Writer) !void {
        switch (self) {
            .start_tag => |s| try writer.print("Start[{s}|{s}]", .{ s.name, s.args orelse "(null)" }),
            .end_tag => |e| try writer.print("End[{s}]", .{e}),
            .empty_tag => |s| try writer.print("Empty[{s}|{s}]", .{ s.name, s.args orelse "(null)" }),
            .version_tag => |v| try writer.print("Version[{s}]", .{v}),
            .text => |t| try writer.print("Text[{s}]", .{t}),
            .cdata => |t| try writer.print("cdata[{s}]", .{t}),
            .comment => |t| try writer.print("Comment[{s}]", .{t}),
        }
    }
};

fn startsWith(data: []const u8, starting_msg: []const u8) bool {
    if (starting_msg.len > data.len) return false;
    return std.mem.eql(u8, data[0..starting_msg.len], starting_msg);
}

const TokenIter = struct {
    data: []const u8,
    idx: usize = 0,
    pub fn next(self: *TokenIter) !?Token {
        if (self.idx >= self.data.len) return null;
        if (self.data[self.idx] == '<') {
            if (startsWith(self.data[self.idx..], commentOpen)) {
                self.idx += commentOpen.len;
                if (std.mem.findPos(u8, self.data, self.idx, commentClose)) |end| {
                    defer self.idx = end + commentClose.len;
                    return .{ .comment = self.data[self.idx..end] };
                } else {
                    return error.InvalidToken;
                }
            } else if (startsWith(self.data[self.idx..], cdataOpen)) {
                self.idx += cdataOpen.len;
                if (std.mem.findPos(u8, self.data, self.idx, cdataClose)) |end| {
                    defer self.idx = end + cdataClose.len;
                    return .{ .cdata = self.data[self.idx..end] };
                } else {
                    return error.InvalidToken;
                }
            } else if (startsWith(self.data[self.idx..], xmlOpenToken)) {
                self.idx += xmlOpenToken.len;
                if (std.mem.findPos(u8, self.data, self.idx, xmlCloseToken)) |end| {
                    defer self.idx = end + xmlCloseToken.len;
                    return .{ .version_tag = self.data[self.idx..end] };
                } else {
                    return error.InvalidToken;
                }
            } else if (startsWith(self.data[self.idx..], openCloseTag)) {
                self.idx += openCloseTag.len;
                if (std.mem.findPos(u8, self.data, self.idx, ">")) |end| {
                    defer self.idx = end + 1;
                    return .{ .end_tag = self.data[self.idx..end] };
                } else {
                    return error.InvalidToken;
                }
            } else {
                if (std.mem.findPos(u8, self.data, self.idx, ">")) |pos| {
                    defer self.idx = pos + 1;
                    const is_empty_tag = self.data[pos - 1] == '/';
                    const total = if (is_empty_tag) self.data[self.idx + 1 .. pos - 1] else self.data[self.idx + 1 .. pos];
                    const tag_def: Token.TagDef = if (std.mem.find(u8, total, " ")) |split| .{
                        .name = total[0..split],
                        .args = total[split..],
                    } else .{
                        .name = total,
                        .args = null,
                    };
                    if (is_empty_tag) {
                        return .{ .empty_tag = tag_def };
                    } else {
                        return .{ .start_tag = tag_def };
                    }
                } else {
                    return error.UnexpectedEnd;
                }
            }
        } else {
            if (std.mem.findPos(u8, self.data, self.idx, "<")) |pos| {
                defer self.idx = pos;
                return .{ .text = self.data[self.idx..pos] };
                //
            } else {
                defer self.idx = self.data.len;
                return .{ .text = self.data[self.idx..] };
            }
        }
    }
};
