// Laat een tekening zwemmen: de staart (links) slaat op en neer, de kop (rechts) blijft rustig.
shader_type canvas_item;

uniform float fase = 0.0;
uniform float amp = 0.05;
uniform float golf = 3.4;

varying vec4 kleur;

void vertex() {
	kleur = COLOR;
}

void fragment() {
	float staart = 1.0 - UV.x;
	float off = sin(fase - staart * golf) * staart * staart * amp;
	vec2 uv = vec2(UV.x, UV.y - off);
	vec4 c = texture(TEXTURE, uv);
	if (uv.y < 0.0 || uv.y > 1.0) {
		c.a = 0.0;
	}
	COLOR = c * kleur;
}
