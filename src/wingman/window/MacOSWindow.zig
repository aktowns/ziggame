pub const MacOSWindow = @This();

const std = @import("std");
const WindowOptions = @import("WindowOptions.zig");
const assert = std.debug.assert;

pub const c = @import("../native/macos/cinclude.zig").c;

const class = @import("../native/macos/Class.zig");
const objc = @import("../native/macos/objc_helper.zig");
const send = objc.send;

app: c.id,
window: c.id,
layer: c.id,
view: c.id,
cc: ClassCache,

const ClassCache = struct {
    NSApplication: c.Class,
    NSDate: c.Class,
    NSString: c.Class,
    NSMenu: c.Class,
    NSMenuItem: c.Class,
    NSObject: c.Class,
    NSView: c.Class,
    NSWindow: c.Class,
    NSWindowController: c.Class,
    CAMetalLayer: c.Class,
    NSAutoreleasePool: c.Class,
    NSDefaultRunLoopMode: c.id,
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

const NSEventType = enum(c_ulong) {
    NSEventTypeLeftMouseDown = 1,
    NSEventTypeLeftMouseUp = 2,
    NSEventTypeRightMouseDown = 3,
    NSEventTypeRightMouseUp = 4,
    NSEventTypeMouseMoved = 5,
    NSEventTypeLeftMouseDragged = 6,
    NSEventTypeRightMouseDragged = 7,
    NSEventTypeMouseEntered = 8,
    NSEventTypeMouseExited = 9,
    NSEventTypeKeyDown = 10,
    NSEventTypeKeyUp = 11,
    NSEventTypeFlagsChanged = 12,
    NSEventTypeAppKitDefined = 13,
    NSEventTypeSystemDefined = 14,
    NSEventTypeApplicationDefined = 15,
    NSEventTypePeriodic = 16,
    NSEventTypeCursorUpdate = 17,
    NSEventTypeScrollWheel = 22,
    NSEventTypeTabletPoint = 23,
    NSEventTypeTabletProximity = 24,
    NSEventTypeOtherMouseDown = 25,
    NSEventTypeOtherMouseUp = 26,
    NSEventTypeOtherMouseDragged = 27,
    NSEventTypeGesture = 29,
    NSEventTypeMagnify = 30,
    NSEventTypeSwipe = 31,
    NSEventTypeRotate = 18,
    NSEventTypeBeginGesture = 19,
    NSEventTypeEndGesture = 20,

    NSEventTypeSmartMagnify = 32,
    NSEventTypeQuickLook = 33,

    NSEventTypePressure = 34,
    NSEventTypeDirectTouch = 37,

    NSEventTypeChangeMode = 38,
};

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
        .NSApplication = class.from_name_strict("NSApplication"),
        .NSDate = class.from_name_strict("NSDate"),
        .NSString = class.from_name_strict("NSString"),
        .NSMenu = class.from_name_strict("NSMenu"),
        .NSMenuItem = class.from_name_strict("NSMenuItem"),
        .NSObject = class.from_name_strict("NSObject"),
        .NSView = class.from_name_strict("NSView"),
        .NSWindow = class.from_name_strict("NSWindow"),
        .NSWindowController = class.from_name_strict("NSWindowController"),
        .CAMetalLayer = class.from_name_strict("CAMetalLayer"),
        .NSAutoreleasePool = class.from_name_strict("NSAutoreleasePool"),
        .NSDefaultRunLoopMode = send(
            class.from_name_strict("NSString"),
            c.id,
            "stringWithUTF8String:",
            .{"kCFRunLoopDefaultMode"},
        ),
    };

    const rect: c.CGRect = .{ .origin = .{ .x = 0, .y = 0 }, .size = .{
        .height = @floatFromInt(window_options.height),
        .width = @floatFromInt(window_options.width),
    } };

    const app = send(cc.NSApplication, c.id, "sharedApplication", .{});
    send(app, void, "setActivationPolicy:", .{0});

    const window_style: c_ulong = NSWindowStyleMask.NSWindowStyleMaskClosable | NSWindowStyleMask.NSWindowStyleMaskMiniaturizable | NSBackingStoreType.NSBackingStoreBuffered | NSWindowStyleMask.NSWindowStyleMaskTitled | NSWindowStyleMask.NSWindowStyleMaskResizable;

    const WindowDelegate = class.define("WindowDelegate", cc.NSObject, &.{
        class.Method{ .name = "windowWillResize:toSize:", .imp = @ptrCast(&on_resize), .types = "{NSSize=ff}@:{NSSize=ff}" },
        class.Method{ .name = "windowShouldClose:", .imp = @ptrCast(&on_close), .types = "B@:{NSWindow}" },
    });

    const ContentView = class.define("ContentView", cc.NSView, &.{});

    const ZenWindow = class.define("ZenWindow", cc.NSWindow, &.{
        class.Method{ .name = "canBecomeKeyWindow", .imp = @ptrCast(&can_become_key_window), .types = "B@" },
        class.Method{ .name = "canBecomeMainWindow", .imp = @ptrCast(&can_become_main_window), .types = "B@" },
    });

    const view = send(class.alloc(ContentView), c.id, "initWithFrame:", .{rect});

    const window = send(
        class.alloc(ZenWindow),
        c.id,
        "initWithContentRect:styleMask:backing:defer:",
        .{
            rect,
            window_style,
            window_style,
            NO,
        },
    );

    send(window, void, "setContentView:", .{view});

    send(class.alloc(cc.NSWindowController), void, "initWithWindow:", .{window});

    const menubar = send(cc.NSMenu, c.id, "new", .{});
    const menubar_item = send(cc.NSMenuItem, c.id, "new", .{});
    send(menubar, void, "addItem:", .{menubar_item});
    send(app, void, "setMainMenu:", .{menubar});

    const delegate = send(class.alloc(WindowDelegate), c.id, "init", .{});
    send(window, void, "setDelegate:", .{delegate});
    send(app, void, "setDelegate:", .{delegate});

    send(app, void, "activateIgnoringOtherApps:", .{YES});
    send(window, void, "makeKeyAndOrderFront:", .{c.nil});
    send(window, void, "setIsVisible:", .{YES});

    send(app, void, "finishLaunching", .{});

    send(
        window,
        void,
        "setTitle:",
        .{
            send(
                cc.NSString,
                c.id,
                "stringWithUTF8String:",
                .{@as([*c]const u8, @ptrCast(window_options.title))},
            ),
        },
    );

    const layer = send(cc.CAMetalLayer, c.id, "layer", .{});
    send(view, void, "setWantsLayer:", .{YES});
    send(view, void, "setLayer:", .{layer});

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
    std.Thread.sleep(std.time.ns_per_ms * 100);
    while (true) {
        const pool = objc.init(class.alloc(self.cc.NSAutoreleasePool));
        defer objc.release(pool);

        const event = send(
            self.app,
            c.id,
            "nextEventMatchingMask:untilDate:inMode:dequeue:",
            .{
                @as(c_ulong, std.math.maxInt(u64)),
                @as(c.id, null),
                self.cc.NSDefaultRunLoopMode,
                YES,
            },
        );

        if (event == @as(c.id, @alignCast(@ptrCast(c.nil)))) {
            break;
        }

        const typ = send(event, c_uint, "type", .{});
        const event_type: NSEventType = @enumFromInt(typ);

        //NSPoint p = ((NSPoint(*)(id, SEL)) objc_msgSend)(e, sel_registerName("locationInWindow"));
        const p = send(event, c.CGPoint, "locationInWindow", .{});

        std.log.debug("Window event: {?*} {?} {?}", .{ event, event_type, p });

        send(self.app, void, "sendEvent:", .{event});
    }

    // send(self.view, void, "setNeedsDisplay:", .{YES});
    return 0;
}
