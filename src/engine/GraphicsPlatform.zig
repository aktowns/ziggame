const GraphicsPlatform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const wg = cincludes.wg;
const glfw = cincludes.glfw;
const u = @import("util.zig");
const Platform = @import("Platform.zig");
const Filesystem = @import("filesystem/Filesystem.zig");

const w = @import("wgpu/wgpu.zig");
const Instance = w.Instance;
const Surface = w.Surface;
const Device = w.Device;
const Adapter = w.Adapter;
const Queue = w.Queue;
const Texture = w.Texture;
const BindGroup = w.BindGroup;
const Buffer = w.Buffer;
const RenderPipeline = w.RenderPipeline;
const ShaderModule = w.ShaderModule;
const Image = @import("media/Image.zig");
const log = @import("log.zig");

instance: Instance,
surface: Surface,
adapter: Adapter,
device: Device,
queue: Queue,
config: *wg.WGPUSurfaceConfiguration,
render_pipeline: RenderPipeline,
image: Image,
texture: Texture,
img_bind_group: BindGroup,
vertex_buffer: Buffer,
index_buffer: Buffer,
window: *glfw.GLFWwindow,

pub const Error = error{ FailedToCreateInstance, FailedToInitializeGLFW, FailedToGetSurface };

pub const GraphicsPlatformOptions = struct {
    window_title: []const u8,
    window_width: u32,
    window_height: u32,
    platform: Platform,
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
//      .      ..
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

pub fn createShaderModuleFromFile(platform: *const Platform, device: *const Device, name: [:0]const u8) !ShaderModule {
    log.debug(@src(), "Opening shader at {s}", .{name});

    const buffer = try platform.filesystem.readFile(name, Filesystem.ResourceType.Shaders);

    return device.createShaderModuleFromSource(@constCast(buffer));
}

export fn animation_frame_cb(user_data: ?*anyopaque) void {
    const self = @as(*@This(), @alignCast(@ptrCast(user_data)));
    self.mainLoop() catch |err| {
        std.log.debug("mainloop error {?}", .{err});
    };
}

pub fn init(options: GraphicsPlatformOptions) !@This() {
    log.debug(@src(), "Creating webgpu instance", .{});

    const instance = try Instance.init(&options.platform);

    log.debug(@src(), "Initializing GLFW", .{});
    if (glfw.glfwInit() != 1) {
        std.log.err("failed to initialize glfw: {?s}", .{"?"});
        return Error.FailedToInitializeGLFW;
    }

    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);

    if (builtin.target.isWasm()) {
        log.debug(@src(), "forcing emscripten selector", .{});
        cincludes.glfw.emscripten_glfw_set_next_window_canvas_selector("#canvas");
    }

    const window = glfw.glfwCreateWindow(
        @intCast(options.window_width),
        @intCast(options.window_height),
        @as([*c]const u8, @ptrCast(options.window_title)),
        null,
        null,
    ).?;

    const surface_source = options.platform.getSurfaceSource(window);

    log.debug(@src(), "Creating surface (from source {?})", .{surface_source});
    const surface = try instance.createSurfaceFromNative(surface_source);

    const adapter_options: *wg.WGPURequestAdapterOptions = if (!builtin.target.isWasm()) opts: {
        const toggles = [_][*c]const u8{ "dump_shaders", "disable_symbol_renaming" };
        const toggles_desc = wg.WGPUDawnTogglesDescriptor{
            .enabledToggles = @ptrCast(&toggles),
            .enabledToggleCount = toggles.len,
        };
        break :opts @constCast(@ptrCast(&wg.WGPURequestAdapterOptions{
            .compatibleSurface = surface.native,
            .nextInChain = @ptrCast(&toggles_desc),
        }));
    } else @constCast(&wg.WGPURequestAdapterOptions{ .compatibleSurface = surface.native });
    const adapter = instance.requestAdapter(adapter_options);

    const device = adapter.requestDevice(null);
    const queue = device.getQueue();

    const shader_module = try createShaderModuleFromFile(&options.platform, &device, "/shader.wgsl");
    //defer shaderModule.deinit();

    const bind_group_layout = device.createBindGroupLayout(&wg.WGPUBindGroupLayoutDescriptor{
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

    const pipeline_layout = device.createPipelineLayout(&wg.WGPUPipelineLayoutDescriptor{
        .label = u.stringView("pipeline_layout"),
        .bindGroupLayouts = &[_]wg.WGPUBindGroupLayout{bind_group_layout.native},
        .bindGroupLayoutCount = 1,
    });
    // defer pipelineLayout.deinit();

    const caps = surface.capabilities();
    //defer wg.wgpuSurfaceCapabilitiesFreeMembers(caps);

    const buffer_layout = wg.WGPUVertexBufferLayout{
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

    const render_pipeline = device.createRenderPipeline(&wg.WGPURenderPipelineDescriptor{
        .label = u.stringView("render_pipeline"),
        .layout = pipeline_layout.native,
        .vertex = wg.WGPUVertexState{
            .module = shader_module.native,
            .entryPoint = u.stringView("vs_main"),
            .buffers = &[_]wg.WGPUVertexBufferLayout{buffer_layout},
            .bufferCount = 1,
        },
        .fragment = &wg.WGPUFragmentState{
            .module = shader_module.native,
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
    // defer renderPipeline.deinit();

    const config = @constCast(
        &wg.WGPUSurfaceConfiguration{
            .device = device.native,
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

    const image = try Image.init(&options.platform, "/tilemap.png");
    const txtr = device.createTextureFromImage(&image);
    const txtr_view = txtr.createView(null);

    const vertex_buffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = u.stringView("vertex_buffer"),
        .size = @intCast(@sizeOf(Vertex) * vertices.len),
        .usage = wg.WGPUBufferUsage_Vertex | wg.WGPUBufferUsage_CopyDst,
    });

    const index_buffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = u.stringView("index_buffer"),
        .size = @intCast(@sizeOf(u16) * indices.len),
        .usage = wg.WGPUBufferUsage_Index | wg.WGPUBufferUsage_CopyDst,
    });

    queue.writeBuffer(vertex_buffer, 0, std.mem.asBytes(&vertices));
    queue.writeBuffer(index_buffer, 0, std.mem.asBytes(&indices));

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

    const img_bind_group = device.createBindGroup(&wg.WGPUBindGroupDescriptor{
        .label = u.stringView("bind_group"),
        .layout = bind_group_layout.native,
        .entryCount = 2,
        .entries = &[_]wg.WGPUBindGroupEntry{
            wg.WGPUBindGroupEntry{
                .binding = 0,
                .textureView = txtr_view.native,
            },
            wg.WGPUBindGroupEntry{
                .binding = 1,
                .sampler = sampler.native,
            },
        },
    });

    //    image.deinit();

    return .{
        .instance = instance,
        .surface = surface,
        .adapter = adapter,
        .device = device,
        .config = config,
        .queue = queue,
        .image = image,
        .texture = txtr,
        .render_pipeline = render_pipeline,
        .img_bind_group = img_bind_group,
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
        .window = window,
    };
}

pub fn start(self: *const @This()) !void {
    if (!builtin.target.isWasm()) {
        while (glfw.glfwWindowShouldClose(self.window) == glfw.GLFW_FALSE) {
            try self.mainLoop();
        }
    } else {
        cincludes.emscripten.emscripten_set_main_loop_arg(animation_frame_cb, @constCast(self), 0, true);
    }
}

pub fn mainLoop(self: *const @This()) !void {
    glfw.glfwPollEvents();

    const try_texture = try self.surface.getSurfaceTexture();
    const surface_texture = switch (try_texture) {
        .Success => |texture| texture,
        .Timeout, .Outdated, .Lost => {
            var width: c_int = 0;
            var height: c_int = 0;
            glfw.glfwGetWindowSize(self.window, &width, &height);
            if (width != 0 and height != 0) {
                self.config.width = @intCast(width);
                self.config.height = @intCast(height);
                self.surface.configure(self.config);
            }
            return;
        },
        .OutOfMemory, .DeviceLost, .Force32 => {
            std.log.err("[GraphicsPlatform] get_current_texture status={?}", .{try_texture});
            std.process.exit(1);
        },
    };

    self.queue.writeImageToTexture(&self.image, &self.texture);
    // queue.copyExternalImageToTexture(&image, &surfaceTexture.texture);

    const frame = surface_texture.texture.createView(null);
    // const frame = txtr.createView(null);
    const command_encoder = self.device.createCommandEncoder(
        &wg.WGPUCommandEncoderDescriptor{
            .label = u.stringView("command_encoder"),
        },
    );

    const time = @mod(cincludes.glfw.glfwGetTime(), 1.0);

    const render_pass_encoder = command_encoder.beginRenderPass(
        &wg.WGPURenderPassDescriptor{
            .label = u.stringView("render_pass_encoder"),
            .colorAttachmentCount = 1,
            .colorAttachments = &[_]wg.WGPURenderPassColorAttachment{
                wg.WGPURenderPassColorAttachment{
                    .view = frame.native,
                    .loadOp = wg.WGPULoadOp_Clear,
                    .storeOp = wg.WGPUStoreOp_Store,
                    .depthSlice = wg.WGPU_DEPTH_SLICE_UNDEFINED,
                    .clearValue = u.colourR(time, 0.5, 0.5, 1.0),
                },
            },
        },
    );

    render_pass_encoder.setPipeline(&self.render_pipeline);
    render_pass_encoder.setBindGroup(0, &self.img_bind_group, &.{});
    render_pass_encoder.setVertexBuffer(0, self.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    render_pass_encoder.setIndexBuffer(self.index_buffer, wg.WGPUIndexFormat_Uint16, 0, @sizeOf(u16) * indices.len);
    // renderPassEncoder.draw(3, 1, 0, 0);
    render_pass_encoder.drawIndexed(indices.len, 1, 0, 0, 0);
    render_pass_encoder.end();
    render_pass_encoder.deinit();

    const command_buffer = command_encoder.finish(
        &wg.WGPUCommandBufferDescriptor{
            .label = u.stringView("command_buffer"),
        },
    );

    self.queue.submit(
        1,
        &[_]wg.WGPUCommandBuffer{
            command_buffer.native,
        },
    );
    if (!builtin.target.isWasm()) {
        self.surface.present();
    }

    command_buffer.deinit();
    command_encoder.deinit();
    frame.deinit();
    surface_texture.deinit();
}

pub fn deinit(self: *const @This()) void {
    log.debug(@src(), "Cleaning up", .{});
    self.texture.deinit();
    self.vertex_buffer.deinit();
    self.index_buffer.deinit();
}
