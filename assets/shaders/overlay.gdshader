shader_type canvas_item;


uniform vec4 overlay_color: source_color = vec4(1.0);
uniform float overlay_amount: hint_range(0.0, 1.0) = 0.5;

uniform float alpha_cutoff: hint_range(0.0, 1.0) = 0.5;

varying vec4 modulate;


void vertex() {
	modulate = COLOR;
}


void fragment() {
	vec4 base_color = texture(TEXTURE, UV) * modulate;
	if (base_color.a > alpha_cutoff) {
		COLOR = mix(base_color, overlay_color, overlay_amount);
	} else {
		COLOR = base_color;
	}
}
