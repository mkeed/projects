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

pub const ClientLog = struct {};

pub const Server = struct {
    clients: ConcurrentList(ClientLog),
    pub fn init(alloc: std.mem.Allocator) Server {
        return .{
            .clients = ConcurrentList(ClientLog).init(alloc),
        };
    }
    pub fn deinit(self: *Server) void {
        self.clients.deinit();
    }
};

pub fn run(alloc: std.mem.Allocator, config: Config.Config) !void {
    var server = Server.init(alloc);
    defer server.deinit();
    const view_addr = try std.net.Address.initUnix(config.viewer_port);
    const log_addr = try std.net.Address.initUnix(config.log_port);
    const log_srv = try std.Thread.spawn(.{}, @import("LogServer.zig").run_log_srv, .{ &server, alloc, log_addr });
    defer log_srv.join();
    const view_srv = try std.Thread.spawn(.{}, @import("ViewServer.zig").run_view_srv, .{ &server, alloc, view_addr });
    defer view_srv.join();
}

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
