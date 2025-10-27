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
        std.log.err("next_pt:{}", .{next_end - self.prev});
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
    x_data: []const u8,
    x_idx: usize = 0,
    prev_x: i32 = 0,
    y_data: []const u8,
    y_idx: usize = 0,
    prev_y: i32 = 0,
    points: *std.ArrayList(Point),
    contour_iter: EndIter,

    pub fn get_curve(self: *PointIter) ?[]const Point {
        self.points.clearRetainingCapacity();
        if (self.contour_iter.next_pt()) |p| {
            for (0..p) |_| {
                const n = self.next().?;

                self.points.appendAssumeCapacity(n.p);
            }
            return self.points.items;
        }
        return null;
    }
    pub fn next(self: *PointIter) ?struct { p: Point, flag: Flag } {
        if (self.flag.next()) |n| {
            //std.debug.assert(n.on_curve == true);
            var x: i32 = 0;
            var y: i32 = 0;
            if (n.x_short) {
                x = self.x_data[self.x_idx];
                self.x_idx += 1;
                if (!n.x_same_or_pos) {
                    x *= -1;
                }
                x += self.prev_x;
            } else {
                if (n.x_same_or_pos) {
                    x = self.prev_x;
                } else {
                    x = std.mem.readVarInt(i16, self.x_data[self.x_idx..][0..2], .big);
                    self.x_idx += 2;
                    x += self.prev_x;
                }
            }
            if (n.y_short) {
                y = self.y_data[self.y_idx];
                self.y_idx += 1;
                if (!n.y_same_or_pos) {
                    y *= -1;
                }
                y += self.prev_y;
            } else {
                if (n.y_same_or_pos) {
                    y = self.prev_y;
                } else {
                    y = std.mem.readVarInt(i16, self.y_data[self.y_idx..][0..2], .big);
                    self.y_idx += 2;
                    y += self.prev_y;
                }
            }
            self.prev_x = x;
            self.prev_y = y;
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
    try contour_points.ensureTotalCapacity(alloc, m.maxPoints);

    defer contour_points.deinit(alloc);
    const char = "\xBC#!^%";
    for (char) |map_c| {
        //for (0..l.numGlyphs) |idx| {
        const mapped_c = map.get(map_c);
        const pos = l.get(mapped_c);
        //_ = map;
        std.log.err("pos:{}|{}|{c}", .{ mapped_c, pos, map_c });
        std.log.err("data:{x}", .{data[pos..][0..50]});
        var reader = util.Reader{ .data = data[pos..] };
        const header = try reader.read(glyf_header);
        std.log.err("{}", .{header});
        if (header.numberOfContours > 0) {
            const ends = try reader.takeBytes(@intCast(2 * header.numberOfContours));
            const end_pt = std.mem.readVarInt(u16, ends[@intCast(2 * (header.numberOfContours - 1))..][0..2], .big);

            const ins_length = try reader.read(u16);
            const ins = try reader.takeBytes(ins_length);
            var flag_iter = FlagIter{ .flags = reader.data[reader.idx..] };
            const end_of_flags = flag_iter.total_offset(end_pt);
            _ = try reader.takeBytes(end_of_flags.flag_end);
            const x_s = try reader.takeBytes(end_of_flags.xCoordend);
            const y_s = reader.data[reader.idx..];
            //std.log.err("`{x}` `{x}`", .{ x_s, y_s });
            std.log.err("[{}]{x}[{}]", .{ ins_length, ins, end_of_flags });
            var pt = PointIter{
                .flag = flag_iter,
                .x_data = x_s,
                .y_data = y_s,
                .points = &contour_points,
                .contour_iter = EndIter.init(ends),
            };
            while (pt.get_curve()) |curve| {
                for (curve, 0..) |c, c_idx| {
                    std.log.err("[{}]{}", .{ c_idx, c });
                }
            }
            std.log.err("y_used {}", .{pt.y_idx});
        } else if (header.numberOfContours == -1) {
            const flags = try reader.read(CompositeFlag);
            const index = try reader.read(u16);
            std.log.err("{} {}", .{ flags, index });
            const arg1 = if (flags.arg_1_and_2_are_words) try reader.read(u16) else try reader.read(u8);
            const arg2 = if (flags.arg_1_and_2_are_words) try reader.read(u16) else try reader.read(u8);
            if (flags.we_have_a_scale) {} else if (flags.we_have_an_x_and_y_scale) {} else if (flags.we_have_a_two_by_two) {}
            std.log.err("arg1:{} arg2:{}", .{ arg1, arg2 });
            std.log.err("arg1:{} arg2:{}", .{ @as(i16, @bitCast(arg1)), @as(i16, @bitCast(arg2)) });
            unreachable;
        } else {}
        std.log.err("Used: {}", .{reader.idx});
    }

    return .{};
}

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
