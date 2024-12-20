#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>

//    std.log.info("Using MacOS Surface", .{});
//    const objc = @import("objc");
//
//    const ns_window = glfw.glfwGetCocoaWindow(window);
//    const objc_window = objc.Object.fromId(ns_window);
//    const objc_view = objc_window.getProperty(objc.Object, "contentView");
//
//    _ = objc_view.msgSend(objc.Object, "setWantsLayer:", .{true});
//    const CAMetalLayer = objc.getClass("CAMetalLayer").?;
//    const layer = CAMetalLayer.msgSend(objc.Object, "layer", .{});
//    _ = objc_view.msgSend(objc.Object, "setLayer:", .{layer});
//
//    var strct = self.allocator.create(wg.WGPUSurfaceDescriptorFromMetalLayer) catch return Error.FailedToConstructSurface;
//    strct.chain = wg.WGPUChainedStruct{ .sType = wg.WGPUSType_SurfaceSourceMetalLayer, .next = null };
//    strct.layer = layer.value;
#import "metal.h"

CAMetalLayer* getOSXSurface(NSWindow* window) {
    NSView* view = [window contentView];
    CAMetalLayer* layer = [CAMetalLayer layer];

    [view setWantsLayer:YES];
    [view setLayer:layer];

    return layer;
}