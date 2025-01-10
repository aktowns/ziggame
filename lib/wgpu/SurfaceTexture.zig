const SurfaceTexture = @This();

const std = @import("std");
const wg = @import("cincludes.zig").wg;
const Texture = @import("Texture.zig");

native: wg.WGPUSurfaceTexture,
texture: Texture,

pub fn init(surface_texture: wg.WGPUSurfaceTexture) @This() {
    return .{
        .native = surface_texture,
        .texture = Texture.init(surface_texture.texture.?),
    };
}

pub fn deinit(self: *const @This()) void {
    self.texture.deinit();
}
