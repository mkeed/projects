const std = @import("std");

pub const Sin = struct {
    val: f64,
    pub fn run(self: Sin) f64 {
        return @sin(self.val);
    }
};

pub const Cos = struct {
    val: f64,
    pub fn run(self: Cos) f64 {
        return @cos(self.val);
    }
};

pub const Tan = struct {
    val: f64,
    pub fn run(self: Tan) f64 {
        return @tan(self.val);
    }
};
