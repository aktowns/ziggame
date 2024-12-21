const CommandEncoder = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const RenderPassEncoder = @import("RenderPassEncoder.zig");
const CommandBuffer = @import("CommandBuffer.zig");

commandEncoder: *wg.WGPUCommandEncoderImpl,

pub fn init(commandEncoder: *wg.WGPUCommandEncoderImpl) @This() {
    return .{ .commandEncoder = commandEncoder };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuCommandEncoderRelease(self.commandEncoder);
}

pub fn beginRenderPass(self: *const @This(), descriptor: [*c]const wg.WGPURenderPassDescriptor) RenderPassEncoder {
    const brp = wg.wgpuCommandEncoderBeginRenderPass(self.commandEncoder, descriptor).?;

    return RenderPassEncoder.init(brp);
}

pub fn finish(self: *const @This(), descriptor: [*c]const wg.WGPUCommandBufferDescriptor) CommandBuffer {
    const bfr = wg.wgpuCommandEncoderFinish(self.commandEncoder, descriptor).?;

    return CommandBuffer.init(bfr);
}
