const std = @import("std");
const Value = @import("Value.zig").Value;
const eq = @import("eq.zig");

pub const VM = struct {
    alloc: std.mem.Allocator,
    variables: std.StringArrayHashMap(Value),
    strings: std.ArrayList([]const u8),
    pub fn init(alloc: std.mem.Allocator) VM {
        return .{
            .alloc = alloc,
            .variables = std.StringArrayHashMap(Value).init(alloc),
            .strings = std.ArrayList([]const u8).empty,
        };
    }
    pub fn deinit(self: *VM) void {
        for (self.variables.keys()) |k| {
            self.alloc.free(k);
        }

        self.variables.deinit();
        for (self.strings.items) |k| {
            self.alloc.free(k);
        }

        self.strings.deinit(self.alloc);
    }
    pub fn set(self: *VM, name: []const u8, val: Value) !void {
        std.log.info("set: {s} => {}", .{ name, val });
        if (self.variables.getPtr(name)) |pos| {
            pos.* = val;
        } else {
            const name_dup = try self.alloc.dupe(u8, name);
            errdefer self.alloc.free(name_dup);
            try self.variables.put(name_dup, val);
        }
    }
    pub fn get(self: *VM, name: []const u8) ?Value {
        if (self.variables.get(name)) |val| {
            std.log.info("get: {s} => {}", .{ name, val });
            return val;
        }
        std.log.info("get: {s} => null", .{name});
        return null;
    }

    pub fn exec(self: *VM, equation: []const u8) !Value {
        const e = try eq.compile(equation, self, self.alloc);
        defer e.deinit();
        return e.value;
    }
};

pub const FunctionCall = struct {
    args: []const Value,
};
