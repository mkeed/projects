const std = @import("std");

pub const Type = enum {
    int,
    uint,
    object,
    new_id,
    string,
    array,
    fd,
    @"enum",
};

pub const Header = packed struct(u64) {
    object_id: u32,
    len_opcode: u32,
};

pub fn connect() !std.net.Stream {
    if (std.posix.getenv("WAYLAND_SOCKET")) |sock| {
        const fd = try std.fm.parseInt(u32, sock, 10);
        return .{ .handle = fd };
    }
    const socket_name = if (std.posix.getenv("WAYLAND_DISPLAY")) |d| d else "wayland-0";
    var buf = std.mem.zeroes([512]u8);
    const dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return error.NeedXDG_RUNTIME_DIR;
    const val = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ dir, socket_name });
    return try std.net.connectUnixSocket(val);
}
