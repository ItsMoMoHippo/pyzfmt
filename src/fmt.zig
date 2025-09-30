const std = @import("std");
const ts = @import("tree_sitter");

pub const Formatter = struct {
    allocator: std.mem.Allocator,
    source: []const u8,
    output: std.ArrayList(u8),
    indent_str: []const u8 = "    ",

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Formatter {
        return .{
            .allocator = allocator,
            .source = source,
            .output = .empty,
            .indent_level = 0,
        };
    }

    pub fn format(self: *Formatter, tree: ?*ts.Tree) !void {
        const root = tree.?.rootNode();
        try self.formatNode(root, 0);
    }

    fn formatNode(self: *Formatter, node: ts.Node, indent: usize) !void {
        const node_type = NodeKind.fromStr(node);
        switch (node_type) {}
    }
};

const NodeKind = enum {
    module,
    function_definition,
    class_definition,
    if_statement,
    for_statement,
    while_statement,
    with_statement,
    try_statement,
    match_statement,
    decorated_definition,

    return_statement,
    import_statement,
    import_from_statement,
    future_import_statement,
    assert_statement,
    break_statement,
    continue_statement,
    pass_statement,
    global_statement,
    nonlocal_statement,
    expression_statement,
    raise_statement,
    delete_statement,
    comment,

    fn fromStr(node: ts.Node) NodeKind {
        const kind = node.kind();
        if (std.mem.eql(u8, kind, "module")) return .module;
        if (std.mem.eql(u8, kind, "function_definition")) return .function_definition;
        if (std.mem.eql(u8, kind, "class_definition")) return .class_definition;
        if (std.mem.eql(u8, kind, "if_statement")) return .if_statement;
        if (std.mem.eql(u8, kind, "for_statement")) return .for_statement;
        if (std.mem.eql(u8, kind, "while_statement")) return .while_statement;
        if (std.mem.eql(u8, kind, "with_statement")) return .with_statement;
        if (std.mem.eql(u8, kind, "try_statement")) return .try_statement;
        if (std.mem.eql(u8, kind, "match_statement")) return .match_statement;
        if (std.mem.eql(u8, kind, "decorated_definition")) return .decorated_definition;
        if (std.mem.eql(u8, kind, "return_statement")) return .return_statement;
        if (std.mem.eql(u8, kind, "import_statement")) return .import_statement;
        if (std.mem.eql(u8, kind, "import_from_statement")) return .import_from_statement;
        if (std.mem.eql(u8, kind, "future_import_statement")) return .future_import_statement;
        if (std.mem.eql(u8, kind, "assert_statement")) return .assert_statement;
        if (std.mem.eql(u8, kind, "break_statement")) return .break_statement;
        if (std.mem.eql(u8, kind, "continue_statement")) return .continue_statement;
        if (std.mem.eql(u8, kind, "pass_statement")) return .pass_statement;
        if (std.mem.eql(u8, kind, "global_statement")) return .global_statement;
        if (std.mem.eql(u8, kind, "nonlocal_statement")) return .nonlocal_statement;
        if (std.mem.eql(u8, kind, "expression_statement")) return .expression_statement;
        if (std.mem.eql(u8, kind, "raise_statement")) return .raise_statement;
        if (std.mem.eql(u8, kind, "delete_statement")) return .delete_statement;
        if (std.mem.eql(u8, kind, "comment")) return .comment;
    }
};
