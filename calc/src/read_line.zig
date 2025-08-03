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
        const orig = try enable_raw_mode(self.stdin.handle);

        defer std.posix.tcsetattr(self.stdin.handle, .FLUSH, orig) catch {};
        while (true) {
            _ = try self.stdout.write(self.prompt);
            var buf: [512]u8 = undefined;

            const len = try self.stdin.read(&buf);
            try output.appendSlice(buf[0..len]);
        }
        //
    }
};

fn enable_raw_mode(fd: std.posix.fd_t) !std.posix.termios {
    const orig = try std.posix.tcgetattr(fd);
    var new = orig;

    new.iflag.BRKINT = false;
    new.iflag.ICRNL = false;
    new.iflag.INPCK = false;
    new.iflag.ISTRIP = false;
    new.iflag.IXON = false;

    new.oflag.OPOST = false;

    new.cflag.CSIZE = .CS8;

    new.lflag.ECHO = false;
    new.lflag.ICANON = false;
    new.lflag.IEXTEN = false;
    new.lflag.ISIG = false;
    const VMIN = 6;

    new.cc[VMIN] = 1;
    try std.posix.tcsetattr(fd, .FLUSH, new);
    return orig;
}
