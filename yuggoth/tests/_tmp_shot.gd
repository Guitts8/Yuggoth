extends Node
## Descartável: a criatura cruzando o céu da cidade (Dia 3, depois do disco), em
## SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 3)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	esc.player.global_position = Vector3(0, 0, -1.4)
	esc.player.rotation = Vector3.ZERO
	esc.player.head.rotation.x = deg_to_rad(8)
	await _s(0.5)
	GameState.set_flag(&"tocou_disco")
	var t := 0.0
	for marca in [0.9, 1.5, 2.1, 2.7]:
		await _s(marca - t)
		t = marca
		_shot("%s_%.2f" % [tag, marca])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
