extends Node
## Descartável (playtest 5, Fase 3f): o fonógrafo novo na mesinha dele, e o mi-go
## do Dia 5 passando rente à janela. Em SHOT_DIR, com prefixo SHOT_TAG.

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
	GameState.set_value(&"dia", 3)
	GameState.set_flag(&"comecou_dia_3")
	GameState.set_flag(&"fono_cilindro")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	var e: Escritorio = root.find_child("Escritorio", true, false)
	e.player.input_enabled = false
	var f := e.fonografo.global_position
	e.player.global_position = Vector3(0.4, 0, 0.6)
	e.player.olhar_para(f + Vector3(0, 0.15, 0), 0.01)
	await _s(0.6)
	_shot("%s_1_fonografo" % tag)
	e.player.global_position = Vector3(-1.5, 0, -0.45)
	e.player.olhar_para(f + Vector3(0, 0.1, 0), 0.01)
	await _s(0.6)
	_shot("%s_2_fonografo_perto" % tag)
	e.player.global_position = Vector3(0.9, 0, 1.6)
	e.player.olhar_para(Vector3(-2.0, 0.9, -0.9), 0.01)
	await _s(0.6)
	_shot("%s_3_sala" % tag)

	# O mi-go do Dia 5.
	GameState.set_value(&"dia", 5)
	GameState.set_flag(&"comecou_dia_5")
	GameState.set_flag(&"leu_bilhete_akeley_agosto")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	e = root.find_child("Escritorio", true, false)
	e.player.input_enabled = false
	e.player.global_position = Vector3(0, 0, -1.6)
	e.player.olhar_para(Vector3(0, 1.62, -4.0), 0.01)
	await _s(1.3)
	_shot("%s_4_migo" % tag)
	await _s(0.5)
	_shot("%s_5_migo" % tag)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
