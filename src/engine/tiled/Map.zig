const Map = @This();

const std = @import("std");
const xml = @import("xml");
const Tileset = @import("Tileset.zig");

pub const Orientation = enum { orthogonal, isometric, staggered, hexagonal };
pub const RenderOrder = enum { rightDown, rightUp, leftDown, leftUp };

allocator: std.mem.Allocator,
version: []const u8,
tiledVersion: []const u8,
orientation: Orientation,
renderOrder: RenderOrder,
width: u32,
height: u32,
tileWidth: u32,
tileHeight: u32,
infinite: bool,
nextLayerId: u32,
nextObjectId: u32,
tilesets: []*MapTileset,
layers: []*Layer,

pub const ValidMapAttributes = enum { version, tiledversion, orientation, renderorder, width, height, tilewidth, tileheight, infinite, nextlayerid, nextobjectid };

fn renderOrderFromString(str: []const u8) ?RenderOrder {
    if (std.mem.eql(u8, str, "right-down")) {
        return RenderOrder.rightDown;
    } else if (std.mem.eql(u8, str, "right-up")) {
        return RenderOrder.rightUp;
    } else if (std.mem.eql(u8, str, "left-down")) {
        return RenderOrder.leftDown;
    } else if (std.mem.eql(u8, str, "left-up")) {
        return RenderOrder.leftUp;
    } else {
        return null;
    }
}

pub const Error = error{ FailedToOpenMap, InvalidStateTransition };

pub const MapTileset = struct {
    firstGid: u32,
    source: []const u8,
    tileset: *const Tileset,
};
pub const ValidTileSetAttributes = enum { firstgid, source };

pub const Layer = struct {
    id: u32,
    name: []const u8,
    width: u32,
    height: u32,
    data: [][]u8,
};
pub const ValidLayerAttributes = enum { id, name, width, height };

const ProcessingState = enum { start, map, tileset, layer, data };

