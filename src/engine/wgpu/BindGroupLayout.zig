const BindGroupLayout = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

native: *wg.WGPUBindGroupLayoutImpl,

pub fn init(bind_group_layout: *wg.WGPUBindGroupLayoutImpl) @This() {
    return .{ .native = bind_group_layout };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBindGroupLayoutRelease(self.native);
}
