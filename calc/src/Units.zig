const std = @import("std");

pub const Unit = struct {
    mass: i8 = 0,
    length: i8 = 0,
    time: i8 = 0,
    current: i8 = 0,
    temperature: i8 = 0,
    amount: i8 = 0,
    luminous: i8 = 0,

    pub fn format(self: Unit, io: *std.Io.Writer) !void {
        if (self.mass != 0) {
            try io.print("kg^{}", .{self.mass});
        }
        if (self.length != 0) {
            try io.print("m^{}", .{self.length});
        }
        if (self.time != 0) {
            try io.print("s^{}", .{self.time});
        }
        if (self.current != 0) {
            try io.print("A^{}", .{self.current});
        }
        if (self.temperature != 0) {
            try io.print("K^{}", .{self.temperature});
        }
        if (self.amount != 0) {
            try io.print("mol^{}", .{self.amount});
        }
        if (self.luminous != 0) {
            try io.print("cd^{}", .{self.luminous});
        }
    }
    pub fn combine(self: Unit, other: Unit) !void {
        return .{
            .mass = self.mass + other.mass,
            .length = self.length + other.length,
            .time = self.time + other.time,
            .current = self.current + other.current,
            .temperature = self.temperature + other.temperature,
            .amount = self.amount + other.amount,
            .luminous = self.luminous + other.luminous,
        };
    }
};

pub const UnitDef = struct {
    unit: Unit,
    name: []const u8,
};

pub const units = [_]UnitDef{
    .{ .unit = .{ .time = 1 }, .name = "seconds" },
    .{ .unit = .{ .length = 1 }, .name = "metre" },
    .{ .unit = .{ .mass = 1 }, .name = "kilogram" },
    .{ .unit = .{ .current = 1 }, .name = "ampere" },
    .{ .unit = .{ .temperature = 1 }, .name = "kelvin" },
    .{ .unit = .{ .amount = 1 }, .name = "mole" },
    .{ .unit = .{ .luminous = 1 }, .name = "candela" },

    .{ .unit = .{ .time = -1 }, .name = "hertz" },
    .{ .unit = .{ .mass = 1, .length = 1, .time = -2 }, .name = "newton" },
    .{ .unit = .{ .mass = 1, .length = -1, .time = -2 }, .name = "pascal" },
    .{ .unit = .{ .mass = 1, .length = 2, .time = -2 }, .name = "joule" },
    .{ .unit = .{ .mass = 1, .length = 2, .time = -3 }, .name = "watt" },
    .{ .unit = .{ .current = 1, .time = 1 }, .name = "coulomb" },
    .{ .unit = .{ .mass = 1, .length = 2, .time = -3, .current = -1 }, .name = "volt" },
    .{ .unit = .{ .mass = -1, .length = -2, .time = 4, .current = 2 }, .name = "farad" },
    .{ .unit = .{ .mass = 1, .length = 2, .time = -3, .current = -2 }, .name = "ohm" },
    .{ .unit = .{ .mass = -1, .length = -2, .time = 3, .current = 2 }, .name = "siemens" },
    .{ .unit = .{ .mass = 1, .length = 2, .time = -2, .current = -1 }, .name = "weber" },
    .{ .unit = .{ .mass = 1, .time = -2, .current = -1 }, .name = "tesla" },
    .{ .unit = .{ .mass = 1, .length = 2, .time = -2, .current = -2 }, .name = "henry" },
    .{ .unit = .{ .temperature = 1 }, .name = "celcius" },
    .{ .unit = .{ .luminous = 1 }, .name = "lumen" },
    .{ .unit = .{ .luminous = 1, .length = -2 }, .name = "lux" },
    //.{ .unit = .{ .time = -1 }, .name = "becquerel" },
    //.{ .unit = .{ .length = 2, .time = -2 }, .name = "gray" },
    //.{ .unit = .{ .length = 2, .time = -2 }, .name = "sievert" },
    //.{ .unit = .{ .amount = 1, .time = -1 }, .name = "katal" },
};

test {
    for (units) |u| std.log.err("{s}:{f}", .{ u.name, u.unit });
}
