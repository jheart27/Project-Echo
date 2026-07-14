shader_type canvas_item;

// Full-screen PS2-era horror pass: animated film grain, vignette, and
// edge-weighted chromatic aberration. Applied via a ColorRect on a high
// CanvasLayer (see scenes/effects/post_process.tscn). Keep values subtle —
// this should read as texture, not as a filter.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;

uniform float grain_intensity : hint_range(0.0, 0.2) = 0.045;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_radius : hint_range(0.3, 1.0) = 0.85;
uniform float aberration_strength : hint_range(0.0, 4.0) = 1.0;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p.yx + 19.19);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	float dist = length(centered);

	// Chromatic aberration, growing toward the screen edges.
	vec2 ab_offset = centered * dist * 0.004 * aberration_strength;
	vec3 color;
	color.r = texture(screen_texture, uv + ab_offset).r;
	color.g = texture(screen_texture, uv).g;
	color.b = texture(screen_texture, uv - ab_offset).b;

	// Animated film grain.
	float grain = hash(uv * 731.7 + vec2(fract(TIME * 7.31), fract(TIME * 3.17)) * 913.0);
	color += (grain - 0.5) * grain_intensity;

	// Vignette.
	float falloff = smoothstep(vignette_radius - 0.45, vignette_radius, dist);
	color *= 1.0 - falloff * vignette_intensity;

	COLOR = vec4(color, 1.0);
}
