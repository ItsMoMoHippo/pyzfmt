const std = @import("std");
const ts = @import("tree_sitter");

pub const Fmt = struct {
    source: []const u8,
    stderr: *std.Io.Writer,

    pub fn init(source: []const u8, stderr: *std.Io.Writer) Fmt {
        return .{
            .source = source,
            .stderr = stderr,
        };
    }

    pub fn format(self: *Fmt, writer: *std.Io.Writer, tree: ?*ts.Tree) error{WriteFailed}!void {
        var cursor = tree.?.walk();
        try self.formatNode(writer, &cursor, 0);
    }

    fn formatNode(self: *Fmt, writer: *std.Io.Writer, cursor: *ts.TreeCursor, indent: usize) error{WriteFailed}!void {
        const node = cursor.node();
        const node_type = NodeType.fromTsNode(node);

        switch (node_type) {
            .module, .block => {
                const is_module = node_type == .module;
                var first = true;

                if (cursor.gotoFirstChild()) {
                    while (true) {
                        const child = cursor.node();

                        if (!first) {
                            if (cursor.gotoPreviousSibling()) {
                                const prev_node = cursor.node();
                                _ = cursor.gotoNextSibling();

                                const gap = self.source[prev_node.endByte()..child.startByte()];
                                var newline_count: usize = 0;
                                for (gap) |char| {
                                    if (char == '\n') newline_count += 1;
                                }

                                try writer.writeAll("\n");
                                if (newline_count > 1) try writer.writeAll("\n");
                            } else {
                                try writer.writeAll("\n");
                            }
                        }

                        first = false;
                        try writeIndent(writer, indent);

                        var child_cursor = child.walk();
                        try self.formatNode(writer, &child_cursor, indent);

                        if (!cursor.gotoNextSibling()) break;
                    }

                    if (is_module) try writer.writeAll("\n");
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

                try writer.writeAll("class ");
                var name_cursor = name.walk();
                try self.formatNode(writer, &name_cursor, indent);

                if (args) |args_list| {
                    var args_cursor = args_list.walk();
                    try self.formatNode(writer, &args_cursor, indent);
                }
                try writer.writeAll(":\n");

                var body_cursor = body.?.walk();
                try self.formatNode(writer, &body_cursor, indent + 1);
            },
            .function_definition => {
                const children = node.namedChildCount();

                const name = node.namedChild(0).?;
                const params = node.namedChild(1).?;

                const has_ret = children == 4;
                const ret_type: ?ts.Node = if (has_ret) node.namedChild(2) else null;

                const body = node.namedChild(if (has_ret) 3 else 2).?;

                try writer.writeAll("def ");

                var name_cursor = name.walk();
                try self.formatNode(writer, &name_cursor, indent);

                var params_cursor = params.walk();
                try self.formatNode(writer, &params_cursor, indent);

                if (has_ret) {
                    try writer.writeAll(" -> ");
                    var ret_cursor = ret_type.?.walk();
                    try self.formatNode(writer, &ret_cursor, indent);
                }

                try writer.writeAll(":\n");

                var body_cursor = body.walk();
                try self.formatNode(writer, &body_cursor, indent + 1);
            },
            .decorated_definition => {
                const dec = node.namedChild(0).?;
                var dec_cursor = dec.walk();
                try self.formatNode(writer, &dec_cursor, indent);

                const func = node.namedChild(1).?;
                var func_cursor = func.walk();
                try self.formatNode(writer, &func_cursor, indent);
            },
            .parameters, .argument_list, .tuple, .tuple_pattern => {
                try writer.writeAll("(");
                try self.splatChildren(writer, node);
                try writer.writeAll(")");
            },
            .return_statement => {
                const expr = node.namedChild(0) orelse {
                    try writer.writeAll("return");
                    return;
                };

                try writer.writeAll("return ");
                var expr_cursor = expr.walk();
                try self.formatNode(writer, &expr_cursor, 0);
            },
            .call => {
                const func = node.namedChild(0).?;
                const args = node.namedChild(1).?;

                var func_cursor = func.walk();
                try self.formatNode(writer, &func_cursor, 0);

                var args_cursor = args.walk();
                try self.formatNode(writer, &args_cursor, 0);
            },
            .assignment => {
                const children = node.namedChildCount();
                const has_annotation = children == 3;

                const lhs = node.namedChild(0).?;
                const middle = if (has_annotation) node.namedChild(1).? else null;
                const rhs = node.namedChild(if (has_annotation) 2 else 1).?;

                var lhs_cursor = lhs.walk();
                try self.formatNode(writer, &lhs_cursor, indent);

                if (has_annotation) {
                    try writer.writeAll(": ");
                    var middle_cursor = middle.?.walk();
                    try self.formatNode(writer, &middle_cursor, indent);
                }

                try writer.writeAll(" = ");

                var rhs_cursor = rhs.walk();
                try self.formatNode(writer, &rhs_cursor, indent);
            },
            .parenthesized_expression => {
                try writer.writeAll("(");

                const exp = node.namedChild(0).?;
                var exp_cursor = exp.walk();
                try self.formatNode(writer, &exp_cursor, indent);

                try writer.writeAll(")");
            },
            .attribute => {
                const obj = node.namedChild(0).?;
                const attr = node.namedChild(1).?;

                var obj_cursor = obj.walk();
                try self.formatNode(writer, &obj_cursor, 0);

                try writer.writeAll(".");

                var attr_cursor = attr.walk();
                try self.formatNode(writer, &attr_cursor, 0);
            },
            .subscript => {
                const store = node.namedChild(0).?;
                var store_cursor = store.walk();
                try self.formatNode(writer, &store_cursor, indent);

                try writer.writeAll("[");
                try self.splatChildrenLua(writer, node);
                try writer.writeAll("]");
            },
            .default_parameter, .keyword_argument => {
                const param = node.namedChild(0).?;
                const value = node.namedChild(1).?;

                var param_cursor = param.walk();
                try self.formatNode(writer, &param_cursor, 0);
                try writer.writeAll(" = ");
                var value_cursor = value.walk();
                try self.formatNode(writer, &value_cursor, 0);
            },
            .pass_statement => {
                try writer.writeAll("pass");
            },
            .conditional_expression => {
                const first_val = node.namedChild(0).?;
                const cond = node.namedChild(1).?;
                const second_val = node.namedChild(2).?;

                var first_val_cursor = first_val.walk();
                try self.formatNode(writer, &first_val_cursor, indent);

                try writer.writeAll(" if ");

                var cond_cursor = cond.walk();
                try self.formatNode(writer, &cond_cursor, indent);

                try writer.writeAll(" else ");

                var second_val_cursor = second_val.walk();
                try self.formatNode(writer, &second_val_cursor, indent);
            },
            .augmented_assignment => {
                const val = node.namedChild(0).?;
                const delta = node.namedChild(1).?;

                var val_cursor = val.walk();
                try self.formatNode(writer, &val_cursor, indent);

                const operand_slice = self.source[val.endByte()..delta.startByte()];
                const operand_trimmed = std.mem.trim(u8, operand_slice, " \t\r\n");
                try writer.writeAll(" ");
                try writer.writeAll(operand_trimmed);
                try writer.writeAll(" ");

                var delta_cursor = delta.walk();
                try self.formatNode(writer, &delta_cursor, indent);
            },
            .decorator => {
                const text = node.namedChild(0).?;
                var text_cursor = text.walk();
                try writer.writeAll("@");
                try self.formatNode(writer, &text_cursor, indent);
                try writer.writeAll("\n");
            },

            .with_statement => {
                try writer.writeAll("with ");
                const clause = node.namedChild(0).?;
                var clause_cursor = clause.walk();
                try self.formatNode(writer, &clause_cursor, indent);

                const block = node.namedChild(1).?;
                var block_cursor = block.walk();
                try self.formatNode(writer, &block_cursor, indent + 1);
            },
            .with_clause => {
                try self.splatChildren(writer, node);
                try writer.writeAll(":\n");
            },
            .as_pattern => {
                const primary = node.namedChild(0).?;
                var primary_cursor = primary.walk();
                try self.formatNode(writer, &primary_cursor, indent);

                try writer.writeAll(" as ");

                const secondary = node.namedChild(1).?;
                var secondary_cursor = secondary.walk();
                try self.formatNode(writer, &secondary_cursor, indent);
            },

            .try_statement => {
                try writer.writeAll("try:\n");
                const try_block = node.namedChild(0).?;
                var block_cursor = try_block.walk();
                try self.formatNode(writer, &block_cursor, indent + 1);
                try writer.writeAll("\n");

                const children = node.namedChildCount();
                var i: u32 = 1;
                while (i < children) : (i += 1) {
                    const child = node.namedChild(i).?;
                    var child_cursor = child.walk();
                    try self.formatNode(writer, &child_cursor, indent);
                }
            },
            .except_clause => {
                try writer.writeAll("except ");

                const exception = node.namedChild(0).?;
                var exception_cursor = exception.walk();
                try self.formatNode(writer, &exception_cursor, indent);

                try writer.writeAll(":\n");

                const block = node.namedChild(1).?;
                var block_cursor = block.walk();
                try self.formatNode(writer, &block_cursor, indent + 1);

                const parent = node.parent();
                if (parent) |p| {
                    const p_children = p.namedChildCount();
                    var node_index: ?u32 = null;

                    var i: u32 = 0;
                    while (i < p_children) : (i += 1) {
                        if (p.namedChild(i).?.eql(node)) {
                            node_index = i;
                            break;
                        }
                    }

                    if (node_index != null and node_index.? + 1 < p_children) {
                        try writer.writeAll("\n");
                    }
                }
            },
            .finally_clause => {
                try writer.writeAll("finally:\n");
                const block = node.namedChild(0).?;
                var block_cursor = block.walk();
                try self.formatNode(writer, &block_cursor, indent + 1);
            },

            .lambda => {
                self.nodeDebugInfo(node);
                try writer.writeAll("lambda ");

                const param = node.namedChild(0).?;
                var param_cursor = param.walk();
                try self.formatNode(writer, &param_cursor, indent);

                try writer.writeAll(": ");

                const op = node.namedChild(1).?;
                var op_cursor = op.walk();
                try self.formatNode(writer, &op_cursor, indent);
            },

            .for_statement => {
                const id = node.namedChild(0).?;
                try writer.writeAll("for ");

                var id_cursor = id.walk();
                try self.formatNode(writer, &id_cursor, 0);

                try writer.writeAll(" in ");

                const call = node.namedChild(1).?;
                var call_cursor = call.walk();
                try self.formatNode(writer, &call_cursor, 0);
                try writer.writeAll(":\n");

                const body = node.namedChild(2).?;
                var body_cursor = body.walk();
                try self.formatNode(writer, &body_cursor, indent + 1);

                // why does python loop have a possible else clause
                const possible_else = node.namedChild(3);
                if (possible_else) |else_clause| {
                    var else_cursor = else_clause.walk();
                    try self.formatNode(writer, &else_cursor, indent);
                }
            },
            .while_statement => {
                try writer.writeAll("while ");

                const cond = node.namedChild(0).?;
                var cond_cursor = cond.walk();
                try self.formatNode(writer, &cond_cursor, 0);
                try writer.writeAll(":\n");

                const body = node.namedChild(1).?;
                var body_cursor = body.walk();
                try self.formatNode(writer, &body_cursor, indent + 1);
            },

            .if_statement => {
                try writer.writeAll("if ");

                const cond = node.namedChild(0).?;
                var cond_cursor = cond.walk();
                try self.formatNode(writer, &cond_cursor, indent);

                try writer.writeAll(":\n");

                const true_block = node.namedChild(1).?;
                var true_cursor = true_block.walk();
                try self.formatNode(writer, &true_cursor, indent + 1);

                const children = node.namedChildCount();

                if (children > 2) try writer.writeAll("\n");

                var i: u32 = 2;
                while (i < children) : (i += 1) {
                    const clause = node.namedChild(i).?;
                    var clause_cursor = clause.walk();
                    try self.formatNode(writer, &clause_cursor, indent);
                }
            },
            .elif_clause => {
                try writer.writeAll("elif ");

                const cond = node.namedChild(0).?;
                var cond_cursor = cond.walk();
                try self.formatNode(writer, &cond_cursor, indent);

                try writer.writeAll(":\n");

                const body = node.namedChild(1).?;
                var body_cursor = body.walk();
                try self.formatNode(writer, &body_cursor, indent + 1);

                const parent = node.parent();
                if (parent) |p| {
                    const p_children = p.namedChildCount();
                    var node_index: ?u32 = null;

                    var i: u32 = 0;
                    while (i < p_children) : (i += 1) {
                        if (p.namedChild(i).?.eql(node)) {
                            node_index = i;
                            break;
                        }
                    }

                    if (node_index != null and node_index.? + 1 < p_children) {
                        try writer.writeAll("\n");
                    }
                }
            },
            .else_clause => {
                try writer.writeAll("else:\n");

                const body = node.namedChild(0).?;
                var body_cursor = body.walk();
                try self.formatNode(writer, &body_cursor, indent + 1);
            },

            .binary_operator, .comparison_operator, .boolean_operator => {
                const lhs = node.namedChild(0).?;
                const rhs = node.namedChild(1).?;

                var lhs_cursor = lhs.walk();
                try self.formatNode(writer, &lhs_cursor, indent);

                const op_text = self.source[node.child(1).?.startByte()..node.child(1).?.endByte()];
                try writer.writeAll(" ");
                try writer.writeAll(op_text);
                try writer.writeAll(" ");

                var rhs_cursor = rhs.walk();
                try self.formatNode(writer, &rhs_cursor, indent);
            },
            .unary_operator, .not_operator => {
                const operand = node.namedChild(0).?;

                const op_text = self.source[node.startByte()..operand.startByte()];
                try writer.writeAll(op_text);

                var rhs_cursor = operand.walk();
                try self.formatNode(writer, &rhs_cursor, indent);
            },

            .import_statement => {
                const import_stat = node.namedChild(0).?;
                var import_cursor = import_stat.walk();
                try writer.writeAll("import ");
                try self.formatNode(writer, &import_cursor, indent);
            },
            .aliased_import => {
                const package = node.namedChild(0).?;
                const alias = node.namedChild(1).?;

                var package_cursor = package.walk();
                try self.formatNode(writer, &package_cursor, indent);

                try writer.writeAll(" as ");

                var alias_cursor = alias.walk();
                try self.formatNode(writer, &alias_cursor, indent);
            },
            .import_from_statement => {
                try writer.writeAll("from ");

                const package = node.namedChild(0).?;
                var package_cursor = package.walk();
                try self.formatNode(writer, &package_cursor, indent);

                try writer.writeAll(" import ");

                try self.splatChildrenLua(writer, node);
            },
            .wildcard_import => {
                try writer.writeAll("*");
            },

            .identifier, .integer, .float, .comment, .true, .false, .none, .string => {
                const text = self.source[node.startByte()..node.endByte()];
                try writer.writeAll(text);
            },
            .with_item, .dotted_name, .as_pattern_target => {
                const child = node.namedChild(0).?;
                var child_cursor = child.walk();
                try self.formatNode(writer, &child_cursor, indent);
            },
            .list, .list_pattern => {
                try writer.writeAll("[");
                try self.splatChildren(writer, node);
                try writer.writeAll("]");
            },
            .dictionary, .set => {
                try writer.writeAll("{");
                try self.splatChildren(writer, node);
                try writer.writeAll("}");
            },
            .pair => {
                const key = node.namedChild(0).?;
                const value = node.namedChild(1).?;

                var key_cursor = key.walk();
                try self.formatNode(writer, &key_cursor, 0);

                try writer.writeAll(" : ");

                var value_cursor = value.walk();
                try self.formatNode(writer, &value_cursor, 0);
            },
            .pattern_list, .lambda_parameters => {
                try self.splatChildren(writer, node);
            },
            .expression_list => {
                try self.splatChildren(writer, node);
            },
            .list_splat_pattern => {
                try writer.writeAll("*");
                const child = node.namedChild(0).?;
                var child_cursor = child.walk();
                try self.formatNode(writer, &child_cursor, indent);
            },
            .ellipsis => {
                try writer.writeAll("...");
            },

            .type => {
                const child = node.namedChild(0).?;
                var child_cursor = child.walk();
                try self.formatNode(writer, &child_cursor, indent);
            },
            .generic_type => {
                const ident = node.namedChild(0).?;
                var ident_cursor = ident.walk();
                try self.formatNode(writer, &ident_cursor, indent);

                try writer.writeAll("[");

                const given_type = node.namedChild(1).?;
                var type_cursor = given_type.walk();
                try self.formatNode(writer, &type_cursor, indent);

                try writer.writeAll("]");
            },
            .type_parameter => {
                try self.splatChildren(writer, node);
            },
            .typed_parameter => {
                const ident = node.namedChild(0).?;
                var indent_cursor = ident.walk();
                try self.formatNode(writer, &indent_cursor, indent);

                try writer.writeAll(": ");

                const given_type = node.namedChild(1).?;
                var type_cursor = given_type.walk();
                try self.formatNode(writer, &type_cursor, indent);
            },

            .list_comprehension => {
                try writer.writeAll("[");
                var i: u32 = 0;
                while (i < node.namedChildCount()) : (i += 1) {
                    const child = node.namedChild(i).?;
                    var child_cursor = child.walk();
                    try self.formatNode(writer, &child_cursor, 0);
                    if (i + 1 < node.namedChildCount()) try writer.writeAll(" ");
                }
                try writer.writeAll("]");
            },
            .dictionary_comprehension, .set_comprehension => {
                try writer.writeAll("{");
                var i: u32 = 0;
                while (i < node.namedChildCount()) : (i += 1) {
                    const child = node.namedChild(i).?;
                    var child_cursor = child.walk();
                    try self.formatNode(writer, &child_cursor, 0);
                    if (i + 1 < node.namedChildCount()) try writer.writeAll(" ");
                }
                try writer.writeAll("}");
            },
            .for_in_clause => {
                try writer.writeAll("for ");

                const vari = node.namedChild(0).?;
                var vari_cursor = vari.walk();
                try self.formatNode(writer, &vari_cursor, 0);

                try writer.writeAll(" in ");

                const range = node.namedChild(1).?;
                var range_cursor = range.walk();
                try self.formatNode(writer, &range_cursor, 0);
            },
            .if_clause => {
                try writer.writeAll("if ");
                const child = node.namedChild(0).?;
                var child_cursor = child.walk();
                try self.formatNode(writer, &child_cursor, indent);
            },

            .ERROR => {
                std.debug.print("error\n", .{});
                //TODO: just abort operation, maybe say which line is error
            },
            else => {
                std.debug.print("{s} node found\n", .{node.kind()});
            },
        }
    }

    /// adds all children nodes and seperate with a comma
    /// useful for writing:
    /// - Lists
    /// - Argument list
    /// - Sets
    /// - Dicts
    /// - Parameters
    fn splatChildren(self: *Fmt, writer: *std.Io.Writer, node: ts.Node) error{WriteFailed}!void {
        const child_count = node.namedChildCount();
        var i: u32 = 0;
        while (i < child_count) : (i += 1) {
            const elem = node.namedChild(i).?;
            var elem_cursor = elem.walk();
            try self.formatNode(writer, &elem_cursor, 0);

            if (i + 1 < child_count) {
                try writer.writeAll(", ");
            }
        }
    }

    /// adds all children nodes and seperate with a comma
    /// useful for writing:
    /// - Subscript
    /// - multiple imports from
    fn splatChildrenLua(self: *Fmt, writer: *std.Io.Writer, node: ts.Node) error{WriteFailed}!void {
        const child_count = node.namedChildCount();
        var i: u32 = 1;
        while (i < child_count) : (i += 1) {
            const elem = node.namedChild(i).?;
            var elem_cursor = elem.walk();
            try self.formatNode(writer, &elem_cursor, 0);

            if (i + 1 < child_count) {
                try writer.writeAll(", ");
            }
        }
    }

    fn writeIndent(writer: *std.Io.Writer, level: usize) !void {
        var i: usize = 0;
        while (i < level) : (i += 1) {
            try writer.writeAll("    ");
        }
    }

    /// Prints debug info for a node
    /// First prints name
    /// Then number of children
    /// Then each child, including their type and thier content
    fn nodeDebugInfo(self: *Fmt, node: ts.Node) void {
        std.debug.print("node is: {s}\n", .{@tagName(NodeType.fromTsNode(node))});
        const children = node.namedChildCount();
        std.debug.print("node has {d} child nodes\n", .{children});
        var i: u32 = 0;
        while (i < children) : (i += 1) {
            const child = node.namedChild(i).?;
            std.debug.print("child {d} = {s}\n", .{ i, child.kind() });
            std.debug.print("{s}\n", .{self.source[child.startByte()..child.endByte()]});
        }
        std.debug.print("\n", .{});
    }
};

const NodeType = enum {
    module,
    block,
    class_definition,
    function_definition,
    decorated_definition,
    parameters,
    argument_list,
    tuple,
    return_statement,
    call,
    assignment,
    parenthesized_expression,
    attribute,
    subscript,
    default_parameter,
    keyword_argument,
    pass_statement,
    conditional_expression,
    augmented_assignment,
    decorator,

    with_statement,
    with_clause,
    as_pattern,

    try_statement,
    except_clause,
    finally_clause,

    lambda,

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

    import_statement,
    aliased_import,
    import_from_statement,
    wildcard_import,

    identifier,
    integer,
    float,
    comment,
    true,
    false,
    none,
    string,
    with_item,
    dotted_name,
    lambda_parameters,
    as_pattern_target,
    list,
    dictionary,
    set,
    pair,
    pattern_list,
    expression_list,
    list_splat_pattern,
    list_pattern,
    tuple_pattern,
    ellipsis,

    type,
    generic_type,
    typed_parameter,
    type_parameter,

    list_comprehension,
    set_comprehension,
    dictionary_comprehension,
    for_in_clause,
    if_clause,

    ERROR,
    unknown,

    /// translate TS node kinds to enums
    fn fromTsNode(node: ts.Node) NodeType {
        return std.meta.stringToEnum(NodeType, node.kind()) orelse .unknown;
    }
};
