const std = @import("std");

pub const StringRef = struct {
    idx: u32,
};

pub const Value = union(enum) {
    int: i64,
    float: f64,
    string: StringRef,
};
