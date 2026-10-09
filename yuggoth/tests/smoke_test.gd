extends Node
## Teste de fumaça do M0. Rodar com:
##   godot --headless --path . res://tests/smoke_test.tscn
## Sai com código = número de falhas.

var _failures := 0


const TEST_SAVE := "user://smoke_test_save.json"
const TEST_SETTINGS := "user://smoke_test_settings.cfg"


func _ready() -> void:
	SaveSystem.save_path = TEST_SAVE
	SaveSystem.delete_save()
	Settings.settings_path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)

	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	root.start_level = load("res://levels/test/test_room.tscn")
	add_child(root)
	if SceneDirector.is_busy:
		await SceneDirector.level_changed
	await _frames(3)

	var player: Player = root.find_child("Player", true, false)
	var pickup: DocumentPickup = root.find_child("Pickup", true, false)
	var sleep: StateInteractable = root.find_child("Sleep", true, false)
	var reader: Control = root.get_node("UI/DocumentReader")
	var carta: DocumentData = load("res://tests/fixtures/teste_carta.tres")

	_check(carta.resolve_pages()[1].contains("não me responda"), "carta começa no texto original")

	# Mirar a carta sobre a mesa pelo raycast.
	player.global_position = Vector3(-0.3, 0.0, -1.3)
	player.rotation = Vector3.ZERO
	player.head.rotation.x = deg_to_rad(-45.0)
	await _frames(4)
	_check(player._target == pickup, "raycast encontra a carta")

	pickup.interact(player)
	await _frames(1)
	_check(reader.visible, "leitor abre")
	_check(not player.input_enabled, "player bloqueado durante leitura")
	_check(carta in GameState.dossier, "carta vai para o dossiê")
	_check(GameState.has_flag(&"leu_teste_carta"), "flag de leitura marcada")

	reader.close()
	await _frames(1)
	_check(player.input_enabled, "player liberado ao fechar")

	sleep.interact(player)
	_check(GameState.get_value(&"dia") == 2, "dormir avança o dia")
	_check(carta.resolve_pages()[1].contains("Peço apenas que venha"), "variante do dia 2 ativa")
	_check(is_equal_approx(GameState.get_number(&"exposicao"), 0.3), "exposição acumulada (0.05 + 0.25)")

	GameState.add(&"crenca", 99)
	_check(GameState.get_value(&"crenca") == 4, "crença grampeada em +4")

	# --- Examinable ---
	var examine: Examinable = root.find_child("Examine", true, false)
	var viewer: Control = root.get_node("UI/ExamineViewer")
	examine.interact(player)
	await _frames(1)
	_check(viewer.visible, "visualizador abre")
	_check(not player.input_enabled, "player bloqueado ao examinar")
	await _seconds(1.0)
	_check(not GameState.has_flag(&"viu_garra_na_pegada"), "detalhe não aparece de longe")
	viewer._zoom = 1.0
	await _seconds(1.0)
	_check(GameState.has_flag(&"viu_garra_na_pegada"), "detalhe encontrado de perto")
	_check(viewer.caption.text.begins_with("Não é casco"), "legenda mostra o detalhe")
	viewer.close()
	await _frames(1)
	_check(player.input_enabled, "player liberado ao devolver")
	_check(is_instance_valid(examine.get_visual()), "original continua na cena")

	# --- Narrator ---
	var linha: NarrationLine = load("res://tests/fixtures/teste_quarto_vazio.tres")
	var silhueta: Node3D = root.find_child("Silhouette", true, false)
	var caption: RichTextLabel = root.get_node("Narration/NarrationView").caption
	GameState.set_value(&"exposicao", 0.2)
	_check(not silhueta.visible, "silhueta escondida de início")

	player.global_position = Vector3(-2.0, 0.0, 2.0)
	await _frames(4)
	_check(GameState.has_flag(linha.get_said_flag()), "gatilho fala a linha ao entrar")
	_check(caption.visible and caption.text.begins_with("O quarto estava vazio"), "legenda mostra a linha")
	_check(not GameState.has_flag(linha.get_discrepancy_flag()), "sem discrepância com exposição baixa")
	_check(not silhueta.visible, "silhueta continua escondida")

	GameState.set_value(&"exposicao", 0.9)
	GameState.set_value(&"discrepancias", Narrator.MAX_DISCREPANCIES)
	Narrator.resolve(linha)
	_check(not GameState.has_flag(linha.get_discrepancy_flag()), "limite de discrepâncias respeitado")

	GameState.set_value(&"discrepancias", 0)
	Narrator.resolve(linha)
	_check(GameState.has_flag(linha.get_discrepancy_flag()), "exposição alta vira discrepância")
	_check(GameState.get_value(&"discrepancias") == 1, "discrepância contada")
	_check(silhueta.visible, "cena contradiz o narrador (silhueta aparece)")

	var mentira := NarrationLine.new()
	mentira.id = &"teste_mentira"
	mentira.text = "A porta estava aberta."
	mentira.discrepancy_exposure = 0.0
	mentira.discrepancy_text = "A porta estava trancada."
	_check(Narrator.resolve(mentira) == "A porta estava trancada.", "texto de discrepância substitui o normal")

	var card: RichTextLabel = root.get_node("Narration/NarrationView").card
	Narrator.say(mentira, Narrator.Style.CARTAO)
	Narrator.say(linha)  # fica na fila
	await _frames(2)
	Narrator.cancel()
	await _frames(2)
	_check(not card.visible and not caption.visible, "cancelar apaga a narração da tela")
	await _seconds(0.5)
	_check(not caption.visible and not card.visible, "fala que estava na fila é descartada")

	# --- SaveSystem ---
	_check(SaveSystem.has_save(), "autosave ao carregar a fase inicial")
	SaveSystem.checkpoint()
	GameState.reset()
	_check(GameState.get_value(&"dia") == 1, "estado zerado antes de carregar")
	_check(await SaveSystem.load_game(), "load_game encontra o save")
	_check(GameState.get_value(&"dia") is int and GameState.get_value(&"dia") == 2, "dia volta como int 2")
	_check(GameState.get_value(&"exposicao") is float, "exposição volta como float")
	_check(GameState.has_flag(&"leu_teste_carta"), "flag de leitura restaurada")
	_check(carta in GameState.dossier, "dossiê restaurado")
	await _frames(1)
	_check(root.get_node("WorldContainer/World").get_child_count() == 1, "fase antiga liberada")

	# --- SceneDirector: ponto de entrada ---
	await SceneDirector.change_level("res://levels/test/test_room.tscn", &"Cama")
	_check(SceneDirector.current_spawn == &"Cama", "spawn atual registrado")
	await _frames(1)
	player = root.find_child("Player", true, false)
	_check(player.global_position.distance_to(Vector3(1.2, 0.0, 1.5)) < 0.05, "player posicionado no spawn")
	_check(not get_tree().paused, "árvore despausada após a troca")

	# --- Settings ---
	var master := AudioServer.get_bus_index(&"Master")
	for bus: StringName in [&"Music", &"Ambience", &"SFX", &"Voice", &"Whisper"]:
		_check(AudioServer.get_bus_index(bus) >= 0, "bus %s existe" % bus)
	Settings.set_value(&"volume_Master", 0.5)
	_check(is_equal_approx(AudioServer.get_bus_volume_db(master), linear_to_db(0.5)), "volume aplicado ao bus")
	Settings.set_value(&"sensibilidade", 2)
	_check(Settings.get_value(&"sensibilidade") is float, "preferência mantém o tipo")
	Settings.save_settings()
	Settings.reset_to_defaults()
	Settings.load_settings()
	_check(is_equal_approx(Settings.get_value(&"volume_Master"), 0.5), "preferências gravadas e relidas")
	Settings.reset_to_defaults()

	# --- AudioDirector ---
	var chuva := AudioStreamGenerator.new()
	var relogio := AudioStreamGenerator.new()
	AudioDirector.play_ambience(chuva, 0.1)
	_check(AudioDirector.get_ambience() == chuva, "ambiente toca")
	AudioDirector.play_ambience(relogio, 0.1)
	_check(AudioDirector.get_ambience() == relogio, "crossfade troca o ambiente")
	AudioDirector.set_hum(AudioStreamGenerator.new(), 0.1)
	GameState.set_value(&"exposicao", 1.0)
	await _seconds(1.0)
	_check(AudioDirector.is_hum_on(), "zumbido ligado")
	_check(AudioDirector._lowpass.cutoff_hz > 2000.0, "exposição abre o filtro do zumbido")

	# --- Pausa e menus ---
	var pause: PauseMenu = root.get_node("Menus/PauseMenu")
	var main_menu: MainMenu = root.get_node("Menus/MainMenu")
	await _press(&"ui_cancel")
	_check(pause.visible and get_tree().paused, "Esc abre a pausa e congela o jogo")
	_check(Events.is_modal_open, "pausa é modal")
	await _press(&"ui_cancel")
	_check(not pause.visible and not get_tree().paused, "Esc de novo despausa")

	Events.document_requested.emit(carta)
	await _frames(1)
	await _press(&"ui_cancel")
	_check(not reader.visible and not pause.visible, "Esc fecha o leitor sem abrir a pausa")

	await root.quit_to_menu()
	await _frames(1)
	_check(main_menu.visible and SceneDirector.current_level.is_empty(), "voltar ao menu descarrega a fase")
	_check(root.get_node("WorldContainer/World").get_child_count() == 0, "mundo vazio no menu")
	await _press(&"ui_cancel")
	_check(not pause.visible, "pausa não abre no menu principal")
	_check(AudioDirector.get_ambience() == null, "ambiente para no menu")

	await root.new_game()
	_check(not main_menu.visible and SceneDirector.current_level != "", "novo jogo carrega a fase")
	_check(GameState.get_value(&"dia") == 1 and GameState.dossier.is_empty(), "novo jogo zera o estado")

	# --- Visual: firme → sonho ---
	await _frames(2)
	_check(is_zero_approx(root.dream_level), "mundo firme com exposição 0")
	GameState.set_value(&"sonho", 1.0)
	await _frames(2)
	_check(is_equal_approx(root.dream_level, 1.0), "sonho liga a estética crua")
	GameState.set_value(&"sonho", 0.0)
	GameState.set_value(&"exposicao", 1.0)
	await _seconds(1.0)
	_check(root.dream_level > 0.5, "exposição alta também quebra o visual")
	GameState.set_value(&"exposicao", 0.0)

	# --- Escritório: Prólogo (GDD §5.0) ---
	GameState.reset()
	Engine.time_scale = 8.0
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	player = esc.player
	_check(esc.gabinete.visible and not esc.miskatonic.visible, "Prólogo abre no gabinete de 1930")
	_check(player.seated and not player.lamp.available, "Wilmarth sentado, sem lamparina na mão")
	_check(SceneDirector.hold_black, "tela preta segura para o cartão")
	await _until(func() -> bool: return not SceneDirector.hold_black, 30.0)
	_check(not SceneDirector.hold_black, "cartão termina e a sala aparece")
	_check(AudioDirector.get_ambience() == esc.som_chuva, "chuva no gabinete")
	player.stand()
	_check(not player.seated, "levantar da cadeira")
	_check(not esc.caixa.can_interact(player), "a caixa de cartas espera a folha do relato")
	esc.gabinete.get_node("Folha/Ler").interact(player)
	await _frames(2)
	_check(reader.visible, "ler a folha do relato")
	reader.close()
	await _frames(1)
	_check(esc.caixa.can_interact(player), "lido o relato, a caixa de cartas abre")
	Events.examine_closed.emit(esc.caixa)
	await _until(func() -> bool: return GameState.has_flag(&"prologo_concluido") \
		and is_zero_approx(GameState.get_number(&"sonho")), 40.0)
	_check(GameState.has_flag(&"prologo_concluido"), "examinar a caixa leva a maio")
	_check(esc.miskatonic.visible and not esc.gabinete.visible, "a sala vira o escritório da Miskatonic")
	_check(GameState.get_value(&"dia") == 1, "começa o Dia 1")
	await _until(func() -> bool: return not SceneDirector.hold_black, 10.0)
	_check(not SceneDirector.hold_black, "luz da tarde depois do cartão de maio")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	esc = root.find_child("Escritorio", true, false)
	_check(esc.miskatonic.visible and not esc.player.seated, "recarregar depois do Prólogo vai direto ao escritório")
	await _frames(2)
	_check(esc._fora() and not esc.calha.porta_aberta and esc.calha.corredor.visible and esc.porta_fora.can_interact(esc.player)
		and not esc.porta.can_interact(esc.player), "o dia começa no corredor, diante da porta fechada")
	await _check_dia(esc, 1)
	_check(not esc._fora() and not esc.calha.porta_aberta and not esc.calha.corredor.visible, "entrou: a porta fecha atrás dele")

	# --- Escritório: Dia 1 (GDD §5.1) ---
	player = esc.player
	var carta1: DocumentData = load("res://narrative/documents/carta_akeley_1.tres")
	var escrever: WriteReply = esc.find_child("Escrever", true, false)
	var writer: Control = root.get_node("UI/ReplyWriter")
	_check(not escrever.can_interact(player), "responder só depois de ler a carta")
	await _porta(esc)
	_check(GameState.get_value(&"dia") == 1 and not esc._saindo, "porta não leva para casa sem resposta")

	# O correio pela fresta: do chão para a mão, da mão para a mesa, e aberto.
	var dia1: Node3D = esc.find_child("Dia1", true, false)
	var correio1: Correspondencia = dia1.get_node("Envelope/Correio")
	var mesa: MesaCorreio = esc.get_node(^"%PorNaMesa")
	var carta_mesa: Node3D = dia1.get_node("Carta")
	_check(correio1.get_visual().global_position.distance_to(Vector3(-1.0, 0.0, 2.3)) < 1.0 \
		and not carta_mesa.visible, "Dia 1: a carta chega fechada, no chão junto à porta")
	_check(correio1.prompt == "Pegar o correio" and not mesa.can_interact(player) and not mesa.visible, "sem nada na mão, a mesa não pede nada")
	var no_chao := correio1.get_visual().global_position
	correio1.interact(player)
	await _frames(1)
	_check(correio1.get_visual().global_position.distance_to(no_chao) < 0.6, "pegar o correio: o envelope sobe do chão (sem teleporte)")
	await _until(func() -> bool: return correio1.get_visual().global_position.distance_to(player.camera.global_position) < 0.6, 3.0)
	_check(Correspondencia.na_mao == [correio1] and correio1.get_visual().global_position.distance_to(player.camera.global_position) < 0.6,
		"pegar o correio: o envelope na mão")
	_check(mesa.can_interact(player) and mesa.visible and not correio1.visible, "na mão: mirar a mesa para pôr o envelope")
	mesa.interact(player)
	await _frames(1)
	_check(not correio1.get_visual().transform.is_equal_approx(correio1.mesa), "pôr na mesa: o envelope viaja da mão até lá")
	await _until(func() -> bool: return correio1.get_visual().transform.is_equal_approx(correio1.mesa), 3.0)
	_check(Correspondencia.na_mao.is_empty() and correio1.get_visual().transform.is_equal_approx(correio1.mesa) \
		and correio1.prompt == "Abrir com a espátula" and not mesa.visible, "pôr na mesa: o envelope no lugar dele")
	_check(not carta_mesa.visible, "fechado, a carta continua no envelope")
	correio1.interact(player)
	await _frames(2)
	_check(carta_mesa.visible and (correio1.get_visual() as Envelope).aberto and correio1.prompt == "Examinar o envelope",
		"aberto com a espátula: a carta sai para a mesa")
	await _check_alcance(esc, "Dia 1, carta aberta")
	var ler_carta: DocumentPickup = carta_mesa.get_node("Ler")
	ler_carta.interact(player)
	await _until(func() -> bool: return AudioDirector._duck.volume_db < -10.0, 5.0)
	_check(AudioDirector._duck.volume_db < -10.0, "lendo, o ambiente (os pássaros) abaixa")
	reader.close()
	_check(carta1 in GameState.dossier and GameState.has_flag(&"leu_carta_akeley_1"), "carta do Dia 1 lida e no dossiê")
	reader.open(carta1)
	for i in 3:  # a paginação roda no quadro de processo seguinte
		await get_tree().process_frame
	var cabe := true
	for i in reader._pages.size():
		reader._page = i
		reader._show_page()
		if reader.body.get_content_height() > reader.body.size.y + 1:
			cabe = false
	# Na letra estreita de Akeley (Tangerine) cada página do livro já cabe numa folha.
	_check(cabe and reader._pages.size() >= carta1.pages.size(), "carta longa paginada sem estourar o papel")
	reader.close()
	_check(escrever.can_interact(player), "depois de ler, dá para responder")
	escrever.interact(player)
	await _frames(1)
	_check(writer.visible and not player.input_enabled, "tela de escrita abre como modal")
	writer._choose(escrever.reply.options[0])
	await _frames(1)
	await _press(&"ui_cancel")
	_check(writer.visible and writer._chosen == null and writer.choices.visible, "Esc amassa a folha: de volta às aberturas")
	_check(GameState.get_value(&"resposta_dia_1") == null and not escrever.reply.is_done(), "recomeçar não decide nada")
	writer._choose(escrever.reply.options[2])
	writer._finish_writing()
	writer._seal()
	await _frames(1)
	_check(writer.visible and GameState.get_value(&"resposta_dia_1") == 1, "selar decide na hora; a folha some da tela")
	await _until(func() -> bool: return esc.selando, 10.0)
	_check(not writer.visible and esc.selando and not player.input_enabled, "a carta é dobrada e selada na mesa; Wilmarth parado")
	var selagem: Selagem = esc.find_child("Selagem", true, false)
	_check(selagem != null and (selagem.get_node("Envelope") as Envelope).destinatario.contains("Townshend"), "o envelope endereçado a Townshend")
	await _until(func() -> bool: return (selagem.get_node("Envelope") as Envelope).selos == 1, 30.0)
	_check((selagem.get_node("Envelope") as Envelope).selos == 1, "o selo batido no envelope")
	await _porta(esc)
	_check(GameState.get_value(&"dia") == 1 and not esc._saindo, "selando, a porta espera")
	await _until(func() -> bool: return not esc.selando, 30.0)
	await _frames(1)
	_check(not esc.selando and player.input_enabled, "selada, Wilmarth volta a andar")
	var carta_saida := CartaSaida.atual
	_check(carta_saida != null and carta_saida.global_position.distance_to(player.camera.global_position) < 0.6,
		"a carta selada vai para a mão")
	_check(esc.porta.prompt == "Abrir a porta" and not esc.por_na_calha.can_interact(player), "com a carta na mão, abrir a porta")
	_check(GameState.get_value(&"crenca") == 1 and GameState.get_value(&"resposta_dia_1") == 1, "resposta crédula: crença +1 e tom gravado")
	_check(escrever.reply.options[2].document in GameState.dossier, "a resposta escrita vai para o dossiê")
	_check(not escrever.can_interact(player), "não dá para responder duas vezes")
	esc.porta.interact(player)
	await _until(func() -> bool: return esc.calha.folha.rotation_degrees.y > 10.0, 10.0)
	_check(esc.calha.corredor.visible and not player.input_enabled, "a porta abre para o corredor")
	await _until(func() -> bool: return esc.calha.porta_aberta and player.input_enabled, 20.0)
	await _frames(2)
	_check(player.input_enabled and esc.calha.porta_aberta and esc.por_na_calha.can_interact(player) and CartaSaida.atual != null,
		"aberta, o corredor é dele: \"Pôr a carta na calha\"")
	await _frames(10)
	_check(esc.calha.porta_aberta, "a porta não fecha enquanto ele não sai e volta")
	esc.por_na_calha.interact(player)
	await _frames(2)
	_check(esc.postando and not player.input_enabled, "a carta vai à boca da calha")
	await _until(func() -> bool: return not esc.postando, 30.0)
	await _frames(2)
	_check(player.input_enabled and CartaSaida.atual == null and esc._fora() and esc.calha.porta_aberta, "a carta desce pela calha; ele fica no corredor")
	await _entrar(esc)
	_check(not esc.calha.corredor.visible and is_zero_approx(esc.calha.folha.rotation_degrees.y) and player.input_enabled,
		"de volta à sala, a porta fecha sozinha")
	_check(GameState.get_value(&"dia") == 1 and GameState.get_value(&"diario") == 1 and not esc._saindo and CartaSaida.atual == null,
		"postada a resposta, o dia não acaba: falta o diário")
	await _porta(esc)
	_check(GameState.get_value(&"dia") == 1 and not esc._saindo, "sem o diário, a porta não leva para casa")
	var anotar: Interactable = esc.diario.get_node("Anotar")
	_check(anotar.can_interact(player) and anotar.is_visible_in_tree(), "o caderno na mesa: \"Anotar o dia\"")
	await _anotar(esc)
	await _until(func() -> bool: return esc.diario.aberto, 45.0)
	_check(esc.diario.aberto and player.seated, "Wilmarth senta e o diário abre diante dele")
	var entrada1: DocumentData = esc.diario_entradas[1]
	_check(entrada1 in GameState.dossier, "a entrada do dia vai para o dossiê")
	_check(esc.bebida.xicara.get_node("Nivel").visible, "antes de anotar o dia, o café na xícara")
	await _ir_para_casa(esc)
	await _until(func() -> bool: return GameState.get_value(&"dia") == 2 and not SceneDirector.hold_black and not esc._saindo, 60.0)
	_check(GameState.get_value(&"dia") == 2, "anotado o dia (sem sonho), ir para casa avança para o Dia 2")
	_check(not esc.diario.aberto and not player.seated and esc.diario.transform.is_equal_approx(esc.diario._casa), "o caderno de volta ao lugar, fechado")
	_check(not esc.find_child("Dia1", true, false).visible, "objetos do Dia 1 somem no Dia 2")
	_check(SaveSystem.has_save(), "checkpoint no começo do dia")

	# --- Escritório: Dia 2 (GDD §5.1, livro cap. II) ---
	var dia2: Node3D = esc.find_child("Dia2", true, false)
	var fotos: Node3D = esc.find_child("Fotografias", true, false)
	var lista_fotos: Array[Node] = fotos.find_children("*", "Fotografia", false, false)
	_check(dia2.visible and lista_fotos.size() == 9, "as nove fotografias do livro")
	_check(lista_fotos.all(func(f: Node3D) -> bool: return not f.visible), "Dia 2: as fotografias ainda no envelope")
	await _check_dia(esc, 2)
	var correio2: Correspondencia = dia2.get_node("Envelope/Correio")
	correio2.interact(player)
	await _frames(1)
	_check(Correspondencia.na_mao == [correio2], "Dia 2: o envelope gordo na mão")
	await _abrir_correio(esc, correio2)
	_check(dia2.get_node("Carta").visible and correio2.prompt == "Tirar uma fotografia", "aberto: a carta na mesa; as fotos esperam no envelope")
	var lugar_foto: Vector3 = lista_fotos[0].position
	correio2.interact(player)
	await _frames(1)
	_check(lista_fotos[0].visible and not lista_fotos[1].visible, "tirar uma fotografia: uma por vez")
	await _until(func() -> bool: return lista_fotos[0].position.is_equal_approx(lugar_foto), 5.0)
	_check(lista_fotos[0].position.is_equal_approx(lugar_foto), "a fotografia vai para o lugar dela na mesa")
	for i in 8:
		correio2.interact(player)
	await _seconds(0.6)
	_check(lista_fotos.all(func(f: Node3D) -> bool: return f.visible) and correio2.prompt == "Examinar o envelope", "as nove fotografias na mesa")
	await _check_alcance(esc, "Dia 2, fotos na mesa")
	_check(not esc.relogio.playing, "o relógio da parede parou")
	_check(esc.world_env.environment == esc.ambientes_dia[2], "entardecer no Dia 2")
	var envelope: Envelope = dia2.get_node("Envelope")
	_check(envelope.has_node(^"_Selo1") and envelope.has_node(^"_Carimbo"), "envelope com dois selos e carimbo")
	var deixar: StateInteractable = esc.find_child("DeixarSemResposta", true, false)
	_check(not deixar.can_interact(player), "debate só se encerra depois da 2ª carta")
	var ler2: DocumentPickup = dia2.get_node("Carta/Ler")
	ler2.interact(player)
	await _frames(2)
	reader.close()
	await _until(func() -> bool: return GameState.has_flag(&"narrou_ao_ler_carta_akeley_2"), 30.0)
	_check(GameState.has_flag(&"narrou_ao_ler_carta_akeley_2"), "narrador reage à 2ª carta")
	deixar.interact(player)
	await _frames(2)
	_check(GameState.has_flag(&"debate_encerrado") and not esc.find_child("Debate", true, false).visible, "debate encerrado: rascunho e opositores somem")
	var viewer2: Control = root.get_node("UI/ExamineViewer")
	var caverna: Examinable = fotos.get_node("Foto2/Examinar")
	caverna.interact(player)
	await _seconds(1.0)
	_check(not GameState.has_flag(&"viu_rastros_caverna"), "rastros da caverna não aparecem de longe")
	viewer2._zoom = 1.0
	viewer2._pan_target = Vector2(0.0, 0.35)
	await _seconds(2.0)
	_check(GameState.has_flag(&"viu_rastros_caverna"), "com a lupa, os rastros diante da caverna")
	viewer2.close()
	await _frames(2)
	var escrever2: WriteReply = dia2.get_node("Escrever")
	escrever2.interact(player)
	await _frames(1)
	writer._choose(escrever2.reply.options[2])
	writer._finish_writing()
	await _selar(esc, writer)
	_check(GameState.get_value(&"crenca") == 2, "duas respostas crédulas: crença 2")
	await _porta(esc)
	await _sonho_no_teste(esc, 2, func() -> void: esc.player.global_position = Vector3(-1.0, 0, 2.4))
	await _until(func() -> bool: return GameState.get_value(&"dia") == 3 and not SceneDirector.hold_black and not esc._saindo, 45.0)
	_check(GameState.get_value(&"dia") == 3 and fotos.visible and not dia2.visible, "Dia 3: as fotografias ficam, a carta do Dia 2 não")

	# --- Escritório: Dia 3, o disco (livro cap. III) ---
	var fono: Fonografo = esc.fonografo
	var escrever3: WriteReply = esc.find_child("Dia3", true, false).get_node("Escrever")
	_check(fono.is_visible_in_tree() and fono.prompt == "Examinar o fonógrafo", "a máquina emprestada chega montada; o cilindro ainda no pacote")
	await _check_dia(esc, 3)
	_check(not escrever3.can_interact(player), "responder só depois de ouvir o disco")
	# Como o jogador: diante da mesinha do fonógrafo, mirar a máquina.
	player.global_position = esc.find_child("DianteDisco", true, false).global_position
	await _mirar(player, fono.global_position)
	_check(player._target == fono, "a mira alcança o fonógrafo na mesinha dele")
	fono.interact(player)
	_check(not GameState.has_flag(&"fono_cilindro"), "sem abrir o pacote, não há cilindro")
	var dia3: Node3D = esc.find_child("Dia3", true, false)
	var pacote: Correspondencia = dia3.get_node("Pacote/Correio")
	_check(pacote.prompt == "Pegar o pacote" and not dia3.get_node("Estojo").visible and not dia3.get_node("Bilhete").visible,
		"Dia 3: o pacote do expresso fechado, no chão junto à porta")
	await _abrir_correio(esc, pacote)
	_check(not dia3.get_node("Pacote/Barbante").visible and not dia3.get_node("Estojo").visible and pacote.prompt == "Tirar o bilhete",
		"cortado o barbante: as coisas ainda dentro do pacote")
	var tirar := PackedStringArray()
	while pacote.tiradas() < pacote.retirar.size():
		tirar.append(pacote.prompt)
		pacote.interact(player)
		await _frames(1)
	await _seconds(0.7)
	_check(tirar == PackedStringArray(["Tirar o bilhete", "Tirar a transcrição", "Tirar o estojo do cilindro"])
		and dia3.get_node("Estojo").visible and dia3.get_node("Transcricao").visible and dia3.get_node("Bilhete").visible
		and pacote.prompt == "Examinar o pacote", "tirados do pacote, um a um: o bilhete, a transcrição e o estojo")
	await _check_alcance(esc, "Dia 3, pacote aberto")
	_check(fono.prompt == "Pôr o cilindro de cera", "com o pacote aberto, o cilindro vai para a máquina")
	fono.interact(player)
	await _frames(2)
	_check(not esc.find_child("Estojo", true, false).visible, "o cilindro sai do estojo para a máquina")
	var legendas: Array[String] = []
	var ouvir := func(texto: String, _s: float) -> void: legendas.append(texto)
	Events.subtitle_requested.connect(ouvir)
	var exp_antes := GameState.get_number(&"exposicao")
	fono.interact(player)
	await _frames(3)
	_check(fono.tocando() and GameState.has_flag(&"tocou_disco"), "o disco toca")
	_check(is_equal_approx(GameState.get_number(&"exposicao") - exp_antes, fono.exposicao_primeira), "ouvir o disco aumenta a exposição")
	_check(legendas.size() > 0 and legendas[0] == "(SONS INDISTINGUÍVEIS)", "legenda da gravação")
	fono.interact(player)
	await _frames(2)
	Events.subtitle_requested.disconnect(ouvir)
	_check(not fono.tocando() and AudioDirector.is_hum_on(), "levantar a agulha; o zumbido fica")
	player.global_position = Vector3(0, 0, -1.4)
	player.rotation = Vector3.ZERO
	player.head.rotation.x = deg_to_rad(8)
	await _until(func() -> bool: return GameState.has_flag(&"viu_criatura_ceu_3"), 5.0)
	_check(GameState.has_flag(&"viu_criatura_ceu_3"), "depois do disco, olhando a janela, algo cruza o céu da cidade")
	escrever3.interact(player)
	await _frames(1)
	writer._choose(escrever3.reply.options[1])
	writer._finish_writing()
	await _selar(esc, writer)
	await _porta(esc)
	await _sonho_no_teste(esc, 3, func() -> void:
		# O disco de Akeley, no bosque: tocando de onde parou; levantar a agulha acorda.
		var disco: Fonografo = esc.find_child("Noite3", true, false).get_node("Fonografo/Disco")
		_check(esc.find_child("Bosque", true, false).is_visible_in_tree() and not (esc.get_node("Estrutura") as Node3D).visible,
			"a noite do disco: a sala some, e ele está no bosque onde o disco foi gravado")
		if not disco.tocando():
			disco.tocar()
		disco.interact(esc.player))
	await _until(func() -> bool: return GameState.get_value(&"dia") == 4 and not SceneDirector.hold_black and not esc._saindo, 45.0)
	_check(GameState.get_value(&"dia") == 4 and fono.is_visible_in_tree() and esc.find_child("Cilindro", true, false).visible, "Dia 4: a máquina fica montada, com o cilindro")

	# --- Escritório: Dia 4, a pedra que não chega (livro cap. III) ---
	var dia4: Node3D = esc.find_child("Dia4", true, false)
	var tel: Telefone = esc.find_child("Telefone", true, false)
	var foto10: Node3D = esc.find_child("Foto10", true, false)
	_check(dia4.visible and not foto10.visible and not dia4.get_node("Telegrama").visible, "Dia 4: o telegrama e a carta de julho chegam fechados")
	await _check_dia(esc, 4)
	_check(esc.lapso.texto_dia.text == "18" and esc.lapso.texto_semana.text == "WEDNESDAY", "Dia 4: a folhinha em quarta-feira, 18 de julho")
	_check(not tel.can_interact(player), "telefone sem ligação antes do telegrama")
	var correio_tel: Correspondencia = dia4.get_node("EnvelopeTelegrama/Correio")
	var correio_julho: Correspondencia = dia4.get_node("Envelope/Correio")
	correio_tel.interact(player)
	await _frames(1)
	_check(correio_julho in Correspondencia.na_mao and correio_tel in Correspondencia.na_mao and not correio_julho.can_interact(player),
		"pegar o correio junta tudo o que caiu pela fresta")
	await _abrir_correio(esc, correio_tel)
	_check(correio_julho.can_interact(player) and dia4.get_node("Telegrama").visible, "telegrama aberto; a mão livre para a carta de julho")
	await _abrir_correio(esc, correio_julho)
	correio_julho.interact(player)
	await _frames(1)
	_check(foto10.is_visible_in_tree() and dia4.get_node("CartaJulho").visible, "da carta de julho sai a foto do exército")
	# A foto sai do envelope num arco até o lugar dela; no meio do caminho, rasante
	# sobre o mata-borrão, contaria como enterrada.
	await _seconds(0.8)
	await _check_alcance(esc, "Dia 4, correio aberto")
	dia4.get_node("Telegrama/Ler").interact(player)
	await _frames(2)
	reader.close()
	await _frames(2)
	_check(tel.can_interact(player) and tel.atual().id == &"agencia_arkham", "depois do telegrama: telefonar à agência")
	var falas_tel: Array[String] = []
	var ouvir_tel := func(texto: String, _s: float) -> void: falas_tel.append(texto)
	Events.subtitle_requested.connect(ouvir_tel)
	esc.fonografo.tocar()
	_check(esc.fonografo.tocando(), "o disco tocando antes do telefonema")
	for id: StringName in [&"agencia_arkham", &"boston", &"telegrama_noturno"]:
		tel.interact(player)
		if id == &"agencia_arkham":
			await _frames(1)
			_check(not esc.fonografo.tocando() and not esc.fonografo.can_interact(player), "atender levanta a agulha; ao telefone, o fonógrafo não toca")
			await _until(func() -> bool: return tel._linha.playing, 10.0)
			_check(tel._linha.playing and tel._voz.playing, "dada a manivela: o chiado da linha e a voz da telefonista")
		await _until(func() -> bool: return GameState.has_flag(StringName("ligou_%s" % id)) and not tel.em_ligacao(), 60.0)
	_check(esc.lapso.texto_dia.text == "20" and esc.lapso.texto_semana.text == "FRIDAY" and esc.lapso.texto_mes.text == "JULY", "o lapso na sala: a folhinha chega a sexta, 20 de julho")
	_check(GameState.has_flag(&"ligou_telegrama_noturno") and not SceneDirector.hold_black, "agência, Boston e o telegrama noturno; salto para sexta")
	_check(tel.atual() != null and tel.atual().recebida and tel.prompt == "Atender o telefone", "sexta-feira: o telefone toca")
	tel.interact(player)
	await _until(func() -> bool: return GameState.has_flag(&"ligou_relato_keene"), 60.0)
	Events.subtitle_requested.disconnect(ouvir_tel)
	_check(falas_tel.any(func(f: String) -> bool: return f.contains("Stanley Adams")), "o relato de Keene: Stanley Adams")

	# --- Boston: a vinheta (livro cap. III) ---
	const BOSTON := "res://levels/boston/boston.tscn"
	await _until(func() -> bool: return SceneDirector.current_level == BOSTON and not SceneDirector.is_busy, 30.0)
	var boston: Boston = root.find_child("Boston", true, false)
	_check(boston != null, "naquela noite, a Boston: o quarto do funcionário")
	player = boston.player
	var rapaz: Interlocutor = boston.get_node("%Conversa")
	var saida: Interactable = boston.get_node("%Saida")
	var bater: StateInteractable = boston.get_node("%Bater")
	_check(bater.can_interact(player) and not rapaz.can_interact(player) and not saida.can_interact(player),
		"o corredor da pensão: a porta do rapaz, fechada; ainda não se volta")
	bater.interact(player)
	await _until(func() -> bool: return GameState.has_flag(&"porta_aberta_boston"), 20.0)
	await _frames(2)
	_check(rapaz.can_interact(player) and rapaz.prompt == "Apresentar-se" and boston.folha.rotation_degrees.y > 30.0,
		"batida a porta, ele abre uma fresta")
	await _check_alcance(boston, "Boston, porta fechada", Vector2(0.6, 2.8))
	var sonho_max := 0.0
	var falas_boston: Array[String] = []
	var ouvir_boston := func(texto: String, _s: float) -> void: falas_boston.append(texto)
	Events.subtitle_requested.connect(ouvir_boston)
	# Em pessoa, as perguntas aparecem embaixo para escolher (Fase 3e): sempre a
	# primeira (a ordem do livro), até não sobrar nenhuma.
	var max_opcoes := 0
	rapaz.interact(player)
	await _frames(1)
	while rapaz.em_conversa():
		sonho_max = maxf(sonho_max, GameState.get_number(&"sonho"))
		if OpcoesConversa.atual and OpcoesConversa.atual.is_inside_tree():
			max_opcoes = maxi(max_opcoes, OpcoesConversa.atual._frases.size())
			OpcoesConversa.atual.confirmar(0)
		await get_tree().process_frame
	_check(max_opcoes == 3, "depois do homem de Keene, duas perguntas e a despedida, à escolha")
	Events.subtitle_requested.disconnect(ouvir_boston)
	_check(falas_boston.any(func(f: String) -> bool: return f.contains("não tenho certeza nem disso")), "nem tem certeza de que o reconheceria")
	await _check_alcance(boston, "Boston, pela fresta", Vector2(0.6, 2.8))
	_check(sonho_max > 0.3, "falando da voz de Keene, a sala amolece")
	await _until(func() -> bool: return is_zero_approx(GameState.get_number(&"sonho")), 10.0)
	_check(is_zero_approx(GameState.get_number(&"sonho")) and saida.can_interact(player), "nada de novo: a porta leva de volta a Arkham")
	var ditas: Array[String] = []
	var ouvir_narrador := func(texto: String, _estilo: Narrator.Style) -> void: ditas.append(texto)
	Narrator.line_started.connect(ouvir_narrador)
	saida.interact(player)
	await _until(func() -> bool: return SceneDirector.current_level == "res://levels/escritorio/escritorio.tscn" and not SceneDirector.is_busy, 30.0)
	esc = root.find_child("Escritorio", true, false)
	player = esc.player
	dia4 = esc.find_child("Dia4", true, false)
	tel = esc.find_child("Telefone", true, false)
	_check(esc.world_env.environment == esc.env_noite and dia4.get_node("Noite").visible and not dia4.get_node("Tarde").visible,
		"de volta a Arkham, já de noite")
	await _until(func() -> bool: return GameState.has_flag(&"narrou_depois_relato"), 30.0)
	Narrator.line_started.disconnect(ouvir_narrador)
	_check(GameState.has_flag(&"narrou_depois_relato") and not ditas.any(func(d: String) -> bool: return d.contains("Na manhã de quarta-feira")),
		"a noite em claro escrevendo cartas (sem repetir o correio da manhã)")
	var escrever4: WriteReply = dia4.get_node("Escrever")
	_check(escrever4.can_interact(player), "depois do relato, as cartas da noite")
	escrever4.interact(player)
	await _frames(1)
	writer._choose(escrever4.reply.options[2])
	writer._finish_writing()
	await _selar(esc, writer)
	await _porta(esc)
	await _sonho_no_teste(esc, 4, func() -> void: esc.find_child("Noite4", true, false).get_node("Pedra/Examinar").interact(esc.player))
	await _until(func() -> bool: return GameState.get_value(&"dia") == 5 and not SceneDirector.hold_black and not esc._saindo, 45.0)
	_check(GameState.get_value(&"dia") == 5 and not tel.can_interact(player), "Dia 5: o telefone volta a ficar mudo")
	_check(GameState.has_flag(&"serviu_uisque") and esc.bebida.copo.visible and esc.bebida.frasco.get_parent() == esc.bebida.gaveta,
		"o uísque da noite do Dia 4: o copo fica na mesa; o frasco, escondido na gaveta")

	# --- Escritório: Dia 5, o telegrama "AKELY" (livro cap. IV) ---
	var dia5: Node3D = esc.find_child("Dia5", true, false)
	_check(dia5.visible and esc.world_env.environment == esc.ambientes_dia[5], "Dia 5: noite no escritório")
	_check(AudioDirector.get_ambience() == esc.sons_dia[5], "Dia 5: chuva")
	await _check_dia(esc, 5)
	var acender: StateInteractable = dia5.get_node("AcenderLareira")
	_check(not dia5.get_node("Fogo").visible and acender.can_interact(player), "Dia 5: a lareira apagada, com lenha")
	acender.interact(player)
	await _frames(2)
	_check(dia5.get_node("Fogo").visible and not acender.can_interact(player) and (dia5.get_node("Fogo/Chamas/Crepitar") as AudioStreamPlayer3D).playing,
		"acender a lareira: fogo, luz e o crepitar")
	var oferta: WriteReply = dia5.get_node("Oferta/Escrever")
	var telegrama5: Node3D = dia5.get_node("TelegramaAkely")
	_check(not oferta.can_interact(player) and not telegrama5.visible, "antes da carta de 15 de agosto, nada a responder")
	var soltas: Array[Correspondencia] = [dia5.get_node("EnvelopeAgosto/Correio"), dia5.get_node("Envelope/Correio")]
	_check(not soltas[0].get_visual().visible and not soltas[1].get_visual().visible, "Dia 5: as duas cartas chegam amarradas num maço")
	await _abrir_correio(esc, dia5.get_node("Maco/Correio"))
	_check(not dia5.get_node("Maco").visible and soltas.all(func(c: Correspondencia) -> bool:
		return c.get_visual().visible and c.estado() == Correspondencia.NA_MESA), "desamarrado, as cartas ficam soltas na mesa, fechadas")
	await _check_alcance(esc, "Dia 5, maço desamarrado")
	for c in soltas:
		c.interact(player)
	await _frames(2)
	_check(dia5.get_node("CartaAgosto").visible and dia5.get_node("Carta15").visible, "Dia 5: as duas cartas de agosto abertas")
	dia5.get_node("Carta15/Ler").interact(player)
	await _frames(2)
	reader.close()
	oferta.interact(player)
	await _frames(1)
	_check(writer.visible and oferta.reply.options.size() == 1, "a oferta de ir a Vermont: uma carta só, sem tom a escolher")
	writer._choose(oferta.reply.options[0])
	writer._finish_writing()
	await _selar(esc, writer)
	_check(GameState.get_number(&"dia") >= 5 and not GameState.has_flag(&"narrou_cartao_telegrama_akely"), "a carta selada espera o correio (narrou_cartao_telegrama_akely)")
	await _porta(esc)
	await _until(func() -> bool: return GameState.has_flag(&"narrou_cartao_telegrama_akely"), 60.0)
	_check(esc.lapso.passando, "o cartão entra no escuro do lapso, não depois dele")
	await _until(func() -> bool: return not esc.em_lapso, 60.0)
	var papel: Node3D = telegrama5.get_node("Papel")
	var correio_akely: Correspondencia = telegrama5.get_node("EnvelopeTelegrama/Correio")
	_check(telegrama5.visible and not oferta.is_visible_in_tree() and correio_akely.estado() == Correspondencia.NO_CHAO and correio_akely._chegou and not papel.visible,
		"em resposta, só um telegrama de Bellows Falls, caído pela fresta no escuro")
	await _check_alcance(esc, "Dia 5, o telegrama")
	await _abrir_correio(esc, correio_akely)
	papel.get_node("Leitura/Ler").interact(player)
	await _frames(2)
	reader.close()
	await _frames(2)
	_check(tel.atual() != null and tel.atual().id == &"resposta_telegrama", "depois do telegrama: responder pelo telefone")
	tel.interact(player)
	await _until(func() -> bool: return GameState.has_flag(&"narrou_cartao_aprofundava") and not SceneDirector.hold_black and not esc.em_lapso and not tel.em_ligacao(), 60.0)
	var bilhete: Node3D = dia5.get_node("Bilhete")
	var comparar: StateInteractable = papel.get_node("Comparacao/Comparar")
	_check(bilhete.visible and not comparar.is_visible_in_tree(), "o bilhete de Akeley chega; ainda não há o que comparar")
	await _abrir_correio(esc, bilhete.get_node("Envelope/Correio"))
	bilhete.get_node("Folha/Ler").interact(player)
	await _frames(2)
	reader.close()
	await _frames(2)
	_check(comparar.is_visible_in_tree() and not papel.get_node("Leitura").visible, "depois do bilhete, o telegrama é para comparar")
	await _check_alcance(esc, "Dia 5, o bilhete")
	var julho: DocumentData = load("res://narrative/documents/carta_akeley_julho.tres")
	var renovar: WriteReply = dia5.get_node("Renovacao/Escrever")
	_check(not julho.resolve_pages()[2].contains("ruivo") and not renovar.can_interact(player), "antes de comparar: a carta de julho intacta, nada a escrever")
	comparar.interact(player)
	await _frames(2)
	_check(GameState.has_flag(&"comparou_assinatura") and papel.get_node("Leitura").visible, "assinatura comparada; o telegrama volta a ser só leitura")
	_check(julho.resolve_pages()[2].contains("magro, ruivo"), "a carta de julho agora fala de um homem ruivo")
	var exp_julho := GameState.get_number(&"exposicao")
	reader.open(julho)
	await _frames(1)
	reader.close()
	_check(GameState.has_flag(&"leu_carta_akeley_julho_ruivo") and GameState.get_number(&"exposicao") > exp_julho, "reler a carta alterada expõe")
	player.global_position = Vector3(0, 0, -1.6)
	player.rotation = Vector3.ZERO
	player.head.rotation.x = 0.0
	await _until(func() -> bool: return GameState.has_flag(&"viu_sombra_janela"), 5.0)
	_check(GameState.has_flag(&"viu_sombra_janela"), "olhando a janela, algo passa lá fora")
	await _until(func() -> bool: return dia5.get_node("Sombra").visible, 5.0)
	_check(dia5.get_node("Sombra").visible, "o vulto atravessa a janela")
	renovar.interact(player)
	await _frames(1)
	writer._choose(renovar.reply.options[0])
	writer._finish_writing()
	await _selar(esc, writer)
	_check(GameState.get_number(&"dia") >= 5 and not GameState.has_flag(&"narrou_cartao_28_agosto"), "a carta selada espera o correio (narrou_cartao_28_agosto)")
	await _porta(esc)
	await _until(func() -> bool: return GameState.has_flag(&"narrou_cartao_28_agosto") and not SceneDirector.hold_black and not esc.em_lapso, 60.0)
	var c28: Node3D = dia5.get_node("Carta28")
	_check(c28.visible and not dia5.get_node("Sombra").visible, "28 de agosto: a carta da saída digna")
	await _check_alcance(esc, "Dia 5, 28 de agosto")
	await _porta(esc)
	_check(GameState.get_value(&"dia") == 5, "a porta espera a resposta de 28 de agosto")
	await _abrir_correio(esc, c28.get_node("Envelope/Correio"))
	c28.get_node("Folha/Ler").interact(player)
	await _frames(2)
	reader.close()
	var escrever5: WriteReply = c28.get_node("Escrever")
	var crenca_antes := GameState.get_number(&"crenca")
	escrever5.interact(player)
	await _frames(1)
	writer._choose(escrever5.reply.options[1])
	writer._finish_writing()
	await _selar(esc, writer)
	_check(GameState.get_value(&"resposta_dia_5") == 0 and GameState.get_number(&"crenca") == crenca_antes, "a resposta animadora (a do livro) não mexe na crença")
	await _porta(esc)
	await _sonho_no_teste(esc, 5, func() -> void: esc.find_child("TelefoneSonho", true, false).interact(esc.player))
	await _until(func() -> bool: return GameState.get_value(&"dia") == 6 and not SceneDirector.hold_black and not esc._saindo, 45.0)
	_check(GameState.get_value(&"dia") == 6 and not dia5.visible, "ir para casa leva a setembro")

	# --- Escritório: Dia 6, as três últimas cartas e o fim da demo (livro cap. IV) ---
	var dia6: Node3D = esc.find_child("Dia6", true, false)
	_check(dia6.visible and esc.world_env.environment == esc.ambientes_dia[6], "Dia 6: noite sem lua")
	await _check_dia(esc, 6)
	_check(not dia6.get_node("Fogo").visible and dia6.get_node("AcenderLareira").can_interact(player), "Dia 6: outra noite, a lareira por acender")
	var animo: WriteReply = dia6.get_node("Animo/Escrever")
	var segunda: Node3D = dia6.get_node("Segunda")
	_check(not animo.can_interact(player) and not segunda.visible, "Dia 6: antes da carta calma, nada a responder")
	var calma: DocumentPickup = dia6.get_node("CartaSetembro/Ler")
	_check(calma.document.resolve_pages()[0].contains("fez-me bem"), "a carta calma responde à resposta animadora")
	await _abrir_correio(esc, dia6.get_node("Envelope/Correio"))
	calma.interact(player)
	await _frames(2)
	reader.close()
	animo.interact(player)
	await _frames(1)
	_check(writer.visible and animo.reply.options.size() == 1, "o novo ânimo: uma carta só, sem tom")
	writer._choose(animo.reply.options[0])
	writer._finish_writing()
	await _selar(esc, writer)
	_check(GameState.get_number(&"dia") >= 5 and not GameState.has_flag(&"narrou_cartao_5_setembro"), "a carta selada espera o correio (narrou_cartao_5_setembro)")
	await _porta(esc)
	await _until(func() -> bool: return GameState.has_flag(&"narrou_cartao_5_setembro") and not SceneDirector.hold_black and not esc.em_lapso, 60.0)
	_check(segunda.visible and not animo.is_visible_in_tree(), "5 de setembro: a carta de segunda cruzou com a minha")
	await _check_alcance(esc, "Dia 6, segunda-feira")
	var terca: Node3D = dia6.get_node("Terca")
	_check(not segunda.get_node("Folha").visible, "a carta de segunda caiu pela fresta, fechada")
	await _abrir_correio(esc, segunda.get_node("Envelope/Correio"))
	segunda.get_node("Folha/Ler").interact(player)
	await _frames(2)
	_check(not terca.visible, "a carta de terça só chega no dia seguinte")
	reader.close()
	await _until(func() -> bool: return GameState.has_flag(&"narrou_cartao_6_setembro") and not SceneDirector.hold_black and not esc.em_lapso, 60.0)
	_check(terca.visible, "6 de setembro: \"falaram comigo\"")
	var quarta: Node3D = dia6.get_node("Quarta")
	var segunda_doc: DocumentData = segunda.get_node("Folha/Ler").document
	reader.open(segunda_doc)
	await _frames(1)
	reader.close()
	await _frames(2)
	_check(not SceneDirector.hold_black and not quarta.visible, "reler a carta de segunda não salta no tempo de novo")
	await _abrir_correio(esc, terca.get_node("Envelope/Correio"))
	terca.get_node("Folha/Ler").interact(player)
	await _frames(2)
	reader.close()
	await _until(func() -> bool: return GameState.has_flag(&"narrou_cartao_7_setembro") and not SceneDirector.hold_black and not esc.em_lapso, 60.0)
	var escrever6: WriteReply = quarta.get_node("Escrever")
	_check(quarta.visible and not escrever6.can_interact(player), "7 de setembro: a última carta manuscrita, ainda não lida")
	await _check_alcance(esc, "Dia 6, quarta-feira")
	await _porta(esc)
	_check(GameState.get_value(&"dia") == 6, "a porta espera a carta registrada")
	await _abrir_correio(esc, quarta.get_node("Envelope/Correio"))
	var ultima: DocumentPickup = quarta.get_node("Folha/Ler")
	_check(ultima.document == esc.ultima_carta and TintaTransicao.fim_da_carta(ultima.document).contains("AKELEY"), "a transição mostra o fim da última carta")
	ultima.interact(player)
	await _frames(2)
	reader.close()
	await _frames(2)
	escrever6.interact(player)
	await _frames(1)
	writer._choose(escrever6.reply.options[2])
	writer._finish_writing()
	await _selar(esc, writer)
	_check(GameState.get_value(&"resposta_dia_6") == 1, "a carta registrada (crédula, a do livro)")
	_check(CartaSaida.atual.get_node(^"Envelope").selos == 3, "a carta registrada leva mais selos")
	await _porta(esc)
	var tinta_na_tela := func() -> bool: return get_tree().root.get_children().any(func(n: Node) -> bool: return n is TintaTransicao)
	await _until(tinta_na_tela, 60.0)
	_check(tinta_na_tela.call() and not player.input_enabled, "a letra de Akeley enche a tela; o jogador não anda")
	await _until(func() -> bool: return main_menu.visible and not tinta_na_tela.call(), 120.0)
	_check(main_menu.visible and SceneDirector.current_level.is_empty() and not tinta_na_tela.call(), "fim da demo: a tinta vira céu e o jogo volta ao menu")
	_check(not SceneDirector.hold_black, "depois da demo, a tela preta não fica presa")
	Engine.time_scale = 1.0

	# Depuração (playtest 5): F2 pula o dia; o seguinte encontra o que espera do pulado.
	var depuracao := root.get_node_or_null(^"/root/Depuracao")
	if depuracao:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", 2)
		main_menu.close()
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn", &"Porta", false)
		await _frames(2)
		depuracao.pular_dia()
		await _until(func() -> bool: return GameState.get_value(&"dia") == 3 and not SceneDirector.is_busy, 30.0)
		await _frames(2)
		var esc_p := root.find_children("*", "Escritorio", true, false).front() as Escritorio
		_check(GameState.get_value(&"dia") == 3 and GameState.has_flag(&"anotou_dia_2") and GameState.get_value(&"correio_dia_2_tiradas") == 9
			and esc_p and esc_p.find_child("Fotografias", true, false).visible and GameState.get_value(&"data") == esc_p.datas_dia[3],
			"F2: pula do Dia 2 ao 3, com as fotografias tiradas e a data do dia")
		depuracao.pular_dia()
		await _until(func() -> bool: return GameState.get_value(&"dia") == 4 and not SceneDirector.is_busy, 30.0)
		_check(GameState.has_flag(&"tocou_disco") and GameState.has_flag(&"fono_cilindro"), "F2: pulado o Dia 3, o fonógrafo já tocou")
		SceneDirector.clear_level()

	# Paginar sem abrir (abrir marcaria `leu_<id>`); no fim, porque é um quadro longo.
	var sozinhas := PackedStringArray()
	for arquivo in DirAccess.get_files_at("res://narrative/documents"):
		var doc := load("res://narrative/documents/" + arquivo.trim_suffix(".remap")) as DocumentData
		DocumentData.apply_fonts(reader.body, doc.style)
		for pagina in reader._paginate(doc.resolve_pages()).slice(1):
			if reader._curto(pagina):
				sozinhas.append(doc.id)
	_check(sozinhas.is_empty(), "nenhuma folha só com a assinatura %s" % [sozinhas if sozinhas else ""])
	# As cartas de Wilmarth (as respostas) cabem numa folha do dossiê, como no papel em que foram escritas.
	var partidas := PackedStringArray()
	reader.show()
	for arquivo in DirAccess.get_files_at("res://narrative/documents"):
		if arquivo.begins_with("resposta_"):
			var doc := load("res://narrative/documents/" + arquivo.trim_suffix(".remap")) as DocumentData
			if reader._paginar_apertando(doc).size() > 1:
				partidas.append(doc.id)
	reader.hide()
	_check(partidas.is_empty(), "as cartas de Wilmarth cabem numa folha do dossiê %s" % [partidas if partidas else ""])
	DocumentData.apply_fonts(reader.body, DocumentData.Style.MANUSCRITO)
	_check(reader.body.get_theme_font(&"italics_font") is FontVariation, "[i] na letra de mão: a fonte inclinada")

	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string('{"type":"Dictionary","args":["s:version","i:0"]}')
	file.close()
	_check(not SaveSystem.has_save(), "save de outra versão é ignorado")
	SaveSystem.delete_save()
	_check(not SaveSystem.has_save(), "delete_save apaga o save")
	DirAccess.remove_absolute(TEST_SETTINGS)

	print("SMOKE: %s (%d falha(s))" % ["OK" if _failures == 0 else "FALHOU", _failures])
	get_tree().quit(_failures)


