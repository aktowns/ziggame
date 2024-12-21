const wg = @import("cincludes.zig").wg;

pub inline fn stringView(comptime str: [:0]const u8) wg.WGPUStringView {
    return wg.WGPUStringView{ .data = str, .length = str.len };
}

pub inline fn stringViewR(str: []u8) wg.WGPUStringView {
    return wg.WGPUStringView{ .data = @ptrCast(str), .length = str.len };
}

pub inline fn colour(comptime r: f64, comptime g: f64, comptime b: f64, comptime a: f64) wg.WGPUColor {
    return .{
        .r = r,
        .g = g,
        .b = b,
        .a = a,
    };
}
