// O corte das folhas do livro dos menus (Necronomicon): as bordas do miolo, de
// centenas de folhas velhas e desiguais. Os vértices de cima (COLOR.r = 1)
// sobem com o arco da página, como a página (livro_pagina.gdshader).
shader_type spatial;
render_mode cull_disabled;

uniform float arco = 0.04;
uniform float largura = 0.5;
uniform vec3 cor : source_color = vec3(0.72, 0.62, 0.43);

varying float alto;

float perfil(float u) {
	u = clamp(u, 0.0, 1.0);
	return (1.0 - exp(-12.0 * u)) * (1.0 - 0.85 * u);
}

float ruido(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

void vertex() {
	alto = COLOR.r;
	if (COLOR.r > 0.5) {
		VERTEX.y += arco * perfil(abs(VERTEX.x) / largura);
	}
}

void fragment() {
	// As folhas, uma sobre a outra: riscas finas, cada uma de um tom; umas
	// saem mais que as outras (o corte desigual).
	float folha = floor(UV.y * 260.0);
	float tom = 0.82 + 0.3 * ruido(folha);
	float risca = smoothstep(0.35, 0.5, abs(fract(UV.y * 260.0) - 0.5));
	vec3 c = cor * tom * mix(1.0, 0.72, risca);
	// A sujeira dos séculos: mais escuro perto das bordas e em manchas.
	float mancha = ruido(floor(UV.x * 40.0) + folha * 0.01);
	c *= mix(0.78, 1.0, mancha);
	c *= mix(0.55, 1.0, smoothstep(0.0, 0.25, min(UV.y, 1.0 - UV.y)));
	ALBEDO = c;
	ROUGHNESS = 0.95;
	EMISSION = c * 0.06;
}
