const std = @import("std");
const node = @import("../node/index.zig");

pub const Shape = struct {
    allocator: std.mem.Allocator,
    behaviors: struct {
        pathing: struct {
            delimeter: u8,
        },
        data: std.ArrayList(node.data.behavior.Shape),
    },
};
