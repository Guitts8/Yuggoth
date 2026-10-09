extends Node
## Descartável (playtest 5, Fase 3f): pôr na mesa à mão (o envelope viaja da mão
## até o lugar) e o pacote do Dia 3 esvaziando peça por peça. Em SHOT_DIR, com
## prefixo SHOT_TAG.

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
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	var e: Escritorio = root.find_child("Escritorio", true, false)
	var pac: Correspondencia = e.find_child("Dia3", true, false).get_node("Pacote/Correio")
	e.player.global_position = Vector3(0.3, 0, -1.35)
	e.player.olhar_para(Vector3(0.3, 0.78, -2.15), 0.01)
	await _s(0.5)
	pac.interact(e.player)
	await _s(0.6)
	(e.get_node(^"%PorNaMesa") as MesaCorreio).interact(e.player)
	await _s(0.25)
	_shot("%s_1_pousando" % tag)
	await _s(0.8)
	_shot("%s_2_na_mesa" % tag)
	pac.interact(e.player)
	await _s(0.5)
	pac.interact(e.player)
	await _s(0.25)
	_shot("%s_3_tirando" % tag)
	await _s(0.6)
	pac.interact(e.player)
	await _s(0.3)
	pac.interact(e.player)
	await _s(0.8)
	_shot("%s_4_tirados" % tag)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
