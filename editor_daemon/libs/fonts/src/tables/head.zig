const std = @import("std");
const util = @import("../utils.zig");

pub const Flags = packed struct(u16) {
    baseline_at_0: bool,
    left_sidebearing_at_0: bool,
    instructions_depend_on_point_size: bool,
    force_ppem_to_integer: bool,
    instructions_may_alter_advance_width: bool,
    res: u6,
    lossless: bool,
    font_converted: bool,
    optimized_for_cleartype: bool,
    last_resort_font: bool,
    res2: bool,
};

pub const MacStyle = packed struct(u16) {
    bold: bool,
    italic: bool,
    underline: bool,
    outline: bool,
    shadow: bool,
    condensed: bool,
    extended: bool,
    res: u9,
};

pub const head = struct {
    majorVersion: u16,
    minorVersion: u16,
    fontRev: util.Fixed,
    checksumADj: u32,
    magic: u32,
    flags: Flags,
    unitsPerEm: u16,
    created: util.LONGDATETIME,
    modified: util.LONGDATETIME,
    xMin: i16,
    yMin: i16,
    xMax: i16,
    yMax: i16,
    macStyle: MacStyle,
    lowestRecPPEM: u16,
    fontDirectionHint: i16,
    indexToLocFormat: i16,
    glyphDataFormat: i16,
};

pub fn decode(data: []const u8) !head {
    return try util.read(head, data);
}
