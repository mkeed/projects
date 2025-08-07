const std = @import("std");

pub const Option = struct {
    indent_style: enum { tab, space } = .space,
    indent_size: u8 = 4,
    tab_width: ?u8 = null,
    end_of_line: ?enum { lf, cr, crlf } = null,
    charset: enum { latin1, utf8, utf8bom, utf16be, utf16le } = .utf8,
    spelling_language: Language,
    trim_trailing_whitespace: bool = false,
    insert_final_newline: bool = false,
};

pub const EditorConfig = struct {
    opts: std.StringArrayHashMap(Option),

    pub fn init(alloc: std.mem.Allocator) EditorConfig {
        return .{
            .opts = std.StringArrayHashMap(Option).init(alloc),
        };
    }
};

pub fn parse(alloc: std.mem.Allocator, data: []const u8) !void {
    //

}

pub const Language = struct {
    iso_639_code: [2]u8,
    iso_3166_code: [2]u8,
};
