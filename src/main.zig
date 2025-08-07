const std = @import("std");

const fe = @import("explorer.zig");

const vaxis = @import("vaxis");

const Event = union(enum) {
    key_pressed: vaxis.Key,
    winsize: vaxis.Winsize,
};

const App = struct {
    alloc: std.mem.Allocator,
    should_quit: bool,
    tty: vaxis.Tty,
    xv: vaxis.Vaxis,
    explorer: fe.DirScanner,
    cursor: usize,

    pub fn init(allocator: std.mem.Allocator) !App {
        return App{
            .alloc = allocator,
            .should_quit = false,
            .tty = try vaxis.Tty.init(),
            .xv = try vaxis.init(allocator, .{}),
            .explorer = try fe.DirScanner.init(allocator),
            .cursor = 0,
        };
    }

    pub fn deinit(self: *App) void {
        self.explorer.deinit();
        self.xv.deinit(self.alloc, self.tty.anyWriter());
        self.tty.deinit();
    }

    pub fn run(self: *App) !void {
        var loop: vaxis.Loop(Event) = .{
            .tty = &self.tty,
            .vaxis = &self.xv,
        };
        try loop.init();
        try loop.start();

        try self.xv.queryTerminal(self.tty.anyWriter(), 1 * std.time.ns_per_s);

        while (!self.should_quit) {
            loop.pollEvent();
            while (loop.tryEvent()) |event| {
                try self.update(event);
            }
            self.draw();

            var buffered = self.tty.bufferedWriter();
            try self.xv.render(buffered.writer().any());
            try buffered.flush();
        }
    }

    pub fn update(self: *App, event: Event) !void {
        switch (event) {
            .key_pressed => |key| {
                if (key.matches('c', .{ .ctrl = true })) self.should_quit = true;
                //TODO: change to backspace
                if (key.matches('u', .{})) try self.explorer.go_up();
                //TODO: change to enter
                if (key.matches('d', .{})) try self.explorer.enter_sub_dir("foo");
                //TODO: change to up arrow
                if (key.matches('k', .{})) {
                    if (self.cursor != 0) {
                        self.cursor -= 1;
                    }
                }
                //TODO: change to down arrow
                if (key.matches('j', .{})) {
                    const items = self.explorer.dirList.items.len + self.explorer.fileList.items.len;
                    if (self.cursor != items - 1) {
                        self.cursor += 1;
                    }
                }
            },
            .winsize => |ws| try self.xv.resize(self.alloc, self.tty.anyWriter(), ws),
        }
    }

    pub fn draw(self: *App) void {
        const msg = "Hello, world!";

        const win = self.xv.window();

        win.clear();

        const child = win.child(.{
            .x_off = (win.width / 2) - 7,
            .y_off = win.height / 2 + 1,
            .width = .{ .limit = msg.len },
            .height = .{ .limit = 1 },
        });

        _ = try child.printSegment(.{ .text = msg }, .{});
    }
};

pub fn main() !void {
    // allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var app = try App.init(alloc);
    defer app.deinit();

    try app.run();
}
