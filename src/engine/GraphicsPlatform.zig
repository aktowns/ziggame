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
const Texture = w.Texture;
const Image = @import("media/Image.zig");

instance: Instance,
surface: Surface,
adapter: wg.WGPUAdapter,
device: wg.WGPUDevice,
config: ?*wg.WGPUSurfaceConfiguration,

pub const Error = error{ FailedToCreateInstance, FailedToInitializeGLFW, FailedToGetSurface };

pub const GraphicsPlatformOptions = struct {
    windowTitle: []const u8,
    windowWidth: u32,
    windowHeight: u32,
    osPlatform: Platform,
};

const Vertex = struct {
    position: [3]f32,
    tex_coords: [2]f32,
};

//      -0.5              0.0               0.5
// 0.5  ----------------------------------------
//      |
//      |
// 0.0  |
//      |
//      |
// -0.5 |----------------------------------------
//
//  (0) ......... (1)
//      ..      .
//      . .     .
//      .  .    .
//      .   .   .
//      .    .  .
//      .     . .
//  (3) ......... (2)
//
// 0.0, 0.0 => top left tex coord == top left
// 1.0, 0.0 => top right tex coord == top right
// 1.0, 1.0 => bottom right tex coord == bottom right
// 0.0, 1.0 => bottom left tex coord == bottom left
//
const vertices: [4]Vertex = .{
    .{ .position = .{ -0.5, 0.5, 0.0 }, .tex_coords = .{ 0.0, 0.0 } }, // TOP LEFT (0)
    .{ .position = .{ 0.5, 0.5, 0.0 }, .tex_coords = .{ 1.0, 0.0 } }, // TOP RIGHT (1)
    .{ .position = .{ 0.5, -0.5, 0.0 }, .tex_coords = .{ 1.0, 1.0 } }, // BOTTOM RIGHT (2)
    //  .{ .position = .{ 0.5, -0.5, 0.0 }, .tex_coords = .{ 0.0, 1.0 } }, // BOTTOM RIGHT (2)
    .{ .position = .{ -0.5, -0.5, 0.0 }, .tex_coords = .{ 0.0, 1.0 } }, // BOTTOM LEFT (3)
    //   .{ .position = .{ -0.5, -0.5, 0.0 }, .tex_coords = .{ 1.0, 1.0 } }, // TOP LEFT (0)
};

