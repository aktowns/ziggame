const builtin = @import("builtin");

pub const c = @cImport({
    if (builtin.target.os.tag == .macos) {
        @cInclude("objc/runtime.h");
        @cInclude("objc/message.h");
        @cInclude("Carbon/Carbon.h");
    }
});
