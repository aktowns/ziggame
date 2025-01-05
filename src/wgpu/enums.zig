const wg = @import("cincludes.zig").wg;

pub const WaitStatus = enum(wg.enum_WGPUWaitStatus) {
    success = wg.WGPUWaitStatus_Success,
    timed_out = wg.WGPUWaitStatus_TimedOut,
    unsupported_timeout = wg.WGPUWaitStatus_UnsupportedTimeout,
    unsupported_count = wg.WGPUWaitStatus_UnsupportedCount,
    unsupported_mixed_souces = wg.WGPUWaitStatus_UnsupportedMixedSources,
    unknown = wg.WGPUWaitStatus_Unknown,
};

pub const RequestAdapterStatus = enum(wg.enum_WGPURequestAdapterStatus) {
    success = wg.WGPURequestAdapterStatus_Success,
    instance_dropped = wg.WGPURequestAdapterStatus_InstanceDropped,
    unavailable = wg.WGPURequestAdapterStatus_Unavailable,
    err = wg.WGPURequestAdapterStatus_Error,
    unknown = wg.WGPURequestAdapterStatus_Unknown,
};

pub const CallbackMode = enum(wg.enum_WGPUCallbackMode) {
    wait_any_only = wg.WGPUCallbackMode_WaitAnyOnly,
    allow_process_events = wg.WGPUCallbackMode_AllowProcessEvents,
    allow_spontaneous = wg.WGPUCallbackMode_AllowSpontaneous,
};

pub const IndexFormat = enum(wg.enum_WGPUIndexFormat) {
    undef = wg.WGPUIndexFormat_Undefined,
    uint16 = wg.WGPUIndexFormat_Uint16,
    uint32 = wg.WGPUIndexFormat_Uint32,
};

pub const AddressMode = enum(wg.enum_WGPUAddressMode) {
    undef = wg.WGPUAddressMode_Undefined,
    clamp_to_edge = wg.WGPUAddressMode_ClampToEdge,
    repeat = wg.WGPUAddressMode_Repeat,
    mirror_repeat = wg.WGPUAddressMode_MirrorRepeat,
};

pub const FilterMode = enum(wg.enum_WGPUFilterMode) {
    undef = wg.WGPUFilterMode_Undefined,
    nearest = wg.WGPUFilterMode_Nearest,
    linear = wg.WGPUFilterMode_Linear,
};

pub const MipmapFilterMode = enum(wg.enum_WGPUMipmapFilterMode) {
    undef = wg.WGPUMipmapFilterMode_Undefined,
    nearest = wg.WGPUMipmapFilterMode_Nearest,
    linear = wg.WGPUMipmapFilterMode_Linear,
};

pub const CompareFunction = enum(wg.enum_WGPUCompareFunction) {
    undef = wg.WGPUCompareFunction_Undefined,
    never = wg.WGPUCompareFunction_Never,
    less = wg.WGPUCompareFunction_Less,
    equal = wg.WGPUCompareFunction_Equal,
    less_equal = wg.WGPUCompareFunction_LessEqual,
    greater = wg.WGPUCompareFunction_Greater,
    not_equal = wg.WGPUCompareFunction_NotEqual,
    greater_equal = wg.WGPUCompareFunction_GreaterEqual,
    always = wg.WGPUCompareFunction_Always,
};

pub const BufferUsage = struct {
    pub const BufferUsageImpl = wg.WGPUBufferUsage;

    pub const none: BufferUsageImpl = wg.WGPUBufferUsage_None;
    pub const map_read: BufferUsageImpl = wg.WGPUBufferUsage_MapRead;
    pub const map_write: BufferUsageImpl = wg.WGPUBufferUsage_MapWrite;
    pub const copy_src: BufferUsageImpl = wg.WGPUBufferUsage_CopySrc;
    pub const copy_dst: BufferUsageImpl = wg.WGPUBufferUsage_CopyDst;
    pub const index: BufferUsageImpl = wg.WGPUBufferUsage_Index;
    pub const vertex: BufferUsageImpl = wg.WGPUBufferUsage_Vertex;
    pub const uniform: BufferUsageImpl = wg.WGPUBufferUsage_Uniform;
    pub const storage: BufferUsageImpl = wg.WGPUBufferUsage_Storage;
    pub const indirect: BufferUsageImpl = wg.WGPUBufferUsage_Indirect;
    pub const query_resolve: BufferUsageImpl = wg.WGPUBufferUsage_QueryResolve;
};

pub const MapMode = enum(wg.WGPUMapMode) {
    _,

    pub const None: MapMode = @enumFromInt(0);
    pub const Read: MapMode = @enumFromInt(1);
    pub const Write: MapMode = @enumFromInt(2);
};

pub const BufferMapAsyncStatus = enum(wg.enum_WGPUBufferMapAsyncStatus) {
    success = wg.WGPUBufferMapAsyncStatus_Success,
    instance_dropped = wg.WGPUBufferMapAsyncStatus_InstanceDropped,
    validation_error = wg.WGPUBufferMapAsyncStatus_ValidationError,
    unknown = wg.WGPUBufferMapAsyncStatus_Unknown,
    device_lost = wg.WGPUBufferMapAsyncStatus_DeviceLost,
    destroyed_before_callback = wg.WGPUBufferMapAsyncStatus_DestroyedBeforeCallback,
    unmapped_before_callbaclk = wg.WGPUBufferMapAsyncStatus_UnmappedBeforeCallback,
    mapping_already_pending = wg.WGPUBufferMapAsyncStatus_MappingAlreadyPending,
    offset_out_of_range = wg.WGPUBufferMapAsyncStatus_OffsetOutOfRange,
    size_out_of_range = wg.WGPUBufferMapAsyncStatus_SizeOutOfRange,
};
