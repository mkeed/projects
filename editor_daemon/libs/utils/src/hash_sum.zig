const std = @import("std");
const util = @import("Util.zig");

const hash = std.crypto.hash;

const b2 = hash.blake2.Blake2b256;
const b3 = hash.Blake3;
const md5 = hash.Md5;
const sha1 = hash.Sha1;
const sha224 = hash.sha2.Sha224;
const sha256 = hash.sha2.Sha224;
const sha3_224 = hash.sha3.Sha3_224;
const sha3_256 = hash.sha3.Sha3_256;
const sha3_384 = hash.sha3.Sha3_384;
const sha3_512 = hash.sha3.Sha3_512;

const sha384 = sha3_384;
const sha512 = hash.sha2.Sha512;

const shake128 = hash.sha3.Shake128;
const shake256 = hash.sha3.Shake256;

const Prog = struct {
    name: []const u8,
    hasher: type,
};

const programs = [_]Prog{
    .{ .name = "b2sum", .hasher = b2 },
    .{ .name = "b3sum", .hasher = b3 },
    .{ .name = "md5sum", .hasher = md5 },
    .{ .name = "sha1sum", .hasher = sha1 },
    .{ .name = "sha224sum", .hasher = sha224 },
    .{ .name = "sha256sum", .hasher = sha256 },
    .{ .name = "sha3-224sum", .hasher = sha3_224 },
    .{ .name = "sha3-256sum", .hasher = sha3_256 },
    .{ .name = "sha3-384sum", .hasher = sha3_384 },
    .{ .name = "sha3-512sum", .hasher = sha3_512 },
    .{ .name = "sha384sum", .hasher = sha384 },
    .{ .name = "sha512sum", .hasher = sha512 },
    .{ .name = "shake128sum", .hasher = shake128 },
    .{ .name = "shake256sum", .hasher = shake256 },
};

fn runner(comptime T: type) type {
    return struct {
        pub fn run(info: util.RunInfo) !void {
            _ = info;
            _ = T;
        }
    };
}
