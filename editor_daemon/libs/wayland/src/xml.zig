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
pub const XMLDoc = struct {
    version: ?Version,
    encoding: ?Encoding,
    alloc: std.mem.Allocator,
    elements: []Element,
    pub const ElementIdx = u32;
    pub const Element = union(enum) {
        sub: struct {
            sub_elements: []const ElementIdx,
            attrs: []const Attribute,
        },
        text: []const u8,
    };
    pub fn deinit(self: XMLDoc) void {
        _ = self;
    }
};

const XMLBuilder = struct {
    alloc:std.mem.Allocator,
    pub fn init(alloc:std.mem.Allocator) XMLBuilder {
        return .{
            .alloc = alloc,
        };
    }
    pub fn deinit(self:*XMLBuilder) void {
        _ = self;
    }
};

pub fn parseXML(alloc: std.mem.Allocator, data: []const u8) !XMLDoc {
    var elements = std.ArrayList(XMLDoc.Element){};
    defer elements.deinit(alloc);
    const version: ?Version = null;
    const encoding: ?Encoding = null;
    var builder = XMLBuilder.init(alloc);
    defer builder.deinit();
    var iter = TokenIter{ .data = data };
    var count: usize = 0;
    while (try iter.next()) |token| {
        defer count += 1;
        if (count > 100) break;
        std.log.err("{f}", .{token});
        switch (token) {
            .start_tag => {
                const new_id = try 
            }, // TagDef,
            .end_tag => {}, // []const u8,
            .empty_tag => {}, // TagDef,
            .version_tag => {}, // []const u8,
            .text => {}, // []const u8,
            .cdata => {}, // []const u8,
            .comment => {}, // []const u8,
        }
    }

    return .{
        .version = version,
        .encoding = encoding,
        .alloc = alloc,
        .elements = try elements.toOwnedSlice(alloc),
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
