const std = @import("std");

const fs = std.fs;

const Manifest = struct {
    writer: std.fs.File.Writer,

    pub fn init(writer: std.fs.File.Writer) @This() {
        return .{ .writer = writer };
    }
    pub fn writeEnum(self: *const @This(), name: []const u8, branches: [][]const u8) !void {
        try std.fmt.format(self.writer, "pub const {s} = enum {{\n", .{name});
        for (branches) |branch| {
            try std.fmt.format(self.writer, "    {s},\n", .{branch});
        }
        _ = try self.writer.write("};\n");
    }

    pub const StructField = struct { name: []const u8, typ: []const u8 };

    pub fn writeStruct(self: *const @This(), name: []const u8, fields: []const StructField) !void {
        try std.fmt.format(self.writer, "pub const {s} = struct {{\n", .{name});
        for (fields) |field| {
            try std.fmt.format(self.writer, "    {s}: {s},\n", .{ field.name, field.typ });
        }
        _ = try self.writer.write("};\n");
    }

    pub const ArrayField = struct { name: []const u8, value: []const u8 };
    pub const ArrayItem = struct { fields: []*ArrayField };

    pub fn writeConst(self: *const @This(), name: []const u8, value: []const u8) !void {
        try std.fmt.format(self.writer, "pub const {s} = {s};\n", .{ name, value });
    }

    pub fn writeArray(self: *const @This(), name: []const u8, typ: []const u8, items: []const *ArrayItem) !void {
        try std.fmt.format(self.writer, "pub const {s}: {s} = &.{{\n", .{ name, typ });
        for (items) |item| {
            _ = try self.writer.write("    .{\n");
            for (item.fields) |field| {
                try std.fmt.format(self.writer, "        .{s} = {s},\n", .{ field.name, field.value });
            }
            _ = try self.writer.write("    },\n");
        }
        _ = try self.writer.write("};\n");
    }

    pub fn writeImport(self: *const @This(), name: []const u8, import: []const u8) !void {
        try std.fmt.format(self.writer, "const {s} = @import(\"{s}\");\n", .{ name, import });
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const path = try fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(path);

    const resources_path = try fs.path.join(allocator, &[_][]const u8{ path, "resources" });
    defer allocator.free(resources_path);

    const dir = try fs.openDirAbsolute(resources_path, .{ .access_sub_paths = false, .iterate = true });

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var roots = std.ArrayList([]const u8).init(allocator);
    defer roots.deinit();

    //var files = std.StringHashMap([]const u8).init(allocator);
    var files = std.ArrayList(*Manifest.ArrayItem).init(allocator);
    defer files.deinit();

    const manifest_path = try fs.path.join(allocator, &[_][]const u8{ path, "resources", "manifest.zig" });
    defer allocator.free(manifest_path);

    const manifest_file = try fs.createFileAbsolute(manifest_path, .{});
    defer manifest_file.close();
    const manifest_writer = manifest_file.writer();
    const manifest = Manifest.init(manifest_writer);

    while (try walker.next()) |entry| {
        var cit = try fs.path.componentIterator(entry.path);
        const maybeBase = cit.first();
        if (entry.kind == fs.File.Kind.directory) {
            if (maybeBase) |base| {
                const idx = for (roots.items, 0..) |root, index| {
                    if (std.mem.eql(u8, root, base.name)) break index;
                } else null;

                if (idx == null) {
                    try roots.append(try allocator.dupe(u8, base.name));
                }
            }
        } else if (std.mem.indexOf(u8, entry.path, std.fs.path.sep_str) != null) {
            if (maybeBase) |base| {
                const rest = entry.path[base.name.len..];
                const name = try allocator.dupe(u8, rest);
                defer allocator.free(name);
                const resource = try allocator.dupe(u8, base.name);
                defer allocator.free(resource);
                const fullPath = try std.fs.path.resolve(allocator, &[_][]const u8{ resources_path, entry.path });
                defer allocator.free(fullPath);
                // const relativePath = try std.fs.path.join(allocator, &[_][]const u8{ "resources", entry.path });
                // defer allocator.free(relativePath);

                const nameField = try allocator.create(Manifest.ArrayField);
                nameField.name = "name";
                nameField.value = try std.fmt.allocPrint(allocator, "\"{s}\"", .{name});

                const resourceField = try allocator.create(Manifest.ArrayField);
                resourceField.name = "resource";
                resourceField.value = try std.fmt.allocPrint(allocator, "ResourceType.{s}", .{resource});

                const embeddedField = try allocator.create(Manifest.ArrayField);
                embeddedField.name = "embedded";
                embeddedField.value = try std.fmt.allocPrint(allocator, "if (builtin.target.isWasm()) @embedFile(\"{s}\") else null", .{entry.path});

                const pathField = try allocator.create(Manifest.ArrayField);
                pathField.name = "path";
                pathField.value = try std.fmt.allocPrint(allocator, "\"{s}\"", .{fullPath});

                const arrayItem = try allocator.create(Manifest.ArrayItem);
                arrayItem.fields = try allocator.alloc(*Manifest.ArrayField, 4);
                arrayItem.fields[0] = nameField;
                arrayItem.fields[1] = resourceField;
                arrayItem.fields[2] = embeddedField;
                arrayItem.fields[3] = pathField;

                try files.append(arrayItem);
            }
        }
    }

    try manifest.writeImport("std", "std");
    try manifest.writeImport("builtin", "builtin");
    try manifest.writeEnum("ResourceType", roots.items);
    try manifest.writeStruct("Resource", &.{
        .{ .name = "name", .typ = "[]const u8" },
        .{ .name = "resource", .typ = "ResourceType" },
        .{ .name = "embedded", .typ = "?[]const u8" },
        .{ .name = "path", .typ = "[]const u8" },
    });

    try manifest.writeArray("resources", "[]const Resource", files.items);

    for (roots.items) |root| {
        allocator.free(root);
    }

    for (files.items) |item| {
        for (item.fields) |field| {
            allocator.free(field.value);
            allocator.destroy(field);
        }
        allocator.free(item.fields);
        allocator.destroy(item);
    }
}
