pub const MacOSWindow = @This();

const std = @import("std");
const WindowOptions = @import("WindowOptions.zig");
const assert = std.debug.assert;

pub const c = @import("../native/macos/cinclude.zig").c;

const Class = @import("../native/macos/Class.zig");
const Obj = @import("../native/macos/Obj.zig");

app: Obj,
window: Obj,
layer: c.id,
view: c.id,
cc: ClassCache,

const ClassCache = struct {
    NSApplication: Class,
    NSDate: Class,
};

const YES: c.BOOL = true;
const NO: c.BOOL = false;

const NSWindowStyleMask = struct {
    const NSWindowStyleMaskBorderless: c_ulong = 0;
    const NSWindowStyleMaskTitled: c_ulong = 1 << 0;
    const NSWindowStyleMaskClosable: c_ulong = 1 << 1;
    const NSWindowStyleMaskMiniaturizable: c_ulong = 1 << 2;
    const NSWindowStyleMaskResizable: c_ulong = 1 << 3;
    const NSWindowStyleMaskTexturedBackground: c_ulong = 1 << 8;
    const NSWindowStyleMaskUnifiedTitleAndToolbar: c_ulong = 1 << 12;
    const NSWindowStyleMaskFullScreen: c_ulong = 1 << 14;
    const NSWindowStyleMaskFullSizeContentView: c_ulong = 1 << 15;
    const NSWindowStyleMaskUtilityWindow: c_ulong = 1 << 4;
    const NSWindowStyleMaskDocModalWindow: c_ulong = 1 << 6;
    const NSWindowStyleMaskNonactivatingPanel: c_ulong = 1 << 7;
    const NSWindowStyleMaskHUDWindow: c_ulong = 1 << 13;
};

const NSBackingStoreType = struct {
    const NSBackingStoreRetained: c_ulong = 0;
    const NSBackingStoreNonretained: c_ulong = 1;
    const NSBackingStoreBuffered: c_ulong = 2;
};

inline fn sel(comptime s: [*c]const u8) c.SEL {
    return c.sel_registerName(s);
}

inline fn cls(comptime cl: [*c]const u8) c.Class {
    // const found = c.objc_getClass(cl);
    // assert(found != null);
    const found = c.objc_getRequiredClass(cl);
    return found;
}

inline fn allocate_cls(base: c.Class, cl: [*c]const u8, sz: usize) c.Class {
    return c.objc_allocateClassPair(base, cl, sz);
}

inline fn add_method(cl: c.Class, name: c.SEL, imp: c.IMP, types: [*c]const u8) bool {
    return c.class_addMethod(cl, name, imp, types);
}

