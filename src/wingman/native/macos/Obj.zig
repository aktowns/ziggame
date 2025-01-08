pub const Obj = @This();

const std = @import("std");
const builtin = @import("builtin");
const c = @import("cinclude.zig").c;
const objc = @import("objc_helper.zig");
const Class = @import("Class.zig");
const assert = std.debug.assert;

pub const NativeObj = c.id;

native: c.id,

pub fn init(obj: c.id) @This() {
    assert(obj != null);
    return .{ .native = obj };
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

// const _msg_id = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// pub fn msg_id(self: *const @This(), sel: c.SEL) Obj {
//     return Obj.init(_msg_id(self.native, sel));
// }
//
// const _msg_id_id = @as(*const fn (cl: c.id, s: c.SEL, i: c.id) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// pub fn msg_id_id(self: *const @This(), sel: c.SEL, id: c.id) Obj {
//     return Obj.init(_msg_id_id(self.native, sel, id));
// }
//
// const _msg_id_rect = @as(*const fn (cl: c.id, s: c.SEL, i: c.CGRect) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// pub fn msg_id_rect(self: *const @This(), sel: c.SEL, rect: c.CGRect) Obj {
//     return Obj.init(_msg_id_rect(self.native, sel, rect));
// }
//
// const msg_uint = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c_ulong, @ptrCast(&c.objc_msgSend));
// const msg_int = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c_long, @ptrCast(&c.objc_msgSend));
// const msg_SEL = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.SEL, @ptrCast(&c.objc_msgSend));
// const msg_float = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.CGFloat, @ptrCast(&c.objc_msgSend));
// const msg_bool = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.BOOL, @ptrCast(&c.objc_msgSend));
// const msg_void = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// //const msg_double = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) , @ptrCast(&c.objc_msgSend));
// const _msg_void_id = @as(*const fn (cl: c.id, s: c.SEL, i: c.id) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// pub fn msg_void_id(self: *const @This(), sel: c.SEL, i: c.id) void {
//     return _msg_void_id(self.native, sel, i);
// }
//
// const msg_void_uint = @as(*const fn (cl: c.id, s: c.SEL, i: c_ulong) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// const msg_void_int = @as(*const fn (cl: c.id, s: c.SEL, i: c_long) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// const msg_void_SEL = @as(*const fn (cl: c.id, s: c.SEL, i: c.SEL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// const msg_void_float = @as(*const fn (cl: c.id, s: c.SEL, i: c.CGFloat) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// const msg_void_bool = @as(*const fn (cl: c.id, s: c.SEL, i: c.BOOL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// const msg_void_ptr = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// const msg_id_chr = @as(*const fn (cl: c.id, s: c.SEL, i: [*c]const u8) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// const msg_id_ptr = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
