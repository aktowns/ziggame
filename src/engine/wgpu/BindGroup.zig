const BindGroup = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

bindGroup: *wg.WGPUBindGroupImpl,

pub fn init(bindGroup: *wg.WGPUBindGroupImpl) @This() {
    return .{ .bindGroup = bindGroup };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBindGroupRelease(self.bindGroup);
}