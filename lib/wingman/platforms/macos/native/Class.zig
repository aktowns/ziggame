const std = @import("std");
const c = @import("cinclude.zig").c;
const send = @import("objc_helper.zig").send;
const assert = std.debug.assert;

pub const Method = struct {
    name: []const u8,
    imp: c.IMP,
    types: []const u8,
};

pub fn define(name: []const u8, superclass: c.Class, methods: []const Method) c.Class {
    const cl = c.objc_allocateClassPair(superclass, @ptrCast(name), 0);
    if (cl == null) {
        std.debug.panic("Failed to allocate class: {s}", .{name});
    }

    for (methods) |method| {
        _ = c.class_addMethod(cl, c.sel_registerName(@ptrCast(method.name)), method.imp, @ptrCast(method.types));
    }

    c.objc_registerClassPair(cl);

    return cl;
}

pub fn from_name(name: [*c]const u8) c.Class {
    return c.objc_getClass(name);
}

pub fn from_name_strict(name: [*c]const u8) c.Class {
    return c.objc_getRequiredClass(name);
}

pub fn dispose(cls: c.Class) void {
    c.objc_disposeClassPair(cls);
}

pub fn add_ivar(cls: c.Class, name: []const u8, size: usize, alignment: usize, types: []const u8) void {
    c.class_addIvar(cls, name, size, alignment, types);
}

pub fn add_method(cls: c.Class, name: c.SEL, imp: c.IMP, types: []const u8) void {
    c.class_addMethod(cls, name, imp, types);
}

pub fn add_protocol(cls: c.Class, protocol: c.Protocol) void {
    c.class_addProtocol(cls, protocol);
}

pub fn alloc(cls: c.Class) c.id {
    return send(cls, c.id, "alloc", .{});
}
