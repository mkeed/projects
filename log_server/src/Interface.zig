const std = @import("std");

pub const MicroTimestamp = i64; // microsSinceEpoch

pub const LogClient = struct {
    pub const Version = "v1";
    pub const MessageId = enum(u32) {
        init = 1,
        send_log = 2,
    };
    pub const Message = union(MessageId) {
        init: struct { name: []const u8, starup_time: MicroTimestamp },
        send_log: struct {
            sub_system: []const u8,
            time_stamp: MicroTimestamp, // offset from start
            severity: std.log.Level,
            message: []const u8,
        },
    };
};

pub const ViewerClient = struct {
    pub const Version = "v1";
    pub const MessageId = enum(u32) {
        init = 1,
        list = 2,
        subscribe = 3,
        subscribe_all = 4,
    };
    pub const Message = union(MessageId) {
        init: struct { name: []const u8 },
        list: struct {},
        subscribe: struct { name: []const u8 },
        subscribe_all: struct {},
    };
};

pub const Server = struct {
    pub const Version = "v1";
    pub const MessageId = enum(u32) {};
};
