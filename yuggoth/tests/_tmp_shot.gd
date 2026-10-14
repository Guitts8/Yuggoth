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
	if OS.get_environment("SHOT_MODO") == "alcance":
		await _alcance_sonda()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "lapso":
		await _lapso_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "vigilia":
		await _vigilia_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "olhar":
		await _olhar_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "entardecer":
		await _entardecer_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "fazenda":
		await _fazenda_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "preparacao":
		await _preparacao_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "rotina":
		await _rotina_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "matilha":
		await _matilha_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "caes":
		await _caes_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "ceu":
		GameState.reset()
		GameState.set_flag(&"interludio")
		await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Entardecer", false)
		await _s(0.3)
		await _shot("%s_ceu_0" % tag)
		var img := get_viewport().get_texture().get_image()
		for y in [10, 120, 240, 360, 480, 600, 710]:
			print("CEU y=", y, " ", img.get_pixel(640, y), " ", img.get_pixel(200, y))
		await _s(2.0)
		await _shot("%s_ceu_1" % tag)
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "selagem":
		await _selagem_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "diario":
		await _diario_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "boston":
		await _boston_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "guia":
		await _guia_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "percurso":
		await _percurso_fazenda()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "pessoa":
		await _pessoa_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "migo":
		await _migo_fotos()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_MODO") == "documento":
		await _documento_fotos()
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
	if n == 3:
		var vigia := esc.find_child("Vigia", true, false) as Node3D
		var caverna := vigia.global_position
		# De costas para a vigia por um tempo (ela aparece fora da vista).
		await _olhar(p, p.global_position - (vigia.global_position - p.global_position))
		await _s(20.0)
		await _olhar(p, vigia.global_position)
		p.head.rotation.x = 0.05
		await _s(0.6)
		await _shot("%s_vigia" % tag)
		for c: Node3D in esc.find_children("Respira*", "", true, false):
			pass
		await _olhar(p, p.global_position + Vector3(0.9, 0, -7.2))
		p.head.rotation.x = 0.0
		await _s(0.6)
		await _shot("%s_caverna" % tag)
		p.global_position += Vector3(0.4, 0, -3.5)
		await _olhar(p, p.global_position + Vector3(0.5, 0, -3.0))
		await _s(0.6)
		await _shot("%s_caverna_perto" % tag)
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
	# O rapaz pela fresta (playtest 11: o modelo novo).
	b.bater.interact(p)
	await _until(func() -> bool: return GameState.has_flag(&"porta_aberta_boston"), 20.0)
	await _s(1.0)
	for k in 3:
		p.global_position = Vector3(-0.25 + k * 0.12, 0, -1.2 - k * 0.15)
		await _olhar(p, Vector3(1.0, 0, -1.25))
		var olho := p.camera.global_position
		p.head.rotation.x = atan2(1.62 - olho.y, Vector2(1.0 - olho.x, -1.25 - olho.z).length())
		await _s(1.2)
		await _shot("%s_rapaz_%d" % [tag, k])
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
	p.global_position = Vector3(0, 0, 2.8)
	await _olhar(p, Vector3(0, 0, 6.0))
	p.head.rotation.x = -0.45
	await _s(0.5)
	await _shot("%s_boston_escada_topo" % tag)
	# Andando escada abaixo (a física): até o patamar.
	p.global_position = Vector3(0, 0.1, 2.6)
	await _olhar(p, Vector3(0, 0, 9.0))
	Input.action_press(&"mover_frente")
	await _s(2.6)
	Input.action_release(&"mover_frente")
	await _s(0.3)
	print("ESCADA y=", p.global_position.y, " z=", p.global_position.z)
	await _olhar(p, p.global_position + Vector3(-3, 0, 0.3))
	p.head.rotation.x = -0.25
	await _s(0.5)
	await _shot("%s_boston_patamar" % tag)
	await _olhar(p, Vector3(0, 0, 0))
	p.head.rotation.x = 0.3
	await _s(0.5)
	await _shot("%s_boston_subindo" % tag)
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


