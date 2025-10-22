const std = @import("std");
const t = std.testing;
const ts = @import("tree_sitter");

const Fmt = @import("fmt_module");

extern fn tree_sitter_python() callconv(.c) *ts.Language;

test "assignment" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/assignment.py");
    // const input = std.mem.trim(u8, @embedFile("test_files/assignment.py"), &std.ascii.whitespace);

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "bad assignment" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/assignment_bad.py");
    const correct = @embedFile("test_files/assignment.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(correct, allocating.written());
}
test "if_simple" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/ifs/if_simple.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "if_elif" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/ifs/if_elif.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "if_elif_else" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/ifs/if_elif_else.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "if_elif_elif" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/ifs/if_elif_elif.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "for" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/for.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "list" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/list/list.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "list_bad" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/list/list_bad.py");
    const correct = @embedFile("test_files/list/list.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(correct, allocating.written());
}
test "while" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/while.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
test "funcs" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/funcs.py");

    const lang = tree_sitter_python();
    defer lang.destroy();
    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);
    const tree = parser.parseString(input, null);
    defer tree.?.destroy();

    var err: std.Io.Writer.Allocating = .init(alloc);
    var stderr = err.writer;
    defer err.deinit();

    var allocating: std.Io.Writer.Allocating = try .initCapacity(alloc, input.len);
    defer allocating.deinit();
    const alloc_writer = &allocating.writer;

    var form: Fmt.Fmt = Fmt.Fmt.init(input, &stderr);
    try form.format(alloc_writer, tree);
    try alloc_writer.flush();

    try t.expectEqualStrings(input, allocating.written());
}
