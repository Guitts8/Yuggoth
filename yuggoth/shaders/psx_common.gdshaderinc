// Parte comum dos materiais PSX (psx_lit, psx_unlit): jitter de vértices,
// textura afim e UV opcional pelo espaço do mundo.
// Pensado para rodar dentro do SubViewport de baixa resolução do GameRoot.

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0);
// UV projetada do mundo pelo eixo dominante da normal: paredes e pisos de
// qualquer tamanho com a mesma densidade de textura, sem ajustar uv_scale.
uniform bool world_uv = false;
uniform float tiles_per_meter = 1.0;
// 1.0 = grade de meio pixel do viewport; maior = jitter mais grosso.
uniform float snap_scale : hint_range(0.5, 4.0) = 1.0;
// Globais (Project Settings > Shader Globals), definidos pelo GameRoot a partir
// de `exposicao` e `sonho`: mundo firme por padrão, "amolecendo" quando a
// realidade quebra.
// psx_affine: 0 = correção de perspectiva normal; 1 = afim total (PS1); >1 exagera.
global uniform float psx_jitter;
global uniform float psx_affine;
// 0 = realidade firme; 1 = sonho / realidade quebrando (a estética crua do PS1).
global uniform float psx_dream;
// Multiplica snap_scale: grade de jitter mais grossa = vértices pulando mais.
global uniform float psx_snap;
// Perto da câmera o erro afim explode (polígono grande rente à câmera vira
// redemoinho). Com psx_dream baixo, o efeito some até affine_near, fica completo
// em affine_far (metros) e o desvio não passa de affine_max_error (em repetições
// da textura). Com psx_dream = 1 essas proteções somem: o redemoinho é proposital.
// Mesmo assim: modele superfícies grandes subdivididas (~0,5–1 m), como no PS1.
uniform float affine_near = 1.0;
uniform float affine_far = 3.5;
uniform float affine_max_error = 0.35;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;

// Quem inclui declara `varying vec2 affine_uv; varying float affine_w;` e os
// repassa (varyings só podem ser usados direto em vertex()/fragment()).
void psx_vertex(inout vec2 uv, vec3 vertex, vec3 normal, mat4 model, mat4 modelview,
		mat4 projection, vec2 viewport_size, out vec4 position, out vec2 a_uv, out float a_w) {
	if (world_uv) {
		vec3 wp = (model * vec4(vertex, 1.0)).xyz;
		vec3 wn = abs((model * vec4(normal, 0.0)).xyz);
		vec2 p = wn.x > wn.y && wn.x > wn.z ? wp.zy : (wn.y > wn.z ? wp.xz : wp.xy);
		// Imagem cresce para baixo; mundo, para cima.
		uv = vec2(p.x, -p.y) * tiles_per_meter;
	} else {
		uv *= uv_scale;
	}
	vec4 clip = projection * modelview * vec4(vertex, 1.0);
	vec3 ndc = clip.xyz / clip.w;
	vec2 grid = viewport_size * 0.5 / (snap_scale * psx_snap);
	ndc.xy = mix(ndc.xy, round(ndc.xy * grid) / grid, psx_jitter);
	position = vec4(ndc * clip.w, clip.w);

	// Interpolar uv*w e w com correção de perspectiva e dividir no fragment
	// resulta em interpolação linear na tela, ou seja, mapeamento afim.
	a_uv = uv * clip.w;
	a_w = clip.w;
}

vec4 psx_albedo(vec2 uv, vec2 a_uv, float a_w, float view_depth) {
	vec2 offset = a_uv / a_w - uv;
	float max_error = affine_max_error / max(1.0 - psx_dream, 0.001);
	offset /= max(1.0, length(offset) / max_error);
	float fade = mix(smoothstep(affine_near, affine_far, view_depth), 1.0, psx_dream);
	return texture(albedo_tex, uv + offset * psx_affine * fade) * albedo_color;
}
