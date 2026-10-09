// As páginas do livro dos menus (Necronomicon, playtest 7): o papel velho por
// baixo e a tinta dos menus por cima (a textura de um SubViewport com os
// menus, as duas páginas lado a lado: UV.x 0..0.5 a esquerda, 0.5..1 a direita).
// A página sobe junto à lombada (`arco`) e escurece no vinco e nas bordas.
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
// 1 = esta página mostra a foto (o par de antes) em vez da tinta viva.
uniform float usar_foto = 0.0;
// Quanto a página sobe junto à lombada (m); 0 = plana (o livro fechado).
uniform float arco = 0.04;
// Largura de uma página (m).
uniform float largura = 0.5;
uniform bool virando = false;
uniform float progresso = 0.0;
uniform float lado = 1.0;
uniform float curva = 1.4;
uniform float claridade = 0.22;

varying float s_folha;

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
		// A normal da página arqueada (a derivada do perfil).
		float d = arco * (12.0 * exp(-12.0 * u) * (1.0 - 0.85 * u) - 0.85 * (1.0 - exp(-12.0 * u))) / largura;
		NORMAL = normalize(vec3(-sign(VERTEX.x) * d, 1.0, 0.0));
	}
}

vec3 papel_em(vec2 uv) {
	vec2 pu = vec2(fract(uv.x * 2.0), uv.y);
	// Cada página com a sua metade da textura do papel (sem emenda no meio dela).
	vec3 c = texture(papel, vec2(clamp(uv.x, 0.002, 0.998), uv.y)).rgb;
	// As bordas mais escuras e queimadas; o vinco, na sombra.
	float borda = min(min(pu.x, 1.0 - pu.x), min(pu.y, 1.0 - pu.y));
	c *= mix(0.62, 1.0, smoothstep(0.0, 0.07, borda));
	float vinco = abs(uv.x - 0.5) * 2.0;
	c *= mix(0.42, 1.0, smoothstep(0.0, 0.16, vinco));
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
	vec3 p = papel_em(uv);
	// A tinta assenta no papel: um pouco do papel passa por ela.
	vec3 c = mix(p, t.rgb * mix(vec3(1.0), p, 0.25), t.a);
	ALBEDO = c;
	ROUGHNESS = 0.92;
	EMISSION = c * claridade;
}
