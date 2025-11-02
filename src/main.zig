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

    // set up arena for each file parse
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

/// Checks if a given filename is a python file
fn isPythonFile(file: []const u8) bool {
    const ext = std.fs.path.extension(file);
    return std.mem.eql(u8, ext, ".py");
}

/// Gets program arguments
/// Preferably using an arena allocator
/// Uses iterator version
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
