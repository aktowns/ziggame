const std = @import("std");
const Thread = std.Thread;
const builtin = @import("builtin");

pub fn Signal(comptime Ctx: type) type {
    return struct {
        name: []const u8 = @typeName(@This()),
        subscribers: Subscribers,
        allocator: std.mem.Allocator,

        const Callback = *const fn (event: *const @This(), ctx: *const Ctx, user_data: ?*anyopaque) void;
        const Subscriber = struct { cb: Callback, user_data: ?*anyopaque };
        const Subscribers = std.ArrayList(Subscriber);

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .subscribers = Subscribers.init(allocator),
                .allocator = allocator,
            };
        }

        fn process(self: *const @This(), sub: Subscriber, ctx: *const Ctx) void {
            std.log.debug("[{s}] processing event: {?}", .{ self.name, Thread.getCurrentId() });

            sub.cb(self, ctx, sub.user_data);
        }

        pub fn fire(self: *const @This(), ctx: *const Ctx, deinit: ?*const fn (ctx: *const Ctx) void) !void {
            std.log.debug("[{s}] firing event on thread {?}", .{ self.name, Thread.getCurrentId() });
            var workers = std.ArrayList(Thread).init(self.allocator);

            for (self.subscribers.items) |subscriber| {
                const thr = try Thread.spawn(.{ .allocator = self.allocator }, process, .{ self, subscriber, ctx });
                try workers.append(thr);
            }

            for (workers.items) |thr| {
                thr.join();
            }

            if (deinit != null) deinit.?(ctx);
        }

        pub fn fireAsync(self: *const @This(), ctx: *const Ctx, deinit: ?*const fn (ctx: *const Ctx) void) !void {
            var thr = try Thread.spawn(.{ .allocator = self.allocator }, fire, .{ self, ctx, deinit });

            thr.detach();
        }

        pub fn subscribe(self: *@This(), f: Callback, user_data: ?*anyopaque) !void {
            try self.subscribers.append(Subscriber{ .cb = f, .user_data = user_data });
        }
    };
}
