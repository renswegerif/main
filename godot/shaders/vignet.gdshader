// Randen lopen af naar zwart, zodat je de rechthoek van de beamer niet op het water ziet.
shader_type canvas_item;

uniform float sterkte = 1.0;

void fragment() {
	vec2 d = UV - 0.5;
	float a = smoothstep(0.3, 0.72, length(d));
	COLOR = vec4(0.0, 0.0, 0.0, a * sterkte);
}
