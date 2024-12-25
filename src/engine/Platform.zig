const Platform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const glfw = cincludes.glfw;
const wg = cincludes.wg;
const Filesystem = @import("filesystem/Filesystem.zig");
const Audio = @import("media/Audio.zig");

name: []const u8,
comptime os: std.Target.Os = builtin.os,
allocator: std.mem.Allocator,
filesystem: Filesystem,

pub const tracing: bool = true;

pub inline fn sentinel(self: *const @This()) ?*u8 {
    if (comptime tracing) {
        const sentinelPtr = self.allocator.create(u8) catch unreachable;
        sentinelPtr.* = 0xAA;
        return sentinelPtr;
    } else return null;
}

pub const Error = error{ PlatformNotFound, FailedToConstructSurface, FailedToInitializeFilesystem };

fn platformName() Error![]const u8 {
    return switch (comptime builtin.target.os.tag) {
        .windows => "Windows",
        .linux => "Linux",
        .macos => "MacOS",
        .emscripten => "Web",
        else => {
            std.log.err("Platform not supported: {?}", builtin.target.os.tag);
            Error.PlatformNotFound;
        },
    };
}

pub fn getCurrentPlatform(allocator: std.mem.Allocator) Error!Platform {
    const fs = Filesystem.init(allocator) catch |err| {
        std.log.err("[Platform] Filesystem initialization failed: {?}", .{err});
        return Error.FailedToInitializeFilesystem;
    };
    return .{
        .name = try platformName(),
        .allocator = allocator,
        .filesystem = fs,
    };
}

pub fn deinit(self: *@This()) void {
    self.filesystem.deinit();
}

pub const NativeSurface: type = switch (builtin.target.os.tag) {
    .windows => wg.WGPUSurfaceDescriptorFromWindowsHWND,
    .linux => wg.WGPUSurfaceDescriptorFromWaylandSurface,
    .macos => wg.WGPUSurfaceDescriptorFromMetalLayer,
    .emscripten => wg.WGPUSurfaceDescriptorFromCanvasHTMLSelector,
    else => @compileError("Unsupported Platform"),
};

pub fn getSurfaceSource(self: *const @This(), window: *glfw.GLFWwindow) NativeSurface {
    return switch (self.os.tag) {
        .macos => getMacOSSurface(window),
        .linux => getLinuxSurface(window),
        .windows => getWindowsSurface(window),
        .emscripten => getEmscriptenSurface(window),

        else => unreachable,
    };
}

fn getMacOSSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptorFromMetalLayer {
    const ns_window = glfw.glfwGetCocoaWindow(window);
    const layer = cincludes.glfw.getOSXSurface(ns_window);

    return .{
        .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceSourceMetalLayer },
        .layer = layer,
    };
}

fn getLinuxSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptorFromWaylandSurface {
    const wl_display = glfw.glfwGetWaylandDisplay();
    const wl_surface = glfw.glfwGetWaylandWindow(window);

    return wg.WGPUSurfaceDescriptorFromWaylandSurface{
        .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceSourceWaylandSurface },
        .display = wl_display,
        .surface = wl_surface,
    };
}

fn getWindowsSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptorFromWindowsHWND {
    const hwnd = glfw.glfwGetWin32Window(window);
    const hinstance = glfw.GetModuleHandle(null);

    return wg.WGPUSurfaceDescriptorFromWindowsHWND{
        .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromWindowsHWND },
        .hinstance = hinstance,
        .hwnd = hwnd,
    };
}

fn getEmscriptenSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptorFromCanvasHTMLSelector {
    _ = window;
    return wg.WGPUSurfaceDescriptorFromCanvasHTMLSelector{
        .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromCanvasHTMLSelector },
        .selector = "#canvas",
    };
}

pub fn sleep(ms: u64) void {
    if (builtin.target.isWasm()) {
        cincludes.emscripten.emscripten_sleep(@intCast(ms));
    } else {
        std.Thread.sleep(std.time.ns_per_ms * ms);
    }
}