## SHOT_MODO=olhar, SHOT_EXTRA="dia;chave=valor,chave=valor;ox,oy,oz>ax,ay,az|...":
## o escritório no dia, com o estado, e uma foto de cada olho (o) para cada alvo (a).
## Um alvo "exame:Caminho/Do/Examinable" abre o exame dele.
func _olhar_fotos() -> void:
	var partes := OS.get_environment("SHOT_EXTRA").split(";")
	var estado := {}
	for par in partes[1].split(",", false):
		var kv := par.split("=")
		estado[StringName(kv[0])] = int(kv[1]) if kv[1].is_valid_int() else (float(kv[1]) if kv[1].is_valid_float() else kv[1] == "true")
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	if int(partes[0]) == 0:
		GameState.set_value(&"prologo_concluido", false)
	GameState.set_value(&"dia", maxi(1, int(partes[0])))
	for k: StringName in estado:
		GameState.set_value(k, estado[k])
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(2.0)
	if int(partes[0]) == 0:
		await _s(8.0)
		SceneDirector.release_black()
		await _s(1.0)
	Narrator.cancel()
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var p := esc.player
	if p.seated:
		p.stand()
	(esc.get_node("%Corredor") as Node3D).visible = true
	for n: Node in esc.find_children("_Nome*", "Label3D", true, false):
		print("NOME ", n.name, " ", (n as Label3D).text, " ", (n as Node3D).global_position, " vis ", (n as Node3D).is_visible_in_tree(), " ps ", (n as Label3D).pixel_size)
		var l := n as Label3D
		print("   font ", l.font, " ", l.font.get_font_name() if l.font else "-", " mod ", l.modulate, " basis ", l.global_basis.z, " fs ", l.font_size, " aabb ", l.get_aabb())
	var i := 0
	for olho in partes[2].split("|", false):
		if olho.begins_with("exame:"):
			var ex := esc.get_node(olho.substr(6)) as Examinable
			ex.interact(p)
			await _s(1.5)
			await _shot("%s_%d_exame" % [tag, i])
			var viewer := root.find_child("ExamineViewer", true, false)
			viewer._zoom = 1.0
			await _s(1.0)
			await _shot("%s_%d_exame_perto" % [tag, i])
			viewer.close()
			await _s(0.6)
		else:
			var oa := olho.split(">")
			var o := oa[0].split_floats(",")
			var a := oa[1].split_floats(",")
			p.global_position = Vector3(o[0], o[1], o[2])
			var alvo := Vector3(a[0], a[1], a[2])
			p.look_at(Vector3(alvo.x, p.global_position.y, alvo.z))
			var cam := p.camera.global_position
			var d := alvo - cam
			p.head.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())
			await _s(0.7)
			await _shot("%s_%d" % [tag, i])
		i += 1


## SHOT_MODO=vigilia: a noite em claro do Dia 6 — a janela entreaberta, a cortina,
## e o dia raiando.
func _vigilia_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 6)
	for f: StringName in [&"comecou_dia_6", &"escreveu_resposta_dia_5", &"narrou_cartao_31_agosto", &"escreveu_animo_dia_6",
			&"narrou_cartao_5_setembro", &"narrou_cartao_6_setembro", &"leu_carta_akeley_terca", &"lareira_dia_6"]:
		GameState.set_flag(f)
	GameState.set_value(&"resposta_dia_5", 0)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(1.5)
	Narrator.cancel()
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var p := esc.player
	p.global_position = Vector3(0.3, 0, -0.6)
	p.look_at(Vector3(0, p.global_position.y, 5))
	esc.vigilia.ate_o_toque = 1.0
	esc.vigilia.ate_a_janela = 1.0
	esc.vigilia.comecar(esc)
	await _until(func() -> bool: return GameState.has_flag(&"vigilia_janela"), 30.0)
	await _s(1.0)
	p.global_position = Vector3(0.6, 0, -1.4)
	await _olhar(p, Vector3(0.4, 1.4, -3.0))
	p.head.rotation.x = 0.0
	for k in 3:
		await _s(0.9)
		await _shot("%s_janela_%d" % [tag, k])
	esc.vigilia.fechar.interact(p)
	await _s(1.5)
	await _shot("%s_fechada" % tag)
	await _until(func() -> bool: return esc.vigilia.esperar.can_interact(p), 40.0)
	esc.vigilia.esperar.interact(p)
	for k in 6:
		await _s(2.5)
		await _shot("%s_raiar_%d" % [tag, k])


## SHOT_MODO=lapso: um lapso de dias no Dia 6 (ele lendo à mesa), em fotos seguidas.
func _lapso_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 6)
	for f: StringName in [&"comecou_dia_6", &"escreveu_resposta_dia_5", &"narrou_cartao_31_agosto"]:
		GameState.set_flag(f)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(1.5)
	Narrator.cancel()
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	esc.player.global_position = Vector3(0.3, 0, -1.0)
	SceneDirector.time_skip(load("res://narrative/narration/cartao_5_setembro.tres"))
	for k in 60:
		await _s(0.25)
		await _shot("%s_lapso_%02d" % [tag, k])


## SHOT_MODO=alcance: no Dia 5, com o telegrama aberto, o que tapa a carta de agosto.
func _alcance_sonda() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 5)
	for k: StringName in [&"comecou_dia_5", &"narrou_cartao_telegrama_akely"]:
		GameState.set_flag(k)
	for k: StringName in [&"correio_agosto", &"correio_15_agosto", &"correio_telegrama_akely"]:
		GameState.set_value(k, 3)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(2.0)
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var alvo := esc.find_child("CartaAgosto", true, false).get_node("Ler") as Interactable
	var centro := (alvo.get_child(0) as Node3D).global_position
	print("ALVO ", centro, " folha ", (alvo.get_parent() as Node3D).global_position)
	var space := esc.get_world_3d().direct_space_state
	var vistos := {}
	for h in [1.15, 1.6]:
		for r in [0.4, 0.8, 1.2]:
			for i in 16:
				var a := TAU * i / 16.0
				var origem := Vector3(centro.x + cos(a) * r, h, centro.z + sin(a) * r)
				var q := PhysicsRayQueryParameters3D.create(origem, centro, 3, [esc.player.get_rid()])
				q.collide_with_areas = true
				q.hit_from_inside = true
				var c = space.intersect_ray(q).get("collider")
				if c:
					vistos[esc.get_path_to(c)] = vistos.get(esc.get_path_to(c), 0) + 1
	print("COLISORES ", vistos)


