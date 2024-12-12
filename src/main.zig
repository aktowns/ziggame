const rl = @import("raylib");

const std = @import("std");

fn positionVector(shape: rl.Rectangle) rl.Vector2 {
    return struct {
        .x = shape.x,
        .y = shape.y
    };
}

const Entity = struct {
    var shape: rl.Rectangle = rl.Rectangle { 0 };

    inline fn camera() rl.Camera2D {
        return rl.Camera2D {
            .target = shape,
            .offset = rl.Vector2 { .x = 200, .y = 200 },
            .rotation = 0,
            .zoom = 1.0
        };
    }
};

pub fn MakeEntity(position: rl.Vector2, size: rl.Vector2) Entity {
    return Entity { position, size };
}

pub fn main() !void {
    const kScreenWidth = 800;
    const kScreenHeight = 600;
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    rl.initWindow(kScreenWidth, kScreenHeight, "testing");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var player: rl.Rectangle = rl.Rectangle { .height = 40, .width = 40, .x = 200, .y = 200 };


    const camera: rl.Camera2D = rl.Camera2D{
        .target = rl.Vector2 { .x = player.x, .y = player.y },
        .offset = rl.Vector2 { .x = 200, .y = 200 },
        .rotation = 0,
        .zoom = 1.0,
    };

    const sourceRectangle = rl.Rectangle { .height = -kScreenHeight, .width = kScreenWidth, .x = 0, .y = 0};

    const screenCamera1 = rl.loadRenderTexture(kScreenWidth, kScreenHeight);
    defer rl.unloadRenderTexture(screenCamera1);

    while (!rl.windowShouldClose()) {
        if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            player.y += 3;
        }
        {
            rl.beginTextureMode(screenCamera1);
            defer rl.endTextureMode();
            {
                camera.begin();
                defer camera.end();
                rl.clearBackground(rl.Color.ray_white);

                for (0..kScreenWidth/40) |i| {
                    const startVector = rl.Vector2 { .x = @as(f32, @floatFromInt(40*i)), .y = 0 };
                    const endVector = rl.Vector2 { .x = @as(f32, @floatFromInt(40*i)), .y = kScreenHeight };

                    rl.drawLineV(startVector, endVector, rl.Color.light_gray);
                }

                for (0..kScreenHeight/40) |i| {
                    const startVector = rl.Vector2 { .y = @as(f32, @floatFromInt(40*i)), .x = 0 };
                    const endVector = rl.Vector2 { .y = @as(f32, @floatFromInt(40*i)), .x = kScreenWidth };

                    rl.drawLineV(startVector, endVector, rl.Color.light_gray);
                }

                rl.drawText("Hello World", 190, 200, 20, rl.Color.light_gray);
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        rl.drawTextureRec(screenCamera1.texture, sourceRectangle, rl.Vector2{.x = 0, .y = 0}, rl.Color.white);
    }

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
