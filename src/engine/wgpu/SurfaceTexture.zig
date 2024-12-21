const SurfaceTexture = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const TextureView = @import("TextureView.zig");

surfaceTexture: wg.WGPUSurfaceTexture,

pub fn init(surfaceTexture: wg.WGPUSurfaceTexture) @This() {
    return .{ .surfaceTexture = surfaceTexture };
}

pub fn createView(self: *const @This(), descriptor: [*c]const wg.WGPUTextureViewDescriptor) TextureView {
    const view = wg.wgpuTextureCreateView(self.surfaceTexture.texture, descriptor).?;
    return TextureView.init(view);
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuTextureRelease(self.surfaceTexture.texture);
}
