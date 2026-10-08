extends Node
## Descartável (playtest 4): o acabamento — lareira, estante e livros, janela,
## de dia e de noite com o fogo. Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	var vistas := [
		["lareira", Vector3(0.6, 0, -0.5), Vector3(2.5, 0.9, -0.6)],
		["lareira_perto", Vector3(1.4, 0, -0.6), Vector3(2.5, 0.6, -0.6)],
		["estante", Vector3(-0.6, 0, -1.8), Vector3(-2.5, 1.2, -2.0)],
		["janela", Vector3(0.0, 0, -1.4), Vector3(0.0, 1.6, -3.0)],
		["sala", Vector3(-1.6, 0, 2.2), Vector3(1.5, 1.0, -1.5)],
	]
	for d in [1, 5]:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", d)
		for k in range(1, d + 1):
			GameState.set_flag(StringName("comecou_dia_%d" % k))
		if d == 5:
			GameState.set_flag(&"lareira_dia_5")
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
		await _s(1.0)
		Narrator.cancel()
		var e: Escritorio = root.find_child("Escritorio", true, false)
		for v: Array in vistas:
			e.player.global_position = v[1]
			e.player.look_at(Vector3(v[2].x, 0, v[2].z))
			var olho := e.player.global_position + Vector3(0, 1.62, 0)
			e.player.head.rotation.x = atan2(v[2].y - olho.y, Vector2(v[2].x - olho.x, v[2].z - olho.z).length())
			await _s(0.6)
			_shot("%s_d%d_%s" % [tag, d, v[0]])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