const msg_id = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_id_id = @as(*const fn (cl: c.id, s: c.SEL, i: c.id) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_id_rect = @as(*const fn (cl: c.id, s: c.SEL, i: c.CGRect) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_uint = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c_ulong, @ptrCast(&c.objc_msgSend));
const msg_int = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c_long, @ptrCast(&c.objc_msgSend));
const msg_SEL = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.SEL, @ptrCast(&c.objc_msgSend));
const msg_float = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.CGFloat, @ptrCast(&c.objc_msgSend));
const msg_bool = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.BOOL, @ptrCast(&c.objc_msgSend));
const msg_void = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
//const msg_double = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) , @ptrCast(&c.objc_msgSend));
const msg_void_id = @as(*const fn (cl: c.id, s: c.SEL, i: c.id) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const msg_void_uint = @as(*const fn (cl: c.id, s: c.SEL, i: c_ulong) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const msg_void_int = @as(*const fn (cl: c.id, s: c.SEL, i: c_long) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const msg_void_SEL = @as(*const fn (cl: c.id, s: c.SEL, i: c.SEL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const msg_void_float = @as(*const fn (cl: c.id, s: c.SEL, i: c.CGFloat) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const msg_void_bool = @as(*const fn (cl: c.id, s: c.SEL, i: c.BOOL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const msg_void_ptr = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const msg_id_chr = @as(*const fn (cl: c.id, s: c.SEL, i: [*c]const u8) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_id_ptr = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));

const cmsg_id = @as(*const fn (cl: c.Class, s: c.SEL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const cmsg_id_id = @as(*const fn (cl: c.Class, s: c.SEL, c.id) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const cmsg_id_int = @as(*const fn (cl: c.Class, s: c.SEL, c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const cmsg_void = @as(*const fn (cl: c.Class, s: c.SEL) callconv(.c) void, @ptrCast(&c.objc_msgSend));
const cmsg_void_id = @as(*const fn (cl: c.Class, s: c.SEL, i: c.id) callconv(.c) void, @ptrCast(&c.objc_msgSend));
// const msg_id_int = @as(*const fn (cl: c.id, s: c.SEL, i: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
// const msg_ptr_int = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque, ii: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const cmsg_id_chr = @as(*const fn (cl: c.Class, s: c.SEL, i: [*c]const u8) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));

export fn on_resize(self: c.id, s: c.SEL, size: c.CGSize) c.CGSize {
    _ = self;
    _ = s;
    std.log.debug("onResize size={?}", .{size});

    return size;
}

export fn on_close(self: c.id, s: c.SEL, sender: c.id) c.BOOL {
    _ = self;
    _ = s;
    _ = sender;
    std.log.debug("onClose:", .{});

    return true;
}

export fn can_become_key_window() bool {
    std.log.debug("can become key window", .{});
    return true;
}

export fn can_become_main_window() bool {
    std.log.debug("can become main window", .{});
    return true;
}

pub fn init(window_options: *const WindowOptions) @This() {
    const cc: ClassCache = .{
        .NSApplication = Class.from_name_strict("NSApplication"),
        .NSDate = Class.from_name_strict("NSDate"),
    };

    const rect: c.CGRect = .{ .origin = .{ .x = 0, .y = 0 }, .size = .{
        .height = @floatFromInt(window_options.height),
        .width = @floatFromInt(window_options.width),
    } };

    const app = cc.NSApplication.send(Obj, "sharedApplication", .{});
    // const app = Class.from_name_strict("NSApplication").send(Obj, "sharedApplication", .{});
    app.send(void, "setActivationPolicy:", .{0});

    // const app = cmsg_id(cls("NSApplication"), sel("sharedApplication"));
    // assert(app != null);
    // msg_void_uint(app, sel("setActivationPolicy:"), 0);

    const window_style: c_ulong = NSWindowStyleMask.NSWindowStyleMaskClosable | NSWindowStyleMask.NSWindowStyleMaskMiniaturizable | NSBackingStoreType.NSBackingStoreBuffered | NSWindowStyleMask.NSWindowStyleMaskTitled | NSWindowStyleMask.NSWindowStyleMaskResizable;

    const WindowDelegate = allocate_cls(cls("NSObject"), "WindowDelegate", 0);
    _ = add_method(WindowDelegate, sel("windowWillResize:toSize:"), @ptrCast(&on_resize), "{NSSize=ff}@:{NSSize=ff}");
    _ = add_method(WindowDelegate, sel("windowShouldClose:"), @ptrCast(&on_close), "B@:{NSWindow}");

    const ContentView = allocate_cls(cls("NSView"), "ContentView", 0);

    const ZenWindow = allocate_cls(cls("NSWindow"), "ZenWindow", 0);
    assert(ZenWindow != null);
    _ = add_method(ZenWindow, sel("canBecomeKeyWindow"), @ptrCast(&can_become_key_window), "B@");
    _ = add_method(ZenWindow, sel("canBecomeMainWindow"), @ptrCast(&can_become_main_window), "B@");

    const view = @as(*const fn (cl: c.id, s: c.SEL, frame: c.CGRect) callconv(.c) c.id, @ptrCast(&c.objc_msgSend))(
        cmsg_id(ContentView, sel("alloc")),
        sel("initWithFrame:"),
        rect,
    );
    assert(view != null);

    const window = Class.from_native(ZenWindow)
        .send(Obj, "alloc", .{})
        .send(Obj, "initWithContentRect:styleMask:backing:defer:", .{ rect, window_style, window_style, NO });
    // const window = @as(*const fn (cl: c.id, s: c.SEL, rect: c.CGRect, style_mask: c_int, backing: c_int, deferred: c.BOOL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend))(
    //     cmsg_id(ZenWindow, sel("alloc")),
    //     sel("initWithContentRect:styleMask:backing:defer:"),
    //     rect,
    //     window_style,
    //     window_style,
    //     NO,
    // );
    // assert(window != null);
    window.send(void, "setContentView:", .{view});
    // msg_void_id(window, sel("setContentView:"), view);

    // _ = msg_id(msg_cls(cls("NSWindowController"), sel("alloc")), sel("initWithWindow:"), window);

    const menubar = Class.from_name_strict("NSMenu").send(Obj, "new", .{});
    // const menubar = cmsg_id(cls("NSMenu"), sel("new"));
    const menubar_item = Class.from_name_strict("NSMenuItem").send(Obj, "new", .{});
    //const menubar_item = cmsg_id(cls("NSMenuItem"), sel("new"));
    menubar.send(void, "addItem:", .{menubar_item});
    // msg_void_id(menubar, sel("addItem:"), menubar_item);
    app.send(void, "setMainMenu:", .{menubar});
    // msg_void_id(app, sel("setMainMenu:"), menubar);

    const delegate = msg_id(cmsg_id(WindowDelegate, sel("alloc")), sel("init"));
    //msg_void_id(window, sel("setDelegate:"), delegate);
    window.send(void, "setDelegate:", .{delegate});
    app.send(void, "setDelegate:", .{delegate});
    // msg_void_id(app, sel("setDelegate:"), delegate);

    app.send(void, "activateIgnoringOtherApps:", .{YES});
    // msg_void_bool(app, sel("activateIgnoringOtherApps:"), YES);
    window.send(void, "makeKeyAndOrderFront:", .{c.nil});
    window.send(void, "setIsVisible:", .{YES});
    //msg_void_ptr(window, sel("makeKeyAndOrderFront:"), c.nil);
    //msg_void_bool(window, sel("setIsVisible:"), YES);

    app.send(void, "finishLaunching", .{});
    // msg_void(app, sel("finishLaunching"));

    window.send(
        void,
        "setTitle:",
        .{
            Class.from_name_strict("NSString").send(c.id, "stringWithUTF8String:", .{@as([*c]const u8, @ptrCast(window_options.title))}),
        },
    );

    //msg_void_id(window, sel("setTitle:"), cmsg_id_chr(cls("NSString"), sel("stringWithUTF8String:"), @ptrCast(window_options.title)));

    //const view = msg_id(window, sel("contentView"));
    //assert(view != null);
    const layer = Class.from_name_strict("CAMetalLayer").send(Obj, "layer", .{});
    // const layer = cmsg_id(cls("CAMetalLayer"), sel("layer"));
    // assert(layer != null);
    layer.send(void, "setWantsLayer:", .{YES});
    layer.send(void, "setLayer:", .{layer.native});

    // msg_void_uint(view, sel("setWantsLayer:"), 1);
    // msg_void_ptr(view, sel("setLayer:"), layer);

    std.log.debug("[{d}] created window, view={?*}", .{ std.Thread.getCurrentId(), view });

    return .{
        .app = app,
        .window = window,
        .layer = layer,
        .view = view,
        .cc = cc,
    };
}

pub fn setup(self: *@This()) void {
    _ = self;
}

pub fn dispatch(self: *@This()) i32 {
    const NSDefaultRunLoopMode = cmsg_id_chr(cls("NSString"), sel("stringWithUTF8String:"), "kCFRunLoopDefaultMode");

    while (true) {
        const pool = msg_id(cmsg_id(cls("NSAutoreleasePool"), sel("alloc")), sel("init"));
        defer msg_void(pool, sel("release"));

        const event = self.app.send(c.id, "nextEventMatchingMask:untilDate:inMode:dequeue:", .{
            @as(c_ulong, std.math.maxInt(u64)),
            @as(c.id, null),
            NSDefaultRunLoopMode,
            YES,
        });
        // const event = @as(*const fn (cl: c.id, s: c.SEL, mask: c_ulong, date: c.id, in: c.id, deq: c.BOOL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend))(
        //     self.app,
        //     sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
        //     std.math.maxInt(u64), // NSAnyEventMask
        //     null,
        //     NSDefaultRunLoopMode,
        //     YES,
        // );

        if (event == @as(c.id, @alignCast(@ptrCast(c.nil)))) {
            break;
        }

        self.app.send(void, "sendEvent:", .{event});
        //msg_void_id(self.app, sel("sendEvent:"), event);
    }
    // msg_void_bool(self.view, sel("setNeedsDisplay:"), YES);
    return 0;
}
