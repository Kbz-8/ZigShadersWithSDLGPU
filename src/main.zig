const sdl = @import("sdl3");
const std = @import("std");
const builtin = @import("builtin");

const SCREEN_WIDTH = 1250;
const SCREEN_HEIGHT = 720;

const vertex_shader_source = @embedFile("shaders.vertex.zig");
const fragment_shader_source = @embedFile("shaders.fragment.zig");

pub fn main() !void {
    defer sdl.shutdown();

    const init_flags = sdl.InitFlags{ .video = true };
    try sdl.init(init_flags);
    defer sdl.quit(init_flags);

    const window = try sdl.video.Window.init("Hello triangle", SCREEN_WIDTH, SCREEN_HEIGHT, .{ .resizable = true });
    defer window.deinit();

    const device = try sdl.gpu.Device.init(.{ .spirv = true }, builtin.mode == .Debug, null);
    defer device.deinit();

    try device.claimWindow(window);

    const vertex_shader = try device.createShader(.{ .code = vertex_shader_source, .entry_point = "main", .format = .{ .spirv = true }, .stage = .vertex });
    defer device.releaseShader(vertex_shader);
    const fragment_shader = try device.createShader(.{ .code = fragment_shader_source, .entry_point = "main", .format = .{ .spirv = true }, .stage = .fragment });
    defer device.releaseShader(fragment_shader);

    const pipeline = try device.createGraphicsPipeline(.{ .vertex_shader = vertex_shader, .fragment_shader = fragment_shader, .target_info = .{ .color_target_descriptions = &.{.{ .format = device.getSwapchainTextureFormat(window) }} } });
    defer device.releaseGraphicsPipeline(pipeline);

    var running = true;
    mainloop: while (running) {
        if (sdl.events.poll()) |event| {
            switch (event) {
                .quit => running = false,
                .terminating => running = false,
                else => {},
            }
        }

        const cmd = try device.acquireCommandBuffer();
        const texture = cmd.waitAndAcquireSwapchainTexture(window) catch {
            try cmd.submit();
            continue :mainloop;
        };
        const render_targets = [_]sdl.gpu.ColorTargetInfo{.{ .texture = texture.texture.? }};
        const renderpass = cmd.beginRenderPass(&render_targets, null);
        renderpass.bindGraphicsPipeline(pipeline);
        renderpass.drawPrimitives(3, 1, 0, 0);
        renderpass.end();
        try cmd.submit();
    }
}
