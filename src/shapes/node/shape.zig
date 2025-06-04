const std = @import("std");
const dataShape = @import("data/shape.zig").Shape;

pub const Shape = struct {
    parent: ?*Shape,
    children: std.ArrayList(*Shape),
    key: []const u8,
    data: dataShape,
};
