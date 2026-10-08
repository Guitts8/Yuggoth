extends Node
## Descartável (playtest 4): o corredor visto de dentro, para os lados.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 1)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	var e: Escritorio = root.find_child("Escritorio", true, false)
	e.calha.folha.rotation_degrees.y = 78
	e.calha.corredor.visible = true
	e.player.conduzido = true
	for v: Array in [["oeste", Vector3(-0.9, 0, 3.75), Vector3(-4, 1.2, 3.75)], ["leste", Vector3(-0.9, 0, 3.75), Vector3(2, 1.0, 3.75)],
			["porta", Vector3(-0.9, 0, 4.0), Vector3(-1.0, 1.2, 2.0)], ["sala", Vector3(-1.0, 0, 2.3), Vector3(-1.4, 1.2, 4.4)]]:
		e.player.global_position = v[1]
		e.player.look_at(Vector3(v[2].x, 0, v[2].z))
		e.player.head.rotation.x = 0.0
		await _s(0.5)
		_shot("%s_%s" % [tag, v[0]])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
