const std = @import("std");

pub const FWORD = i16;
pub const UFWORD = u16;
pub const Fixed = packed struct(u32) {
    whole: u16,
    frac: u16,
};
pub const F2DOT14 = struct {
    value: f32,
    const packedSize = @sizeOf(i16);
    pub fn parse(reader: *Reader) !F2DOT14 {
        const input = try reader.read(i16);
        const whole: f32 = @floatFromInt(@as(i2, @truncate(input >> 14)));
        const frac_part: f32 = @floatFromInt(@as(u14, @bitCast(@as(i14, @truncate(input)))));
        const frac: f32 = frac_part / @as(f32, std.math.maxInt(u14) + 1);
        const val = whole + frac;
        return .{ .value = val };
    }

    pub fn format(self: F2DOT14, writer: *std.Io.Writer) !void {
        try writer.print("{}", .{self.value});
    }
};

test {
    // 1.999939  0x7fff   1  16383/16384
    //1.75       0x7000   1  12288/16384
    //0.000061   0x0001   0  1/16384
    //0.0        0x0000   0  0/16384
    //-0.000061  0xffff  -1  16383/16384
    //-2.0       0x8000  -2  0/16384
    const test_vals = [_]struct { bytes: []const u8, dec: []const u8, frac: []const u8 }{
        .{ .bytes = &.{ 0x7F, 0xFF }, .dec = "1.999939", .frac = "16383/16384" },
        .{ .bytes = &.{ 0x70, 0x00 }, .dec = "1.75", .frac = "12288/16384" },
        .{ .bytes = &.{ 0x00, 0x01 }, .dec = "0.000061", .frac = "1/16384" },
        .{ .bytes = &.{ 0x00, 0x00 }, .dec = "0.0", .frac = "0/16384" },
        .{ .bytes = &.{ 0xFF, 0xFF }, .dec = "-0.00061", .frac = "16383/16384" },
        .{ .bytes = &.{ 0x80, 0x00 }, .dec = "-2.0", .frac = "0/16384" },
    };
    for (test_vals) |tv| {
        var reader = Reader{ .data = tv.bytes };
        const val = try reader.read(F2DOT14);
        //std.log.err("{f}", .{val});
        std.log.err("\nexp :{s} : {s} {f}", .{ tv.dec, tv.frac, val });
    }
}
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
                if (@hasDecl(T, "parse")) {
                    return try T.parse(self);
                }
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
                const val = std.mem.readVarInt(T, bytes, .big);

                return val;
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
            if (@hasDecl(T, "parse")) {
                return try T.packedSize;
            }

            var size: usize = 0;
            inline for (s.fields) |f| {
                size += @sizeOf(f.type);
            }
            return size;
        },
        else => @compileError("TODO"),
    }
}
