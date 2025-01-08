pub const Class = @This();

const std = @import("std");
const c = @import("cinclude.zig").c;
const Obj = @import("Obj.zig");
const objc = @import("objc_helper.zig");
const assert = std.debug.assert;

pub const NativeClass = c.Class;

native: c.Class,

pub fn init(name: []const u8, superclass: NativeClass, methods: []const c.Method) @This() {
    const cl = c.objc_allocateClassPair(superclass, name, 0);
    if (cl == null) {
        std.debug.panic("Failed to allocate class");
    }

    for (methods) |method| {
        c.class_addMethod(cl, method.name, method.imp, method.types);
    }

    c.objc_registerClassPair(cl);

    return from_native(cl);
}

pub fn from_native(native: NativeClass) @This() {
    assert(native != null);
    return .{ .native = native };
}

pub fn from_name(name: [*c]const u8) @This() {
    return from_native(c.objc_getClass(name));
}

pub fn from_name_strict(name: [*c]const u8) @This() {
    return from_native(c.objc_getRequiredClass(name));
}

pub fn deinit(self: *const @This()) void {
    c.objc_disposeClassPair(self.native);
}

pub fn add_ivar(self: *const @This(), name: []const u8, size: usize, alignment: usize, types: []const u8) void {
    c.class_addIvar(self.native, name, size, alignment, types);
}

pub fn add_method(self: *const @This(), name: c.SEL, imp: c.IMP, types: []const u8) void {
    c.class_addMethod(self.native, name, imp, types);
}

pub fn add_protocol(self: *const @This(), protocol: c.Protocol) void {
    c.class_addProtocol(self.native, protocol);
}

pub fn send(self: *const @This(), comptime ret: type, comptime selector: []const u8, args: anytype) ret {
    return switch (ret) {
        Obj => {
            const res = objc.send(self.native, c.id, selector, args);
            return Obj.init(res);
        },
        Class => {
            const res = objc.send(self.native, c.Class, selector, args);
            return Class.init(res);
        },
        else => objc.send(self.native, ret, selector, args),
    };
}

// const _msg_id = @as(*const fn (cl: c.Class, s: c.SEL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// pub fn msg_id(self: *const @This(), sel: c.SEL) Obj {
//     return Obj.init(_msg_id(self.native, sel));
// }
//
// pub fn smsg_id(self: *const @This(), sel: [*c]const u8) Obj {
//     return self.msg_id(c.sel_registerName(sel));
// }
//
// const _msg_id_id = @as(*const fn (cl: c.Class, s: c.SEL, c.id) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// pub fn msg_id_id(self: *const @This(), sel: c.SEL, id: c.id) Obj {
//     return Obj.init(_msg_id_id(self.native, sel, id));
// }
//
// const _msg_id_int = @as(*const fn (cl: c.Class, s: c.SEL, c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// pub fn msg_id_int(self: *const @This(), sel: c.SEL, i: c_int) Obj {
//     return Obj.init(_msg_id_int(self.native, sel, i));
// }
//
// const _msg_void = @as(*const fn (cl: c.Class, s: c.SEL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// pub fn msg_void(self: *const @This(), sel: c.SEL) void {
//     return _msg_void(self.native, sel);
// }
//
// const _msg_void_id = @as(*const fn (cl: c.Class, s: c.SEL, i: c.id) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// pub fn msg_void_id(self: *const @This(), sel: c.SEL, i: c.id) void {
//     return _msg_void_id(self.native, sel, i);
// }
//
// const _msg_id_chr = @as(*const fn (cl: c.Class, s: c.SEL, i: [*c]const u8) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// pub fn msg_id_chr(self: *const @This(), sel: c.SEL, i: []const u8) Obj {
//     return Obj.init(_msg_id_chr(self.native, sel, i));
// }

pub fn alloc(self: *const @This()) Obj {
    return self.send(Obj, "alloc", .{});
}

// // const msg_id_int = @as(*const fn (cl: c.id, s: c.SEL, i: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// // const msg_ptr_int = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque, ii: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
