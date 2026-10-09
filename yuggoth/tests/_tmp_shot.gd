extends "res://tests/smoke_test.gd"
## Descartável (sessão de tester 2): cada dia do escritório visto de vários
## pontos — o pé da escada, a porta, o meio da sala nas quatro direções, a mesa.
## Em SHOT_DIR, com prefixo SHOT_TAG. SHOT_DIAS=1,2 limita os dias.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	if OS.get_environment("SHOT_MODO") != "menu":
		root.boot_to_menu = false
		root.start_level = load("res://levels/test/test_room.tscn")
	add_child(root)
	if SceneDirector.is_busy:
		await SceneDirector.level_changed
	var dias := OS.get_environment("SHOT_DIAS").split(",", false)
	if OS.get_environment("SHOT_MODO") == "sonhos":
		for n in [2, 3, 4, 5]:
			if dias.is_empty() or str(n) in dias:
				await _sonho_fotos(n)
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "menu":
		await _menu_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "boston":
		await _boston_fotos()
		get_tree().quit()
		return
	for n in range(1, 7):
		if not dias.is_empty() and str(n) not in dias:
			continue
		await _dia_fotos(n)
	get_tree().quit()


func _dia_fotos(n: int, estado := {}) -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", n)
	for k: StringName in estado:
		GameState.set_value(k, estado[k])
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(1.5)
	Narrator.cancel()
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var p := esc.player
	var sonda := OS.get_environment("SHOT_SONDA")
	if sonda:
		var v := sonda.split_floats(",")
		var caixa := AABB(Vector3(v[0], v[1], v[2]), Vector3(v[3], v[4], v[5]) - Vector3(v[0], v[1], v[2]))
		for mi: MeshInstance3D in esc.find_children("*", "MeshInstance3D", true, false):
			if mi.is_visible_in_tree() and (mi.global_transform * mi.get_aabb()).intersects(caixa):
				print("SONDA ", esc.get_path_to(mi), " ", mi.global_transform * mi.get_aabb())
		get_tree().quit()
		return
	await _olhar(p, Vector3(1.6, 0.0, esc.escada.global_position.z))
	await _shot("%s_d%d_0_escada" % [tag, n])
	Engine.time_scale = 4.0
	await _subir_a_escada(esc)
	Engine.time_scale = 1.0
	await _olhar(p, esc.calha.soleira)
	await _shot("%s_d%d_1_porta" % [tag, n])
	esc.porta_fora.interact(p)
	await _until(func() -> bool: return esc.calha.porta_aberta and p.input_enabled, 20.0)
	await _s(0.5)
	Narrator.cancel()
	await _shot("%s_d%d_2_aberta" % [tag, n])
	await _entrar(esc)
	Narrator.cancel()
	p.global_position = Vector3(0.0, 0.0, 0.3)
	var i := 0
	for ang: float in [0.0, PI / 2.0, PI, -PI / 2.0]:
		p.rotation.y = ang
		p.head.rotation.x = -0.08
		await _s(0.4)
		await _shot("%s_d%d_3_sala_%d" % [tag, n, i])
		i += 1
	# A mesa, de perto.
	p.global_position = Vector3(0.0, 0.0, -1.2)
	p.rotation.y = 0.0
	p.head.rotation.x = -0.6
	await _s(0.4)
	await _shot("%s_d%d_4_mesa" % [tag, n])
	# O canto da lâmpada, de perto.
	p.global_position = Vector3(0.4, 0.0, -1.75)
	await _olhar(p, Vector3(0.4, 0, -2.45))
	p.head.rotation.x = -1.05
	await _s(0.3)
	await _shot("%s_d%d_4b_lampada" % [tag, n])
	# O cesto, de cima, e o canto do armário.
	p.global_position = Vector3(0.7, 0.0, -1.3)
	await _olhar(p, Vector3(1.0, 0, -1.95))
	p.head.rotation.x = -1.0
	await _s(0.3)
	await _shot("%s_d%d_5_cesto" % [tag, n])
	p.global_position = Vector3(-0.6, 0.0, 1.2)
	await _olhar(p, Vector3(-2.15, 0, 2.35))
	p.head.rotation.x = -0.35
	await _s(0.3)
	await _shot("%s_d%d_6_armario" % [tag, n])


## A noite do dia `n`: do diário (ou do lugar do sono) ao sonho, e o sonho em
## quatro direções, de onde ele está.
func _sonho_fotos(n: int) -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", n)
	var estado := {StringName("comecou_dia_%d" % n): true, StringName("escreveu_resposta_dia_%d" % n): true,
		StringName("resposta_dia_%d" % n): 0, &"diario": n}
	if n >= 3:
		for f: StringName in [&"fono_corneta", &"fono_manivela", &"fono_agulha", &"fono_cilindro", &"cilindro_chegou", &"tocou_disco"]:
			estado[f] = true
	if n == 4:
		estado[&"voltou_de_boston"] = true
		estado[&"anoiteceu_dia_4"] = true
	if n == 5:
		estado[&"lareira_dia_5"] = true
	for k: StringName in estado:
		GameState.set_value(k, estado[k])
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(1.0)
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	Engine.time_scale = 8.0
	await _entrar(esc)
	await _anotar(esc)
	var lugar := esc._lugar_sono(n)
	if lugar:
		await _until(func() -> bool: return GameState.get_value(&"sono", 0) == n and esc.player.input_enabled, 120.0)
		lugar.interact(esc.player)
	await _until(func() -> bool: return GameState.get_value(&"sonhando") == n and esc.player.input_enabled, 160.0)
	Engine.time_scale = 1.0
	Narrator.cancel()
	await _s(2.0)
	var p := esc.player
	var base := p.rotation.y
	for i in 4:
		p.rotation.y = base + i * PI / 2.0
		p.head.rotation.x = -0.05
		await _s(0.6)
		await _shot("%s_noite%d_%d" % [tag, n, i])
	var pedra := esc.find_child("Pedra", true, false) as Node3D
	if n == 4 and pedra:
		for k in 3:
			var ang := -0.6 + k * 0.6
			p.global_position = pedra.global_position + Vector3(sin(ang) * 0.9, 0, cos(ang) * 0.9)
			await _olhar(p, pedra.global_position + Vector3(0, 0.3, 0))
			p.head.rotation.x = -0.55
			await _s(0.5)
			await _shot("%s_pedra_%d" % [tag, k])


