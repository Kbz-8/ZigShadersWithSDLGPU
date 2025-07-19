const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdl3 = b.dependency("sdl3", .{
        .target = target,
        .optimize = optimize,
        .callbacks = false,
        .ext_image = true,

        // Options passed directly to https://github.com/castholm/SDL (SDL3 C Bindings):
        //.c_sdl_preferred_linkage = .static,
        //.c_sdl_strip = false,
        //.c_sdl_sanitize_c = .off,
        //.c_sdl_lto = .none,
        //.c_sdl_emscripten_pthreads = false,
        //.c_sdl_install_build_config_h = false,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("sdl3", sdl3.module("sdl3"));

    const exe = b.addExecutable(.{
        .name = "Psyche",
        .root_module = exe_mod,
    });

    const spirv_target = b.resolveTargetQuery(.{
        .cpu_arch = .spirv32,
        .cpu_model = .{ .explicit = &std.Target.spirv.cpu.vulkan_v1_2 },
        .os_tag = .vulkan,
        .ofmt = .spirv,
    });

    const vertex_shader = b.addObject(.{
        .name = "vertex.zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/shaders/vertex.zig"),
            .target = spirv_target,
        }),
        .use_llvm = false,
    });

    const fragment_shader = b.addObject(.{
        .name = "fragment.zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/shaders/fragment.zig"),
            .target = spirv_target,
        }),
        .use_llvm = false,
    });

    exe.root_module.addAnonymousImport(
        "shaders.vertex.zig",
        .{ .root_source_file = vertex_shader.getEmittedBin() },
    );
    exe.root_module.addAnonymousImport(
        "shaders.fragment.zig",
        .{ .root_source_file = fragment_shader.getEmittedBin() },
    );

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
