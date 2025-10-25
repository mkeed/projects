const std = @import("std");

pub const FWORD = i16;
pub const UFWORD = u16;
pub const Fixed = packed struct(u32) {
    whole: u16,
    frac: u16,
};
pub const F2DOT14 = packed struct(u16) {
    fix: u2,
    frac: u14,
};
pub const LONGDATETIME = i64;
pub const Version16Dot16 = struct {
    major: u16,
    minor: u16,
};

pub const Reader = struct {
    data: []const u8,
    idx: usize = 0,
    fn takeBytes(self: *Reader, len: usize) ![]const u8 {
        if (self.idx + len > self.data.len) {
            return error.TooLong;
        }
        defer self.idx += len;
        return self.data[self.idx..][0..len];
    }
    pub fn read(self: *Reader, comptime T: type) !T {
        switch (@typeInfo(T)) {
            .@"struct" => |s| {
                switch (s.layout) {
                    .auto, .@"extern" => {
                        var ret: T = undefined;
                        inline for (s.fields) |f| {
                            @field(ret, f.name) = try self.read(f.type);
                        }
                        return ret;
                    },
                    .@"packed" => {
                        const val = try self.read(s.backing_integer.?);
                        return @bitCast(val);
                    },
                }
            },
            .int => {
                const bytes = try self.takeBytes(@sizeOf(T));
                return std.mem.readVarInt(T, bytes, .big);
            },
            else => {
                @compileError("TODO");
            },
        }
    }
};

pub fn read(comptime T: type, data: []const u8) !T {
    var reader = Reader{ .data = data };
    return try reader.read(T);
}
