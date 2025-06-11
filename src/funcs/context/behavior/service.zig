const std = @import("std");
const shapes = @import("../../../shapes/index.zig");

/// Stores behavior by tag validation.
/// Returns temporary behavior pointer.
pub fn register(context: *shapes.context.Shape, new: shapes.node.data.behavior.Shape) !*shapes.node.data.behavior.Shape {
    if (new.tag.len == 0) {
        return error.invalid_tag;
    }
    for (context.*.behaviors.data.items) |item| {
        if (std.mem.eql(u8, item.tag, new.tag)) {
            return error.BehaviorExists;
        }
    }
    try context.*.behaviors.data.append(new);
    return &context.*.behaviors.data.items[context.*.behaviors.data.items.len - 1];
}

/// Returns the behavior associated with the given tag, or an error if not found.
pub fn find(behaviors: std.ArrayList(shapes.node.data.behavior.Shape), tag: []const u8) anyerror!*shapes.node.data.behavior.Shape {
    for (behaviors.items) |*item| {
        if (std.mem.eql(u8, item.*.tag, tag)) {
            return item;
        }
    }
    return error.BehaviorNotFound;
}
