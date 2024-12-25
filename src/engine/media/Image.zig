const Image = @This();

const std = @import("std");
const Platform = @import("../Platform.zig");
const ResourceType = @import("../filesystem/Filesystem.zig").ResourceType;
const cinclude = @import("../cincludes.zig");
const log = @import("../log.zig");

image: ImageInternal,

pub const ImageInternal = struct {
    data: [*]u8,
    height: u32,
    width: u32,
    size: usize,
};

pub fn init(platform: *const Platform, name: []const u8) !@This() {
    var w: c_int = 0;
    var h: c_int = 0;
    var c: c_int = 0;

    const file = try platform.filesystem.readFile(name, ResourceType.Tilemaps);

    cinclude.stbImage.stbi_set_flip_vertically_on_load(0);
    const image = @intFromPtr(cinclude.stbImage.stbi_load_from_memory(@as([*c]const u8, &file[0]), @intCast(file.len), &w, &h, &c, cinclude.stbImage.STBI_rgb_alpha));
    std.debug.assert(image != 0);

    const fail = cinclude.stbImage.stbi_failure_reason();
    if (fail != null) {
        log.err(@src(), "stbi={s}", .{fail});
    }

    log.debug(@src(), "Loaded with dimensions {d}x{d} channels {d}", .{ w, h, c });

    return .{ .image = ImageInternal{
        .data = @ptrFromInt(image),
        .width = @intCast(w),
        .height = @intCast(h),
        .size = @intCast(4 * (w * h)),
    } };
}

pub fn deinit(self: *const @This()) void {
    _ = self;
    // @constCast(&self.image).deinit();
}
