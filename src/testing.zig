const std = @import("std");
const t = std.testing;
const ts = @import("tree_sitter");

const Fmt = @import("fmt.zig").Fmt;

extern fn tree_sitter_python() callconv(.c) *ts.Language;

test "assignment" {
    const alloc = t.allocator;
    const input = std.mem.trim(u8, @embedFile("tests/assignment.py"), &std.ascii.whitespace);

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    defer err.deinit();
    var formatter: Fmt = try Fmt.init(alloc, input, &err.writer);
    defer formatter.deinit(alloc);

    try formatter.format(alloc, tree);
    try t.expectEqualStrings(input, formatter.output.items);
}