## Interações visíveis que a mira do jogador (raio de 2 m, camadas mundo e
## interação) não alcança de nenhum ponto da sala, em pé ou sentado — ex.: uma
## colisão tampando as peças dentro do caixote do Dia 3.
func _inalcancaveis(esc: Node3D, limites := Vector2(2.3, 2.8)) -> PackedStringArray:
	var space := esc.get_world_3d().direct_space_state
	var fora := PackedStringArray()
	for alvo: Interactable in esc.find_children("*", "Interactable", true, false):
		if not alvo.is_visible_in_tree():
			continue
		var centro := (alvo.get_child(0) as Node3D).global_position
		var achou := false
		for h in [1.15, 1.6]:
			for r in [0.4, 0.8, 1.2]:
				for i in 16:
					var a := TAU * i / 16.0
					var origem := Vector3(centro.x + cos(a) * r, h, centro.z + sin(a) * r)
					if absf(origem.x) > limites.x or absf(origem.z) > limites.y or origem.distance_to(centro) > 1.9:
						continue
					var q := PhysicsRayQueryParameters3D.create(origem, centro, 3, [(esc.get_node(^"Player") as Player).get_rid()])
					q.collide_with_areas = true
					# De dentro de um móvel não se mira (a lareira inteira tapava a lenha).
					q.hit_from_inside = true
					if space.intersect_ray(q).get("collider") == alvo:
						achou = true
						break
				if achou:
					break
			if achou:
				break
		if not achou:
			fora.append(String(esc.get_path_to(alvo)))
	return fora


