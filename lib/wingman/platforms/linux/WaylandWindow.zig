pub const LinuxWayland = @This();

const std = @import("std");
const WindowOptions = @import("../../window/WindowOptions.zig");

pub const c = @cImport({
    @cInclude("wayland-client.h");
    @cInclude("xdg-shell-protocol.h");
    @cInclude("xdg-decoration-unstable-v1.h");
    @cInclude("sys/mman.h");
});

title: []const u8,
display: *c.wl_display,
registry: *c.wl_registry,
compositor: ?*c.wl_compositor = null,
surface: ?*c.wl_surface = null,
shm: ?*c.wl_shm = null,
seat: ?*c.wl_seat = null,
xdg_toplevel: ?*c.xdg_toplevel = null,
xdg_wm_base: ?*c.xdg_wm_base = null,
xdg_surface: ?*c.xdg_surface = null,
xdg_decoration_manager: ?*c.zxdg_decoration_manager_v1 = null,
input: WindowInput = .{ .keyboard = null, .pointer = null },
configured: bool = false,

pub const WindowInput = struct {
    keyboard: ?*c.wl_keyboard,
    pointer: ?*c.wl_pointer,
};

export fn registryHandleGlobal(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, version: u32) void {
    _ = version;
    // std.log.info("interface: {s}, version: {d}, name: {d}", .{ interface, version, name });
    const self: *@This() = @alignCast(@ptrCast(data));

    const intf = std.mem.span(interface);

    if (std.mem.eql(u8, intf, std.mem.span(c.wl_compositor_interface.name))) {
        self.compositor = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_compositor_interface, 4));
    } else if (std.mem.eql(u8, intf, std.mem.span(c.wl_shm_interface.name))) {
        std.log.debug("binding shm", .{});
        self.shm = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_shm_interface, 1));
    } else if (std.mem.eql(u8, intf, std.mem.span(c.xdg_wm_base_interface.name))) {
        self.xdg_wm_base = @ptrCast(c.wl_registry_bind(registry, name, &c.xdg_wm_base_interface, 1));
        _ = c.xdg_wm_base_add_listener(self.xdg_wm_base, &xdg_wm_base_listener, data);
    } else if (std.mem.eql(u8, intf, std.mem.span(c.zxdg_decoration_manager_v1_interface.name))) {
        self.xdg_decoration_manager = @ptrCast(c.wl_registry_bind(registry, name, &c.zxdg_decoration_manager_v1_interface, 1));
    } else if (std.mem.eql(u8, intf, std.mem.span(c.wl_seat_interface.name))) {
        self.seat = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_seat_interface, 7));
    }
}

export fn registryHandleGlobalRemove(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32) void {
    _ = data;
    _ = registry;
    _ = name;
}

export fn xdgWmBasePing(data: ?*anyopaque, xdg_wm_base: ?*c.xdg_wm_base, serial: u32) void {
    c.xdg_wm_base_pong(xdg_wm_base, serial);
    _ = data;
}

export fn xdgSurfaceConfigure(data: ?*anyopaque, xdg_surface: ?*c.xdg_surface, serial: u32) void {
    const self: *@This() = @alignCast(@ptrCast(data));

    c.xdg_surface_ack_configure(xdg_surface, serial);

    std.log.info("xdgSurfaceConfigure", .{});

    self.configured = true;

    // if (!self.configured) {
    //     const bfr = drawFrame(self) catch unreachable;
    //     c.wl_surface_attach(self.surface, bfr, 0, 0);
    //     c.wl_surface_commit(self.surface);
    // }
}

// fn createShmFile() !i32 {
//     var ts: std.posix.timespec = .{ .sec = 0, .nsec = 0 };
//     std.posix.clock_gettime(std.posix.CLOCK.REALTIME, &ts) catch unreachable;
//     var r = ts.nsec;
//
//     var name: [13]u8 = .{ '/', 'w', 'l', 's', 'h', 'm', '-', 0, 0, 0, 0, 0, 0 };
//     for (7..12) |i| {
//         name[i] = @intCast('A' + (r & 15) + (r & 16) * 2);
//         r >>= 5;
//     }
//
//     std.log.debug("creating shm file {s}", .{name});
//
//     const fd = std.c.shm_open(@ptrCast(&name), @bitCast(std.os.linux.O{ .CREAT = true, .EXCL = true, .ACCMODE = .RDWR }), 0o666);
//     if (fd >= 0) {
//         _ = std.c.shm_unlink(@ptrCast(&name));
//         return fd;
//     }
//
//     return linux_wayland_error.shm_open_failed;
// }
//
// fn allocateShmFile(size: i64) !i32 {
//     const fd = try createShmFile();
//     if (fd < 0) return linux_wayland_error.shm_open_failed;
//
//     var ret = std.c.ftruncate(fd, size);
//     if (ret < 0) {
//         ret = std.c.ftruncate(fd, size);
//     }
//     if (ret < 0) {
//         _ = std.c.close(fd);
//         return linux_wayland_error.shm_truncate_failed;
//     }
//
//     return fd;
// }

