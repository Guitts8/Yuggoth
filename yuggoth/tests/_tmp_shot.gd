extends Node
## Descartável: o lapso na sala (Dia 6, 31 de agosto a 5 de setembro), em
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
	GameState.set_value(&"dia", 6)
	GameState.set_value(&"data", Lapso.dia_do_ano(8, 31))
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	esc.player.global_position = Vector3(0.1, 0, -1.4)
	esc.player.look_at(Vector3(0.4, 0, -3.0))
	esc.player.head.rotation.x = deg_to_rad(-12)
	await _s(1.0)
	_shot("%s_0" % tag)
	esc.passar_tempo(load("res://narrative/narration/cartao_5_setembro.tres"))
	var t := 0.0
	for marca in [0.5, 0.9, 1.35, 2.0, 4.5, 7.4]:
		await _s(marca - t)
		t = marca
		_shot("%s_%.2f" % [tag, marca])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
