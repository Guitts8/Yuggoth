extends Node
## Descartável: a vinheta de Boston e a volta ao escritório de noite, em
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
	GameState.set_value(&"dia", 4)
	GameState.set_flag(&"tocou_disco")
	await SceneDirector.change_level("res://levels/boston/boston.tscn", &"Entrada")
	await _s(2.5)
	var boston: Boston = root.find_child("Boston", true, false)
	_shot("%s_entrada" % tag)
	var player := boston.player
	player.global_position = Vector3(-0.2, 0, 0.2)
	player.look_at(Vector3(1.05, 0, -1.15))
	player.head.rotation.x = deg_to_rad(-12)
	await _s(0.8)
	_shot("%s_rapaz" % tag)
	var rapaz: Interlocutor = boston.get_node("%Conversa")
	rapaz.interact(player)
	while rapaz.em_conversa():
		await _s(0.2)
	rapaz.interact(player)
	await _s(5.5)
	_shot("%s_voz" % tag)
	while rapaz.em_conversa():
		await _s(0.2)
	GameState.set_flag(&"voltou_de_boston")
	GameState.set_flag(&"anoiteceu_dia_4")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta")
	await _s(2.0)
	_shot("%s_volta" % tag)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
