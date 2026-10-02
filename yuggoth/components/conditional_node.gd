class_name ConditionalNode
extends Node
## Mostra o pai só quando a condição vale. Escondido, o pai também deixa de
## processar e sai da física (interações somem junto).
## Ex.: objetos que mudam entre os dias; a silhueta de uma discrepância.

@export var condition: Condition


func _ready() -> void:
	GameState.value_changed.connect(_refresh.unbind(2))
	_refresh()


func _refresh() -> void:
	var target := get_parent()
	var on := condition == null or condition.is_met()
	if "visible" in target:
		target.visible = on
	target.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
