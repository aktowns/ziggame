const Buffer = @This();

const std = @import("std");

const Instance = @import("Instance.zig");

const wg = @import("cincludes.zig").wg;
const wge = @import("enums.zig");
const log = @import("wingman").log;
const string_view = @import("string_view.zig");
const StringView = string_view.StringView;

native: *wg.WGPUBufferImpl,

pub fn init(buffer: *wg.WGPUBufferImpl) @This() {
    return .{ .native = buffer };
}

pub fn deinit(self: *const @This()) void {
    wg.wgpuBufferRelease(self.native);
}

export fn setBufferMapAsync(status: wg.WGPUBufferMapAsyncStatus, error_desc: StringView, setee: ?*anyopaque, nothing: ?*anyopaque) void {
    _ = nothing;
    const pretty_status: wge.BufferMapAsyncStatus = @enumFromInt(status);

    log.debug(@src(), "({?}) {?s}", .{ pretty_status, string_view.data(error_desc) });

    log.debug(@src(), "pointee {*}", .{setee});
    const s = @as(?*wge.BufferMapAsyncStatus, @alignCast(@ptrCast(setee)));
    s.?.* = pretty_status;
}

pub fn bufferMappedSync(self: *const @This(), instance: *Instance, map_mode: wge.MapMode, offset: usize, size: usize) wge.BufferMapAsyncStatus {
    var status: wge.BufferMapAsyncStatus = wge.BufferMapAsyncStatus.unknown;

    const future = wg.wgpuBufferMapAsync2(self.native, @intFromEnum(map_mode), offset, size, wg.WGPUBufferMapCallbackInfo2{
        .callback = setBufferMapAsync,
        .mode = @intFromEnum(wge.CallbackMode.wait_any_only),
        .userdata1 = @ptrCast(&status),
        .userdata2 = null,
    });

    log.debug(@src(), "device future id {d}", .{future.id});

    var futures = [_]wg.WGPUFutureWaitInfo{wg.WGPUFutureWaitInfo{ .completed = 0, .future = future }};
    const wait_res = instance.waitAny(&futures, std.time.ns_per_s * 5);

    switch (wait_res) {
        .success => log.debug(@src(), "future wait complete {any}", .{futures}),
        else => log.err(@src(), "buffer map_sync future failed {?}", .{wait_res}),
    }

    log.debug(@src(), "result is {?} {*}", .{ status, &status });

    return status;
}

pub fn unmap(self: *const @This()) void {
    wg.wgpuBufferUnmap(self.native);
}

pub fn getMappedRange(self: *const @This(), offset: usize, size: usize) ?*anyopaque {
    return wg.wgpuBufferGetMappedRange(self.native, offset, size);
}
