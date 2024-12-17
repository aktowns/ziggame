const std = @import("std");
const wgpu = @cImport({
    @cInclude("wgpu/wgpu.h");
});

const builtin = @import("builtin");

const glfw = @cImport({
    @cDefine(glfwDefine(), "1");
    @cInclude("GLFW/glfw3.h");
    @cInclude("GLFW/glfw3native.h");
});

const State = struct {
    instance: wgpu.WGPUInstance,
    surface: wgpu.WGPUSurface,
    adapter: wgpu.WGPUAdapter,
    device: wgpu.WGPUDevice,
    config: ?*wgpu.WGPUSurfaceConfiguration,
};

var state: State = State{ .instance = null, .surface = null, .adapter = null, .device = null, .config = null };

fn glfwDefine() []const u8 {
    return switch (comptime builtin.os.tag) {
        .macos => "GLFW_EXPOSE_NATIVE_COCOA",
        .linux => "GLFW_EXPOSE_NATIVE_WAYLAND",
        .windows => "GLFW_EXPOSE_NATIVE_WIN32",
        else => std.debug.panic("Unhandled operating system: {s}", .{builtin.os.tag}),
    };
}

export fn handle_request_adapter(status: wgpu.WGPURequestAdapterStatus, adapter: wgpu.WGPUAdapter, message: [*c]const u8, userData: ?*anyopaque) void {
    if (status == wgpu.WGPURequestAdapterStatus_Success) {
        @as(?*State, @alignCast(@ptrCast(userData))).?.adapter = adapter;
    } else {
        std.log.err("request_adapter status={d} message={s}", .{ status, message });
    }
}

export fn handle_request_device(status: wgpu.WGPURequestDeviceStatus, device: wgpu.WGPUDevice, message: [*c]const u8, userData: ?*anyopaque) void {
    if (status == wgpu.WGPURequestDeviceStatus_Success) {
        @as(?*State, @alignCast(@ptrCast(userData))).?.device = device;
    } else {
        std.log.err("request_device status={d} message={s}", .{ status, message });
    }
}

export fn handle_glfw_key(window: ?*glfw.GLFWwindow, key: i32, scancode: i32, action: i32, mods: i32) void {
    _ = scancode;
    _ = mods;

    if (key == glfw.GLFW_KEY_R and (action == glfw.GLFW_PRESS or action == glfw.GLFW_REPEAT)) {
        const userData = @as(?*State, @alignCast(@ptrCast(glfw.glfwGetWindowUserPointer(window)))).?;

        var report: wgpu.WGPUGlobalReport = .{};
        wgpu.wgpuGenerateReport(userData.instance, &report);
        print_global_report(report);
    }
}

fn print_adapter_info(adapter: wgpu.WGPUAdapter) void {
    var info: wgpu.WGPUAdapterInfo = .{};
    wgpu.wgpuAdapterGetInfo(adapter, &info);

    std.log.info("description: {s}", .{info.description});
    std.log.info("vendor: {s}", .{info.vendor});
    std.log.info("architecture: {s}", .{info.architecture});
    std.log.info("device: {s}", .{info.device});
    std.log.info("backend type: {d}", .{info.backendType});
    std.log.info("adapter type: {d}", .{info.adapterType});
    std.log.info("vendorID: {x}", .{info.vendorID});
    std.log.info("deviceID: {x}", .{info.deviceID});
    wgpu.wgpuAdapterInfoFreeMembers(info);
}

inline fn print_registry_report(report: wgpu.WGPURegistryReport, pfx: [:0]const u8) void {
    std.log.info("  {s}.numAllocated={d}", .{ pfx, report.numAllocated });
    std.log.info("  {s}.numKeptFromUser={d}", .{ pfx, report.numKeptFromUser });
    std.log.info("  {s}.numReleasedFromUser={d}", .{ pfx, report.numReleasedFromUser });
    std.log.info("  {s}.numError={d}", .{ pfx, report.numError });
    std.log.info("  {s}.elementSize={d}", .{ pfx, report.elementSize });
}

