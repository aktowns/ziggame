const builtin = @import("builtin");
const wg = @import("cincludes.zig").wg;

pub const StringView: type = if (builtin.target.isWasm()) [*c]const u8 else wg.WGPUStringView;

pub inline fn init(comptime str: [:0]const u8) StringView {
    return if (builtin.target.isWasm()) str else wg.WGPUStringView{ .data = str, .length = str.len };
}

pub inline fn initR(str: []u8) StringView {
    return if (builtin.target.isWasm()) @ptrCast(str) else wg.WGPUStringView{ .data = @ptrCast(str), .length = str.len };
}

pub inline fn data(self: StringView) ?[*c]const u8 {
    return if (builtin.target.isWasm()) self else if (self.length == 0) null else self.data;
}
