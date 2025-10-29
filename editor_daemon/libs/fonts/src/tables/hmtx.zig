const std = @import("std");
const util = @import("../utils.zig");
const maxp = @import("maxp.zig").maxp;
const hhea = @import("hhea.zig").hhea;

pub const hmtx = struct {};
pub const LongHorMetric = struct {
    advanceWidth: util.UFWORD,
    lsb: util.FWORD,
};

pub fn decode(
    data: []const u8,
    m: maxp,
    h: hhea,
) !hmtx {
    for (0..h.numberOfHMetrics) |idx| {
        const offset = util.packedSize(LongHorMetric) * idx;
        const met = try util.read(LongHorMetric, data[offset..]);
        //std.log.debug("{}", .{met});
        _ = met;
    }
    const numGlyphs = if (m.v1) |v1| v1.numGlyphs else 0;
    if (h.numberOfHMetrics < numGlyphs) {
        const offset = util.packedSize(LongHorMetric) * h.numberOfHMetrics;
        for (0..(numGlyphs - h.numberOfHMetrics)) |idx| {
            const pos = @sizeOf(util.FWORD) * idx + offset;
            const lsb = try util.read(util.FWORD, data[pos..]);
            //std.log.debug("{}", .{lsb});
            _ = lsb;
        }
    }
    return .{};
}
