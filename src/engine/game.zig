const std = @import("std");
const builtin = @import("builtin");
const Platform = @import("Platform.zig");
const GraphicsPlatform = @import("GraphicsPlatform.zig");

pub fn Game(comptime State: type) type {

    // var platform = try Platform.getCurrentPlatform(allocator);
    // defer platform.deinit();
    // std.log.info("[Main] Using platform: {s}", .{platform.name});
    // var gfx = try GraphicsPlatform.init(.{ .window_height = 480, .window_width = 640, .window_title = "ZenEng", .platform = &platform });
    // defer gfx.deinit();
    // try gfx.start();

    return struct {
        state: ?State = null,
        setup: *const fn () State,
        loop: *const fn (state: *State) void,

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};

        const allocator: std.mem.Allocator = if (builtin.target.isWasm()) alloc: {
            const wa = std.heap.c_allocator;
            break :alloc wa;
        } else alloc: {
            //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            const alloc = gpa.allocator();
            break :alloc alloc;
        };

        pub fn start(self: *@This()) void {
            var state = self.setup();
            while (true) {
                self.loop(&state);
            }
        }

        pub fn shutdown(self: *@This()) void {
            gpa.deinit();
        }
    };
}
