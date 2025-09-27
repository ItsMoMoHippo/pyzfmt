const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "pyzigfmt",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const tree_sitter = b.dependency("tree_sitter", .{
        .optimize = optimize,
        .target = target,
    });
    exe.root_module.addImport("tree_sitter", tree_sitter.module("tree_sitter"));

    exe.root_module.addCSourceFile(.{
        .file = b.path("tree-sitter-python/src/scanner.c"),
    });
    exe.root_module.addCSourceFile(.{
        .file = b.path("tree-sitter-python/src/parser.c"),
    });
    exe.root_module.link_libc = true;

    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
