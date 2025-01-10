const TextureView = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;

native: *wg.WGPUTextureViewImpl,

pub fn init(texture_view: *wg.WGPUTextureViewImpl) @This() {
    return .{ .native = texture_view };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuTextureViewRelease(self.native);
}
