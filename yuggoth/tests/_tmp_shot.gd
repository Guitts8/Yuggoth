extends Node
## Descartável (playtest 7, Fase 3h): o menu como o Necronomicon em 3D — a capa
## abrindo, o sumário, a folha virando para as Opções e de volta, a pausa.
## Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	add_child(root)
	for i in 6:
		await _s(0.6)
		await _shot("%s_0%d_abrindo" % [tag, i])
	await _s(1.0)
	await _shot("%s_1_menu" % tag)
	var main: MainMenu = root.get_node("Menus/Necronomicon/Paginas/MainMenu")
	# O mouse sobre "Opções" (o ponto da página visto pela câmera), e o clique.
	var nec: Necronomicon = root.get_node("Menus/Necronomicon")
	var alvo := Vector2.ZERO
	for k in 3:
		var u := Vector2(930, 470) / Vector2(Necronomicon.TINTA)
		var x := (u.x * 2.0 - 1.0) * Necronomicon.LARGURA
		var y := Necronomicon.TOPO + Necronomicon.ARCO * Necronomicon._perfil(absf(x) / Necronomicon.LARGURA)
		var p := Vector3(x, y, -Necronomicon.ALTURA / 2.0 + u.y * Necronomicon.ALTURA)
		alvo = nec._camera.unproject_position(p) * (Vector2(DisplayServer.window_get_size()) / Vector2(nec._mundo.size))
		var mov := InputEventMouseMotion.new()
		mov.position = alvo
		mov.global_position = alvo
		Input.parse_input_event(mov)
		await _s(1.5)
	await _shot("%s_1b_hover" % tag)
	for apertado in [true, false]:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = apertado
		b.position = alvo
		b.global_position = alvo
		Input.parse_input_event(b)
		await get_tree().process_frame
	for i in 4:
		await _s(0.2)
		await _shot("%s_2_virando_%d" % [tag, i])
	await _s(0.6)
	await _shot("%s_3_opcoes" % tag)
	var opcoes: OptionsMenu = root.get_node("Menus/Necronomicon/Paginas/OptionsMenu")
	opcoes.close()
	await _s(0.35)
	await _shot("%s_4_voltando" % tag)
	await _s(1.0)
	await _shot("%s_5_menu_de_volta" % tag)
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
	var pausa: PauseMenu = root.get_node("Menus/Necronomicon/Paginas/PauseMenu")
	pausa.open()
	await _s(0.6)
	await _shot("%s_6_pausa" % tag)
	get_tree().quit()


func _shot(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, nome])


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
