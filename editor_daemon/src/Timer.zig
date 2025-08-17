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
            .it_interval = .{
                .sec = 0,
                .nsec = 0,
            },
            .it_value = .{
                .sec = time_millis / std.time.ms_per_s,
                .nsec = time_millis % std.time.ns_per_ms,
            },
        };

        try std.posix.timerfd_settime(
            fd,
            .{},
            &timer,
            null,
        );
        return .{
            .fd = fd,
            .callback = callback,
        };
    }
};
