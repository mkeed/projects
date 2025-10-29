//https://learn.microsoft.com/en-us/typography/opentype/spec/tt_instructions
const std = @import("std");
const util = @import("utils.zig");

//fn decode(

const NPUSHB = 0x40;
const NPUSHW = 0x41;
const PUSHB = &.{ 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7 };
const PUSHW = &.{ 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF };
//b7 07 06 05 04 03 02 01 00   PUSHB[7] 7,6,5,4,3,2,1,0
//2c 20 10 b0 02 25 49 64 b0 40 51 58 20 c8 59 21 2d
//2c b0 02 25 49 64 b0 40 51 58 20 c8 59 21 2d
//  2c 20 10 07 20 b0 00 50 b0 0d 79 20 b8 ff ff 50 58 04 1b 05 59 b0 05 1c b0 03 25 08 b0 04 25 23 e1 20 b0 00 50 b0 0d 79 20 b8 ff ff 50 58 04 1b 05 59 b0 05 1c b0 03 25 08 e1 2d
//2c 4b 50 58 20 b8 01 28 45 44 59 21 2d
//2c b0 02 25 45 60 44 2d
//2c 4b 53 58 b0 02 25 b0 02 25 45 44 59 21 21 2d
//2c 45 44 2d
//2c b0 02 25 b0 02 25 49 b0 05 25 b0 05 25 49 60 b0 20 63 68 20 8a 10 8a 23 3a 8a 10 65 3a 2d

test {
    const prog = &.{
        0xb7, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00, 0x2c, 0x20, 0x10, 0xb0, //
        0x02, 0x25, 0x49, 0x64, 0xb0, 0x40, 0x51, 0x58, 0x20, 0xc8, 0x59, 0x21, 0x2d, //
        0x2c, 0xb0, 0x02, 0x25, 0x49, 0x64, 0xb0, 0x40, 0x51, 0x58, 0x20, 0xc8, 0x59,
        0x21, 0x2d, 0x2c, 0x20, 0x10, 0x07, 0x20, 0xb0, 0x00, 0x50, 0xb0, 0x0d, 0x79,
        0x20, 0xb8, 0xff, 0xff, 0x50, 0x58, 0x04, 0x1b, 0x05, 0x59, 0xb0, 0x05, 0x1c,
        0xb0, 0x03, 0x25, 0x08, 0xb0, 0x04, 0x25, 0x23, 0xe1, 0x20, 0xb0, 0x00, 0x50,
        0xb0, 0x0d, 0x79, 0x20, 0xb8, 0xff, 0xff, 0x50, 0x58, 0x04, 0x1b, 0x05, 0x59,
        0xb0, 0x05, 0x1c, 0xb0, 0x03, 0x25, 0x08, 0xe1, 0x2d, 0x2c, 0x4b, 0x50, 0x58,
        0x20, 0xb8, 0x01, 0x28, 0x45, 0x44, 0x59, 0x21, 0x2d, 0x2c, 0xb0, 0x02, 0x25,
        0x45, 0x60, 0x44, 0x2d, 0x2c, 0x4b, 0x53, 0x58, 0xb0, 0x02, 0x25, 0xb0, 0x02,
        0x25, 0x45, 0x44, 0x59, 0x21, 0x21, 0x2d, 0x2c, 0x45, 0x44, 0x2d, 0x2c, 0xb0,
        0x02, 0x25, 0xb0, 0x02, 0x25, 0x49, 0xb0, 0x05, 0x25, 0xb0, 0x05, 0x25, 0x49,
        0x60, 0xb0, 0x20, 0x63, 0x68, 0x20, 0x8a, 0x10, 0x8a, 0x23, 0x3a, 0x8a, 0x10,
        0x65, 0x3a, 0x2d,
    };
    try decode(prog);
}

