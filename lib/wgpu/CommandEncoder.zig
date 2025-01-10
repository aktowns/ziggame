const CommandEncoder = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;
const RenderPassEncoder = @import("RenderPassEncoder.zig");
const CommandBuffer = @import("CommandBuffer.zig");

native: *wg.WGPUCommandEncoderImpl,

pub fn init(command_encoder: *wg.WGPUCommandEncoderImpl) @This() {
    return .{ .native = command_encoder };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuCommandEncoderRelease(self.native);
}

pub fn beginRenderPass(self: *const @This(), descriptor: [*c]const wg.WGPURenderPassDescriptor) RenderPassEncoder {
    const brp = wg.wgpuCommandEncoderBeginRenderPass(self.native, descriptor).?;

    return RenderPassEncoder.init(brp);
}

pub fn finish(self: *const @This(), descriptor: [*c]const wg.WGPUCommandBufferDescriptor) CommandBuffer {
    const bfr = wg.wgpuCommandEncoderFinish(self.native, descriptor).?;

    return CommandBuffer.init(bfr);
}