## A noite entre os dias: espera o sonho `n` clarear, confere que é sonho (a
## estética crua, os dias sumidos, o grupo da noite) e acorda com `acordar`.
func _sonho_no_teste(esc: Escritorio, n: int, acordar: Callable) -> void:
	_check(GameState.get_value(&"dia") == n and GameState.get_value(&"diario") == n, "Dia %d: postada a resposta, falta o diário" % n)
	await _anotar(esc)
	# Noites 3 e 5: a entrada termina inteira, e o sono vem noutro lugar (LugarSono).
	var lugar := esc._lugar_sono(n)
	if lugar:
		await _until(func() -> bool: return GameState.get_value(&"sono", 0) == n and esc.player.input_enabled, 60.0)
		_check(not esc.diario.aberto and esc.diario._mancha.raio == 0.0 and lugar.can_interact(esc.player) and not esc.player.seated,
			"a noite do Dia %d continua: a entrada inteira, e \"%s\"" % [n, lugar.prompt])
		lugar.interact(esc.player)
	# Adormece (à mesa ou no lugar): a sala vira o sonho em volta dele, sem tela preta.
	var escuro := 0.0
	var t := 0.0
	while t < 90.0 and not (GameState.get_value(&"sonhando") == n and esc.player.input_enabled):
		escuro = maxf(escuro, SceneDirector._fade.modulate.a)
		await get_tree().process_frame
		t += get_process_delta_time()
	# Fora da sala (a noite do disco), ele sonha de pé.
	var fora := n in esc.sonhos_fora
	_check(escuro < 0.5 and not SceneDirector.hold_black and esc.player.seated != fora, "a noite do Dia %d: adormece, sem tela preta" % n)
	if lugar:
		_check(Vector2(esc.player.global_position.x, esc.player.global_position.z).distance_to(
			Vector2(lugar.assento.global_position.x, lugar.assento.global_position.z)) < 0.3, "adormece ali")
	else:
		_check(esc.diario.aberto and esc.diario._mancha.raio > 0.0, "a última linha falhou: a tinta escorre no diário")
		_check(esc.diario._ponta_px().y < Diario.TEXTURA.y - 8.0, "a letra fica no caderno: cheia a folha, ele vira a página")
	var grupo: Node3D = esc.find_child("Noite%d" % n, true, false)
	_check(GameState.get_value(&"sonhando") == n and is_equal_approx(GameState.get_number(&"sonho"), 1.0) and grupo.visible
		and not esc.find_child("Dias", true, false).visible and esc.player.input_enabled, "a noite do Dia %d: o sonho" % n)
	await _check_alcance(esc, "Sonho da noite %d" % n)
	acordar.call()
	await _frames(2)
	var viewer: Control = esc.get_tree().root.find_child("ExamineViewer", true, false)
	if viewer and viewer.visible:
		await _seconds(0.5)
		viewer.close()
	await _until(func() -> bool: return GameState.get_value(&"sonhando") == 0 and not SceneDirector.hold_black, 60.0)
	_check(GameState.get_value(&"sonhando") == 0 and is_zero_approx(GameState.get_number(&"sonho")), "acordar do sonho da noite %d" % n)
	var onde := esc.player.global_position.distance_to(lugar.assento.global_position) < 0.3 if lugar else esc.diario.aberto
	_check(GameState.get_value(&"dia") == n and esc.player.seated and onde and esc.find_child("Dias", true, false).visible
		and esc.lapso.sol.light_energy > 0.0, "de manhã, %s, a aurora na janela" % ("onde o sono o pegou" if lugar else "debruçado no diário aberto"))
	if lugar:
		# Playtest 5: acordado na poltrona, levantava dentro da colisão dela e travava.
		await _until(func() -> bool: return esc._pode_ir and esc.player.input_enabled, 60.0)
		var forma := esc.player.get_node(^"CollisionShape3D") as CollisionShape3D
		var consulta := PhysicsShapeQueryParameters3D.new()
		consulta.shape = forma.shape
		consulta.collision_mask = 1
		consulta.exclude = [esc.player.get_rid()]
		consulta.transform = esc.player.global_transform * forma.transform
		var preso := not esc.player.get_world_3d().direct_space_state.intersect_shape(consulta, 1).is_empty()
		_check(not esc.player.seated and not preso and absf(esc.player.global_position.y - lugar.assento.global_position.y) < 0.1,
			"acordado na noite %d, ele se levanta para fora da poltrona, livre" % n)
	await _ir_para_casa(esc)


