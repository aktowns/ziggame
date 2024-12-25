const RenderPassEncoder = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const RenderPipeline = @import("RenderPipeline.zig");
const Buffer = @import("Buffer.zig");
const BindGroup = @import("BindGroup.zig");

native: *wg.WGPURenderPassEncoderImpl,

pub inline fn init(render_pass_encoder: *wg.WGPURenderPassEncoderImpl) @This() {
    return .{ .native = render_pass_encoder };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuRenderPassEncoderRelease(self.native);
}

pub fn setPipeline(self: *const @This(), render_pipeline: *const RenderPipeline) void {
    wg.wgpuRenderPassEncoderSetPipeline(self.native, render_pipeline.native);
}

pub fn setVertexBuffer(self: *const @This(), slot: u32, buffer: Buffer, offset: u64, size: u64) void {
    wg.wgpuRenderPassEncoderSetVertexBuffer(self.native, slot, buffer.native, offset, size);
}

pub fn setIndexBuffer(self: *const @This(), buffer: Buffer, format: wg.WGPUIndexFormat, offset: u64, size: u64) void {
    wg.wgpuRenderPassEncoderSetIndexBuffer(self.native, buffer.native, format, offset, size);
}

pub fn setBindGroup(self: *const @This(), index: u32, bind_group: *const BindGroup, dynamic_offsets: []const u32) void {
    wg.wgpuRenderPassEncoderSetBindGroup(self.native, index, bind_group.native, dynamic_offsets.len, dynamic_offsets.ptr);
}

pub fn draw(self: *const @This(), vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
    wg.wgpuRenderPassEncoderDraw(self.native, vertex_count, instance_count, first_vertex, first_instance);
}

pub fn drawIndexed(self: *const @This(), index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
    wg.wgpuRenderPassEncoderDrawIndexed(self.native, index_count, instance_count, first_index, base_vertex, first_instance);
}

pub fn end(self: *const @This()) void {
    wg.wgpuRenderPassEncoderEnd(self.native);
}
