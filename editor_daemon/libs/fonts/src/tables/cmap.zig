const std = @import("std");
const util = @import("../utils.zig");

const CmapHeader = struct {
    version: u16,
    numTables: u16,
};

pub const PlatformId = enum(u16) {
    unicode = 0,
    macinntosh = 1,
    ISO = 2,
    windows = 3,
    custom = 4,
};

const UnicodeEncodingIds = enum(u16) {
    unicode_1_0 = 0, //deprecated
    unicode_1_1 = 1, //deprecated
    iso_iec_10646 = 2, //deprecated
    unicode_2_0_bmp = 3,
    unicode_2_0_full = 4,
    unicode_variation_sequences = 5,
    unicode_full = 6,
};

const ISOencodingIds = enum(u16) {
    ascii = 0,
    iso_10646 = 1,
    iso_8859_1 = 2,
};

const WindowsEncodingIds = enum(u16) {
    symbol = 0,
    unicode_bmp = 1,
    shiftJIS = 2,
    PRC = 3,
    Big5 = 4,
    Wansung = 5,
    Johab = 6,
    unicode_Full = 10,
};

const EncodingRecord = struct {
    platformId: PlatformId,
    encodingId: u16,
    subtableOffset: u32,
};

pub const subtable_header = struct {
    format: u16,
    length: u16,
};

pub const cmap = struct {
    pub const Glyphs = struct {
        maps: [256]u32 = std.mem.zeroes([256]u32),
    };
    alloc: std.mem.Allocator,
    map: std.AutoArrayHashMap(u32, Glyphs),

    pub fn init(alloc: std.mem.Allocator) cmap {
        return .{
            .alloc = alloc,
            .map = std.AutoArrayHashMap(u32, Glyphs).init(alloc),
        };
    }
    pub fn deinit(self: *cmap) void {
        self.map.deinit();
        self.* = undefined;
    }
    pub fn set(self: *cmap, char: u32, code: u32) !void {
        const key = char & ~@as(u32, 0xFF);
        const idx: u8 = @truncate(char);
        if (self.map.getPtr(key)) |val| {
            val.maps[idx] = code;
        } else {
            var glyphs = Glyphs{};
            glyphs.maps[idx] = code;
            try self.map.put(key, glyphs);
        }
    }
    pub fn get(self: *const cmap, char: u32) u32 {
        const key = char & ~@as(u32, 0xFF);
        const idx: u8 = @truncate(char);
        if (self.map.get(key)) |val| {
            return val.maps[idx];
        } else {
            return 0;
        }
    }
    pub fn revMap(self: *const cmap, code: u32) ?u32 {
        var iter = self.map.iterator();
        while (iter.next()) |k| {
            for (k.value_ptr.maps, 0..) |m, idx| {
                if (m == code) {
                    return @intCast(k.key_ptr.* + idx);
                }
            }
        }
        return null;
    }
};

pub fn decode(data: []const u8, alloc: std.mem.Allocator) !cmap {
    var ret = cmap.init(alloc);
    errdefer ret.deinit();
    const header = try util.read(CmapHeader, data);
    for (0..header.numTables) |t| {
        const offset = util.packedSize(CmapHeader) + t * util.packedSize(EncodingRecord);
        const rec = try util.read(EncodingRecord, data[offset..]);

        const subtable = try util.read(subtable_header, data[rec.subtableOffset..]);

        switch (subtable.format) {
            4 => try parse_v4(data[rec.subtableOffset..][0..subtable.length], &ret),
            6 => try parse_v6(data[rec.subtableOffset..][0..subtable.length], &ret),
            12 => try parse_v12(data[rec.subtableOffset..], &ret),
            else => {
                std.log.err("Subtable:{}", .{subtable});
                return error.Unknown;
            },
        }
    }
    return ret;
}

const v4_header = struct {
    format: u16,
    length: u16,
    language: u16,
    segCountX2: u16,
    searchRange: u16,
    entrySelector: u16,
    rangeShift: u16,
};

fn parse_v4(data: []const u8, c: *cmap) !void {
    const header = try util.read(v4_header, data);
    var idx = util.packedSize(v4_header);
    var ends = util.Reader{ .data = data[idx..][0..header.segCountX2] };
    idx += header.segCountX2 + @sizeOf(u16);
    var starts = util.Reader{ .data = data[idx..][0..header.segCountX2] };
    idx += header.segCountX2;
    var idDeltas = util.Reader{ .data = data[idx..][0..header.segCountX2] };
    idx += header.segCountX2;
    var idRanges = util.Reader{ .data = data[idx..][0..header.segCountX2] };
    idx += header.segCountX2;
    const glyphIdArray = data[idx..];
    const num_segs = header.segCountX2 / 2;

    for (0..num_segs) |seg_idx| {
        const end: i32 = try ends.read(u16);
        const start: i32 = try starts.read(u16);
        if (end < start) return error.BadData;
        const idDelta = try idDeltas.read(i16);
        const idRange = try idRanges.read(u16);
        if (idRange == 0) {
            var char = start;
            while (char < end) : (char += 1) {
                try c.set(@intCast(char), @intCast(char + idDelta));
            }
        } else {
            var char = start;
            var char_off: usize = 0;
            while (char < end) : (char += 1) {
                defer char_off += 1;
                const new_offset = (idRange + seg_idx * @sizeOf(u16)) - header.segCountX2 + char_off;
                const glyphId = std.mem.readVarInt(u16, glyphIdArray[new_offset..][0..2], .big);

                try c.set(@intCast(char), @intCast(glyphId));
            }
        }
    }
}

const v12_header = struct {
    format: u16,
    res: u16,
    length: u32,
    lang: u32,
    numGroups: u32,
};

const SequentialMapGroup = struct {
    startChar: u32,
    endChar: u32,
    startGlyphID: u32,
};

fn parse_v12(data: []const u8, c: *cmap) !void {
    var reader = util.Reader{ .data = data };
    const header = try reader.read(v12_header);
    for (0..header.numGroups) |_| {
        const group = try reader.read(SequentialMapGroup);
        const num_items = group.endChar - group.startChar + 1;
        for (0..num_items) |_idx| {
            const idx: u32 = @intCast(_idx);
            try c.set(group.startChar + idx, group.startGlyphID + idx);
        }
    }
}

const v6_header = struct {
    format: u16,
    length: u16,
    language: u16,
    firstCode: u16,
    entryCount: u16,
};

fn parse_v6(data: []const u8, c: *cmap) !void {
    var reader = util.Reader{ .data = data };
    const header = try reader.read(v6_header);
    for (0..header.entryCount) |ec| {
        const code = try reader.read(u16);
        try c.set(@intCast(header.firstCode + ec), code);
    }
}