fn decode(data: []const u8) !void {
    var reader = util.Reader{ .data = data };
    while (reader.tryGetByte()) |ins| {
        switch (ins) {
            0x04, 0x05 => std.log.err("Set Freedom_Vector to Coordinate Axis", .{}),
            0x06, 0x07 => std.log.err("Set Projection_Vector To Line", .{}),
            0x08, 0x09 => std.log.err("Set Freedom_Vector to Line", .{}),
            0xb0...0xb7 => {
                const num_b = ins - 0xb0 + 1;
                for (0..num_b) |_| {
                    std.log.err("PUSHB[{x}]", .{try reader.read(u8)});
                }
            }, //PUSHB
            0xb8...0xbF => {
                const num_b = ins - 0xb8 + 1;
                for (0..num_b) |_| {
                    std.log.err("PUSHW[{x}]", .{try reader.read(u16)});
                }
            }, //PUSHW
            0x2c => std.log.err("Start function", .{}),
            0x2d => std.log.err("end Function", .{}),
            0x20 => std.log.err("DUPlicate", .{}),
            0x21 => std.log.err("Pop", .{}),
            0x23 => std.log.err("SWAP", .{}),
            0x10 => std.log.err("Set Reference Point 0", .{}),
            0x25 => std.log.err("Copy INDEXed element", .{}),
            0x44 => std.log.err("Write Control Value Table in Pixel units", .{}),
            0x45 => std.log.err("Read Control Value Table", .{}),
            0x49 => std.log.err("Measure Distance[{}]", .{0}),
            0x4A => std.log.err("Measure Distance[{}]", .{1}),
            0x4B => std.log.err("Measure Pixels Per EM", .{}),
            0x64 => std.log.err("ABSolute value", .{}),
            0x50 => std.log.err("Less than", .{}),
            0x51 => std.log.err("Less than Or Equal", .{}),
            0x52 => std.log.err("Greated than", .{}),

            0x58 => std.log.err("IF test", .{}),
            0x59 => std.log.err("End IF", .{}),
            0x1b => std.log.err("Else", .{}),
            0x1c => std.log.err("Jump", .{}),
            0x79 => std.log.err("Jump Relative On False", .{}),
            0xC0...0xDF => std.log.err("Move Direct Relative Point", .{}),
            0xE0...0xFF => std.log.err("Move Indirect Relative Point", .{}),
            else => {
                std.log.err("Not Handled {x}", .{ins});
                return error.TODO;
            },
        }
    }
}

const InstructionIter = struct {
    reader: util.Reader,

    pub fn next(self: *InstructionIter) !?Instruction {
        if (self.reader.tryGetByte()) |ins| {
            switch (ins) {
                0xb0...0xb7 => {
                    const num_b = ins - 0xb0 + 1;
                    var bytes = std.mem.zeroes([8]u8);
                    for (0..num_b) |idx| {
                        bytes[idx] = try reader.read(u8);
                    }
                    return .{ .pushb = .{ .num = num_b, .bytes = bytes } };
                },
                0xB8...0xBF => {
                    const num_b = ins - 0xb8 + 1;
                    var bytes = std.mem.zeroes([8]u16);
                    for (0..num_b) |idx| {
                        bytes[idx] = try reader.read(u16);
                    }
                    return .{ .pushw = .{ .num = num_b, .bytes = bytes } };
                }, //PUSHW
                0x2c => std.log.err("Start function", .{}),
                0x2d => std.log.err("end Function", .{}),
                0x20 => std.log.err("DUPlicate", .{}),
                0x21 => std.log.err("Pop", .{}),
                0x23 => std.log.err("SWAP", .{}),
                0x10 => std.log.err("Set Reference Point 0", .{}),
                0x25 => std.log.err("Copy INDEXed element", .{}),
                0x44 => std.log.err("Write Control Value Table in Pixel units", .{}),
                0x45 => std.log.err("Read Control Value Table", .{}),
                0x49 => std.log.err("Measure Distance[{}]", .{0}),
                0x4A => std.log.err("Measure Distance[{}]", .{1}),
                0x4B => std.log.err("Measure Pixels Per EM", .{}),
                0x64 => std.log.err("ABSolute value", .{}),
                0x50 => std.log.err("Less than", .{}),
                0x51 => std.log.err("Less than Or Equal", .{}),
                0x52 => std.log.err("Greated than", .{}),

                0x58 => std.log.err("IF test", .{}),
                0x59 => std.log.err("End IF", .{}),
                0x1b => std.log.err("Else", .{}),
                0x1c => std.log.err("Jump", .{}),
                0x79 => std.log.err("Jump Relative On False", .{}),
                0xC0...0xDF => std.log.err("Move Direct Relative Point", .{}),
                0xE0...0xFF => std.log.err("Move Indirect Relative Point", .{}),
            }
        } else {
            return null;
        }
    }
};

const Instruction = union(enum) {
    pushb: struct { num: u8, bytes: [8]u8 },
    pushw: struct { num: u8, bytes: [8]u16 },
    function: enum { start, end },
};
