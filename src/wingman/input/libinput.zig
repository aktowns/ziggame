pub const Libinput = @This();

const c = @cImport({
    @cInclude("libinput.h");
    @cInclude("libudev.h");
});

udev: *c.udev,
libinput = *c.libinput,

pub fn init() @This() {
    const uctx = c.udev_new();
    const lctx = c.libinput_udev_create_context(&c.libinput_interface, null, uctx);
    c.libinput_udev_assign_seat(lctx, "seat0");

    return .{ .udev = uctx };
}
