class_name Respira
extends Node3D
## O que respira (docs/PLANO_ESCRITORIO.md, Fase 3f: o sonho do disco, "as
## árvores respirando"): o nó incha e murcha devagar em volta da própria base —
## largo, mais do que alto, como um peito. Só enquanto está à vista.

## Quanto alarga no fôlego cheio (fração), e fôlegos por minuto.
@export var amplitude := 0.07
@export var por_minuto := 11.0
## Em fôlegos (0..1): as árvores juntas, mas não em uníssono perfeito.
@export var fase := 0.0

var _t := 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	var s := sin((_t * por_minuto / 60.0 + fase) * TAU)
	# Inspira devagar, solta mais depressa: a curva pende para o cheio.
	var k := (s + 1.0) * 0.5
	k = k * k
	scale = Vector3(1.0 + amplitude * k, 1.0 + amplitude * 0.25 * k, 1.0 + amplitude * k)
