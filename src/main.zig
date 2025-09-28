const std = @import("std");
const ts = @import("tree_sitter");
const testing = std.testing;
const ArgErr = @import("fmterr.zig").ArgCountErr;
const FileErr = @import("fmterr.zig").FileErr;

extern fn tree_sitter_python() callconv(.c) *ts.Language;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // get arg
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    // check arg count
    const file = argCount(args) catch |err| switch (err) {
        ArgErr.ExtraArgs => {
            std.debug.print("foo\n", .{});
            std.process.exit(1);
        },
        ArgErr.FileArgMissing => {
            std.debug.print("bar\n", .{});
            std.process.exit(1);
        },
    };
    // check if python file
    isPy(file) catch |err| {
        if (err == FileErr.InvalidFileType) {
            std.debug.print("not py\n", .{});
            std.process.exit(1);
        }
    };

    const python_file = std.fs.cwd().openFile(file, .{}) catch |err| switch (err) {
        std.fs.File.OpenError.FileNotFound => {
            std.debug.print("file {s} not found", .{file});
            std.process.exit(1);
        },
        std.fs.File.OpenError.AccessDenied, std.fs.File.OpenError.PermissionDenied => {
            std.debug.print("file is inaccessible", .{});
            std.process.exit(1);
        },
        else => return err,
    };
    defer python_file.close();

    var file_reader = python_file.reader(&.{});
    const buf = try file_reader.interface.allocRemaining(alloc, .unlimited);
    defer alloc.free(buf);
    std.debug.print("{s}", .{buf[0..buf.len]});

    // Create a parser for the python language
    const language = tree_sitter_python();
    defer language.destroy();

    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(language);

    // Parse some source code and get the root node
    const source = "def foo(x,y):return x+y";

    const tree = parser.parseString(source, null);
    defer tree.?.destroy();

    //const node = tree.?.rootNode();
    //printNode(node, source);
}

fn printNode(node: ts.Node, source: []const u8) void {
    const kind = node.kind();
    const start = node.startByte();
    const end = node.endByte();
    const text = source[start..end];

    std.debug.print("{s}: \"{s}\"\n", .{ kind, text });
    const n: u32 = node.childCount();
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        if (node.child(i)) |child| {
            printNode(child, source);
        }
    }
}

fn argCount(args: [][:0]u8) ![]const u8 {
    return switch (args.len) {
        0 => unreachable,
        1 => ArgErr.FileArgMissing,
        2 => args[1],
        else => ArgErr.ExtraArgs,
    };
}

fn isPy(file: []const u8) !void {
    const ext = std.fs.path.extension(file);
    if (!std.mem.eql(u8, ext, ".py")) {
        return FileErr.InvalidFileType;
    }
}
