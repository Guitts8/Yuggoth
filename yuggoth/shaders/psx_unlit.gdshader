// Material PSX sem iluminação: paisagens atrás de janelas, mostradores, brilhos.
// Ver psx_common.gdshaderinc.
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;

#include "res://shaders/psx_common.gdshaderinc"

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
}
