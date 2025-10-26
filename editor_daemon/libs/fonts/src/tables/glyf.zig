const std = @import("std");
const util = @import("../utils.zig");
const loca = @import("loca.zig").loca;
const maxp = @import("maxp.zig").maxp;

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
    next_end: u16,
    num: usize,
    idx: usize = 0,
    glyf_id: u32 = 0,
    pub fn init(data: []const u8, num: u32) !EndIter {
        var endPoints = util.Reader{ .data = data };
        const next_end = try endPoints.read(u16);

        return .{
            .eps = endPoints,
            .next_end = next_end,
            .num = num,
            .idx = 0,
            .glyf_id = 0,
        };
    }

    pub fn next(self: *EndIter) !?bool {
        defer self.idx += 1;
        var new = false;
        if (self.idx > self.next_end) {
            new = true;
            self.glyf_id += 1;
            if (self.glyf_id >= self.num) return null;
            self.next_end = try self.eps.read(u16);
        }
        return new;
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
    }
    pub fn next(self: *PointIter) ?struct { p: Point, flag: Flag } {
        if (self.flag.next()) |n| {
            std.debug.assert(n.onCurve == false);
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
                },
                .flag = n,
            };
        }
        return null;
    }
};

pub fn decode(data: []const u8, alloc: std.mem.Allocator, l: loca, m: maxp) !glyf {
    var contour_points = std.ArrayList(Point){};
    try contour_points.ensureTotalCapacity(alloc, m.maxPoints);

    defer contour_points.deinit(alloc);
    for (0..l.numGlyphs) |idx| {
        const pos = l.get(idx);
        var reader = util.Reader{ .data = data[pos..] };
        const header = try reader.read(glyf_header);
        std.log.err("{}", .{header});
        if (header.numberOfContours > 0) {
            var iter = try EndIter.init(try reader.takeBytes(@intCast(2 * header.numberOfContours)), @intCast(header.numberOfContours));
            const end_pt = std.mem.readVarInt(u16, iter.eps.data[@intCast(2 * (header.numberOfContours - 1))..][0..2], .big);

            const ins_length = try reader.read(u16);
            const ins = try reader.takeBytes(ins_length);
            var flag_iter = FlagIter{ .flags = reader.data[reader.idx..] };
            const end_of_flags = flag_iter.total_offset(end_pt);
            _ = try reader.takeBytes(end_of_flags.flag_end);
            const x_s = try reader.takeBytes(end_of_flags.xCoordend);
            const y_s = reader.data[reader.idx..];
            std.log.err("{} X {}", .{ std.mem.readVarInt(i16, x_s[0..2], .big), std.mem.readVarInt(i16, y_s[0..2], .big) });
            std.log.err("`{x}` `{x}`", .{ x_s, y_s });
            std.log.err("[{}]{x}[{}]", .{ ins_length, ins, end_of_flags });
            var pt = PointIter{
                .flag = flag_iter,
                .x_data = x_s,
                .y_data = y_s,
                .points = &contour_points,
                .contour_iter = iter,
            };
            while (try iter.next()) |_| {
                const point = pt.next().?;
                std.log.err("{}", .{point.p});
                //const flag = flag_iter.next().?;
                //std.log.err("{}|{}", .{ idx2, flag });
            }
        } else {}
        break;
    }

    return .{};
}
