const ShaderModule = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

native: *wg.WGPUShaderModuleImpl,

pub fn init(shader_module: *wg.WGPUShaderModuleImpl) @This() {
    return .{ .native = shader_module };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuShaderModuleRelease(self.native);
}
