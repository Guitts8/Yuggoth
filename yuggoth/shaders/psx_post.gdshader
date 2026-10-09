// Pós-processamento aplicado ao SubViewportContainer do mundo:
// dithering Bayer 4x4 + redução de cor, e distorção guiada por `exposicao`.
shader_type canvas_item;

// Níveis por canal (32 = 15 bits, como o PS1).
uniform float color_levels : hint_range(2.0, 256.0) = 32.0;
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;
uniform float vignette : hint_range(0.0, 2.0) = 0.6;
// Espelha GameState.exposicao (0..1), suavizado pelo GameRoot.
uniform float exposure : hint_range(0.0, 1.0) = 0.0;
// Visão dupla (0..1): a imagem se desdobra num fantasma que oscila ao lado
// (o sonho do disco, na voz zumbida; o Fonografo põe).
global uniform float psx_dupla;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	float e = exposure * exposure;
	vec2 uv = UV;
	uv.x += sin(uv.y * 38.0 + TIME * 1.7) * 0.003 * e;

	vec2 split = vec2(0.004 * e, 0.0);
	vec3 col = vec3(
		texture(TEXTURE, uv + split).r,
		texture(TEXTURE, uv).g,
		texture(TEXTURE, uv - split).b
	);
	if (psx_dupla > 0.001) {
		vec2 o = vec2(0.016 + 0.008 * sin(TIME * 0.9), 0.005 * cos(TIME * 1.3)) * psx_dupla;
		col = mix(col, texture(TEXTURE, uv + o).rgb, 0.45 * psx_dupla);
	}

	// Dither alinhado aos pixels do viewport de baixa resolução, não da tela.
	ivec2 p = ivec2(floor(uv / TEXTURE_PIXEL_SIZE)) % 4;
	float threshold = BAYER[p.y * 4 + p.x] / 16.0 - 0.5;
	col += threshold * dither_strength / color_levels;
	col = floor(col * color_levels + 0.5) / color_levels;

	vec2 d = UV - 0.5;
	col *= clamp(1.0 - dot(d, d) * vignette * (1.0 + e * 1.5), 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
