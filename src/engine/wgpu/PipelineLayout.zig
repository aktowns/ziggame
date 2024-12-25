const PipelineLayout = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

native: *wg.WGPUPipelineLayoutImpl,

pub fn init(pipeline_layout: *wg.WGPUPipelineLayoutImpl) @This() {
    return .{ .native = pipeline_layout };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuPipelineLayoutRelease(self.native);
}
