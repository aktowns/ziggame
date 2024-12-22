const Texture = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const TextureView = @import("TextureView.zig");

texture: *wg.WGPUTextureImpl,

pub fn init(texture: *wg.WGPUTextureImpl) @This() {
    return .{ .texture = texture };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuTextureRelease(self.texture);
}

pub fn createView(self: *const @This(), descriptor: [*c]const wg.WGPUTextureViewDescriptor) TextureView {
    const view = wg.wgpuTextureCreateView(self.texture, descriptor).?;
    return TextureView.init(view);
}
