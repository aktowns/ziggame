const SurfaceTexture = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const Texture = @import("Texture.zig");

surfaceTexture: wg.WGPUSurfaceTexture,
texture: Texture,

pub fn init(surfaceTexture: wg.WGPUSurfaceTexture) @This() {
    return .{
        .surfaceTexture = surfaceTexture,
        .texture = Texture.init(surfaceTexture.texture.?),
    };
}

pub fn deinit(self: *const @This()) void {
    self.texture.deinit();
}
