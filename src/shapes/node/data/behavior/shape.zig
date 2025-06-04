const std = @import("std");

pub const Shape = struct {
    tag: []const u8,
    initFn: ?*const fn (allocator: std.mem.Allocator, *?*anyopaque) anyerror!void,
    freeFn: ?*const fn (allocator: std.mem.Allocator, *?*anyopaque) anyerror!void,
};
