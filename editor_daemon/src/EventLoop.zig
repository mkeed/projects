const std = @import("std");
const Concurrent = @import("concurrent.zig");
pub const EventLoopOpts = struct {
    listener_type: type,
    num_threads: ?u8 = null,
};
const ThreadState = enum {
    Sleep,
    Running,
    AwaitingReaping,
};
pub fn listenItem(comptime T: type) type {
    return struct {
        t: T,
        fd: std.posix.fd_t,
        state: ThreadState,
    };
}

pub fn EventLoop(comptime opts: EventLoopOpts) type {
    return struct {
        const Self = @This();
        const ListenItem = listenItem(opts.listener_type);
        items: Concurrent.List(ListenItem),
        threadPool: *std.Thread.Pool,
        alloc: std.mem.Allocator,
        pub fn init(alloc: std.mem.Allocator) !Self {
            var tp = try alloc.create(std.Thread.Pool);
            errdefer tp.deinit();
            try std.Thread.Pool.init(tp, .{
                .allocator = alloc,
                .n_jobs = opts.num_threads orelse null,
            });
            return .{
                .items = Concurrent.List(ListenItem).init(alloc),
                .threadPool = tp,
                .alloc = alloc,
            };
        }
        pub fn deinit(self: *Self) void {
            self.items.deinit();
            self.threadPool.deinit();
            self.alloc.destroy(self.threadPool);
        }
        pub fn run(self: *Self) !void {
            var pollfds = std.ArrayList(std.posix.pollfd).init(self.alloc);
            defer pollfds.deinit();
            while (self.items.len() > 0) {
                pollfds.clearRetainingCapacity();
                try self.items.iterate(add_pidfs(&pollfds));

                const num_ret = try std.posix.poll(pollfds.items, -1);
                if (num_ret == 0) continue;
                for (self.pollfs.items) |ret| {
                    if (ret.revents != 0) {}
                }
            }
        }
        const AddPidfds = struct {
            arr: *std.ArrayList(std.posix.pollfd),
            fn add(self: AddPidfds, item: *ListenItem) !void {
                try self.arr.append(.{
                    .fd = item.fd,
                    .events = std.posix.POLL.IN,
                    .revents = 0,
                });
            }
        };

        fn add_pidfs(arr: *std.ArrayList(std.posix.pollfd)) AddPidfds {
            return .{ .arr = arr };
        }
    };
}
