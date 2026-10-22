class_name Fosforo
extends Node3D
## Um fósforo de cozinha na mão (sem mãos: diante da câmera), riscado, levado a um
## pavio ou ao jornal sob a lenha, sacudido até apagar (playtest 7: a lareira do
## escritório; playtest 12: os lampiões da fazenda). `ir` vai de 0 (na mão) a 1 (no
## ponto `onde`, no mundo); a chama é um billboard com a luz dela.

## O fósforo na mão, no espaço da câmera.
const NA_MAO := Vector3(0.07, -0.08, -0.36)

var camera: Camera3D
var ir := 0.0
var onde := Vector3.ZERO
## O gesto de riscar e de sacudir (0 = parado).
var risco := 0.0
var aceso := false

var _luz: OmniLight3D
var _chama: MeshInstance3D
var _t := 0.0


## Um fósforo novo em `pai` (no mundo), seguindo `camera`.
static func novo(pai: Node, cam: Camera3D, chama: Texture2D) -> Fosforo:
	var f := Fosforo.new()
	f.name = "_Fosforo"
	f.camera = cam
	pai.add_child(f)
	f._montar(chama)
	f._seguir()
	return f


func _process(delta: float) -> void:
	_t += delta
	_seguir()
	if aceso and _luz:
		_luz.light_energy = 0.5 + 0.12 * sin(_t * 23.0) + 0.06 * sin(_t * 37.0)
		_chama.scale = Vector3.ONE * (1.0 + 0.15 * sin(_t * 19.0))


## Risca (vai e volta, rápido) e acende, com o som.
func riscar(som: AudioStream) -> void:
	if som:
		AudioDirector.play_sfx(som, -4.0)
	var t := create_tween()
	t.tween_method(func(k: float) -> void: risco = sin(k * PI), 0.0, 1.0, 0.18)
	await t.finished
	aceso = true
	_luz.visible = true
	_chama.visible = true
	# A cabeça do fósforo chameja e assenta.
	_chama.scale = Vector3.ONE * 1.8
	var c := create_tween()
	c.tween_property(_chama, ^"scale", Vector3.ONE, 0.35)


## Leva a chama até `ponto` (no mundo) em `segundos`; `false` a traz de volta.
func levar(ponto: Vector3, segundos: float) -> void:
	onde = ponto
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, ^"ir", 1.0, segundos)
	await t.finished


func trazer(segundos: float) -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, ^"ir", 0.0, segundos)
	await t.finished


## Sacode até apagar, e some.
func apagar_e_sumir() -> void:
	var s := create_tween()
	s.tween_method(func(k: float) -> void: risco = sin(k * TAU * 3.0) * 0.6, 0.0, 1.0, 0.45)
	await s.finished
	aceso = false
	_luz.visible = false
	_chama.visible = false
	risco = 0.0
	var f := create_tween()
	f.tween_property(self, ^"scale", Vector3.ONE * 0.01, 0.3)
	await f.finished
	queue_free()


## Entre a mão (diante da câmera) e o ponto no mundo, com o gesto.
func _seguir() -> void:
	if not is_instance_valid(camera):
		return
	var cam := camera.global_transform
	var mao := cam * (NA_MAO + Vector3(-0.05 * risco, 0.02 * risco, 0.0))
	var p := mao.lerp(onde, ir)
	# Inclinado, a cabeça para a frente e para cima.
	var frente := (-cam.basis.z).lerp((onde - mao).normalized() if onde != mao else -cam.basis.z, ir)
	var b := Basis.looking_at(frente.normalized() + Vector3.UP * 0.6, cam.basis.y)
	global_transform = Transform3D(b, p)


func _montar(chama: Texture2D) -> void:
	top_level = true
	var pau := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.004, 0.004, 0.05)
	pau.mesh = caixa
	pau.position = Vector3(0, 0, 0.025)
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.5, 0.42, 0.3)
	pau.material_override = madeira
	pau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pau)
	var ponta := MeshInstance3D.new()
	var bola := BoxMesh.new()
	bola.size = Vector3(0.006, 0.006, 0.008)
	ponta.mesh = bola
	var cabeca_mat := StandardMaterial3D.new()
	cabeca_mat.albedo_color = Color(0.35, 0.08, 0.05)
	ponta.material_override = cabeca_mat
	ponta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ponta)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.albedo_texture = chama
	var q := QuadMesh.new()
	q.size = Vector2(0.018, 0.034)
	q.center_offset = Vector3(0, 0.012, 0)
	q.material = mat
	_chama = MeshInstance3D.new()
	_chama.mesh = q
	_chama.position = Vector3(0, 0.002, -0.004)
	_chama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chama.visible = false
	add_child(_chama)
	_luz = OmniLight3D.new()
	_luz.light_color = Color(1.0, 0.62, 0.3)
	_luz.omni_range = 1.4
	_luz.light_energy = 0.5
	_luz.position = Vector3(0, 0.02, 0)
	_luz.visible = false
	add_child(_luz)
