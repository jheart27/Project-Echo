shader_type canvas_item;

// Full-screen PS2-era horror pass: animated film grain, vignette, and
// edge-weighted chromatic aberration. Applied via a ColorRect on a high
// CanvasLayer (see scenes/effects/post_process.tscn). Keep values subtle —
// this should read as texture, not as a filter.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;

uniform float grain_intensity : hint_range(0.0, 0.2) = 0.035;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_radius : hint_range(0.3, 1.0) = 0.85;
uniform float aberration_strength : hint_range(0.0, 4.0) = 1.0;

// Hash from pixel coordinates (not UV) so the noise is uncorrelated per
// pixel — UV-based hashing produced visible diagonal patterning.
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
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

	// Animated film grain, weighted toward the shadows like real film stock.
	vec2 seed = fract(vec2(TIME * 0.1231, TIME * 0.3171)) * 1024.0;
	float grain = hash(FRAGCOORD.xy + seed);
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color += (grain - 0.5) * grain_intensity * (1.0 - luma * 0.6);

	// Vignette.
	float falloff = smoothstep(vignette_radius - 0.45, vignette_radius, dist);
	color *= 1.0 - falloff * vignette_intensity;

	COLOR = vec4(color, 1.0);
}
