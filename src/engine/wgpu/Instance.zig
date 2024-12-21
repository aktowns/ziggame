const Instance = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const Adapter = @import("Adapter.zig");
const Surface = @import("Surface.zig");
const Error = @import("error.zig").Error;
const u = @import("../util.zig");

instance: *wg.WGPUInstanceImpl,
adapter: ?Adapter = null,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Error!@This() {
    const instance = wg.wgpuCreateInstance(null) orelse return Error.FailedToCreateInstance;
    return .{ .instance = instance, .allocator = allocator };
}

pub fn createSurface(self: *const @This(), descriptor: [*c]const wg.WGPUSurfaceDescriptor) Error!Surface {
    const surface = wg.wgpuInstanceCreateSurface(self.instance, descriptor);

    return Surface.init(surface.?, self);
}

pub fn createSurfaceFromSource(self: *const @This(), source: Surface.SurfaceSource) Error!Surface {
    const surface_descriptor = switch (source) {
        .MacOS => |chain| wg.WGPUSurfaceDescriptor{ .nextInChain = @ptrCast(&chain), .label = u.stringView("MacOSSurface") },
        .Linux => |chain| wg.WGPUSurfaceDescriptor{ .nextInChain = @ptrCast(&chain), .label = u.stringView("LinuxSurface") },
        .Windows => |chain| wg.WGPUSurfaceDescriptor{ .nextInChain = @ptrCast(&chain), .label = u.stringView("WindowsSurface") },
        .Web => |chain| wg.WGPUSurfaceDescriptor{ .nextInChain = @ptrCast(&chain), .label = u.stringView("WebSurface") },
    };

    return self.createSurface(&surface_descriptor);
}

export fn handle_request_adapter(status: wg.WGPURequestDeviceStatus, adapter: wg.WGPUAdapter, message: wg.WGPUStringView, userData: ?*anyopaque) void {
    std.log.debug("[Instance] request_adapter status={d}", .{status});
    if (status == wg.WGPURequestAdapterStatus_Success) {
        const inst = @as(?*Instance, @alignCast(@ptrCast(userData))).?;
        inst.adapter = Adapter.init(adapter.?, inst.allocator);
    } else {
        std.log.err("[Instance] request_adapter status={d} message={s}", .{ status, message.data });
    }
}

pub fn requestAdapter(self: *const @This(), options: [*c]const wg.WGPURequestAdapterOptions) Adapter {
    if (self.adapter == null) {
        wg.wgpuInstanceRequestAdapter(self.instance, options, handle_request_adapter, @ptrCast(@constCast(self)));
    }

    // TODO: Implement proper waiting
    while (self.adapter == null) {
        std.log.debug("[Instance] Waiting for adapter", .{});
    }

    std.log.debug("[Instance] got adapter", .{});

    return self.adapter.?;
}
