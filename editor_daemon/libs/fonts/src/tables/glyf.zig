const std = @import("std");
const util = @import("../utils.zig");
const loca = @import("loca.zig").loca;
const maxp = @import("maxp.zig").maxp;
const cmap = @import("cmap.zig").cmap;

pub const glyf = struct {};

const glyf_header = struct {
    numberOfContours: i16,
    xMin: i16,
    yMin: i16,
    xMax: i16,
    yMax: i16,
};

pub const Flag = packed struct(u8) {
    on_curve: bool,
    x_short: bool,
    y_short: bool,
    repeat: bool,
    x_same_or_pos: bool,
    y_same_or_pos: bool,
    overlap_simple: bool,
    res: bool,
};

const EndIter = struct {
    eps: util.Reader,
    prev: u16 = 0,
    pub fn init(data: []const u8) EndIter {
        return .{
            .eps = util.Reader{ .data = data },
        };
    }

    pub fn next_pt(self: *EndIter) ?usize {
        const next_end = self.eps.read(u16) catch return null;
        defer self.prev = next_end;
        if (self.prev == 0) {
            return (next_end - self.prev) + 1;
        }
        return next_end - self.prev;
    }
};

const FlagIter = struct {
    flags: []const u8,
    idx: usize = 0,
    repeat: ?struct {
        flag: Flag,
        num: u8,
    } = null,

    pub fn next(self: *FlagIter) ?Flag {
        if (self.repeat) |r| {
            defer self.repeat = if (r.num == 0) null else .{
                .flag = r.flag,
                .num = r.num - 1,
            };
            return r.flag;
        }
        if (self.idx >= self.flags.len) return null;
        const flag: Flag = @bitCast(self.flags[self.idx]);
        self.idx += 1;
        if (flag.repeat) {
            const repeat = self.flags[self.idx];
            self.idx += 1;
            self.repeat = .{
                .flag = flag,
                .num = repeat,
            };
        }
        return flag;
    }
    pub fn total_offset(self: FlagIter, num_points: usize) struct { flag_end: usize, xCoordend: usize } {
        var new = FlagIter{
            .flags = self.flags,
        };
        var xCoordend: usize = 0;
        for (0..num_points + 1) |_| {
            const flag = new.next().?;
            if (flag.x_short) {
                xCoordend += 1;
            } else {
                if (flag.x_same_or_pos == false) {
                    xCoordend += 2;
                }
            }
        }
        return .{ .flag_end = new.idx, .xCoordend = xCoordend };
    }
};

const Point = struct {
    x: i32,
    y: i32,
    on_curve: bool,
};

const PointIter = struct {
    flag: FlagIter,
    x_reader: util.Reader, //L("x_reader"),
    prev_x: i32 = 0,
    y_reader: util.Reader, //L("y_reader"),
    prev_y: i32 = 0,
    points: *std.ArrayList(Point),
    contour_iter: EndIter,

    pub fn get_curve(self: *PointIter) !?[]const Point {
        self.points.clearRetainingCapacity();
        if (self.contour_iter.next_pt()) |p| {
            for (0..p) |_| {
                const n = try self.next() orelse break;

                self.points.appendAssumeCapacity(n.p);
            }
            return self.points.items;
        }
        return null;
    }
    pub fn next(self: *PointIter) !?struct { p: Point, flag: Flag } {
        if (self.flag.next()) |n| {
            errdefer std.log.err("Flag:{}", .{n});
            errdefer std.log.err("{*} => {*} | {*} => {*}", .{
                self.x_reader.data.ptr,
                &self.x_reader.data[self.x_reader.data.len - 1],
                self.y_reader.data.ptr,
                &self.y_reader.data[self.y_reader.data.len - 1],
            });
            errdefer std.log.err("Flags:{x} x:{x} y:{x}", .{
                self.flag.flags,
                self.x_reader.data,
                self.y_reader.data[0..50],
            });
            //std.debug.assert(n.on_curve == true);
            var x: i32 = 0;
            var y: i32 = 0;
            //if (self.x_idx >= self.x_data.len) return error.InvalidGLyfData;
            if (n.x_short) {
                x = try self.x_reader.read(u8);
                if (!n.x_same_or_pos) {
                    x *= -1;
                }
                x += self.prev_x;
            } else {
                if (n.x_same_or_pos) {
                    x = self.prev_x;
                } else {
                    x = try self.x_reader.read(i16);
                    x += self.prev_x;
                }
            }
            if (n.y_short) {
                y = try self.y_reader.read(u8);
                if (!n.y_same_or_pos) {
                    y *= -1;
                }
                y += self.prev_y;
            } else {
                if (n.y_same_or_pos) {
                    y = self.prev_y;
                } else {
                    y = try self.y_reader.read(i16);
                    y += self.prev_y;
                }
            }
            self.prev_x = x;
            self.prev_y = y;
            //std.log.err("PT:(x:{},y:{})", .{ x, y });
            return .{
                .p = .{
                    .x = x,
                    .y = y,
                    .on_curve = n.on_curve,
                },
                .flag = n,
            };
        }
        return null;
    }
};

