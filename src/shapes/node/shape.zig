const std = @import("std");
const data = @import("data/shape.zig").Shape;

pub const Shape = struct {
    parent: ?usize,
    children: std.ArrayList(usize),
    key: []const u8,
    data: data,
};
