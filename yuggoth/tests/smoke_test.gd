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

	# --- Escritório: Dia 1 (GDD §5.1) ---
	player = esc.player
	var carta1: DocumentData = load("res://narrative/documents/carta_akeley_1.tres")
	var escrever: WriteReply = esc.find_child("Escrever", true, false)
	var writer: Control = root.get_node("UI/ReplyWriter")
	_check(not escrever.can_interact(player), "responder só depois de ler a carta")
	esc.porta.interact(player)
	await _frames(2)
	_check(GameState.get_value(&"dia") == 1 and not esc._saindo, "porta não leva para casa sem resposta")
	var ler_carta: DocumentPickup = esc.find_child("Carta", true, false).get_node("Ler")
	ler_carta.interact(player)
	await _frames(1)
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
	_check(cabe and reader._pages.size() > carta1.pages.size(), "carta longa paginada sem estourar o papel")
	reader.close()
	_check(escrever.can_interact(player), "depois de ler, dá para responder")
	escrever.interact(player)
	await _frames(1)
	_check(writer.visible and not player.input_enabled, "tela de escrita abre como modal")
	writer._choose(escrever.reply.options[2])
	writer._finish_writing()
	writer._seal()
	await _frames(1)
	_check(not writer.visible and player.input_enabled, "selar fecha a escrita")
	_check(GameState.get_value(&"crenca") == 1 and GameState.get_value(&"resposta_dia_1") == 1, "resposta crédula: crença +1 e tom gravado")
	_check(escrever.reply.options[2].document in GameState.dossier, "a resposta escrita vai para o dossiê")
	_check(not escrever.can_interact(player), "não dá para responder duas vezes")
	esc.porta.interact(player)
	await _until(func() -> bool: return GameState.get_value(&"dia") == 2 and not SceneDirector.hold_black and not esc._saindo, 20.0)
	_check(GameState.get_value(&"dia") == 2, "ir para casa avança para o Dia 2")
	_check(not esc.find_child("Dia1", true, false).visible, "objetos do Dia 1 somem no Dia 2")
	_check(SaveSystem.has_save(), "checkpoint no começo do dia")

	# --- Escritório: Dia 2 (GDD §5.1, livro cap. II) ---
	var dia2: Node3D = esc.find_child("Dia2", true, false)
	var fotos: Node3D = esc.find_child("Fotografias", true, false)
	_check(dia2.visible and fotos.visible, "Dia 2: a carta e as fotografias na mesa")
	_check(fotos.find_children("*", "Fotografia", false, false).size() == 9, "as nove fotografias do livro")
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
	writer._seal()
	_check(GameState.get_value(&"crenca") == 2, "duas respostas crédulas: crença 2")
	esc.porta.interact(player)
	await _until(func() -> bool: return GameState.get_value(&"dia") == 3 and not SceneDirector.hold_black and not esc._saindo, 20.0)
	_check(GameState.get_value(&"dia") == 3 and fotos.visible and not dia2.visible, "Dia 3: as fotografias ficam, a carta do Dia 2 não")

	# --- Escritório: Dia 3, o disco (livro cap. III) ---
	var fono: Fonografo = esc.fonografo
	var escrever3: WriteReply = esc.find_child("Dia3", true, false).get_node("Escrever")
	_check(fono.is_visible_in_tree() and fono.faltando().size() == 3, "a máquina emprestada chega desmontada")
	_check(not escrever3.can_interact(player), "responder só depois de ouvir o disco")
	fono.interact(player)
	_check(not GameState.has_flag(&"tocou_disco"), "sem corneta, manivela e agulha não toca")
	for montar: StateInteractable in esc.find_child("Caixote", true, false).find_children("Montar", "StateInteractable", true, false):
		montar.interact(player)
	await _frames(2)
	_check(fono.faltando().is_empty() and fono.prompt == "Pôr o cilindro de cera", "peças montadas; falta o cilindro")
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
	escrever3.interact(player)
	await _frames(1)
	writer._choose(escrever3.reply.options[1])
	writer._finish_writing()
	writer._seal()
	esc.porta.interact(player)
	await _until(func() -> bool: return GameState.get_value(&"dia") == 4 and not SceneDirector.hold_black and not esc._saindo, 20.0)
	_check(GameState.get_value(&"dia") == 4 and fono.is_visible_in_tree() and esc.find_child("Cilindro", true, false).visible, "Dia 4: a máquina fica montada, com o cilindro")

	# --- Escritório: Dia 4, a pedra que não chega (livro cap. III) ---
	var dia4: Node3D = esc.find_child("Dia4", true, false)
	var tel: Telefone = esc.find_child("Telefone", true, false)
	_check(dia4.visible and esc.find_child("Foto10", true, false).is_visible_in_tree(), "Dia 4: telegrama, carta de julho e a foto do exército")
	_check(not tel.can_interact(player), "telefone sem ligação antes do telegrama")
	dia4.get_node("Telegrama/Ler").interact(player)
	await _frames(2)
	reader.close()
	await _frames(2)
	_check(tel.can_interact(player) and tel.atual().id == &"agencia_arkham", "depois do telegrama: telefonar à agência")
	var falas_tel: Array[String] = []
	var ouvir_tel := func(texto: String, _s: float) -> void: falas_tel.append(texto)
	Events.subtitle_requested.connect(ouvir_tel)
	for id: StringName in [&"agencia_arkham", &"boston", &"telegrama_noturno"]:
		tel.interact(player)
		await _until(func() -> bool: return GameState.has_flag(StringName("ligou_%s" % id)) and not tel.em_ligacao(), 60.0)
	_check(GameState.has_flag(&"ligou_telegrama_noturno") and not SceneDirector.hold_black, "agência, Boston e o telegrama noturno; salto para sexta")
	_check(tel.atual() != null and tel.atual().recebida and tel.prompt == "Atender o telefone", "sexta-feira: o telefone toca")
	tel.interact(player)
	await _until(func() -> bool: return GameState.has_flag(&"ligou_relato_keene") and not tel.em_ligacao(), 60.0)
	Events.subtitle_requested.disconnect(ouvir_tel)
	_check(falas_tel.any(func(f: String) -> bool: return f.contains("Stanley Adams")), "o relato de Keene: Stanley Adams")
	var escrever4: WriteReply = dia4.get_node("Escrever")
	_check(escrever4.can_interact(player), "depois do relato, as cartas da noite")
	escrever4.interact(player)
	await _frames(1)
	writer._choose(escrever4.reply.options[2])
	writer._finish_writing()
	writer._seal()
	esc.porta.interact(player)
	await _until(func() -> bool: return GameState.get_value(&"dia") == 5 and not SceneDirector.hold_black and not esc._saindo, 30.0)
	_check(GameState.get_value(&"dia") == 5 and not tel.can_interact(player), "Dia 5: o telefone volta a ficar mudo")
	Engine.time_scale = 1.0

	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string('{"type":"Dictionary","args":["s:version","i:0"]}')
	file.close()
	_check(not SaveSystem.has_save(), "save de outra versão é ignorado")
	SaveSystem.delete_save()
	_check(not SaveSystem.has_save(), "delete_save apaga o save")
	DirAccess.remove_absolute(TEST_SETTINGS)

	print("SMOKE: %s (%d falha(s))" % ["OK" if _failures == 0 else "FALHOU", _failures])
	get_tree().quit(_failures)


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		_failures += 1


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)


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
