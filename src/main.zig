const za = @import("zalgebra");
const std = @import("std");
const pretty = @import("pretty");
const builtin = @import("builtin");

const Vec3 = za.Vec3;
const Vec2 = za.Vec2;

const engine = @import("engine");

const Rectangle = struct {
    position: Vec2,
    size: Vec2,

    fn new(x: f32, y: f32, w: f32, h: f32) Rectangle {
        return Rectangle{ .position = Vec2.new(x, y), .size = Vec2.new(w, h) };
    }

    fn zero() Rectangle {
        return new(0, 0, 0, 0);
    }
};

const Entity = struct {
    var shape: Rectangle = Rectangle.zero();

    // inline fn camera() rl.Camera2D {
    //     return rl.Camera2D {
    //         .target = shape,
    //         .offset = rl.Vector2 { .x = 200, .y = 200 },
    //         .rotation = 0,
    //         .zoom = 1.0
    //     };
    // }
};

pub fn MakeEntity(position: @Vector(2, f32), size: Vec2) Entity {
    return Entity{ position, size };
}

const kScreenWidth = 800;
const kScreenHeight = 600;

// const state = struct {
//     var pass_action = sg.PassAction{};
//     var time_stamp: u64 = 0;
//     var prim = struct { ibuf: sg.Buffer, pip: sg.Pipeline };
// };

// export fn init() void {
//     stm.setup();
//     sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });
//
//     var sdtx_desc = sdtx.Desc{ .logger = .{ .func = slog.func } };
//     sdtx_desc.fonts[0] = sdtx.fontKc853();
//     sdtx.setup(sdtx_desc);
//
//     const pip_desc = sg.PipelineDesc{
//         .layout = {
//             .attrs[shd.ATTR_primtypes_position].format = sg.VertexFormat.FLOAT2;
//             .attrs[shd.ATTR_primtypes_color0].format = sg.VertexFormat.UBYTE4N;
//         },
//         .shader = sg.makeShader(shd.primtypesShaderDesc(sg.queryBackend())),
//         .depth = .{ .write_enabled = true, .compare = sg.CompareFunc.LESS_EQUAL },
//         .index_type = sg.IndexType.UINT16,
//         .primitive_type = sg.PrimitiveType.LINES,
//     };
//
//     state.prim.ibuf = sg.makeBuffer();
//     _ = sg.makePipeline(pip_desc);
//
//     state.pass_action.colors[0] = sg.ColorAttachmentAction{ .load_action = .CLEAR, .clear_value = sg.Color{ .r = 0, .g = 0.125, .b = 0.25, .a = 1 } };
// }

