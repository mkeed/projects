const std = @import("std");

pub const String = struct {
    data: std.array_list.Managed(u8),
    pub fn init(alloc: std.mem.Allocator) String {
        return .{
            .data = std.array_list.Managed(u8).init(alloc),
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
    items: std.array_list.Managed(Item),

    pub fn init(alloc: std.mem.Allocator) History {
        return .{
            .alloc = alloc,
            .items = std.array_list.Managed(Item).init(alloc),
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
        var index: usize = 0;
        while (true) {
            var io = self.stdout.deprecatedWriter();
            try io.print("\x1B[1K\r{s}{s}\x1B[{}G", .{ self.prompt, output.items, index + self.prompt.len + 1 });

            var buf: [512]u8 = undefined;

            const len = try self.stdin.read(&buf);

            //std.log.info("{f}", .{std.ascii.hexEscape(buf[0..len], .upper)});
            if (buf[0] == '\x1B') {
                switch (buf[2]) {
                    'A' => {}, // UP
                    'B' => {}, //DN
                    'C' => {
                        if (index + 1 < output.items.len) index += 1;
                    }, //Forwad
                    'D' => {
                        if (index >= 1) index -= 1;
                    }, //back
                    else => return error.TODO,
                }
            } else if (buf[0] == 0x7F) {
                remove_at(&index, 1, output);
            } else {
                if (std.mem.indexOfAny(u8, buf[0..len], "\r\n\n") != null) break;

                try insert_at(buf[0..len], &index, output);
            }
        }
        //
    }
    fn remove_at(pos: *usize, cnt: usize, buf: *std.ArrayList(u8)) void {
        if (pos.* != buf.items.len) {
            for (0..cnt) |idx| {
                buf.items[pos.*] = buf.items[pos.* + idx];
            }
        }
        pos.* -= cnt;
        buf.shrinkRetainingCapacity(buf.items.len - cnt);
    }
    fn insert_at(bytes: []const u8, pos: *usize, buf: *std.ArrayList(u8)) !void {
        if (pos.* == buf.items.len) {
            try buf.appendSlice(bytes);
            pos.* += bytes.len;
        } else {
            const end = buf.items.len;
            try buf.appendNTimes(0, bytes.len);

            for (0..(end - pos.*)) |idx| {
                buf.items[buf.items.len - idx - 1] = buf.items[end - idx - 1];
            }
            for (0..bytes.len) |idx| {
                buf.items[pos.* + idx] = bytes[idx];
            }
            pos.* += bytes.len;
        }
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
