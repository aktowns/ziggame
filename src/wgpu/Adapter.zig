const Adapter = @This();

const std = @import("std");
const builtin = @import("builtin");
const wg = @import("cincludes.zig").wg;
const Error = @import("error.zig").Error;
const Device = @import("Device.zig");
const Platform = @import("../Platform.zig");
const Instance = @import("Instance.zig");
const log = @import("wingman").log;
const enums = @import("enums.zig");
const CallbackMode = enums.CallbackMode;
const string_view = @import("string_view.zig");
const StringView = string_view.StringView;

native: *wg.WGPUAdapterImpl,
device: ?Device,
instance: *Instance,

pub fn init(instance: *Instance, adapter: *wg.WGPUAdapterImpl) @This() {
    return .{
        .native = adapter,
        .instance = instance,
        .device = null,
    };
}

export fn handle_request_device(status: wg.WGPURequestDeviceStatus, device: wg.WGPUDevice, message: StringView, userData: ?*anyopaque) void {
    log.debug(@src(), "Got device callback", .{});
    if (status == wg.WGPURequestDeviceStatus_Success) {
        const inst = @as(?*Adapter, @alignCast(@ptrCast(userData))).?;
        inst.device = Device.init(device.?);
    } else {
        log.err(@src(), "request_device status={d} message={?s}", .{ status, string_view.data(message) });
    }
}

pub fn requestDevice(self: *const @This(), descriptor: [*c]const wg.WGPUDeviceDescriptor) Device {
    if (self.device == null) {
        // wg.wgpuAdapterRequestDevice(self.native, descriptor, handle_request_device, @ptrCast(@constCast(self)));
        const future = wg.wgpuAdapterRequestDeviceF(self.native, descriptor, wg.WGPURequestDeviceCallbackInfo{
            .callback = handle_request_device,
            .mode = @intFromEnum(CallbackMode.wait_any_only),
            .userdata = @ptrCast(@constCast(self)),
        });

        log.debug(@src(), "device future id {d}", .{future.id});

        var futures = [_]wg.WGPUFutureWaitInfo{wg.WGPUFutureWaitInfo{ .completed = 0, .future = future }};
        const wait_res = self.instance.waitAny(&futures, std.time.ns_per_s * 5);

        switch (wait_res) {
            .success => log.debug(@src(), "future wait complete {any}", .{futures}),
            else => log.err(@src(), "device future failed {?}", .{wait_res}),
        }
    }

    // TODO: Implement proper waiting
    // while (self.device == null) {
    //     log.debug(@src(), "Waiting for device", .{});

    //     Platform.sleep(1000);
    // }

    log.debug(@src(), "got device", .{});

    return self.device.?;
}
