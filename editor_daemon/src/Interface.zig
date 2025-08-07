const std = @import("std");
pub const Client = struct {
    pub const MessageId = enum(u32) {
        attach = 0,
        openFile = 1,
    };

    pub const Message = union(MessageId) {
        attach: Attach,
        openFile: OpenFile,
    };

    pub const Attach = struct {
        directory: []const u8,
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
