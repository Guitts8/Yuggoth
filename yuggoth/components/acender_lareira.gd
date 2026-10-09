class_name AcenderLareira
extends StateInteractable
## "Acender a lareira" (playtest 7: "uma animação para acender o fogo"):
## Wilmarth vai até a lareira, ajoelha-se diante da lenha, risca um fósforo — a
## chama pequena na mão, a luz dela no rosto da lareira —, leva-o ao jornal sob
## as toras, e o fogo pega no meio e se espalha (`Fogo.intensidade`); ele sacode
## o fósforo, olha o fogo crescer um pouco e se levanta. As `changes` (a flag
## `lareira_dia_N`) entram quando o fósforo encosta no jornal.
## A cabeça continua livre o tempo todo (o mouse olha).

## Onde ele se ajoelha e a lenha (no espaço do pai, como as posições do gerador).
@export var ajoelhar := Vector3.ZERO
@export var lenha := Vector3.ZERO
## O fogo que pega (num grupo que aparece com a flag).
@export var fogo: Fogo
## O fósforo riscado (o `som` da StateInteractable fica para quem não anima).
@export var som_riscar: AudioStream
@export var chama: Texture2D

## Quanto tempo o fogo leva de pegar até inteiro.
const PEGAR := 6.0
## Ajoelhado, quanto os olhos descem.
const AJOELHADO := 0.9
## O fósforo na mão, no espaço da câmera.
const NA_MAO := Vector3(0.05, -0.05, -0.2)

var _acendendo := false
var _fosforo: Node3D
var _luz: OmniLight3D
var _cabeca: Node3D
var _riscado := false
var _t := 0.0
## 0 = na mão (segue a câmera); 1 = no ponto `_onde` (no mundo).
var _ir := 0.0
var _onde := Vector3.ZERO
var _player: Player


func can_interact(by: Node) -> bool:
	return not _acendendo and super(by)


func _on_interact(by: Node) -> void:
	var player := by as Player
	if player == null or not is_inside_tree():
		_acender()
		return
	_acendendo = true
	_player = player
	player.input_enabled = false
	var pai := get_parent_node_3d().global_transform
	var joelho := pai * ajoelhar
	var alvo := pai * lenha
	await player.conduzir([joelho], alvo, 0.9)
	if not is_inside_tree():
		return

	# Ajoelha-se: a cabeça desce (devagar, o Player a leva), os olhos na lenha.
	player.abaixar = AJOELHADO
	# Os olhos um pouco acima da lenha: a boca da lareira inteira, não o chão.
	await player.olhar_para(alvo + Vector3.UP * 0.22, 1.0, joelho).finished
	if not is_inside_tree():
		return

	# O fósforo aparece na mão e é riscado (vai e volta, rápido).
	_montar_fosforo()
	_seguir()
	await _esperar(0.5)
	if som_riscar:
		AudioDirector.play_sfx(som_riscar, -4.0)
	elif som:
		AudioDirector.play_sfx(som, -4.0)
	var risco := create_tween()
	risco.tween_method(func(k: float) -> void: _fosforo.set_meta(&"risco", sin(k * PI)), 0.0, 1.0, 0.18)
	await risco.finished
	_riscado = true
	_luz.visible = true
	_cabeca.visible = true
	await _esperar(0.9)
	if not is_inside_tree():
		return

	# Leva a chama ao jornal sob as toras.
	_onde = alvo + Vector3(-0.1, -0.06, 0.04)
	var levar := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	levar.tween_property(self, ^"_ir", 1.0, 1.1)
	await levar.finished
	await _esperar(0.5)
	if not is_inside_tree():
		return

	# Pega: o fogo nasce no meio e cresce.
	if fogo:
		fogo.intensidade = 0.04
	_acender()
	var pegar := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if fogo:
		pegar.tween_property(fogo, ^"intensidade", 1.0, PEGAR)
	await _esperar(0.6)
	# O fósforo volta para a mão e é sacudido até apagar.
	var voltar := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	voltar.tween_property(self, ^"_ir", 0.0, 0.6)
	await voltar.finished
	var sacudir := create_tween()
	sacudir.tween_method(func(k: float) -> void: _fosforo.set_meta(&"risco", sin(k * TAU * 3.0) * 0.6), 0.0, 1.0, 0.45)
	await sacudir.finished
	_riscado = false
	_luz.visible = false
	_cabeca.visible = false
	var sumir := create_tween()
	sumir.tween_property(_fosforo, ^"scale", Vector3.ONE * 0.01, 0.3)
	await sumir.finished
	_fosforo.queue_free()
	_fosforo = null

	# Olha o fogo pegar um pouco e se levanta.
	await _esperar(1.6)
	if not is_inside_tree():
		return
	player.abaixar = 0.0
	await _esperar(0.6)
	player.input_enabled = true
	_acendendo = false


