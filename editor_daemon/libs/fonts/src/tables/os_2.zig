const std = @import("std");
const util = @import("../utils.zig");

pub const os_2_v0 = struct {
    version: u16,
    xAvgCharWidth: util.FWORD,
    usWeightClass: u16,
    usWidthClass: u16,
    fsType: u16,
    ySubscriptXSize: util.FWORD,
    ySubscriptYSize: util.FWORD,
    ySubscriptXOffset: util.FWORD,
    ySubscriptYOffset: util.FWORD,
    ySuperscriptXSize: util.FWORD,
    ySuperscriptYSize: util.FWORD,
    ySuperscriptXOffset: util.FWORD,
    ySuperscriptYOffset: util.FWORD,
    yStrikeoutSize: util.FWORD,
    yStrikeoutPosition: util.FWORD,
    sFamilyClass: i16,
    panose: [10]u8,
    ulUnicodeRange1: u32,
    ulUnicodeRange2: u32,
    ulUnicodeRange3: u32,
    ulUnicodeRange4: u32,
    achVendID: util.Tag,
    fsSelection: u16,
    usFirstCharIndex: u16,
    usLastCharIndex: u16,
    sTypoAscender: util.FWORD,
    sTypoDescender: util.FWORD,
    sTypoLineGap: util.FWORD,
    usWinAscent: util.UFWORD,
    usWinDescent: util.UFWORD,
};

const v1_offset = util.packedSize(os_2_v0);
pub const os_2_v1 = struct {
    UlCodePageRange1: u32,
    UlCodePageRange2: u32,
};

const v4_offset = util.packedSize(os_2_v1) + v1_offset;
pub const os_2_v4 = struct {
    sxHeight: util.FWORD,
    sCapHeight: util.FWORD,
    usDefaultChar: u16,
    usBreakChar: u16,
    usMaxContext: u16,
};

const v5_offset = util.packedSize(os_2_v4) + v4_offset;
pub const os_2_v5 = struct {
    usLowerOpticalPointSize: u16,
    usUpperOpticalPointSize: u16,
};

pub const os_2 = struct {
    v0: os_2_v0,
    v1: ?os_2_v1,
    v4: ?os_2_v4,
    v5: ?os_2_v5,
};

pub fn decode(data: []const u8) !os_2 {
    const v0 = try util.read(os_2_v0, data);

    return .{
        .v0 = v0,
        .v1 = if (v0.version >= 1) try util.read(os_2_v1, data[v1_offset..]) else null,
        .v4 = if (v0.version >= 4) try util.read(os_2_v4, data[v4_offset..]) else null,
        .v5 = if (v0.version >= 5) try util.read(os_2_v5, data[v5_offset..]) else null,
    };
}
