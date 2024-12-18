const Platform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const glfw = cincludes.glfw;
const wg = cincludes.wg;

name: []const u8,
surface_descriptor: fn (window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor,

pub const Error = error{PlatformNotFound};

pub fn getCurrentPlatform() Error!Platform {
    return switch (comptime builtin.target.os.tag) {
        .windows => .{ .name = "Windows", .surface_descriptor = getWindowsSurface },
        .linux => .{ .name = "Linux", .surface_descriptor = getLinuxSurface },
        .macos => .{ .name = "MacOS", .surface_descriptor = getMacOSSurface },
        .emscripten => .{ .name = "Emscripten", .surface_descriptor = getEmscriptenSurface },
        else => {
            std.log.err("Platform not supported: {?}", builtin.target.os.tag);
            Error.PlatformNotFound;
        },
    };
}

fn getMacOSSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor {
    std.log.info("Using MacOS Surface", .{});
    const objc = @import("objc");

    const ns_window = glfw.glfwGetCocoaWindow(window);
    const objc_window = objc.Object.fromId(ns_window);

    const objc_window_descr = objc_window
        .msgSend(objc.Object, "description", .{})
        .msgSend([*c]const u8, "UTF8String", .{});
    std.log.debug("objc_window: {s}", .{objc_window_descr});

    const objc_view = objc_window.getProperty(objc.Object, "contentView");
    const objc_view_descr = objc_view
        .msgSend(objc.Object, "description", .{})
        .msgSend([*c]const u8, "UTF8String", .{});
    std.log.debug("objc_view: {s}", .{objc_view_descr});

    _ = objc_view.msgSend(objc.Object, "setWantsLayer:", .{true});
    const CAMetalLayer = objc.getClass("CAMetalLayer").?;
    const layer = CAMetalLayer.msgSend(objc.Object, "layer", .{});
    _ = objc_view.msgSend(objc.Object, "setLayer:", .{layer});

    const chain: *wg.WGPUChainedStruct = @constCast(@ptrCast(&wg.WGPUSurfaceDescriptorFromMetalLayer{ .layer = layer.value, .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromMetalLayer } }));

    return wg.WGPUSurfaceDescriptor{ .nextInChain = chain };
}

fn getLinuxSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor {
    const wl_display = glfw.glfwGetWaylandDisplay();
    const wl_surface = glfw.glfwGetWaylandWindow(window);

    const chain: *wg.WGPUChainedStruct = @constCast(@ptrCast(&wg.WGPUSurfaceDescriptorFromWaylandSurface{ .display = wl_display, .surface = wl_surface, .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromWaylandSurface } }));

    return wg.WGPUSurfaceDescriptor{ .nextInChain = chain, .label = "LinuxSurface" };
}

fn getWindowsSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor {
    const hwnd = glfw.glfwGetWin32Window(window);
    const hinstance = glfw.GetModuleHandle(null);

    const chain: *wg.WGPUChainedStruct = @constCast(@ptrCast(&wg.WGPUSurfaceDescriptorFromWindowsHWND{ .hinstance = hinstance, .hwnd = hwnd, .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromWindowsHWND } }));
    return wg.WGPUSurfaceDescriptor{ .nextInChain = chain, .label = "WindowsSurface" };
}

fn getEmscriptenSurface(window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor {
    _ = window;
    const chain: *wg.WGPUChainedStruct = @constCast(@ptrCast(&wg.WGPUSurfaceDescriptorFromCanvasHTMLSelector{ .selector = "#canvas", .chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceDescriptorFromCanvasHTMLSelector } }));

    return wg.WGPUSurfaceDescriptor{ .nextInChain = chain, .label = "WebSurface" };
}
