class_name MesaDoDia
extends Node
## As folhas na escrivaninha (playtest 9: "a principal folha do dia sempre deve
## ficar no meio e as outras próximas; as dos dias anteriores vão ficando nas
## extremidades"). A carta que acabou de chegar vai para o meio, sobre o
## mata-borrão; as outras do dia escorregam para os lugares em volta, da mais nova
## à mais velha. (As dos dias anteriores são cópias numa pilha no canto da mesa,
## feitas pelo gerador: `_mesa_do_dia`.)
##
## Uma folha está na mesa quando o dia é o dela e as ConditionalNode dela e dos
## pais (até `raiz`) valem. Decide-se em `GameState.value_changed`, que é síncrono:
## a folha recém-aberta já tem o lugar quando sai do envelope (Correspondencia
## lê o destino depois).

@export var raiz: Node
@export var folhas: Array[Node3D] = []
@export var dias: PackedInt32Array = []
## O meio e os lugares em volta, do mais perto ao mais longe (globais; o y é
## somado à altura original de cada folha).
@export var lugares: Array[Transform3D] = []
## A pilha da ponta da mesa (a base; cada folha sobe `PASSO`): as dos dias
## anteriores (cópias do gerador) e, quando o dia tem mais folhas que lugares, as
## mais velhas do dia, que deixam de se ler na mesa (relê-se pelo dossiê).
@export var pilha := Transform3D.IDENTITY

const PASSO := 0.0032

const ESCORREGAR := 0.6
## Espera antes de escorregar: mais que o voo de uma peça saindo do envelope.
const ESPERA := 1.0

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


## Põe cada folha do dia no seu lugar: a mais nova no meio.
func arrumar(animar: bool) -> void:
	var presentes: Array[Node3D] = []
	for i in folhas.size():
		if _presente(i):
			presentes.append(folhas[i])
	for f in _onde.keys():
		if f not in presentes:
			_onde.erase(f)
	var n := presentes.size()
	var hoje := int(GameState.get_value(&"dia", 1))
	var passadas := 0
	for d in dias:
		if d < hoje:
			passadas += 1
	for j in n:
		var f := presentes[n - 1 - j]
		var lugar := j
		var antes: int = _onde.get(f, -1)
		if antes == lugar:
			continue
		_onde[f] = lugar
		var pai := f.get_parent_node_3d()
		var alvo: Transform3D
		if lugar < lugares.size():
			alvo = pai.global_transform.affine_inverse() * lugares[lugar]
			alvo.origin.y = _y[f] + j * 0.0015
		else:
			# Para a pilha, por cima das dos dias anteriores (a mais velha no fundo).
			var na_pilha := pilha
			na_pilha.origin.y += (passadas + (n - 1 - j)) * PASSO
			alvo = pai.global_transform.affine_inverse() * na_pilha
			for area in f.find_children("*", "Interactable", true, false):
				(area as Interactable).visible = false
				(area as Interactable).collision_layer = 0
		if antes < 0 or not animar:
			f.transform = alvo
		else:
			# Primeiro a nova sai do envelope (e as que ainda voavam assentam); depois
			# as outras escorregam para o lado. No fim, o lugar certo, de todo jeito.
			var t := f.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.tween_interval(ESPERA)
			t.tween_property(f, ^"transform", alvo, ESCORREGAR)
			t.tween_callback(func() -> void:
				if _onde.get(f, -1) == lugar:
					f.transform = alvo)
