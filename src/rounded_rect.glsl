@vs vs
layout(binding=0) uniform vs_params {
	vec2 framesize;
};

in vec4 rect;
in vec4 shape;
in vec4 fill_color;
in vec4 border_color;

out vec2 local_pos;
out flat vec2 rect_size;
out flat float radius;
out flat float border_width;
out vec4 frag_fill_color;
out vec4 frag_border_color;

void main() {
	vec2 corner = vec2(float(gl_VertexIndex & 1), float(gl_VertexIndex >> 1));
	vec2 local = corner * rect.zw;
	vec2 pos = rect.xy + local;
	vec2 clip = pos * framesize;
	gl_Position = vec4(clip.x - 1.0, clip.y + 1.0, 0.0, 1.0);
	local_pos = local;
	rect_size = rect.zw;
	radius = shape.x;
	border_width = shape.y;
	frag_fill_color = fill_color;
	frag_border_color = border_color;
}
@end

@fs fs
in vec2 local_pos;
in flat vec2 rect_size;
in flat float radius;
in flat float border_width;
in vec4 frag_fill_color;
in vec4 frag_border_color;

out vec4 out_color;

float rounded_box_distance(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
	vec2 half_size = rect_size * 0.5;
	vec2 p = local_pos - half_size;
	float outer_radius = min(radius, min(half_size.x, half_size.y));
	float outer = rounded_box_distance(p, half_size, outer_radius);
	float outer_alpha = 1.0 - smoothstep(-0.5, 0.5, outer);
	vec4 color = frag_fill_color;
	if (border_width > 0.0) {
		vec2 inner_half = max(half_size - vec2(border_width), vec2(0.0));
		float inner_radius = max(outer_radius - border_width, 0.0);
		float inner = rounded_box_distance(p, inner_half, inner_radius);
		float inner_alpha = 1.0 - smoothstep(-0.5, 0.5, inner);
		color = mix(frag_border_color, frag_fill_color, inner_alpha);
	}
	out_color = vec4(color.rgb, color.a * outer_alpha);
}
@end

@program rounded_rect vs fs
