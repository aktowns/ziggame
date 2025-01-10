const BindGroup = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;

native: *wg.WGPUBindGroupImpl,

pub fn init(bind_group: *wg.WGPUBindGroupImpl) @This() {
    return .{ .native = bind_group };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBindGroupRelease(self.native);
}
