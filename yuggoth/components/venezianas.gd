class_name Venezianas
extends Interactable
## As venezianas de uma janela da casa de Akeley (docs/PLANO_FAZENDA.md, F6): de
## dentro, ele se debruça, puxa as duas folhas e passa a tranca. As folhas são os
## nós `VenezianaA`/`VenezianaB` do gerador (`_janela`), com a meta `aberta` (o
## giro, em graus, contra a parede). Na noite do telhado (F7), `fresta()` as abre
## um palmo para a janela servir de seteira.

signal fechou

@export var folhas: Array[Node3D] = []
@export var som: AudioStream
## Quanto abre a fresta (graus).
@export var fresta_graus := 20.0

var fechada := false
var _base: Array[Basis] = []
var _aberta: Array[float] = []


func _ready() -> void:
	super()
	prompt = "Fechar as venezianas"
	for f in folhas:
		var a: float = f.get_meta(&"aberta", 170.0)
		_aberta.append(a)
		_base.append(f.basis * Basis(Vector3.UP, deg_to_rad(-a)))


func can_interact(by: Node) -> bool:
	return super(by) and not fechada


func _on_interact(by: Node) -> void:
	var p := by as Player
	fechada = true
	if p:
		p.input_enabled = false
		await p.olhar_para(global_position, 0.5).finished
	if som:
		AudioDirector.play_sfx(som, -4.0)
	await _girar(0.0, 0.9)
	if p and is_instance_valid(p):
		p.input_enabled = true
	fechou.emit()


## Fecha de uma vez, sem animar (pular, testes).
func fechar_ja() -> void:
	fechada = true
	for i in folhas.size():
		_pose(i, 0.0)


## Entreabre (a seteira da noite do telhado; `graus` < 0 = `fresta_graus`) ou
## volta a fechar.
func fresta(abrir: bool, graus := -1.0) -> void:
	if abrir and som:
		AudioDirector.play_sfx(som, -10.0)
	await _girar((fresta_graus if graus < 0.0 else graus) if abrir else 0.0, 0.4)


func _girar(alvo: float, segundos: float) -> void:
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	for i in folhas.size():
		var de := _angulo(i)
		var ate := alvo * signf(_aberta[i])
		t.tween_method(func(a: float) -> void: _pose_graus(i, a), de, ate, segundos)
	await t.finished


func _angulo(i: int) -> float:
	var rel := _base[i].inverse() * folhas[i].basis
	return rad_to_deg(rel.get_euler().y)


func _pose(i: int, fracao: float) -> void:
	_pose_graus(i, _aberta[i] * fracao)


func _pose_graus(i: int, graus: float) -> void:
	folhas[i].basis = _base[i] * Basis(Vector3.UP, deg_to_rad(graus))
