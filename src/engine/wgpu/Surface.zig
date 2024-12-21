const Surface = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const Instance = @import("Instance.zig");
const SurfaceTexture = @import("SurfaceTexture.zig");
const Error = @import("error.zig").Error;

instance: *const Instance,
surface: *wg.WGPUSurfaceImpl,

const SurfaceSourceOS = enum { MacOS, Linux, Windows, Web };
pub const SurfaceSource = union(SurfaceSourceOS) { MacOS: wg.WGPUSurfaceSourceMetalLayer, Linux: wg.WGPUSurfaceSourceWaylandSurface, Windows: wg.WGPUSurfaceSourceWindowsHWND, Web: wg.WGPUSurfaceSourceCanvasHTMLSelector_Emscripten };

pub fn init(surface: *wg.WGPUSurfaceImpl, instance: *const Instance) @This() {
    return .{ .surface = surface, .instance = instance };
}

pub fn capabilities(self: *const @This()) wg.WGPUSurfaceCapabilities {
    var surface_capabilities: wg.WGPUSurfaceCapabilities = .{};
    const res = wg.wgpuSurfaceGetCapabilities(self.surface, self.instance.adapter.?.adapter, &surface_capabilities);

    std.debug.assert(res == wg.WGPUStatus_Success);

    return surface_capabilities;
}

pub fn configure(self: *const @This(), config: *wg.WGPUSurfaceConfiguration) void {
    wg.wgpuSurfaceConfigure(self.surface, config);
}

pub fn present(self: *const @This()) void {
    wg.wgpuSurfacePresent(self.surface);
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
    var surfaceTexture: wg.WGPUSurfaceTexture = .{};
    wg.wgpuSurfaceGetCurrentTexture(self.surface, &surfaceTexture);

    return switch (surfaceTexture.status) {
        wg.WGPUSurfaceGetCurrentTextureStatus_Success => SurfaceTextureResult{
            .Success = SurfaceTexture.init(surfaceTexture),
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_Timeout => {
            if (surfaceTexture.texture != null) wg.wgpuTextureRelease(surfaceTexture.texture);

            return SurfaceTextureResult{ .Timeout = {} };
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_Outdated => {
            if (surfaceTexture.texture != null) wg.wgpuTextureRelease(surfaceTexture.texture);

            return SurfaceTextureResult{ .Outdated = {} };
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_Lost => {
            if (surfaceTexture.texture != null) wg.wgpuTextureRelease(surfaceTexture.texture);

            return SurfaceTextureResult{ .Lost = {} };
        },
        wg.WGPUSurfaceGetCurrentTextureStatus_OutOfMemory => SurfaceTextureResult{ .OutOfMemory = {} },
        wg.WGPUSurfaceGetCurrentTextureStatus_DeviceLost => SurfaceTextureResult{ .DeviceLost = {} },
        wg.WGPUSurfaceGetCurrentTextureStatus_Force32 => SurfaceTextureResult{ .Force32 = {} },
        else => {
            std.log.err("FATAL UNHANDLED get_current_texture status={d}", .{surfaceTexture.status});
            return Error.UnknownSurfaceTextureStatus;
        },
    };
}
