// Material PSX iluminado por pixel, com facetas: cada polígono recebe a normal
// da própria face, então o low-poly aparece na luz (e as sombras funcionam).
// Ver psx_common.gdshaderinc.
shader_type spatial;
render_mode specular_disabled, cull_back;

#include "res://shaders/psx_common.gdshaderinc"

// Normal da face (derivadas da posição) em vez da normal suavizada do modelo.
uniform bool facetado = true;

varying vec2 affine_uv;
varying float affine_w;

void vertex() {
	vec4 pos;
	vec2 a_uv;
	float a_w;
	psx_vertex(UV, VERTEX, NORMAL, MODEL_MATRIX, MODELVIEW_MATRIX, PROJECTION_MATRIX, VIEWPORT_SIZE, pos, a_uv, a_w);
	POSITION = pos;
	affine_uv = a_uv;
	affine_w = a_w;
}

void fragment() {
	vec4 tex = psx_albedo(UV, affine_uv, affine_w, -VERTEX.z);
	if (tex.a < alpha_cut) {
		discard;
	}
	ALBEDO = tex.rgb;
	if (facetado) {
		NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	}
}
