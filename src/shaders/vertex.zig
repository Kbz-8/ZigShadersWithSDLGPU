const std = @import("std");
const gpu = std.gpu;

extern var color: @Vector(4, f32) addrspace(.output);

export fn main() callconv(.spirv_vertex) void {
    gpu.location(&color, 0);

    const vertices = [_]@Vector(4, f32){
        .{ 0.0, 0.5, 0.0, 1.0 },
        .{ 0.5, -0.5, 0.0, 1.0 },
        .{ -0.5, -0.5, 0.0, 1.0 },
    };
    const colors = [_]@Vector(4, f32){
        .{ 1.0, 0.0, 0.0, 1.0 },
        .{ 0.0, 1.0, 0.0, 1.0 },
        .{ 0.0, 0.0, 1.0, 1.0 },
    };

    color = colors[gpu.vertex_index];
    gpu.position_out.* = vertices[gpu.vertex_index];
}
