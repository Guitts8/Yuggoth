class_name Estranheza
extends Node
## Uma estranheza sutil (docs/PLANO_ESCRITORIO.md, Fase 6): uma vez, sem som, sem
## fala, algo da sala fica diferente — o cilindro fora da máquina, o relógio parado
## noutra hora, uma fotografia virada para baixo. Só com `exposicao` acima do
## `limiar` (quem leu e olhou menos, vê menos), e só quando ninguém está olhando:
## os `alvos` passam às `transformacoes` (locais) depois de `intervalo` segundos
## fora da vista. Feito, marca `flag`. Quando a `condition` deixa de valer (o dia
## acabou), tudo volta ao lugar; usar `desfazer_com` (o fonógrafo) também põe de
## volta — e não acontece mais.

@export var condition: Condition
@export_range(0.0, 1.0, 0.01) var limiar := 0.5
@export var flag: StringName
@export var alvos: Array[Node3D] = []
@export var transformacoes: Array[Transform3D] = []
@export var desfazer_com: Interactable
@export var intervalo := 2.5
## Ângulo (graus) a partir do centro da tela dentro do qual conta como visto.
@export var angulo_visto := 60.0

var _originais: Array[Transform3D] = []
var _aplicada := false
var _fora := 0.0


func _ready() -> void:
	for a in alvos:
		_originais.append(a.transform)
	if desfazer_com:
		desfazer_com.interacted.connect(func(_by: Node) -> void:
			if _aplicada:
				_voltar()
				GameState.set_flag(_flag_desfeita()))


func _flag_desfeita() -> StringName:
	return StringName("%s_desfeita" % flag)


func _process(delta: float) -> void:
	var vale := condition == null or condition.is_met()
	if _aplicada:
		if not vale:
			_voltar()
		return
	if not vale or GameState.has_flag(_flag_desfeita()):
		return
	# Já aconteceu (uma volta da fase no mesmo dia): está como estava.
	if GameState.has_flag(flag):
		_aplicar()
		return
	if GameState.get_number(&"exposicao") < limiar:
		return
	if _visto():
		_fora = 0.0
		return
	_fora += delta
	if _fora >= intervalo:
		_aplicar()
		GameState.set_flag(flag)


func _aplicar() -> void:
	for i in alvos.size():
		alvos[i].transform = transformacoes[i]
	_aplicada = true


func _voltar() -> void:
	for i in alvos.size():
		alvos[i].transform = _originais[i]
	_aplicada = false
	_fora = 0.0


## Algum alvo à vista: perto do centro da tela e sem parede no meio.
func _visto() -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var espaco := cam.get_world_3d().direct_space_state
	for a in alvos:
		var para := a.global_position - cam.global_position
		if rad_to_deg(para.angle_to(-cam.global_basis.z)) > angulo_visto:
			continue
		var raio := PhysicsRayQueryParameters3D.create(cam.global_position, a.global_position, 1)
		var bateu := espaco.intersect_ray(raio)
		if bateu.is_empty() or (bateu.position as Vector3).distance_to(a.global_position) < 0.3:
			return true
	return false
