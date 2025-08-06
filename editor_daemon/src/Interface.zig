const std = @import("std");
pub const Client = struct {
    pub const MessageId = enum(u32) {
        openFile = 0,
    };

    pub const Message = union(MessageId) {
        openFile: OpenFile,
    };

    pub const OpenFile = struct {
        file_name: []const u8,
        mode: packed struct(u8) {
            create: bool,
            write: bool,
            lock: bool,
            _: u5,
        },
    };
};

pub const Server = struct {};

test {
    _ = Client.Message;
}
