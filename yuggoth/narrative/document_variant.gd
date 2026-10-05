class_name DocumentVariant
extends Resource
## Versão alternativa de um documento, ativa quando a condição é satisfeita.

@export var condition: Condition
@export_multiline var pages: PackedStringArray = []
## Com id, a primeira vez que esta versão é lida marca `leu_<id>` e soma
## `exposure_on_read` (GDD §6.3: reler um documento alterado expõe).
@export var id: StringName
@export_range(0.0, 1.0, 0.01) var exposure_on_read := 0.0


func get_read_flag() -> StringName:
	return StringName("leu_%s" % id) if id else &""
