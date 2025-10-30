const std = @import("std");
const t = std.testing;
const ts = @import("tree_sitter");

const Fmt = @import("fmt_module");

extern fn tree_sitter_python() callconv(.c) *ts.Language;

test "assignment" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/assign/assignment.py");

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
    const input = @embedFile("test_files/assign/assignment_bad.py");
    const correct = @embedFile("test_files/assign/assignment.py");

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
test "augmented" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/assign/augm.py");

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
test "pattern_assign" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/assign/pattern.py");

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

test "comprehensions" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/brackets/comprehensions.py");

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
test "dict" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/brackets/dict.py");

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
test "parens" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/brackets/parens.py");

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
test "set" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/brackets/set.py");

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
test "tuple" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/brackets/tuples.py");

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

test "conds" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/conds/cond1.py");

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
test "cond2" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/conds/cond2.py");

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
test "if_simple" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/conds/if.py");

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
    const input = @embedFile("test_files/conds/if_elif.py");

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
    const input = @embedFile("test_files/conds/if_elif_else.py");

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
    const input = @embedFile("test_files/conds/if_elif_elif.py");

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
test "if_else" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/conds/if_else.py");

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

test "concant_str" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/str/concat_str.py");

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
test "interp_str" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/str/interp_str.py");

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

test "try_1_exc" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/try/try_exc.py");

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
test "try_2_exc" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/try/try_exc_exc.py");

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
test "try_2_exc_final" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/try/try_exc_exc_final.py");

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
test "try_final" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/try/try_final.py");

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

test "indexing" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/arrays.py");

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
test "attr" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/attr.py");

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
test "byte" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/byte.py");

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
test "classes" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/classes.py");

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
test "decorator" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/decor.py");

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
test "def_params" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/def_param.py");

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
test "ellipsis" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/ellipsis.py");

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
test "imports" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/imports.py");

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
test "lambda" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/lambda.py");

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
test "ops" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/operators.py");

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
test "types" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/types.py");

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
test "with" {
    const alloc = t.allocator;
    const input = @embedFile("test_files/with.py");

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
