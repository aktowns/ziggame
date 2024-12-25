const Sampler = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");

const wg = cincludes.wg;

native: *wg.WGPUSamplerImpl,

pub fn init(sampler: *wg.WGPUSamplerImpl) @This() {
    return .{ .native = sampler };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuSamplerRelease(self.native);
}
