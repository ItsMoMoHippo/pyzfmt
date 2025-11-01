const std = @import("std");
const ts = @import("tree_sitter");

const FooErr = @import("fmterr.zig");
const Formatter = @import("fmt.zig");

extern fn tree_sitter_python() callconv(.c) *ts.Language;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    var newArgs = try grabArgs(arena.allocator());

    // get arg
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    //TODO: re-do add directory support and multiple inputted files
    //just silently fail if non-python file found

    // check arg count
    const file = argCount(args) catch |err| switch (err) {
        FooErr.ArgCountErr.ExtraArgs => {
            std.debug.print(
                \\User has inputted too many arguments,
                \\Please input 1 python file only
            , .{});
            std.process.exit(1);
        },
        FooErr.ArgCountErr.FileArgMissing => {
            std.debug.print(
                \\User has not inputted a file,
                \\Please input a pyhton file
            , .{});
            std.process.exit(1);
        },
    };
    // check if python file
    isPy(file) catch |err| {
        if (err == FooErr.FileErr.InvalidFileType) {
            std.debug.print(
                \\{s} is not a python file,
                \\Please only input a python file
            , .{file});
            std.process.exit(1);
        }
    };

    const python_file = std.fs.cwd().openFile(file, .{}) catch |err| switch (err) {
        std.fs.File.OpenError.FileNotFound => {
            std.debug.print("file {s} not found\n", .{file});
            std.process.exit(1);
        },
        std.fs.File.OpenError.AccessDenied, std.fs.File.OpenError.PermissionDenied => {
            std.debug.print("file is inaccessible\n", .{});
            std.process.exit(1);
        },
        else => return err,
    };
    defer python_file.close();

    //read till end of file
    var file_reader = python_file.reader(&.{});
    const buf = try file_reader.interface.allocRemaining(alloc, .unlimited);
    defer alloc.free(buf);

    // Create a parser for the python language
    const language = tree_sitter_python();
    defer language.destroy();

    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(language);

    // let ts parse soure code
    const tree = parser.parseString(buf[0..buf.len], null);
    defer tree.?.destroy();

    const root_node = tree.?.rootNode();
    printNode(root_node, buf[0..buf.len]);

    std.debug.print("\n\n", .{});

    var stderr_writer = std.fs.File.stderr().writer(&.{});
    const stderr = &stderr_writer.interface;

    // writer for wrting into file ?
    // var file_writer :std.Io.Writer = std.fs.File.Writer.init(python_file, &.{});

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, buf.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var py_formatter = Formatter.Fmt.init(buf[0..buf.len], stderr);
    try py_formatter.format(alloc_writer, tree);

    try alloc_writer.flush();

    std.debug.print("output:\n{s}\noutput end...\n", .{allocating.written()});
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
        1 => FooErr.ArgCountErr.FileArgMissing,
        2 => args[1],
        else => FooErr.ArgCountErr.ExtraArgs,
    };
}

fn isPy(file: []const u8) !void {
    const ext = std.fs.path.extension(file);
    if (!std.mem.eql(u8, ext, ".py")) {
        return FooErr.FileErr.InvalidFileType;
    }
}

fn isPythonFile(file: []const u8) bool {
    const ext = std.fs.path.extension(file);
    return std.mem.eql(u8, ext, ".py");
}

fn grabArgs(arena: std.mem.Allocator) !std.ArrayList([]const u8) {
    var args = try std.process.argsWithAllocator(arena);
    _ = args.next();

    var files: std.ArrayList([]const u8) = try .initCapacity(arena, args.inner.count);
    while (args.next()) |arg| {
        const stat = std.fs.cwd().statFile(arg) catch continue;
        if (stat.kind == .file and isPythonFile(arg)) {
            try files.append(arena, arg);
            continue;
        }

        var dir = std.fs.cwd().openDir(arg, .{ .iterate = true }) catch continue;
        defer dir.close();
        var walker = dir.walk(arena);
        while (try walker.next()) |entry| {
            if (entry.kind == .file and isPythonFile(entry.basename)) {
                const file_path = try arena.dupe(u8, entry.path);
                try files.append(arena, try std.fs.path.join(arena, &.{ arg, file_path }));
            }
        }
    }
    return files;
}
