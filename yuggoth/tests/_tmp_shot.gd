extends Node
## Descartável: o corredor da pensão em Boston, antes e depois de bater, em
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
	await SceneDirector.change_level("res://levels/boston/boston.tscn", &"Entrada")
	await _s(2.5)
	var boston: Boston = root.find_child("Boston", true, false)
	_shot("%s_corredor" % tag)
	var player := boston.player
	_mirar(player, Vector3(0.05, 0, -0.55), Vector3(0.95, 1.45, -1.35))
	await _s(0.6)
	_shot("%s_porta" % tag)
	boston.get_node("%Bater").interact(player)
	await _s(4.5)
	_shot("%s_fresta" % tag)
	_mirar(player, Vector3(-0.3, 0, -1.2), Vector3(1.0, 1.65, -1.22))
	await _s(0.6)
	var rapaz: Interlocutor = boston.get_node("%Conversa")
	rapaz.interact(player)
	await _s(3.0)
	_shot("%s_conversa" % tag)
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
