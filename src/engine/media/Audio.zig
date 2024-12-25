pub const Audio = @This();

const std = @import("std");

const cinclude = @import("../cincludes.zig");
const al = cinclude.openal;

pub fn xx() void {
    const x = cinclude.emscripten;
    x.EM_JS("int", "saudio_js_init");
}
