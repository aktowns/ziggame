const TexutreView = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const TextureView = @import("TextureView.zig");

textureView: *wg.WGPUTextureViewImpl,

pub fn init(textureView: *wg.WGPUTextureViewImpl) @This() {
    return .{ .textureView = textureView };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuTextureViewRelease(self.textureView);
}
