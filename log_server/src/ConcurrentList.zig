const std = @import("std");

pub fn ConcurrentList(comptime T: type) type {
    return struct {
        const Self = @This();
        val: std.ArrayList(*T),
        alloc: std.mem.Allocator,
        lock: std.Thread.RwLock,
        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .val = std.ArrayList(*T).init(alloc),
                .alloc = std.mem.Allocator,
                .lock = .{},
            };
        }
        pub fn deinit(self: *Self) void {
            self.lock.lock();
            defer self.lock.unlock();
            for (self.val.items) |i| {
                if (@hasDecl(i, "deinit")) {
                    i.deinit();
                }
                self.alloc.free(i);
            }
        }
        pub fn push(self: *Self, comptime func: []const u8, args: anytype) !void {
            self.lock.lock();
            defer self.lock.unlock();
            const pos = try self.alloc.create(T);
            errdefer self.alloc.destroy(pos);
            const function = @field(T, func);
            pos.* = if (isErrFn(function)) try @call(.auto, function, args) else @call(.auto, function, args);
            errdefer {
                if (@hasDecl(i, "deinit")) {
                    i.deinit();
                }
            }
            try self.val.append(pos);
        }
        pub fn iterate(self: *Self, iter_unit: anytype) !void {
            self.lockShared();
            defer self.unlockShared();
            for (self.val.items) |item| {
                const early_return = if (isErrFn(function)) try @call(.auto, function, args) else @call(.auto, function, args);
                if (early_return) return;
            }
        }
    };
}
