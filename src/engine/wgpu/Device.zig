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
const Error = @import("error.zig").Error;

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
