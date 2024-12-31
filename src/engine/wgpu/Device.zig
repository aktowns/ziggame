const Device = @This();

const std = @import("std");
const builtin = @import("builtin");
const cincludes = @import("../cincludes.zig");
const wg = cincludes.wg;
const wge = @import("enums.zig");
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
const Platform = @import("../Platform.zig");

native: *wg.WGPUDeviceImpl,
platform: *const Platform,
sentinel: ?*u8 = null,

pub fn init(platform: *const Platform, device: *wg.WGPUDeviceImpl) @This() {
    return .{ .native = device, .platform = platform, .sentinel = platform.sentinel() };
}

pub fn getQueue(self: *const @This()) Queue {
    return Queue.init(wg.wgpuDeviceGetQueue(self.native).?);
}

pub fn createPipelineLayout(self: *const @This(), pipelineLayout: [*c]const wg.WGPUPipelineLayoutDescriptor) PipelineLayout {
    return PipelineLayout.init(wg.wgpuDeviceCreatePipelineLayout(self.native, pipelineLayout).?);
}

pub fn createRenderPipeline(self: *const @This(), descriptor: [*c]const wg.WGPURenderPipelineDescriptor) RenderPipeline {
    return RenderPipeline.init(wg.wgpuDeviceCreateRenderPipeline(self.native, descriptor).?);
}

pub fn createShaderModule(self: *const @This(), descriptor: [*c]const wg.WGPUShaderModuleDescriptor) ShaderModule {
    return ShaderModule.init(wg.wgpuDeviceCreateShaderModule(self.native, descriptor).?);
}

pub fn createShaderModuleFromSource(self: *const @This(), contents: []u8) ShaderModule {
    const shader_source = if (builtin.target.isWasm()) wg.WGPUSType_ShaderModuleWGSLDescriptor else wg.WGPUSType_ShaderSourceWGSL;

    return self.createShaderModule(&wg.WGPUShaderModuleDescriptor{
        .label = u.stringView("Shader"),
        .nextInChain = @as(*wg.WGPUChainedStruct, @constCast(@ptrCast(
            &wg.WGPUShaderModuleWGSLDescriptor{
                .chain = wg.WGPUChainedStruct{
                    .sType = shader_source,
                },
                .code = u.stringViewR(contents),
            },
        ))),
    });
}

pub fn createCommandEncoder(self: *const @This(), descriptor: [*c]const wg.WGPUCommandEncoderDescriptor) CommandEncoder {
    const enc = wg.wgpuDeviceCreateCommandEncoder(self.native, descriptor).?;

    return CommandEncoder.init(enc);
}

pub fn createTexture(self: *const @This(), descriptor: [*c]const wg.WGPUTextureDescriptor) Texture {
    return Texture.init(wg.wgpuDeviceCreateTexture(self.native, descriptor).?);
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

pub const BufferDescriptor = struct {
    // nextInChain: [*c]const WGPUChainedStruct = @import("std").mem.zeroes([*c]const WGPUChainedStruct),
    // label: WGPUStringView = @import("std").mem.zeroes(WGPUStringView),
    usage: wge.BufferUsage.BufferUsageImpl,
    size: u64,
    mapped_at_creation: bool,

    fn native(self: *const @This()) wg.WGPUBufferDescriptor {
        return .{
            .usage = self.usage,
            .size = self.size,
            .mappedAtCreation = if (self.mapped_at_creation) 0 else 1,
        };
    }
};

pub fn createBufferT(self: *const @This(), descriptor: BufferDescriptor) Buffer {
    return self.createBuffer(&descriptor.native());
}

pub fn createBuffer(self: *const @This(), descriptor: [*c]const wg.WGPUBufferDescriptor) Buffer {
    const bfr = wg.wgpuDeviceCreateBuffer(self.native, descriptor).?;

    return Buffer.init(bfr);
}

pub const CreateSamplerDescriptor = struct {
    // nextInChain: [*c]const WGPUChainedStruct = @import("std").mem.zeroes([*c]const WGPUChainedStruct),
    // label: WGPUStringView = @import("std").mem.zeroes(WGPUStringView),
    address_mode_u: wge.AddressMode,
    address_mode_v: wge.AddressMode,
    address_mode_w: wge.AddressMode,
    mag_filter: wge.FilterMode,
    min_filter: wge.FilterMode,
    mipmap_filter: wge.MipmapFilterMode,
    lod_min_clamp: f32,
    lod_max_clamp: f32,
    compare: wge.CompareFunction,
    max_anisotropy: u16,

    fn native(self: *const @This()) wg.WGPUSamplerDescriptor {
        return .{
            .addressModeU = @intFromEnum(self.address_mode_u),
            .addressModeV = @intFromEnum(self.address_mode_v),
            .addressModeW = @intFromEnum(self.address_mode_w),
            .magFilter = @intFromEnum(self.mag_filter),
            .minFilter = @intFromEnum(self.min_filter),
            .mipmapFilter = @intFromEnum(self.mipmap_filter),
            .lodMinClamp = self.lod_min_clamp,
            .lodMaxClamp = self.lod_max_clamp,
            .compare = @intFromEnum(self.compare),
            .maxAnisotropy = self.max_anisotropy,
        };
    }
};

pub fn createSamplerT(self: *const @This(), descriptor: CreateSamplerDescriptor) Sampler {
    return self.createSampler(&descriptor.native());
}

pub fn createSampler(self: *const @This(), descriptor: [*c]const wg.WGPUSamplerDescriptor) Sampler {
    const sampler = wg.wgpuDeviceCreateSampler(self.native, descriptor).?;

    return Sampler.init(sampler);
}

pub fn createBindGroupLayout(self: *const @This(), descriptor: [*c]const wg.WGPUBindGroupLayoutDescriptor) BindGroupLayout {
    const bgl = wg.wgpuDeviceCreateBindGroupLayout(self.native, descriptor).?;

    return BindGroupLayout.init(bgl);
}

pub fn createBindGroup(self: *const @This(), descriptor: [*c]const wg.WGPUBindGroupDescriptor) BindGroup {
    const bg = wg.wgpuDeviceCreateBindGroup(self.native, descriptor).?;

    return BindGroup.init(bg);
}

pub fn tick(self: *const @This()) void {
    wg.wgpuDeviceTick(self.native);
}
