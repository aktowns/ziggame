const std = @import("std");
const builtin = @import("builtin");
const wingman = @import("wingman");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    switch (builtin.target.os.tag) {
        .linux => {
            const wm = wingman.Window.init(allocator, .{ .title = "testing", .height = 640, .width = 480 });
            const input = wingman.Input.initWayland(allocator, &wm.underlying.input);
            _ = input;
        },
        .macos => {
            var wm = wingman.Window.init(allocator, .{ .title = "testing", .height = 640, .width = 480 });
            while (wm.dispatch() == 0) {
                std.Thread.sleep(std.time.ns_per_ms * 10);
            }
        },
        else => unreachable,
    }

    std.Thread.sleep(std.time.ns_per_s * 10);
}
