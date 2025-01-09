pub const MacOSWindow = @This();

const std = @import("std");
const WindowOptions = @import("WindowOptions.zig");
const assert = std.debug.assert;

pub const c = @import("../native/macos/cinclude.zig").c;

const class = @import("../native/macos/Class.zig");
const send = @import("../native/macos/objc_helper.zig").send;

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
    CAMetalLayer: c.Class,
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
        .CAMetalLayer = class.from_name_strict("CAMetalLayer"),
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

    // _ = msg_id(msg_cls(cls("NSWindowController"), sel("alloc")), sel("initWithWindow:"), window);

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
    while (true) {
        // const pool = msg_id(cmsg_id(cls("NSAutoreleasePool"), sel("alloc")), sel("init"));
        // defer msg_void(pool, sel("release"));

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

        send(self.app, void, "sendEvent:", .{event});
    }
    // msg_void_bool(self.view, sel("setNeedsDisplay:"), YES);
    return 0;
}
