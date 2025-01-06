pub const MacOSWindow = @This();

const std = @import("std");
pub const c = @cImport({
    @cInclude("objc/runtime.h");
    @cInclude("objc/message.h");
    @cInclude("Carbon/Carbon.h");
});

window: c.id,
layer: c.id,
view: c.struct_objc_object,
cache: ClassCache,

const ClassCache = struct {
    NSApp: c.Class,
    NSDate: c.Class,
    NSDefaultRunLoopMode: c.id,
};

const YES = 1;
const NO = 0;

inline fn sel(s: [*c]const u8) c.SEL {
    return c.sel_getUid(s);
}

inline fn cls(cl: [*c]const u8) c.Class {
    return c.objc_getClass(cl);
}

inline fn allocate_cls(base: c.Class, cl: [*c]const u8, sz: usize) c.Class {
    return c.objc_allocateClassPair(base, cl, sz);
}

inline fn add_method(cl: c.Class, name: c.SEL, imp: c.IMP, types: [*c]const u8) bool {
    return c.class_addMethod(cl, name, imp, types);
}

const msg = @as(*const fn (cl: c.id, s: c.SEL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_cls = @as(*const fn (cl: c.Class, s: c.SEL) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_cls_id = @as(*const fn (cl: c.Class, s: c.SEL, c.id) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_int = @as(*const fn (cl: c.id, s: c.SEL, i: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_id = @as(*const fn (cl: c.id, s: c.SEL, i: c.id) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_ptr = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_ptr_int = @as(*const fn (cl: c.id, s: c.SEL, i: ?*anyopaque, ii: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));
const msg_cls_chr = @as(*const fn (cl: c.Class, s: c.SEL, i: [*c]const u8) callconv(.c) c.id, @ptrCast(&c.objc_msgSend));

export fn on_resize() void {
    std.log.debug("onResize", .{});
}

pub fn init(title: []const u8) @This() {
    const cache = ClassCache{
        .NSApp = cls("NSApp"),
        .NSDate = cls("NSDate"),
        .NSDefaultRunLoopMode = msg_cls_chr(cls("NSString"), sel("stringWithUTF8String:"), "NSDefaultRunLoopMode"),
    };
    const rect: c.CGRect = .{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .height = 640, .width = 480 } };
    const app = msg_cls(cls("NSApplication"), sel("sharedApplication"));
    _ = msg_int(app, sel("setActivationPolicy:"), 0);

    const WindowDelegate = allocate_cls(cls("NSObject"), "WindowDelegate", 0);
    _ = add_method(WindowDelegate, sel("windowWillResize:toSize:"), on_resize, "{NSSize=ff}@:{NSSize=ff}");

    const view = @as(*const fn (cl: c.id, s: c.SEL, frame: c.CGRect) callconv(.c) c.id, @ptrCast(&c.objc_msgSend))(
        msg_cls(cls("NSView"), sel("alloc")),
        sel("initWithFrame:"),
        rect,
    );

    const window = @as(*const fn (cl: c.id, s: c.SEL, rect: c.CGRect, style_mask: c_int, backing: c_int, deferred: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend))(
        msg_cls(cls("NSWindow"), sel("alloc")),
        sel("initWithContentRect:styleMask:backing:defer:"),
        rect,
        (1 << 0 | 1 << 1 | 1 << 2 | 1 << 3),
        2,
        NO,
    );
    _ = msg_id(window, sel("setContentView:"), view);

    _ = msg_id(msg_cls(cls("NSWindowController"), sel("alloc")), sel("initWithWindow:"), window);

    const delegate = msg(msg_cls(WindowDelegate, sel("alloc")), sel("init"));
    _ = msg_id(window, sel("setDelegate:"), delegate);

    _ = msg_id(window, sel("setTitle:"), msg_cls_chr(cls("NSString"), sel("stringWithUTF8String:"), @ptrCast(title)));
    _ = msg_ptr(window, sel("makeKeyAndOrderFront:"), c.nil);
    _ = msg_int(app, sel("activateIgnoringOtherApps:"), YES);

    // const view = msg(window, sel("contentView"));
    const layer = msg_cls(cls("CAMetalLayer"), sel("layer"));

    _ = msg_int(view, sel("setWantsLayer:"), 1);
    _ = msg_ptr(view, sel("setLayer:"), layer);

    _ = @as(*const fn (cl: c.id, s: c.SEL, rect: c.CGRect, display: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend))(
        window,
        sel("setFrame:display:"),
        rect,
        YES,
    );

    _ = msg_cls(cls("NSApp"), sel("finishLaunching"));

    std.log.debug("[{d}] created window, view={?*}", .{ std.Thread.getCurrentId(), view });

    return .{
        .window = window,
        .layer = layer,
        .view = view.*,
        .cache = cache,
    };
}

pub fn setup(self: *@This()) void {
    _ = self;
}

pub fn dispatch(self: *@This()) i32 {
    const NSDefaultRunLoopMode = msg_cls_chr(cls("NSString"), sel("stringWithUTF8String:"), "NSDefaultRunLoopMode");
    while (true) {
        const date = msg_cls(cls("NSDate"), sel("distantPast"));
        const event = @as(*const fn (cl: c.Class, s: c.SEL, mask: c_ulong, date: c.id, in: c.id, deq: c_int) callconv(.c) c.id, @ptrCast(&c.objc_msgSend))(
            cls("NSApp"),
            sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
            std.math.maxInt(u64), // NSAnyEventMask
            date,
            NSDefaultRunLoopMode,
            YES,
        );

        if (event == @as(c.id, @alignCast(@ptrCast(c.nil)))) {
            break;
        }

        std.log.debug("ev={?*}", .{event});

        _ = msg_cls_id(cls("NSApp"), sel("sendEvent:"), event);
    }

    std.log.debug("[{d}] window loop view={?*}", .{ std.Thread.getCurrentId(), &self.view });
    _ = msg_int(&self.view, sel("setNeedsDisplay:"), YES);
    return 0;
}
