const CommandBuffer = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

commandBuffer: *wg.WGPUCommandBufferImpl,

pub fn init(commandBuffer: *wg.WGPUCommandBufferImpl) @This() {
    return .{ .commandBuffer = commandBuffer };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuCommandBufferRelease(self.commandBuffer);
}
