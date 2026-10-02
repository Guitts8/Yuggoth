class_name Examinable
extends Interactable
## Objeto que o jogador pega para girar e aproximar: fotografias, a pedra, o disco.
## Uma cópia do visual aparece no ExamineViewer; o original fica na cena.
## Detalhes escondidos são ExamineHotspot filhos do visual (GDD §10.4).

@export var title := ""
@export_multiline var description := ""
## Nó mostrado no visualizador. Vazio = o pai.
@export var visual: Node3D
## Orientação inicial no visualizador, em graus (ex.: 90,0,0 põe uma foto deitada de pé).
@export var initial_rotation := Vector3.ZERO
@export_group("Primeira vez")
## Marcada ao examinar pela primeira vez (vazio = nada é marcado).
@export var flag: StringName
## Somado a `exposicao` na primeira vez (precisa de `flag`).
@export_range(0.0, 1.0, 0.01) var exposure := 0.0


func get_visual() -> Node3D:
	return visual if visual else get_parent() as Node3D


func _on_interact(_by: Node) -> void:
	if not flag.is_empty() and not GameState.has_flag(flag):
		GameState.set_flag(flag)
		GameState.add(&"exposicao", exposure)
	Events.examine_requested.emit(self)
