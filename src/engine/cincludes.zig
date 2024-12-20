const std = @import("std");
const builtin = @import("builtin");

pub const wg = @cImport({
    @cInclude("webgpu/webgpu.h");
});
pub const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
    if (!builtin.target.isWasm()) {
        @cDefine(glfwDefine(), "1");
        @cInclude("GLFW/glfw3native.h");
        if (builtin.os.tag == .macos) {
            @cInclude("osxextra.h");
        }
    } else {
        @cInclude("contrib.glfw3/GLFW/emscripten_glfw3.h");
    }
});

fn glfwDefine() []const u8 {
    return switch (comptime builtin.os.tag) {
        .macos => "GLFW_EXPOSE_NATIVE_COCOA",
        .linux => "GLFW_EXPOSE_NATIVE_WAYLAND",
        .windows => "GLFW_EXPOSE_NATIVE_WIN32",
        .emscripten => "GLFW_NATIVE_INCLUDE_NONE",
        else => std.debug.panic("Unhandled operating system: {?}", .{builtin.os.tag}),
    };
}
