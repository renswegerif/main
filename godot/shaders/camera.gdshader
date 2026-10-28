// Zet het webcambeeld om naar gewone kleuren (Mac-camera's leveren YCbCr) en draait of spiegelt het.
shader_type canvas_item;

uniform sampler2D tex_rgb : filter_linear;
uniform sampler2D tex_y : filter_linear;
uniform sampler2D tex_cbcr : filter_linear;
uniform int modus = 0; // 0 = rgb, 1 = y en cbcr apart
uniform int draai = 0; // aantal kwartslagen
uniform bool spiegel = false;

void fragment() {
	vec2 uv = UV;
	if (draai == 1) { uv = vec2(uv.y, 1.0 - uv.x); }
	if (draai == 2) { uv = vec2(1.0 - uv.x, 1.0 - uv.y); }
	if (draai == 3) { uv = vec2(1.0 - uv.y, uv.x); }
	if (spiegel) { uv.x = 1.0 - uv.x; }
	vec3 rgb;
	if (modus == 1) {
		float y = texture(tex_y, uv).r;
		vec2 c = texture(tex_cbcr, uv).rg - vec2(0.5);
		rgb = vec3(y + 1.402 * c.y, y - 0.344136 * c.x - 0.714136 * c.y, y + 1.772 * c.x);
	} else {
		rgb = texture(tex_rgb, uv).rgb;
	}
	COLOR = vec4(rgb, 1.0);
}
