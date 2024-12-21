const RenderPassEncoder = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const RenderPipeline = @import("RenderPipeline.zig");

renderPassEncoder: *wg.WGPURenderPassEncoderImpl,

pub inline fn init(renderPassEncoder: *wg.WGPURenderPassEncoderImpl) @This() {
    return .{ .renderPassEncoder = renderPassEncoder };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuRenderPassEncoderRelease(self.renderPassEncoder);
}

pub fn setPipeline(self: *const @This(), pipeline: *const RenderPipeline) void {
    wg.wgpuRenderPassEncoderSetPipeline(self.renderPassEncoder, pipeline.renderPipeline);
}

pub fn draw(self: *const @This(), vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) void {
    wg.wgpuRenderPassEncoderDraw(self.renderPassEncoder, vertexCount, instanceCount, firstVertex, firstInstance);
}

pub fn end(self: *const @This()) void {
    wg.wgpuRenderPassEncoderEnd(self.renderPassEncoder);
}