inline fn print_hub_report(report: wgpu.WGPUHubReport, pfx: [:0]const u8) void {
    print_registry_report(report.adapters, pfx ++ ".adapter");
    print_registry_report(report.devices, pfx ++ ".devices");
    print_registry_report(report.queues, pfx ++ ".queues");
    print_registry_report(report.pipelineLayouts, pfx ++ ".pipelineLayouts");
    print_registry_report(report.shaderModules, pfx ++ ".shaderModules");
    print_registry_report(report.bindGroupLayouts, pfx ++ ".bindGroupLayouts");
    print_registry_report(report.bindGroups, pfx ++ ".bindGroups");
    print_registry_report(report.commandBuffers, pfx ++ ".commandBuffers");
    print_registry_report(report.renderBundles, pfx ++ ".renderBundles");
    print_registry_report(report.renderPipelines, pfx ++ ".renderPipelines");
    print_registry_report(report.computePipelines, pfx ++ ".computePipelines");
    print_registry_report(report.querySets, pfx ++ ".querySets");
    print_registry_report(report.textures, pfx ++ ".textures");
    print_registry_report(report.textureViews, pfx ++ ".textureViews");
    print_registry_report(report.samplers, pfx ++ ".samplers");
}

fn load_shader_module(device: wgpu.WGPUDevice, name: [:0]const u8) anyerror!wgpu.WGPUShaderModule {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const path = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(path);

    const shader_path = try std.fs.path.join(allocator, &[_][]const u8{ path, "shaders", name });
    defer allocator.free(shader_path);

    std.log.info("[Shaders] opening path {s}", .{shader_path});

    const file = try std.fs.cwd().openFile(shader_path, .{});
    defer file.close();

    const stat = try file.stat();
    // const buffer = try file.readToEndAlloc(allocator, stat.size);
    const buffer = try file.readToEndAllocOptions(allocator, stat.size, null, @alignOf(u8), 0);
    defer allocator.free(buffer);

    std.log.info("[Shaders] loaded shader {s}", .{buffer});

    return wgpu.wgpuDeviceCreateShaderModule(device, &wgpu.WGPUShaderModuleDescriptor{ .label = name, .nextInChain = @as(*wgpu.WGPUChainedStruct, @constCast(@ptrCast(&wgpu.WGPUShaderModuleWGSLDescriptor{ .chain = wgpu.WGPUChainedStruct{ .sType = wgpu.WGPUSType_ShaderModuleWGSLDescriptor }, .code = buffer.ptr }))) });
}

fn print_global_report(report: wgpu.WGPUGlobalReport) void {
    std.log.info("struct WGPUGlobalReport {{", .{});
    print_registry_report(report.surfaces, "surfaces");

    switch (report.backendType) {
        wgpu.WGPUBackendType_D3D12 => print_hub_report(report.dx12, "dx12"),
        wgpu.WGPUBackendType_Metal => print_hub_report(report.metal, "metal"),
        wgpu.WGPUBackendType_Vulkan => print_hub_report(report.vulkan, "vulkan"),
        wgpu.WGPUBackendType_OpenGL => print_hub_report(report.gl, "gl"),
        else => std.log.err("invalid backend type: {d}", .{report.backendType}),
    }
    std.log.info("}}", .{});
}

pub fn getMacOSSurface(window: *glfw.GLFWwindow) wgpu.WGPUSurface {
    const objc = @import("objc");

    const ns_window = glfw.glfwGetCocoaWindow(window);
    const objc_window = objc.Object.fromId(ns_window);

    const objc_view = objc_window.getProperty(objc.Object, "contentView");

    _ = objc_view.msgSend(objc.Object, "setWantsLayer:", .{true});
    const CAMetalLayer = objc.getClass("CAMetalLayer").?;
    const layer = CAMetalLayer.msgSend(objc.Object, "layer", .{});
    _ = objc_view.msgSend(objc.Object, "setLayer:", .{layer});

    const chain: *wgpu.WGPUChainedStruct = @constCast(@ptrCast(&wgpu.WGPUSurfaceDescriptorFromMetalLayer{ .layer = layer.value, .chain = wgpu.WGPUChainedStruct{ .sType = wgpu.WGPUSType_SurfaceDescriptorFromMetalLayer } }));
    const desc = &wgpu.WGPUSurfaceDescriptor{ .nextInChain = chain };

    return wgpu.wgpuInstanceCreateSurface(state.instance, desc);
}

