const std = @import("std");
const gpu = std.gpu;

extern var color: @Vector(4, f32) addrspace(.input);

extern var frag_color: @Vector(4, f32) addrspace(.output);

export fn main() callconv(.spirv_fragment) void {
    gpu.location(&color, 0);
    gpu.location(&frag_color, 0);

    frag_color = color;
}
