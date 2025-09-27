const std = @import("std");
const ts = @import("tree_sitter");

extern fn tree_sitter_python() callconv(.c) *ts.Language;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    checkArgForPy(args);

    // Create a parser for the zig language
    const language = tree_sitter_python();
    defer language.destroy();

    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(language);

    // Parse some source code and get the root node
    const source = "def foo(x,y):return x+y";

    const tree = parser.parseString(source, null);
    defer tree.?.destroy();

    const node = tree.?.rootNode();
    printNode(node, source);
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

fn checkArgForPy(args: [][:0]u8) void {
    if (args.len < 2) {
        std.debug.print("No file given\nUsage: {s} <filename.py>\n", .{args[0]});
        std.process.exit(1);
    }
    if (args.len > 2) {
        std.debug.print("Too many files given\nUsage: {s} <filename.py>\n", .{args[0]});
        std.process.exit(1);
    }

    const ext = std.fs.path.extension(args[1]);
    if (!std.mem.eql(u8, ext, ".py")) {
        std.debug.print("Incorrect filetype given\nUsage: {s} <filename.py>\n", .{args[0]});
        std.process.exit(1);
    }

    std.debug.print("file {s} is ok\n", .{args[1]});
}

