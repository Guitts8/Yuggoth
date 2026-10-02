class_name ValueCondition
extends Condition
## Compara um valor de GameState com uma constante.
## Flags booleanas contam como 1.0 (ligada) ou 0.0 (desligada).

enum Op { IGUAL, DIFERENTE, MAIOR, MAIOR_OU_IGUAL, MENOR, MENOR_OU_IGUAL }

@export var key: StringName
@export var op := Op.MAIOR_OU_IGUAL
@export var value := 1.0


func _evaluate() -> bool:
	var current := GameState.get_number(key)
	match op:
		Op.IGUAL:
			return is_equal_approx(current, value)
		Op.DIFERENTE:
			return not is_equal_approx(current, value)
		Op.MAIOR:
			return current > value
		Op.MAIOR_OU_IGUAL:
			return current >= value
		Op.MENOR:
			return current < value
		Op.MENOR_OU_IGUAL:
			return current <= value
	return false
