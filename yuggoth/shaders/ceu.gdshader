// O céu atrás da cidade (Fase 3d): degradê do topo ao horizonte, nuvens de um
// ruído que corre devagar, e estrelas à noite. Num quad grande, longe.
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;

uniform vec3 topo : source_color = vec3(0.45, 0.62, 0.85);
uniform vec3 horizonte : source_color = vec3(0.8, 0.84, 0.88);
uniform vec3 nuvem_cor : source_color = vec3(0.95);
uniform float nuvens = 0.4;
uniform float estrelas = 0.0;
// O lapso (Fase 3e) faz as nuvens correrem: soma aqui, sem pular.
uniform float deriva = 0.0;
uniform sampler2D ruido : filter_linear, repeat_enable;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// UV.y = 0 no alto, 1 embaixo.
	float h = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 c = mix(horizonte, topo, smoothstep(0.0, 0.75, h));
	// Nuvens: faixas achatadas, mais densas perto do horizonte.
	vec2 p = vec2(UV.x * 2.5 + TIME * 0.002 + deriva, UV.y * 7.0);
	float n = texture(ruido, p * 0.5).r * 0.65 + texture(ruido, p * 1.3 + 0.37).r * 0.35;
	float cobre = smoothstep(1.0 - nuvens, 1.0 - nuvens * 0.45, n) * smoothstep(0.02, 0.35, 1.0 - abs(h - 0.45) * 1.6);
	c = mix(c, nuvem_cor, cobre * 0.85);
	// Estrelas: pontos raros, só no céu limpo.
	vec2 cel = floor(UV * vec2(420.0, 160.0));
	float e = step(0.9965, hash(cel)) * estrelas * (1.0 - cobre) * smoothstep(0.15, 0.6, h);
	c += vec3(e) * (0.6 + 0.4 * hash(cel + 3.1));
	ALBEDO = c;
}
