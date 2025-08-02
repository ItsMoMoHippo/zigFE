const std = @import("std");

const DirView = struct {
    cwd: std.fs.Dir,
    dirList: std.ArrayList([]const u8),
    fileList: std.ArrayList([]const u8),
    alloc: std.mem.Allocator,

    ///init
    pub fn init(allocator: std.mem.Allocator) !DirView {
        const curr_dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
        return DirView{
            .cwd = curr_dir,
            .dirList = std.ArrayList([]const u8).init(allocator),
            .fileList = std.ArrayList([]const u8).init(allocator),
            .alloc = allocator,
        };
    }

    ///deinit
    pub fn deinit(self: *DirView) void {
        for (self.dirList.items) |name| self.alloc.free(name);
        self.dirList.deinit();
        for (self.fileList.items) |name| self.alloc.free(name);
        self.fileList.deinit();
    }

    /// grabs all files and sub dirs
    pub fn crawl_cwd(self: *DirView) !void {
        var iter = self.cwd.iterate();
        while (try iter.next()) |entry| {
            const name = try self.alloc.dupe(u8, entry.name);
            switch (entry.kind) {
                .directory => try self.dirList.append(name),
                .file => try self.fileList.append(name),
                else => self.alloc.free(name),
            }
        }
        std.mem.sortUnstable([]const u8, self.dirList.items, {}, sort_slices);
        std.mem.sortUnstable([]const u8, self.fileList.items, {}, sort_slices);
    }

    /// Sort strings
    fn sort_slices(_: void, a: []const u8, b: []const u8) bool {
        return std.mem.lessThan(u8, a, b);
    }

    /// change cwd
    pub fn set_cwd(self: *DirView, dir: std.fs.Dir) void {
        for (self.dirList.items) |name| self.alloc.free(name);
        self.dirList.clearRetainingCapacity();
        for (self.fileList.items) |name| self.alloc.free(name);
        self.fileList.clearRetainingCapacity();

        self.cwd.close();
        self.cwd = dir;
    }

    ///prints all immediate children of a dir
    pub fn print_all(self: *DirView) void {
        std.debug.print("dirs:\n", .{});
        for (self.dirList.items) |dir| {
            std.debug.print("\t{s}\n", .{dir});
        }
        std.debug.print("files:\n", .{});
        for (self.fileList.items) |file| {
            std.debug.print("\t{s}\n", .{file});
        }
    }

    pub fn enter_dir(self: *DirView, dir_name: []const u8) !void {
        const new_dir = try self.cwd.openDir(dir_name, .{ .iterate = true });
        self.set_cwd(new_dir);
    }

    pub fn go_up(self: *DirView) !void {
        const parent = try self.cwd.openDir("..", .{ .iterate = true });
        self.set_cwd(parent);
    }
};