const indices: [6]u16 = .{ 0, 1, 2, 2, 3, 0 };

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

    const window = glfw.glfwCreateWindow(
        @intCast(options.windowWidth),
        @intCast(options.windowHeight),
        @as([*c]const u8, @ptrCast(options.windowTitle)),
        null,
        null,
    ).?;

    // const surface_descriptor = options.osPlatform.surface_descriptor(window);
    const surfaceSource = options.osPlatform.getSurfaceSource(window) catch |err| {
        std.log.err("Failed to get surface: {?}", .{err});
        return Error.FailedToGetSurface;
    };

    std.log.debug("[GraphicsPlatform] Creating surface (from source {?})", .{surfaceSource});
    const surface = try instance.createSurfaceFromSource(surfaceSource);

    const toggles = [_][*c]const u8{ "dump_shaders", "disable_symbol_renaming" };
    const togglesDesc = wg.WGPUDawnTogglesDescriptor{
        .enabledToggles = @ptrCast(&toggles),
        .enabledToggleCount = toggles.len,
    };
    const adapter = instance.requestAdapter(@ptrCast(&wg.WGPUDeviceDescriptor{
        .nextInChain = @ptrCast(&togglesDesc),
    }));
    const device = adapter.requestDevice(null);
    const queue = device.getQueue();

    const shaderModule = try device.createShaderModuleFromFile("shader.wgsl");
    defer shaderModule.deinit();

    const bindGroupLayout = device.createBindGroupLayout(&wg.WGPUBindGroupLayoutDescriptor{
        .label = u.stringView("bind_group_layout"),
        .entryCount = 2,
        .entries = &[_]wg.WGPUBindGroupLayoutEntry{
            wg.WGPUBindGroupLayoutEntry{
                .binding = 0,
                .visibility = wg.WGPUShaderStage_Fragment,
                .texture = wg.WGPUTextureBindingLayout{
                    .sampleType = wg.WGPUTextureSampleType_Float,
                    .viewDimension = wg.WGPUTextureViewDimension_2D,
                    .multisampled = 0,
                },
            },
            wg.WGPUBindGroupLayoutEntry{
                .binding = 1,
                .visibility = wg.WGPUShaderStage_Fragment,
                .sampler = wg.WGPUSamplerBindingLayout{
                    .type = wg.WGPUSamplerBindingType_Filtering,
                },
            },
        },
    });

    const pipelineLayout = device.createPipelineLayout(&wg.WGPUPipelineLayoutDescriptor{
        .label = u.stringView("pipeline_layout"),
        .bindGroupLayouts = &[_]wg.WGPUBindGroupLayout{bindGroupLayout.bindGroupLayout},
        .bindGroupLayoutCount = 1,
    });
    defer pipelineLayout.deinit();

    const caps = surface.capabilities();
    defer wg.wgpuSurfaceCapabilitiesFreeMembers(caps);

    const bufferLayout = wg.WGPUVertexBufferLayout{
        .arrayStride = @sizeOf(Vertex),
        .stepMode = wg.WGPUVertexStepMode_Vertex,
        .attributes = &[_]wg.WGPUVertexAttribute{
            // Position
            wg.WGPUVertexAttribute{
                .offset = 0,
                .shaderLocation = 0,
                .format = wg.WGPUVertexFormat_Float32x3,
            },
            // Colour
            wg.WGPUVertexAttribute{
                .offset = @sizeOf(f32) * 3,
                .shaderLocation = 1,
                .format = wg.WGPUVertexFormat_Float32x2,
            },
        },
        .attributeCount = 2,
    };

    const renderPipeline = device.createRenderPipeline(&wg.WGPURenderPipelineDescriptor{
        .label = u.stringView("render_pipeline"),
        .layout = pipelineLayout.pipelineLayout,
        .vertex = wg.WGPUVertexState{
            .module = shaderModule.shaderModule,
            .entryPoint = u.stringView("vs_main"),
            .buffers = &[_]wg.WGPUVertexBufferLayout{bufferLayout},
            .bufferCount = 1,
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

    const image = try Image.init(options.osPlatform.allocator, "maps/tilemap.png");
    const txtr = device.createTextureFromImage(&image);
    const txtrView = txtr.createView(null);

    const vertexBuffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = u.stringView("vertex_buffer"),
        .size = @intCast(@sizeOf(Vertex) * vertices.len),
        .usage = wg.WGPUBufferUsage_Vertex | wg.WGPUBufferUsage_CopyDst,
    });

    const indexBuffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = u.stringView("index_buffer"),
        .size = @intCast(@sizeOf(u16) * indices.len),
        .usage = wg.WGPUBufferUsage_Index | wg.WGPUBufferUsage_CopyDst,
    });

    queue.writeBuffer(vertexBuffer, 0, std.mem.asBytes(&vertices));
    queue.writeBuffer(indexBuffer, 0, std.mem.asBytes(&indices));

    const sampler = device.createSampler(&wg.WGPUSamplerDescriptor{
        .label = u.stringView("sampler"),
        .addressModeU = wg.WGPUAddressMode_ClampToEdge,
        .addressModeV = wg.WGPUAddressMode_ClampToEdge,
        .addressModeW = wg.WGPUAddressMode_ClampToEdge,
        .magFilter = wg.WGPUFilterMode_Linear,
        .minFilter = wg.WGPUFilterMode_Nearest,
        .mipmapFilter = wg.WGPUFilterMode_Nearest,
        .lodMinClamp = 0.0,
        .lodMaxClamp = 32.0,
        .compare = wg.WGPUCompareFunction_Undefined,
        .maxAnisotropy = 1,
    });

    const imgBindGroup = device.createBindGroup(&wg.WGPUBindGroupDescriptor{
        .label = u.stringView("bind_group"),
        .layout = bindGroupLayout.bindGroupLayout,
        .entryCount = 2,
        .entries = &[_]wg.WGPUBindGroupEntry{
            wg.WGPUBindGroupEntry{
                .binding = 0,
                .textureView = txtrView.textureView,
            },
            wg.WGPUBindGroupEntry{
                .binding = 1,
                .sampler = sampler.sampler,
            },
        },
    });

    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        glfw.glfwPollEvents();

        const tryTexture = try surface.getSurfaceTexture();
        const surfaceTexture = switch (tryTexture) {
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

        queue.writeImageToTexture(&image, &txtr);
        // queue.copyExternalImageToTexture(&image, &surfaceTexture.texture);

        const frame = surfaceTexture.texture.createView(null);
        // const frame = txtr.createView(null);
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
                        .clearValue = u.colour(0.5, 0.5, 0.5, 1.0),
                    },
                },
            },
        );

        renderPassEncoder.setPipeline(&renderPipeline);
        renderPassEncoder.setBindGroup(0, &imgBindGroup, &.{});
        renderPassEncoder.setVertexBuffer(0, vertexBuffer, 0, @sizeOf(Vertex) * vertices.len);
        renderPassEncoder.setIndexBuffer(indexBuffer, wg.WGPUIndexFormat_Uint16, 0, @sizeOf(u16) * indices.len);
        // renderPassEncoder.draw(3, 1, 0, 0);
        renderPassEncoder.drawIndexed(indices.len, 1, 0, 0, 0);
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
        surfaceTexture.deinit();
    }

    image.deinit();

    return .{
        .instance = instance,
        .surface = surface,
        .adapter = null,
        .device = null,
        .config = null,
    };
}

pub fn deinit(self: *@This()) void {
    _ = self;
}
