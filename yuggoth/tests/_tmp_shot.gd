extends Node
## Descartável: a Selagem na mesa (Dia 3, noite), quadro a quadro, em SHOT_DIR,
## com prefixo SHOT_TAG.

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
	GameState.set_flag(&"tocou_disco")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	esc.player.global_position = Vector3(0.1, 0, -1.35)
	esc.player.rotation.y = 0
	esc.player.head.rotation.x = deg_to_rad(-20)
	var writer = root.get_node("UI/ReplyWriter")
	var reply: ReplyData = load("res://narrative/replies/resposta_dia_3.tres")
	writer.open(reply)
	await _s(0.3)
	writer._choose(reply.options[1])
	writer._finish_writing()
	writer._seal()
	var t := 0.0
	for marca in [1.0, 2.6, 3.9, 5.2, 6.6, 8.0, 9.4, 10.6, 11.9, 13.5]:
		await _s(marca - t)
		t = marca
		_shot("%s_%05.1f" % [tag, marca])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
