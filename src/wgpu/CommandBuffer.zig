const CommandBuffer = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;

native: *wg.WGPUCommandBufferImpl,

pub fn init(command_buffer: *wg.WGPUCommandBufferImpl) @This() {
    return .{ .native = command_buffer };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuCommandBufferRelease(self.native);
}
