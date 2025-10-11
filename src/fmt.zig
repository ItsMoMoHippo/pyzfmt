const std = @import("std");
const ts = @import("tree_sitter");

pub const Fmt = struct {
    source: []const u8,
    output: std.ArrayList(u8),
    indent_str: []const u8 = "    ",
    stderr: *std.Io.Writer,

    /// init the formatter
    pub fn init(allocator: std.mem.Allocator, source: []const u8, stderr: *std.Io.Writer) !Fmt {
        return .{
            .source = source,
            .output = try .initCapacity(allocator, ((3 * source.len) / 2)),
            .stderr = stderr,
        };
    }

    /// clean up
    pub fn deinit(self: *Fmt, allocator: std.mem.Allocator) void {
        self.output.deinit(allocator);
    }

    /// print output to stdout
    pub fn print(self: *Fmt, stdout: *std.Io.Writer) !void {
        try stdout.print("output:\n{s}\n", .{self.output.items});
        try stdout.flush();
    }

    /// try to format given ast
    pub fn format(self: *Fmt, allocator: std.mem.Allocator, tree: ?*ts.Tree) !void {
        var cursor = tree.?.walk();
        try self.formatNode(allocator, &cursor, 0);
        self.removeExtraNewlines();
    }

    /// format a node
    fn formatNode(self: *Fmt, allocator: std.mem.Allocator, cursor: *ts.TreeCursor, indent: usize) !void {
        const node = cursor.node();
        const node_type = NodeType.fromTsNode(node);

        switch (node_type) {
            .module, .block => {
                var first = true;

                if (cursor.gotoFirstChild()) {
                    while (true) {
                        const child = cursor.node();

                        // if (std.mem.eql(u8, child.kind(), "comment")) {
                        //     if (!first) try self.output.append(allocator, '\n');
                        //     first = false;
                        //
                        //     try self.writeIndent(allocator, indent);
                        //
                        //     const text = self.source[child.startByte()..child.endByte()];
                        //     try self.output.appendSlice(allocator, text);
                        //
                        //     if (!cursor.gotoNextSibling()) break;
                        //     continue;
                        // }

                        if (!first) {
                            if (cursor.gotoPreviousSibling()) {
                                const prev_node = cursor.node();

                                _ = cursor.gotoNextSibling();

                                const gap = self.source[prev_node.endByte()..child.startByte()];
                                var newline_count: usize = 0;
                                for (gap) |char| {
                                    if (char == '\n') newline_count += 1;
                                }

                                try self.output.append(allocator, '\n');

                                if (newline_count > 1) try self.output.append(allocator, '\n');
                            } else {
                                try self.output.append(allocator, '\n');
                            }
                        }

                        first = false;
                        try self.writeIndent(allocator, indent);

                        var child_cursor = child.walk();
                        try self.formatNode(allocator, &child_cursor, indent);

                        if (!cursor.gotoNextSibling()) break;
                    }
                    _ = cursor.gotoParent();
                }
            },
            .class_definition => {
                const child_count = node.namedChildCount();
                const name = node.namedChild(0).?;
                var args: ?ts.Node = null;
                var body: ?ts.Node = null;
                if (child_count == 3) {
                    args = node.namedChild(1).?;
                    body = node.namedChild(2).?;
                } else {
                    body = node.namedChild(1).?;
                }

                try self.output.print(allocator, "class {s}", .{self.source[name.startByte()..name.endByte()]});

                if (args) |args_list| {
                    var args_list_cursor = args_list.walk();
                    try self.formatNode(allocator, &args_list_cursor, indent);
                }

                try self.output.appendSlice(allocator, ":\n");

                var body_cursor = body.?.walk();
                try self.formatNode(allocator, &body_cursor, indent + 1);
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
            .call => {
                const func = node.namedChild(0).?;
                const args = node.namedChild(1).?;

                var func_cursor = func.walk();
                try self.formatNode(allocator, &func_cursor, 0);

                var args_cursor = args.walk();
                try self.formatNode(allocator, &args_cursor, 0);
            },
            .assignment => {
                const lhs = node.namedChild(0).?;
                const rhs = node.namedChild(1).?;

                const lhs_text = self.source[lhs.startByte()..lhs.endByte()];

                try self.writeIndent(allocator, indent);
                try self.output.print(allocator, "{s} = ", .{lhs_text});

                var rhs_cursor = rhs.walk();
                try self.formatNode(allocator, &rhs_cursor, indent);

                // if (NodeType.fromTsNode(rhs) == .call) {
                //     if (self.output.items[self.output.items.len - 1] == '\n') _ = self.output.pop();
                // }
            },
            .parenthesized_expression => {
                try self.output.append(allocator, '(');

                const exp = node.namedChild(0).?;
                var exp_cursor = exp.walk();
                try self.formatNode(allocator, &exp_cursor, indent);
                try self.output.append(allocator, ')');
            },
            .attribute => {
                const obj = node.namedChild(0).?;
                const attr = node.namedChild(1).?;

                var obj_cursor = obj.walk();
                try self.formatNode(allocator, &obj_cursor, 0);

                try self.output.append(allocator, '.');

                var attr_cursor = attr.walk();
                try self.formatNode(allocator, &attr_cursor, 0);
            },
            .subscript => {
                const store = node.namedChild(0).?;
                var store_cursor = store.walk();
                try self.formatNode(allocator, &store_cursor, indent);

                try self.output.append(allocator, '[');

                const index = node.namedChild(1).?;
                var index_cursor = index.walk();
                try self.formatNode(allocator, &index_cursor, indent);

                try self.output.append(allocator, ']');
            },
            .tuple => {
                try self.output.append(allocator, '(');

                const named_childs = node.namedChildCount();
                var i: u32 = 0;
                while (i < named_childs) : (i += 1) {
                    const child = node.namedChild(i).?;
                    var child_cursor = child.walk();
                    try self.formatNode(allocator, &child_cursor, indent);
                    if (i + 1 < named_childs) try self.output.appendSlice(allocator, ", ");
                }
                try self.output.append(allocator, ')');
            },
            .default_parameter, .keyword_argument => {
                const param = node.namedChild(0).?;
                const value = node.namedChild(1).?;

                var param_cursor = param.walk();
                try self.formatNode(allocator, &param_cursor, 0);
                try self.output.appendSlice(allocator, " = ");
                var value_cursor = value.walk();
                try self.formatNode(allocator, &value_cursor, 0);
            },
            .pass_statement => {
                try self.output.appendSlice(allocator, "pass");
            },
            .conditional_expression => {
                const first_val = node.namedChild(0).?;
                const cond = node.namedChild(1).?;
                const second_val = node.namedChild(2).?;

                var first_val_cursor = first_val.walk();
                try self.formatNode(allocator, &first_val_cursor, indent);

                try self.output.appendSlice(allocator, " if ");

                var cond_cursor = cond.walk();
                try self.formatNode(allocator, &cond_cursor, indent);

                try self.output.appendSlice(allocator, " else ");

                var second_val_cursor = second_val.walk();
                try self.formatNode(allocator, &second_val_cursor, indent);
            },
            .augmented_assignment => {
                const val = node.namedChild(0).?;
                const delta = node.namedChild(1).?;

                var val_cursor = val.walk();
                try self.formatNode(allocator, &val_cursor, indent);

                const operand_slice = self.source[val.endByte()..delta.endByte()];
                const operand_trimmed = std.mem.trim(u8, operand_slice, " \t\r\n");
                try self.output.append(allocator, ' ');
                try self.output.appendSlice(allocator, operand_trimmed);

                var delta_cursor = delta.walk();
                try self.formatNode(allocator, &delta_cursor, indent);
            },

            .for_statement => {
                const id = node.namedChild(0).?;
                try self.output.print(allocator, "for {s} in ", .{self.source[id.startByte()..id.endByte()]});

                const call = node.namedChild(1).?;
                var call_cursor = call.walk();
                try self.formatNode(allocator, &call_cursor, 0);
                try self.output.appendSlice(allocator, ":\n");

                const body = node.namedChild(2).?;
                var body_cursor = body.walk();
                try self.formatNode(allocator, &body_cursor, indent + 1);
                try self.output.append(allocator, '\n');

                // why does python loop have a possible else clause
                const possible_else = node.namedChild(3);
                if (possible_else) |else_clause| {
                    var else_cursor = else_clause.walk();
                    try self.formatNode(allocator, &else_cursor, indent);
                }
            },
            .while_statement => {
                try self.output.appendSlice(allocator, "while ");

                const cond = node.namedChild(0).?;
                var cond_cursor = cond.walk();
                try self.formatNode(allocator, &cond_cursor, 0);

                try self.output.appendSlice(allocator, ":\n");

                const body = node.namedChild(1).?;
                var body_cursor = body.walk();
                try self.formatNode(allocator, &body_cursor, indent + 1);
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

            .binary_operator, .comparison_operator, .boolean_operator => {
                const lhs = node.namedChild(0).?;
                const rhs = node.namedChild(1).?;

                var lhs_cursor = lhs.walk();
                try self.formatNode(allocator, &lhs_cursor, indent);

                const op_text = self.source[node.child(1).?.startByte()..node.child(1).?.endByte()];
                try self.output.print(allocator, " {s} ", .{op_text});

                var rhs_cursor = rhs.walk();
                try self.formatNode(allocator, &rhs_cursor, indent);
            },
            .unary_operator => {
                const operand = node.namedChild(0).?;

                const op_text = self.source[node.startByte()..operand.startByte()];
                try self.output.appendSlice(allocator, op_text);

                var operand_cursor = operand.walk();
                try self.formatNode(allocator, &operand_cursor, indent);
            },
            .not_operator => {
                const operand = node.namedChild(0).?;
                const op_text = self.source[node.startByte()..operand.startByte()];

                try self.output.appendSlice(allocator, op_text);

                var operand_cursor = operand.walk();
                try self.formatNode(allocator, &operand_cursor, indent);
            },

            .true, .false, .none => {
                try self.output.appendSlice(allocator, self.source[node.startByte()..node.endByte()]);
            },

            .identifier, .integer, .float, .string => {
                const text = self.source[node.startByte()..node.endByte()];
                try self.output.appendSlice(allocator, text);
            },
            .list => {
                try self.output.append(allocator, '[');

                const child_count = node.namedChildCount();
                var i: u32 = 0;
                while (i < child_count) : (i += 1) {
                    const elem = node.namedChild(i).?;
                    var elem_cursor = elem.walk();
                    try self.formatNode(allocator, &elem_cursor, 0);

                    if (i + 1 < child_count) {
                        try self.output.appendSlice(allocator, ", ");
                    }
                }

                try self.output.append(allocator, ']');
            },

            .comment => {
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

    /// Prints a node type
    fn printNode(node: ts.Node) void {
        std.debug.print("node is :{s}\n", .{@tagName(NodeType.fromTsNode(node))});
    }

    /// print number of children and their types
    fn printNameChildren(self: *Fmt, node: ts.Node) void {
        printNode(node);
        const children = node.namedChildCount();
        std.debug.print("{d} named child nodes\n", .{children});
        var i: u32 = 0;
        while (i < children) : (i += 1) {
            std.debug.print("child {d} = {s}\n", .{ i, node.namedChild(i).?.kind() });
            std.debug.print("{s}\n", .{self.source[node.namedChild(i).?.startByte()..node.namedChild(i).?.endByte()]});
        }
    }

    /// Writes an indent to output ArrayList
    /// the indent is given by self.indent_str
    fn writeIndent(self: *Fmt, allocator: std.mem.Allocator, level: usize) !void {
        var i: usize = 0;
        while (i < level) : (i += 1) {
            try self.output.appendSlice(allocator, self.indent_str);
        }
    }

    fn removeExtraNewlines(self: *Fmt) void {
        if (self.output.items.len < 2) return;
        var i: usize = 0;
        while (i < self.output.items.len - 2) {
            if (self.output.items[i] == '\n' and
                self.output.items[i + 1] == '\n' and
                self.output.items[i + 2] == '\n')
            {
                _ = self.output.orderedRemove(i + 2);
            } else {
                i += 1;
            }
        }
        while (self.output.items[self.output.items.len - 1] == '\n') {
            _ = self.output.pop();
        }
    }
};

const NodeType = enum {
    module,
    block,
    class_definition,
    function_definition,
    parameters,
    argument_list,
    return_statement,
    call,
    assignment,
    parenthesized_expression,
    attribute,
    subscript,
    tuple,
    default_parameter,
    pass_statement,
    conditional_expression,
    augmented_assignment,
    keyword_argument,

    for_statement,
    while_statement,

    if_statement,
    elif_clause,
    else_clause,

    binary_operator,
    comparison_operator,
    boolean_operator,
    unary_operator,
    not_operator,

    true,
    false,
    none,

    identifier,
    integer,
    float,
    string,
    list,

    comment,

    ERROR,
    unknown,

    /// translate TS node kinds to enums
    fn fromTsNode(node: ts.Node) NodeType {
        return std.meta.stringToEnum(NodeType, node.kind()) orelse .unknown;
    }
};