## O dia acabou: a porta abre para o corredor e ele desce a escada, como o
## jogador (Fase 3e).
func _ir_para_casa(esc: Escritorio) -> void:
	var n: int = GameState.get_value(&"dia")
	await _until(func() -> bool: return esc._pode_ir and esc.player.input_enabled, 60.0)
	_check(esc._pode_ir and esc.porta.prompt == "Ir para casa" and GameState.get_value(&"dia") == n, "Dia %d acabado: hora de ir para casa" % n)
	esc.porta.interact(esc.player)
	await _until(func() -> bool: return esc.calha.porta_aberta and esc.player.input_enabled, 20.0)
	await _frames(2)
	_check(esc.calha.corredor.visible and not esc.porta.can_interact(esc.player) and not esc.player.seated, "a porta aberta: o corredor")
	# Pelo corredor até a escada, andando como o jogador (com a física: o vão
	# está livre): primeiro pela soleira, depois corredor afora.
	var alvo := esc.escada.global_position
	var t := 0.0
	while t < 20.0 and GameState.get_value(&"dia") == n and not esc._saindo:
		var p := esc.player.global_position
		var rumo := Vector3(alvo.x, p.y, alvo.z) if p.z > 3.4 else Vector3(esc.calha.soleira.x, p.y, 3.8)
		if p.distance_to(rumo) > 0.05:
			esc.player.look_at(rumo)
		Input.action_press(&"mover_frente")
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	Input.action_release(&"mover_frente")
	_check(esc._saindo or GameState.get_value(&"dia") == n + 1, "pelo corredor até a escada: o dia acaba")


