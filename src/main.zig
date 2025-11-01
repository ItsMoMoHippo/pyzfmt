const std = @import("std");
const ts = @import("tree_sitter");

const FmtErr = @import("fmterr.zig");
const Formatter = @import("fmt.zig");

extern fn tree_sitter_python() callconv(.c) *ts.Language;

pub fn main() !void {
    // allocator
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // args
    var argArena = std.heap.ArenaAllocator.init(alloc);
    defer argArena.deinit();
    const args = try grabArgs(argArena.allocator());

    // Create a parser for the python language
    const language = tree_sitter_python();
    defer language.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(language);

    //TODO: might remove the need
    var stderr_writer = std.fs.File.stderr().writer(&.{});
    const stderr = &stderr_writer.interface;

    // TODO: remove -----------------------------------------------------------

    // // get arg
    // const args = try std.process.argsAlloc(alloc);
    // defer std.process.argsFree(alloc, args);
    // // check arg count
    // const file = argCount(args) catch |err| switch (err) {
    //     FooErr.ArgCountErr.ExtraArgs => {
    //         std.debug.print(
    //             \\User has inputted too many arguments,
    //             \\Please input 1 python file only
    //         , .{});
    //         std.process.exit(1);
    //     },
    //     FooErr.ArgCountErr.FileArgMissing => {
    //         std.debug.print(
    //             \\User has not inputted a file,
    //             \\Please input a pyhton file
    //         , .{});
    //         std.process.exit(1);
    //     },
    // };
    // // check if python file
    // isPy(file) catch |err| {
    //     if (err == FooErr.FileErr.InvalidFileType) {
    //         std.debug.print(
    //             \\{s} is not a python file,
    //             \\Please only input a python file
    //         , .{file});
    //         std.process.exit(1);
    //     }
    // };

    // ------------------------------------------------------------------

    var fmtSetupArena = std.heap.ArenaAllocator.init(alloc);
    const fmtArena = fmtSetupArena.allocator();
    defer fmtSetupArena.deinit();

    for (args.items) |file| {
        // make sure to reset (not release) memory
        // releasing would incur performance penalty i guess
        defer _ = fmtSetupArena.reset(.retain_capacity);

        // ignore inaccessible files
        const file_handle = std.fs.cwd().openFile(file, .{}) catch continue;
        defer file_handle.close();

        // read file contents
        var file_reader = file_handle.reader(&.{});
        const file_buf = try file_reader.interface.allocRemaining(fmtArena, .unlimited);

        // make tree
        const ast_tree = parser.parseString(file_buf[0..file_buf.len], null);
        defer ast_tree.?.destroy();

        // writer
        var arena_allocating: std.Io.Writer.Allocating = try .initCapacity(fmtArena, file_buf.len);
        defer arena_allocating.deinit();
        const arena_alloc_writer = &arena_allocating.writer;

        //TODO: switch to file writer for release
        //
        // var file_writer = file_handle.writer(&.{});

        var pyFmt = Formatter.Fmt.init(file_buf[0..file_buf.len], stderr);
        try pyFmt.format(arena_alloc_writer, ast_tree);
        // try pyFmt.format(file_writer, ast_tree);

        try arena_alloc_writer.flush();
        // try file_writer.flush();

        std.debug.print("output:\n{s}\noutput end...\n", .{arena_allocating.written()});
    }

    //TODO: remove----------------------------------------------------------------

    // const python_file = std.fs.cwd().openFile(file, .{}) catch |err| switch (err) {
    //     std.fs.File.OpenError.FileNotFound => {
    //         std.debug.print("file {s} not found\n", .{file});
    //         std.process.exit(1);
    //     },
    //     std.fs.File.OpenError.AccessDenied, std.fs.File.OpenError.PermissionDenied => {
    //         std.debug.print("file is inaccessible\n", .{});
    //         std.process.exit(1);
    //     },
    //     else => return err,
    // };
    // defer python_file.close();
    //
    // //read till end of file
    // var file_reader = python_file.reader(&.{});
    // const buf = try file_reader.interface.allocRemaining(alloc, .unlimited);
    // defer alloc.free(buf);
    //
    //
    // // let ts parse soure code
    // const tree = parser.parseString(buf[0..buf.len], null);
    // defer tree.?.destroy();
    //
    // const root_node = tree.?.rootNode();
    // printNode(root_node, buf[0..buf.len]);
    //
    // std.debug.print("\n\n", .{});
    //
    // // writer for wrting into file ?
    // // var file_writer :std.Io.Writer = std.fs.File.Writer.init(python_file, &.{});
    //
    // var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, buf.len);
    // defer allocating.deinit();
    // const alloc_writer = &allocating.writer;
    //
    // var py_formatter = Formatter.Fmt.init(buf[0..buf.len], stderr);
    // try py_formatter.format(alloc_writer, tree);
    //
    // try alloc_writer.flush();

    //---------------------------------------------------------------------------
}

//TODO: eventually remove debug ---------------------------------------------
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
// --------------------------------------------------------------------------

//TODO: remove useless functions now ----------------------------------------
fn argCount(args: [][:0]u8) ![]const u8 {
    return switch (args.len) {
        0 => unreachable,
        1 => FmtErr.ArgCountErr.FileArgMissing,
        2 => args[1],
        else => FmtErr.ArgCountErr.ExtraArgs,
    };
}

fn isPy(file: []const u8) !void {
    const ext = std.fs.path.extension(file);
    if (!std.mem.eql(u8, ext, ".py")) {
        return FmtErr.FileErr.InvalidFileType;
    }
}
//--------------------------------------------------------------------------

//the new useful stuff------------------------------------------------------
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

        var walker = try dir.walk(arena);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            if (entry.kind == .file and isPythonFile(entry.basename)) {
                const file_path = try arena.dupe(u8, entry.path);
                try files.append(arena, try std.fs.path.join(arena, &.{ arg, file_path }));
            }
        }
    }
    return files;
}
//---------------------------------------------------------------------------
