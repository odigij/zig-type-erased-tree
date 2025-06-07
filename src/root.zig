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

test "test-00" {
    const ctx = try funcs.context.service.create(std.testing.allocator);
    const documentBehavior = try funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "document",
            .initFn = initDocument,
            .freeFn = freeDocument,
        },
    );
    var base = [_]u8{ 'c', 'h', 'i', 'l', 'd', 'r', 'e', 'n', '-', '0', '0' };
    var buffer: []u8 = &base;
    const root_index = try funcs.node.service.create(ctx, "root", documentBehavior.*.tag);
    for (0..10) |i| {
        const tens: u8 = @intCast(i / 10);
        const ones: u8 = @intCast(i % 10);
        buffer[9] = '0' + tens;
        buffer[10] = '0' + ones;
        const childIndex = try funcs.node.service.create(ctx, buffer, documentBehavior.*.tag);
        try funcs.node.service.attach(ctx, i, childIndex);
    }

    for (ctx.*.nodes.items) |node| {
        const casted_data: *Document = @alignCast(@ptrCast(node.data.ptr));
        const parent = if (node.parent) |p| p else null;
        std.debug.print(
            "Node:\n\tkey: {s}\n\tdata:\n\t\tparent: {?}\n\t\tchildren: {any}\n\t\tname: {s},\n\t\t \n\t\text: {s},\n\t\t size: {d}\n",
            .{ node.key, parent, node.children, casted_data.*.name, casted_data.*.ext, casted_data.*.size },
        );
    }

    const path_index = try funcs.node.service.get(ctx, 0, "children-00/children-01/children-02");
    const found_node = ctx.*.nodes.items[path_index];
    const casted_data: *Document = @alignCast(@ptrCast(found_node.data.ptr));
    const parent = if (found_node.parent) |p| p else null;
    std.debug.print(
        "Node:\n\tkey: {s}\n\tdata:\n\t\tparent: {?}\n\t\tchildren: {any}\n\t\tname: {s},\n\t\t \n\t\text: {s},\n\t\t size: {d}\n",
        .{ found_node.key, parent, found_node.children, casted_data.*.name, casted_data.*.ext, casted_data.*.size },
    );

    try funcs.node.service.free(ctx, root_index);
    funcs.context.service.destroy(ctx);
}
