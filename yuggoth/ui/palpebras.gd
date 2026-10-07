class_name Palpebras
extends CanvasLayer
## As pálpebras pesando (o sono à mesa, docs/PLANO_ESCRITORIO.md, "A passagem
## para o sonho"): sombras curvas que fecham de cima e de baixo, sem chegar à
## tela preta do fade. `await fechar(0..1, segundos)`; quem usa a põe na fase
## e a libera. Montada em código.

const SHADER := "shader_type canvas_item;
uniform float fechado : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// A fresta é mais alta no meio que nos cantos, como um olho.
	float abertura = (1.0 - fechado) * (1.3 - 0.5 * p.x * p.x);
	float borda = 0.15 + 0.3 * (1.0 - fechado);
	float a = smoothstep(abertura - borda, abertura + 0.02, abs(p.y));
	COLOR = vec4(0.0, 0.0, 0.0, max(a, smoothstep(0.8, 1.0, fechado)));
}"

## 0 = olhos abertos, 1 = fechados.
var fechado := 0.0:
	set(v):
		fechado = v
		(_rect.material as ShaderMaterial).set_shader_parameter(&"fechado", v)

var _rect: ColorRect


func _init() -> void:
	# Acima do mundo e da UI, abaixo da tinta (90) e do fade.
	layer = 50
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_rect.material = mat
	add_child(_rect)


func fechar(ate: float, segundos: float) -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, ^"fechado", ate, segundos)
	await t.finished
