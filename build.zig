const std = @import("std");
const builtin = @import("builtin");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // const dep_sokol = b.dependency("sokol", .{
    //     .target = target,
    //     .optimize = optimize,
    // });

    const dep_zalgebra = b.dependency("zalgebra", .{ .target = target, .optimize = optimize });

    const deps = [_]struct { []const u8, *Build.Dependency }{.{ "zalgebra", dep_zalgebra }};

    if (target.result.isWasm()) {
        // try buildWeb(b, target, optimize);
    } else {
        try buildNative(b, target, optimize, &deps);
    }

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn buildNative(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, other_deps: []const struct { []const u8, *Build.Dependency }) !void {
    const exe = b.addExecutable(.{
        .name = "test",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // exe.root_module.addImport("sokol", dep_sokol.module("sokol"));

    for (other_deps) |dep| {
        exe.root_module.addImport(dep[0], dep[1].module(dep[0]));
    }

    exe.linkLibC();

    const gpu_lib = b.addModule("gpu", .{ .root_source_file = b.path("src/gpu.zig"), .target = target, .optimize = optimize });

    exe.addIncludePath(b.path("ext/wgpu-macos-aarch64-debug/include/"));
    exe.addIncludePath(b.path("ext/wgpu-macos-aarch64-debug/include/webgpu/"));

    const dep_glfw = b.dependency("mach_glfw", .{ .target = target, .optimize = optimize });
    gpu_lib.addImport("mach-glfw", dep_glfw.module("mach-glfw"));

    // const gpu_lib = b.addStaticLibrary(.{ .name = "gpu", .root_source_file = b.path("src/gpu.zig"), .target = target, .optimize = optimize });
    gpu_lib.addIncludePath(b.path("ext/wgpu-macos-aarch64-debug/include/"));
    gpu_lib.addIncludePath(b.path("ext/wgpu-macos-aarch64-debug/include/webgpu/"));
    gpu_lib.addLibraryPath(b.path("ext/wgpu-macos-aarch64-debug/lib/"));
    gpu_lib.linkSystemLibrary("wgpu_native", .{ .preferred_link_mode = .static });
    gpu_lib.linkFramework("CoreFoundation", .{});
    gpu_lib.linkFramework("Metal", .{});
    gpu_lib.linkFramework("QuartzCore", .{});

    // b.installArtifact(gpu_lib);

    exe.root_module.addImport("gpu", gpu_lib);

    // exe.addLibraryPath(b.path("ext/wgpu-macos-aarch64-debug/lib/"));
    // exe.linkLibrary(gpu_lib);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

// fn buildWeb(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, dep_sokol: *Build.Dependency) !void {
//     const exe = b.addExecutable(.{
//         .name = "test",
//         .root_source_file = b.path("src/main.zig"),
//         .target = target,
//         .optimize = optimize,
//     });
//
//     exe.root_module.addImport("sokol", dep_sokol.module("sokol"));
//
//     const emsdk = dep_sokol.builder.dependency("emsdk", .{});
//     const link_step = try sokol.emLinkStep(b, .{
//         .lib_main = exe,
//         .target = target,
//         .optimize = optimize,
//         .emsdk = emsdk,
//         .use_webgl2 = true,
//         .use_emmalloc = true,
//         .use_filesystem = false,
//         .shell_file_path = dep_sokol.path("src/sokol/web/shell.html"),
//     });
//
//     const run = sokol.emRunStep(b, .{ .name = "test", .emsdk = emsdk });
//     run.step.dependOn(&link_step.step);
//     b.step("run", "Run test").dependOn(&run.step);
// }
