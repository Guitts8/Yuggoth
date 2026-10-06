extends Node
## Descartável: a janela com o painel e com a cidade em 3D (Dia 3, noite, e a
## criatura passando), em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	for cidade in [false, true]:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", 3)
		GameState.set_flag(&"cidade_3d", cidade)
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
		await _s(1.0)
		var esc: Escritorio = root.find_child("Escritorio", true, false)
		Narrator.cancel()
		esc.player.global_position = Vector3(0, 0, -1.4)
		esc.player.rotation = Vector3.ZERO
		esc.player.head.rotation.x = deg_to_rad(8)
		await _s(0.6)
		_shot("%s_%s" % [tag, "cidade" if cidade else "painel"])
		GameState.set_flag(&"tocou_disco")
		await _s(2.1)
		_shot("%s_%s_migo" % [tag, "cidade" if cidade else "painel"])
		esc.player.global_position = Vector3(-0.6, 0, -2.0)
		esc.player.look_at(Vector3(0.3, 0, -6.0))
		esc.player.head.rotation.x = deg_to_rad(5)
		await _s(0.6)
		_shot("%s_%s_perto" % [tag, "cidade" if cidade else "painel"])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
