extends Node
## Descartável: prints do Dia 4 em SHOT_DIR.

var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 4)
	GameState.set_flag(&"tocou_disco")
	GameState.set_flag(&"leu_telegrama_pedra")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	var player := esc.player
	player.global_position = Vector3(1.4, 0, -1.9)
	player.rotation.y = deg_to_rad(-75)
	player.head.rotation.x = deg_to_rad(-5)
	await _s(9.0)
	var tel: Telefone = esc.find_child("Telefone", true, false)
	GameState.set_flag(&"ligou_agencia_arkham")
	GameState.set_flag(&"ligou_boston")
	tel.interact(player)
	await _s(5.5)
	_shot("d4_telefone")
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