pub fn getLinuxSurface(window: *glfw.GLFWwindow) wgpu.WGPUSurface {
    const wl_display = glfw.glfwGetWaylandDisplay();
    const wl_surface = glfw.glfwGetWaylandWindow(window);

    const chain: *wgpu.WGPUChainedStruct = @constCast(@ptrCast(&wgpu.WGPUSurfaceDescriptorFromWaylandSurface{ .display = wl_display, .surface = wl_surface, .chain = wgpu.WGPUChainedStruct{ .sType = wgpu.WGPUSType_SurfaceDescriptorFromWaylandSurface } }));
    const desc = &wgpu.WGPUSurfaceDescriptor{ .nextInChain = chain };

    return wgpu.wgpuInstanceCreateSurface(state.instance, desc);
}

pub fn getWindowsSurface(window: *glfw.GLFWwindow) wgpu.WGPUSurface {
    const hwnd = glfw.glfwGetWin32Window(window);
    const hinstance = glfw.GetModuleHandle(null);

    const chain: *wgpu.WGPUChainedStruct = @constCast(@ptrCast(&wgpu.WGPUSurfaceDescriptorFromWindowsHWND{ .hinstance = hinstance, .hwnd = hwnd, .chain = wgpu.WGPUChainedStruct{ .sType = wgpu.WGPUSType_SurfaceDescriptorFromWindowsHWND } }));
    const desc = &wgpu.WGPUSurfaceDescriptor{ .nextInChain = chain };

    return wgpu.wgpuInstanceCreateSurface(state.instance, desc);
}

