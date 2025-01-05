const Texture = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;
const u = @import("../util.zig");
const TextureView = @import("TextureView.zig");

native: *wg.WGPUTextureImpl,

pub fn init(texture: *wg.WGPUTextureImpl) @This() {
    return .{ .native = texture };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuTextureRelease(self.native);
}

pub fn createView(self: *const @This(), descriptor: [*c]const wg.WGPUTextureViewDescriptor) TextureView {
    const view = wg.wgpuTextureCreateView(self.native, descriptor).?;
    return TextureView.init(view);
}
