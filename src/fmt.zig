const std = @import("std");
const ts = @import("tree_sitter");

pub const Fmt = struct {
    source: []const u8,
    output: std.ArrayList(u8),
    indent_str: []const u8 = "    ",
    stderr: *std.Io.Writer,

    pub fn init(allocator: std.mem.Allocator, source: []const u8, stderr: *std.Io.Writer) !Fmt {
        return .{
            .source = source,
            .output = try .initCapacity(allocator, ((3 * source.len) / 2)),
            .stderr = stderr,
        };
    }

    pub fn deinit(self: *Fmt, allocator: std.mem.Allocator) void {
        self.output.clearAndFree(allocator);
        self.output.deinit(allocator);
    }

    pub fn print(self: *Fmt, stdout: *std.Io.Writer) !void {
        try stdout.print("output:\n{s}\n", .{self.output.items});
        try stdout.flush();
    }

    pub fn format(self: *Fmt, allocator: std.mem.Allocator, tree: ?*ts.Tree) !void {
        var cursor = tree.?.walk();
        try self.formatNode(allocator, &cursor, 0);
    }

    fn formatNode(self: *Fmt, allocator: std.mem.Allocator, cursor: *ts.TreeCursor, indent: usize) !void {
        const node = cursor.node();
        const node_type = NodeType.fromTsNode(node);

        switch (node_type) {
            .module => {
                if (cursor.gotoFirstChild()) {
                    while (true) {
                        try self.formatNode(allocator, cursor, indent);
                        if (!cursor.gotoNextSibling()) break;
                    }
                    _ = cursor.gotoParent();
                }
            },
            .function_definition => {
                const name = node.namedChild(0).?;
                const params = node.namedChild(1).?;
                const body = node.namedChild(2).?;

                try self.output.print(allocator, "def {s}", .{self.source[name.startByte()..name.endByte()]});

                var params_cursor = params.walk();
                try self.formatNode(allocator, &params_cursor, 0);

                try self.output.appendSlice(allocator, ":\n");

                var body_cursor = body.walk();
                try self.formatNode(allocator, &body_cursor, indent + 1);

                try self.output.append(allocator, '\n');
            },
            .parameters => {
                try self.output.append(allocator, '(');

                const child_count = node.namedChildCount();
                var i: u32 = 0;
                while (i < child_count) : (i += 1) {
                    const child = node.namedChild(i).?;
                    var child_cursor = child.walk();
                    try self.formatNode(allocator, &child_cursor, 0);

                    if (i + 1 < child_count) {
                        try self.output.appendSlice(allocator, ", ");
                    }
                }

                try self.output.append(allocator, ')');
            },
            .call => {
                const func = node.namedChild(0).?;
                const args = node.namedChild(1).?;

                var func_cursor = func.walk();
                try self.formatNode(allocator, &func_cursor, 0);

                var args_cursor = args.walk();
                try self.formatNode(allocator, &args_cursor, 0);
            },
            .argument_list => {
                try self.output.append(allocator, '(');

                const arg_count = node.namedChildCount();
                var i: u32 = 0;
                while (i < arg_count) : (i += 1) {
                    const arg = node.namedChild(i).?;
                    var arg_cursor = arg.walk();
                    try self.formatNode(allocator, &arg_cursor, 0);

                    if (i + 1 < arg_count) try self.output.appendSlice(allocator, ", ");
                }

                try self.output.append(allocator, ')');
            },
            .return_statement => {
                const expr = node.namedChild(0) orelse {
                    try self.output.appendSlice(allocator, "return");
                    return;
                };

                try self.output.appendSlice(allocator, "return ");

                var expr_cursor = expr.walk();
                try self.formatNode(allocator, &expr_cursor, 0);
            },
            .block => {
                var body_cursor = node.walk();

                if (body_cursor.gotoFirstChild()) {
                    while (true) {
                        try self.writeIndent(allocator, indent);
                        try self.formatNode(allocator, &body_cursor, indent);
                        try self.output.append(allocator, '\n');
                        if (!body_cursor.gotoNextSibling()) break;
                    }
                }
            },
            .if_statement => {
                try self.output.appendSlice(allocator, "if ");

                const cond = node.namedChild(0).?;
                var cond_cursor = cond.walk();
                try self.formatNode(allocator, &cond_cursor, indent);

                try self.output.appendSlice(allocator, ":\n");

                const true_block = node.namedChild(1).?;
                var true_block_cursor = true_block.walk();
                try self.formatNode(allocator, &true_block_cursor, indent + 1);

                const total_children = node.namedChildCount();

                const has_alt_clause = total_children > 2;
                if (has_alt_clause) {
                    if (self.output.items[self.output.items.len - 1] == '\n') _ = self.output.pop();
                }

                var i: u32 = 2;
                while (i < total_children) : (i += 1) {
                    const clause = node.namedChild(i).?;
                    var clause_cursor = clause.walk();
                    try self.output.append(allocator, '\n');
                    try self.formatNode(allocator, &clause_cursor, indent);
                }
            },
            .elif_clause => {
                try self.output.appendSlice(allocator, "elif ");
                const cond = node.namedChild(0).?;
                var cond_cursor = cond.walk();
                try self.formatNode(allocator, &cond_cursor, indent);

                try self.output.appendSlice(allocator, ":\n");

                const body = node.namedChild(1).?;
                var body_cursor = body.walk();
                try self.formatNode(allocator, &body_cursor, indent + 1);

                const parent = node.parent();
                if (parent) |p| {
                    const total = p.namedChildCount();
                    var node_index: ?u32 = null;

                    var i: u32 = 0;
                    while (i < total) : (i += 1) {
                        if (p.namedChild(i).?.eql(node)) {
                            node_index = i;
                            break;
                        }
                    }

                    if (node_index != null and node_index.? + 1 < total) {
                        const next_sibling = p.namedChild(node_index.? + 1).?;
                        const sibling_kind = NodeType.fromTsNode(next_sibling);
                        if (sibling_kind == .elif_clause or sibling_kind == .else_clause) {
                            if (self.output.items[self.output.items.len - 1] == '\n') _ = self.output.pop();
                        }
                    }
                }
            },
            .else_clause => {
                try self.output.appendSlice(allocator, "else:\n");

                const body = node.namedChild(0).?;
                var body_cursor = body.walk();
                try self.formatNode(allocator, &body_cursor, indent + 1);
            },
            .assignment => {
                const lhs = node.namedChild(0).?;
                const rhs = node.namedChild(1).?;

                const lhs_text = self.source[lhs.startByte()..lhs.endByte()];

                try self.writeIndent(allocator, indent);
                try self.output.print(allocator, "{s} = ", .{lhs_text});

                var rhs_cursor = rhs.walk();
                try self.formatNode(allocator, &rhs_cursor, indent);
                try self.output.append(allocator, '\n');
            },
            .binary_operator, .comparison_operator => {
                const lhs = node.namedChild(0).?;
                const rhs = node.namedChild(1).?;

                var lhs_cursor = lhs.walk();
                try self.formatNode(allocator, &lhs_cursor, indent);

                const op_text = self.source[node.child(1).?.startByte()..node.child(1).?.endByte()];
                std.debug.print("{s}\n", .{op_text});
                try self.output.print(allocator, " {s} ", .{op_text});

                var rhs_cursor = rhs.walk();
                try self.formatNode(allocator, &rhs_cursor, indent);
            },
            .identifier, .integer, .float, .string => {
                const text = self.source[node.startByte()..node.endByte()];
                try self.output.appendSlice(allocator, text);
            },
            .ERROR => {
                const start = node.startByte();
                const end = node.endByte();
                const text = self.source[start..end];

                try self.output.print(allocator, "{s}\n", .{text});
                try self.stderr.print("ERROR encountered during formatting...\n", .{});
            },
            else => {
                std.debug.print("{s} node found\n", .{node.kind()});
            },
        }
    }

    fn printNode(node: ts.Node) void {
        std.debug.print("{s}", .{@tagName(NodeType.fromTsNode(node))});
    }

    fn writeIndent(self: *Fmt, allocator: std.mem.Allocator, level: usize) !void {
        var i: usize = 0;
        while (i < level) : (i += 1) {
            try self.output.appendSlice(allocator, self.indent_str);
        }
    }
};

const NodeType = enum {
    module,
    assignment,
    function_definition,
    parameters,
    call,
    argument_list,
    return_statement,
    block,

    if_statement,
    elif_clause,
    else_clause,

    binary_operator,
    comparison_operator,

    identifier,
    integer,
    float,
    string,

    ERROR,
    unknown,

    fn fromTsNode(node: ts.Node) NodeType {
        return std.meta.stringToEnum(NodeType, node.kind()) orelse .unknown;
    }
};
