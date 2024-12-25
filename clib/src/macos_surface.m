#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>

//#import "osxextra.h"

CAMetalLayer* getOSXSurface(NSWindow* window) {
    NSView* view = [window contentView];
    CAMetalLayer* layer = [CAMetalLayer layer];

    [view setWantsLayer:YES];
    [view setLayer:layer];

    return layer;
}
