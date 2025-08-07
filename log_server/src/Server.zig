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

fn file_exists(dir: std.fs.Dir, file: []const u8) bool {
    _ = dir.statFile(file) catch return false;
    return true;
}

fn setup_unix_socket(dir: std.fs.Dir, file: []const u8) !std.net.Server {
    const addr = try std.net.Address.initUnix(file);
    if (file_exists(dir, file)) {
        try dir.deleteFile(file);
    }
    const srv = try addr.listen(.{ .reuse_address = true });
    return srv;
}

pub fn run(alloc: std.mem.Allocator, config: Config.Config) !void {
    var server = Server.init(alloc);
    defer server.deinit();
    var view_srv = try setup_unix_socket(std.fs.cwd(), config.viewer_port);
    defer view_srv.deinit();

    var log_srv = try setup_unix_socket(std.fs.cwd(), config.log_port);
    defer log_srv.deinit();

    const log_thread = try std.Thread.spawn(.{}, @import("LogServer.zig").run_log_srv, .{ &server, alloc, &log_srv });
    defer log_thread.join();
    const view_thread = try std.Thread.spawn(.{}, @import("ViewServer.zig").run_view_srv, .{ &server, alloc, &view_srv });
    defer view_thread.join();
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
