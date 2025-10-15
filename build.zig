const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // main project
    const exe = b.addExecutable(.{
        .name = "pyzfmt",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // ts bindings
    const tree_sitter = b.dependency("tree_sitter", .{
        .optimize = optimize,
        .target = target,
    });
    exe.root_module.addImport("tree_sitter", tree_sitter.module("tree_sitter"));

    // python grammer
    exe.root_module.addCSourceFiles(.{ .files = &.{ "tree-sitter-python/src/scanner.c", "tree-sitter-python/src/parser.c" } });
    exe.root_module.link_libc = true;

    const fmt = b.addModule("fmt", .{
        .root_source_file = b.path("src/fmt.zig"),
    });
    fmt.addImport("tree_sitter", tree_sitter.module("tree_sitter"));

    // build
    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const test_step = b.step("test", "Run unit tests");

    const module = b.createModule(.{
        .root_source_file = b.path("test/test.zig"),
        .target = target,
    });
    module.addImport("tree_sitter", tree_sitter.module("tree_sitter"));
    module.addImport("fmt_module", fmt);
    const unit_tests = b.addTest(.{
        .root_module = module,
        //  .test_runner = .{ .path = serpent_mod.root_source_file.?, .mode = .simple }
    });

    module.addCSourceFiles(.{ .files = &.{ "tree-sitter-python/src/scanner.c", "tree-sitter-python/src/parser.c" } });
    module.link_libc = true;

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.has_side_effects = true;
    test_step.dependOn(&run_unit_tests.step);
}
