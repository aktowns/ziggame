const Buffer = @This();

const std = @import("std");

const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

buffer: *wg.WGPUBufferImpl,

pub fn init(buffer: *wg.WGPUBufferImpl) @This() {
    return .{ .buffer = buffer };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBufferRelease(self.buffer);
}