const Device = @This();

const std = @import("std");
const builtin = @import("builtin");
const wg = @import("cincludes.zig").wg;
const Queue = @import("Queue.zig");
const PipelineLayout = @import("PipelineLayout.zig");
const RenderPipeline = @import("RenderPipeline.zig");
const ShaderModule = @import("ShaderModule.zig");
const CommandEncoder = @import("CommandEncoder.zig");
const Texture = @import("Texture.zig");
const Error = @import("error.zig").Error;
const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const BindGroupLayout = @import("BindGroupLayout.zig");
const BindGroup = @import("BindGroup.zig");
const string_view = @import("string_view.zig");
const StringView = string_view.StringView;

native: *wg.WGPUDeviceImpl,

pub fn init(device: *wg.WGPUDeviceImpl) @This() {
    return .{ .native = device };
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
        .label = string_view.init("Shader"),
        .nextInChain = @as(*wg.WGPUChainedStruct, @constCast(@ptrCast(
            &wg.WGPUShaderModuleWGSLDescriptor{
                .chain = wg.WGPUChainedStruct{
                    .sType = shader_source,
                },
                .code = string_view.initR(contents),
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

pub fn createBuffer(self: *const @This(), descriptor: [*c]const wg.WGPUBufferDescriptor) Buffer {
    const bfr = wg.wgpuDeviceCreateBuffer(self.native, descriptor).?;

    return Buffer.init(bfr);
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
