const RenderPassEncoder = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const RenderPipeline = @import("RenderPipeline.zig");
const Buffer = @import("Buffer.zig");
const BindGroup = @import("BindGroup.zig");

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

pub fn setVertexBuffer(self: *const @This(), slot: u32, buffer: Buffer, offset: u64, size: u64) void {
    wg.wgpuRenderPassEncoderSetVertexBuffer(self.renderPassEncoder, slot, buffer.buffer, offset, size);
}

pub fn setIndexBuffer(self: *const @This(), buffer: Buffer, format: wg.WGPUIndexFormat, offset: u64, size: u64) void {
    wg.wgpuRenderPassEncoderSetIndexBuffer(self.renderPassEncoder, buffer.buffer, format, offset, size);
}

pub fn setBindGroup(self: *const @This(), index: u32, bindGroup: *const BindGroup, dynamicOffsets: []const u32) void {
    wg.wgpuRenderPassEncoderSetBindGroup(self.renderPassEncoder, index, bindGroup.bindGroup, dynamicOffsets.len, dynamicOffsets.ptr);
}

pub fn draw(self: *const @This(), vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) void {
    wg.wgpuRenderPassEncoderDraw(self.renderPassEncoder, vertexCount, instanceCount, firstVertex, firstInstance);
}

pub fn drawIndexed(self: *const @This(), indexCount: u32, instanceCount: u32, firstIndex: u32, baseVertex: i32, firstInstance: u32) void {
    wg.wgpuRenderPassEncoderDrawIndexed(self.renderPassEncoder, indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
}

pub fn end(self: *const @This()) void {
    wg.wgpuRenderPassEncoderEnd(self.renderPassEncoder);
}
