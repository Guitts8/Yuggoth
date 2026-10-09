extends Node
## Descartável (playtest 5, Fase 3f): o diário novo — fechado, a capa abrindo, as
## folhas correndo até a fita, aberto. Em SHOT_DIR, com prefixo SHOT_TAG.

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
	Narrator.cancel()
	var e: Escritorio = root.find_child("Escritorio", true, false)
	var d := e.diario
	e.player.global_position = Vector3(-0.1, 0, -1.45)
	e.player.input_enabled = false
	e.player.fov_forcado = 30.0
	e.player.olhar_para(d.global_position + Vector3(0.07, 0, 0), 0.01)
	await _s(0.6)
	_shot("%s_1_fechado" % tag)
	e.player.fov_forcado = 0.0
	d._abrir(e.player)
	await _s(4.1)
	_shot("%s_2_capa" % tag)
	await _s(0.6)
	_shot("%s_3_correndo" % tag)
	await _s(0.5)
	_shot("%s_4_correndo" % tag)
	await _s(2.5)
	_shot("%s_5_aberto" % tag)
	d.fechar(e.player)
	await _s(1.6)
	_shot("%s_6_fechando" % tag)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
