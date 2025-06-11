const std = @import("std");

pub const shapes = @import("shapes/index.zig");
pub const funcs = @import("funcs/index.zig");

const Document = struct {
    name: []const u8,
    ext: []const u8,
    createdAt: []const u8,
    size: u32,
};

fn initDocument(allocator: std.mem.Allocator, data: *?*anyopaque) !void {
    const known = try allocator.create(Document);
    known.* = .{
        .name = "empty-name",
        .ext = "empty-ext",
        .createdAt = "empty-creation-date",
        .size = 0,
    };
    data.* = @ptrCast(known);
}

fn freeDocument(allocator: std.mem.Allocator, data: *?*anyopaque) !void {
    if (data.*) |ptr| {
        const typed: *Document = @alignCast(@ptrCast(ptr));
        allocator.destroy(typed);
        data.* = null;
    }
}

test "create context" {
    const ctx = try funcs.context.service.create(std.testing.allocator);
    try std.testing.expectEqual(shapes.context.Shape, @TypeOf(ctx.*));
    funcs.context.service.destroy(ctx);
}

test "register valid behaviors" {
    const ctx = try funcs.context.service.create(std.testing.allocator);
    const nullBehavior = try funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "null_behavior",
            .initFn = null,
            .freeFn = null,
        },
    );
    try std.testing.expectEqual(shapes.node.data.behavior.Shape, @TypeOf(nullBehavior.*));
    const documentBehavior = try funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "document",
            .initFn = initDocument,
            .freeFn = freeDocument,
        },
    );
    try std.testing.expectEqual(shapes.node.data.behavior.Shape, @TypeOf(documentBehavior.*));
    funcs.context.service.destroy(ctx);
}

test "register invalid behaviors" {
    const ctx = try funcs.context.service.create(std.testing.allocator);
    const nullBehavior = funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "",
            .initFn = null,
            .freeFn = null,
        },
    );
    try std.testing.expectError(error.invalid_tag, nullBehavior);

    const documentBehavior = funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "",
            .initFn = initDocument,
            .freeFn = freeDocument,
        },
    );
    try std.testing.expectError(error.invalid_tag, documentBehavior);

    funcs.context.service.destroy(ctx);
}

test "registering null data behavior root" {
    const ctx = try funcs.context.service.create(std.testing.allocator);
    const nullBehavior = try funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "null_behavior",
            .initFn = null,
            .freeFn = null,
        },
    );
    _ = try funcs.node.service.create(ctx, "root", nullBehavior.*.tag);
    try std.testing.expectEqual(0, ctx.*.tree.root_index);
    try std.testing.expectEqual(ctx.*.tree.nodes.items.len, 1);
    try funcs.node.service.freeTree(ctx);
    // try std.testing.expectEqual(ctx.*.tree.nodes.items.len, 0);
    funcs.context.service.destroy(ctx);
}

test "single line tree with custom data behavior" {
    const ctx = try funcs.context.service.create(std.testing.allocator);
    const documentBehavior = try funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "document",
            .initFn = initDocument,
            .freeFn = freeDocument,
        },
    );
    _ = try funcs.node.service.create(ctx, "root", documentBehavior.*.tag);

    var base = [_]u8{ 'c', 'h', 'i', 'l', 'd', 'r', 'e', 'n', '-', '0', '0' };
    var buffer: []u8 = &base;

    for (0..10) |i| {
        const tens: u8 = @intCast(i / 10);
        const ones: u8 = @intCast(i % 10);
        buffer[9] = '0' + tens;
        buffer[10] = '0' + ones;
        const childIndex = try funcs.node.service.create(ctx, buffer, documentBehavior.*.tag);
        try funcs.node.service.attach(ctx, i, childIndex);
    }

    for (ctx.*.tree.nodes.items) |node| {
        const casted_data: *Document = @alignCast(@ptrCast(node.data.ptr));
        try std.testing.expectEqual(Document, @TypeOf(casted_data.*));
        try std.testing.expectEqual("empty-name", casted_data.*.name);
        try std.testing.expectEqual("empty-ext", casted_data.*.ext);
        try std.testing.expectEqual("empty-creation-date", casted_data.*.createdAt);
        try std.testing.expectEqual(@as(u32, 0), casted_data.*.size);
        // const parent = if (node.parent) |p| p else null;
        // std.debug.print(
        //     "Node {s}\n\tdata:\n\t\tparent: {?}\n\t\tchildren: {any}\n\t\tname: {s},\n\t\t \n\t\text: {s},\n\t\t size: {d}\n______________________________________________\n",
        //     .{ node.key, parent, node.children.items, casted_data.*.name, casted_data.*.ext, casted_data.*.size },
        // );
    }

    const found_index = try funcs.node.service.get(ctx, 0, "children-00/children-01/children-02");
    const found_node = ctx.*.tree.nodes.items[found_index];
    const casted_data: *Document = @alignCast(@ptrCast(found_node.data.ptr));
    try std.testing.expectEqual(Document, @TypeOf(casted_data.*));
    try std.testing.expectEqual("empty-name", casted_data.*.name);
    try std.testing.expectEqual("empty-ext", casted_data.*.ext);
    try std.testing.expectEqual("empty-creation-date", casted_data.*.createdAt);
    try std.testing.expectEqual(@as(u32, 0), casted_data.*.size);

    // const parent = if (found_node.parent) |p| p else null;
    // std.debug.print(
    //     "Retrieved node via path {s}\n\tdata:\n\t\tparent: {?}\n\t\tchildren: {any}\n\t\tname: {s},\n\t\t \n\t\text: {s},\n\t\t size: {d}\n______________________________________________\n",
    //     .{ found_node.key, parent, found_node.children.items, casted_data.*.name, casted_data.*.ext, casted_data.*.size },
    // );

    try funcs.node.service.freeTree(ctx);
    funcs.context.service.destroy(ctx);
}

test "random tree branches with custom data behavior" {
    const ctx = try funcs.context.service.create(std.testing.allocator);
    const behavior = try funcs.context.behavior.service.register(ctx, .{
        .tag = "document",
        .initFn = initDocument,
        .freeFn = freeDocument,
    });

    const root_index = try funcs.node.service.create(ctx, "root", behavior.*.tag);

    var created_indices = try std.ArrayList(usize).initCapacity(std.testing.allocator, 11);
    defer created_indices.deinit();
    try created_indices.append(root_index);

    var base = [_]u8{ 'c', 'h', 'i', 'l', 'd', 'r', 'e', 'n', '-', '0', '0' };
    var buffer: []u8 = &base;

    var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    const rand = prng.random();

    for (0..10) |i| {
        const tens: u8 = @intCast(i / 10);
        const ones: u8 = @intCast(i % 10);
        buffer[9] = '0' + tens;
        buffer[10] = '0' + ones;

        const child_index = try funcs.node.service.create(ctx, buffer, behavior.*.tag);

        const parent_index = created_indices.items[rand.intRangeAtMost(usize, 0, created_indices.items.len - 1)];
        try funcs.node.service.attach(ctx, parent_index, child_index);

        try created_indices.append(child_index);
    }

    for (ctx.*.tree.nodes.items) |node| {
        const doc: *Document = @alignCast(@ptrCast(node.data.ptr));
        try std.testing.expectEqualStrings("empty-name", doc.name);
        try std.testing.expectEqualStrings("empty-ext", doc.ext);
        try std.testing.expectEqualStrings("empty-creation-date", doc.createdAt);
        try std.testing.expectEqual(@as(u32, 0), doc.size);
    }

    try funcs.node.service.freeTree(ctx);
    funcs.context.service.destroy(ctx);
}
