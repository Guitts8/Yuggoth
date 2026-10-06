extends Node
## Descartável: look-dev do escritório (Dia 1 tarde, Dia 6 noite) em SHOT_DIR,
## com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	if OS.get_environment("SHOT_ALTURA") != "":
		root.target_height = int(OS.get_environment("SHOT_ALTURA"))
	add_child(root)
	await _s(0.5)
	for dia in [1, 6]:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", dia)
		if dia == 6:
			GameState.set_flag(&"tocou_disco")
			GameState.set_flag(&"narrou_cartao_5_setembro")
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
		await _s(1.0)
		var esc: Escritorio = root.find_child("Escritorio", true, false)
		var player := esc.player
		Narrator.cancel()
		# Da porta, olhando a escrivaninha e a janela.
		player.global_position = Vector3(-0.9, 0, 2.2)
		player.look_at(Vector3(0.1, 0, -2.3))
		player.head.rotation.x = deg_to_rad(-12)
		await _s(3.0)
		Narrator.cancel()
		await _s(0.3)
		_shot("%s_d%d_sala" % [tag, dia])
		# Sentado à mesa.
		player.global_position = Vector3(0, 0, -1.35)
		player.rotation.y = 0
		player.head.rotation.x = deg_to_rad(-38)
		await _s(1.0)
		_shot("%s_d%d_mesa" % [tag, dia])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
