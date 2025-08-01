const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello world!\n", .{});

    std.debug.print("\n", .{});

    //const array
    const words = [_][]const u8{ "apple", "banana", "pear" };

    for (words) |word| {
        std.debug.print("{s}\n", .{word});
    }

    std.debug.print("\n", .{});

    //array list
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var list = std.ArrayList([]const u8).init(alloc);
    defer list.deinit();

    try list.append("orange");
    try list.append("grape");
    try list.append("mango");

    for (list.items) |item| {
        std.debug.print("{s}\n", .{item});
    }
}
