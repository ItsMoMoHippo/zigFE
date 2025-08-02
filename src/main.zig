const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const TextInput = vaxis.widgets.TextInput;
const Key = vaxis.Key;

const Exp = @import("explorer.zig");

const Event = union(enum) {
    key_pressed: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
    foo: u8,
};

pub fn main() !void {
    //allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    //init tty
    const tty = try vaxis.Tty.init();
    defer tty.deinit();

    //init vaxis
    var vx = try vaxis.init(alloc, .{});
    defer vx.deinit(alloc, tty.anyWriter());

    //event loop
    var loop: vaxis.Loop(Event) = .{
        .tty = &tty,
        .vaxis = &vx,
    };
    try loop.init();

    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(tty.anyWriter());

    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    while (true) {
        const event = loop.nextEvent();
        switch (event) {
            .key_pressed => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                }
                if (key.matches(Key.up, .{})) {
                    break;
                }
                if (key.matches(Key.down, .{})) {
                    break;
                }
                if (key.matches(Key.enter, .{})) {
                    //dir iterate
                }
            },
            .winsize => |ws| try vx.resize(alloc, tty.anyWriter(), ws),
            else => {},
        }
        const win = vx.window();
        win.clear();

        try vx.render(tty.anyWriter());
    }

    //open up dir
    var cwd = try fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    //make lists
    var dirs = std.ArrayList([]const u8).init(alloc);
    defer dirs.deinit();
    var files = std.ArrayList([]const u8).init(alloc);
    defer files.deinit();

    try dirIterate(cwd, &dirs, &files, alloc);

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

    for (dirs.items) |name| alloc.free(name);
    for (files.items) |name| alloc.free(name);
}

/// Sort strings
fn sortSlices(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

/// Crawls the directory and puts all immediate children into directory and
/// file arraylists
///
/// The caller is expected to clear the lists before calling this function.
///
/// ## Example
/// ```zig
/// var dirs  = std.ArrayList([]const u8).init(allocator);
/// var files = std.ArrayList([]const u8).init(allocator);
/// defer dirs.deinit();
/// defer files.deinit();
///
/// try dirIterate(dir, &dirs, &files, allocator);
/// ```
fn dirIterate(dir: std.fs.Dir, dirList: *std.ArrayList([]const u8), fileList: *std.ArrayList([]const u8), alloc: std.mem.Allocator) !void {
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        const name = try alloc.dupe(u8, entry.name);
        switch (entry.kind) {
            .directory => try dirList.append(name),
            .file => try fileList.append(name),
            else => {},
        }
    }
}
