const Buffer = @This();

const std = @import("std");

const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

native: *wg.WGPUBufferImpl,

pub fn init(buffer: *wg.WGPUBufferImpl) @This() {
    return .{ .native = buffer };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBufferRelease(self.native);
}