// export fn wlBufferRelease(data: ?*anyopaque, buffer: ?*c.wl_buffer) void {
//     _ = data;
//     _ = buffer;
//     std.log.debug("releasing buffer", .{});
//     // c.wl_buffer_destroy(buffer);
// }
//
// pub const wl_buffer_listener: c.wl_buffer_listener = .{
//     .release = wlBufferRelease,
// };

pub const linux_wayland_error = error{ shm_open_failed, shm_truncate_failed };

// pub fn drawFrame(self: *@This()) !*c.wl_buffer {
//     const width = 640;
//     const height = 480;
//     const stride = width * 4;
//     const size = stride * height;
//
//     const fd = try allocateShmFile(size);
//     const data = try std.posix.mmap(null, size, std.os.linux.PROT.READ | std.os.linux.PROT.WRITE, std.os.linux.MAP{ .TYPE = .SHARED }, fd, 0);
//
//     const pool = c.wl_shm_create_pool(self.shm.?, fd, size).?;
//     const buffer = c.wl_shm_pool_create_buffer(pool, 0, width, height, stride, c.WL_SHM_FORMAT_XRGB8888).?;
//     c.wl_shm_pool_destroy(pool);
//     _ = std.c.close(fd);
//
//     for (0..height) |y| {
//         for (0..width) |x| {
//             data[y * width + x] = 0xFF;
//             data[y * width + x + 1] = 0x66;
//             data[y * width + x + 2] = 0x33;
//             data[y * width + x + 3] = 0xEE;
//         }
//     }
//
//     _ = std.os.linux.munmap(@ptrCast(data), size);
//     _ = c.wl_buffer_add_listener(buffer, &wl_buffer_listener, null);
//
//     return buffer;
// }

pub const registry_listener: c.wl_registry_listener = .{
    .global = registryHandleGlobal,
    .global_remove = registryHandleGlobalRemove,
};

pub const xdg_wm_base_listener: c.xdg_wm_base_listener = .{
    .ping = xdgWmBasePing,
};

pub const xdg_surface_listener: c.xdg_surface_listener = .{
    .configure = xdgSurfaceConfigure,
};

pub fn init(window_options: *const WindowOptions) @This() {
    std.log.info("Starting LinuxWayland platform", .{});
    const display: *c.wl_display = c.wl_display_connect(null).?;
    const registry: *c.wl_registry = c.wl_display_get_registry(display).?;

    return .{
        .display = display,
        .registry = registry,
        .title = window_options.title,
    };
}

pub fn setup(self: *@This()) void {
    _ = c.wl_registry_add_listener(self.registry, &registry_listener, @constCast(@ptrCast(self)));
    _ = c.wl_display_roundtrip(self.display);

    self.surface = @ptrCast(c.wl_compositor_create_surface(self.compositor).?);
    self.xdg_surface = @ptrCast(c.xdg_wm_base_get_xdg_surface(self.xdg_wm_base, self.surface).?);
    _ = c.xdg_surface_add_listener(self.xdg_surface, &xdg_surface_listener, @constCast(@ptrCast(self)));
    self.xdg_toplevel = c.xdg_surface_get_toplevel(self.xdg_surface).?;
    c.xdg_toplevel_set_title(self.xdg_toplevel, @ptrCast(self.title));
    _ = c.wl_display_roundtrip(self.display);
    c.wl_surface_commit(self.surface);

    const decoration = c.zxdg_decoration_manager_v1_get_toplevel_decoration(self.xdg_decoration_manager, self.xdg_toplevel);
    c.zxdg_toplevel_decoration_v1_set_mode(decoration, c.ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE);

    while (c.wl_display_dispatch(self.display) != -1 and !self.configured) {}

    self.input.keyboard = c.wl_seat_get_keyboard(self.seat);
    self.input.pointer = c.wl_seat_get_pointer(self.seat);

    // const bfr = self.drawFrame() catch unreachable;
    // c.wl_surface_attach(self.surface, bfr, 0, 0);
    // c.wl_surface_commit(self.surface);

    std.log.info("Ending..", .{});
}

pub fn deinit(self: *@This()) void {
    c.wl_display_disconnect(self.display);
}

pub fn dispatch(self: *@This()) i32 {
    _ = c.wl_display_roundtrip(self.display);
    return 0;
    //return @intCast(c.wl_display_dispatch(self.display));
}
