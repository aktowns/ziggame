const RenderPipeline = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

native: *wg.WGPURenderPipelineImpl,

pub fn init(render_pipeline: *wg.WGPURenderPipelineImpl) @This() {
    return .{ .native = render_pipeline };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuRenderPipelineRelease(self.native);
}
