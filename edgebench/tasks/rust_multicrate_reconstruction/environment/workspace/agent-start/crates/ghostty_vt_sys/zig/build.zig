const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    // First, get the uucode dependency with our config to generate tables.zig
    const uucode_config = b.dependency("uucode", .{
        .build_config_path = b.path("uucode_config.zig"),
    });
    const uucode_tables = uucode_config.namedLazyPath("tables.zig");

    // Get uucode module for host (for running the generators)
    const uucode_host = b.dependency("uucode", .{
        .target = b.graph.host,
        .optimize = optimize,
        .build_config_path = b.path("uucode_config.zig"),
        .tables_path = uucode_tables,
    });

    // Get uucode module for target (for the actual library)
    const uucode_target = b.dependency("uucode", .{
        .target = target,
        .optimize = optimize,
        .build_config_path = b.path("uucode_config.zig"),
        .tables_path = uucode_tables,
    });

    // Build the props table generator (uses uucode)
    const props_exe = b.addExecutable(.{
        .name = "props-unigen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("ghostty_src/unicode/props_uucode.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
        .use_llvm = true,
    });
    props_exe.root_module.addImport("uucode", uucode_host.module("uucode"));

    // Build the symbols table generator (uses uucode)
    const symbols_exe = b.addExecutable(.{
        .name = "symbols-unigen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("ghostty_src/unicode/symbols_uucode.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
        .use_llvm = true,
    });
    symbols_exe.root_module.addImport("uucode", uucode_host.module("uucode"));

    const props_run = b.addRunArtifact(props_exe);
    const symbols_run = b.addRunArtifact(symbols_exe);

    // Capture and rename to .zig files
    const wf = b.addWriteFiles();
    const props_output = wf.addCopyFile(props_run.captureStdOut(), "props.zig");
    const symbols_output = wf.addCopyFile(symbols_run.captureStdOut(), "symbols.zig");

    // Create terminal_options build options
    const terminal_options = b.addOptions();
    terminal_options.addOption(Artifact, "artifact", .lib);
    terminal_options.addOption(bool, "c_abi", false);
    terminal_options.addOption(bool, "oniguruma", false);
    terminal_options.addOption(bool, "simd", false);
    terminal_options.addOption(bool, "slow_runtime_safety", false);
    terminal_options.addOption(bool, "kitty_graphics", false);
    terminal_options.addOption(bool, "tmux_control_mode", false);

    const lib = b.addLibrary(.{
        .name = "ghostty_vt",
        .root_module = b.createModule(.{
            .root_source_file = b.path("lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });
    lib.linkLibC();
    lib.root_module.addImport("uucode", uucode_target.module("uucode"));
    lib.root_module.addOptions("terminal_options", terminal_options);

    props_output.addStepDependencies(&lib.step);
    lib.root_module.addAnonymousImport("unicode_tables", .{
        .root_source_file = props_output,
    });
    symbols_output.addStepDependencies(&lib.step);
    lib.root_module.addAnonymousImport("symbols_tables", .{
        .root_source_file = symbols_output,
    });

    const include_step = b.addInstallHeaderFile(
        b.path("../include/ghostty_vt.h"),
        "ghostty_vt.h",
    );

    const lib_install = b.addInstallLibFile(lib.getEmittedBin(), "libghostty_vt.a");
    b.getInstallStep().dependOn(&include_step.step);
    b.getInstallStep().dependOn(&lib_install.step);
}

const Artifact = enum {
    ghostty,
    lib,
};