## SHOT_MODO=fazenda: a planta da fazenda (F1) de vários pontos. SHOT_EXTRA
## ("ox,oy,oz>ax,ay,az|...") troca a lista padrão.
func _fazenda_fotos() -> void:
	GameState.reset()
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Quintal", false)
	await _s(1.0)
	var faz := root.find_child("Fazenda", true, false) as Node3D
	var p := faz.find_child("Player", true, false) as Player
	var pontos := [
		["estrada", Vector3(30.5, 0, 6.0), Vector3(2, 4, 0)],
		["caminho", Vector3(16.0, 0, 1.5), Vector3(5, 2.5, 0)],
		["nordeste", Vector3(26.0, 0, -32.0), Vector3(-8, 3, -6)],
		["fundos", Vector3(-38.0, 0, -4.0), Vector3(-6, 4, -6)],
		["montanha", Vector3(-20.0, 0, 10.0), Vector3(-120, 30, 0)],
		["vale", Vector3(20.0, 0, -4.0), Vector3(120, -10, 0)],
		["vestibulo", Vector3(5.4, 0.6, 0.6), Vector3(-2, 1.8, 0.2)],
		["escritorio", Vector3(5.0, 0.6, 2.2), Vector3(1.5, 1.0, 5.2)],
		["sala_estar", Vector3(5.0, 0.6, -2.0), Vector3(2, 1.0, -5.5)],
		["jantar", Vector3(0.6, 0.6, 2.0), Vector3(-2.5, 1.0, 5.5)],
		["cozinha", Vector3(-3.6, 0.6, 2.0), Vector3(-8, 1.2, 5)],
		["andar_de_cima", Vector3(-0.4, 3.75, 0.8), Vector3(5.5, 4.6, 0.5)],
		["quarto_hospedes", Vector3(3.0, 3.75, 1.9), Vector3(4, 4.2, 5.5)],
		["canil", Vector3(6.0, 0, -7.0), Vector3(-2.5, 0.8, -12)],
		["ford", Vector3(18.0, 0, -15.0), Vector3(12, 1, -15)],
		["celeiro", Vector3(-12.0, 0, 0.5), Vector3(-15, 3, -12)],
	]
	var extra := OS.get_environment("SHOT_EXTRA")
	if extra:
		pontos.clear()
		var i := 0
		for par in extra.split("|"):
			var oa := par.split(">")
			var o := oa[0].split_floats(",")
			var a := oa[1].split_floats(",")
			pontos.append(["x%d" % i, Vector3(o[0], o[1], o[2]), Vector3(a[0], a[1], a[2])])
			i += 1
	for pt: Array in pontos:
		p.global_position = pt[1]
		p.velocity = Vector3.ZERO
		await _s(0.3)
		var alvo: Vector3 = pt[2]
		p.look_at(Vector3(alvo.x, p.global_position.y, alvo.z))
		var olho := p.camera.global_position
		p.head.rotation.x = atan2(alvo.y - olho.y, Vector2(alvo.x - olho.x, alvo.z - olho.z).length())
		await _s(0.5)
		await _shot("%s_%s" % [tag, pt[0]])


## SHOT_MODO=entardecer: a passagem da tinta para o quintal (F2) e o quintal em
## três momentos do entardecer, de frente para a montanha e para a casa.
func _entardecer_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 6)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(1.0)
	Narrator.cancel()
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var tinta := TintaTransicao.new()
	tinta.aproximar = 2.0
	tinta.espalhar = 1.5
	tinta.secar = 1.5
	tinta.segurar = 0.5
	get_tree().root.add_child(tinta)
	await tinta.tocar(esc.ultima_carta)
	await _shot("%s_0_tinta" % tag)
	GameState.set_flag(&"interludio")
	tinta.revelar("res://levels/fazenda/fazenda.tscn", &"Entardecer", 3.0, "Domingo, 2 de setembro de 1928")
	await _s(2.6)
	await _shot("%s_0b_data" % tag)
	await _until_nivel("res://levels/fazenda/fazenda.tscn")
	# A descida do céu, quadro a quadro.
	for k in 22:
		await _s(0.85)
		await _shot("%s_1_descida_%02d" % [tag, k])
	await _s(1.5)
	await _shot("%s_2_quintal" % tag)
	var faz := root.find_child("Fazenda", true, false) as Fazenda
	var p := faz.player
	if OS.get_environment("SHOT_SO_DESCIDA") == "1":
		return
	for momento: float in [0.0, 0.45, 1.0]:
		faz.entardecer = momento
		faz.duracao_entardecer = 99999.0
		faz._aplicar(momento)
		await _s(0.6)
		for alvo: Array in [["oeste", Vector3(-60, 8, -14)], ["casa", Vector3(1, 3, 0)], ["vale", Vector3(60, -4, -10)]]:
			var a: Vector3 = alvo[1]
			p.look_at(Vector3(a.x, p.global_position.y, a.z))
			var olho := p.camera.global_position
			p.head.rotation.x = atan2(a.y - olho.y, Vector2(a.x - olho.x, a.z - olho.z).length())
			await _s(0.5)
			await _shot("%s_p%d_%s" % [tag, int(momento * 100), alvo[0]])


