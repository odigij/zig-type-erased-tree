const std = @import("std");
const tree = @import("lib.zig");

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

test "non-behavioral root test" {
    const ctx: *tree.shapes.context.Shape = try tree.funcs.context.service.create(std.testing.allocator);
    const nullBehavior = try tree.funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "null",
            .initFn = null,
            .freeFn = null,
        },
    );
    const key = "root";
    const root = try tree.funcs.node.service.create(ctx, key, nullBehavior.*.tag);

    try std.testing.expectEqual(*tree.shapes.node.Shape, @TypeOf(root));
    try std.testing.expectEqualStrings(root.*.key, key);
    try std.testing.expectEqual(null, root.*.parent);
    try std.testing.expectEqual(std.ArrayList(*tree.shapes.node.Shape), @TypeOf(root.*.children));
    try std.testing.expectEqual(0, root.*.children.items.len);

    try tree.funcs.node.service.free(ctx, root);
    tree.funcs.context.service.destroy(ctx);
}

test "behavioral root test" {
    const ctx: *tree.shapes.context.Shape = try tree.funcs.context.service.create(std.testing.allocator);
    const nullBehavior = try tree.funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "document",
            .initFn = initDocument,
            .freeFn = freeDocument,
        },
    );
    const key = "root";
    const root = try tree.funcs.node.service.create(ctx, key, nullBehavior.*.tag);

    try std.testing.expectEqual(*tree.shapes.node.Shape, @TypeOf(root));
    try std.testing.expectEqualStrings(root.*.key, key);
    try std.testing.expectEqual(null, root.*.parent);
    try std.testing.expectEqual(std.ArrayList(*tree.shapes.node.Shape), @TypeOf(root.*.children));
    try std.testing.expectEqual(0, root.*.children.items.len);

    const castedRootData: *Document = @alignCast(@ptrCast(root.*.data.ptr));
    castedRootData.* = .{
        .name = "directory-0",
        .ext = "",
        .createdAt = "2025-06-04",
        .size = 0,
    };
    try std.testing.expectEqualStrings("directory-0", castedRootData.name);
    try std.testing.expectEqualStrings("", castedRootData.ext);
    try std.testing.expectEqualStrings("2025-06-04", castedRootData.createdAt);
    try std.testing.expectEqual(@as(u32, 0), castedRootData.size);

    try tree.funcs.node.service.free(ctx, root);
    tree.funcs.context.service.destroy(ctx);
}

