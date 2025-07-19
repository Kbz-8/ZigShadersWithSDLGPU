const sdl = @import("sdl3");
const builtin = @import("builtin");

pub const Renderer = struct {
    device: sdl.gpu.Device,

    pub fn init(window: *const sdl.video.Window) !Renderer {
        const device = try sdl.gpu.Device.init(.{ .spirv = true }, builtin.mode == .Debug, null);
        try device.claimWindow(window.*);
        return .{
            .device = device,
        };
    }

    pub fn deinit(self: *const Renderer) void {
        self.device.deinit();
    }
};