## SHOT_MODO=diario: o caderno abre diante dele e fecha, em quadros seguidos (o
## salto da capa ao fechar, playtest 10). SHOT_PASSO (s entre quadros).
func _diario_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 2)
	GameState.set_flag(&"comecou_dia_2")
	GameState.add_document(load("res://narrative/documents/diario_dia_1.tres"))
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(1.5)
	Narrator.cancel()
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var p := esc.player
	await _entrar(esc)
	Narrator.cancel()
	p.input_enabled = false
	var d := esc.diario
	d._paginas = [[Diario.ROSTO, 0.0], [d._esquerda.text, 0.0]]
	var passo := float(OS.get_environment("SHOT_PASSO")) if OS.has_environment("SHOT_PASSO") else 0.1
	var est := {"abrindo": true}
	var abre := func() -> void:
		await d._abrir(p)
		est["abrindo"] = false
	abre.call()
	var q := 0
	while est["abrindo"] and q < 200:
		await _s(passo)
		await _shot("%s_abrindo_%03d" % [tag, q])
		q += 1
	await _s(0.5)
	await _shot("%s_aberto" % tag)
	d.fechar(p)
	for k in int(5.0 / passo):
		await _s(passo)
		await _shot("%s_fechando_%03d" % [tag, k])
		print("Q ", k, " capa ", snappedf(d._k_capa, 0.001), " folhas ", snappedf(d._k_folhas, 0.001), " aberto ", d.aberto)
	# A escrita que passa de página (playtest 11): uma entrada longa.
	var longa := DocumentData.new()
	longa.id = &"diario_teste_longa"
	var frase := "Escrevo isto com a mão firme, embora a noite tenha sido longa e o vento não pare de bater nas vidraças. "
	longa.pages = [frase.repeat(14)]
	GameState.add_document(longa)
	var est2 := {"fim": false}
	var escreve := func() -> void:
		await d.anotar(longa, null, p, false)
		est2["fim"] = true
	escreve.call()
	var q2 := 0
	while not est2["fim"] and q2 < 400:
		await _s(0.25)
		await _shot("%s_escrevendo_%03d" % [tag, q2])
		q2 += 1


## SHOT_MODO=selagem: no Dia 6, com as cartas de setembro abertas na mesa, a
## carta registrada selada (playtest 10: a dobra atravessava a folha do dia).
func _selagem_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 6)
	for f: StringName in [&"comecou_dia_6", &"escreveu_resposta_dia_5", &"narrou_cartao_31_agosto", &"escreveu_animo_dia_6",
			&"narrou_cartao_5_setembro", &"narrou_cartao_6_setembro", &"narrou_cartao_7_setembro", &"leu_carta_akeley_terca",
			&"leu_carta_akeley_quarta", &"leu_carta_akeley_28_agosto", &"leu_carta_akeley_setembro", &"leu_carta_akeley_segunda"]:
		GameState.set_flag(f)
	GameState.set_value(&"resposta_dia_5", 0)
	for k: StringName in [&"correio_28_agosto", &"correio_setembro", &"correio_segunda", &"correio_terca", &"correio_quarta"]:
		GameState.set_value(k, 3)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
	await _s(2.0)
	Narrator.cancel()
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var p := esc.player
	p.global_position = Vector3(0.1, 0, -1.3)
	await _olhar(p, Vector3(0.05, 0, -2.2))
	p.head.rotation.x = -0.9
	await _s(0.5)
	await _shot("%s_antes" % tag)
	esc._on_reply_written(load("res://narrative/replies/resposta_dia_6.tres"), null)
	for k in 34:
		await _s(0.5)
		await _shot("%s_selando_%02d" % [tag, k])


## SHOT_MODO=preparacao: a preparação para a noite (F6), tarefa por tarefa.
func _preparacao_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"interludio")
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Entardecer", false)
	var faz := root.find_child("Fazenda", true, false) as Fazenda
	Engine.time_scale = 6.0
	await _until(func() -> bool: return not faz.descendo, 60.0)
	faz.rotina.pular()
	await _until(func() -> bool: return faz.preparacao._ativa, 30.0)
	Engine.time_scale = 1.0
	var p := faz.player
	var pr := faz.preparacao
	var fazer := func(area: Interactable, de: Vector3, nome: String, espera: float, alvo := Vector3.INF) -> void:
		p.global_position = de
		p.velocity = Vector3.ZERO
		var c := area.global_position if alvo == Vector3.INF else alvo
		p.look_at(Vector3(c.x, p.global_position.y, c.z))
		await _s(0.2)
		var olho := p.camera.global_position
		p.head.rotation.x = atan2(c.y - olho.y, Vector2(c.x - olho.x, c.z - olho.z).length())
		await _s(0.3)
		print("ALVO ", nome, " mira=", p._target == area, " pegou=", p.ray.get_collider())
		area.interact(p)
		await _s(espera)
		await _shot("%s_%s" % [tag, nome])
	await fazer.call(pr.lampioes[0], Vector3(4.6, 0.6, 3.25), "1_lampiao_escritorio", 4.0)
	await fazer.call(pr.venezianas[4], Vector3(4.9, 0.6, 2.6), "2_veneziana", 2.0)
	await fazer.call(pr.pegar_rifle, Vector3(-1.0, 0.6, -4.2), "3_rifle", 1.5)
	for k in 4:
		await fazer.call(pr.carregar_rifle, Vector3(-1.4, 0.6, -3.2), "4_carregar_%d" % k, 1.4)
	await fazer.call(pr.acender_lareira, Vector3(3.0, 0.6, 2.9), "5_lareira", 12.0)
	await fazer.call(pr.telefone, Vector3(2.4, 0.6, 0.3), "6_telefone", 3.0)
	await fazer.call(pr.soltar_caes, Vector3(-0.3, 0, -6.2), "7_porteira", 4.0, Vector3(-0.35, 0.6, -7.0))
	for l in pr.lampioes:
		l.aceso = true
		l._k = 1.0
		l._mostrar()
	for v in pr.venezianas:
		v.fechar_ja()
	await _s(8.0)
	p.global_position = Vector3(3.2, 0.6, 3.9)
	await _olhar(p, Vector3(1.8, 0.6, 3.6))
	p.head.rotation.x = -0.45
	await _s(0.5)
	await _shot("%s_8_conan" % tag)
	faz.teto = 1.0
	faz.entardecer = 1.0
	faz._noite_alvo = 0.8
	faz.noite = 0.8
	faz._aplicar(1.0)
	print("CONAN ", faz.get_node("Caes/Conan").global_position)
	p.global_position = Vector3(30.5, 0, -6)
	await _olhar(p, Vector3(900, 700, -100))
	p.head.rotation.x = 0.55
	for k in 6:
		await _s(6.0)
		await _shot("%s_9_lua_%d" % [tag, k])
	print("FEITA ", pr.feita, " modo ", faz.get_node("Caes").modo, " noite ", faz.noite)


