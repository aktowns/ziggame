const Sampler = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;

native: *wg.WGPUSamplerImpl,

pub fn init(sampler: *wg.WGPUSamplerImpl) @This() {
    return .{ .native = sampler };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuSamplerRelease(self.native);
}
