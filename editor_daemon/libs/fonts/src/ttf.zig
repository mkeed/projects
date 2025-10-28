const std = @import("std");

pub const Header = struct {
    tables: []const TableRef,

    pub const TableRef = struct {
        data: []const u8,
        name: []const u8,
    };
    const TableRecord = struct {
        tag: [4]u8,
        checksum: u32,
        offset: u32,
        len: u32,
    };
    pub fn deinit(self: Header, alloc: std.mem.Allocator) void {
        alloc.free(self.tables);
    }
    pub fn get(self: Header, name: []const u8) ?[]const u8 {
        for (self.tables) |t| {
            if (std.mem.eql(u8, t.name, name)) {
                return t.data;
            }
        }
        return null;
    }
};

fn calcChecksum(data: []const u8, headAdjust: bool) u32 {
    var sum: u32 = 0;
    var idx: usize = 0;
    while (idx < data.len) {
        defer idx += 4;
        if (headAdjust and idx == 8) continue;
        const buf = [4]u8{
            data[idx],
            if (idx + 1 < data.len) data[idx + 1] else 0,
            if (idx + 2 < data.len) data[idx + 2] else 0,
            if (idx + 3 < data.len) data[idx + 3] else 0,
        };
        sum +%= std.mem.readInt(u32, &buf, .big);
    }
    return sum;
}

pub fn parseHeader(data: []const u8, alloc: std.mem.Allocator) !Header {
    const version = std.mem.readVarInt(u32, data[0..4], .big);
    const num_tables = std.mem.readVarInt(u16, data[4..][0..2], .big);
    _ = version;
    const tables = try alloc.alloc(Header.TableRef, num_tables);
    errdefer alloc.free(tables);
    for (0..num_tables) |t| {
        const idx = 12 + (16 * t);

        const tag = data[idx..][0..4];
        const checksum = std.mem.readVarInt(u32, data[idx + 4 ..][0..4], .big);
        const offset = std.mem.readVarInt(u32, data[idx + 8 ..][0..4], .big);
        const length = std.mem.readVarInt(u32, data[idx + 12 ..][0..4], .big);

        const section_data = data[offset..][0..length];
        const is_head = std.mem.eql(u8, "head", tag);
        const calc_checksum = calcChecksum(section_data, is_head);
        if (checksum != calc_checksum) {
            std.log.err("Bad checksum[{s}] {x} != {x}", .{ tag, checksum, calc_checksum });
            return error.FailedChecksum;
        }
        //std.log.err("[{s}]", .{tag});
        tables[t] = .{
            .data = section_data,
            .name = tag,
        };
    }
    return .{ .tables = tables };
}

pub fn parse_file(file: []const u8, alloc: std.mem.Allocator) !void {
    const header = try parseHeader(file, alloc);
    defer header.deinit(alloc);
    const head = try @import("tables/head.zig").decode(header.get("head") orelse unreachable);
    const os_2 = try @import("tables/os_2.zig").decode(header.get("OS/2") orelse unreachable);
    const post = try @import("tables/post.zig").decode(header.get("post") orelse unreachable);
    const m = try @import("tables/maxp.zig").decode(header.get("maxp") orelse unreachable);
    const n = try @import("tables/name.zig").decode(header.get("name") orelse unreachable);
    var cmap = try @import("tables/cmap.zig").decode(header.get("cmap") orelse unreachable, alloc);
    defer cmap.deinit();
    const hhea = try @import("tables/hhea.zig").decode(header.get("hhea") orelse unreachable, alloc);
    const loca = try @import("tables/loca.zig").decode(header.get("loca") orelse unreachable, head, m);
    const hmtx = try @import("tables/hmtx.zig").decode(header.get("hmtx") orelse unreachable, m, hhea);
    const glyf = try @import("tables/glyf.zig").decode(header.get("glyf") orelse unreachable, alloc, loca, m, &cmap);
    _ = glyf;
    _ = hmtx;
    _ = post;
    _ = os_2;
    _ = n;
}

test {
    const file = @embedFile("Roboto-Black.ttf");

    const header = try parseHeader(file, std.testing.allocator);
    defer header.deinit(std.testing.allocator);
    const head = try @import("tables/head.zig").decode(header.get("head") orelse unreachable);
    const os_2 = try @import("tables/os_2.zig").decode(header.get("OS/2") orelse unreachable);
    const post = try @import("tables/post.zig").decode(header.get("post") orelse unreachable);
    const m = try @import("tables/maxp.zig").decode(header.get("maxp") orelse unreachable);
    const n = try @import("tables/name.zig").decode(header.get("name") orelse unreachable);
    var cmap = try @import("tables/cmap.zig").decode(header.get("cmap") orelse unreachable, std.testing.allocator);
    defer cmap.deinit();
    const hhea = try @import("tables/hhea.zig").decode(header.get("hhea") orelse unreachable, std.testing.allocator);
    const loca = try @import("tables/loca.zig").decode(header.get("loca") orelse unreachable, head, m);
    const hmtx = try @import("tables/hmtx.zig").decode(header.get("hmtx") orelse unreachable, m, hhea);
    const glyf = try @import("tables/glyf.zig").decode(header.get("glyf") orelse unreachable, std.testing.allocator, loca, m, &cmap);

    std.log.err("map: 0xc0 => {x}", .{cmap.get(0xc0)});
    std.log.err("maxp {}", .{m});
    std.log.err("name {}", .{n});
    std.log.err("hhea {}", .{hhea});
    std.log.err("hmtx {}", .{hmtx});
    std.log.err("head {}", .{head});
    std.log.err("cmap {}", .{cmap});
    std.log.err("OS/2 {}", .{os_2});
    std.log.err("post {}", .{post});
    std.log.err("glyf {}", .{glyf});
    std.log.err("loca {}", .{loca});
    for (header.tables) |t| {
        std.log.err("[{s}][{}]", .{ t.name, t.data.len });
    }
}
