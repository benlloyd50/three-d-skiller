shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec2 region_size_px;
uniform vec2 tile_factor = vec2(1.000000, 1.000000);
uniform vec2 atlas_offset;
uniform sampler2D atlas : source_color, filter_nearest;

void fragment() {
    const float SEEM_HIDING = 1.0/128.0;
    const float SEEM_SCALE = 1.0 - SEEM_HIDING * 2.0;
    vec2 tiled_pixel = mod(UV * tile_factor, 1.0) * region_size_px * SEEM_SCALE + SEEM_HIDING;
    vec2 newUV = (tiled_pixel + atlas_offset) / vec2(textureSize(atlas, 0));

    ALBEDO = texture(atlas, newUV).xyz;
}