const GraphicsPlatform = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("cincludes.zig");
const glfw = cincludes.glfw;
const u = @import("util.zig");
const Platform = @import("Platform.zig");
const Filesystem = @import("filesystem/Filesystem.zig");

const w = @import("wgpu");
const wg = w.wg;
const Instance = w.Instance;
const Surface = w.Surface;
const Device = w.Device;
const Adapter = w.Adapter;
const Queue = w.Queue;
const Texture = w.Texture;
const BindGroup = w.BindGroup;
const Buffer = w.Buffer;
const RenderPipeline = w.RenderPipeline;
const RenderPassEncoder = w.RenderPassEncoder;
const ShaderModule = w.ShaderModule;
const wge = @import("wgpu").enums;
const Image = @import("media/Image.zig");
const log = @import("wingman").log;
const nuklear = cincludes.nuklear;
const string_view = w.string_view;

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
// window: *glfw.GLFWwindow,
platform: *Platform,
ui: UIConfig,

pub const UIConfig = struct {
    nkctx: nuklear.nk_context,
    index_buffer: Buffer,
    vertex_buffer: Buffer,
    cmds: nuklear.nk_buffer,
};

pub const Error = error{ FailedToCreateInstance, FailedToInitializeGLFW, FailedToGetSurface };

pub const GraphicsPlatformOptions = struct {
    window_title: []const u8,
    window_width: u32,
    window_height: u32,
    platform: *Platform,
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

export fn glfwErrorCallback(err: c_int, description: [*c]const u8) void {
    log.err(@src(), "GFLW Error ({d}): {s}", .{ err, description });
}

pub fn init(options: GraphicsPlatformOptions) !@This() {
    _ = glfw.glfwSetErrorCallback(glfwErrorCallback);

    log.debug(@src(), "Creating webgpu instance", .{});
    const instance = try Instance.init(&wg.WGPUInstanceDescriptor{
        .features = wg.WGPUInstanceFeatures{
            .timedWaitAnyEnable = 1,
            .timedWaitAnyMaxCount = 10,
        },
    });

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

    // WGPUDevice              Device;
    // int                     NumFramesInFlight = 3;
    // WGPUTextureFormat       RenderTargetFormat = WGPUTextureFormat_Undefined;
    // WGPUTextureFormat       DepthStencilFormat = WGPUTextureFormat_Undefined;
    // WGPUMultisampleState    PipelineMultisampleState = {};

    // ImGui_ImplWGPU_InitInfo()
    // {
    //     PipelineMultisampleState.count = 1;
    //     PipelineMultisampleState.mask = UINT32_MAX;
    //     PipelineMultisampleState.alphaToCoverageEnabled = false;
    // }

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

    const shader_module = try createShaderModuleFromFile(options.platform, &device, "/shader.wgsl");
    //defer shaderModule.deinit();

    const bind_group_layout = device.createBindGroupLayout(&wg.WGPUBindGroupLayoutDescriptor{
        .label = string_view.init("bind_group_layout"),
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
        .label = string_view.init("pipeline_layout"),
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
        .label = string_view.init("render_pipeline"),
        .layout = pipeline_layout.native,
        .vertex = wg.WGPUVertexState{
            .module = shader_module.native,
            .entryPoint = string_view.init("vs_main"),
            .buffers = &[_]wg.WGPUVertexBufferLayout{buffer_layout},
            .bufferCount = 1,
        },
        .fragment = &wg.WGPUFragmentState{
            .module = shader_module.native,
            .entryPoint = string_view.init("fs_main"),
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
        var width: c_int = 640;
        var height: c_int = 480;
        glfw.glfwGetWindowSize(window, &width, &height);
        config.width = @intCast(width);
        config.height = @intCast(height);
    }

    surface.configure(config);

    const image = try Image.init(options.platform, "/tilemap.png");
    const txtr = image.createTexture(&device);
    const txtr_view = txtr.createView(null);

    const vertex_buffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = string_view.init("vertex_buffer"),
        .size = @intCast(@sizeOf(Vertex) * vertices.len),
        .usage = wg.WGPUBufferUsage_Vertex | wg.WGPUBufferUsage_CopyDst,
    });

    // const vertex_buffer = device.createBufferT(Device.BufferDescriptor{
    //     .size = @intCast(@sizeOf(Vertex) * vertices.len),
    //     .usage = wge.BufferUsage.vertex | wge.BufferUsage.copy_dst,
    //     .mapped_at_creation = false,
    // });

    const index_buffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = string_view.init("index_buffer"),
        .size = @intCast(@sizeOf(u16) * indices.len),
        .usage = wg.WGPUBufferUsage_Index | wg.WGPUBufferUsage_CopyDst,
    });

    queue.writeBuffer(vertex_buffer, 0, std.mem.asBytes(&vertices));
    queue.writeBuffer(index_buffer, 0, std.mem.asBytes(&indices));

    // const sampler = device.createSamplerT(Device.CreateSamplerDescriptor{
    //     .address_mode_u = wge.AddressMode.clamp_to_edge,
    //     .address_mode_v = wge.AddressMode.clamp_to_edge,
    //     .address_mode_w = wge.AddressMode.clamp_to_edge,
    //     .mag_filter = wge.FilterMode.linear,
    //     .min_filter = wge.FilterMode.nearest,
    //     .mipmap_filter = wge.MipmapFilterMode.nearest,
    //     .lod_min_clamp = 0.0,
    //     .lod_max_clamp = 32.0,
    //     .compare = wge.CompareFunction.undef,
    //     .max_anisotropy = 1,
    // });

    const sampler = device.createSampler(&wg.WGPUSamplerDescriptor{
        .label = string_view.init("sampler"),
        .addressModeU = @intFromEnum(wge.AddressMode.clamp_to_edge),
        .addressModeV = @intFromEnum(wge.AddressMode.clamp_to_edge),
        .addressModeW = @intFromEnum(wge.AddressMode.clamp_to_edge),
        .magFilter = wg.WGPUFilterMode_Linear,
        .minFilter = wg.WGPUFilterMode_Nearest,
        .mipmapFilter = wg.WGPUFilterMode_Nearest,
        .lodMinClamp = 0.0,
        .lodMaxClamp = 32.0,
        .compare = wg.WGPUCompareFunction_Undefined,
        .maxAnisotropy = 1,
    });

    const img_bind_group = device.createBindGroup(&wg.WGPUBindGroupDescriptor{
        .label = string_view.init("bind_group"),
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
        // .window = window,
        .platform = options.platform,
        .ui = try initUI(options.platform, &device),
    };
}

