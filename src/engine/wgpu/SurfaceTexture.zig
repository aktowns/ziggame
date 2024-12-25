const SurfaceTexture = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
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
