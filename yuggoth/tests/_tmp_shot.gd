extends Node
## Descartável (playtest 5, Fase 3f): o café na xícara aberta, servindo e servido.
## Em SHOT_DIR, com prefixo SHOT_TAG.

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
	GameState.set_value(&"dia", 2)
	GameState.set_flag(&"comecou_dia_2")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var e: Escritorio = root.find_child("Escritorio", true, false)
	e.player.global_position = Vector3(0.05, 0, -1.55)
	e.player.input_enabled = false
	e.player.seated = true
	var x := e.bebida.xicara.global_position
	e.player.olhar_para(x, 0.01)
	await _s(0.5)
	_shot("%s_1_vazia" % tag)
	e.bebida.cafe(e.player)
	await _s(2.4)
	_shot("%s_2_servindo" % tag)
	await _s(1.2)
	_shot("%s_3_servida" % tag)
	await _s(5.0)
	e.player.fov_forcado = 30.0
	e.player.olhar_para(x, 0.01)
	await _s(0.8)
	_shot("%s_4_perto" % tag)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
