pub const Events = @This();

const std = @import("std");
const Signal = @import("./event/signal.zig").Signal;
const Point = @import("types/Point.zig").Point;

pub const PointerEnter = Signal(Point(i32));
pub const PointerExit = Signal(Point(i32));
pub const PointerMove = Signal(Point(i32));

pointer_enter: PointerEnter,
pointer_exit: PointerExit,
pointer_move: PointerMove,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{
        .pointer_enter = PointerEnter.init(allocator),
        .pointer_exit = PointerExit.init(allocator),
        .pointer_move = PointerMove.init(allocator),
    };
}
