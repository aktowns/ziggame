const Tileset = @This();

const std = @import("std");
const xml = @import("xml");

allocator: std.mem.Allocator,
version: []const u8,
tiledVersion: []const u8,
name: []const u8,
tileWidth: u32,
tileHeight: u32,
spacing: u32,
tileCount: u32,
columns: u32,
images: []*TilesetImage,

pub const ValidTilesetAttributes = enum { version, tiledversion, name, tilewidth, tileheight, spacing, tilecount, columns };

pub const Error = error{ FailedToOpenTileset, InvalidStateTransition };

const ProcessingState = enum { start, tileset, image };

pub const TilesetImage = struct {
    source: []const u8,
    width: u32,
    height: u32,
};

pub const ValidTilesetImageAttributes = enum { source, width, height };

fn transition(state: ProcessingState, nextTag: []const u8) Error!ProcessingState {
    const next = std.meta.stringToEnum(ProcessingState, nextTag).?;
    switch (state) {
        .start => {
            if (next == ProcessingState.tileset) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
        .tileset => {
            if (next == ProcessingState.image) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
        .image => {
            if (next == ProcessingState.image) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
    }
}

pub fn init(allocator: std.mem.Allocator, name: []const u8) !*const @This() {
    const path = std.fs.cwd().realpathAlloc(allocator, ".") catch return Error.FailedToOpenTileset;
    defer allocator.free(path);

    const shader_path = std.fs.path.join(allocator, &[_][]const u8{ path, "resources", "maps", name }) catch return Error.FailedToOpenTileset;
    defer allocator.free(shader_path);

    std.log.debug("[Tileset] Opening tileset at {s}", .{shader_path});

    const file = try std.fs.cwd().openFile(shader_path, .{});
    defer file.close();

    var doc = xml.streamingDocument(allocator, file.reader());
    defer doc.deinit();
    var reader = doc.reader(allocator, .{});
    defer reader.deinit();

    var state = ProcessingState.start;
    var open: bool = true;

    var tileset: ?*Tileset = null;
    var image: ?*TilesetImage = null;

    var images = std.ArrayList(*TilesetImage).init(allocator);

    while (true) {
        const node = try reader.read();

        switch (node) {
            .eof => break,
            .cdata => break,
            .character_reference => break,
            .comment => continue,
            .element_end => {
                const element_name = reader.elementNameNs();
                const tag = std.meta.stringToEnum(ProcessingState, element_name.local).?;
                open = false;

                switch (tag) {
                    .image => {
                        try images.append(image.?);
                        image = null;
                    },
                    .tileset => {
                        tileset.?.images = try images.toOwnedSlice();
                    },
                    .start => {},
                }
            },
            .element_start => {
                const element_name = reader.elementNameNs();

                state = try transition(state, element_name.local);
                open = true;

                std.log.info("[Tileset] element_start: {?}", .{state});

                switch (state) {
                    .tileset => {
                        tileset = try allocator.create(Tileset);
                        tileset.?.allocator = allocator;

                        for (0..reader.reader.attributeCount()) |i| {
                            const attribute_name = reader.attributeNameNs(i);
                            const attribute_value = try reader.attributeValue(i);
                            const case = std.meta.stringToEnum(ValidTilesetAttributes, attribute_name.local).?;

                            const t = tileset.?;

                            switch (case) {
                                .version => t.version = try allocator.dupe(u8, attribute_value),
                                .tiledversion => t.tiledVersion = try allocator.dupe(u8, attribute_value),
                                .name => t.name = try allocator.dupe(u8, attribute_value),
                                .tilewidth => t.tileWidth = try std.fmt.parseInt(u32, attribute_value, 10),
                                .tileheight => t.tileHeight = try std.fmt.parseInt(u32, attribute_value, 10),
                                .spacing => t.spacing = try std.fmt.parseInt(u32, attribute_value, 10),
                                .tilecount => t.tileCount = try std.fmt.parseInt(u32, attribute_value, 10),
                                .columns => t.columns = try std.fmt.parseInt(u32, attribute_value, 10),
                            }
                        }
                    },
                    .image => {
                        image = try allocator.create(TilesetImage);

                        for (0..reader.reader.attributeCount()) |i| {
                            const attribute_name = reader.attributeNameNs(i);
                            const attribute_value = try reader.attributeValue(i);
                            const case = std.meta.stringToEnum(ValidTilesetImageAttributes, attribute_name.local).?;

                            const ti = image.?;

                            switch (case) {
                                .source => ti.source = try allocator.dupe(u8, attribute_value),
                                .width => ti.width = try std.fmt.parseInt(u32, attribute_value, 10),
                                .height => ti.height = try std.fmt.parseInt(u32, attribute_value, 10),
                            }
                        }
                    },
                    .start => {},
                }
            },
            .entity_reference => continue,
            .pi => continue,
            .text => continue,
            .xml_declaration => continue,
        }
    }

    return tileset.?;
}

pub fn deinit(self: *const @This()) void {
    self.allocator.free(self.version);
    self.allocator.free(self.tiledVersion);
    self.allocator.free(self.name);

    for (self.images) |image| {
        self.allocator.free(image.source);
        self.allocator.destroy(image);
    }
    self.allocator.free(self.images);

    self.allocator.destroy(self);
}
