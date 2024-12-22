const BindGroupLayout = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

bindGroupLayout: *wg.WGPUBindGroupLayoutImpl,

pub fn init(bindGroupLayout: *wg.WGPUBindGroupLayoutImpl) @This() {
    return .{ .bindGroupLayout = bindGroupLayout };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBindGroupLayoutRelease(self.bindGroupLayout);
}