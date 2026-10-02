class_name Condition
extends Resource
## Base das condições narrativas. Subclasses implementam _evaluate().
## Reaproveitada por variantes de documento, diálogo, narrador e gatilhos.

@export var negate := false


func is_met() -> bool:
	return _evaluate() != negate


func _evaluate() -> bool:
	return true
