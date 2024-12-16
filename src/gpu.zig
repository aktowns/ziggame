const std = @import("std");
const glfw = @import("mach-glfw");
const wgpu = @cImport({
    @cInclude("wgpu/wgpu.h");
});

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn wgpuInit() void {
    glfw.setErrorCallback(errorCallback);

    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    const instance = wgpu.wgpuCreateInstance(null);

    if (instance == null) {
        std.log.err("failed to initialize wgpu: {?s}", .{"?"});
        std.process.exit(1);
    }

    const version = wgpu.wgpuGetVersion();
    std.debug.print("wgpu version: {d}", .{version});
}