## As `changes` (a flag que mostra o fogo), sem o som (o fósforo já tocou).
func _acender() -> void:
	var s := som
	som = null
	super._on_interact(_player)
	som = s


func _process(delta: float) -> void:
	_t += delta
	if _fosforo:
		_seguir()
	if _riscado and _luz:
		_luz.light_energy = 0.5 + 0.12 * sin(_t * 23.0) + 0.06 * sin(_t * 37.0)
		_cabeca.scale = Vector3.ONE * (1.0 + 0.15 * sin(_t * 19.0))


## O fósforo entre a mão (diante da câmera) e o ponto no mundo, com o risco.
func _seguir() -> void:
	if _player == null:
		return
	var cam := _player.camera.global_transform
	var risco: float = _fosforo.get_meta(&"risco", 0.0)
	var mao := cam * (NA_MAO + Vector3(-0.05 * risco, 0.02 * risco, 0.0))
	var p := mao.lerp(_onde, _ir)
	# Inclinado, a cabeça para a frente e para cima.
	var frente := (-cam.basis.z).lerp((_onde - mao).normalized() if _onde != mao else -cam.basis.z, _ir)
	var b := Basis.looking_at(frente.normalized() + Vector3.UP * 0.6, cam.basis.y)
	_fosforo.global_transform = Transform3D(b, p)


func _montar_fosforo() -> void:
	_fosforo = Node3D.new()
	_fosforo.name = "_Fosforo"
	get_parent().add_child(_fosforo)
	var pau := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.004, 0.004, 0.05)
	pau.mesh = caixa
	pau.position = Vector3(0, 0, 0.025)
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.78, 0.66, 0.45)
	pau.material_override = madeira
	_fosforo.add_child(pau)
	var ponta := MeshInstance3D.new()
	var bola := BoxMesh.new()
	bola.size = Vector3(0.006, 0.006, 0.008)
	ponta.mesh = bola
	var cabeca_mat := StandardMaterial3D.new()
	cabeca_mat.albedo_color = Color(0.35, 0.08, 0.05)
	ponta.material_override = cabeca_mat
	_fosforo.add_child(ponta)
	# A chama: um billboard pequeno na ponta, e a luz dela.
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
	_cabeca = MeshInstance3D.new()
	_cabeca.mesh = q
	_cabeca.position = Vector3(0, 0.002, -0.004)
	_cabeca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cabeca.visible = false
	_fosforo.add_child(_cabeca)
	_luz = OmniLight3D.new()
	_luz.light_color = Color(1.0, 0.62, 0.3)
	_luz.omni_range = 1.4
	_luz.light_energy = 0.5
	_luz.position = Vector3(0, 0.02, 0)
	_luz.visible = false
	_fosforo.add_child(_luz)


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


func _exit_tree() -> void:
	if _acendendo and is_instance_valid(_player):
		_player.abaixar = 0.0
	if _fosforo:
		_fosforo.queue_free()
		_fosforo = null