pub fn wgpuInit() anyerror!void {
    state.instance = wgpu.wgpuCreateInstance(null).?;

    // if (instance == null) {
    //     std.log.err("failed to initialize wgpu: {?s}", .{"?"});
    //     std.process.exit(1);
    // }

    if (glfw.glfwInit() != 1) {
        std.log.err("failed to initialize glfw: {?s}", .{"?"});
        std.process.exit(1);
    }

    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);
    const window = glfw.glfwCreateWindow(640, 480, "aa", null, null).?;

    glfw.glfwSetWindowUserPointer(window, &state);
    _ = glfw.glfwSetKeyCallback(window, handle_glfw_key);

    state.surface = switch (comptime builtin.target.os.tag) {
        .macos => getMacOSSurface(window),
        .linux => getLinuxSurface(window),
        .windows => getWindowsSurface(window),
        else => {
            std.log.err("Operating system not supported {s}", .{builtin.target.os.tag});
            std.process.exit(1);
        },
    };

    wgpu.wgpuInstanceRequestAdapter(state.instance, &.{ .compatibleSurface = state.surface }, handle_request_adapter, &state);
    print_adapter_info(state.adapter);

    wgpu.wgpuAdapterRequestDevice(state.adapter, null, handle_request_device, &state);

    const queue = wgpu.wgpuDeviceGetQueue(state.device);

    const shader_module = try load_shader_module(state.device, "shader.wgsl");
    defer wgpu.wgpuShaderModuleRelease(shader_module);

    const pipeline_layout = wgpu.wgpuDeviceCreatePipelineLayout(state.device, &wgpu.WGPUPipelineLayoutDescriptor{
        .label = "pipeline_layout",
    });
    defer wgpu.wgpuPipelineLayoutRelease(pipeline_layout);

    var surface_capabilities: wgpu.WGPUSurfaceCapabilities = .{};
    wgpu.wgpuSurfaceGetCapabilities(state.surface, state.adapter, &surface_capabilities);
    defer wgpu.wgpuSurfaceCapabilitiesFreeMembers(surface_capabilities);

    const render_pipeline = wgpu.wgpuDeviceCreateRenderPipeline(state.device, &wgpu.WGPURenderPipelineDescriptor{ .label = "render_pipeline", .layout = pipeline_layout, .vertex = wgpu.WGPUVertexState{
        .module = shader_module,
        .entryPoint = "vs_main",
    }, .fragment = &wgpu.WGPUFragmentState{ .module = shader_module, .entryPoint = "fs_main", .targetCount = 1, .targets = &[_]wgpu.WGPUColorTargetState{wgpu.WGPUColorTargetState{ .format = surface_capabilities.formats[0], .writeMask = wgpu.WGPUColorWriteMask_All }} }, .primitive = wgpu.WGPUPrimitiveState{
        .topology = wgpu.WGPUPrimitiveTopology_TriangleList,
    }, .multisample = wgpu.WGPUMultisampleState{ .count = 1, .mask = 0xFFFFFFFF } });
    defer wgpu.wgpuRenderPipelineRelease(render_pipeline);

    state.config = @constCast(&wgpu.WGPUSurfaceConfiguration{ .device = state.device, .usage = wgpu.WGPUTextureUsage_RenderAttachment, .format = surface_capabilities.formats[0], .presentMode = wgpu.WGPUPresentMode_Fifo, .alphaMode = surface_capabilities.alphaModes[0] });

    {
        var width: c_int = 0;
        var height: c_int = 0;
        glfw.glfwGetWindowSize(window, &width, &height);
        state.config.?.width = @intCast(width);
        state.config.?.height = @intCast(height);
    }

    wgpu.wgpuSurfaceConfigure(state.surface, state.config);

    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        glfw.glfwPollEvents();

        var surface_texture: wgpu.WGPUSurfaceTexture = .{};
        wgpu.wgpuSurfaceGetCurrentTexture(state.surface, &surface_texture);
        switch (surface_texture.status) {
            wgpu.WGPUSurfaceGetCurrentTextureStatus_Success => {},
            wgpu.WGPUSurfaceGetCurrentTextureStatus_Timeout, wgpu.WGPUSurfaceGetCurrentTextureStatus_Outdated, wgpu.WGPUSurfaceGetCurrentTextureStatus_Lost => {
                if (surface_texture.texture != null) {
                    wgpu.wgpuTextureRelease(surface_texture.texture);
                }
                var width: c_int = 0;
                var height: c_int = 0;
                glfw.glfwGetWindowSize(window, &width, &height);
                if (width != 0 and height != 0) {
                    state.config.?.width = @intCast(width);
                    state.config.?.height = @intCast(height);
                    wgpu.wgpuSurfaceConfigure(state.surface, state.config);
                }
            },
            wgpu.WGPUSurfaceGetCurrentTextureStatus_OutOfMemory, wgpu.WGPUSurfaceGetCurrentTextureStatus_DeviceLost, wgpu.WGPUSurfaceGetCurrentTextureStatus_Force32 => {
                std.log.err("get_current_texture status={d}", .{surface_texture.status});
                std.process.exit(1);
            },
            else => {
                std.log.err("UNHANDLED get_current_texture status={d}", .{surface_texture.status});
                std.process.exit(1);
            },
        }

        const frame = wgpu.wgpuTextureCreateView(surface_texture.texture, null);
        const command_encoder = wgpu.wgpuDeviceCreateCommandEncoder(state.device, &wgpu.WGPUCommandEncoderDescriptor{ .label = "command_encoder" });

        const render_pass_encoder = wgpu.wgpuCommandEncoderBeginRenderPass(command_encoder, &wgpu.WGPURenderPassDescriptor{ .label = "render_pass_encoder", .colorAttachmentCount = 1, .colorAttachments = &[_]wgpu.WGPURenderPassColorAttachment{wgpu.WGPURenderPassColorAttachment{ .view = frame, .loadOp = wgpu.WGPULoadOp_Clear, .storeOp = wgpu.WGPUStoreOp_Store, .depthSlice = wgpu.WGPU_DEPTH_SLICE_UNDEFINED, .clearValue = wgpu.WGPUColor{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 } }} });

        wgpu.wgpuRenderPassEncoderSetPipeline(render_pass_encoder, render_pipeline);
        wgpu.wgpuRenderPassEncoderDraw(render_pass_encoder, 3, 1, 0, 0);
        wgpu.wgpuRenderPassEncoderEnd(render_pass_encoder);
        wgpu.wgpuRenderPassEncoderRelease(render_pass_encoder);

        const command_buffer = wgpu.wgpuCommandEncoderFinish(command_encoder, &wgpu.WGPUCommandBufferDescriptor{ .label = "command_buffer" });

        wgpu.wgpuQueueSubmit(queue, 1, &[_]wgpu.WGPUCommandBuffer{command_buffer});
        wgpu.wgpuSurfacePresent(state.surface);

        wgpu.wgpuCommandBufferRelease(command_buffer);
        wgpu.wgpuCommandEncoderRelease(command_encoder);
        wgpu.wgpuTextureViewRelease(frame);
        wgpu.wgpuTextureRelease(surface_texture.texture);
    }

    const version = wgpu.wgpuGetVersion();
    std.debug.print("wgpu version: {d}", .{version});
}
