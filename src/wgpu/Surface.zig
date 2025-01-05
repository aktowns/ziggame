const Surface = @This();

const std = @import("std");
const builtin = @import("builtin");
const wg = @import("cincludes.zig").wg;
const Instance = @import("Instance.zig");
const SurfaceTexture = @import("SurfaceTexture.zig");
const Error = @import("error.zig").Error;

native: *wg.WGPUSurfaceImpl,
instance: *const Instance,

pub fn init(surface: *wg.WGPUSurfaceImpl, instance: *const Instance) @This() {
    return .{ .native = surface, .instance = instance };
}

pub fn capabilities(self: *const @This()) wg.WGPUSurfaceCapabilities {
    var surface_capabilities: wg.WGPUSurfaceCapabilities = .{};
    // Is void on emscripten headers
    if (builtin.target.isWasm()) {
        wg.wgpuSurfaceGetCapabilities(self.native, self.instance.adapter.?.native, &surface_capabilities);
    } else {
        const res = wg.wgpuSurfaceGetCapabilities(self.native, self.instance.adapter.?.native, &surface_capabilities);

        std.debug.assert(res == wg.WGPUStatus_Success);
    }

    return surface_capabilities;
}

pub fn configure(self: *const @This(), config: *wg.WGPUSurfaceConfiguration) void {
    wg.wgpuSurfaceConfigure(self.native, config);
}

pub fn present(self: *const @This()) void {
    wg.wgpuSurfacePresent(self.native);
}

const SurfaceTextureResultTag = enum { Success, Timeout, Outdated, Lost, OutOfMemory, DeviceLost, Force32 };
const SurfaceTextureResult = union(SurfaceTextureResultTag) {
    Success: SurfaceTexture,
    Timeout,
    Outdated,
    Lost,
    OutOfMemory,
    DeviceLost,
    Force32,
};

pub fn getSurfaceTexture(self: *const @This()) Error!SurfaceTextureResult {
    var surface_texture: wg.WGPUSurfaceTexture = .{};
    wg.wgpuSurfaceGetCurrentTexture(self.native, &surface_texture);

    return switch (surface_texture.status) {
        wg.WGPUSurfaceGetCurrentTextureStatus_Success => SurfaceTextureResult{
            .Success = SurfaceTexture.init(surface_texture),
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_Timeout => {
            if (surface_texture.texture != null) wg.wgpuTextureRelease(surface_texture.texture);

            return SurfaceTextureResult{ .Timeout = {} };
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_Outdated => {
            if (surface_texture.texture != null) wg.wgpuTextureRelease(surface_texture.texture);

            return SurfaceTextureResult{ .Outdated = {} };
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_Lost => {
            if (surface_texture.texture != null) wg.wgpuTextureRelease(surface_texture.texture);

            return SurfaceTextureResult{ .Lost = {} };
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_OutOfMemory => SurfaceTextureResult{ .OutOfMemory = {} },
        wg.WGPUSurfaceGetCurrentTextureStatus_DeviceLost => SurfaceTextureResult{ .DeviceLost = {} },
        wg.WGPUSurfaceGetCurrentTextureStatus_Force32 => SurfaceTextureResult{ .Force32 = {} },
        else => {
            std.log.err("FATAL UNHANDLED get_current_texture status={d}", .{surface_texture.status});
            return Error.UnknownSurfaceTextureStatus;
        },
    };
}
