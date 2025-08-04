const std = @import("std");

const fe = @import("explorer.zig");

const vaxis = @import("vaxis");

pub fn main() !void {
    // allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // set up fs walker/scanner
    var fileExplorer = try fe.DirScanner.init(alloc);
    defer fileExplorer.deinit();

    // init tty
    var tty = try vaxis.Tty.init();
    defer tty.deinit();

    // init vaxis
    var vx = try vaxis.init(alloc, .{});
    defer vx.deinit(alloc, tty.anyWriter());
}
