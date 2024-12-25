const std = @import("std");
const builtin = @import("builtin");
const emcc = @import("emcc.zig");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_zalgebra = b.dependency("zalgebra", .{ .target = target, .optimize = optimize });
    const dep_xml = b.dependency("xml", .{ .target = target, .optimize = optimize });
    const dep_zigimg = b.dependency("zigimg", .{ .target = target, .optimize = optimize });
    const dep_pretty = b.dependency("pretty", .{ .target = target, .optimize = optimize });

    const deps = [_]struct { []const u8, *Build.Dependency }{
        .{ "zalgebra", dep_zalgebra },
        .{ "xml", dep_xml },
        .{ "pretty", dep_pretty },
        .{ "zigimg", dep_zigimg },
    };

    try buildNative(b, target, optimize, &deps);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn setupBuildPaths(b: *Build, c: *Build.Module, target: Build.ResolvedTarget) void {
    c.addIncludePath(b.path("sysroot/include"));
    c.addLibraryPath(b.path("sysroot/lib"));

    if (!target.result.isWasm()) {
        c.linkSystemLibrary("clib", .{});
        c.linkSystemLibrary("webgpu_dawn", .{});
        c.linkSystemLibrary("openal", .{});
        c.linkSystemLibrary("glfw3", .{ .preferred_link_mode = .static });
        const imgui_path = std.fs.cwd().realpathAlloc(b.allocator, "sysroot/lib/cimgui.a") catch unreachable;
        c.linkSystemLibrary(imgui_path, .{ .preferred_link_mode = .static, .use_pkg_config = .no });
        c.linkSystemLibrary("imgui_backend", .{});
    } else {}

    switch (target.result.os.tag) {
        .linux => {
            c.linkSystemLibrary("unwind", .{});
        },
        .macos => {
            c.linkFramework("CoreFoundation", .{});
            c.linkFramework("Metal", .{});
            c.linkFramework("QuartzCore", .{});
        },
        .emscripten => {},
        else => std.debug.panic("Unhandled target {?}", .{target.result.os}),
    }
}

fn buildNative(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, other_deps: []const struct { []const u8, *Build.Dependency }) anyerror!void {
    const resources_lib = b.addModule("resources", .{ .root_source_file = b.path("resources/manifest.zig"), .target = target, .optimize = optimize });
    const engine_lib = b.addModule("engine", .{ .root_source_file = b.path("src/engine/engine.zig"), .target = target, .optimize = optimize });
    engine_lib.addImport("resources", resources_lib);

    for (other_deps) |dep| {
        engine_lib.addImport(dep[0], dep[1].module(dep[0]));
    }

    setupBuildPaths(b, engine_lib, target);

    if (!target.result.isWasm()) {
        const exe = b.addExecutable(.{
            .name = "zen",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        const exe_check = b.addExecutable(.{
            .name = "zen",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        exe.linkLibC();
        exe_check.linkLibC();

        for (other_deps) |dep| {
            exe.root_module.addImport(dep[0], dep[1].module(dep[0]));
        }

        for (other_deps) |dep| {
            exe_check.root_module.addImport(dep[0], dep[1].module(dep[0]));
        }

        // setupBuildPaths(b, exe, target);
        // setupBuildPaths(b, exe_check, target);

        exe.root_module.addImport("engine", engine_lib);
        exe_check.root_module.addImport("engine", engine_lib);

        exe.root_module.addImport("resources", resources_lib);
        exe_check.root_module.addImport("resources", resources_lib);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

        const check = b.step("check", "Check if foo compiles");
        check.dependOn(&exe_check.step);
    } else if (target.result.os.tag == .emscripten) {
        const emscripten_headers = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "cache", "sysroot", "include" });
        defer b.allocator.free(emscripten_headers);
        std.log.info("Using emscripten headers {s}", .{emscripten_headers});
        engine_lib.addIncludePath(.{ .cwd_relative = emscripten_headers });

        const exe_lib = try emcc.compileForEmscripten(b, "test", "src/main.zig", target, optimize);
        exe_lib.root_module.addImport("engine", engine_lib);
        exe_lib.root_module.addImport("resources", resources_lib);
        exe_lib.linkLibC();
        exe_lib.addIncludePath(.{ .cwd_relative = emscripten_headers });

        const link_step = try emcc.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{exe_lib});
        link_step.addArg("--embed-file");
        link_step.addArg("resources/");

        b.installArtifact(exe_lib);

        const run_step = try emcc.emscriptenRunStep(b);
        run_step.step.dependOn(&link_step.step);

        const run_option = b.step("run", "idk man");
        run_option.dependOn(&run_step.step);
    }
}
