const std = @import("std");
pub const shapes = @import("../../shapes/index.zig");
pub const contextFuncs = @import("../context/index.zig");

/// Adds a new tree node with the given key and tag.
pub fn create(context: *shapes.context.Shape, key: []const u8, tag: []const u8) !usize {
    // NOTE:
    // - Duplicating strings due to not want to depend on global strings.
    const behavior = try contextFuncs.behavior.service.find(context.behaviors.data, tag);

    var data: ?*anyopaque = null;
    if (behavior.*.initFn) |alloc_behavior| {
        try alloc_behavior(context.allocator, &data);
    }

    const key_dup = try context.*.allocator.dupe(u8, key);
    const tag_dup = try context.*.allocator.dupe(u8, tag);
    const node = try context.*.tree.nodes.addOne();
    node.* = .{
        .parent = null,
        .children = std.ArrayList(usize).init(context.*.allocator),
        .key = key_dup,
        .data = .{
            .tag = tag_dup,
            .ptr = data,
        },
    };
    if (context.*.tree.nodes.items.len == 1) {
        context.*.tree.root_index = 0;
    }
    return context.*.tree.nodes.items.len - 1;
}

fn find(context: *shapes.context.Shape, index: usize, keys: *std.ArrayList([]const u8)) !usize {
    if (keys.items.len == 0) {
        return index;
    }
    const key = keys.orderedRemove(0);
    const node = &context.*.tree.nodes.items[index];
    for (node.*.children.items) |child_index| {
        const child_node = &context.*.tree.nodes.items[child_index];
        if (std.mem.eql(u8, child_node.key, key)) {
            return find(context, child_index, keys);
        }
    }
    return error.NodeNotFound;
}

/// Splits path into keys according to delimeter and starts recursive search from the given node index.
pub fn get(context: *shapes.context.Shape, node_index: usize, path: []const u8) !usize {
    var iterator = std.mem.splitScalar(u8, path, context.*.behaviors.pathing.delimeter);
    var parts = std.ArrayList([]const u8).init(context.*.allocator);
    defer parts.deinit();
    while (iterator.next()) |part| {
        if (part.len > 0) {
            try parts.append(part);
        }
    }

    return try find(context, node_index, &parts);
}

/// Re-allocates parent's children container and appends child index.
pub fn attach(context: *shapes.context.Shape, parent_index: usize, child_index: usize) !void {
    const parent = &context.*.tree.nodes.items[parent_index];
    try parent.*.children.append(child_index);
    const child = &context.*.tree.nodes.items[child_index];
    child.parent = parent_index;
}

/// Searches for node data behavior & runs deallocation behavior.
fn free(context: *shapes.context.Shape, index: usize) !void {
    const node = &context.*.tree.nodes.items[index];
    const behavior = try contextFuncs.behavior.service.find(context.*.behaviors.data, node.data.tag);
    if (behavior.freeFn) |run| {
        try run(context.*.allocator, &node.data.ptr);
    }
    context.*.allocator.free(node.key);
    context.*.allocator.free(node.data.tag);
    node.children.deinit();
    // _ = context.*.tree.nodes.orderedRemove(index);
}

/// Recursively frees node downward, along with any allocated custom data.
pub fn freeDownward(context: *shapes.context.Shape, index: usize) !void {
    const node = &context.*.tree.nodes.items[index];
    for (node.*.children.items) |i| {
        try freeDownward(context, i);
    }
    try free(context, index);
}

/// Recursively frees node from root.
pub fn freeTree(context: *shapes.context.Shape) !void {
    try freeDownward(context, context.*.tree.root_index);
}
