const std = @import("std");

pub const MathOp = enum {
    add,
    sub,
    multiply,
    divide,
};

pub const FuncRef = struct {
    module: u16,
    func: u16,
};

pub const FunctionCall = struct {
    num_args: u16,
    func: FuncRef,
};

pub const Op = union(enum) {
    math: MathOp,
    functionCall: FunctionCall,
};
