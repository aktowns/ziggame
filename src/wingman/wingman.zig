pub const Window = @import("window/Window.zig");
pub const Input = @import("input/Input.zig");
pub const Signal = @import("event/signal.zig");
pub const log = @import("log/log.zig");

// pub const Wingman = @This();
//
// pub const std = @import("std");
// pub const Window = @import("window/Window.zig");
//
// //lw: linux_wayland,
// window: Window,
//
// pub const window_options = struct {
//     title: []const u8,
//     width: u32,
//     height: u32,
// };
//
// pub fn init(allocator: std.mem.Allocator, options: window_options) @This() {
//     const window = Window.init(allocator, options.title, options.width, options.height);
//
//     return .{ .window = window };
// }
//
// pub fn dispatch(self: *@This()) i32 {
//     _ = self;
//     // return 0;
//     return 0;
//     //    return self.lw.dispatch();
// }