pub fn start(self: *@This()) !void {
    if (!builtin.target.isWasm()) {
        //while (glfw.glfwWindowShouldClose(self.window) == glfw.GLFW_FALSE) {
        while (self.platform.window.dispatch() == 0) {
            try self.mainLoop();
        }
    } else {
        cincludes.emscripten.emscripten_set_main_loop_arg(animation_frame_cb, @constCast(self), 0, true);
    }
}

pub fn initUI(platform: *Platform, device: *const Device) !UIConfig {
    var nkctx = nuklear.nk_context{};
    const atlas = try platform.allocator.create(nuklear.nk_font_atlas);
    const tex_null = try platform.allocator.create(nuklear.nk_draw_null_texture);
    nuklear.nk_font_atlas_init_default(atlas);
    nuklear.nk_font_atlas_begin(atlas);
    const font = nuklear.nk_font_atlas_add_default(atlas, 13, null);
    var fw: c_int = 0;
    var fh: c_int = 0;
    _ = nuklear.nk_font_atlas_bake(atlas, &fw, &fh, nuklear.NK_FONT_ATLAS_RGBA32);
    nuklear.nk_font_atlas_end(atlas, nuklear.nk_handle_id(1), tex_null);
    nuklear.nk_style_set_font(&nkctx, &font.*.handle);

    _ = nuklear.nk_init_default(&nkctx, &font.*.handle);

    const vertex_buffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = string_view.init("ui_vertex_buffer"),
        .size = 256, // @intCast(@sizeOf(Vertex) * vertices.len),
        .usage = wg.WGPUBufferUsage_CopySrc | wg.WGPUBufferUsage_MapWrite,
    });

    const index_buffer = device.createBuffer(&wg.WGPUBufferDescriptor{
        .label = string_view.init("index_buffer"),
        .size = @intCast(@sizeOf(u16) * indices.len),
        .usage = wg.WGPUBufferUsage_Index | wg.WGPUBufferUsage_CopyDst,
    });

    var cmds: nuklear.nk_buffer = .{};
    nuklear.nk_buffer_init_default(&cmds);

    return .{
        .nkctx = nkctx,
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
        .cmds = cmds,
    };
}

