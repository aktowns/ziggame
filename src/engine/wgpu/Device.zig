const Device = @This();

const std = @import("std");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const u = @import("../util.zig");
const Queue = @import("Queue.zig");
const PipelineLayout = @import("PipelineLayout.zig");
const RenderPipeline = @import("RenderPipeline.zig");
const ShaderModule = @import("ShaderModule.zig");
const CommandEncoder = @import("CommandEncoder.zig");
const Texture = @import("Texture.zig");
const Error = @import("error.zig").Error;
const Image = @import("../media/Image.zig");
const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const BindGroupLayout = @import("BindGroupLayout.zig");
const BindGroup = @import("BindGroup.zig");

device: *wg.WGPUDeviceImpl,
allocator: std.mem.Allocator,

pub fn init(device: *wg.WGPUDeviceImpl, allocator: std.mem.Allocator) @This() {
    return .{ .device = device, .allocator = allocator };
}

pub fn getQueue(self: *const @This()) Queue {
    return Queue.init(wg.wgpuDeviceGetQueue(self.device).?);
}

pub fn createPipelineLayout(self: *const @This(), pipelineLayout: [*c]const wg.WGPUPipelineLayoutDescriptor) PipelineLayout {
    // nextInChain: [*c]const WGPUChainedStruct = @import("std").mem.zeroes([*c]const WGPUChainedStruct),
    // label: WGPUStringView = @import("std").mem.zeroes(WGPUStringView),
    // bindGroupLayoutCount: usize = @import("std").mem.zeroes(usize),
    // bindGroupLayouts: [*c]const WGPUBindGroupLayout = @import("std").mem.zeroes([*c]const WGPUBindGroupLayout),
    // immediateDataRangeByteSize: u32 = @import("std").mem.zeroes(u32),

    return PipelineLayout.init(wg.wgpuDeviceCreatePipelineLayout(self.device, pipelineLayout).?);
}

pub fn createRenderPipeline(self: *const @This(), descriptor: [*c]const wg.WGPURenderPipelineDescriptor) RenderPipeline {
    return RenderPipeline.init(wg.wgpuDeviceCreateRenderPipeline(self.device, descriptor).?);
}

pub fn createShaderModule(self: *const @This(), descriptor: [*c]const wg.WGPUShaderModuleDescriptor) ShaderModule {
    return ShaderModule.init(wg.wgpuDeviceCreateShaderModule(self.device, descriptor).?);
}

pub fn createShaderModuleFromSource(self: *const @This(), contents: []u8) ShaderModule {
    // return wgpu.wgpuDeviceCreateShaderModule(device,
    // &wgpu.WGPUShaderModuleDescriptor{ .label = name,
    // .nextInChain = @as(*wgpu.WGPUChainedStruct, @constCast(@ptrCast(&wgpu.WGPUShaderModuleWGSLDescriptor{ .chain = wgpu.WGPUChainedStruct{ .sType = wgpu.WGPUSType_ShaderModuleWGSLDescriptor }, .code = buffer.ptr }))) });
    return self.createShaderModule(&wg.WGPUShaderModuleDescriptor{
        .label = u.stringView("Shader"),
        .nextInChain = @as(*wg.WGPUChainedStruct, @constCast(@ptrCast(
            &wg.WGPUShaderModuleWGSLDescriptor{
                .chain = wg.WGPUChainedStruct{
                    .sType = wg.WGPUSType_ShaderSourceWGSL,
                },
                .code = u.stringViewR(contents),
            },
        ))),
    });
}

pub fn createShaderModuleFromFile(self: *const @This(), name: [:0]const u8) Error!ShaderModule {
    const path = std.fs.cwd().realpathAlloc(self.allocator, ".") catch return Error.FailedToCreateShader;
    defer self.allocator.free(path);

    const shader_path = std.fs.path.join(self.allocator, &[_][]const u8{ path, "resources", "shaders", name }) catch return Error.FailedToCreateShader;
    defer self.allocator.free(shader_path);

    std.log.debug("[Shader] Opening shader at {s}", .{shader_path});

    const file = std.fs.cwd().openFile(shader_path, .{}) catch return Error.FailedToCreateShader;
    defer file.close();

    const stat = file.stat() catch return Error.FailedToCreateShader;
    const buffer = file.readToEndAllocOptions(self.allocator, stat.size, null, @alignOf(u8), 0) catch return Error.FailedToCreateShader;
    defer self.allocator.free(buffer);

    return self.createShaderModuleFromSource(buffer);
}

pub fn createCommandEncoder(self: *const @This(), descriptor: [*c]const wg.WGPUCommandEncoderDescriptor) CommandEncoder {
    const enc = wg.wgpuDeviceCreateCommandEncoder(self.device, descriptor).?;

    return CommandEncoder.init(enc);
}

pub fn createTexture(self: *const @This(), descriptor: [*c]const wg.WGPUTextureDescriptor) Texture {
    return Texture.init(wg.wgpuDeviceCreateTexture(self.device, descriptor).?);
}

pub fn createTextureFromImage(self: *const @This(), image: *const Image) Texture {
    return self.createTexture(&wg.WGPUTextureDescriptor{
        .label = u.stringView("image"),
        .format = wg.WGPUTextureFormat_RGBA8Unorm,
        .size = wg.WGPUExtent3D{
            .height = @intCast(image.image.height),
            .width = @intCast(image.image.width),
            .depthOrArrayLayers = 1,
        },
        .mipLevelCount = 1,
        .sampleCount = 1,
        .dimension = wg.WGPUTextureDimension_2D,
        .usage = wg.WGPUTextureUsage_TextureBinding | wg.WGPUTextureUsage_CopyDst | wg.WGPUTextureUsage_RenderAttachment,
    });
}

pub fn createBuffer(self: *const @This(), descriptor: [*c]const wg.WGPUBufferDescriptor) Buffer {
    const bfr = wg.wgpuDeviceCreateBuffer(self.device, descriptor).?;

    return Buffer.init(bfr);
}

pub fn createSampler(self: *const @This(), descriptor: [*c]const wg.WGPUSamplerDescriptor) Sampler {
    const sampler = wg.wgpuDeviceCreateSampler(self.device, descriptor).?;

    return Sampler.init(sampler);
}

pub fn createBindGroupLayout(self: *const @This(), descriptor: [*c]const wg.WGPUBindGroupLayoutDescriptor) BindGroupLayout {
    const bgl = wg.wgpuDeviceCreateBindGroupLayout(self.device, descriptor).?;

    return BindGroupLayout.init(bgl);
}

pub fn createBindGroup(self: *const @This(), descriptor: [*c]const wg.WGPUBindGroupDescriptor) BindGroup {
    const bg = wg.wgpuDeviceCreateBindGroup(self.device, descriptor).?;

    return BindGroup.init(bg);
}