// export fn frame() void {
//     const frame_time = stm.ms(stm.laptime(&state.time_stamp));
//
//     sdtx.canvas(@as(f32, @floatFromInt(sapp.width())) * 0.5, @as(f32, @floatFromInt(sapp.height())) * 0.5);
//     sdtx.origin(0.0, 2.0);
//
//     sdtx.font(0);
//     sdtx.color3b(100, 80, 120);
//     sdtx.puts("Hello\n");
//     sdtx.print("Frame Time: {d:.3}ms\n", .{frame_time});
//
//     sg.beginPass(sg.Pass{ .action = state.pass_action, .swapchain = sglue.swapchain() });
//     sg.applyPipeline(state.prim.pip);
//     sg.applyBindings(.{
//         .vertex_buffers = [0]state.vbuf,
//         .index_buffer = state.prim.ibuf
//     });
//     sg.applyUniforms(shd.UB_vs_params, sg.asRange(shd.VsParams));
//     sg.draw(0, state.prim.ibuf, 1);
//
//     sdtx.draw();
//
//     for (0..kScreenWidth / 40) |i| {
//         const startVector = Vec2.new(40.0 * i, 0);
//         const endVector = Vec2.new(40.0 * i, kScreenHeight);
//
//         // const startVector = rl.Vector2 { .x = @as(f32, @floatFromInt(40*i)), .y = 0 };
//         // const endVector = rl.Vector2 { .x = @as(f32, @floatFromInt(40*i)), .y = kScreenHeight };
//
//         // rl.drawLineV(startVector, endVector, rl.Color.light_gray);
//     }
//
//     // for (0..kScreenHeight/40) |i| {
//     //   const startVector = rl.Vector2 { .y = @as(f32, @floatFromInt(40*i)), .x = 0 };
//     //   const endVector = rl.Vector2 { .y = @as(f32, @floatFromInt(40*i)), .x = kScreenWidth };
//
//     //   rl.drawLineV(startVector, endVector, rl.Color.light_gray);
//     // }
//
//     sg.endPass();
//     sg.commit();
// }
// export fn input(event: ?*const sapp.Event) void {
//     _ = event; // autofix
// }
// export fn cleanup() void {
//     sdtx.shutdown();
//     sg.shutdown();
// }

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }

    const allocator: std.mem.Allocator = if (builtin.target.isWasm()) alloc: {
        const wa = std.heap.c_allocator;
        _ = try wa.alloc(u8, 10);
        break :alloc wa;
    } else alloc: {
        //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        break :alloc allocator;
    };
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer {
    //     _ = gpa.deinit();
    // }
    //const allocator = gpa.allocator();

    // const map = try engine.tiled.Map.init(allocator, "test.tmx");
    // defer map.deinit();
    // std.log.info("map={?}", .{map});
    // try pretty.print(allocator, map, .{ .array_max_len = 3, .max_depth = 20, .slice_u8_is_str = false });

    var platform = try engine.Platform.getCurrentPlatform(allocator);
    defer platform.deinit();
    std.log.info("[Main] Using platform: {s}", .{platform.name});
    var gfx = try engine.GraphicsPlatform.init(.{ .window_height = 480, .window_width = 640, .window_title = "ZenEng", .platform = &platform });
    defer gfx.deinit();
    try gfx.start();

    //sapp.run(.{ .init_cb = init, .frame_cb = frame, .event_cb = input, .cleanup_cb = cleanup, .width = kScreenWidth, .height = kScreenHeight, .sample_count = 4, .icon = .{ .sokol_default = true }, .window_title = "test", .logger = .{ .func = slog.func } });
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // rl.initWindow(kScreenWidth, kScreenHeight, "testing");
    // defer rl.closeWindow();

    // rl.setTargetFPS(60);

    // var player: rl.Rectangle = rl.Rectangle { .height = 40, .width = 40, .x = 200, .y = 200 };

    // const camera: rl.Camera2D = rl.Camera2D{
    //     .target = rl.Vector2 { .x = player.x, .y = player.y },
    //     .offset = rl.Vector2 { .x = 200, .y = 200 },
    //     .rotation = 0,
    //     .zoom = 1.0,
    // };

    // const sourceRectangle = rl.Rectangle { .height = -kScreenHeight, .width = kScreenWidth, .x = 0, .y = 0};

    // const screenCamera1 = rl.loadRenderTexture(kScreenWidth, kScreenHeight);
    // defer rl.unloadRenderTexture(screenCamera1);

    // while (!rl.windowShouldClose()) {
    //     if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
    //         player.y += 3;
    //     }
    //     {
    //         rl.beginTextureMode(screenCamera1);
    //         defer rl.endTextureMode();
    //         {
    //             camera.begin();
    //             defer camera.end();
    //             rl.clearBackground(rl.Color.ray_white);

    //             for (0..kScreenWidth/40) |i| {
    //                 const startVector = rl.Vector2 { .x = @as(f32, @floatFromInt(40*i)), .y = 0 };
    //                 const endVector = rl.Vector2 { .x = @as(f32, @floatFromInt(40*i)), .y = kScreenHeight };

    //                 rl.drawLineV(startVector, endVector, rl.Color.light_gray);
    //             }

    //             for (0..kScreenHeight/40) |i| {
    //                 const startVector = rl.Vector2 { .y = @as(f32, @floatFromInt(40*i)), .x = 0 };
    //                 const endVector = rl.Vector2 { .y = @as(f32, @floatFromInt(40*i)), .x = kScreenWidth };

    //                 rl.drawLineV(startVector, endVector, rl.Color.light_gray);
    //             }

    //             rl.drawText("Hello World", 190, 200, 20, rl.Color.light_gray);
    //         }
    //     }

    //     rl.beginDrawing();
    //     defer rl.endDrawing();
    //     rl.clearBackground(rl.Color.black);
    //     rl.drawTextureRec(screenCamera1.texture, sourceRectangle, rl.Vector2{.x = 0, .y = 0}, rl.Color.white);
    // }

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
