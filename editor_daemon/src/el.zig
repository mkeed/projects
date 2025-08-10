const std = @import("std");

pub const Events = union(enum) {
    fileNotify: *@import("FileNotify.zig").FileNotify,
    //
    pub fn handle(
        self: Events,
        fd: std.posix.fd_t,
        el: *EventLoop,
    ) !void {
        switch (self) {
            inline else => |e| try e.handle(fd, el),
        }
    }
};

pub const EventLoop = @import("EventLoop.zig").EventLoop(.{
    .listener_type = Events,
});
