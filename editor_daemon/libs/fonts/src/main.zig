const std = @import("std");
const ttf = @import("ttf.zig");

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
    for (files) |f| {
        try list.append(alloc, try alloc.dupe(u8, f));
    }
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

pub fn main() !void {
    var dir = std.fs.cwd();
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    const names = try get_all_fonts(alloc);
    defer {
        for (names) |n| alloc.free(n);
        alloc.free(names);
    }
    for (names) |f| {
        const file_data = try dir.readFileAlloc(f, alloc, .unlimited);
        defer alloc.free(file_data);
        std.log.info("{s} => {}", .{ f, file_data.len });
        try ttf.parse_file(file_data, alloc);
    }
}
