const std = @import("std");
const util = @import("../utils.zig");

pub const maxp = struct {
    version: util.Version16Dot16,
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
    return try util.read(maxp, data);
}