## SHOT_MODO=rotina: a rotina do entardecer (F5), tarefa por tarefa.
func _rotina_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"interludio")
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Entardecer", false)
	var faz := root.find_child("Fazenda", true, false) as Fazenda
	Engine.time_scale = 6.0
	await _until(func() -> bool: return not faz.descendo, 60.0)
	Engine.time_scale = 1.0
	var p := faz.player
	var r := faz.rotina
	var passo := func(area: Interactable, de: Vector3, nome: String, espera: float) -> void:
		p.global_position = de
		p.velocity = Vector3.ZERO
		await _olhar(p, area.global_position)
		var olho := p.camera.global_position
		var c := area.global_position
		p.head.rotation.x = atan2(c.y - olho.y, Vector2(c.x - olho.x, c.z - olho.z).length())
		await _s(0.3)
		print("ALVO ", nome, " mira=", p._target == area, " pode=", area.can_interact(p))
		area.interact(p)
		await _s(espera)
		await _shot("%s_%s" % [tag, nome])
	await passo.call(r.por_racao, Vector3(2.6, 0, -6.4), "1_racao", 2.0)
	await _until(func() -> bool: return not r._ocupado, 30.0)
	await _s(4.0)
	p.global_position = Vector3(1.0, 0, -6.4)
	await _olhar(p, Vector3(-1.0, 0, -8.0))
	p.head.rotation.x = -0.5
	await _s(0.5)
	await _shot("%s_1b_comendo" % tag)
	await passo.call(r.bombear, Vector3(5.4, 0, -11.6), "2_bomba", 3.0)
	await _until(func() -> bool: return not r._ocupado, 30.0)
	await passo.call(r.encher_bebedouro, Vector3(3.4, 0, -9.85), "3_bebedouro", 2.0)
	await _until(func() -> bool: return not r._ocupado, 30.0)
	await passo.call(r.pegar_lenha, Vector3(-11.0, 0, 3.6), "4_lenha", 1.0)
	await _until(func() -> bool: return not r._ocupado, 30.0)
	await _shot("%s_4b_bracada" % tag)
	await passo.call(r.por_lenha, Vector3(3.2, 0.6, 3.7), "5_lareira", 1.0)
	await _until(func() -> bool: return not r._ocupado, 30.0)
	await _shot("%s_5b_lareira" % tag)
	await passo.call(r.fechar_celeiro, Vector3(-15.0, 0, -5.5), "6_celeiro", 2.0)
	await _until(func() -> bool: return not r._ocupado, 30.0)
	await _shot("%s_6b_celeiro" % tag)
	print("ETAPA ", r.etapa)
	await _s(4.0)
	p.global_position = Vector3(-6.0, 0, -4.0)
	await _olhar(p, Vector3(-40, 0, -6))
	for k in 4:
		await _s(1.5)
		await _shot("%s_7_yautja_%d" % [tag, k])
	print("ETAPA ", r.etapa, " yautja fugiu=", faz.get_node("Caes/Yautja").fugiu)


## SHOT_MODO=matilha: no Interlúdio, a matilha viva (F4): os cães na tela do lado
## de Akeley com o balde, latindo; Brutus o seguindo; depois, sem o balde.
func _matilha_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"interludio")
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Entardecer", false)
	var faz := root.find_child("Fazenda", true, false) as Fazenda
	Engine.time_scale = 6.0
	await _until(func() -> bool: return not faz.descendo, 60.0)
	Engine.time_scale = 1.0
	var p := faz.player
	for k in 4:
		await _s(1.5)
		await _shot("%s_cerca_%d" % [tag, k])
	var brutus := faz.get_node("Caes/Brutus") as Node3D
	# Andando para o leste: Brutus vem atrás.
	p.look_at(Vector3(20, p.global_position.y, -9.5))
	Input.action_press(&"mover_frente")
	await _s(3.0)
	Input.action_release(&"mover_frente")
	await _s(1.5)
	p.look_at(Vector3(brutus.global_position.x, p.global_position.y, brutus.global_position.z))
	p.head.rotation.x = -0.4
	await _s(0.4)
	await _shot("%s_brutus" % tag)
	print("BRUTUS ", brutus.global_position, " AKELEY ", p.global_position)
	for c in faz.get_node("Caes").get_children():
		print("CAO ", c.name, " ", (c as Node3D).global_position, " pose ", (c.get_node("Visual") as Cao).pose)


