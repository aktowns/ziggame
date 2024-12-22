const TextureView = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;

textureView: *wg.WGPUTextureViewImpl,

pub fn init(textureView: *wg.WGPUTextureViewImpl) @This() {
    return .{ .textureView = textureView };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuTextureViewRelease(self.textureView);
}
