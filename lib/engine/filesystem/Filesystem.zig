const Filesystem = @This();

const std = @import("std");
const builtin = @import("builtin");
const manifest = @import("resources");
const log = @import("wingman").log;

pub const ResourceType = manifest.ResourceType;
const InternalFilesystemNodes = std.StringHashMap(u32);
const InternalFilesystem = std.AutoHashMap(ResourceType, InternalFilesystemNodes);

const Error = error{ ResourceNotFound, FileNotFound, IndexMissing, FailedToOpenFile };

allocator: std.mem.Allocator,
internal: *InternalFilesystem,

pub fn init(allocator: std.mem.Allocator) !@This() {
    log.debug(@src(), "Creating internal filesystem structure", .{});
    const internal = try allocator.create(InternalFilesystem);
    internal.* = InternalFilesystem.init(allocator);

    log.debug(@src(), "Creating manifest table", .{});
    for (manifest.resources, 0..) |resource, idx| {
        var resources = try internal.getOrPut(resource.resource);
        if (!resources.found_existing) {
            log.debug(@src(), "Creating new node table for {?}", .{resource.resource});
            resources.value_ptr.* = InternalFilesystemNodes.init(allocator);
        }
        log.debug(@src(), "Adding file {s} under {?} with node number {d}", .{ resource.name, resource.resource, idx });

        try resources.value_ptr.putNoClobber(resource.name, @intCast(idx));
    }

    return .{ .allocator = allocator, .internal = internal };
}

pub fn deinit(self: *@This()) void {
    log.debug(@src(), "deinitializing..", .{});
    var it = self.internal.valueIterator();
    while (it.next()) |item| {
        item.deinit();
    }

    self.internal.deinit();
    self.allocator.destroy(self.internal);
}

pub fn readFile(self: *const @This(), path: []const u8, typ: ResourceType) Error![]const u8 {
    log.debug(@src(), "looking up {s} under type {?}", .{ path, typ });

    const idx = if (self.internal.get(typ)) |resourceLookup| resourceIdx: {
        if (resourceLookup.get(path)) |resource| {
            break :resourceIdx resource;
        } else {
            return Error.FileNotFound;
        }
    } else return Error.ResourceNotFound;

    if (idx > manifest.resources.len) {
        return Error.IndexMissing;
    }

    const resource = manifest.resources[idx];

    if (!builtin.target.isWasm()) {
        const file = std.fs.cwd().openFile(resource.path, .{}) catch return Error.FailedToOpenFile;
        defer file.close();

        const stat = file.stat() catch return Error.FailedToOpenFile;
        const buffer = file.readToEndAllocOptions(self.allocator, @intCast(stat.size), null, @alignOf(u8), 0) catch return Error.FailedToOpenFile;

        return buffer;
    } else {
        return self.allocator.dupe(u8, resource.embedded.?) catch return Error.FailedToOpenFile;
    }
}
