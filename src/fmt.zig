const std = @import("std");
const ts = @import("tree_sitter");

pub const Fmt = struct {
    source: []const u8,
    output: std.ArrayList(u8),
    indent_str: []const u8 = "    ",

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Fmt {
        return .{
            .source = source,
            .output = try .initCapacity(allocator, ((3 * source.len) / 2)),
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

                try self.output.appendSlice(allocator, "\n");
            },
            .parameters => {
                try self.output.appendSlice(allocator, "(");

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

                try self.output.appendSlice(allocator, ")");
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
                try self.output.appendSlice(allocator, "(");

                const arg_count = node.namedChildCount();
                var i: u32 = 0;
                while (i < arg_count) : (i += 1) {
                    const arg = node.namedChild(i).?;
                    var arg_cursor = arg.walk();
                    try self.formatNode(allocator, &arg_cursor, 0);

                    if (i + 1 < arg_count) try self.output.appendSlice(allocator, ", ");
                }

                try self.output.appendSlice(allocator, ")");
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
                        try self.output.appendSlice(allocator, "\n");
                        if (!body_cursor.gotoNextSibling()) break;
                    }
                }
            },

            .assignment => {
                const lhs = node.namedChild(0).?;
                const rhs = node.namedChild(1).?;

                const lhs_text = self.source[lhs.startByte()..lhs.endByte()];

                try self.writeIndent(allocator, indent);
                try self.output.print(allocator, "{s} = ", .{lhs_text});

                var rhs_cursor = rhs.walk();
                try self.formatNode(allocator, &rhs_cursor, indent);
                try self.output.appendSlice(allocator, "\n");
            },
            .binary_operator => {
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
            //other node types
            else => {},
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

    binary_operator,

    identifier,
    integer,
    float,
    string,
    //add more nodetypes
    unknown,

    fn fromTsNode(node: ts.Node) NodeType {
        return std.meta.stringToEnum(NodeType, node.kind()) orelse .unknown;
    }
};
