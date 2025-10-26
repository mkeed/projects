const std = @import("std");
const util = @import("../utils.zig");
const loca = @import("loca.zig").loca;

pub const glyf = struct {};

const glyf_header = struct {
    numberOfContours: i16,
    xMin: i16,
    yMin: i16,
    xMax: i16,
    yMax: i16,
};

pub const Flag = packed struct(u8) {
    on_curve: bool,
    x_short: bool,
    y_short: bool,
    repeat: bool,
    x_same_or_pos: bool,
    y_same_or_pos: bool,
    overlap_simple: bool,
    res: bool,
};

const EndIter = struct {
    eps: util.Reader,
    next_end: u16,
    num: usize,
    idx: usize = 0,
    glyf_id: u32 = 0,
    pub fn init(data: []const u8, num: u32) !EndIter {
        var endPoints = util.Reader{ .data = data };
        const next_end = try endPoints.read(u16);

        return .{
            .eps = endPoints,
            .next_end = next_end,
            .num = num,
            .idx = 0,
            .glyf_id = 0,
        };
    }

    pub fn next(self: *EndIter) !?u32 {
        defer self.idx += 1;
        if (self.idx > self.next_end) {
            self.glyf_id += 1;
            if (self.glyf_id >= self.num) return null;
            self.next_end = try self.eps.read(u16);
        }
        return self.glyf_id;
    }
};

pub fn decode(data: []const u8, alloc: std.mem.Allocator, l: loca) !glyf {
    for (0..l.numGlyphs) |idx| {
        const pos = l.get(idx);
        var reader = util.Reader{ .data = data[pos..] };
        const header = try reader.read(glyf_header);
        std.log.err("{}", .{header});
        var iter = try EndIter.init(try reader.takeBytes(@intCast(2 * header.numberOfContours)), @intCast(header.numberOfContours));

        const ins_length = try reader.read(u16);
        const ins = try reader.takeBytes(ins_length);

        std.log.err("[{}]{x}", .{ ins_length, ins });
        while (try iter.next()) |idx2| {
            const flag = try reader.read(Flag);
            std.log.err("{}|{}", .{ idx2, flag });
        }
    }
    _ = alloc;

    return .{};
}
