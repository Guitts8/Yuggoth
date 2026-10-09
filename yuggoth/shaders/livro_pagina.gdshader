// As páginas do livro dos menus (Necronomicon, playtest 7; refeito na sessão do
// menu, à maneira de Castlevania: Lords of Shadow 2): o papel velho por baixo e a
// tinta dos menus por cima (a textura de um SubViewport com os menus, as duas
// páginas lado a lado: UV.x 0..0.5 a esquerda, 0.5..1 a direita).
//
// O papel: amarelado, as bordas queimadas e irregulares, manchas de umidade e de
// mofo, uma mancha cor de ferrugem que sobe das bordas. A tinta assenta nele e se
// espalha um pouco nas fibras (uma auréola mais escura em volta do traço).
// `revelar` (0..1) faz a tinta brotar no papel, do meio para fora, com a borda
// molhada; `sombra` escurece a página sob a folha que vira; `brisa` levanta um
// pouco o canto de fora da página da direita.
//
// Com `virando`, é a folha que vira: a malha é uma folha deitada de s = 0 (na
// lombada) a 1 (na borda), ao longo de +X, e o vértice gira na lombada com a
// ponta atrasada (a folha se curva); `lado` = +1 vira da direita para a
// esquerda, −1 ao contrário. A frente mostra a página que sai (`foto`); o
// verso, a que chega (a tinta viva).
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform sampler2D tinta : source_color, filter_linear, repeat_disable;
uniform sampler2D foto : source_color, filter_linear, repeat_disable;
uniform sampler2D papel : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
// 1 = esta página mostra a foto (o par de antes) em vez da tinta viva.
uniform float usar_foto = 0.0;
// Quanto a página sobe junto à lombada (m); 0 = plana (o livro fechado).
uniform float arco = 0.04;
// Largura de uma página (m).
uniform float largura = 0.5;
uniform float altura = 0.68;
uniform bool virando = false;
uniform float progresso = 0.0;
uniform float lado = 1.0;
uniform float curva = 1.4;
uniform float claridade = 0.12;
// A tinta brotando no papel (0 = nada escrito, 1 = tudo).
uniform float revelar = 1.0;
// A sombra da folha que vira sobre esta página: força e até onde (0..1 da
// lombada à borda) ela cobre.
uniform float sombra = 0.0;
uniform float sombra_ate = 0.0;
// O canto de fora levantado pela corrente de ar (m).
uniform float brisa = 0.0;

varying float s_folha;
varying vec3 pos_local;

float perfil(float u) {
	u = clamp(u, 0.0, 1.0);
	return (1.0 - exp(-12.0 * u)) * (1.0 - 0.85 * u);
}

void vertex() {
	if (virando) {
		float s = clamp(VERTEX.x / largura, 0.0, 1.0);
		s_folha = s;
		float theta = PI * progresso;
		float c = curva * sin(PI * progresso) / largura;
		float l = s * largura;
		vec2 p;
		float phi = theta - c * l;
		if (abs(c) < 0.0001) {
			p = l * vec2(cos(theta), sin(theta));
		} else {
			p = vec2(sin(theta) - sin(phi), cos(phi) - cos(theta)) / c;
		}
		// O arco da página em repouso, dos dois lados, enquanto ela passa.
		float y = p.y + arco * perfil(s) * (1.0 - sin(PI * progresso)) + 0.0015;
		VERTEX = vec3(lado * p.x, y, VERTEX.z);
		// Espelhada (lado = −1), a face de cima vira a de trás: a normal acompanha.
		NORMAL = normalize(vec3(-lado * sin(phi), cos(phi), 0.0)) * lado;
	} else {
		float u = abs(VERTEX.x) / largura;
		VERTEX.y += arco * perfil(u);
		// O canto de fora, embaixo (o mais perto dos olhos), levantado pelo ar.
		if (VERTEX.x > 0.0) {
			float canto = smoothstep(0.55, 1.0, u) * smoothstep(0.5, 1.0, VERTEX.z / altura + 0.5);
			VERTEX.y += brisa * canto * canto;
		}
		// A normal da página arqueada (a derivada do perfil).
		float d = arco * (12.0 * exp(-12.0 * u) * (1.0 - 0.85 * u) - 0.85 * (1.0 - exp(-12.0 * u))) / largura;
		NORMAL = normalize(vec3(-sign(VERTEX.x) * d, 1.0, 0.0));
	}
	pos_local = VERTEX;
}

float n2(vec2 uv) {
	return texture(ruido, uv).r;
}

