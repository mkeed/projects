const std = @import("std");
const Config = @import("Config.zig");

pub const String = struct {
    val: std.ArrayList(u8),
    pub fn init(alloc: std.mem.Allocator) String {
        return .{ .val = std.ArrayList(u8).init(alloc) };
    }
    pub fn deinit(self: String) void {
        self.val.deinit();
    }
};

pub const Server = struct {
    view_srv: std.net.Address,
    log_srv: std.net.Address,
    threads: std.ArrayList(Client),
    alloc: std.mem.Allocator,
    pub fn init(alloc: std.mem.Allocator, config: Config.Config) !Server {
        const view_addr = try std.net.initUnix(config.viewer_port);
        const log_addr = try std.net.initUnix(config.log_port);

        return .{
            .view_srv = try view_addr.listen(.{ .reuse_address = true, .force_nonblocking = true }),
            .log_srv = try log_addr.listen(.{ .reuse_address = true, .force_nonblocking = true }),
            .threads = std.ArrayList(Client).init(alloc),
            .alloc = alloc,
        };
    }

    pub fn deinit(self: Server) void {
        _ = self;
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
