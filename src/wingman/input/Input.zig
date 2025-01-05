const Input = @This();

const std = @import("std");
const builtin = @import("builtin");

const Underlying = switch (builtin.target.os.tag) {
    .linux => @import("WaylandInput.zig"),
    .macos => @import("MacOSInput.zig"),
    else => undefined,
};

const Signal = @import("../event/signal.zig").Signal;
const Events = @import("Events.zig");

pub usingnamespace switch (builtin.target.os.tag) {
    .linux => linux_impl,
    .macos => macos_impl,
    else => undefined,
};

underlying: Underlying,
events: Events,

const linux_impl = struct {
    const WindowInput = @import("../window/linux_wayland.zig").WindowInput;

    pub fn initWayland(allocator: std.mem.Allocator, input: *const WindowInput) @This() {
        const events: Events = Events.init(allocator);
        const wlinput = Underlying.init(&events, input);

        return .{
            .underlying = .{ .wayland_input = wlinput },
            .events = events,
        };
    }
};

const macos_impl = struct {};
