const std = @import("std");

pub const VarRef = struct {
    idx: u32,
};

pub const Number = struct {
    val: i64,
};

pub const Value = union(enum) {
    number: Number,
    variable: VarRef,
};
