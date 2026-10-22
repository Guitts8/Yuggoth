class_name PassarPorteira
extends Interactable
## Entrar no cercado dos cães, ou sair dele, pela porteira fechada (playtest 12,
## depois: "não consigo mais entrar para dentro do canil pois a porta está sendo
## fechada" — a porteira passou a barrar o corpo, e só a preparação a abria). Ele
## ergue o trinco, abre a porteira para dentro, passa, sai do arco dela e a fecha
## atrás de si; os cães não saem (a porteira fica aberta só uns segundos, e eles
## só saem pela `Matilha.porteira_aberta`, que é a da preparação).
##
## Duas áreas, uma de cada lado (`de_dentro`); cada uma só vale com Akeley do seu
## lado e a porteira fechada. De fora, quando a preparação pede para soltar os
## cães, cede o lugar à área dela.

@export var porteira: Node3D
@export var trinco: Node3D
@export var matilha: Matilha
## A área de soltar os cães (a preparação): ligada, esta, de fora, não vale.
@export var soltar: Interactable
@export var de_dentro := false
@export var som_trinco: AudioStream
@export var som_porteira: AudioStream

## O comprimento da porteira e o quanto abre para se passar (graus).
const COMPRIMENTO := 1.3
const ABRE := 85.0

var _ocupado := false
var _dobradica := Vector3.ZERO
var _ao_longo := Vector3.RIGHT
var _dentro := Vector3.FORWARD
## A porteira usada por qualquer um dos lados (as duas áreas dividem a porteira).
static var _em_uso := false


func _ready() -> void:
	super()
	prompt = "Sair do cercado" if de_dentro else "Entrar no cercado"
	if porteira:
		_dobradica = porteira.global_position
		var giro := porteira.rotation.y
		_ao_longo = (porteira.global_basis * Basis(Vector3.UP, -giro)).x
		_ao_longo.y = 0.0
		_ao_longo = _ao_longo.normalized()
		# Ela abre para dentro do cercado (o giro positivo).
		_dentro = Basis(Vector3.UP, PI / 2.0) * _ao_longo


func _process(_delta: float) -> void:
	var p := matilha.akeley() if matilha else null
	var vale := p != null and not _em_uso and not matilha.porteira_aberta \
		and matilha.no_cercado(p.global_position) == de_dentro \
		and (de_dentro or soltar == null or soltar.collision_layer == 0)
	collision_layer = LAYER_INTERACAO if vale else 0


func can_interact(by: Node) -> bool:
	return super(by) and not _em_uso and matilha != null and not matilha.porteira_aberta


func _exit_tree() -> void:
	if _ocupado:
		_em_uso = false


func _on_interact(by: Node) -> void:
	var p := by as Player
	if p == null or porteira == null:
		return
	_ocupado = true
	_em_uso = true
	p.input_enabled = false
	var y := p.global_position.y
	var no_chao := func(v: Vector3) -> Vector3: return Vector3(v.x, y, v.z)
	var meio: Vector3 = no_chao.call(_dobradica + _ao_longo * 0.85)
	# Do lado do trinco, fora do arco da porteira aberta (de dentro) ou diante dele
	# (de fora).
	var junto_dentro: Vector3 = no_chao.call(_dobradica + _ao_longo * 1.5 + _dentro * 0.75)
	var junto_fora: Vector3 = no_chao.call(_dobradica + _ao_longo * 1.15 - _dentro * 0.75)
	var meio_porteira := _dobradica + _ao_longo * 0.65 + Vector3.UP * 0.7
	var t_pos := trinco.global_position if trinco else meio_porteira
	await p.conduzir([junto_dentro if de_dentro else junto_fora], t_pos)
	if not is_inside_tree():
		return
	# Ergue o trinco, e a porteira vai para dentro.
	await _trinco(true)
	_tocar(som_porteira, -8.0)
	var abre := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	abre.tween_property(porteira, ^"rotation_degrees:y", ABRE, 1.0)
	await _esperar(0.35)
	_trinco(false)
	if abre.is_running():
		await abre.finished
	if not is_inside_tree():
		return
	# Passa pelo vão; de dentro para fora, fica do lado de fora; de fora para
	# dentro, sai do arco da porteira (ela varre o cercado ao fechar).
	var passagem_fora := meio - _dentro * 0.6
	var passagem_dentro := meio + _dentro * 0.6
	if de_dentro:
		await p.conduzir([passagem_dentro, passagem_fora], passagem_fora - _dentro * 2.0)
	else:
		await p.conduzir([passagem_fora, passagem_dentro, junto_dentro], junto_dentro + _dentro * 2.0)
	if not is_inside_tree():
		return
	# Vira-se e a fecha atrás de si; o trinco cai no batente.
	await p.olhar_para(_dobradica + _ao_longo * 0.6 + _dentro * 0.5 + Vector3.UP * 0.6, 0.5).finished
	var fecha := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fecha.tween_property(porteira, ^"rotation_degrees:y", 0.0, 0.9)
	await fecha.finished
	_tocar(som_trinco, -6.0)
	var repica := create_tween().set_trans(Tween.TRANS_SINE)
	repica.tween_property(porteira, ^"rotation_degrees:y", 3.0, 0.07)
	repica.tween_property(porteira, ^"rotation_degrees:y", 0.0, 0.1)
	await repica.finished
	if not is_inside_tree():
		return
	_ocupado = false
	_em_uso = false
	p.input_enabled = true


func _trinco(erguido: bool) -> void:
	if trinco == null:
		return
	if erguido:
		_tocar(som_trinco, -9.0)
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(trinco, ^"rotation:z", deg_to_rad(65.0) if erguido else 0.0, 0.25)
	await t.finished


func _tocar(s: AudioStream, db: float) -> void:
	if s:
		AudioDirector.play_sfx(s, db)


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout
