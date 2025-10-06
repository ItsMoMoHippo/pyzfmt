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
                std.debug.print("cursor inside module\n", .{});
                if (cursor.gotoFirstChild()) {
                    // std.debug.print("found child", .{});
                    while (true) {
                        try self.formatNode(allocator, cursor, indent);
                        if (!cursor.gotoNextSibling()) break;
                    }
                    _ = cursor.gotoParent();
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