func _boston_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 4)
	for f: StringName in [&"comecou_dia_4", &"ligou_agencia_arkham", &"ligou_boston", &"ligou_telegrama_noturno", &"ligou_relato_keene",
			&"narrou_cartao_sexta", &"leu_telegrama_pedra"]:
		GameState.set_flag(f)
	await SceneDirector.change_level("res://levels/boston/boston.tscn", &"", false)
	await _s(1.5)
	Narrator.cancel()
	var b := root.find_child("Boston", true, false) as Boston
	var p := b.player
	var base := p.rotation.y
	for i in 4:
		p.rotation.y = base + i * PI / 2.0
		p.head.rotation.x = -0.05
		await _s(0.5)
		await _shot("%s_boston_%d" % [tag, i])
	p.global_position = Vector3(0, 0, 0.8)
	await _olhar(p, Vector3(0, 0, 5.0))
	p.head.rotation.x = -0.2
	await _s(0.5)
	await _shot("%s_boston_escada" % tag)
	p.global_position = Vector3(0, 0, 2.3)
	p.rotation.y = base
	b.bater.interact(p)
	await _until(func() -> bool: return GameState.has_flag(&"porta_aberta_boston"), 20.0)
	await _s(1.5)
	await _olhar(p, (b.get_node("%Folha") as Node3D).global_position)
	await _shot("%s_boston_porta" % tag)


func _menu_fotos() -> void:
	Necronomicon._pena(64).get_image().save_png("%s/%s_pena.png" % [dir, tag])
	# A abertura: as velas, a câmera, a capa, a tinta.
	for i in 16:
		await _s(0.5)
		await _shot("%s_0%02d_abrindo" % [tag, i])
	await _s(1.0)
	await _shot("%s_1_menu" % tag)
	var main: MainMenu = root.get_node("Menus/Necronomicon/Paginas/MainMenu")
	var nec: Necronomicon = root.get_node("Menus/Necronomicon")
	# O mouse sobre "Opções" (o ponto da página visto pela câmera), e o clique.
	var alvo := Vector2.ZERO
	for k in 3:
		alvo = _na_tela(nec, main.options_button.get_global_rect().get_center())
		_mouse(alvo, -1)
		await _s(1.0)
	await _shot("%s_1b_hover" % tag)
	main.new_game_button.grab_focus()
	await _s(0.08)
	await _shot("%s_1c_foco_andando" % tag)
	await _s(0.5)
	await _shot("%s_1d_foco" % tag)
	_mouse(alvo, 1)
	await get_tree().process_frame
	_mouse(alvo, 0)
	for i in 5:
		await _s(0.18)
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
	await _s(0.12)
	await _shot("%s_6_pausa_chegando" % tag)
	await _s(0.6)
	await _shot("%s_6_pausa" % tag)
	# De volta ao menu e "Continuar": o mergulho na tinta.
	await root.quit_to_menu()
	await _s(1.5)
	await _shot("%s_7_menu_de_novo" % tag)
	main._on_new_game()
	await _s(0.6)
	await _shot("%s_7b_confirmar" % tag)
	main.confirm._answered.emit(false)
	await _s(0.4)
	main._on_continue()
	for i in 5:
		await _s(0.25)
		await _shot("%s_8_mergulho_%d" % [tag, i])


## A posição na tela do ponto `p` das páginas (na textura de 1240 × 840).
func _na_tela(nec: Necronomicon, p: Vector2) -> Vector2:
	var ponto := nec._livro.global_transform * nec._ponto_da_pagina(p / Vector2(Necronomicon.TINTA))
	return nec._camera.unproject_position(ponto) * (Vector2(DisplayServer.window_get_size()) / Vector2(nec._mundo.size))


## Move o mouse (`botao` -1) ou aperta (1) / solta (0) o botão esquerdo em `p`.
func _mouse(p: Vector2, botao: int) -> void:
	if botao < 0:
		var mov := InputEventMouseMotion.new()
		mov.position = p
		mov.global_position = p
		Input.parse_input_event(mov)
		return
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = botao == 1
	b.position = p
	b.global_position = p
	Input.parse_input_event(b)


func _olhar(p: Player, ponto: Vector3) -> void:
	p.look_at(Vector3(ponto.x, p.global_position.y, ponto.z))
	p.head.rotation.x = 0.0
	await _s(0.4)


func _shot(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, nome])


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