## Postada a resposta do dia: "Anotar o dia" no caderno, como o jogador.
func _anotar(esc: Escritorio) -> void:
	(esc.diario.get_node("Anotar") as Interactable).interact(esc.player)
	await _frames(1)


## Selar como o jogador e esperar a Selagem na mesa terminar (a carta na mão).
func _selar(esc: Escritorio, writer: Control) -> void:
	await writer._seal()
	await _until(func() -> bool: return esc.selando, 10.0)
	await _until(func() -> bool: return not esc.selando, 60.0)
	await _frames(1)


## Como o jogador: pegar o correio do chão, pôr na mesa e abrir.
func _abrir_correio(esc: Escritorio, correio: Correspondencia) -> void:
	if correio.estado() == Correspondencia.NO_CHAO:
		correio.interact(esc.player)
		await _frames(2)
	if correio.estado() == Correspondencia.NA_MAO:
		(esc.get_node(^"%PorNaMesa") as MesaCorreio).interact(esc.player)
		await _frames(1)
	if correio.estado() == Correspondencia.NA_MESA:
		correio.interact(esc.player)
		await _frames(2)


## Como o jogador: usar a porta. Com a carta na mão (Fase 3f, duas ações): ela
## abre, ele põe a carta na calha do corredor, volta à sala e a porta fecha atrás.
func _porta(esc: Escritorio) -> void:
	await _entrar(esc)
	var com_carta := CartaSaida.atual != null and not esc.selando
	esc.porta.interact(esc.player)
	await _frames(2)
	if not com_carta:
		return
	await _until(func() -> bool: return esc.calha.porta_aberta and esc.player.input_enabled, 20.0)
	await _frames(2)
	esc.por_na_calha.interact(esc.player)
	await _frames(2)
	await _until(func() -> bool: return not esc.postando, 30.0)
	await _frames(1)
	if not esc._saindo:
		await _entrar(esc)


