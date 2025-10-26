const std = @import("std");
const util = @import("../utils.zig");

pub const post = struct {
    version: util.Version16Dot16,
    italicAngle: util.Fixed,
    unerlinePosiition: util.FWORD,
    underlineThickness: util.FWORD,
    isFixedPitch: u32,
    minMemType42: u32,
    maxMemType42: u32,
    minMemType1: u32,
    maxMemType1: u32,
};

pub fn decode(data: []const u8) !post {
    return try util.read(post, data);
}
