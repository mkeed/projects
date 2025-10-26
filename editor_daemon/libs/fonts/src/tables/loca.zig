const std = @import("std");
const util = @import("../utils.zig");
const head = @import("head.zig").head;
const maxp = @import("maxp.zig").maxp;

pub const loca = struct {
    numGlyphs: u32,
    format: enum { short, long },
    data: []const u8,

    pub fn get(self: loca, point: usize) u32 {
        std.debug.assert(point < self.numGlyphs);
        switch (self.format) {
            .short => {
                const offset = 2 * point;
                return std.mem.readVarInt(u16, self.data[offset..][0..2], .big);
            },
            .long => {
                const offset = 4 * point;
                return std.mem.readVarInt(u32, self.data[offset..][0..4], .big);
            },
        }
    }
};

pub fn decode(data: []const u8, h: head, m: maxp) !loca {
    return .{
        .numGlyphs = m.numGlyphs,
        .format = switch (h.indexToLocFormat) {
            0 => .short,
            1 => .long,
            else => return error.Invalid,
        },
        .data = data,
    };
}
