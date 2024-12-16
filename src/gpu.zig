const std = @import("std");
const wgpu = @cImport({
    @cInclude("wgpu/wgpu.h");
});

const glfw = @cImport({
    @cDefine("GLFW_EXPOSE_NATIVE_COCOA", "1");
    @cInclude("GLFW/glfw3.h");
    @cInclude("GLFW/glfw3native.h");
});

const objc = @import("objc");

const State = struct {
    instance: wgpu.WGPUInstance,
    surface: wgpu.WGPUSurface,
    adapter: wgpu.WGPUAdapter,
    device: wgpu.WGPUDevice,
    // config: wgpu.WGPUSurfaceConfiguration,
};

var state: State = State{ .instance = null, .surface = null, .adapter = null, .device = null };

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

pub fn wgpuInit() void {
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
    const window = glfw.glfwCreateWindow(640, 480, "aa", null, null);

    const ns_window = glfw.glfwGetCocoaWindow(window);
    const objc_window = objc.Object.fromId(ns_window);

    const objc_view = objc_window.getProperty(objc.Object, "contentView");

    _ = objc_view.msgSend(objc.Object, "setWantsLayer:", .{true});
    const CAMetalLayer = objc.getClass("CAMetalLayer").?;
    const layer = CAMetalLayer.msgSend(objc.Object, "layer", .{});
    _ = objc_view.msgSend(objc.Object, "setLayer:", .{layer});

    //const window = rgfw.RGFW_createWindow("Testing", rgfw.RGFW_RECT(0, 0, 800, 600), rgfw.RGFW_CENTER | rgfw.RGFW_NO_RESIZE);
    // const view: *objc.Object = @as(*objc.Object, @alignCast(window.*.src.view.?));
    // const view = objc.Object.fromId(window.*.src.view.?);

    // CAMetalLayer* layer = [CAMetalLayer layer];
    // layer.device = device;
    // layer.pixelFormat = MTLPixelFormatBGRA8Unorm;

    // NSView* view = (NSView*)window->src.view;
    // [view setLayer: layer];

    //_ = view.msgSend(objc.Object, "setLayer", .{layer});

    const chain: *wgpu.WGPUChainedStruct = @constCast(@ptrCast(&wgpu.WGPUSurfaceDescriptorFromMetalLayer{ .layer = layer.value, .chain = wgpu.WGPUChainedStruct{ .sType = wgpu.WGPUSType_SurfaceDescriptorFromMetalLayer } }));
    const desc = &wgpu.WGPUSurfaceDescriptor{ .nextInChain = chain };

    state.surface = wgpu.wgpuInstanceCreateSurface(state.instance, desc);

    wgpu.wgpuInstanceRequestAdapter(state.instance, &.{ .compatibleSurface = state.surface }, handle_request_adapter, &state);
    print_adapter_info(state.adapter);

    wgpu.wgpuAdapterRequestDevice(state.adapter, null, handle_request_device, &state);

    const queue = wgpu.wgpuDeviceGetQueue(state.device);

    _ = queue;

    const version = wgpu.wgpuGetVersion();
    std.debug.print("wgpu version: {d}", .{version});
}
