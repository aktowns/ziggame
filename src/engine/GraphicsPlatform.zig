const GraphicsPlatform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const wg = cincludes.wg;
const glfw = cincludes.glfw;

instance: *wg.WGPUInstanceImpl,
surface: *wg.WGPUSurfaceImpl,
adapter: wg.WGPUAdapter,
device: wg.WGPUDevice,
config: ?*wg.WGPUSurfaceConfiguration,

pub const Error = error{ FailedToCreateInstance, FailedToInitializeGLFW, FailedToGetSurface };

pub const GraphicsPlatformOptions = struct { windowTitle: []const u8, windowWidth: u32, windowHeight: u32, getSurfaceDescriptor: fn (window: *glfw.GLFWwindow) wg.WGPUSurfaceDescriptor };

pub fn init(options: GraphicsPlatformOptions) Error!@This() {
    const instance = wg.wgpuCreateInstance(null) orelse return Error.FailedToCreateInstance;

    if (glfw.glfwInit() != 1) {
        std.log.err("failed to initialize glfw: {?s}", .{"?"});
        return Error.FailedToInitializeGLFW;
    }

    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);

    if (comptime builtin.target.os.tag == .emscripten) {
        std.log.info("webassembly hacks", .{});
        glfw.emscripten_glfw_set_next_window_canvas_selector("#canvas");
    }

    const window = glfw.glfwCreateWindow(options.windowWidth, options.windowHeight, @as([*c]const u8, @ptrCast(options.windowTitle)), null, null).?;

    const surface_descriptor = options.getSurfaceDescriptor(window);

    std.log.info("Got surface descriptor: {?}", .{surface_descriptor});

    const surface = wg.wgpuInstanceCreateSurface(instance, &surface_descriptor) orelse return Error.FailedToGetSurface;

    return .{ .instance = instance, .surface = surface, .adapter = null, .device = null, .config = null };
}
