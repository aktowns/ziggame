const std = @import("std");
const builtin = @import("builtin");
const Platform = @import("Platform.zig");
const GraphicsPlatform = @import("GraphicsPlatform.zig");

pub fn Game(comptime State: type) type {
    return struct {
        state: ?State = null,
        platform: ?Platform = null,
        graphics_platform: ?GraphicsPlatform = null,
        setup: *const fn () State,
        loop: *const fn (state: *State) void,

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};

        const allocator: std.mem.Allocator = if (builtin.target.isWasm()) alloc: {
            const wa = std.heap.c_allocator;
            break :alloc wa;
        } else alloc: {
            const alloc = gpa.allocator();
            break :alloc alloc;
        };

        pub fn start(self: *@This()) !void {
            self.platform = try Platform.getCurrentPlatform(allocator);
            self.graphics_platform = try GraphicsPlatform.init(.{ .window_height = 480, .window_width = 640, .window_title = "ZenEng", .platform = &self.platform.? });

            std.log.info("[Main] Using platform: {s}", .{self.platform.?.name});

            if (!builtin.target.isWasm()) {
                while (self.platform.?.window.dispatch() == 0) {
                    try self.graphics_platform.?.main_loop();
                }
            } else {
                std.debug.panic("TODO: re-add wasm support");
                // cincludes.emscripten.emscripten_set_main_loop_arg(animation_frame_cb, @constCast(self), 0, true);
            }

            var state = self.setup();
            while (true) {
                self.loop(&state);
            }
        }

        pub fn shutdown(self: *@This()) void {
            self.graphics_platform.deinit();
            self.platform.deinit();
            gpa.deinit();
        }
    };
}
