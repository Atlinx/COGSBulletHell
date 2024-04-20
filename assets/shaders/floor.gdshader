shader_type canvas_item;
render_mode unshaded;

uniform vec4 background_color: source_color;
uniform sampler2D layer_1_noise;
uniform vec4 layer_1_color: source_color;
uniform float layer_1_threshold: hint_range(0.0, 1.0);
uniform sampler2D layer_2_noise;
uniform vec4 layer_2_color: source_color;
uniform float layer_2_threshold: hint_range(0.0, 1.0);

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment(){
    float noise_value;
    vec4 color = background_color;
	noise_value = texture(layer_1_noise, UV).x;
	if (noise_value > layer_1_threshold)
		color.rgb = mix(color.rgb, layer_1_color.rgb, layer_1_color.a);
	noise_value = texture(layer_2_noise, UV).x;
	if (noise_value > layer_2_threshold)
    	color.rgb = mix(color.rgb, layer_2_color.rgb, layer_2_color.a);
	COLOR = color * modulate;
}