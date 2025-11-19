const std = @import("std");
const zutil = @import("zutil.zig");
const ArgParse = @import("ArgParse.zig");

const args = ArgParse.Program{
    .name = "yes",
    .opts = &.{},
    .inbuilts = .{},
};

pub fn run_func(env: *zutil.Environment) anyerror!void {
    var stdout = env.stdout;
    for (0..10) |_| {
        //while (true) {
        for (env.args, 0..) |a, idx| {
            if (idx != 0) {
                try stdout.print(" ", .{});
            }
            try stdout.print("{s}", .{a});
        }
        if (env.args.len == 0) {
            try stdout.print("yes", .{});
        }
        try stdout.print("\n", .{});
    }
    try stdout.flush();
}
