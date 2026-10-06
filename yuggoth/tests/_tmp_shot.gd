extends Node
## Descartável: a noite do Dia 6 com a lareira apagada e acesa, em SHOT_DIR,
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
	GameState.set_value(&"dia", 6)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	var vistas := [["porta", Vector3(-0.9, 0, 2.2), Vector3(0.6, 0.9, -1.5)],
		["mesa", Vector3(-0.2, 0, -1.2), Vector3(1.5, 0.8, -1.4)],
		["lareira", Vector3(0.6, 0, 0.6), Vector3(2.4, 0.4, -0.6)]]
	for aceso in [false, true]:
		if aceso:
			esc.find_child("Dia6", true, false).get_node("AcenderLareira").interact(esc.player)
		for v: Array in vistas:
			_mirar(esc.player, v[1], v[2])
			await _s(1.2)
			Narrator.cancel()
			_shot("%s_%s_%s" % [tag, "acesa" if aceso else "apagada", v[0]])
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
