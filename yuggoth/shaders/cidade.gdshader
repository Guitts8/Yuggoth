// A cidade lá fora (Arkham pela janela do escritório, docs/PLANO_ESCRITORIO.md,
// Fase 3d). Sem as luzes da cena: a cor vem do vértice (cada casa, telhado,
// árvore a sua), sombreada por um sol fixo de cada hora do dia, e a distância a
// afoga na névoa (perspectiva aérea). As janelas usam `janelas`: a cor do vértice
// diz quanto cada uma acende (0 = nunca), e `acesas` liga a noite.
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;

uniform vec3 sol_dir = vec3(0.3, 0.7, 0.6);
uniform vec3 sol_cor : source_color = vec3(1.0);
uniform vec3 ambiente : source_color = vec3(0.45);
uniform vec3 neblina_cor : source_color = vec3(0.75, 0.8, 0.85);
uniform float neblina_de = 20.0;
uniform float neblina_ate = 90.0;
uniform float neblina_max = 0.85;
uniform bool janelas = false;
uniform vec3 vidro : source_color = vec3(0.1, 0.12, 0.14);
uniform vec3 luz_janela : source_color = vec3(1.0, 0.78, 0.42);
uniform float acesas = 0.0;
// O mostrador do relógio da torre (cor g do vértice): claro de dia.
uniform vec3 mostrador : source_color = vec3(0.86, 0.83, 0.72);

varying vec3 n_mundo;
varying vec4 cor;

void vertex() {
	n_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	cor = COLOR;
}

void fragment() {
	float d = length(VERTEX);
	vec3 c;
	float nb = clamp((d - neblina_de) / max(neblina_ate - neblina_de, 0.01), 0.0, 1.0) * neblina_max;
	if (janelas) {
		float luz = cor.r * acesas;
		vec3 base = cor.g > 0.5 ? mostrador * (ambiente + sol_cor * 0.7) : vidro;
		c = mix(base, luz_janela, luz);
		// Janela acesa fura a névoa (é luz, não superfície).
		nb *= 1.0 - luz * 0.7;
	} else {
		float lambert = max(dot(normalize(n_mundo), normalize(sol_dir)), 0.0);
		c = cor.rgb * (ambiente + sol_cor * lambert);
	}
	ALBEDO = mix(c, neblina_cor, nb);
}
