const Platform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const glfw = cincludes.glfw;
const wg = cincludes.wg;

const SurfaceSource = @import("wgpu/Surface.zig").SurfaceSource;

name: []const u8,
comptime os: std.Target.Os = builtin.os,
allocator: std.mem.Allocator,

pub const Error = error{ PlatformNotFound, FailedToConstructSurface };

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
    return .{ .name = try platformName(), .allocator = allocator };
}

pub fn getSurfaceSource(self: *const @This(), window: *glfw.GLFWwindow) Error!SurfaceSource {
    return switch (self.os.tag) {
        .macos => SurfaceSource{ .MacOS = getMacOSSurface(window) },
        .linux => SurfaceSource{ .Linux = getLinuxSurface(window) },
        .windows => SurfaceSource{ .Windows = getWindowsSurface(window) },
        .emscripten => SurfaceSource{ .Web = getEmscriptenSurface(window) },

        else => Error.PlatformNotFound,
    };
}

fn getMacOSSurface(window: *glfw.GLFWwindow) Error!wg.WGPUSurfaceDescriptorFromMetalLayer {
    std.log.info("Using MacOS Surface", .{});
    const ns_window = glfw.glfwGetCocoaWindow(window);
    const layer = cincludes.glfw.getOSXSurface(ns_window);

    return .{ .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceSourceMetalLayer, .next = null }, .layer = layer };
}

fn getLinuxSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptorFromWaylandSurface {
    const wl_display = glfw.glfwGetWaylandDisplay();
    const wl_surface = glfw.glfwGetWaylandWindow(window);

    return wg.WGPUSurfaceDescriptorFromWaylandSurface{ .display = wl_display, .surface = wl_surface, .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceSourceWaylandSurface } };
}

fn getWindowsSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor {
    const hwnd = glfw.glfwGetWin32Window(window);
    const hinstance = glfw.GetModuleHandle(null);

    return wg.WGPUSurfaceDescriptorFromWindowsHWND{ .hinstance = hinstance, .hwnd = hwnd, .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromWindowsHWND } };
}

fn getEmscriptenSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor {
    _ = window;
    return wg.WGPUSurfaceDescriptorFromCanvasHTMLSelector{ .selector = "#canvas", .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromCanvasHTMLSelector } };
}