## SHOT_MODO=caes: os cães (F4) em cada pose, no quintal, de lado, de frente e de
## perto; e um andando e um correndo.
func _caes_fotos() -> void:
	GameState.reset()
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Quintal", false)
	await _s(1.0)
	var faz := root.find_child("Fazenda", true, false) as Node3D
	var p := faz.find_child("Player", true, false) as Player
	var base := Vector3(14.0, 0.0, 6.0)
	var poses := [Cao.Pose.PARADO, Cao.Pose.SENTADO, Cao.Pose.DEITADO, Cao.Pose.LATINDO, Cao.Pose.ROSNANDO, Cao.Pose.COMENDO, Cao.Pose.PARADO, Cao.Pose.PARADO]
	var caes: Array[Cao] = []
	for i in poses.size():
		var c := Cao.new()
		c.name = "CaoTeste%d" % i
		c.pose = poses[i]
		c.andar = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.2][i]
		c.pelagem = [0.0, 0.5, -0.5, 0.2, -0.2, 0.8, -0.8, 0.0][i]
		faz.add_child(c)
		c.global_position = base + Vector3(i * 1.3, 0, 0)
		c.rotation.y = PI / 2.0
		caes.append(c)
	await _s(1.5)
	for vista: Array in [["lado", base + Vector3(4.5, 0, 4.2), base + Vector3(4.5, 0.4, 0)], ["frente", base + Vector3(-2.4, 0, 0.0), base + Vector3(4, 0.3, 0)],
			["perto", base + Vector3(0.6, 0, 1.6), base + Vector3(0.3, 0.45, 0)], ["alto", base + Vector3(4.5, 2.5, 3.0), base + Vector3(4.5, 0, 0)]]:
		p.global_position = vista[1]
		p.velocity = Vector3.ZERO
		await _s(0.2)
		var alvo: Vector3 = vista[2]
		p.look_at(Vector3(alvo.x, p.global_position.y, alvo.z))
		var olho := p.camera.global_position
		p.head.rotation.x = atan2(alvo.y - olho.y, Vector2(alvo.x - olho.x, alvo.z - olho.z).length())
		for k in 3:
			await _s(0.23)
			await _shot("%s_caes_%s_%d" % [tag, vista[0], k])


func _until_nivel(caminho: String) -> void:
	while SceneDirector.current_level != caminho or SceneDirector.is_busy:
		await get_tree().process_frame


## SHOT_MODO=documento, SHOT_DOCS=id1,id2: cada folha de cada documento, no leitor.
func _documento_fotos() -> void:
	await _s(1.0)
	var leitor := root.find_child("DocumentReader", true, false)
	for id in OS.get_environment("SHOT_DOCS").split(",", false):
		var doc := load("res://narrative/documents/%s.tres" % id) as DocumentData
		Events.document_requested.emit(doc)
		await _s(0.6)
		for k in leitor._pages.size():
			leitor._page = k
			leitor._show_page()
			await _s(0.4)
			await _shot("%s_%s_%d" % [tag, id, k])
		leitor.close()
		await _s(0.3)


## SHOT_MODO=migo: o mi-go (props/migo.gd) num palco neutro, de vários lados:
## voando, de pé com as asas recolhidas e em silhueta.
func _migo_fotos() -> void:
	await _s(1.0)
	var palco := Node3D.new()
	root.find_child("World", true, false).add_child(palco)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.32, 0.34, 0.38)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.55)
	e.ambient_light_energy = 0.6
	env.environment = e
	palco.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 30, 0)
	sol.light_energy = 1.3
	sol.shadow_enabled = true
	palco.add_child(sol)
	var m := Migo.new()
	m.position = Vector3(0, 50.0, 0)
	m.batida = float(OS.get_environment("SHOT_BATIDA")) if OS.has_environment("SHOT_BATIDA") else 0.0
	palco.add_child(m)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.environment = e
	palco.add_child(cam)
	cam.make_current()
	var vistas := [["lado", Vector3(3.2, 50.3, 0.0)], ["tres_quartos", Vector3(2.2, 50.8, -2.2)], ["frente", Vector3(0.2, 50.4, -3.0)],
		["cima", Vector3(0.6, 53.0, 0.4)], ["tras", Vector3(-1.8, 50.9, 2.4)], ["cabeca", Vector3(0.7, 50.3, -1.3)]]
	for v: Array in vistas:
		cam.position = v[1]
		cam.look_at(m.position + (Vector3(0, 0.05, -0.55) if v[0] == "cabeca" else Vector3.ZERO))
		await _s(0.4)
		await _shot("%s_%s" % [tag, v[0]])
	m.batida = 0.45
	for k in 4:
		cam.position = Vector3(2.4, 50.6, -1.6)
		cam.look_at(m.position)
		await _s(0.11)
		await _shot("%s_voo_%d" % [tag, k])
	m.batida = 0.0
	m.recolhidas = true
	m.rotation_degrees = Vector3(-78, 0, 0)
	m.position = Vector3(0, 50.8, 0)
	await _s(1.2)
	cam.position = Vector3(1.6, 50.8, -2.6)
	cam.look_at(m.position + Vector3(0, 0.1, 0))
	await _s(0.3)
	await _shot("%s_de_pe" % tag)
	m.silhueta = true
	e.background_color = Color(0.25, 0.3, 0.4)
	await _s(0.3)
	await _shot("%s_silhueta" % tag)


