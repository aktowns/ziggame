const RenderPipeline = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

renderPipeline: *wg.WGPURenderPipelineImpl,

pub fn init(renderPipeline: *wg.WGPURenderPipelineImpl) @This() {
    return .{ .renderPipeline = renderPipeline };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuRenderPipelineRelease(self.renderPipeline);
}
