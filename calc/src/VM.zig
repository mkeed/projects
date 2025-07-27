const std = @import("std");

pub const Variable = struct {
    value: i64,
};

pub const VM = struct {
    alloc: std.mem.Allocator,
    variables: std.StringArrayHashMap(Variable),
    pub fn init(alloc: std.mem.Allocator) VM {
        return .{
            .alloc = alloc,
            .variables = std.StringArrayHashMap(Variable).init(alloc),
        };
    }
    pub fn deinit(self: *VM) void {
        for (self.variables.keys()) |k| {
            self.alloc.free(k);
        }

        self.variables.deinit();
    }
    pub fn set(self: *VM, name: []const u8, val: Variable) !void {
        if (self.variables.getPtr(name)) |pos| {
            pos.* = val;
        } else {
            const name_dup = try alloc.dupe(u8, name);
            errdefer self.alloc.free(name_dup);
            try self.variables.put(val);
        }
    }
    pub fn get(self: *VM, name: []const u8) ?val {
        if (self.variables.get(name)) |val| {
            return val;
        }
        return null;
    }
};
