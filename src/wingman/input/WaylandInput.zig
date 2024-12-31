pub const WaylandInput = @This();

const std = @import("std");
const builtin = @import("builtin");
const log = @import("../log/log.zig");
const linux_wayland = @import("../window/linux_wayland.zig");
const c = linux_wayland.c;

const Events = @import("Events.zig");

input: *const linux_wayland.WindowInput,

pub const PointerEvent = packed struct {
    mouse_enter: bool = false,
    mouse_leave: bool = false,
    mouse_motion: bool = false,
    mouse_button: bool = false,
    axis: bool = false,
    axis_source: bool = false,
    axis_stop: bool = false,
    axis_discrete: bool = false,
};

pub const PointerAxis = struct {
    valid: bool = false,
    value: i32 = 0,
    discrete: i32 = 0,
};

pub const PointerState = struct {
    event: PointerEvent,
    serial: u32 = 0,
    time: u32 = 0,
    surface_x: i32 = 0,
    surface_y: i32 = 0,
    button: u32 = 0,
    button_state: u32 = 0,
    axes: [2]PointerAxis = .{ PointerAxis{}, PointerAxis{} },
    axis_source: u32 = 0,
    mutex: std.Thread.Mutex,
};

export fn onEnter(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, serial: u32, surface: ?*c.wl_surface, surface_x: i32, surface_y: i32) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.mouse_enter = true;
    state.serial = serial;
    state.surface_x = surface_x;
    state.surface_y = surface_y;

    _ = wl_pointer;
    _ = surface;
}

export fn onMotion(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, time: u32, surface_x: i32, surface_y: i32) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.mouse_motion = true;
    state.surface_x = surface_x;
    state.surface_y = surface_y;

    _ = time;
    _ = wl_pointer;
}

export fn onLeave(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, serial: u32, surface: ?*c.wl_surface) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.mouse_leave = true;
    state.serial = serial;

    _ = wl_pointer;
    _ = surface;
}

export fn onFrame(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    if (state.mutex.tryLock()) {
        if (state.event.mouse_enter) {
            log.debug(@src(), "entered {d}x{d}", .{ state.surface_x, state.surface_y });
        }
        if (state.event.mouse_leave) {
            log.debug(@src(), "leave", .{});
        }
        if (state.event.mouse_motion) {
            // log.debug(@src(), "motion {d}x{d}", .{ state.surface_x, state.surface_y });
        }
        if (state.event.mouse_button) {
            const button_state = if (state.button_state == c.WL_POINTER_BUTTON_STATE_RELEASED) "released" else "pressed";
            log.debug(@src(), "button {d} {s}", .{ state.button, button_state });
        }

        var axis_name: [2][]const u8 = undefined;
        axis_name[c.WL_POINTER_AXIS_VERTICAL_SCROLL] = "vertical";
        axis_name[c.WL_POINTER_AXIS_HORIZONTAL_SCROLL] = "horizontal";

        var axis_source: [4][]const u8 = undefined;
        axis_source[c.WL_POINTER_AXIS_SOURCE_WHEEL] = "wheel";
        axis_source[c.WL_POINTER_AXIS_SOURCE_FINGER] = "finger";
        axis_source[c.WL_POINTER_AXIS_SOURCE_CONTINUOUS] = "continous";
        axis_source[c.WL_POINTER_AXIS_SOURCE_WHEEL_TILT] = "wheel tilt";

        if (state.event.axis or state.event.axis_discrete or state.event.axis_source or state.event.axis_stop) {
            log.debug(@src(), "axis event", .{});
            for (0..1) |i| {
                if (state.axes[i].valid) continue;

                std.log.debug("{s} axis", .{axis_name[i]});

                if (state.event.axis) {
                    log.debug(@src(), "value {d}", .{state.axes[i].value});
                }
                if (state.event.axis_discrete) {
                    log.debug(@src(), "discrete {d}", .{state.axes[i].discrete});
                }
                if (state.event.axis_source) {
                    log.debug(@src(), "via {s}", .{axis_source[i]});
                }
                if (state.event.axis_stop) {
                    log.debug(@src(), "stopped", .{});
                }
            }
        }

        state.mutex.unlock();
        state.* = PointerState{ .event = PointerEvent{}, .mutex = state.mutex };
        // state.event = PointerEvent{};
    }

    _ = wl_pointer;
}

export fn onButton(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, serial: u32, time: u32, button: u32, button_state: u32) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.mouse_button = true;
    state.serial = serial;
    state.time = time;
    state.button = button;
    state.button_state = button_state;

    _ = wl_pointer;
}

export fn onAxis(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, time: u32, axis: u32, value: i32) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.axis = true;
    state.time = time;
    state.axes[axis].valid = true;
    state.axes[axis].value = value;

    _ = wl_pointer;
}

export fn onAxisSource(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, axis_source: u32) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.axis_source = true;
    state.axis_source = axis_source;

    _ = wl_pointer;
}

export fn onAxisStop(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, time: u32, axis: u32) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.axis_stop = true;
    state.time = time;
    state.axes[axis].valid = true;

    _ = wl_pointer;
}

export fn onAxisDiscrete(data: ?*anyopaque, wl_pointer: ?*c.wl_pointer, axis: u32, discrete: i32) void {
    const state: *PointerState = @alignCast(@ptrCast(data));

    state.mutex.lock();
    defer state.mutex.unlock();

    state.event.axis_discrete = true;
    state.axes[axis].valid = true;
    state.axes[axis].discrete = discrete;

    _ = wl_pointer;
}

pub const pointer_listener: c.wl_pointer_listener = .{
    .enter = onEnter,
    .motion = onMotion,
    .leave = onLeave,
    .frame = onFrame,
    .button = onButton,
    .axis = onAxis,
    .axis_source = onAxisSource,
    .axis_stop = onAxisStop,
    .axis_discrete = onAxisDiscrete,
};

pub fn init(events: *const Events, input: *const linux_wayland.WindowInput) @This() {
    _ = events;

    var state = PointerState{ .event = PointerEvent{}, .mutex = std.Thread.Mutex{} };

    _ = c.wl_pointer_add_listener(input.pointer, &pointer_listener, @ptrCast(&state));

    return .{ .input = input };
}
