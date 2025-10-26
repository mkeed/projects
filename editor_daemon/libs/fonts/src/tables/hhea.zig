const std = @import("std");
const util = @import("../utils.zig");

pub const hhea = struct {
    version: util.Version16Dot16,
    ascender: util.FWORD,
    descender: util.FWORD,
    lineGap: util.FWORD,
    advanceWidthMax: util.UFWORD,
    minLeftSideBearing: util.FWORD,
    minRightSideBearing: util.FWORD,
    xMaxExtend: util.FWORD,
    caretSlopeRise: i16,
    caretSlopeRun: i16,
    caretOffset: i16,
    res: [4]i16,
    metricDataFormat: i16,
    numberOfHMetrics: u16,
};

pub fn decode(data: []const u8, alloc: std.mem.Allocator) !hhea {
    _ = alloc;
    return try util.read(hhea, data);
}
