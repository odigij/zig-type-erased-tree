const std = @import("std");
const shapes = @import("../../shapes/index.zig");

/// Creates a new context (shape) with an empty behavior list using the given allocator.
pub fn create(allocator: std.mem.Allocator) !*shapes.context.Shape {
    const context: *shapes.context.Shape = try allocator.create(shapes.context.Shape);
    context.* = .{
        .allocator = allocator,
        .nodes = std.ArrayList(shapes.node.Shape).init(allocator),
        .behaviors = .{
            .pathing = .{
                .delimeter = '/',
            },
            .data = std.ArrayList(shapes.node.data.behavior.Shape).init(allocator),
        },
    };
    return context;
}

/// Destroys the given context, freeing associated memory and behaviors list.
pub fn destroy(context: *shapes.context.Shape) void {
    context.*.behaviors.data.deinit();
    context.*.nodes.deinit();
    context.*.allocator.destroy(context);
}