## SHOT_MODO=pessoa: o funcionário (Pessoa, colete) e o cultista (manto), num
## palco neutro: de frente, a três quartos, de lado e o rosto de perto.
func _pessoa_fotos() -> void:
	await _s(1.0)
	var palco := Node3D.new()
	root.find_child("World", true, false).add_child(palco)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.32, 0.34, 0.38)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.55)
	e.ambient_light_energy = 0.5
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, -30, 0)
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	palco.add_child(sol)
	var a := Pessoa.new()
	a.position = Vector3(-0.6, 50.0, 0)
	a.pose = Pessoa.Pose.MAO_NA_PORTA
	palco.add_child(a)
	var b := Pessoa.new()
	b.position = Vector3(0.6, 50.0, 0)
	b.manto = true
	b.pose = Pessoa.Pose.MAOS_JUNTAS
	b.pele = Color(0.62, 0.58, 0.55)
	palco.add_child(b)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.environment = e
	palco.add_child(cam)
	cam.make_current()
	var vistas := [["frente", Vector3(0, 51.1, -3.6), Vector3(0, 50.95, 0)], ["tres_quartos", Vector3(2.4, 51.2, -2.8), Vector3(0, 50.95, 0)],
		["lado", Vector3(3.6, 51.1, 0.0), Vector3(0, 50.95, 0)], ["rosto", Vector3(-0.45, 51.66, -0.55), Vector3(-0.6, 51.64, 0)],
		["rosto_lado", Vector3(-0.1, 51.66, -0.35), Vector3(-0.6, 51.64, 0)], ["capuz", Vector3(0.75, 51.6, -0.7), Vector3(0.6, 51.62, 0)],
		["tronco", Vector3(-0.4, 51.3, -1.2), Vector3(-0.6, 51.2, 0)], ["cultista_lado", Vector3(2.0, 51.2, -0.6), Vector3(0.6, 51.0, 0)]]
	for v: Array in vistas:
		cam.position = v[1]
		cam.look_at(v[2])
		await _s(0.4)
		await _shot("%s_%s" % [tag, v[0]])


