class_name Rastro
extends Node3D
## Marcas que se formam sozinhas (docs/PLANO_ESCRITORIO.md, Fase 3f: o sonho da
## noite 2, "mais sinistro... talvez se formando"): enquanto o grupo está à vista,
## os filhos aparecem um a um, na ordem, cada um crescendo do centro, com um
## estalo úmido no lugar dele — ouvido também pelas costas. Sem susto: devagar,
## e nada salta.

## Segundos até a primeira, e entre uma e outra.
@export var espera := 5.0
@export var intervalo := 3.2
@export var som: AudioStream

var _marcas: Array[Node3D] = []
var _t := 0.0
var _feitas := 0
var _som: AudioStreamPlayer3D


func _ready() -> void:
	for n in get_children():
		if n is Node3D:
			_marcas.append(n)
	_som = AudioStreamPlayer3D.new()
	_som.name = "_Som"
	_som.bus = &"SFX"
	_som.unit_size = 1.5
	_som.volume_db = -6.0
	_som.stream = som
	add_child(_som)
	_zerar()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		if _feitas > 0 or _t > 0.0:
			_zerar()
		return
	_t += delta
	if _feitas < _marcas.size() and _t >= espera + _feitas * intervalo:
		_formar(_marcas[_feitas])
		_feitas += 1


func _zerar() -> void:
	_t = 0.0
	_feitas = 0
	for m in _marcas:
		m.visible = false


func _formar(m: Node3D) -> void:
	var tam := m.scale
	m.scale = tam * 0.25
	m.visible = true
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) \
		.tween_property(m, ^"scale", tam, 0.9)
	if som:
		_som.global_position = m.global_position
		_som.pitch_scale = randf_range(0.85, 1.1)
		_som.play()
