const std = @import("std");
const VM = @import("VM.zig");

const funcs = [_]type{
    @import("funcs/math.zig"),
};

test {
    inline for (funcs) |f| {
        std.log.err("C {}", .{f});
        switch (@typeInfo(f)) {
            .@"struct" => |s| {
                std.log.err("C {}:{}", .{ s, s.fields.len });
                inline for (s.decls) |field| {
                    std.log.err("B {s}", .{field.name});
                }
            },
            else => std.log.err("A {}", .{@typeInfo(f)}),
        }
    }
}

fn caller(comptime T: type) type {
    return struct {
        pub fn exec(vm: *VM.FunctionCall) !void {
            var input: T = undefined;
            const input = @typeInfo(T).@"struct";
            inline for (input.fields, 0..) |field, idx| {
                @field(input, field.name) = vm.getArg(field.type, idx);
            }
            const ret = input.run();
            vm.setResult(@typeOf(ret), ret);
        }
    };
}
