const Instance = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const Adapter = @import("Adapter.zig");
const Surface = @import("Surface.zig");
const Error = @import("error.zig").Error;
const Platform = @import("../Platform.zig");
const u = @import("../util.zig");
const log = @import("../log.zig");

native: *wg.WGPUInstanceImpl,
adapter: ?Adapter = null,
platform: *const Platform,
sentinel: ?*u8 = null,

pub fn init(platform: *const Platform) Error!@This() {
    const instance = wg.wgpuCreateInstance(null) orelse return Error.FailedToCreateInstance;
    return .{ .native = instance, .platform = platform, .sentinel = platform.sentinel() };
}

pub fn createSurface(self: *const @This(), descriptor: [*c]const wg.WGPUSurfaceDescriptor) Error!Surface {
    const surface = wg.wgpuInstanceCreateSurface(self.native, descriptor);

    return Surface.init(surface.?, self);
}

pub fn createSurfaceFromNative(self: *const @This(), source: Platform.NativeSurface) Error!Surface {
    const surface_descriptor = wg.WGPUSurfaceDescriptor{
        .nextInChain = @ptrCast(&source),
        .label = u.stringView("Surface"),
    };

    return self.createSurface(&surface_descriptor);
}

export fn handle_request_adapter(status: wg.WGPURequestDeviceStatus, adapter: wg.WGPUAdapter, message: u.StringView, userData: ?*anyopaque) void {
    log.debug(@src(), "request_adapter status={d}", .{status});
    if (status == wg.WGPURequestAdapterStatus_Success) {
        const inst = @as(?*Instance, @alignCast(@ptrCast(userData))).?;
        inst.adapter = Adapter.init(inst.platform, adapter.?);
    } else {
        log.err(@src(), "request_adapter status={d} message={s}", .{ status, u.stringViewData(message) });
    }
}

pub fn requestAdapter(self: *const @This(), options: [*c]const wg.WGPURequestAdapterOptions) Adapter {
    if (self.adapter == null) {
        log.debug(@src(), "Requesting new adapter", .{});
        wg.wgpuInstanceRequestAdapter(self.native, options, handle_request_adapter, @ptrCast(@constCast(self)));
    }

    // TODO: Implement proper waiting
    while (self.adapter == null) {
        log.debug(@src(), "Waiting for adapter", .{});

        Platform.sleep(1000);
    }

    log.debug(@src(), "got adapter", .{});

    return self.adapter.?;
}
