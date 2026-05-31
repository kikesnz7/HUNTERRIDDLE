shader_type canvas_item;

uniform float radius_px : hint_range(0.0, 400.0) = 40.0;

void fragment() {
	vec2 tex_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	vec2 pos = UV * tex_size;
	vec2 d = min(pos, tex_size - pos);
	if (d.x < radius_px && d.y < radius_px) {
		vec2 corner = vec2(radius_px - d.x, radius_px - d.y);
		if (length(corner) > radius_px) {
			discard;
		}
	}
}
