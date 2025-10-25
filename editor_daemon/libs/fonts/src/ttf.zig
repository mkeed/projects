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

fn parseHeader(data: []const u8, alloc: std.mem.Allocator) !Header {
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
        tables[t] = .{
            .data = section_data,
            .name = tag,
        };
    }
    return .{ .tables = tables };
}

test {
    const file = @embedFile("Roboto-Black.ttf");

    const header = try parseHeader(file, std.testing.allocator);
    defer header.deinit(std.testing.allocator);
    const m = try @import("tables/maxp.zig").decode(header.get("maxp") orelse unreachable, std.testing.allocator);
    std.log.err("{}", .{m});
}
