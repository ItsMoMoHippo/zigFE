const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

const fe = @import("explorer.zig");

pub fn main() !void {
    //allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    //set up fs walker/scanner
    var fileExplorer = try fe.DirScanner.init(alloc);
    defer fileExplorer.deinit();

    try fileExplorer.scan_dir();
    fileExplorer.print_all();

    try fileExplorer.go_up();
    try fileExplorer.scan_dir();
    fileExplorer.print_all();

    try fileExplorer.enter_sub_dir("fe");
    try fileExplorer.scan_dir();
    fileExplorer.print_all();
}
