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
pub const Tag = struct {
    char: [4]u8,
};

pub const Reader = struct {
    data: []const u8,
    idx: usize = 0,
    pub fn takeBytes(self: *Reader, len: usize) ![]const u8 {
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
            .@"enum" => |e| {
                const int = try self.read(e.tag_type);
                errdefer std.log.err("Bad Enum: {}", .{int});
                return try std.meta.intToEnum(T, int);
            },
            .array => |a| {
                var ret: T = undefined;
                for (&ret) |*val| {
                    val.* = try self.read(a.child);
                }
                return ret;
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

pub fn packedSize(comptime T: type) usize {
    switch (@typeInfo(T)) {
        .@"struct" => |s| {
            var size: usize = 0;
            inline for (s.fields) |f| {
                size += @sizeOf(f.type);
            }
            return size;
        },
        else => @compileError("TODO"),
    }
}