## Do corredor para dentro da sala, como o jogador (de manhã ele chega pela
## escada; de volta da calha): abre a porta, se fechada, entra, e ela fecha.
func _entrar(esc: Escritorio) -> void:
	var player := esc.player
	if not esc._fora() and not esc.calha.porta_aberta:
		return
	if esc._fora() and not esc.calha.porta_aberta:
		await _until(func() -> bool: return player.input_enabled and not SceneDirector.hold_black, 30.0)
		esc.porta_fora.interact(player)
		await _until(func() -> bool: return esc.calha.porta_aberta and player.input_enabled, 20.0)
	await _frames(2)
	player.global_position = Vector3(-0.2, player.global_position.y, 1.4)
	await _until(func() -> bool: return not esc.calha.porta_aberta and not esc.calha.movendo, 20.0)
	await _frames(2)


## Vira o corpo e a cabeça do player para o ponto e espera a mira atualizar.
func _mirar(player: Player, ponto: Vector3) -> void:
	player.look_at(Vector3(ponto.x, player.global_position.y, ponto.z))
	await _frames(1)
	var olho := player.camera.global_position
	player.head.rotation.x = atan2(ponto.y - olho.y, Vector2(ponto.x - olho.x, ponto.z - olho.z).length())
	await _frames(3)


