const std = @import("std");
const builtin = @import("builtin");
pub const ResourceType = enum {
    Audio,
    Maps,
    Tilemaps,
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
        .name = "/Free_Test_Data_500KB_OGG.ogg",
        .resource = ResourceType.Audio,
        .embedded = if (builtin.target.isWasm()) @embedFile("Audio/Free_Test_Data_500KB_OGG.ogg") else null,
        .path = "/home/ash/CLionProjects/zen/resources/Audio/Free_Test_Data_500KB_OGG.ogg",
    },
    .{
        .name = "/test/test.tmx",
        .resource = ResourceType.Maps,
        .embedded = if (builtin.target.isWasm()) @embedFile("Maps/test/test.tmx") else null,
        .path = "/home/ash/CLionProjects/zen/resources/Maps/test/test.tmx",
    },
    .{
        .name = "/test/test.tsx",
        .resource = ResourceType.Maps,
        .embedded = if (builtin.target.isWasm()) @embedFile("Maps/test/test.tsx") else null,
        .path = "/home/ash/CLionProjects/zen/resources/Maps/test/test.tsx",
    },
    .{
        .name = "/tilemap.png",
        .resource = ResourceType.Tilemaps,
        .embedded = if (builtin.target.isWasm()) @embedFile("Tilemaps/tilemap.png") else null,
        .path = "/home/ash/CLionProjects/zen/resources/Tilemaps/tilemap.png",
    },
    .{
        .name = "/shader.wgsl",
        .resource = ResourceType.Shaders,
        .embedded = if (builtin.target.isWasm()) @embedFile("Shaders/shader.wgsl") else null,
        .path = "/home/ash/CLionProjects/zen/resources/Shaders/shader.wgsl",
    },
};
