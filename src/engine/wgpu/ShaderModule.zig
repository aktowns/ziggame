const ShaderModule = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

shaderModule: *wg.WGPUShaderModuleImpl,

pub fn init(shaderModule: *wg.WGPUShaderModuleImpl) @This() {
    return .{ .shaderModule = shaderModule };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuShaderModuleRelease(self.shaderModule);
}
