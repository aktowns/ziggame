const Input = @This();

const std = @import("std");
const WaylandInput = @import("WaylandInput.zig");
const WindowInput = @import("../window/linux_wayland.zig").WindowInput;
const Signal = @import("../event/signal.zig").Signal;
const Events = @import("Events.zig");

pub const InputTag = enum { wayland_input };
pub const InputSource = union(InputTag) { wayland_input: WaylandInput };

underlying: InputSource,
events: Events,

pub fn initWayland(allocator: std.mem.Allocator, input: *const WindowInput) @This() {
    const events: Events = Events.init(allocator);
    const wlinput = WaylandInput.init(&events, input);

    return .{
        .underlying = .{ .wayland_input = wlinput },
        .events = events,
    };
}