pub fn drawUI(self: *@This(), render_pass_encoder: *const RenderPassEncoder) void {
    const nkctx = @as(*nuklear.nk_context, @constCast(@ptrCast(&self.ui.nkctx)));
    if (nuklear.nk_begin(nkctx, "Show", nuklear.nk_rect(50, 50, 220, 220), nuklear.NK_WINDOW_BORDER | nuklear.NK_WINDOW_MOVABLE | nuklear.NK_WINDOW_CLOSABLE)) {
        nuklear.nk_layout_row_static(nkctx, 30, 80, 1);
        if (nuklear.nk_button_label(nkctx, "button")) {
            log.info(@src(), "testing", .{});
        }
    }

    nuklear.nk_end(nkctx);

    // NOP for now
    const layout = &[_]nuklear.nk_draw_vertex_layout_element{
        nuklear.nk_draw_vertex_layout_element{
            .attribute = nuklear.NK_VERTEX_POSITION,
            .format = nuklear.NK_FORMAT_FLOAT,
            .offset = 0,
        },
        nuklear.nk_draw_vertex_layout_element{
            .attribute = nuklear.NK_VERTEX_TEXCOORD,
            .format = nuklear.NK_FORMAT_FLOAT,
            .offset = 0,
        },
        nuklear.nk_draw_vertex_layout_element{
            .attribute = nuklear.NK_VERTEX_COLOR,
            .format = nuklear.NK_FORMAT_R8G8B8A8,
            .offset = 0,
        },
        // NK_VERTEX_LAYOUT_END
        nuklear.nk_draw_vertex_layout_element{
            .attribute = nuklear.NK_VERTEX_ATTRIBUTE_COUNT,
            .format = nuklear.NK_FORMAT_COUNT,
            .offset = 0,
        },
    };

    const config = nuklear.nk_convert_config{
        .vertex_layout = layout,
        .vertex_size = @sizeOf(Vertex),
        .vertex_alignment = @alignOf(Vertex),
        .arc_segment_count = 22,
        .circle_segment_count = 22,
        .curve_segment_count = 22,
        .global_alpha = 1.0,
    };

    var vbuf: nuklear.nk_buffer = .{};
    var ebuf: nuklear.nk_buffer = .{};

    const map_result = self.ui.vertex_buffer.bufferMappedSync(&self.instance, wge.MapMode.Write, 0, 256);
    switch (map_result) {
        .success => log.debug(@src(), "successfully mapped buffer", .{}),
        else => unreachable, // BANG
    }

    nuklear.nk_buffer_init_fixed(&vbuf, self.ui.vertex_buffer.getMappedRange(0, 256), 256);
    // nuklear.nk_buffer_init_fixed(&ebuf, self.ui.index_buffer.native, 1024);
    _ = nuklear.nk_convert(nkctx, &self.ui.cmds, &vbuf, &ebuf, &config);

    self.ui.vertex_buffer.unmap();

    render_pass_encoder.setVertexBuffer(0, self.ui.vertex_buffer, 0, @sizeOf(Vertex) * 3);
    // render_pass_encoder.setIndexBuffer(self.ui.index_buffer, wg.WGPUIndexFormat_Uint32, 0, 0);

    // const bfr = undefined;
    // // nk_buffer_init(bfr);
    // // #define nk_draw_foreach(cmd,ctx, b) for((cmd)=nk__draw_begin(ctx, b); (cmd)!=0; (cmd)=nk__draw_next(cmd, b, ctx))
    var cmd: [*c]nuklear.nk_draw_command = @constCast(@ptrCast(nuklear.nk__draw_begin(nkctx, &self.ui.cmds)));
    while (cmd != null) {
        //std.log.info("UI_DRAW. {*}", .{cmd});
        // const texture_id = cmd.*.texture.id;

        // render_pass_encoder.setScissorRect(@intFromFloat(cmd.*.clip_rect.x), @intFromFloat(cmd.*.clip_rect.y), @intFromFloat(cmd.*.clip_rect.w), @intFromFloat(cmd.*.clip_rect.h));
        //render_pass_encoder.drawIndexed(0, cmd.*.elem_count, 0, 0, 0);

        cmd = @constCast(nuklear.nk__draw_next(cmd, &self.ui.cmds, nkctx));
    }

    // // nuklear.nk_convert(nkctx, cmds, )

    // #define nk_foreach(c, ctx) for((c) = nk__begin(ctx); (c) != 0; (c) = nk__next(ctx,c))
    // var cmd: [*c]nuklear.nk_command = @constCast(@ptrCast(nuklear.nk__begin(nkctx)));

    // while (cmd != null) {
    //     switch (cmd.*.type) {
    //         nuklear.NK_COMMAND_LINE => log.info(@src(), "Being told to draw a line", .{}),
    //         nuklear.NK_COMMAND_RECT => log.info(@src(), "Being told to draw a rect", .{}),
    //         nuklear.NK_COMMAND_SCISSOR => log.info(@src(), "Being told to draw a scissor", .{}),
    //         nuklear.NK_COMMAND_RECT_FILLED => log.info(@src(), "Being told to draw a rect filled", .{}),
    //         else => log.info(@src(), "Unhandled type {d}", .{cmd.*.type}),
    //     }
    //     cmd = @constCast(nuklear.nk__next(nkctx, cmd));
    // }

    nuklear.nk_clear(nkctx);
    nuklear.nk_buffer_clear(&self.ui.cmds);
}

