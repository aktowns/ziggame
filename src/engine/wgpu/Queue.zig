const Queue = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

const Image = @import("../media/Image.zig");
const Texture = @import("Texture.zig");
const Buffer = @import("Buffer.zig");

queue: *wg.WGPUQueueImpl,

pub fn init(queue: *wg.WGPUQueueImpl) @This() {
    return .{ .queue = queue };
}

pub fn submit(self: *const @This(), commandCount: usize, commands: [*c]const wg.WGPUCommandBuffer) void {
    wg.wgpuQueueSubmit(self.queue, commandCount, commands);
}

pub fn writeImageToTexture(self: *const @This(), image: *const Image, texture: *const Texture) void {
    wg.wgpuQueueWriteTexture(
        self.queue,
        &wg.WGPUImageCopyTexture{
            .texture = texture.texture,
            .mipLevel = 0,
            .aspect = wg.WGPUTextureAspect_All,
            .origin = wg.WGPUOrigin3D{ .x = 0, .y = 0, .z = 0 },
        },
        @ptrCast(image.image.rawBytes()),
        image.image.imageByteSize(),
        &wg.WGPUTextureDataLayout{
            .offset = 0,
            .bytesPerRow = @intCast(image.image.rowByteSize()),
            .rowsPerImage = @intCast(image.image.height),
        },
        &wg.WGPUExtent3D{ .width = @intCast(image.image.width), .height = @intCast(image.image.height), .depthOrArrayLayers = 1 },
    );
}

pub fn writeBuffer(self: *const @This(), buffer: Buffer, bufferOffset: u64, data: []const u8) void {
    wg.wgpuQueueWriteBuffer(self.queue, buffer.buffer, bufferOffset, data.ptr, data.len);
}