const std = @import("std");
pub const shapes = @import("../../shapes/index.zig");
pub const contextFuncs = @import("../context/index.zig");

/// Adds a new tree node with the given key and tag.
pub fn create(context: *shapes.context.Shape, key: []const u8, tag: []const u8) !usize {
    // NOTE:
    // - Duplicating strings due to not want to depend on global strings.
    const key_dup = try context.allocator.dupe(u8, key);
    const tag_dup = try context.allocator.dupe(u8, tag);
    const behavior = try contextFuncs.behavior.service.find(context.behaviors.data, tag_dup);

    const node = context.*.nodes.addOne() catch |err| {
        context.allocator.free(key_dup);
        context.allocator.free(tag_dup);
        return err;
    };

    var data_ptr: ?*anyopaque = null;
    if (behavior.*.initFn) |run| {
        try run(context.allocator, &data_ptr);
    }

    const children = context.allocator.alloc(usize, 0) catch |err| {
        if (behavior.freeFn) |cleanup| {
            try cleanup(context.allocator, &data_ptr);
        }
        context.allocator.free(key_dup);
        context.allocator.free(tag_dup);
        return err;
    };

    const index = context.nodes.items.len - 1;

    node.* = .{
        .parent = null,
        .children = children,
        .key = key_dup,
        .data = .{
            .tag = tag_dup,
            .ptr = data_ptr,
        },
    };

    return index;
}

fn splitPath(allocator: std.mem.Allocator, path: []const u8, delimeter: u8) !std.ArrayList([]const u8) {
    var iterator = std.mem.splitScalar(u8, path, delimeter);
    var parts = std.ArrayList([]const u8).init(allocator);
    while (iterator.next()) |part| {
        if (part.len > 0) {
            try parts.append(part);
        }
    }
    return parts;
}

fn find(context: *shapes.context.Shape, index: usize, keys: *std.ArrayList([]const u8)) !usize {
    const node = &context.nodes.items[index];
    if (keys.items.len == 0) {
        return index;
    }
    const key = keys.orderedRemove(0);
    for (node.children) |i| {
        const child = &context.nodes.items[i];
        if (std.mem.eql(u8, child.key, key)) {
            return find(context, i, keys);
        }
    }
    return error.NodeNotFound;
}

pub fn get(context: *shapes.context.Shape, node_index: usize, path: []const u8) !usize {
    var keys = try splitPath(context.allocator, path, context.behaviors.pathing.delimeter);
    defer keys.deinit();
    return try find(context, node_index, &keys);
}

pub fn attach(context: *shapes.context.Shape, parent_index: usize, child_index: usize) !void {
    const parent = &context.nodes.items[parent_index];
    const child = &context.nodes.items[child_index];

    // Expand parent's children list
    const new_children: []usize = try context.allocator.realloc(parent.*.children, parent.*.children.len + 1);
    new_children[parent.*.children.len] = child_index;
    parent.*.children = new_children;

    // Set child's parent index
    child.parent = parent_index;
}

/// Recursively frees the node downward, along with any allocated tag data.
pub fn free(context: *shapes.context.Shape, index: usize) !void {
    const node = &context.nodes.items[index];
    for (node.*.children) |i| {
        try free(context, i);
    }
    const behavior = try contextFuncs.behavior.service.find(context.behaviors.data, node.data.tag);
    if (behavior.freeFn) |run| {
        try run(context.allocator, &node.data.ptr);
    }
    context.allocator.free(node.key);
    context.allocator.free(node.data.tag);
    context.allocator.free(node.children);
}
