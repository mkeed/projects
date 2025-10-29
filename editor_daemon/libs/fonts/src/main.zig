const std = @import("std");
const ttf = @import("ttf.zig");

pub const std_options: std.Options = .{
    // Set the log level to info
    .log_level = .info,

    // Define logFn to override the std implementation
    .logFn = myLogFn,
};

var log_writer: ?*std.Io.Writer = null;
var log_lock: std.Thread.Mutex = .{};

pub fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-error logging from sources other than
    // .my_project, .nice_library and the default
    const scope_prefix = "(" ++ switch (scope) {
        .my_project, .nice_library, std.log.default_log_scope => @tagName(scope),
        else => if (@intFromEnum(level) <= @intFromEnum(std.log.Level.err))
            @tagName(scope)
        else
            return,
    } ++ "): ";

    const prefix = "[" ++ comptime level.asText() ++ "] " ++ scope_prefix;

    // Print the message to stderr, silently ignoring any errors

    if (log_writer) |lw| {
        log_lock.lock();
        defer log_lock.unlock();
        nosuspend lw.print(prefix ++ format ++ "\n", args) catch return;
    } else {
        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();
        var stderr = std.fs.File.stderr().writer(&.{});
        nosuspend stderr.interface.print(prefix ++ format ++ "\n", args) catch return;
    }
}

const files = [_][]const u8{
    "../examples/Roboto/static/Roboto-BlackItalic.ttf",
    "../examples/Roboto/static/Roboto-Black.ttf",
    "../examples/Roboto/static/Roboto-BoldItalic.ttf",
    "../examples/Roboto/static/Roboto-Bold.ttf",
    "../examples/Roboto/static/Roboto_Condensed-BlackItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-Black.ttf",
    "../examples/Roboto/static/Roboto_Condensed-BoldItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-Bold.ttf",
    "../examples/Roboto/static/Roboto_Condensed-ExtraBoldItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-ExtraBold.ttf",
    "../examples/Roboto/static/Roboto_Condensed-ExtraLightItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-ExtraLight.ttf",
    "../examples/Roboto/static/Roboto_Condensed-Italic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-LightItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-Light.ttf",
    "../examples/Roboto/static/Roboto_Condensed-MediumItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-Medium.ttf",
    "../examples/Roboto/static/Roboto_Condensed-Regular.ttf",
    "../examples/Roboto/static/Roboto_Condensed-SemiBoldItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-SemiBold.ttf",
    "../examples/Roboto/static/Roboto_Condensed-ThinItalic.ttf",
    "../examples/Roboto/static/Roboto_Condensed-Thin.ttf",
    "../examples/Roboto/static/Roboto-ExtraBoldItalic.ttf",
    "../examples/Roboto/static/Roboto-ExtraBold.ttf",
    "../examples/Roboto/static/Roboto-ExtraLightItalic.ttf",
    "../examples/Roboto/static/Roboto-ExtraLight.ttf",
    "../examples/Roboto/static/Roboto-Italic.ttf",
    "../examples/Roboto/static/Roboto-LightItalic.ttf",
    "../examples/Roboto/static/Roboto-Light.ttf",
    "../examples/Roboto/static/Roboto-MediumItalic.ttf",
    "../examples/Roboto/static/Roboto-Medium.ttf",
    "../examples/Roboto/static/Roboto-Regular.ttf",
    "../examples/Roboto/static/Roboto-SemiBoldItalic.ttf",
    "../examples/Roboto/static/Roboto-SemiBold.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-BlackItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-Black.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-BoldItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-Bold.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-ExtraBoldItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-ExtraBold.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-ExtraLightItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-ExtraLight.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-Italic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-LightItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-Light.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-MediumItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-Medium.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-Regular.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-SemiBoldItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-SemiBold.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-ThinItalic.ttf",
    "../examples/Roboto/static/Roboto_SemiCondensed-Thin.ttf",
    "../examples/Roboto/static/Roboto-ThinItalic.ttf",
    "../examples/Roboto/static/Roboto-Thin.ttf",
    "../examples/Playball/Playball-Regular.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-Black.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-Bold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-Black.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-Bold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-ExtraBold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-ExtraLight.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-Light.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-Medium.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-Regular.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-SemiBold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Cursive-Thin.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-ExtraBold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-ExtraLight.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-Light.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-Medium.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-Regular.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-Black.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-Bold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-ExtraBold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-ExtraLight.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-Light.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-Medium.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-Regular.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-SemiBold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle_Roman-Thin.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-SemiBold.ttf",
    "../examples/Bitcount_Grid_Single/static/BitcountGridSingle-Thin.ttf",
};

