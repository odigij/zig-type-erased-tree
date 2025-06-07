const std = @import("std");
const shapes = @import("../../shapes/index.zig");

pub const Shape = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(shapes.node.Shape),
    behaviors: struct {
        pathing: struct {
            delimeter: u8,
        },
        data: std.ArrayList(shapes.node.data.behavior.Shape),
    },
};
