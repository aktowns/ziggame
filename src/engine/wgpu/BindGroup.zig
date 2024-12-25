const BindGroup = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

native: *wg.WGPUBindGroupImpl,

pub fn init(bind_group: *wg.WGPUBindGroupImpl) @This() {
    return .{ .native = bind_group };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBindGroupRelease(self.native);
}
