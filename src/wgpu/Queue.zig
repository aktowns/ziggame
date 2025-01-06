const Queue = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;

const Image = @import("../media/Image.zig");
const Texture = @import("Texture.zig");
const Buffer = @import("Buffer.zig");

native: *wg.WGPUQueueImpl,

pub fn init(queue: *wg.WGPUQueueImpl) @This() {
    return .{ .native = queue };
}

pub fn submit(self: *const @This(), command_count: usize, commands: [*c]const wg.WGPUCommandBuffer) void {
    wg.wgpuQueueSubmit(self.native, command_count, commands);
}

pub fn writeBuffer(self: *const @This(), buffer: Buffer, buffer_offset: u64, data: []const u8) void {
    wg.wgpuQueueWriteBuffer(self.native, buffer.native, buffer_offset, data.ptr, data.len);
}
