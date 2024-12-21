const GraphicsPlatform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const wg = cincludes.wg;
const glfw = cincludes.glfw;
const u = @import("util.zig");
const Platform = @import("Platform.zig");

const w = @import("wgpu/wgpu.zig");
const Instance = w.Instance;
const Surface = w.Surface;

instance: Instance,
surface: Surface,
adapter: wg.WGPUAdapter,
device: wg.WGPUDevice,
config: ?*wg.WGPUSurfaceConfiguration,

pub const Error = error{ FailedToCreateInstance, FailedToInitializeGLFW, FailedToGetSurface };

pub const GraphicsPlatformOptions = struct { windowTitle: []const u8, windowWidth: u32, windowHeight: u32, osPlatform: Platform };

pub fn init(options: GraphicsPlatformOptions) !@This() {
    std.log.info("Creating webgpu instance", .{});
    const instance = try Instance.init(options.osPlatform.allocator);
    // const instance = wg.wgpuCreateInstance(null) orelse return Error.FailedToCreateInstance;

    std.log.debug("[GraphicsPlatform] Initializing GLFW", .{});
    if (glfw.glfwInit() != 1) {
        std.log.err("failed to initialize glfw: {?s}", .{"?"});
        return Error.FailedToInitializeGLFW;
    }

    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);

    const window = glfw.glfwCreateWindow(@intCast(options.windowWidth), @intCast(options.windowHeight), @as([*c]const u8, @ptrCast(options.windowTitle)), null, null).?;

    // const surface_descriptor = options.osPlatform.surface_descriptor(window);
    const surfaceSource = options.osPlatform.getSurfaceSource(window) catch |err| {
        std.log.err("Failed to get surface: {?}", .{err});
        return Error.FailedToGetSurface;
    };

    std.log.debug("[GraphicsPlatform] Creating surface (from source {?})", .{surfaceSource});
    const surface = try instance.createSurfaceFromSource(surfaceSource);
    const adapter = instance.requestAdapter(null);
    const device = adapter.requestDevice(null);
    const queue = device.getQueue();

    const shaderModule = try device.createShaderModuleFromFile("shader.wgsl");
    defer shaderModule.deinit();

    const pipelineLayout = device.createPipelineLayout(&wg.WGPUPipelineLayoutDescriptor{ .label = u.stringView("pipeline_layout") });
    defer pipelineLayout.deinit();

    const caps = surface.capabilities();
    defer wg.wgpuSurfaceCapabilitiesFreeMembers(caps);

    const renderPipeline = device.createRenderPipeline(&wg.WGPURenderPipelineDescriptor{
        .label = u.stringView("render_pipeline"),
        .layout = pipelineLayout.pipelineLayout,
        .vertex = wg.WGPUVertexState{
            .module = shaderModule.shaderModule,
            .entryPoint = u.stringView("vs_main"),
        },
        .fragment = &wg.WGPUFragmentState{
            .module = shaderModule.shaderModule,
            .entryPoint = u.stringView("fs_main"),
            .targetCount = 1,
            .targets = &[_]wg.WGPUColorTargetState{
                wg.WGPUColorTargetState{
                    .format = caps.formats[0],
                    .writeMask = wg.WGPUColorWriteMask_All,
                },
            },
        },
        .primitive = wg.WGPUPrimitiveState{
            .topology = wg.WGPUPrimitiveTopology_TriangleList,
        },
        .multisample = wg.WGPUMultisampleState{
            .count = 1,
            .mask = 0xFFFFFFFF,
        },
    });
    defer renderPipeline.deinit();

    const config = @constCast(
        &wg.WGPUSurfaceConfiguration{
            .device = device.device,
            .usage = wg.WGPUTextureUsage_RenderAttachment,
            .format = caps.formats[0],
            .presentMode = wg.WGPUPresentMode_Fifo,
            .alphaMode = caps.alphaModes[0],
        },
    );

    {
        var width: c_int = 0;
        var height: c_int = 0;
        glfw.glfwGetWindowSize(window, &width, &height);
        config.width = @intCast(width);
        config.height = @intCast(height);
    }

    surface.configure(config);

    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        glfw.glfwPollEvents();

        const tryTexture = try surface.getSurfaceTexture();
        const texture = switch (tryTexture) {
            .Success => |texture| texture,
            .Timeout, .Outdated, .Lost => {
                var width: c_int = 0;
                var height: c_int = 0;
                glfw.glfwGetWindowSize(window, &width, &height);
                if (width != 0 and height != 0) {
                    config.width = @intCast(width);
                    config.height = @intCast(height);
                    surface.configure(config);
                }
                continue;
            },
            .OutOfMemory, .DeviceLost, .Force32 => {
                std.log.err("[GraphicsPlatform] get_current_texture status={?}", .{tryTexture});
                std.process.exit(1);
            },
        };

        const frame = texture.createView(null);
        const commandEncoder = device.createCommandEncoder(
            &wg.WGPUCommandEncoderDescriptor{
                .label = u.stringView("command_encoder"),
            },
        );

        const renderPassEncoder = commandEncoder.beginRenderPass(
            &wg.WGPURenderPassDescriptor{
                .label = u.stringView("render_pass_encoder"),
                .colorAttachmentCount = 1,
                .colorAttachments = &[_]wg.WGPURenderPassColorAttachment{
                    wg.WGPURenderPassColorAttachment{
                        .view = frame.textureView,
                        .loadOp = wg.WGPULoadOp_Clear,
                        .storeOp = wg.WGPUStoreOp_Store,
                        .depthSlice = wg.WGPU_DEPTH_SLICE_UNDEFINED,
                        .clearValue = u.colour(0.0, 1.0, 0.0, 1.0),
                    },
                },
            },
        );

        renderPassEncoder.setPipeline(&renderPipeline);
        renderPassEncoder.draw(3, 1, 0, 0);
        renderPassEncoder.end();
        renderPassEncoder.deinit();

        const command_buffer = commandEncoder.finish(
            &wg.WGPUCommandBufferDescriptor{
                .label = u.stringView("command_buffer"),
            },
        );

        queue.submit(
            1,
            &[_]wg.WGPUCommandBuffer{
                command_buffer.commandBuffer,
            },
        );
        surface.present();

        command_buffer.deinit();
        commandEncoder.deinit();
        frame.deinit();
        texture.deinit();
    }

    return .{ .instance = instance, .surface = surface, .adapter = null, .device = null, .config = null };
}

pub fn deinit(self: *@This()) void {
    _ = self;
}
