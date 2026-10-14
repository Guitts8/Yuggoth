class_name MesaDoDia
extends Node
## As folhas na escrivaninha (playtest 9: "a principal folha do dia sempre deve
## ficar no meio e as outras próximas; as dos dias anteriores vão ficando nas
## extremidades"). As do dia em leque sobre o mata-borrão, a mais nova por cima
## (playtest 11: sem escorregar sozinhas; `arrumar`). As dos dias anteriores são
## cópias numa pilha no canto da mesa, feitas pelo gerador (`_mesa_do_dia`).
##
## Uma folha está na mesa quando o dia é o dela e as ConditionalNode dela e dos
## pais (até `raiz`) valem. Decide-se em `GameState.value_changed`, que é síncrono:
## a folha recém-aberta já tem o lugar quando sai do envelope (Correspondencia
## lê o destino depois).

@export var raiz: Node
@export var folhas: Array[Node3D] = []
@export var dias: PackedInt32Array = []
## A base do leque é o primeiro (global; o y é somado à altura original de cada
## folha).
@export var lugares: Array[Transform3D] = []
## A pilha da ponta da mesa, das cópias dos dias anteriores (do gerador).
@export var pilha := Transform3D.IDENTITY

## O leque: quantas folhas antes de recomeçar, o passo de uma para a outra (x, z;
## metros) e o giro de cada uma (graus).
const LEQUE := 4
const PASSO_LEQUE := Vector2(0.085, 0.035)
const GIRO_LEQUE: Array[float] = [0.0, -4.0, 2.5, -6.0]

var _onde: Dictionary[Node3D, int] = {}
var _y: Dictionary[Node3D, float] = {}


func _ready() -> void:
	for f in folhas:
		_y[f] = f.position.y
	GameState.value_changed.connect(func(_k: StringName, _v: Variant) -> void: arrumar(true))
	arrumar.call_deferred(false)


func _presente(i: int) -> bool:
	if int(GameState.get_value(&"dia", 1)) != dias[i]:
		return false
	var n: Node = folhas[i]
	while n and n != raiz:
		for c in n.get_children():
			if c is ConditionalNode and (c as ConditionalNode).condition and not (c as ConditionalNode).condition.is_met():
				return false
		n = n.get_parent()
	return true


## Põe cada folha do dia no seu lugar do leque, pela ordem de chegada.
##
## Playtest 11 ("um pouco incômodo a forma como fizemos essas arrumações de
## folha"): as folhas do dia escorregavam sozinhas pela mesa a cada carta nova. Agora
## nenhuma se mexe sozinha: a que chega pousa por cima, um pouco à frente e à direita
## da anterior, como quem vai deixando as cartas lidas umas sobre as outras — a mais
## nova inteira à vista, das outras o alto e a margem (e cada uma se lê pelo pedaço
## que aparece). Passado `LEQUE`, recomeça no alto, por cima.
func arrumar(animar: bool) -> void:
	var presentes: Array[Node3D] = []
	for i in folhas.size():
		if _presente(i):
			presentes.append(folhas[i])
	for f in _onde.keys():
		if f not in presentes:
			_onde.erase(f)
	for j in presentes.size():
		var f := presentes[j]
		var antes: int = _onde.get(f, -1)
		if antes == j:
			continue
		_onde[f] = j
		var pai := f.get_parent_node_3d()
		var alvo := pai.global_transform.affine_inverse() * _no_leque(j)
		alvo.origin.y = _y[f] + j * 0.0015
		if antes < 0 or not animar:
			f.transform = alvo
		else:
			# Só se a ordem do dia mudar (raro): vai à mão, sem pressa.
			var t := f.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.tween_property(f, ^"transform", alvo, 0.6)


## O lugar `j` do leque (global): a base é `lugares[0]`; cada folha seguinte um
## pouco à frente e à direita, girando de leve.
func _no_leque(j: int) -> Transform3D:
	var k := j % LEQUE
	var base: Transform3D = lugares[0] if not lugares.is_empty() else Transform3D.IDENTITY
	var t := base
	t.origin += Vector3(PASSO_LEQUE.x * k, 0.0, PASSO_LEQUE.y * k)
	t.basis = Basis(Vector3.UP, deg_to_rad(GIRO_LEQUE[k])) * base.basis
	return t
