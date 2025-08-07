const std = @import("std");
const Server = @import("Server.zig").Server;

pub fn run_log_srv(server: *Server, alloc: std.mem.Allocator, addr: std.net.Address) void {
    run_log_srv_inner(server, alloc, addr) catch {};
}

fn run_log_srv_inner(server: *Server, alloc: std.mem.Allocator, addr: std.net.Address) !void {
    _ = server;
    _ = alloc;
    _ = addr;
}