test "behavioral child test" {
    const ctx: *tree.shapes.context.Shape = try tree.funcs.context.service.create(std.testing.allocator);
    const documentBehavior = try tree.funcs.context.behavior.service.register(
        ctx,
        .{
            .tag = "document",
            .initFn = initDocument,
            .freeFn = freeDocument,
        },
    );
    const rootKey = "root";
    const root = try tree.funcs.node.service.create(ctx, rootKey, documentBehavior.*.tag);

    try std.testing.expectEqual(*tree.shapes.node.Shape, @TypeOf(root));
    try std.testing.expectEqualStrings(root.*.key, rootKey);
    try std.testing.expectEqual(null, root.*.parent);
    try std.testing.expectEqual(std.ArrayList(*tree.shapes.node.Shape), @TypeOf(root.*.children));
    try std.testing.expectEqual(0, root.*.children.items.len);

    const firstChildKey = "child-1";
    var firstChild = try tree.funcs.node.service.create(ctx, firstChildKey, documentBehavior.tag);
    try root.*.children.append(firstChild);
    firstChild.*.parent = root;

    try std.testing.expectEqual(1, root.*.children.items.len);
    try std.testing.expectEqual(*tree.shapes.node.Shape, @TypeOf(firstChild));
    try std.testing.expectEqualStrings(firstChild.*.key, firstChildKey);
    try std.testing.expectEqual(root, firstChild.*.parent);
    try std.testing.expectEqual(std.ArrayList(*tree.shapes.node.Shape), @TypeOf(firstChild.*.children));
    try std.testing.expectEqual(0, firstChild.*.children.items.len);

    const secondChildKey = "child-2";
    var secondChild = try tree.funcs.node.service.create(ctx, secondChildKey, documentBehavior.tag);
    try root.*.children.append(secondChild);
    secondChild.*.parent = root;

    try std.testing.expectEqual(2, root.*.children.items.len);
    try std.testing.expectEqual(*tree.shapes.node.Shape, @TypeOf(secondChild));
    try std.testing.expectEqualStrings(secondChild.*.key, secondChildKey);
    try std.testing.expectEqual(root, secondChild.*.parent);
    try std.testing.expectEqual(std.ArrayList(*tree.shapes.node.Shape), @TypeOf(secondChild.*.children));
    try std.testing.expectEqual(0, secondChild.*.children.items.len);

    const firstGrandChildKey = "grandchild-1";
    var firstGrandChild = try tree.funcs.node.service.create(ctx, firstGrandChildKey, documentBehavior.*.tag);
    try firstChild.*.children.append(firstGrandChild);
    firstGrandChild.*.parent = firstChild;

    try std.testing.expectEqual(*tree.shapes.node.Shape, @TypeOf(firstGrandChild));
    try std.testing.expectEqualStrings(firstGrandChild.*.key, firstGrandChildKey);
    try std.testing.expectEqual(firstChild, firstGrandChild.*.parent);
    try std.testing.expectEqual(std.ArrayList(*tree.shapes.node.Shape), @TypeOf(firstGrandChild.*.children));
    try std.testing.expectEqual(1, firstChild.*.children.items.len);
    try std.testing.expectEqual(0, firstGrandChild.*.children.items.len);

    const castedRootData: *Document = @alignCast(@ptrCast(root.*.data.ptr));
    castedRootData.* = .{
        .name = "directory-1",
        .ext = "",
        .createdAt = "2025-06-05",
        .size = 2048,
    };
    try std.testing.expectEqualStrings("directory-1", castedRootData.name);
    try std.testing.expectEqualStrings("", castedRootData.ext);
    try std.testing.expectEqualStrings("2025-06-05", castedRootData.createdAt);
    try std.testing.expectEqual(@as(u32, 2048), castedRootData.size);

    firstChild = try tree.funcs.node.service.get(ctx, root, "child-1");
    const castedFirstChildData: *Document = @alignCast(@ptrCast(firstChild.*.data.ptr));
    castedFirstChildData.* = .{
        .name = "directory-2",
        .ext = "",
        .createdAt = "2025-06-05",
        .size = 3072,
    };
    try std.testing.expectEqualStrings("directory-2", castedFirstChildData.name);
    try std.testing.expectEqualStrings("", castedFirstChildData.ext);
    try std.testing.expectEqualStrings("2025-06-05", castedFirstChildData.createdAt);
    try std.testing.expectEqual(@as(u32, 3072), castedFirstChildData.size);

    secondChild = try tree.funcs.node.service.get(ctx, root, "child-2");
    const castedSecondChildData: *Document = @alignCast(@ptrCast(secondChild.*.data.ptr));
    castedSecondChildData.* = .{
        .name = "file-0",
        .ext = ".zog",
        .createdAt = "2025-06-05",
        .size = 1024,
    };
    try std.testing.expectEqualStrings("file-0", castedSecondChildData.*.name);
    try std.testing.expectEqualStrings(".zog", castedSecondChildData.*.ext);
    try std.testing.expectEqualStrings("2025-06-05", castedSecondChildData.*.createdAt);
    try std.testing.expectEqual(@as(u32, 1024), castedSecondChildData.*.size);

    firstGrandChild = try tree.funcs.node.service.get(ctx, root, "child-1/grandchild-1");
    const castedFirstGrandChildData: *Document = @alignCast(@ptrCast(firstGrandChild.*.data.ptr));
    castedFirstGrandChildData.* = .{
        .name = "file-1",
        .ext = ".zig",
        .createdAt = "2025-06-05",
        .size = 2048,
    };
    try std.testing.expectEqualStrings("file-1", castedFirstGrandChildData.*.name);
    try std.testing.expectEqualStrings(".zig", castedFirstGrandChildData.*.ext);
    try std.testing.expectEqualStrings("2025-06-05", castedFirstGrandChildData.*.createdAt);
    try std.testing.expectEqual(@as(u32, 2048), castedFirstGrandChildData.*.size);

    try tree.funcs.node.service.free(ctx, root);
    tree.funcs.context.service.destroy(ctx);
}
