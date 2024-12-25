const std = @import("std");
const builtin = @import("builtin");
pub const ResourceType = enum {
    Maps,
    Textures,
    Tilemaps,
    Audio,
    Shaders,
};
pub const Resource = struct {
    name: []const u8,
    resource: ResourceType,
    embedded: ?[]const u8,
    path: []const u8,
};
pub const resources: []const Resource = &.{
    .{
        .name = "/test/test.tmx",
        .resource = ResourceType.Maps,
        .embedded = if (builtin.target.isWasm()) @embedFile("Maps/test/test.tmx") else null,
        .path = "/Users/ash/CLionProjects/zigtest/resources/Maps/test/test.tmx",
    },
    .{
        .name = "/test/test.tsx",
        .resource = ResourceType.Maps,
        .embedded = if (builtin.target.isWasm()) @embedFile("Maps/test/test.tsx") else null,
        .path = "/Users/ash/CLionProjects/zigtest/resources/Maps/test/test.tsx",
    },
    .{
        .name = "/tilemap.png",
        .resource = ResourceType.Tilemaps,
        .embedded = if (builtin.target.isWasm()) @embedFile("Tilemaps/tilemap.png") else null,
        .path = "/Users/ash/CLionProjects/zigtest/resources/Tilemaps/tilemap.png",
    },
    .{
        .name = "/Free_Test_Data_500KB_OGG.ogg",
        .resource = ResourceType.Audio,
        .embedded = if (builtin.target.isWasm()) @embedFile("Audio/Free_Test_Data_500KB_OGG.ogg") else null,
        .path = "/Users/ash/CLionProjects/zigtest/resources/Audio/Free_Test_Data_500KB_OGG.ogg",
    },
    .{
        .name = "/shader.wgsl",
        .resource = ResourceType.Shaders,
        .embedded = if (builtin.target.isWasm()) @embedFile("Shaders/shader.wgsl") else null,
        .path = "/Users/ash/CLionProjects/zigtest/resources/Shaders/shader.wgsl",
    },
};
