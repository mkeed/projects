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
        to_remove: Concurrent.List(std.posix.fd_t),
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
                .to_remove = Concurrent.List(std.posix.fd_t).init(alloc),
            };
        }
        pub fn deinit(self: *Self) void {
            self.items.deinit();
            self.to_remove.deinit();
            self.threadPool.deinit();
            self.alloc.destroy(self.threadPool);
        }

        const list_item = struct {
            pollfd: std.posix.pollfd,
            item: *ListenItem,
        };

        pub fn run(self: *Self) !void {
            var pollfds = std.MultiArrayList(list_item){};
            defer pollfds.deinit(self.alloc);
            while (self.items.len() > 0) {
                pollfds.clearRetainingCapacity();
                try self.items.iterate(add_pidfs(&pollfds, self.alloc), "add");
                const polls_fd = pollfds.items(.pollfd);
                const items = pollfds.items(.item);
                const num_ret = try std.posix.poll(polls_fd, -1);
                std.log.err("poll ret:{}", .{num_ret});
                if (num_ret == 0) continue;
                for (polls_fd, items) |ret, item| {
                    if (ret.revents != 0) {
                        try self.threadPool.spawn(run_thread, .{ item, self });
                    }
                }
            }
        }

        fn run_thread(item: *ListenItem, el: *Self) void {
            item.state = .Running;
            var ret_state = ThreadState.Sleep;
            _ = &ret_state;
            defer item.state = ret_state;
            item.t.handle(item.fd, el) catch {
                ret_state = .AwaitingReaping;
            };
        }

        pub const AddPidfds = struct {
            arr: *std.MultiArrayList(list_item),
            alloc: std.mem.Allocator,
            pub fn add(self: AddPidfds, item: *ListenItem) !bool {
                if (item.state == .Sleep) {
                    try self.arr.append(
                        self.alloc,
                        .{
                            .pollfd = .{
                                .fd = item.fd,
                                .events = std.posix.POLL.IN,
                                .revents = 0,
                            },
                            .item = item,
                        },
                    );
                }
                return false;
            }
        };

        fn add_pidfs(arr: *std.MultiArrayList(list_item), alloc: std.mem.Allocator) AddPidfds {
            return .{ .arr = arr, .alloc = alloc };
        }

        pub fn add(self: *Self, val: opts.listener_type, fd: std.posix.fd_t) !void {
            _ = try self.items.push_item(.{
                .t = val,
                .fd = fd,
                .state = .Sleep,
            });
        }
        pub fn remove(self: *Self, fd: std.posix.fd_t) !void {
            _ = try self.to_remove.push_item(fd);
        }
    };
}
