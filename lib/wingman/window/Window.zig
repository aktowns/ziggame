pub const Window = @This();

const std = @import("std");
const builtin = @import("builtin");
const Signal = @import("../event/signal.zig").Signal;
const WindowOptions = @import("WindowOptions.zig");

const Underlying = switch (builtin.target.os.tag) {
    .linux => @import("../platforms/linux/WaylandWindow.zig"),
    .macos => @import("../platforms/macos/CocoaWindow.zig"),
    else => undefined,
};

width: u32,
height: u32,
surface: Surface,
underlying: Underlying,

pub const Surface = switch (builtin.target.os.tag) {
    .linux => struct {
        wl_surface: *Underlying.c.wl_surface,
        wl_display: *Underlying.c.wl_display,
    },
    .macos => struct {
        layer: Underlying.c.id,
    },
    else => undefined,
};

pub fn init(allocator: std.mem.Allocator, options: WindowOptions) @This() {
    return switch (comptime builtin.target.os.tag) {
        .linux => {
            var lw = Underlying.init(&options);
            lw.setup();
            return .{
                .width = options.width,
                .height = options.height,
                .underlying = lw,
                .surface = Surface{
                    .linux_wayland = .{
                        .wl_display = lw.display,
                        .wl_surface = lw.surface.?,
                    },
                },
            };
        },
        .macos => {
            var mw = Underlying.init(&options);
            mw.setup();
            return .{
                .width = options.width,
                .height = options.height,
                .underlying = mw,
                .surface = Surface{
                    .layer = mw.layer,
                },
            };
        },
        else => unreachable,
    };
}

pub fn dispatch(self: *@This()) i32 {
    return self.underlying.dispatch();
}
