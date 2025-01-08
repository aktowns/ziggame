const std = @import("std");
const assert = std.debug.assert;
const c = @import("cinclude.zig").c;

const Fn = std.builtin.Type.Fn;

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
    comptime var ps: [fields_info.len + 2]Fn.Param = undefined;
    comptime {
        ps[0] = Fn.Param{ .type = target_type, .is_generic = false, .is_noalias = false };
        ps[1] = Fn.Param{ .type = c.SEL, .is_generic = false, .is_noalias = false };
        for (fields_info, 2..) |*field, i| {
            // This should be dropped or improved in somewway, but atm catch any weird args being passed in
            assert(field.type == c.id or field.type == c.Class or field.type == c_uint);

            ps[i] = Fn.Param{ .type = field.type, .is_generic = false, .is_noalias = false };
        }
    }

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
                .params = &ps,
            } }),
        },
    });

    const f: constructed = @ptrCast(&c.objc_msgSend);
    return @call(.auto, f, .{ target, c.sel_registerName(@ptrCast(selector)) } ++ args);
}
