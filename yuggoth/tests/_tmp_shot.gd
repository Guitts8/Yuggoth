extends Node
## Descartável: os quatro sonhos entre os dias, em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	# [noite, de onde, para onde olhar]
	var vistas := [[2, Vector3(-1.0, 0, 2.2), Vector3(-0.2, 0.2, -1.4)],
		[3, Vector3(0.0, 0, -1.0), Vector3(0.0, 0.95, -2.2)],
		[4, Vector3(0.0, 0, -1.3), Vector3(0.2, 1.1, -3.0)],
		[5, Vector3(-0.8, 0, 0.2), Vector3(2.4, 1.3, -2.2)]]
	for v: Array in vistas:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", v[0])
		GameState.set_flag(&"tocou_disco")
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
		await _s(0.5)
		var esc: Escritorio = root.find_child("Escritorio", true, false)
		Narrator.cancel()
		await SceneDirector.fade_out(0.1)
		esc._sonhar(v[0])
		await _s(1.0)
		_mirar(esc.player, v[1], v[2])
		await _s(3.5)
		_shot("%s_noite%d" % [tag, v[0]])
	SaveSystem.delete_save()
	get_tree().quit()


func _mirar(player: Player, de: Vector3, ponto: Vector3) -> void:
	player.global_position = de
	player.look_at(Vector3(ponto.x, de.y, ponto.z))
	var olho := de + Vector3(0, player.eye_height, 0)
	player.head.rotation.x = atan2(ponto.y - olho.y, Vector2(ponto.x - olho.x, ponto.z - olho.z).length())


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
