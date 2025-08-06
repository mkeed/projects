const std = @import("std");

pub fn encode(comptime T: type, val: T, writer: anytype) !void {
    switch (@typeInfo(T)) {
        .int => |i| {
            if (i.bits > 64) @compileError("Max int len in message_pack is 64");
            switch (i.signedness) {
                .signed => {
                    if (val >= 0 and val <= 0x7f) {
                        try writer.writeByte(@as(u8, @bitCast(@as(i8, @truncate(val)))));
                    } else if (val < 0 and val >= -32) {
                        try writer.writeByte(@bitCast(@as(i8, @truncate(val))));
                    } else {
                        const t = [_]struct { t: type, header: u8 }{
                            .{ .t = i8, .header = 0xd0 },
                            .{ .t = i16, .header = 0xd1 },
                            .{ .t = i32, .header = 0xd2 },
                            .{ .t = i64, .header = 0xd3 },
                        };
                        inline for (t) |int_t| {
                            if (val <= std.math.maxInt(int_t.t) and val >= std.math.minInt(int_t.t)) {
                                try writer.writeByte(int_t.header);
                                try writer.writeInt(int_t.t, @intCast(val), .big);
                                return;
                            }
                        }
                    }
                },
                .unsigned => {
                    if (val >= 0 and val <= 0x7f) {
                        try writer.writeByte(@truncate(val));
                    } else {
                        const t = [_]struct { t: type, header: u8 }{
                            .{ .t = u8, .header = 0xcc },
                            .{ .t = u16, .header = 0xcd },
                            .{ .t = u32, .header = 0xce },
                            .{ .t = u64, .header = 0xcf },
                        };
                        inline for (t) |int_t| {
                            if (val <= std.math.maxInt(int_t.t)) {
                                try writer.writeByte(int_t.header);
                                try writer.writeInt(int_t.t, @intCast(val), .big);
                                return;
                            }
                        }
                    }
                },
            }
        },
        .optional => |t| {
            if (val) |v| {
                try encode(t.child, v, writer);
            } else {
                try writer.writeByte(0xc0);
            }
        },
        .bool => {
            if (val) {
                try writer.writeByte(0xc2);
            } else {
                try writer.writeByte(0xc3);
            }
        },
        .float => {
            if (T == f32) {
                const ptr: *const u32 = @ptrCast(&val);
                try writer.writeByte(0xca);
                try writer.writeInt(u32, ptr.*, .big);
            } else if (T == f64) {
                try writer.writeByte(0xcb);
                const ptr: *const u64 = @ptrCast(&val);
                try writer.writeInt(u64, ptr.*, .big);
            } else {
                @compileError("only f32 and f64 supported");
            }
        },
        .pointer => |_| {
            if (T == []u8 or T == []const u8) {
                if (val.len <= std.math.maxInt(u5)) {
                    try writer.writeByte(0b10100000 | (@as(u8, @truncate(val.len)) & 0b11111));
                    try writer.writeAll(val);
                } else if (val.len <= std.math.maxInt(u8)) {
                    try writer.writeByte(0xd9);
                    try writer.writeByte(@truncate(val.len));
                    try writer.writeAll(val);
                } else if (val.len <= std.math.maxInt(u16)) {
                    try writer.writeByte(0xda);
                    try writer.writeInt(u16, @truncate(val.len), .big);
                    try writer.writeAll(val);
                } else if (val.len <= std.math.maxInt(u32)) {
                    try writer.writeByte(0xdb);
                    try writer.writeInt(u32, @truncate(val.len), .big);
                    try writer.writeAll(val);
                    //
                } else {
                    return error.InvalidLen;
                }
            } else {
                if (val.len <= std.math.maxInt(u4)) {
                    try writer.writeByte(0b10010000 | (@as(u8, @truncate(val.len)) & 0b1111));
                } else if (val.len <= std.math.maxInt(u16)) {
                    try writer.writeByte(0xdc);
                    try writer.writeInt(u16, @truncate(val.len), .big);
                } else if (val.len <= std.math.maxInt(u32)) {
                    try writer.writeByte(0xdd);
                    try writer.writeInt(u32, @truncate(val.len), .big);
                } else {
                    return error.InvalidLen;
                }
                for (val) |v| {
                    try encode(@TypeOf(v), v, writer);
                }
            }
        },
        .@"struct" => |s| {
            if (s.fields.len < std.math.maxInt(u4)) {
                try writer.writeByte(0b10000000 | (@as(u8, @truncate(s.fields.len)) & 0b1111));
            } else if (s.fields.len < std.math.maxInt(u16)) {
                try writer.writeByte(0xde);
                try writer.writeByte(@truncate(s.fields.len));
            } else if (s.fields.len < std.math.maxInt(u32)) {
                try writer.writeByte(0xdf);
                try writer.writeByte(@truncate(s.fields.len));
            } else {
                return error.InvalidLen;
            }
            inline for (s.fields) |f| {
                try encode([]const u8, f.name, writer);
                try encode(f.type, @field(val, f.name), writer);
            }
        },

        .@"enum" => {
            try encode([]const u8, @tagName(val), writer);
        },
        else => @compileError("TODO"),
    }
}

test {
    var al = std.ArrayList(u8).init(std.testing.allocator);
    defer al.deinit();

    //try encode(u32, 1234, al.writer());

    //try encode(i32, -1234, al.writer());
    //try encode(?i32, null, al.writer());
    //try encode(f64, -1.2, al.writer());
    //try encode([]const u16, &.{ 123, 123, 1233 }, al.writer());
    //try encode(struct { thing: u8, other: []const u8 }, .{ .thing = 22, .other = "hello" }, al.writer());
    try encode(enum { thing, other }, .thing, al.writer());
}

pub fn decode(comptime T: type, alloc: std.mem.Allocator, reader: anytype) !std.json.Parsed(T) {
    _ = reader;
    var parsed = std.json.Parsed(T){
        .arena = try alloc.create(std.heap.ArenaAllocator),
        .value = undefined,
    };
    errdefer alloc.destroy(parsed.arena);
    parsed.arena.* = std.heap.ArenaAllocator.init(alloc);
    errdefer parsed.arena.deinit();

    return parsed;
}
