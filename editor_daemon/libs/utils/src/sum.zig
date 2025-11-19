const std = @import("std");
const zutil = @import("zutil.zig");

fn Impl(comptime name: []const u8, comptime algo: type) type {
    return struct {
        const ArgParse = @import("ArgParse.zig");
        const Opts = struct {
            binary: bool = false,
            check: bool = false,
            tag: bool = false,
            text: bool = false,
            zero: bool = false,
            ignore_missing: bool = false,
            quiet: bool = false,
            status: bool = false,
            strict: bool = false,
            warn: bool = false,
        };
        const args = ArgParse.Program{
            .name = name,
            .opts = &.{
                .{ .short = 'b', .long = "--binary", .field = "binary" },
                .{ .short = 'c', .long = "--check", .field = "check" },
                .{ .long = "--tag", .field = "tag" },
                .{ .short = 't', .long = "--text", .field = "text" },
                .{ .short = 'z', .long = "--zero", .field = "zero" },
                .{ .short = 'w', .long = "--warn", .field = "warn" },

                .{ .long = "--ignore-missing", .field = "ignore_missing" },
                .{ .long = "--quiet", .field = "quiet" },
                .{ .long = "--status", .field = "status" },
                .{ .long = "--strict", .field = "strict" },
            },
            .inbuilts = .{},
            .result = Opts,
        };

        const Name = name;
        fn run(env: *zutil.Environment) anyerror!void {
            var writer = env.stdout;
            var dir = std.fs.cwd();
            const opt = try ArgParse.parse(args, env.args);

            for (env.args) |file_name| {
                if (file_name[0] == '-') continue;
                var file = try dir.openFile(file_name, .{});
                defer file.close();
                var file_buf: [40960]u8 = undefined;

                var hashed = algo.init(.{});
                while (true) {
                    const len = try file.read(&file_buf);
                    hashed.update(file_buf[0..len]);
                    if (len != file_buf.len) break;
                }

                var output = std.mem.zeroes([algo.digest_length]u8);
                hashed.final(&output);
                if (opt.tag) {
                    try writer.print("{s} ({s}) = {x}\n", .{ name, file_name, output });
                } else {
                    try writer.print("{x} {s}\n", .{ output, file_name });
                }
                try writer.flush();
            }
        }
    };
}

fn binary(comptime name: []const u8, comptime algo: type) zutil.Binary {
    const impl = Impl(name, algo);
    return .{
        .name = name,
        .function = impl.run,
    };
}

pub const sha1 = binary("sha1sum", std.crypto.hash.Sha1);
pub const sha224 = binary("sha224sum", std.crypto.hash.sha2.Sha224);
pub const sha256 = binary("sha256sum", std.crypto.hash.sha2.Sha256);
pub const sha384 = binary("sha384sum", std.crypto.hash.sha2.Sha384);
pub const sha512 = binary("sha384sum", std.crypto.hash.sha2.Sha512);
pub const md5 = binary("md5sum", std.crypto.hash.Md5);
pub const b2 = binary("b2sum", std.crypto.hash.blake2.Blake2b512);

// /usr/bin/cksum TODO
// /usr/bin/shasum TODO
// /usr/bin/sum TODO
