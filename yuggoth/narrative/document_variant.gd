class_name DocumentVariant
extends Resource
## Versão alternativa de um documento, ativa quando a condição é satisfeita.

@export var condition: Condition
@export_multiline var pages: PackedStringArray = []
