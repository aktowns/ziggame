pub const Window = @This();

const std = @import("std");
const builtin = @import("builtin");
const Signal = @import("../event/signal.zig").Signal;

const linux_wayland = @import("linux_wayland.zig");

width: u32,
height: u32,
surface: Surface,
underlying: Underlying,
on_size_changed: SizeChanged,

pub const SizeChangedCtx = struct { width: u32, height: u32, window: *@This() };
pub const SizeChanged = Signal(SizeChangedCtx);

pub const SurfaceTag = enum { linux_wayland };

pub const LinuxSurface = struct {
    wl_surface: *linux_wayland.c.wl_surface,
    wl_display: *linux_wayland.c.wl_display,
};

pub const Surface = union(SurfaceTag) {
    linux_wayland: LinuxSurface,
};

pub const Underlying = switch (builtin.target.os.tag) {
    .linux => linux_wayland,
    .macos => undefined,
    else => unreachable,
};

pub const window_options = struct {
    title: []const u8,
    width: u32,
    height: u32,
};

pub fn init(allocator: std.mem.Allocator, options: window_options) @This() {
    switch (builtin.target.os.tag) {
        .linux => {
            var lw = linux_wayland.init(options.title);
            lw.setup();
            return .{
                .width = options.width,
                .height = options.height,
                .underlying = lw,
                .on_size_changed = SizeChanged.init(allocator),
                .surface = Surface{
                    .linux_wayland = .{
                        .wl_display = lw.display,
                        .wl_surface = lw.surface.?,
                    },
                },
            };
        },
        else => unreachable,
    }
}

pub fn dispatch(self: *@This()) i32 {
    return self.underlying.dispatch();
}
