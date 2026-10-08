class_name LugarSono
extends Interactable
## Onde Wilmarth adormece numa noite de sonho longe do diário (docs/PLANO_ESCRITORIO.md,
## Fase 3d) 💭 — para não dormir sempre escrevendo. Anotado o dia (sem a letra
## falhar), o Escritorio põe `sono` = a noite e diz `linha`; esta área aparece
## (a `condition` é `sono == noite`) — "Ouvir o disco outra vez", "Sentar diante
## do fogo". Usada, o Escritorio o leva ao `assento` (o -Z do marcador é para
## onde o corpo fica virado), ele olha `olhar`, faz o que o lugar pede (tocar o
## disco, um gole) e o sono vem; acorda ali de manhã.

@export var noite := 0
@export var assento: Marker3D
@export var olhar: Marker3D
## Dita ao fechar o diário, nesta noite: o que ele ainda quer fazer.
@export var linha: NarrationLine
## Tocar este fonógrafo ao sentar (a noite do disco).
@export var fonografo: Fonografo
## Beber deste copo ao sentar (Bebida.gole).
@export var copo: Node3D


func _ready() -> void:
	super()
	add_to_group(&"lugar_sono")
	GameState.value_changed.connect(_atualizar.unbind(2))
	_atualizar()


## Fora da noite dele, sai da física: a área é maior que o fonógrafo (ou a
## poltrona) em que está, para ganhar a mira, e não pode tampá-lo de dia.
func _atualizar() -> void:
	var vale := can_interact(null)
	visible = vale
	for c: CollisionShape3D in find_children("*", "CollisionShape3D", false, false):
		c.set_deferred(&"disabled", not vale)
