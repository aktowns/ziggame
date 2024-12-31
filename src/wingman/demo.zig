const std = @import("std");
const wingman = @import("wingman");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const wm = wingman.Window.init(allocator, .{ .title = "testing", .height = 640, .width = 480 });
    const input = wingman.Input.initWayland(allocator, &wm.underlying.input);
    _ = input;

    std.Thread.sleep(std.time.ns_per_s * 10);
}
