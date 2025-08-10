const std = @import("std");

pub const Timer = struct {
    fd: std.posix.fd_t,
    callback: Callback,

    pub fn init(callback: Callback, time_nanoseconds: i64) !Timer {
        const fd = try std.posix.timerfd_create(.MONOTONIC, .{
            .NONBLOCK = true,
            .CLOEXEC = true,
        });
        errdefer std.posix.close(fd);

        const timer = std.posix.system.itimerspec{
            .it_interval = .{},
            .it_value = .{},
        };

        try std.posix.timerfd_settime(
            fd,
            .{},
            &timer,
            null,
        );
    }
};