## SHOT_MODO=percurso: anda por toda a fazenda (playtest 11: "vários locais onde
## não passamos"): cada cômodo da casa, nos dois andares, e as dependências. De
## cada ponto de partida, anda pelos pontos; diz onde chegou e onde ficou preso.
func _percurso_fazenda() -> void:
	GameState.reset()
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Quintal", false)
	await _s(1.0)
	var faz := root.find_child("Fazenda", true, false) as Node3D
	var p := faz.find_child("Player", true, false) as Player
	var T0 := 0.6
	var T1 := 3.75
	var rotas := [
		["porta da frente", Vector3(10, 0, 0), [Vector3(7.5, 0, 0), Vector3(4.5, 0, 0)], T0],
		["escritorio", Vector3(4.5, T0, 0), [Vector3(5.1, 0, 0.3), Vector3(5.1, 0, 2.0), Vector3(4.2, 0, 2.6)], T0],
		["escritorio > lareira", Vector3(4.2, T0, 2.6), [Vector3(2.5, 0, 2.6), Vector3(2.3, 0, 3.2)], T0],
		["sala de estar", Vector3(4.5, T0, 0), [Vector3(5.1, 0, -0.3), Vector3(5.1, 0, -2.0), Vector3(4.4, 0, -2.8)], T0],
		["sala de jantar", Vector3(0.0, T0, 0), [Vector3(-1.5, 0, 0.3), Vector3(-1.5, 0, 2.0), Vector3(-2.3, 0, 2.6)], T0],
		["sala dos fundos", Vector3(0.0, T0, 0), [Vector3(-1.5, 0, -0.3), Vector3(-1.5, 0, -2.0), Vector3(-1.0, 0, -3.8)], T0],
		["escritorio > jantar", Vector3(3.0, T0, 2.2), [Vector3(1.6, 0, 2.15), Vector3(0.3, 0, 2.15)], T0],
		["jantar > cozinha", Vector3(-1.5, T0, 2.0), [Vector3(-2.4, 0, 2.6), Vector3(-2.4, 0, 3.7), Vector3(-4.0, 0, 3.7), Vector3(-4.6, 0, 2.2)], T0],
		["cozinha > despensa", Vector3(-4.6, T0, 2.2), [Vector3(-7.0, 0, 2.0), Vector3(-8.0, 0, 2.0)], T0],
		["cozinha > quintal de tras", Vector3(-6.5, T0, 2.2), [Vector3(-6.5, 0, 1.3), Vector3(-6.5, 0, -0.5)], 0.0],
		["cozinha > galpao", Vector3(-6.8, T0, 4.6), [Vector3(-8.6, 0, 4.6), Vector3(-10.5, 0, 4.6)], 0.0],
		["porta dos fundos", Vector3(0.0, T0, 0), [Vector3(-2.6, 0, 0), Vector3(-4.6, 0, 0)], 0.0],
		["escada", Vector3(4.9, T0, -0.9), [Vector3(-0.3, 0, -0.9), Vector3(-0.3, 0, 0.6)], T1],
		["quarto de hospedes", Vector3(-0.3, T1, 0.6), [Vector3(3.0, 0, 0.6), Vector3(3.0, 0, 2.2), Vector3(3.5, 0, 3.5)], T1],
		["quarto de Akeley", Vector3(-0.3, T1, 0.6), [Vector3(4.9, 0, 0.6), Vector3(5.1, 0, -0.9), Vector3(5.1, 0, -2.2), Vector3(2.5, 0, -3.3)], T1],
		["quarto de tras sul", Vector3(-0.3, T1, 0.6), [Vector3(-0.38, 0, 0.9), Vector3(-0.38, 0, 2.2), Vector3(-1.5, 0, 3.5)], T1],
		["quarto de tras norte", Vector3(-0.3, T1, 0.6), [Vector3(-0.38, 0, -0.9), Vector3(-0.38, 0, -2.2), Vector3(-1.5, 0, -3.5)], T1],
		["banheiro", Vector3(-0.3, T1, 0.0), [Vector3(-1.4, 0, 0.0), Vector3(-1.85, 0, -0.2)], T1],
		["celeiro", Vector3(-15, 0, -2), [Vector3(-15, 0, -6.5), Vector3(-15, 0, -12), Vector3(-14, 0, -14)], 0.0],
		["galinheiro", Vector3(-25.5, 0, -8), [Vector3(-25.5, 0, -10.4), Vector3(-24, 0, -15)], 0.0],
		["galpao de lenha", Vector3(-11.9, 0, -1), [Vector3(-11.9, 0, 1.6), Vector3(-11.9, 0, 3.0)], 0.0],
		["canil (por fora)", Vector3(8, 0, -8), [Vector3(2, 0, -6.2), Vector3(-3, 0, -6.2)], 0.0],
		["moinho e ford", Vector3(10, 0, -5), [Vector3(14, 0, -12), Vector3(18, 0, -15)], 0.0],
		["estrada", Vector3(10, 0, 0), [Vector3(20, 0, 1), Vector3(30.5, 0, 2)], 0.0],
	]
	var falhas := 0
	for r: Array in rotas:
		p.global_position = r[1]
		p.velocity = Vector3.ZERO
		await _s(0.3)
		var t := 0.0
		var preso := ""
		for alvo: Vector3 in r[2]:
			var antes := p.global_position
			var parado := 0.0
			while t < 25.0:
				var q := p.global_position
				var rumo := Vector3(alvo.x, q.y, alvo.z)
				if q.distance_to(rumo) < 0.3:
					break
				p.look_at(rumo)
				Input.action_press(&"mover_frente")
				await get_tree().physics_frame
				var dt := get_physics_process_delta_time()
				t += dt
				parado = parado + dt if p.global_position.distance_to(q) < 0.004 else 0.0
				if parado > 1.0:
					preso = "preso em %s indo para %s" % [p.global_position.snappedf(0.01), alvo]
					break
			if not preso.is_empty():
				break
		Input.action_release(&"mover_frente")
		var fim: Vector3 = r[2][r[2].size() - 1]
		var chegou: bool = preso.is_empty() and Vector2(p.global_position.x - fim.x, p.global_position.z - fim.z).length() < 0.5 and absf(p.global_position.y - float(r[3])) < 0.3
		if not chegou:
			falhas += 1
		print("PERCURSO %s %s %s" % ["ok   " if chegou else "FALHA", r[0], preso if preso else str(p.global_position.snappedf(0.01))])
		if not chegou:
			await _shot("%s_preso_%s" % [tag, String(r[0]).replace(" ", "_").replace(">", "a")])
	print("PERCURSO falhas: ", falhas)


## SHOT_MODO=guia: a luz-guia da fazenda (playtest 11) na rotina e na preparação.
func _guia_fotos() -> void:
	GameState.reset()
	GameState.set_flag(&"interludio")
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Entardecer", false)
	var faz := root.find_child("Fazenda", true, false) as Fazenda
	Engine.time_scale = 6.0
	await _until(func() -> bool: return not faz.descendo, 60.0)
	Engine.time_scale = 1.0
	var p := faz.player
	var guia := faz.get_node("LuzGuia") as LuzGuia
	for v: Array in [["racao", Vector3(9, 0, -13), Vector3(-1.35, 1.0, -7.0)], ["racao_meio", Vector3(4, 0, -11), Vector3(-1.35, 1.0, -7.0)]]:
		p.global_position = v[1]
		await _mirar(p, v[2])
		await _s(1.6)
		print("GUIA ", v[0], " vis=", guia.visible, " em ", guia.global_position)
		await _shot("%s_%s" % [tag, v[0]])
	faz.rotina.pular()
	await _until(func() -> bool: return faz.preparacao._ativa, 30.0)
	for v: Array in [["prep_quintal", Vector3(12, 0, 9), guia.global_position], ["prep_dentro", Vector3(2.4, 0.6, 3.0), guia.global_position]]:
		p.global_position = v[1]
		await _s(0.5)
		await _mirar(p, guia.global_position)
		await _s(1.6)
		print("GUIA ", v[0], " vis=", guia.visible, " em ", guia.global_position)
		await _shot("%s_%s" % [tag, v[0]])