fn transition(state: ProcessingState, nextTag: []const u8) Error!ProcessingState {
    const next = std.meta.stringToEnum(ProcessingState, nextTag).?;
    switch (state) {
        .start => {
            if (next == ProcessingState.map) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
        .map => {
            if (next == ProcessingState.tileset or next == ProcessingState.layer) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
        .tileset => {
            if (next == ProcessingState.layer) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
        .layer => {
            if (next == ProcessingState.data) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
        .data => {
            if (next == ProcessingState.layer) {
                return next;
            } else {
                return Error.InvalidStateTransition;
            }
        },
    }
}

pub fn init(allocator: std.mem.Allocator, name: []const u8) !*const @This() {
    const path = std.fs.cwd().realpathAlloc(allocator, ".") catch return Error.FailedToOpenMap;
    defer allocator.free(path);

    const shader_path = std.fs.path.join(allocator, &[_][]const u8{ path, "resources", "maps", name }) catch return Error.FailedToOpenMap;
    defer allocator.free(shader_path);

    std.log.debug("[Map] Opening map at {s}", .{shader_path});

    const file = try std.fs.cwd().openFile(shader_path, .{});
    defer file.close();

    var doc = xml.streamingDocument(allocator, file.reader());
    defer doc.deinit();
    var reader = doc.reader(allocator, .{});
    defer reader.deinit();

    var state = ProcessingState.start;
    var open: bool = true;

    var map: ?*Map = null;
    var layer: ?*Layer = null;
    var tileset: ?*MapTileset = null;

    var layers = std.ArrayList(*Layer).init(allocator);
    var tilesets = std.ArrayList(*MapTileset).init(allocator);

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
                    .layer => {
                        try layers.append(layer.?);
                        layer = null;
                    },
                    .map => {
                        const m = map.?;
                        m.layers = try layers.toOwnedSlice();
                        m.tilesets = try tilesets.toOwnedSlice();
                    },
                    .tileset => {
                        try tilesets.append(tileset.?);
                        tileset = null;
                    },
                    .data => {},
                    .start => {},
                }

                std.log.info("[Map] element_end: {}", .{tag});
            },
            .element_start => {
                const element_name = reader.elementNameNs();

                state = try transition(state, element_name.local);
                open = true;

                std.log.info("[Map] element_start: {?}", .{state});

                switch (state) {
                    .map => {
                        map = try allocator.create(Map);
                        map.?.allocator = allocator;

                        for (0..reader.reader.attributeCount()) |i| {
                            const attribute_name = reader.attributeNameNs(i);
                            const attribute_value = try reader.attributeValue(i);
                            const case = std.meta.stringToEnum(ValidMapAttributes, attribute_name.local).?;

                            const m = map.?;

                            switch (case) {
                                .version => m.version = try allocator.dupe(u8, attribute_value),
                                .tiledversion => m.tiledVersion = try allocator.dupe(u8, attribute_value),
                                .width => m.width = try std.fmt.parseInt(u32, attribute_value, 10),
                                .height => m.height = try std.fmt.parseInt(u32, attribute_value, 10),
                                .tileheight => m.tileHeight = try std.fmt.parseInt(u32, attribute_value, 10),
                                .tilewidth => m.tileWidth = try std.fmt.parseInt(u32, attribute_value, 10),
                                .orientation => m.orientation = std.meta.stringToEnum(Orientation, attribute_value).?,
                                .renderorder => m.renderOrder = renderOrderFromString(attribute_value).?,
                                .nextlayerid => m.nextLayerId = try std.fmt.parseInt(u32, attribute_value, 10),
                                .nextobjectid => m.nextObjectId = try std.fmt.parseInt(u32, attribute_value, 10),
                                .infinite => m.infinite = (try std.fmt.parseInt(u32, attribute_value, 10)) == 1,
                            }
                        }
                    },
                    .data => {},
                    .layer => {
                        layer = try allocator.create(Layer);

                        for (0..reader.reader.attributeCount()) |i| {
                            const attribute_name = reader.attributeNameNs(i);
                            const attribute_value = try reader.attributeValue(i);
                            const case = std.meta.stringToEnum(ValidLayerAttributes, attribute_name.local).?;

                            const l = layer.?;

                            switch (case) {
                                .id => l.id = try std.fmt.parseInt(u32, attribute_value, 10),
                                .width => l.width = try std.fmt.parseInt(u32, attribute_value, 10),
                                .height => l.height = try std.fmt.parseInt(u32, attribute_value, 10),
                                .name => l.name = try allocator.dupe(u8, attribute_value),
                            }
                        }
                    },
                    .start => {},
                    .tileset => {
                        tileset = try allocator.create(MapTileset);

                        for (0..reader.reader.attributeCount()) |i| {
                            const attribute_name = reader.attributeNameNs(i);
                            const attribute_value = try reader.attributeValue(i);
                            const case = std.meta.stringToEnum(ValidTileSetAttributes, attribute_name.local).?;

                            switch (case) {
                                .firstgid => tileset.?.firstGid = try std.fmt.parseInt(u32, attribute_value, 10),
                                .source => tileset.?.source = try allocator.dupe(u8, attribute_value),
                            }
                        }

                        const ts = try Tileset.init(allocator, tileset.?.source);
                        tileset.?.tileset = ts;
                    },
                }
            },
            .entity_reference => break,
            .pi => break,
            .text => {
                const text = reader.text() catch return Error.FailedToOpenMap;
                const normtext = try std.mem.replaceOwned(u8, allocator, text, " ", "");
                defer allocator.free(normtext);

                if (std.mem.eql(u8, normtext, "") or std.mem.eql(u8, normtext, "\n")) {
                    continue;
                }

                if (state == .data and open) {
                    var rows = std.mem.splitScalar(u8, text, '\n');

                    var rowsOut = std.ArrayList([]u8).init(allocator);

                    while (rows.next()) |row| {
                        var colsOut = std.ArrayList(u8).init(allocator);
                        var cols = std.mem.splitScalar(u8, row, ',');
                        while (cols.next()) |col| {
                            if (std.mem.eql(u8, col, "")) {
                                continue;
                            }
                            const val = try std.fmt.parseInt(u8, col, 10);
                            try colsOut.append(val);
                        }
                        const colsConv = try colsOut.toOwnedSlice();
                        try rowsOut.append(colsConv);
                    }

                    layer.?.data = try rowsOut.toOwnedSlice();
                } else {
                    std.log.info("[Map] unhandled text: {s} {d}", .{ normtext, normtext.len });
                }
            },
            .xml_declaration => {},
        }
    }

    std.debug.assert(map != null);

    return map.?;
}

pub fn deinit(self: *const @This()) void {
    self.allocator.free(self.version);
    self.allocator.free(self.tiledVersion);

    for (self.tilesets) |elem| {
        self.allocator.free(elem.source);
        elem.tileset.deinit();
        self.allocator.destroy(elem);
    }
    self.allocator.free(self.tilesets);

    for (self.layers) |layer| {
        self.allocator.free(layer.name);
        for (layer.data) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(layer.data);
        self.allocator.destroy(layer);
    }
    self.allocator.free(self.layers);

    self.allocator.destroy(self);
}
