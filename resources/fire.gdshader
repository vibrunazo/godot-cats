shader_type canvas_item;

// Fire bullet shader, migrated from the original Godot 3 VisualShader.
// Colors the sprite through MyGradient and fades alpha through AlphaGradient.

uniform sampler2D MyGradient;
uniform sampler2D AlphaGradient;

void fragment() {
	vec4 tex_read = texture(TEXTURE, UV);
	vec4 grad_read = texture(MyGradient, tex_read.rgb.xy);
	vec4 alpha_read = texture(AlphaGradient, tex_read.rgb.xy);
	vec3 m = vec3(tex_read.a) * alpha_read.rgb;
	COLOR.rgb = grad_read.rgb;
	COLOR.a = dot(m, vec3(0.333333, 0.333333, 0.333333));
}
