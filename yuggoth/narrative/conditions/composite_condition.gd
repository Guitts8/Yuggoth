class_name CompositeCondition
extends Condition
## Combina condições com E (TODAS) ou OU (QUALQUER).

enum Mode { TODAS, QUALQUER }

@export var mode := Mode.TODAS
@export var conditions: Array[Condition] = []


func _evaluate() -> bool:
	if mode == Mode.TODAS:
		return conditions.all(func(c: Condition) -> bool: return c == null or c.is_met())
	return conditions.any(func(c: Condition) -> bool: return c != null and c.is_met())
