const Adapter = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const Error = @import("error.zig").Error;
const Device = @import("Device.zig");

adapter: *wg.WGPUAdapterImpl,
device: ?Device,
allocator: std.mem.Allocator,

pub fn init(adapter: *wg.WGPUAdapterImpl, allocator: std.mem.Allocator) @This() {
    return .{ .adapter = adapter, .device = null, .allocator = allocator };
}

export fn handle_request_device(status: wg.WGPURequestDeviceStatus, device: wg.WGPUDevice, message: wg.WGPUStringView, userData: ?*anyopaque) void {
    if (status == wg.WGPURequestDeviceStatus_Success) {
        const inst = @as(?*Adapter, @alignCast(@ptrCast(userData))).?;
        inst.device = Device.init(device.?, inst.allocator);
    } else {
        std.log.err("[Adapter] request_device status={d} message={s}", .{ status, message.data });
    }
}

pub fn requestDevice(self: *const @This(), descriptor: [*c]const wg.WGPUDeviceDescriptor) Device {
    if (self.device == null) {
        wg.wgpuAdapterRequestDevice(self.adapter, descriptor, handle_request_device, @ptrCast(@constCast(self)));
    }

    // TODO: Implement proper waiting
    while (self.device == null) {
        std.log.debug("[Adapter] Waiting for device", .{});
    }

    std.log.debug("[Adapter] got device", .{});

    return self.device.?;
}
