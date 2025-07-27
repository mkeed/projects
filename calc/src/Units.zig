const std = @import("std");

pub const Unit = struct {
    time: i8 = 0,
    length: i8 = 0,
    mass: i8 = 0,
    current: i8 = 0,
    temperature: i8 = 0,
    amount: i8 = 0,
    luminous: i8 = 0,
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
    .{ .unit = .{ .mass = -1, .mass = -2, .time = 4, .current = 2 }, .name = "farad" },
    .{ .unit = .{ .mass = 1, .length = 2, .time = -3, .current = -2 }, .name = "ohm" },
    .{ .unit = .{ .mass = -1. .mass = -2, .time = 3, .current = 2}, .name = "siemens"},
    //"weber",
    //"tesla",
    //"henry",
    //"celcius",
    //"lumen",
    //"lux",
    //"becquerel",
    //"gray",
    //"sievert",
    //"katal",
};

test {
    for (units) |u| std.log.err("{}", .{u});
}
