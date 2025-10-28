const std = @import("std");
const util = @import("../utils.zig");

pub const GSUB = struct {};

const GSUB_header = struct {
    majorVersion: u16,
    minorVersion: u16,
    scriptListOffset: u16,
    featureListOffset: u16,
    lookupListOffset: u16,
};

pub fn decode(data: []const u8) !void {
    //
}