pub fn decode(data: []const u8, alloc: std.mem.Allocator, l: loca, m: maxp, map: *const cmap) !glyf {
    var contour_points = std.ArrayList(Point){};
    const maxPoints = if (m.v1) |v1| v1.maxPoints else 0;
    try contour_points.ensureTotalCapacity(alloc, maxPoints);
    const maxCompositePoints = if (m.v1) |v1| v1.maxCompositePoints else 0;
    defer contour_points.deinit(alloc);
    var composite_points = std.ArrayList(CompositeGlyf.SubGlyf){};
    defer composite_points.deinit(alloc);
    try composite_points.ensureTotalCapacity(alloc, maxCompositePoints);

    for (0..l.numGlyphs) |idx| {
        const pos = l.get(idx);
        var utf8_buf: [32]u8 = undefined;

        const unicode_id: u21 = @intCast(map.revMap(@intCast(idx)) orelse '?');
        const len = try std.unicode.utf8Encode(unicode_id, &utf8_buf);
        var reader = util.Reader{ .data = data[pos..] };
        if (reader.data.len == 0) break;
        const header = try reader.read(glyf_header);
        errdefer std.log.err("{}|{}|{x}", .{ header, pos, unicode_id });
        if (header.numberOfContours > 0) {
            const ends = try reader.takeBytes(@intCast(2 * header.numberOfContours));
            const end_pt = std.mem.readVarInt(u16, ends[@intCast(2 * (header.numberOfContours - 1))..][0..2], .big);

            const ins_length = try reader.read(u16);
            const ins = try reader.takeBytes(ins_length);
            //std.debug.assert(ins_length == 0);
            _ = ins;
            const start_flag = reader.idx;
            var flag_iter = FlagIter{ .flags = reader.data[reader.idx..] };
            const end_of_flags = flag_iter.total_offset(end_pt);
            _ = try reader.takeBytes(end_of_flags.flag_end);
            const x_s = try reader.takeBytes(end_of_flags.xCoordend);
            const y_s = reader.data[reader.idx..];
            //std.log.err("`{x}` `{x}`", .{ x_s, y_s });
            //std.log.err("[{}]{x}[{}]", .{ ins_length, ins, end_of_flags });
            var pt = PointIter{
                .flag = FlagIter{ .flags = reader.data[start_flag..][0..end_of_flags.flag_end] },
                .x_reader = .{ .data = x_s },
                .y_reader = .{ .data = y_s },
                .points = &contour_points,
                .contour_iter = EndIter.init(ends),
            };
            while (try pt.get_curve()) |curve| {
                for (curve, 0..) |c, c_idx| {
                    //std.log.err("[{}]{}", .{ c_idx, c });
                    _ = c;
                    _ = c_idx;
                }
            }
            //std.log.err("y_used {}", .{pt.y_idx});
        } else if (header.numberOfContours == -1) {
            composite_points.clearRetainingCapacity();
            const flags = try reader.read(CompositeFlag);
            const index = try reader.read(u16);

            //std.log.info("{} {}", .{ flags, index });
            const arg1: i16 = if (flags.arg_1_and_2_are_words) try reader.read(i16) else try reader.read(u8);
            const arg2: i16 = if (flags.arg_1_and_2_are_words) try reader.read(i16) else try reader.read(u8);

            //std.log.info("{}|{}", .{ arg1, arg2 });
            const scale: ?CompositeGlyf.Scale = if (flags.we_have_a_scale) .{
                .single = (try reader.read(util.F2DOT14)).value,
            } else if (flags.we_have_an_x_and_y_scale) .{
                .dual = .{
                    .x = (try reader.read(util.F2DOT14)).value,
                    .y = (try reader.read(util.F2DOT14)).value,
                },
            } else if (flags.we_have_a_two_by_two) .{ .affine = .{
                .x = (try reader.read(util.F2DOT14)).value,
                .@"01" = (try reader.read(util.F2DOT14)).value,
                .@"10" = (try reader.read(util.F2DOT14)).value,
                .y = (try reader.read(util.F2DOT14)).value,
            } } else null;
            if (scale) |s| {
                std.log.err("{}|{}|{}|{}|{}", .{ s, arg1, arg2, index, len });
            }
            try composite_points.append(alloc, .{
                .base = index,
                .x = arg1,
                .y = arg2,
                .scale = scale,
            });
        } else {}
        //std.log.err("Used: {}", .{reader.idx});
    }

    return .{};
}

const CompositeGlyf = struct {
    sub_glyfs: []const SubGlyf,
    pub const SubGlyf = struct {
        base: u32,
        x: i16,
        y: i16,
        scale: ?Scale,
    };
    pub const Scale = union(enum) {
        single: f32,
        dual: struct { x: f32, y: f32 },
        affine: Affine,
    };
    pub const Affine = struct {
        x: f32,
        @"01": f32,
        @"10": f32,
        y: f32,
        pub fn transform(self: Affine, x: f32, y: f32) struct { x: f32, y: f32 } {
            return .{
                .x = self.x * x + self.@"10" * y,
                .y = self.y * y + self.@"01" * x,
            };
        }
    };
};

const CompositeFlag = packed struct(u16) {
    arg_1_and_2_are_words: bool,
    args_are_xy_values: bool,
    round_xy_to_grid: bool,
    we_have_a_scale: bool,
    res1: bool,
    more_components: bool,
    we_have_an_x_and_y_scale: bool,
    we_have_a_two_by_two: bool,
    we_have_instructions: bool,
    use_my_metrics: bool,
    overlap_compound: bool,
    scaled_component_offset: bool,
    unscaled_component_offset: bool,
    res2: u3,
};
