const std = @import("std");
const assert = std.debug.assert;
const c = @import("cinclude.zig").c;

const Fn = std.builtin.Type.Fn;

pub fn alloc(target: c.Class) c.id {
    return send(target, c.id, "alloc", .{});
}

pub fn send(target: anytype, comptime ret: type, comptime selector: []const u8, args: anytype) ret {
    const ArgsType = @TypeOf(args);
    const args_type_info = @typeInfo(ArgsType);
    if (args_type_info != .@"struct") {
        @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
    }
    const fields_info = args_type_info.@"struct".fields;

    const target_type = @TypeOf(target);
    assert(target_type == c.Class or target_type == c.id);

    // compiletime co-erce args to generate objc sig
    const type_info = comptime brk: {
        var ps: [fields_info.len + 2]Fn.Param = undefined;
        ps[0] = Fn.Param{ .type = target_type, .is_generic = false, .is_noalias = false };
        ps[1] = Fn.Param{ .type = c.SEL, .is_generic = false, .is_noalias = false };
        for (fields_info, 2..) |*field, i| {
            // This should be dropped or improved in somewway, but atm catch any weird args being passed in
            // if (field.type != c.id and
            //     field.type != c.Class and
            //     field.type != c_uint and
            //     field.type != bool and
            //     field.type != [*c]const u8 and
            //     field.type != c.CGRect and
            //     field.type != c_ulong and
            //     field.type != comptime_int and
            //     field.type != ?*anyopaque)
            // {
            //     @compileLog(field.type);
            //     @compileError("expected type");
            // }
            ps[i] = Fn.Param{ .type = field.type, .is_generic = false, .is_noalias = false };
        }

        break :brk ps;
    };

    const constructed = @Type(.{
        .pointer = .{
            .is_const = true,
            .size = .One,
            .is_volatile = false,
            .alignment = 0, // TODO: idk?
            .address_space = .generic,
            .is_allowzero = false,
            .sentinel = null,
            .child = @Type(.{ .@"fn" = Fn{
                .return_type = ret,
                .calling_convention = .c,
                .is_generic = false,
                .is_var_args = false,
                .params = &type_info,
            } }),
        },
    });

    const f: constructed = @ptrCast(&c.objc_msgSend);
    return @call(.auto, f, .{ target, c.sel_registerName(@ptrCast(selector)) } ++ args);
}
