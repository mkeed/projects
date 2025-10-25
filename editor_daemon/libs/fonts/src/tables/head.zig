const std = @import("std");

pub fn decode(data: []const u8, alloc: std.mem.Allocator) !Head {
    const majorVersion = std.mem.readVarInt(u16, data[0..][0..2]);
    const minorVersion = std.mem.readVarInt(u16, data[2..][0..2]);
}
