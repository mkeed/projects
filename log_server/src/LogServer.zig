const std = @import("std");
const Server = @import("Server.zig").Server;
const ConcurrentList = @import("ConcurrentList.zig").ConcurrentList;

fn run_client(server: *Server, con: std.net.Server.Connection) !void {
    //
}

pub fn run_log_srv(server: *Server, alloc: std.mem.Allocator, socket: *std.net.Server) void {
    run_log_srv_inner(server, alloc, socket) catch {};
    while (true) {
        const con = try socket.accept();
        {
            errdefer con.deinit();
            const thread = try std.Thread.spawn(.{}, run_client, .{ server, con });
        }
    }
}

fn run_log_srv_inner(server: *Server, alloc: std.mem.Allocator, socket: *std.net.Server) !void {
    _ = socket;
    _ = server;
    _ = alloc;
}
