const std = @import("std");
const Config = @import("Config.zig");
const ConcurrentList = @import("ConcurrentList.zig").ConcurrentList;

pub const String = struct {
    val: std.ArrayList(u8),
    pub fn init(alloc: std.mem.Allocator) String {
        return .{ .val = std.ArrayList(u8).init(alloc) };
    }
    pub fn deinit(self: String) void {
        self.val.deinit();
    }
};

const Server = struct {
    clients: ConcurrentList(ClientLog),
    pub fn init(alloc: std.mem.Allocator) Server {
        return .{
            .clients = ConcurrentList(ClientLog).init(alloc),
        };
    }
    pub fn deinit(self: Server) void {
        self.clients.deinit();
    }
};

fn run_log_srv_inner(server: *Server, alloc: std.mem.Allocator, addr: std.net.Address) !void {
    _ = server;
    _ = alloc;
    _ = addr;
}

fn run_log_srv(server: *Server, alloc: std.mem.Allocator, addr: std.net.Address) void {
    run_log_srv_innter(server, alloc, addr) catch {};
}

fn run_view_srv_inner(server: *Server, alloc: std.mem.Allocator, addr: std.net.Address) !void {
    _ = server;
    _ = alloc;
    _ = addr;
}

fn run_view_srv(server: *Server, alloc: std.mem.Allocator, addr: std.net.Address) void {
    run_view_srv_innter(server, alloc, addr) catch {};
}

pub fn run(alloc: std.mem.Allocator, config: Config.Config) !void {
    var server = Server.init(alloc);
    defer server.deinit();
    const view_addr = try std.net.initUnix(config.viewer_port);
    const log_addr = try std.net.initUnix(config.log_port);
    const log_srv = try std.Thread.spawn(run_log_srv, .{ &server, alloc, log_addr });
    defer log_srv.join();
    const view_srv = try std.Thread.spawn(run_view_srv, .{ &server, alloc, view_addr });
    defer view_srv.join();
}

pub const Server = struct {
    pub fn init() !Server {
        return .{
            .view_srv = try view_addr.listen(.{ .reuse_address = true, .force_nonblocking = true }),
            .log_srv = try log_addr.listen(.{ .reuse_address = true, .force_nonblocking = true }),
            .threads = std.ArrayList(Client).init(alloc),
            .alloc = alloc,
        };
    }

    pub fn deinit(self: Server) void {
        self.view_srv.close();
        self.log_srv.close();
    }
};

pub const LogList = struct {
    pub const LogItem = struct {
        time: i64,
        sub_system: []const u8,
        messsage: String,
    };
    list: std.ArrayList(LogItem),
    sub_systems: std.ArrayList(String),
    mutex: std.Thread.Mutex,
    pub fn init(alloc: std.mem.Alocator) LogList {
        return LogList{
            .list = std.ArrayList(LogItem).init(alloc),
            .mutex = .{},
        };
    }
    pub fn deinit(self: LogList) void {
        for (self.list.items) |item| {
            item.message.deinit();
        }
        self.list.deinit();
        for (self.sub_systems.items) |item| item.deinit();
        self.sub_systems.deinit();
    }
};
