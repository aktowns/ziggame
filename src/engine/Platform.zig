const Platform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const glfw = cincludes.glfw;
const wg = cincludes.wg;

name: []const u8,
os: std.Target.Os,
//surface_descriptor: fn (window: *glfw.GLFWwindow) Error!wg.WGPUSurfaceDescriptor,
allocator: std.mem.Allocator,

pub const Error = error{ PlatformNotFound, FailedToConstructSurface };

const SurfaceSourceOS = enum { MacOS };
const SurfaceSource = union(SurfaceSourceOS) {
    MacOS: *wg.WGPUSurfaceSourceMetalLayer,

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        switch (self) {
            .MacOS => |*surf| allocator.free(surf),
        }
    }
};

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
    return .{ .name = try platformName(), .allocator = allocator, .os = builtin.target.os };

    // return switch (comptime builtin.target.os.tag) {
    //     .windows => .{ .name = "Windows", .allocator = allocator, .os = builtin.target.os },
    //     .linux => .{ .name = "Linux", .allocator = allocator, bi},
    //     .macos => .{ .name = "MacOS", .allocator = allocator, .surface_descriptor = getMacOSSurface },
    //     .emscripten => .{ .name = "Emscripten", .allocator = allocator, .surface_descriptor = getEmscriptenSurface },
    //     else => {
    //         std.log.err("Platform not supported: {?}", builtin.target.os.tag);
    //         Error.PlatformNotFound;
    //     },
    // };
}

inline fn stringView(comptime str: [:0]const u8) wg.WGPUStringView {
    return wg.WGPUStringView{ .data = str, .length = str.len };
}

pub fn getSurface(self: *const @This(), window: *glfw.GLFWwindow) Error!SurfaceSource {
    return switch (comptime builtin.target.os.tag) {
        .macos => self.getMacOSSurface(window),
        else => Error.PlatformNotFound,
    };
}

fn getMacOSSurface(self: *const @This(), window: *glfw.GLFWwindow) Error!SurfaceSource {
    std.log.info("Using MacOS Surface", .{});
    // const objc = @import("objc");

    // const ns_window = glfw.glfwGetCocoaWindow(window);
    // const objc_window = objc.Object.fromId(ns_window);
    // const objc_view = objc_window.getProperty(objc.Object, "contentView");

    // _ = objc_view.msgSend(objc.Object, "setWantsLayer:", .{true});
    // const CAMetalLayer = objc.getClass("CAMetalLayer").?;
    // const layer = CAMetalLayer.msgSend(objc.Object, "layer", .{});
    // _ = objc_view.msgSend(objc.Object, "setLayer:", .{layer});
    const ns_window = glfw.glfwGetCocoaWindow(window);
    const layer = cincludes.glfw.getOSXSurface(ns_window);

    var strct = self.allocator.create(wg.WGPUSurfaceDescriptorFromMetalLayer) catch return Error.FailedToConstructSurface;
    strct.chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceSourceMetalLayer, .next = null };
    strct.layer = layer;

    return SurfaceSource{ .MacOS = strct };
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
