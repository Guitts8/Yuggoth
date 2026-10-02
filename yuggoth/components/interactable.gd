class_name Interactable
extends Area3D
## Algo que o jogador pode mirar e usar. Detectado pelo InteractRay do Player
## na camada de física 2 ("interacao"). Subclasses sobrescrevem _on_interact().

signal interacted(by: Node)

const LAYER_INTERACAO := 1 << 1

@export var prompt := "Examinar"
@export var enabled := true
## Desliga após o primeiro uso.
@export var once := false
## Só aparece quando vale (ex.: ter lido a carta do dia). Vazio = sempre.
@export var condition: Condition


func _ready() -> void:
	collision_layer = LAYER_INTERACAO
	collision_mask = 0
	monitoring = false


func can_interact(_by: Node) -> bool:
	return enabled and (condition == null or condition.is_met())


func interact(by: Node) -> void:
	if not can_interact(by):
		return
	interacted.emit(by)
	_on_interact(by)
	if once:
		enabled = false


func _on_interact(_by: Node) -> void:
	pass
