const std = @import("std");
const builtin = @import("builtin");
const wg = @import("cincludes.zig").wg;

pub const StringView: type = if (builtin.target.isWasm()) [*c]const u8 else wg.WGPUStringView;

pub inline fn stringView(comptime str: [:0]const u8) StringView {
    return if (builtin.target.isWasm()) str else wg.WGPUStringView{ .data = str, .length = str.len };
}

pub inline fn stringViewR(str: []u8) StringView {
    return if (builtin.target.isWasm()) @ptrCast(str) else wg.WGPUStringView{ .data = @ptrCast(str), .length = str.len };
}

pub inline fn stringViewData(strView: StringView) [*c]const u8 {
    return if (builtin.target.isWasm()) strView else strView.data;
}

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
