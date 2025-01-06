const std = @import("std");
const builtin = @import("builtin");
const wg = @import("wgpu").wg;

pub inline fn colour(comptime r: f64, comptime g: f64, comptime b: f64, comptime a: f64) wg.WGPUColor {
    return .{
        .r = r,
        .g = g,
        .b = b,
        .a = a,
    };
}

pub inline fn colourR(r: f64, g: f64, b: f64, a: f64) wg.WGPUColor {
    return .{
        .r = r,
        .g = g,
        .b = b,
        .a = a,
    };
}
