shader_type canvas_item;

// Fake thermal optics: luminance is lifted with a soft exponential knee
// (so dark spaces become readable — that's the gameplay use of the goggles)
// then mapped onto a heat ramp, with heavy sensor noise. Sits under the
// grain/vignette overlay in the post stack.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;

uniform float gain : hint_range(0.5, 8.0) = 3.5;
uniform float noise_amount : hint_range(0.0, 0.5) = 0.1;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 heat_ramp(float t) {
	vec3 c1 = vec3(0.02, 0.0, 0.1);
	vec3 c2 = vec3(0.35, 0.05, 0.45);
	vec3 c3 = vec3(0.85, 0.15, 0.1);
	vec3 c4 = vec3(1.0, 0.65, 0.15);
	vec3 c5 = vec3(1.0, 1.0, 0.85);
	if (t < 0.25) {
		return mix(c1, c2, t / 0.25);
	}
	if (t < 0.5) {
		return mix(c2, c3, (t - 0.25) / 0.25);
	}
	if (t < 0.75) {
		return mix(c3, c4, (t - 0.5) / 0.25);
	}
	return mix(c4, c5, (t - 0.75) / 0.25);
}

void fragment() {
	vec3 src = texture(screen_texture, SCREEN_UV).rgb;
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	lum = clamp(1.0 - exp(-lum * gain), 0.0, 1.0);
	vec2 seed = fract(vec2(TIME * 0.1231, TIME * 0.3171)) * 1024.0;
	float n = hash(FRAGCOORD.xy + seed);
	lum = clamp(lum + (n - 0.5) * noise_amount, 0.0, 1.0);
	COLOR = vec4(heat_ramp(lum), 1.0);
}
