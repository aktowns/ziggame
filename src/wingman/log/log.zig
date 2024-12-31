const Log = @This();

const std = @import("std");
const builtin = @import("builtin");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = if (builtin.target.isWasm()) std.heap.c_allocator else gpa.allocator();

pub inline fn info(comptime src: std.builtin.SourceLocation, comptime format: []const u8, args: anytype) void {
    const out = std.fmt.allocPrint(allocator, format, args) catch unreachable;
    std.log.info("[{s}:{s}:{d}] {s}", .{ src.file, src.fn_name, src.line, out });
    allocator.free(out);
}

pub inline fn debug(comptime src: std.builtin.SourceLocation, comptime format: []const u8, args: anytype) void {
    const out = std.fmt.allocPrint(allocator, format, args) catch unreachable;
    std.log.debug("[{s}:{s}:{d}] {s}", .{ src.file, src.fn_name, src.line, out });
    allocator.free(out);
}

pub inline fn err(comptime src: std.builtin.SourceLocation, comptime format: []const u8, args: anytype) void {
    const out = std.fmt.allocPrint(allocator, format, args) catch unreachable;
    std.log.err("[{s}:{s}:{d}] {s}", .{ src.file, src.fn_name, src.line, out });
    allocator.free(out);
}
