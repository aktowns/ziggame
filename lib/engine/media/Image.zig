const Image = @This();

const std = @import("std");
const Platform = @import("../Platform.zig");
const ResourceType = @import("../filesystem/Filesystem.zig").ResourceType;
const cinclude = @import("../cincludes.zig");
const log = @import("wingman").log;
const w = @import("wgpu");
const wg = w.wg;
const Texture = w.Texture;
const Device = w.Device;
const Queue = w.Queue;
const string_view = w.string_view;

image: ImageInternal,

pub const ImageInternal = struct {
    data: [*]u8,
    height: u32,
    width: u32,
    size: usize,
};

pub fn init(platform: *const Platform, name: []const u8) !@This() {
    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;

    const file = try platform.filesystem.readFile(name, ResourceType.Tilemaps);

    cinclude.stbImage.stbi_set_flip_vertically_on_load(0);
    const image = @intFromPtr(cinclude.stbImage.stbi_load_from_memory(@as([*c]const u8, &file[0]), @intCast(file.len), &width, &height, &channels, cinclude.stbImage.STBI_rgb_alpha));
    std.debug.assert(image != 0);

    const fail = cinclude.stbImage.stbi_failure_reason();
    if (fail != null) {
        log.err(@src(), "stbi={s}", .{fail});
    }

    log.debug(@src(), "Loaded with dimensions {d}x{d} channels {d}", .{ width, height, channels });

    return .{ .image = ImageInternal{
        .data = @ptrFromInt(image),
        .width = @intCast(width),
        .height = @intCast(height),
        .size = @intCast(4 * (width * height)),
    } };
}

pub fn deinit(self: *const @This()) void {
    _ = self;
    // @constCast(&self.image).deinit();
}

pub fn createTexture(self: *const @This(), device: *const Device) Texture {
    return device.createTexture(&wg.WGPUTextureDescriptor{
        .label = string_view.init("image"),
        .format = wg.WGPUTextureFormat_RGBA8Unorm,
        .size = wg.WGPUExtent3D{
            .height = @intCast(self.image.height),
            .width = @intCast(self.image.width),
            .depthOrArrayLayers = 1,
        },
        .mipLevelCount = 1,
        .sampleCount = 1,
        .dimension = wg.WGPUTextureDimension_2D,
        .usage = wg.WGPUTextureUsage_TextureBinding | wg.WGPUTextureUsage_CopyDst | wg.WGPUTextureUsage_RenderAttachment,
    });
}

pub fn writeToTexture(self: *const @This(), queue: *const Queue, texture: *const Texture) void {
    wg.wgpuQueueWriteTexture(
        queue.native,
        &wg.WGPUImageCopyTexture{
            .texture = texture.native,
            .mipLevel = 0,
            .aspect = wg.WGPUTextureAspect_All,
            .origin = wg.WGPUOrigin3D{ .x = 0, .y = 0, .z = 0 },
        },
        @ptrCast(self.image.data),
        //@ptrCast(image.image.rawBytes()),
        self.image.size,
        //image.image.imageByteSize(),
        &wg.WGPUTextureDataLayout{
            .offset = 0,
            .bytesPerRow = 4 * self.image.width, // @intCast(image.image.rowByteSize()),
            .rowsPerImage = @intCast(self.image.height),
        },
        &wg.WGPUExtent3D{ .width = @intCast(self.image.width), .height = @intCast(self.image.height), .depthOrArrayLayers = 1 },
    );
}
