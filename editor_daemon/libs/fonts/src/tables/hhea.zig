const std = @import("std");
const util = @import("../utils.zig");
pub const HHEA = struct {
    ascender: util.FWORD,
    descender: util.FWORD,
    lineGap: util.FWORD,
    advanceWidthMax: util.UFWORD,
    minLeftSideBearing: util.FWORD,
    minRightSideBearing: util.FWORD,
    xMaxExtend: util.FWORD,
    caretSlopeRise: i16,
    caretSlopeRUn: i16,
    caretOffset: i16,
    metricDataFormat: i16,
    numberOfHMetrics: u16,
};

pub fn decode(data: []const u8, alloc: std.mem.Allocator) !HHEA {
    return HHEA{
        .ascender = std.mem.readVarInt(util.FWORD, data[4..][0..@sizeOf(util.UFWORD)], .big),
        .descender = std.mem.readVarInt(util.FWORD, data[6..][0..@sizeOf(util.UFWORD)], .big),
        .lineGap = std.mem.readVarInt(util.FWORD, data[8..][0..@sizeOf(util.UFWORD)], .big),
        .advanceWidthMax = std.mem.readVarInt(util.UFWORD, data[10..][0..@sizeOf(util.UFWORD)], .big),
        .minLeftSideBearing = std.mem.readVarInt(util.FWORD, data[12..][0..@sizeOf(util.FWORD)], .big),
        .minRightSideBearing = std.mem.readVarInt(util.FWORD, data[14..][0..@sizeOf(util.FWORD)], .big),
        .xMaxExtend = std.mem.readVarInt(util.FWORD, data[16..][0..@sizeOf(util.FWORD)], .big),
        .caretSlopeRise = std.mem.readVarInt(i16, data[18..][0..@sizeOf(i16)], .big),
        .caretSlopeRUn = std.mem.readVarInt(i16, data[20..][0..@sizeOf(i16)], .big),
        .caretOffset = std.mem.readVarInt(i16, data[22..][0..@sizeOf(i16)], .big),
        .metricDataFormat = std.mem.readVarInt(i16, data[30..][0..@sizeOf(i16)], .big),
        .numberOfHMetrics = std.mem.readVarInt(u16, data[32..][0..@sizeOf(u16)], .big),
    };
}