pub fn mainLoop(self: *@This()) !void {
    glfw.glfwPollEvents();

    const try_texture = try self.surface.getSurfaceTexture();
    const surface_texture = switch (try_texture) {
        .Success => |texture| texture,
        .Timeout, .Outdated, .Lost => {
            const width: c_int = 640;
            const height: c_int = 480;
            // glfw.glfwGetWindowSize(self.window, &width, &height);
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

    self.image.writeToTexture(&self.queue, &self.texture);
    // self.queue.writeImageToTexture(&self.image, &self.texture);
    // queue.copyExternalImageToTexture(&image, &surfaceTexture.texture);

    const frame = surface_texture.texture.createView(null);
    // const frame = txtr.createView(null);
    const command_encoder = self.device.createCommandEncoder(
        &wg.WGPUCommandEncoderDescriptor{
            .label = string_view.init("command_encoder"),
        },
    );

    const time = @mod(cincludes.glfw.glfwGetTime(), 1.0);

    const render_pass_encoder = command_encoder.beginRenderPass(
        &wg.WGPURenderPassDescriptor{
            .label = string_view.init("render_pass_encoder"),
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
    render_pass_encoder.setIndexBuffer(self.index_buffer, wge.IndexFormat.uint16, 0, @sizeOf(u16) * indices.len);
    // renderPassEncoder.draw(3, 1, 0, 0);
    render_pass_encoder.drawIndexed(indices.len, 1, 0, 0, 0);
    render_pass_encoder.end();
    render_pass_encoder.deinit();

    // const ui_frame = surface_texture.texture.createView(null);
    // const ui_pass_encoder = command_encoder.beginRenderPass(&wg.WGPURenderPassDescriptor{
    //     .label = u.stringView("ui_pass_encoder"),
    //     .colorAttachmentCount = 1,
    //     .colorAttachments = &[_]wg.WGPURenderPassColorAttachment{
    //         wg.WGPURenderPassColorAttachment{
    //             .view = ui_frame.native,
    //             .loadOp = wg.WGPULoadOp_Load,
    //             .storeOp = wg.WGPUStoreOp_Store,
    //             .depthSlice = wg.WGPU_DEPTH_SLICE_UNDEFINED,
    //             .clearValue = u.colourR(0.45, 0.55, 0.60, 0.5),
    //         },
    //     },
    // });

    // self.device.tick();

    // // self.drawUI(&ui_pass_encoder);

    // ui_pass_encoder.setPipeline(&self.render_pipeline);
    // ui_pass_encoder.end();
    // ui_pass_encoder.deinit();

    const command_buffer = command_encoder.finish(
        &wg.WGPUCommandBufferDescriptor{
            .label = string_view.init("command_buffer"),
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
    // ui_frame.deinit();
    surface_texture.deinit();
}

pub fn deinit(self: *const @This()) void {
    log.debug(@src(), "Cleaning up", .{});
    self.texture.deinit();
    self.vertex_buffer.deinit();
    self.index_buffer.deinit();
}
