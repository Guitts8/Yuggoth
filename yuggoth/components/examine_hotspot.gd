class_name ExamineHotspot
extends Marker3D
## Detalhe que só se nota de perto num objeto examinado (ex.: a forma na pegada).
## Encontrado quando fica perto do centro da tela, virado para a câmera, com zoom
## suficiente, por DWELL_TIME segundos. A face do detalhe aponta para -Z local.

@export var flag: StringName
@export_multiline var text := ""
## Só pode ser encontrado se a condição valer (ex.: estar com a lupa).
@export var condition: Condition
@export_range(0.0, 1.0, 0.05) var min_zoom := 0.6
## Somado a `exposicao` ao encontrar.
@export_range(0.0, 1.0, 0.01) var exposure := 0.0


func is_available() -> bool:
	return condition == null or condition.is_met()
