extends Node
## Descartável: a animação de selar e a carta na mão (Dia 1) em SHOT_DIR, com
## prefixo SHOT_TAG.

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
	GameState.set_flag(&"ligou_relato_keene")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	var player := esc.player
	Narrator.cancel()
	player.global_position = Vector3(0, 0, -1.35)
	player.rotation.y = 0
	player.head.rotation.x = deg_to_rad(-30)
	var writer = root.get_node("UI/ReplyWriter")
	var escrever: WriteReply = esc.find_child("Dia4", true, false).get_node("Escrever")
	escrever.interact(player)
	await _s(0.3)
	writer._choose(escrever.reply.options[1])
	writer._finish_writing()
	await _s(0.3)
	_shot("%s_0_escrita" % tag)
	writer._seal()
	var t := 0.0
	for marca in [0.6, 1.15, 1.6, 2.05, 2.75, 3.4]:
		await _s(marca - t)
		t = marca
		_shot("%s_%.2f" % [tag, marca])
	await _s(1.5)
	_shot("%s_mao" % tag)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
