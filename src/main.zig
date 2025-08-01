const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

pub fn main() !void {
    //allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    //open up dir
    var cwd = try fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    //make lists
    var dirs = std.ArrayList([]const u8).init(alloc);
    defer dirs.deinit();
    var files = std.ArrayList([]const u8).init(alloc);
    defer files.deinit();

    //iterate over dir
    var iter = cwd.iterate();
    while (try iter.next()) |entry| {
        switch (entry.kind) {
            .directory => try dirs.append(entry.name),
            .file => try files.append(entry.name),
            else => {},
        }
    }

    //sort alphabetically
    std.mem.sortUnstable([]const u8, dirs.items, {}, sortSlices);
    std.mem.sortUnstable([]const u8, files.items, {}, sortSlices);

    //print
    print("dirs:\n", .{});
    for (dirs.items) |dir| {
        print("\t{s}/\n", .{dir});
    }
    print("files:\n", .{});
    for (files.items) |file| {
        print("\t{s}\n", .{file});
    }
}

fn sortSlices(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}