vec3 papel_em(vec2 uv) {
	vec2 pu = vec2(fract(uv.x * 2.0), uv.y);
	if (uv.x >= 0.999) {
		pu.x = 1.0;
	}
	// Cada página com a sua metade da textura do papel (sem emenda no meio dela).
	vec3 c = texture(papel, vec2(clamp(uv.x, 0.002, 0.998), uv.y)).rgb;
	// As fibras do papel: riscas finas e compridas, na direção da folha.
	c *= 0.96 + 0.08 * n2(uv * vec2(3.0, 48.0)) - 0.03 * n2(uv * vec2(40.0, 9.0));
	// A distância à borda de fora (não ao vinco), recortada pelo ruído: a borda
	// gasta e queimada não é reta.
	bool esquerda = uv.x < 0.5;
	float fora_x = esquerda ? pu.x : 1.0 - pu.x;
	float borda = min(fora_x * 1.38, min(pu.y, 1.0 - pu.y));
	float rasgo = (n2(uv * vec2(3.0, 2.2)) - 0.5) * 0.045 + (n2(uv * 17.0) - 0.5) * 0.012;
	float b = borda + rasgo;
	// A mancha de ferrugem (sangue velho) que sobe das bordas, em línguas.
	float lingua = smoothstep(0.42, 0.75, n2(uv * vec2(2.1, 1.6) + 0.37));
	float ferrugem = (1.0 - smoothstep(0.0, 0.16 + 0.1 * lingua, b)) * (0.55 + 0.45 * lingua);
	c = mix(c, vec3(0.42, 0.13, 0.06), ferrugem * 0.55);
	// Queimado: escurece até quase negro na extremidade.
	c *= mix(0.18, 1.0, smoothstep(-0.005, 0.05, b));
	c *= mix(0.72, 1.0, smoothstep(0.0, 0.11, b));
	// O vinco, na sombra (a página desce para dentro da lombada).
	float vinco = abs(uv.x - 0.5) * 2.0;
	c *= mix(0.3, 1.0, smoothstep(0.0, 0.2, vinco));
	return c;
}

void fragment() {
	vec2 uv = UV;
	bool da_foto = usar_foto > 0.5;
	if (virando) {
		// A frente mostra a página que sai; o verso, a do outro lado, que chega.
		// Espelhada (lado = −1), a frente do Godot é a face de baixo.
		if (FRONT_FACING == (lado > 0.0)) {
			uv = vec2(0.5 + lado * 0.5 * s_folha, UV.y);
			da_foto = true;
		} else {
			uv = vec2(0.5 - lado * 0.5 * s_folha, UV.y);
			da_foto = false;
		}
	}
	vec4 t = da_foto ? texture(foto, uv) : texture(tinta, uv);
	// A tinta que se espalhou nas fibras: a média em volta, um pouco maior que o traço.
	vec2 px = vec2(1.0 / 1240.0, 1.0 / 840.0) * 1.6;
	float aura = 0.0;
	if (!da_foto) {
		aura = (texture(tinta, uv + vec2(px.x, 0.0)).a + texture(tinta, uv - vec2(px.x, 0.0)).a
			+ texture(tinta, uv + vec2(0.0, px.y)).a + texture(tinta, uv - vec2(0.0, px.y)).a) * 0.25;
	}
	// A tinta brotando: do meio de cada página para fora, com um contorno irregular.
	float a_rev = 1.0;
	float molhado = 0.0;
	if (revelar < 0.999 && !da_foto) {
		vec2 pu = vec2(fract(uv.x * 2.0), uv.y);
		float d = length((pu - vec2(0.5, 0.42)) * vec2(1.0, 1.3));
		float limiar = revelar * 1.25 - d - (n2(uv * 6.0) - 0.5) * 0.25;
		a_rev = smoothstep(0.0, 0.05, limiar);
		molhado = smoothstep(0.0, 0.03, limiar) * (1.0 - smoothstep(0.03, 0.12, limiar));
	}
	vec3 p = papel_em(uv);
	float sobre = t.a * a_rev;
	// A tinta assenta no papel: um pouco do papel passa por ela; a auréola escurece em volta.
	vec3 c = p * (1.0 - aura * 0.18 * a_rev);
	c = mix(c, t.rgb * mix(vec3(1.0), p * 1.15, 0.3), sobre);
	// A borda da tinta que acaba de brotar, ainda molhada: mais escura e brilhante.
	c *= 1.0 - molhado * t.a * 0.5;
	// A sombra da folha que passa por cima.
	if (sombra > 0.0 && !virando) {
		float s = abs(uv.x - 0.5) * 2.0;
		c *= 1.0 - sombra * (1.0 - smoothstep(sombra_ate - 0.25, sombra_ate + 0.05, s)) * 0.7;
	}
	ALBEDO = c;
	ROUGHNESS = mix(0.93, 0.45, molhado * t.a);
	SPECULAR = 0.25 + molhado * t.a * 0.5;
	EMISSION = c * claridade;
}
