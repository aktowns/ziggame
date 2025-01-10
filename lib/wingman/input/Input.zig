const Input = @This();

const std = @import("std");
const builtin = @import("builtin");

const Signal = @import("../event/signal.zig").Signal;
const Events = @import("../Events.zig");

pub usingnamespace switch (builtin.target.os.tag) {
    .linux => @import("../platforms/linux/WaylandInput.zig"),
    .macos => @import("../platforms/macos/CocoaInput.zig"),
    else => undefined,
};

events: Events,

// const linux_impl = struct {
//     const WindowInput = @import("../window/LinuxWindow.zig").WindowInput;
//
//     pub fn initWayland(allocator: std.mem.Allocator, input: *const WindowInput) @This() {
//         const events: Events = Events.init(allocator);
//         const wlinput = Underlying.init(&events, input);
//
//         return .{
//             .underlying = .{ .wayland_input = wlinput },
//             .events = events,
//         };
//     }
// };
//
// const macos_impl = struct {};
