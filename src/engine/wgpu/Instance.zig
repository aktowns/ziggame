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
const log = @import("wingman").log;
const enums = @import("enums.zig");
const WaitStatus = enums.WaitStatus;
const RequestAdapterStatus = enums.RequestAdapterStatus;
const CallbackMode = enums.CallbackMode;

native: *wg.WGPUInstanceImpl,
adapter: ?Adapter = null,
platform: *const Platform,
sentinel: ?*u8 = null,

pub fn init(platform: *const Platform, descriptor: [*c]const wg.WGPUInstanceDescriptor) Error!@This() {
    const instance = wg.wgpuCreateInstance(descriptor) orelse return Error.FailedToCreateInstance;
    return .{
        .native = instance,
        .platform = platform,
        .sentinel = platform.sentinel(),
    };
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

    const mstatus = std.meta.intToEnum(RequestAdapterStatus, status) catch |err| ret: {
        log.err(@src(), "Unhandled RequestDeviceStatus {d}: {?}", .{ status, err });
        break :ret RequestAdapterStatus.unknown;
    };

    switch (mstatus) {
        .success => {
            const inst = @as(?*Instance, @alignCast(@ptrCast(userData))).?;
            inst.adapter = Adapter.init(inst.platform, inst, adapter.?);
        },
        else => log.err(@src(), "request_adapter status={d} message={?s}", .{ status, u.stringViewData(message) }),
    }
}

pub fn requestAdapter(self: *const @This(), options: [*c]const wg.WGPURequestAdapterOptions) Adapter {
    if (self.adapter == null) {
        log.debug(@src(), "requesting new adapter", .{});
        // wg.wgpuInstanceRequestAdapter(self.native, options, handle_request_adapter, @ptrCast(@constCast(self)));

        const future = wg.wgpuInstanceRequestAdapterF(self.native, options, wg.WGPURequestAdapterCallbackInfo{
            .mode = @intFromEnum(CallbackMode.wait_any_only),
            .callback = handle_request_adapter,
            .userdata = @ptrCast(@constCast(self)),
        });

        log.debug(@src(), "adapter future id {d}", .{future.id});

        var futures = [_]wg.WGPUFutureWaitInfo{wg.WGPUFutureWaitInfo{ .completed = 0, .future = future }};
        const wait_res = self.waitAny(&futures, std.time.ns_per_s * 5);

        switch (wait_res) {
            .success => log.debug(@src(), "future wait complete {any}", .{futures}),
            else => log.err(@src(), "adapter future failed {?}", .{wait_res}),
        }
    }

    // TODO: Implement proper waiting
    // while (self.adapter == null) {
    //     log.debug(@src(), "Waiting for adapter", .{});

    //     Platform.sleep(1000);
    // }

    log.debug(@src(), "got adapter", .{});

    return self.adapter.?;
}

pub fn waitAny(self: *const @This(), futures: []wg.WGPUFutureWaitInfo, timeout_ns: u64) WaitStatus {
    const res = wg.wgpuInstanceWaitAny(self.native, futures.len, futures.ptr, timeout_ns);
    return std.meta.intToEnum(WaitStatus, res) catch |err| {
        log.err(@src(), "Unhandled WaitStatus return code {d}: {?}", .{ res, err });
        return WaitStatus.unknown;
    };
}
