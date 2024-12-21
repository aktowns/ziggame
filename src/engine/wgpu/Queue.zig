const Queue = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

queue: *wg.WGPUQueueImpl,

pub fn init(queue: *wg.WGPUQueueImpl) @This() {
    return .{ .queue = queue };
}

pub fn submit(self: *const @This(), commandCount: usize, commands: [*c]const wg.WGPUCommandBuffer) void {
    wg.wgpuQueueSubmit(self.queue, commandCount, commands);
}
