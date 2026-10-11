shader_type canvas_item;
// A tinta se espalha pela tela (progresso 0→1) e seca em céu de fim de tarde
// (ceu 0→1): só o céu, nas cores do céu da fazenda (gerar_fazenda._env), que
// entra por baixo dele com a câmera olhando para o alto (playtest 10: os morros
// desenhados pareciam "montanhas de desenho de criança"). Entrada do Interlúdio
// (GDD §5.1a); ver TintaTransicao.

uniform float progresso : hint_range(0.0, 1.0) = 0.0;
uniform float ceu : hint_range(0.0, 1.0) = 0.0;
uniform float aspecto = 1.7778;
// O céu é desenhado na grade do mundo (TintaTransicao passa a altura do
// SubViewport), para emendar com o PS1.
uniform float linhas = 540.0;
uniform vec4 cor_tinta : source_color = vec4(0.07, 0.06, 0.08, 1.0);
// Medidas no primeiro quadro da descida (o céu da fazenda já com a névoa, o
// tonemap e o pós): o malva no alto, o rosado, o horizonte alaranjado.
uniform vec4 ceu_alto : source_color = vec4(0.48, 0.37, 0.46, 1.0);
uniform vec4 ceu_horizonte : source_color = vec4(0.84, 0.6, 0.46, 1.0);
uniform vec4 cor_nuvem : source_color = vec4(0.4, 0.3, 0.38, 1.0);
// O sol baixo, perto da borda de baixo, à esquerda (onde está no 3D).
uniform vec2 sol_pos = vec2(0.26, 0.95);
uniform vec4 cor_sol : source_color = vec4(0.97, 0.88, 0.62, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * ruido(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = vec2(UV.x * aspecto, UV.y);

	// Manchas com borda irregular, puxadas do meio (onde está a letra) para fora.
	float campo = fbm(p * 3.0) * 0.7 + (1.0 - length(UV - 0.5)) * 0.3;
	float limiar = 1.0 - progresso * 1.35;
	float tinta = smoothstep(limiar, limiar + 0.03, campo);

	// O céu: escuro no alto, alaranjado no horizonte, nuvens baixas e espessas.
	vec2 grade = vec2(linhas * aspecto, linhas);
	vec2 uv = (floor(UV * grade) + 0.5) / grade;
	p = vec2(uv.x * aspecto, uv.y);
	// O horizonte fica embaixo, rente à borda: é para lá que a câmera da fazenda
	// vai descer.
	vec3 cor = mix(ceu_alto.rgb, ceu_horizonte.rgb, pow(smoothstep(0.0, 1.0, uv.y), 1.2));
	float brilho = 1.0 - smoothstep(0.0, 0.42, length((uv - sol_pos) * vec2(aspecto, 1.0)));
	cor = mix(cor, cor_sol.rgb, brilho * brilho * 0.75);
	float nuvem = fbm(vec2(p.x * 1.6, p.y * 7.0) + vec2(3.0, 0.0));
	cor = mix(cor, cor_nuvem.rgb, smoothstep(0.5, 0.78, nuvem) * (1.0 - smoothstep(0.35, 0.85, uv.y)) * 0.35);

	// Poucas cores, como uma textura de 15 bits.
	cor = floor(cor * 32.0) / 32.0;

	// A tinta "seca" em céu, também em manchas.
	float limiar_ceu = 1.0 - ceu * 1.3;
	float seca = smoothstep(limiar_ceu, limiar_ceu + 0.08, fbm(p * 2.0 + 7.0));
	COLOR = vec4(mix(cor_tinta.rgb, cor, seca), max(tinta, seca));
}
