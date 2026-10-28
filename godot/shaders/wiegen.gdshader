// Wier en koraal wiegen zacht heen en weer; de onderkant staat vast.
shader_type canvas_item;

uniform float amp = 0.035;
uniform float tempo = 0.9;

varying float plek;

void vertex() {
	plek = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x * 0.004;
}

void fragment() {
	float boven = 1.0 - UV.y;
	float off = sin(TIME * tempo + plek + UV.y * 2.0) * boven * boven * amp;
	vec2 uv = vec2(UV.x - off, UV.y);
	vec4 c = texture(TEXTURE, uv);
	if (uv.x < 0.0 || uv.x > 1.0) {
		c.a = 0.0;
	}
	COLOR = c * COLOR;
}
