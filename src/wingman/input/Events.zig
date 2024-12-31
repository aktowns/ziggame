pub const Events = @This();

const std = @import("std");
const Signal = @import("../event/signal.zig").Signal;

pub const PointerEnterCtx = struct {};
pub const PointerEnter = Signal(PointerEnterCtx);

pointer_enter: PointerEnter,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{
        .pointer_enter = PointerEnter.init(allocator),
    };
}
