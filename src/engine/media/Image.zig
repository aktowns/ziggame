const Image = @This();

const std = @import("std");
const zigimg = @import("zigimg");

image: zigimg.Image,

pub fn init(allocator: std.mem.Allocator, name: []const u8) !@This() {
    const path = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(path);

    const image_path = try std.fs.path.join(allocator, &[_][]const u8{ path, "resources", name });
    defer allocator.free(image_path);

    var file = try std.fs.cwd().openFile(image_path, .{});
    defer file.close();

    const image = try zigimg.Image.fromFile(allocator, &file);
    // try image.convert(zigimg.PixelFormat.rgb24);
    return .{ .image = image };
}

pub fn deinit(self: *const @This()) void {
    @constCast(&self.image).deinit();
}
