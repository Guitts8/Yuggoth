extends Node
## Descartável: prints do Dia 3 em SHOT_DIR.

var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 3)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	var player := esc.player
	player.global_position = Vector3(-0.1, 0, -1.3)
	player.rotation.y = 0
	player.head.rotation.x = deg_to_rad(-40)
	await _s(4.0)
	_shot("d3_mesa")
	player.global_position = Vector3(-0.6, 0, 1.1)
	player.rotation.y = deg_to_rad(125)
	player.head.rotation.x = deg_to_rad(-22)
	await _s(1.0)
	_shot("d3_canto")
	for montar: StateInteractable in esc.find_child("Caixote", true, false).find_children("Montar", "StateInteractable", true, false):
		montar.interact(player)
	esc.fonografo.interact(player)
	await _s(0.3)
	esc.fonografo.interact(player)
	await _s(24.5)
	_shot("d3_tocando")
	Events.document_requested.emit(load("res://narrative/documents/carta_akeley_2.tres"))
	await _s(0.6)
	var reader = root.get_node("UI/DocumentReader")
	reader._turn(1)
	await _s(0.3)
	_shot("d3_carta2")
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
