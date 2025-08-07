const std = @import("std");
const Server = @import("Server.zig").Server;

fn run_view_srv_inner(server: *Server, alloc: std.mem.Allocator, socket: *std.net.Server) !void {
    _ = server;
    _ = alloc;

    while (true) {
        const con = try socket.accept();
        {
            errdefer con.deinit();
            // const thread = try

        }
    }
}

pub fn run_view_srv(server: *Server, alloc: std.mem.Allocator, socket: *std.net.Server) void {
    run_view_srv_inner(server, alloc, socket) catch {};
}