## Começo de um dia no escritório: tudo ao alcance da mira, e pássaros só no
## Dia 1 (a única tarde tranquila; à noite e nos dias tensos eles calam).
func _check_dia(esc: Escritorio, n: int) -> void:
	await _entrar(esc)
	await _check_alcance(esc, "Dia %d" % n)
	var amb := AudioDirector.get_ambience()
	var passaros := amb == esc.sons_dia[1]
	_check(passaros == (n == 1) and amb != null, "Dia %d: %s" % [n, "pássaros na tarde" if n == 1 else "sem pássaros"])


func _check_alcance(esc: Node3D, quando: String, limites := Vector2(2.3, 2.8)) -> void:
	await _frames(2)
	var fora := _inalcancaveis(esc, limites)
	_check(fora.is_empty(), "%s: toda interação visível ao alcance da mira %s" % [quando, fora if fora else ""])
	var enterrados := _enterrados(esc)
	_check(enterrados.is_empty(), "%s: nenhum papel enterrado no mata-borrão %s" % [quando, enterrados if enterrados else ""])


## Papéis visíveis (folhas, envelopes, telegramas, fotos) cujo topo fica abaixo
## do topo do mata-borrão ou das cantoneiras onde se sobrepõem: somem na mesa.
func _enterrados(fase: Node3D) -> PackedStringArray:
	var tampas: Array[MeshInstance3D] = []
	for nome in ["MataBorrao", "Cantoneira-1", "Cantoneira1"]:
		var t := fase.find_child(nome, true, false) as MeshInstance3D
		if t and t.is_visible_in_tree():
			tampas.append(t)
	var fora := PackedStringArray()
	for mi: MeshInstance3D in fase.find_children("*", "MeshInstance3D", true, false):
		if mi in tampas or not mi.is_visible_in_tree() or mi.material_override == null:
			continue
		var mat := mi.material_override.resource_path.get_file().get_basename()
		if mat not in ["papel", "envelope", "cartao_foto"]:
			continue
		var caixa := mi.global_transform * mi.get_aabb()
		if caixa.size.y > 0.05:
			continue
		for t in tampas:
			var tampa := t.global_transform * t.get_aabb()
			var cruza := caixa.position.x < tampa.end.x and caixa.end.x > tampa.position.x \
				and caixa.position.z < tampa.end.z and caixa.end.z > tampa.position.z
			if cruza and caixa.end.y < tampa.end.y + 0.0005:
				fora.append(String(fase.get_path_to(mi)))
				break
	return fora


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		_failures += 1


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	# Quadros de processo (a entrada é despachada neles): com o tempo acelerado,
	# vários quadros de física cabem num só, e `_frames` não bastava.
	for i in 3:
		await get_tree().process_frame


## Espera a condição valer (ou o tempo esgotar, em segundos de jogo).
func _until(cond: Callable, timeout: float) -> void:
	var t := 0.0
	while not cond.call() and t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time()


func _seconds(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
