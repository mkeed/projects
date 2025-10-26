const std = @import("std");
const util = @import("../utils.zig");

pub const name = struct {
    version: u16,
    count: u16,
    storageOffset: u16,
};

pub const NameRecord = struct {
    platformId: u16,
    encodingId: u16,
    languageId: u16,
    nameId: u16,
    length: u16,
    stringOffset: u16,
};

pub fn decode(data: []const u8) !name {
    const n = try util.read(name, data);
    std.log.err("{}", .{n});
    var utf16_le_arr = std.mem.zeroes([256]u16);
    var utf8_buf = std.mem.zeroes([512]u8);
    for (0..n.count) |idx| {
        const offset = util.packedSize(NameRecord) * idx + @sizeOf(u16) * 3;
        const record = try util.read(NameRecord, data[offset..]);

        const storage_offset = n.storageOffset + record.stringOffset;
        const string = data[storage_offset..][0..record.length];
        for (0..string.len / 2) |utf8_idx| {
            utf16_le_arr[utf8_idx] = std.mem.readVarInt(u16, string[utf8_idx * 2 ..][0..2], .big);
        }
        const utf8_string = try std.unicode.utf16LeToUtf8(&utf8_buf, utf16_le_arr[0 .. string.len / 2]);
        _ = utf8_string;
        //std.log.err("{} => [{s}]", .{ record, utf8_buf[0..utf8_string] });
    }

    return n;
}

pub const NameId = enum(u16) {
    copyright = 0,
    font_family = 1,
    font_subfamily = 2,
    unique_font_identifier = 3,
    full_font_name = 4,
    version_string = 5,
    postscript_name = 6,
    trademark = 7,
    manufacturer_name = 8,
    designer = 9,
    description = 10,
    url_vendor = 11,
    url_designer = 12,
    license_description = 13,
    licence_info_url = 14,
    reserverd = 15,
    typographic_family_name = 16,
    typographic_subfamily_name = 17,
    compatible_full = 18,
    sample_text = 19,
    postscript_cid_findfont_name = 20,
    wws_family_name = 21,
    wws_subfamily_name = 22,
    light_background_palette = 23,
    dark_background_palette = 24,
    variations = 25,
};
