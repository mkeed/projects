const std = @import("std");
const util = @import("../utils.zig");

pub const maxp = struct {
    version: util.Version16Dot16,
    v1: ?maxp_v1,
};

const maxp_v1 = struct {
    numGlyphs: u16,
    maxPoints: u16,
    maxContours: u16,
    maxCompositePoints: u16,
    maxCompositeContours: u16,
    maxZones: u16,
    maxTwilightPoints: u16,
    maxStorage: u16,
    maxFunctionDefs: u16,
    maxInstructionDefs: u16,
    maxStackElements: u16,
    maxSizeOfInstructions: u16,
    maxComponentElements: u16,
    maxComponentDepth: u16,
};
pub fn decode(data: []const u8) !maxp {
    var reader = util.Reader{ .data = data };
    const version = try reader.read(util.Version16Dot16);
    return .{
        .version = version,
        .v1 = if (version.major == 1 and version.minor == 0) try reader.read(maxp_v1) else null,
    };
}
