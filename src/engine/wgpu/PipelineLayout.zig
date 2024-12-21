const PipelineLayout = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

pipelineLayout: *wg.WGPUPipelineLayoutImpl,

pub fn init(pipelineLayout: *wg.WGPUPipelineLayoutImpl) @This() {
    return .{ .pipelineLayout = pipelineLayout };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuPipelineLayoutRelease(self.pipelineLayout);
}
