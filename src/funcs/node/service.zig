const std = @import("std");
pub const shapes = @import("../../shapes/index.zig");
pub const contextFuncs = @import("../context/index.zig");

/// Creates a new tree node with the given key and tag.
/// Allocates and initializes type-tagged data if a behavior is registered.
pub fn create(context: *shapes.context.Shape, key: []const u8, tag: []const u8) !*shapes.node.Shape {
    // WARN:
    // 1. Validate and prepare dependencies first.
    // 2. If anything goes wrong free earlier allocations.
    const keyDup = try context.allocator.dupe(u8, key);
    const tagDup = try context.allocator.dupe(u8, tag);
    const behavior: *shapes.node.data.behavior.Shape = contextFuncs.behavior.service.find(context, tagDup) catch |err| {
        context.allocator.free(keyDup);
        context.allocator.free(tagDup);
        return err;
    };
    const node: *shapes.node.Shape = try context.allocator.create(shapes.node.Shape);
    node.* = shapes.node.Shape{
        .parent = null,
        .children = std.ArrayList(*shapes.node.Shape).init(context.allocator),
        .key = keyDup,
        .data = .{
            .tag = tagDup,
            .ptr = null,
        },
    };
    if (behavior.*.initFn) |run| {
        run(context.allocator, &node.*.data.ptr) catch |err| {
            node.*.children.deinit();
            context.allocator.free(keyDup);
            context.allocator.free(tagDup);
            context.allocator.destroy(node);
            return err;
        };
    }
    return node;
}

fn splitPath(context: *shapes.context.Shape, path: []const u8, delimeter: u8) !std.ArrayList([]const u8) {
    var iterator = std.mem.splitScalar(u8, path, delimeter);
    var parts = std.ArrayList([]const u8).init(context.*.allocator);
    while (iterator.next()) |part| {
        if (part.len > 0) {
            try parts.append(part);
        }
    }
    return parts;
}

/// Recursively traverses through nodes by fallowing keys.
/// keys: splitted path via delimeter byte.
fn find(node: *shapes.node.Shape, keys: *std.ArrayList([]const u8)) !*shapes.node.Shape {
    if (keys.items.len == 0) return node;
    const key = keys.orderedRemove(0);
    for (node.*.children.items) |child| {
        if (std.mem.eql(u8, child.*.key, key)) {
            return find(child, keys);
        }
    }
    return error.NodeNotFound;
}

/// Recursively searches for the node via path.
pub fn get(context: *shapes.context.Shape, node: *shapes.node.Shape, path: []const u8) !*shapes.node.Shape {
    // NOTE:
    // - keys life limited in this scope via defer.
    var keys = try splitPath(context, path, context.behaviors.pathing.delimeter);
    defer keys.deinit();
    return try find(node, &keys);
}

/// Recursively frees the node downward, along with any allocated tag data.
pub fn free(context: *shapes.context.Shape, node: *shapes.node.Shape) !void {
    for (node.*.children.items) |child| {
        try free(context, child);
    }
    node.*.children.deinit();
    context.*.allocator.free(node.*.key);
    const foundBehavior: *shapes.node.data.behavior.Shape = try contextFuncs.behavior.service.find(context, node.*.data.tag);
    if (foundBehavior.*.freeFn) |run| {
        try run(context.*.allocator, &node.*.data.ptr);
    }
    context.*.allocator.free(node.*.data.tag);
    context.*.allocator.destroy(node);
}
