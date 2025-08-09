const std = @import("std");

inline fn isErrFn(comptime T: type) bool {
    const type_info = @typeInfo(T);
    const info = switch (type_info) {
        .@"fn" => |f| f,
        else => @compileError("Not A fucntion"),
    };
    if (info.return_type) |ret| {
        switch (@typeInfo(ret)) {
            .error_union => return true,
            else => return false,
        }
    } else {
        return false;
    }
}

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();
        val: std.ArrayList(*T),
        alloc: std.mem.Allocator,
        lock: std.Thread.RwLock,
        backup_list: std.ArrayList(*T),
        backup_lock: std.Thread.Mutex,
        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .val = std.ArrayList(*T).init(alloc),
                .alloc = alloc,
                .lock = .{},
                .backup_list = std.ArrayList(*T).init(alloc),
                .backup_lock = .{},
            };
        }
        pub fn deinit(self: *Self) void {
            self.lock.lock();
            defer self.lock.unlock();
            for (self.val.items) |i| {
                if (@hasDecl(T, "deinit")) {
                    i.deinit();
                }
                self.alloc.destroy(i);
            }
            self.val.deinit();
            {
                self.backup_lock.lock();
                defer self.backup_lock.unlock();
                for (self.backup_list.items) |i| {
                    if (@hasDecl(T, "deinit")) {
                        i.deinit();
                    }
                    self.alloc.destroy(i);
                }
            }
            self.backup_list.deinit();
        }
        pub fn push_item(self: *Self, val: T) !*T {
            const pos = try self.alloc.create(T);
            errdefer self.alloc.destroy(pos);
            pos.* = val;
            if (self.lock.tryLock()) {
                defer self.lock.unlock();

                try self.val.append(pos);
            } else {
                self.backup_lock.lock();
                defer self.backup_lock.unlock();
                try self.backup_list.append(pos);
            }
            return pos;
        }
        pub fn push(self: *Self, comptime func: []const u8, args: anytype) !*T {
            const function = @field(T, func);
            const val = if (isErrFn(function)) try @call(.auto, function, args) else @call(.auto, function, args);
            errdefer {
                if (@hasDecl(T, "deinit")) {
                    val.deinit();
                }
            }
            return try self.push_item(val);
        }
        fn push_backup_list(self: *Self) !void {
            self.backup_lock.lock();
            defer self.backup_lock.unlock();
            if (self.backup_list.items.len > 0) {
                self.lock.lock();
                defer self.lock.unlock();
                defer self.backup_list.clearRetainingCapacity();
                for (self.backup_list.items) |i| try self.val.append(i);
            }
        }
        pub fn len(self: Self) usize {
            return self.val.items.len + self.backup_list.items.len;
        }
        pub fn iterate(
            self: *Self,
            iter_unit: anytype,
            comptime func: []const u8,
        ) !void {
            {
                self.lock.lockShared();
                defer self.lock.unlockShared();
                for (self.val.items) |item| {
                    const function = @field(@TypeOf(iter_unit), func);

                    const args = .{ iter_unit, item };

                    const early_return = if (isErrFn(@TypeOf(function))) try @call(.auto, function, args) else @call(.auto, function, args);
                    if (early_return) return;
                }
            }
            try self.push_backup_list();
        }
    };
}