fn get_all_fonts(alloc: std.mem.Allocator) ![]const []const u8 {
    var list = std.ArrayList([]const u8){};
    //for (files) |f| {
    //try list.append(alloc, try alloc.dupe(u8, f));
    //}
    const font_dir_name = "/usr/share/fonts";
    var dir = try std.fs.openDirAbsolute(font_dir_name, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |item| {
        switch (item.kind) {
            .directory => |_| {
                var font_dir = try dir.openDir(item.name, .{ .iterate = true });
                defer font_dir.close();
                var font_iter = font_dir.iterate();
                while (try font_iter.next()) |font_item| {
                    switch (font_item.kind) {
                        .file => {
                            if (std.mem.indexOf(u8, font_item.name, ".ttf") != null //
                            or std.mem.indexOf(u8, font_item.name, ".ttf") != null) {
                                const name = try std.fmt.allocPrint(alloc, "{s}/{s}/{s}", .{
                                    font_dir_name,
                                    item.name,
                                    font_item.name,
                                });
                                try list.append(alloc, name);
                            }
                        },
                        else => {},
                    }
                }
            },
            else => {},
        }
    }
    return try list.toOwnedSlice(alloc);
}

fn tagtou32(data: []const u8) u32 {
    std.debug.assert(data.len == 4);
    var val: u32 = 0;
    for (data, 0..) |d, idx| {
        val |= @as(u32, d) << @intCast(8 * idx);
    }
    return val;
}

fn u32totag(val: u32) [4]u8 {
    return .{
        @truncate(val >> 0),
        @truncate(val >> 8),
        @truncate(val >> 16),
        @truncate(val >> 24),
    };
}
const Counter = struct {
    name: u32,
    count: usize,
    fn lessThan(_: u32, lhs: Counter, rhs: Counter) bool {
        return lhs.count > rhs.count;
    }
};
pub fn main() !void {
    var stdout = std.fs.File.stdout();

    var dir = std.fs.cwd();
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var lw = std.Io.Writer.Allocating.init(alloc);
    defer {
        log_writer = null;
        lw.deinit();
    }
    log_writer = &lw.writer;
    const names = try get_all_fonts(alloc);
    defer {
        for (names) |n| alloc.free(n);
        alloc.free(names);
    }
    var tables = std.array_list.Managed(Counter).init(alloc);
    defer tables.deinit();
    _ = try stdout.write("Starting\n");
    for (names) |f| {
        defer lw.clearRetainingCapacity();
        const file_data = try dir.readFileAlloc(f, alloc, .unlimited);
        defer alloc.free(file_data);
        //std.log.info("{s} => {}", .{ f, file_data.len });
        const headers = ttf.parseHeader(file_data, alloc) catch continue;
        defer headers.deinit(alloc);
        header_loop: for (headers.tables) |t| {
            const id = tagtou32(t.name);
            for (tables.items) |*i| {
                if (i.name == id) {
                    i.count += 1;
                    continue :header_loop;
                }
            }
            try tables.append(.{ .name = id, .count = 1 });
        }
        if (true) {
            ttf.parse_file(file_data, alloc) catch |err| {
                std.log.err("Failure in {s}|{}", .{ f, err });
                _ = stdout.write(f) catch {};
                _ = stdout.write(lw.written()) catch {};
                return err;
            };
        }
    }
    std.mem.sort(Counter, tables.items, @as(u32, 0), Counter.lessThan);
    for (tables.items) |i| {
        std.log.err("{s} => {}", .{ u32totag(i.name), i.count });
    }
    _ = stdout.write(lw.written()) catch {};
}
