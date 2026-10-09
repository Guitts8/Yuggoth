extends Node
## Descartável (playtest 6, Fase 3g): o menu como livro — a capa, as páginas, a
## folha virando para as Opções, a pausa. Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	add_child(root)
	await _s(1.0)
	await _shot("%s_1_menu" % tag)
	var main: MainMenu = root.get_node("Menus/MainMenu")
	main._on_options()
	await _s(0.2)
	await _shot("%s_2_virando" % tag)
	await _s(0.3)
	await _shot("%s_3_virando_verso" % tag)
	await _s(0.8)
	await _shot("%s_4_opcoes" % tag)
	var opcoes: OptionsMenu = root.get_node("Menus/OptionsMenu")
	opcoes.close()
	await _s(0.25)
	await _shot("%s_5_voltando" % tag)
	await _s(1.0)
	await _shot("%s_6_menu_de_volta" % tag)
	# A pausa, no meio de um dia.
	main.close()
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 4)
	GameState.set_value(&"data", Lapso.dia_do_ano(7, 18))
	GameState.set_flag(&"comecou_dia_4")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	var pausa: PauseMenu = root.get_node("Menus/PauseMenu")
	pausa.open()
	await _s(0.5)
	await _shot("%s_7_pausa" % tag)
	get_tree().quit()


func _shot(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, nome])


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
