const std = @import("std");

pub const String = struct {
    data: std.ArrayList(u8),
    pub fn init(alloc: std.mem.Allocator) String {
        return .{
            .data = std.ArrayList(u8).init(alloc),
        };
    }
    pub fn deinit(self: String) void {
        self.data.deinit();
    }
};

pub const Item = struct {
    input: String,
};

pub const History = struct {
    alloc: std.mem.Allocator,
    items: std.ArrayList(Item),

    pub fn init(alloc: std.mem.Allocator) History {
        return .{
            .alloc = alloc,
            .items = std.ArrayList(Item).init(alloc),
        };
    }
    pub fn deinit(self: History) void {
        for (self.items.items) |i| i.input.deinit();
        self.items.deinit();
    }
};

pub const ReadLine = struct {
    stdin: std.fs.File,
    stdout: std.fs.File,
    history: History,
    prompt: []const u8 = "> ",
    pub fn init(
        alloc: std.mem.Allocator,
    ) ReadLine {
        return .{
            .stdin = std.fs.File.stdin(),
            .stdout = std.fs.File.stdout(),
            .history = History.init(alloc),
        };
    }
    pub fn deinit(self: ReadLine) void {
        self.history.deinit();
    }
    pub fn read(self: *ReadLine, output: *std.ArrayList(u8)) !void {
        _ = try self.stdout.write(self.prompt);
        var buf: [512]u8 = undefined;

        const len = try self.stdin.read(&buf);
        try output.appendSlice(buf[0..len]);
        //
    }
};
