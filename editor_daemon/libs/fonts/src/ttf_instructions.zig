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
    var iter = InstructionIter{ .reader = .{ .data = prog } };
    while (try iter.next()) |n| {
        std.log.err("{}", .{n});
    }
    //try decode(prog);
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
                0x04 => return .{ .set = .{ .freedom_vector = .y } },
                0x05 => return .{ .set = .{ .freedom_vector = .x } },
                0x06 => return .{ .set = .{ .projection_vector = .parallel } },
                0x07 => return .{ .set = .{ .projection_vector = .perpendicular } },
                0x08 => return .{ .set = .{ .freedom_vector_line = .parallel } },
                0x09 => return .{ .set = .{ .freedom_vector_line = .perpendicular } },
                0x10, 0x11, 0x12 => return .{ .set = .{ .reference_point = ins - 0x10 } },
                0x13, 0x14, 0x15 => return .{ .set = .{ .zone_pointer = ins - 0x13 } },
                0x16 => return .{ .set = .zone_pointers },
                0x17 => return .{ .set = .loop_variable },
                0x18 => return .{ .grid = .round_to_grid },
                0x19 => return .{ .grid = .round_to_half_grid },
                0x1A => return .{ .set = .minimum_distance },
                0x1B => return .{ .control_flow = .@"else" },
                0x1C => return .{ .control_flow = .jump },
                0x2c => return .{ .function = .start },
                0x2d => return .{ .function = .end },
                0x20 => return .{ .stack = .dup },
                0x21 => return .{ .stack = .pop },
                0x22 => return .{ .stack = .clear },
                0x23 => return .{ .stack = .swap },
                0x25 => return .{ .stack = .copy_indexed },

                0x3D => return .{ .grid = .round_to_double_grid },
                0x44 => return .{ .control_value_table = .write_pixels },
                0x45 => return .{ .control_value_table = .read },

                0x49 => return .{ .measure = .{ .distance = 0 } },
                0x4A => return .{ .measure = .{ .distance = 1 } },
                0x4B => return .{ .measure = .pixels_per_em },
                0x4C => return .{ .measure = .point_size },
                0x60 => return .{ .math = .add },
                0x61 => return .{ .math = .sub },
                0x62 => return .{ .math = .div },
                0x63 => return .{ .math = .mul },
                0x64 => return .{ .math = .abs },
                0x65 => return .{ .math = .neg },
                0x66 => return .{ .math = .floor },
                0x67 => return .{ .math = .ceiling },

                0x50 => return .{ .check = .less_than },
                0x51 => return .{ .check = .less_than_or_equal },
                0x52 => return .{ .check = .greater_than },
                0x53 => return .{ .check = .greater_than_or_equal },
                0x54 => return .{ .check = .equal },
                0x55 => return .{ .check = .not_equal },
                0x56 => return .{ .check = .odd },
                0x57 => return .{ .check = .even },

                0x58 => return .{ .control_flow = .if_test },
                0x59 => return .{ .control_flow = .end_if },
                0x5A => return .{ .check = .@"and" },
                0x5B => return .{ .check = .@"or" },
                0x5C => return .{ .check = .not },
                0x70 => return .{ .control_value_table = .write_font_design_units },
                0x76 => return .{ .grid = .super_round },
                0x77 => return .{ .grid = .super_round_45 },
                0x78 => return .{ .control_flow = .jump_relative_on_true },
                0x79 => return .{ .control_flow = .jump_relative_on_false },
                0x7A => return .{ .grid = .round_off },
                0x7C => return .{ .grid = .round_up_to_grid },
                0x7D => return .{ .grid = .round_down_to_grid },
                0x8B => return .{ .math = .max },
                0x8C => return .{ .math = .min },
                0x8E => return .{ .ins = .instruction_execution_control },
                0xb0...0xb7 => {
                    const num_b = ins - 0xb0 + 1;
                    var bytes = std.mem.zeroes([8]u8);
                    for (0..num_b) |idx| {
                        bytes[idx] = try self.reader.read(u8);
                    }
                    return .{ .pushb = .{ .num = num_b, .bytes = bytes } };
                },
                0xB8...0xBF => {
                    const num_b = ins - 0xb8 + 1;
                    var bytes = std.mem.zeroes([8]u16);
                    for (0..num_b) |idx| {
                        bytes[idx] = try self.reader.read(u16);
                    }
                    return .{ .pushw = .{ .num = num_b, .bytes = bytes } };
                }, //PUSHW
                0xC0...0xDF => {
                    return .{
                        .move_relative_point = .{
                            .direct = .direct,
                            .set_rp0 = (ins & 0x1) != 0,
                            .keep_distance_greater = (ins & 0x2) != 0,
                            .round_distance = (ins & 0x4) != 0,
                            .distance = switch (@as(u2, @truncate(ins >> 3))) {
                                0 => .gray,
                                1 => .black,
                                2 => .white,
                                else => return error.BadInstruction,
                            },
                        },
                    };
                },
                0xE0...0xFF => {
                    return .{
                        .move_relative_point = .{
                            .direct = .indirect,
                            .set_rp0 = (ins & 0x1) != 0,
                            .keep_distance_greater = (ins & 0x2) != 0,
                            .round_distance = (ins & 0x4) != 0,
                            .distance = switch (@as(u2, @truncate(ins >> 3))) {
                                0 => .gray,
                                1 => .black,
                                2 => .white,
                                else => return error.BadInstruction,
                            },
                        },
                    };
                },
                else => {
                    std.log.err("Unhandled ins:{x}", .{ins});
                    return error.TODO;
                },
            }
            unreachable;
        } else {
            return null;
        }
    }
};

const Instruction = union(enum) {
    pushb: struct { num: u8, bytes: [8]u8 },
    pushw: struct { num: u8, bytes: [8]u16 },
    function: enum { start, end },
    stack: enum { pop, swap, dup, clear, copy_indexed },
    set: union(enum) {
        reference_point: u8,
        zone_pointer: u8,
        zone_pointers: void,
        loop_variable: void,
        minimum_distance: void,
        freedom_vector: enum { x, y },
        freedom_vector_line: enum { parallel, perpendicular },
        projection_vector: enum { parallel, perpendicular },
    },
    grid: enum {
        round_to_half_grid,
        round_to_grid,
        round_to_double_grid,
        round_down_to_grid,
        round_up_to_grid,
        round_off,
        super_round,
        super_round_45,
    },
    ins: enum {
        instruction_execution_control,
    },
    check: enum {
        less_than,
        less_than_or_equal,
        greater_than,
        greater_than_or_equal,
        equal,
        not_equal,
        odd,
        even,
        @"and",
        @"or",
        not,
    },
    control_flow: enum {
        if_test,
        @"else",
        end_if,
        jump,
        jump_relative_on_true,
        jump_relative_on_false,
    },
    control_value_table: enum {
        write_pixels,
        write_font_design_units,
        read,
    },
    measure: union(enum) {
        distance: u8,
        pixels_per_em: void,
        point_size: void,
    },
    math: enum {
        abs,
        add,
        sub,
        div,
        mul,
        neg,
        floor,
        ceiling,
        max,
        min,
    },
    move_relative_point: struct {
        direct: enum { direct, indirect },
        set_rp0: bool,
        keep_distance_greater: bool,
        round_distance: bool,
        distance: enum { gray, black, white },
    },
};
