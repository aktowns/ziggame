const Adapter = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const Error = @import("error.zig").Error;
const Device = @import("Device.zig");
const Platform = @import("../Platform.zig");
const u = @import("../util.zig");
const log = @import("../log.zig");

native: *wg.WGPUAdapterImpl,
device: ?Device,
platform: *const Platform,

pub fn init(platform: *const Platform, adapter: *wg.WGPUAdapterImpl) @This() {
    return .{ .native = adapter, .device = null, .platform = platform };
}

export fn handle_request_device(status: wg.WGPURequestDeviceStatus, device: wg.WGPUDevice, message: u.StringView, userData: ?*anyopaque) void {
    log.debug(@src(), "Got device callback", .{});
    if (status == wg.WGPURequestDeviceStatus_Success) {
        const inst = @as(?*Adapter, @alignCast(@ptrCast(userData))).?;
        inst.device = Device.init(inst.platform, device.?);
    } else {
        log.err(@src(), "request_device status={d} message={s}", .{ status, u.stringViewData(message) });
    }
}

pub fn requestDevice(self: *const @This(), descriptor: [*c]const wg.WGPUDeviceDescriptor) Device {
    if (self.device == null) {
        wg.wgpuAdapterRequestDevice(self.native, descriptor, handle_request_device, @ptrCast(@constCast(self)));
    }

    // TODO: Implement proper waiting
    while (self.device == null) {
        log.debug(@src(), "Waiting for device", .{});

        Platform.sleep(1000);
    }

    log.debug(@src(), "got device", .{});

    return self.device.?;
}
