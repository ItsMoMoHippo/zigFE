const std = @import("std");

pub const DirScanner = struct {
    /// Directory currently being used
    cur_dir: std.fs.Dir,

    /// List of all immediate sub directories
    dirList: std.ArrayList([]const u8),

    /// List of all files that are immediate
    /// children of the current working directory
    fileList: std.ArrayList([]const u8),

    /// Allocator used for dynamic allocations
    alloc: std.mem.Allocator,

    /// init the struct
    pub fn init(allocator: std.mem.Allocator) !DirScanner {
        return DirScanner{
            .cur_dir = try std.fs.cwd().openDir(".", .{ .iterate = true }),
            .dirList = std.ArrayList([]const u8).init(allocator),
            .fileList = std.ArrayList([]const u8).init(allocator),
            .alloc = allocator,
        };
    }

    /// cleans up resources
    pub fn deinit(self: *DirScanner) void {
        self.clear_list();
        self.dirList.deinit();
        self.fileList.deinit();
        self.cur_dir.close();
    }

    /// moves to parent dir
    pub fn go_up(self: *DirScanner) !void {
        const parent_dir = try self.cur_dir.openDir("..", .{ .iterate = true });
        self.clear_list();
        self.cur_dir.close();
        self.cur_dir = parent_dir;
        try self.scan_dir();
    }

    /// enters a child dir
    pub fn enter_sub_dir(self: *DirScanner, sub_dir: []const u8) !void {
        const new_dir = try self.cur_dir.openDir(sub_dir, .{ .iterate = true });
        self.clear_list();
        self.cur_dir.close();
        self.cur_dir = new_dir;
        try self.scan_dir();
    }

    /// scan the contents of a directory
    pub fn scan_dir(self: *DirScanner) !void {
        self.clear_list();

        var iter = self.cur_dir.iterate();
        while (try iter.next()) |entry| {
            const name = try self.alloc.dupe(u8, entry.name);
            switch (entry.kind) {
                .file => try self.fileList.append(name),
                .directory => try self.dirList.append(name),
                else => self.alloc.free(name),
            }
        }

        std.mem.sort([]const u8, self.dirList.items, {}, sort_slices);
        std.mem.sort([]const u8, self.fileList.items, {}, sort_slices);
    }

    /// prints values of items in the current directory
    ///
    /// For debugging moving through directories
    pub fn print_all(self: *const DirScanner) void {
        std.debug.print("dirs:\n", .{});
        for (self.dirList.items) |dir| {
            std.debug.print("\t{s}/\n", .{dir});
        }
        std.debug.print("files:\n", .{});
        for (self.fileList.items) |file| {
            std.debug.print("\t{s}\n", .{file});
        }
        std.debug.print("\n", .{});
    }

    /// Sort strings
    fn sort_slices(_: void, a: []const u8, b: []const u8) bool {
        return std.mem.lessThan(u8, a, b);
    }

    /// clear lists
    fn clear_list(self: *DirScanner) void {
        for (self.dirList.items) |n| self.alloc.free(n);
        for (self.fileList.items) |n| self.alloc.free(n);
        self.dirList.clearRetainingCapacity();
        self.fileList.clearRetainingCapacity();
    }
};
