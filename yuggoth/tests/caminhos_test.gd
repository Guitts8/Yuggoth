extends "res://tests/smoke_test.gd"
## Os caminhos fora do roteiro (a sessão de tester): o que o jogador pode fazer
## que o teste de fumaça não faz — abrir a pausa ou o dossiê no meio de uma cena,
## sair para o menu e continuar no meio de um dia, esquecer a lareira, descer a
## escada com a carta na mão, folhear o diário vazio, continuar em Boston. E o
## macaco (só com CAMINHOS=macaco): um jogador ao acaso joga a demo inteira.
## Rodar com:
##   godot --headless --path . res://tests/caminhos_test.tscn
## Sai com código = número de falhas.

const ESCRITORIO := "res://levels/escritorio/escritorio.tscn"
## Um save e preferências próprios: roda junto com o teste de fumaça sem um
## sobrescrever o do outro.
const SAVE_CAMINHOS := "user://caminhos_test_save.json"
const SETTINGS_CAMINHOS := "user://caminhos_test_settings.cfg"

var root: Node
var reader: Control
var writer: Control
var pause: PauseMenu
var dossie: Control
var main_menu: MainMenu


## Todo erro do motor ou de script durante o teste (ex.: um lambda de tween com
## o nó já liberado) conta como falha no fim.
class Registro extends Logger:
	var erros := PackedStringArray()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var onde := "%s:%d" % [file, line]
		if not script_backtraces.is_empty() and script_backtraces[0].get_frame_count() > 0:
			onde = "%s:%d" % [script_backtraces[0].get_frame_file(0), script_backtraces[0].get_frame_line(0)]
		erros.append("%s (%s, %s)" % [code if rationale.is_empty() else rationale, function, onde])


var _registro := Registro.new()
## As últimas ações do macaco (para saber o que levou a um travamento).
var _historico := PackedStringArray()


func _anotar_acao(texto: String) -> void:
	_historico.append("[dia %s] %s" % [GameState.get_value(&"dia"), texto])
	if _historico.size() > 25:
		_historico.remove_at(0)


func _ready() -> void:
	OS.add_logger(_registro)
	# O macaco também tem o seu: roda junto com os caminhos.
	var so := OS.get_environment("CAMINHOS").split(",", false)
	SaveSystem.save_path = SAVE_CAMINHOS.replace("caminhos", "macaco") if "macaco" in so else SAVE_CAMINHOS
	SaveSystem.delete_save()
	Settings.settings_path = SETTINGS_CAMINHOS
	DirAccess.remove_absolute(SETTINGS_CAMINHOS)
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	root.start_level = load("res://levels/test/test_room.tscn")
	add_child(root)
	if SceneDirector.is_busy:
		await SceneDirector.level_changed
	reader = root.get_node("UI/DocumentReader")
	writer = root.get_node("UI/ReplyWriter")
	dossie = root.get_node("UI/Dossier")
	pause = root.get_node("Menus/Necronomicon/Paginas/PauseMenu")
	main_menu = root.get_node("Menus/Necronomicon/Paginas/MainMenu")
	Engine.time_scale = 8.0

	# CAMINHOS=escada_com_a_carta,... roda só esses (depuração do próprio teste).
	# O macaco é longo (o jogo inteiro): só quando pedido (CAMINHOS=macaco).
	for parte: Callable in [_textos, _modais_no_meio_das_cenas, _menu_no_meio_do_dia, _escada_com_a_carta,
			_diario_vazio, _noite_sem_fogo, _exame_na_ligacao_de_keene, _continuar_em_boston, _macaco]:
		var nome := parte.get_method().trim_prefix("_")
		if (so.is_empty() and nome != "macaco") or nome in so:
			print("-- %s" % parte.get_method())
			await parte.call()

	Engine.time_scale = 1.0
	_check(_registro.erros.is_empty(), "nenhum erro no log %s" % [_registro.erros if _registro.erros else ""])
	SaveSystem.delete_save()
	DirAccess.remove_absolute(SETTINGS_CAMINHOS)
	print("CAMINHOS: %s (%d falha(s))" % ["OK" if _failures == 0 else "FALHOU", _failures])
	get_tree().quit(_failures)


## O escritório na manhã do dia `n` (como o F2: o Prólogo feito), no corredor.
func _dia(n: int, estado := {}) -> Escritorio:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", n)
	for k: StringName in estado:
		GameState.set_value(k, estado[k])
	await SceneDirector.change_level(ESCRITORIO, &"Porta", false)
	await _frames(2)
	return root.find_child("Escritorio", true, false) as Escritorio


## Do chão à carta lida: o correio do Dia 1 aberto e a carta no dossiê.
func _ler_carta_1(esc: Escritorio) -> void:
	await _entrar(esc)
	var dia1 := esc.find_child("Dia1", true, false)
	await _abrir_correio(esc, dia1.get_node("Envelope/Correio"))
	(dia1.get_node("Carta/Ler") as DocumentPickup).interact(esc.player)
	await _frames(2)
	reader.close()
	await _frames(2)


## O estado da porta e da cena, para as mensagens de falha.
func _estado(esc: Escritorio) -> String:
	return "[porta %s movendo %s enabled %s | conduzido %s input %s seated %s | saindo %s selando %s postando %s lapso %s | carta %s pos %s]" % [
		esc.calha.porta_aberta, esc.calha.movendo, esc.porta.enabled, esc.player.conduzido, esc.player.input_enabled,
		esc.player.seated, esc._saindo, esc.selando, esc.postando, esc.em_lapso, CartaSaida.atual != null, esc.player.global_position]


## Abre e fecha a pausa (Esc) e o dossiê (Tab), como o jogador, no meio de algo.
func _abrir_e_fechar_telas() -> void:
	# No tempo normal: acelerado, a cena acabaria enquanto as telas abrem e fecham.
	var escala := Engine.time_scale
	Engine.time_scale = 1.0
	await _press(&"ui_cancel")
	var abriu := pause.visible
	await _press(&"ui_cancel")
	await _press(&"dossie")
	abriu = abriu and dossie.visible
	await _press(&"dossie")
	Engine.time_scale = escala
	_check(abriu and not pause.visible and not dossie.visible and not get_tree().paused, "a pausa e o dossiê abrem e fecham no meio da cena")


# --- 1. Textos -------------------------------------------------------------------

## Todo documento, em toda combinação de tons das respostas, resolve um texto não
## vazio, sem tag BBCode aberta que atravesse parágrafos (o leitor pagina por
## parágrafo) nem tag desconhecida.
func _textos() -> void:
	var problemas := PackedStringArray()
	var conhecidas := ["i", "b", "u", "s", "center", "right", "font_size", "color", "sussurro", "tremulo", "queda", "ilegivel", "indent", "p", "url", "font"]
	var tags := RegEx.create_from_string("\\[(/?)([a-z_]+)[^\\]]*\\]")
	for arquivo in DirAccess.get_files_at("res://narrative/documents"):
		var doc := load("res://narrative/documents/" + arquivo.trim_suffix(".remap")) as DocumentData
		for tom in [-1, 0, 1]:
			GameState.reset()
			for d in range(1, 7):
				GameState.set_value(StringName("resposta_dia_%d" % d), tom)
			var textos: Array = [doc.resolve_pages()]
			for v in doc.variants:
				if v:
					textos.append(v.pages)
			for paginas: PackedStringArray in textos:
				if "".join(paginas).strip_edges().is_empty():
					problemas.append("%s: vazio" % doc.id)
				for pagina: String in paginas:
					for par in pagina.split("\n\n"):
						var abertas: Array[String] = []
						for m in tags.search_all(par):
							var nome := m.get_string(2)
							if nome not in conhecidas:
								problemas.append("%s: tag [%s]" % [doc.id, nome])
							elif m.get_string(1) == "/":
								if abertas.is_empty() or abertas.back() != nome:
									problemas.append("%s: [/%s] sem abrir" % [doc.id, nome])
								else:
									abertas.pop_back()
							else:
								abertas.append(nome)
						if not abertas.is_empty():
							problemas.append("%s: [%s] atravessa o parágrafo" % [doc.id, abertas.back()])
	var unicos := PackedStringArray()
	for p in problemas:
		if p not in unicos:
			unicos.append(p)
	_check(unicos.is_empty(), "documentos: texto em todo tom, tags BBCode fechadas no parágrafo %s" % [unicos if unicos else ""])
	var linhas := PackedStringArray()
	for arquivo in DirAccess.get_files_at("res://narrative/narration"):
		var linha := load("res://narrative/narration/" + arquivo.trim_suffix(".remap")) as NarrationLine
		if linha == null or linha.text.strip_edges().is_empty() or String(linha.id) != arquivo.trim_suffix(".remap").get_basename():
			linhas.append(arquivo)
	_check(linhas.is_empty(), "falas do narrador: texto e id igual ao arquivo %s" % [linhas if linhas else ""])
	GameState.reset()


# --- 2. Telas no meio das cenas --------------------------------------------------

## Playtest de tester: a pausa (Esc) ou o dossiê (Tab) abertos e fechados no meio
## de uma cena (selar, o diário, a porta) devolviam o controle antes da hora — ele
## andava com a carta sendo selada, levantava da mesa no meio do diário.
func _modais_no_meio_das_cenas() -> void:
	var esc := await _dia(1)
	var player := esc.player
	await _ler_carta_1(esc)
	var escrever: WriteReply = esc.find_child("Escrever", true, false)
	escrever.interact(player)
	await _frames(1)
	writer._choose(escrever.reply.options[0])
	writer._finish_writing()
	writer._seal()
	await _until(func() -> bool: return esc.selando, 10.0)
	await _seconds(1.0)
	await _abrir_e_fechar_telas()
	_check(esc.selando and not player.input_enabled, "selando: fechada a pausa, ele continua parado à mesa")
	await _until(func() -> bool: return not esc.selando, 60.0)
	await _frames(2)
	_check(player.input_enabled and CartaSaida.atual != null, "selada, o controle volta")

	# A porta: ele vai à maçaneta (conduzido); a pausa no meio não o solta.
	esc.porta.interact(player)
	await _frames(3)
	await _abrir_e_fechar_telas()
	_check(not player.input_enabled and (esc.calha.movendo or not esc.calha.porta_aberta), "abrindo a porta: fechada a pausa, ele continua conduzido")
	await _until(func() -> bool: return esc.calha.porta_aberta and player.input_enabled, 20.0)
	await _frames(2)
	esc.por_na_calha.interact(player)
	await _frames(3)
	await _abrir_e_fechar_telas()
	_check(esc.postando and not player.input_enabled, "pondo a carta na calha: a pausa não o solta (postando %s, input %s, carta %s)" % [esc.postando, player.input_enabled, CartaSaida.atual])
	await _until(func() -> bool: return not esc.postando, 30.0)
	await _entrar(esc)

	# O diário: com o caderno aberto e a pena escrevendo, a pausa e o dossiê.
	await _anotar(esc)
	await _until(func() -> bool: return esc.diario.aberto, 45.0)
	await _seconds(0.5)
	await _abrir_e_fechar_telas()
	_check(not player.input_enabled and player.seated, "escrevendo o diário: fechada a pausa, ele continua sentado escrevendo")
	Input.action_press(&"mover_frente")
	await _frames(4)
	Input.action_release(&"mover_frente")
	_check(player.seated and esc._saindo, "escrevendo o diário: andar não o levanta")
	await _until(func() -> bool: return esc._pode_ir and player.input_enabled, 90.0)
	_check(esc._pode_ir and player.input_enabled and not player.seated, "o diário acaba e o controle volta")
	_check(not Events.is_modal_open, "nenhuma tela presa aberta")


# --- 3. Menu e continuar no meio do dia -------------------------------------------

## Sair para o menu no meio de uma cena e continuar: volta ao checkpoint (o começo
## do dia), sem nada da cena pendurado (a carta na mão, a pilha, o sonho, a tela).
func _menu_no_meio_do_dia() -> void:
	var esc := await _dia(2)
	var dia2 := esc.find_child("Dia2", true, false)
	await _entrar(esc)
	var correio: Correspondencia = dia2.get_node("Envelope/Correio")
	correio.interact(esc.player)
	await _frames(2)
	_check(Correspondencia.na_mao.size() == 1, "Dia 2: o correio na mão")
	await _press(&"ui_cancel")
	await root.quit_to_menu()
	await _frames(2)
	_check(main_menu.visible and Correspondencia.na_mao.is_empty() and CartaSaida.atual == null and not get_tree().paused,
		"no menu, nada na mão nem a pausa presa")
	await root.continue_game()
	await _until(func() -> bool: return not SceneDirector.is_busy and SceneDirector.current_level == ESCRITORIO, 20.0)
	await _frames(3)
	esc = root.find_child("Escritorio", true, false)
	correio = esc.find_child("Dia2", true, false).get_node("Envelope/Correio")
	_check(GameState.get_value(&"dia") == 2 and correio.estado() == Correspondencia.NO_CHAO and esc._fora()
		and esc.player.input_enabled and not Events.is_modal_open, "continuar: a manhã do Dia 2, o correio no chão")
	await _check_dia(esc, 2)
	await _abrir_correio(esc, correio)
	for i in 3:
		correio.interact(esc.player)
	await _seconds(0.5)

	# No meio do sonho da noite 2, de volta ao menu e continuar: a manhã do Dia 2 de
	# novo (o checkpoint), sem a estética do sonho presa. (Responder pede as nove
	# fotografias fora do envelope.)
	while correio.tiradas() < correio.retirar.size():
		correio.interact(esc.player)
	await _seconds(0.7)
	(esc.find_child("Dia2", true, false).get_node("Carta/Ler") as DocumentPickup).interact(esc.player)
	await _frames(2)
	reader.close()
	await _frames(2)
	var escrever2: WriteReply = esc.find_child("Dia2", true, false).get_node("Escrever")
	escrever2.interact(esc.player)
	await _frames(1)
	writer._choose(escrever2.reply.options[0])
	writer._finish_writing()
	await _selar(esc, writer)
	await _porta(esc)
	await _anotar(esc)
	await _until(func() -> bool: return GameState.get_value(&"sonhando") == 2 and esc.player.input_enabled, 120.0)
	_check(GameState.get_value(&"sonhando") == 2, "a noite do Dia 2: o sonho " + _estado(esc))
	await root.quit_to_menu()
	await _frames(2)
	await root.continue_game()
	await _until(func() -> bool: return not SceneDirector.is_busy and SceneDirector.current_level == ESCRITORIO, 20.0)
	await _seconds(1.0)
	esc = root.find_child("Escritorio", true, false)
	_check(GameState.get_value(&"dia") == 2 and GameState.get_value(&"sonhando", 0) == 0 and is_zero_approx(GameState.get_number(&"sonho"))
		and root.dream_level < 0.2 and not esc.find_child("Noite2", true, false).visible, "continuar depois de sair no sonho: a manhã, sem o sonho")
	var fotos := esc.find_child("Fotografias", true, false).find_children("*", "Fotografia", false, false)
	_check(fotos.all(func(f: Node3D) -> bool: return not f.is_visible_in_tree()), "continuar: as fotografias de volta ao envelope (o checkpoint)")


# --- 4. A escada com a carta na mão --------------------------------------------------

## Com a carta selada na mão, ele abre a porta e, em vez da calha, desce a escada:
## o dia não acaba (falta postar); volta, a porta fecha atrás, e posta depois.
func _escada_com_a_carta() -> void:
	var esc := await _dia(1)
	var player := esc.player
	await _ler_carta_1(esc)
	var escrever: WriteReply = esc.find_child("Escrever", true, false)
	escrever.interact(player)
	await _frames(1)
	writer._choose(escrever.reply.options[1])
	writer._finish_writing()
	await _selar(esc, writer)
	esc.porta.interact(player)
	await _until(func() -> bool: return esc.calha.porta_aberta and player.input_enabled, 20.0)
	await _andar(player, [Vector3(esc.calha.soleira.x, 0, 3.8), esc.escada.global_position])
	await _seconds(1.0)
	_check(GameState.get_value(&"dia") == 1 and not esc._saindo and CartaSaida.atual != null, "com a carta na mão, a escada não acaba o dia")
	await _andar(player, [Vector3(esc.calha.soleira.x, 0, 3.8), Vector3(esc.calha.soleira.x, 0, 1.6), Vector3(-0.2, 0, 1.2)])
	await _until(func() -> bool: return not esc.calha.porta_aberta and not esc.calha.movendo, 20.0)
	_check(not esc.calha.porta_aberta and CartaSaida.atual != null, "de volta à sala, a porta fecha; a carta continua na mão")
	await _frames(2)
	esc.porta.interact(player)
	await _until(func() -> bool: return esc.calha.porta_aberta and player.input_enabled, 20.0)
	await _frames(2)
	esc.por_na_calha.interact(player)
	await _until(func() -> bool: return not esc.postando, 30.0)
	await _entrar(esc)
	_check(CartaSaida.atual == null and GameState.get_value(&"diario") == 1, "depois, a carta vai pela calha " + _estado(esc))


# --- 5. O diário vazio -------------------------------------------------------------

## "Ler o diário" no Dia 1, antes de qualquer entrada: abre na folha de rosto, o
## Esc fecha o caderno (não abre a pausa) e ele se levanta.
func _diario_vazio() -> void:
	var esc := await _dia(1)
	await _entrar(esc)
	var ler: Interactable = esc.diario.get_node("Ler")
	_check(ler.can_interact(esc.player), "Dia 1: \"Ler o diário\"")
	ler.interact(esc.player)
	await _until(func() -> bool: return esc.diario.lendo, 30.0)
	await _seconds(0.3)
	await _press(&"ui_cancel")
	_check(not pause.visible, "folheando o diário, o Esc fecha o caderno, não abre a pausa")
	await _until(func() -> bool: return esc.player.input_enabled and not esc.diario.aberto, 30.0)
	_check(esc.player.input_enabled and not esc.player.seated and not esc.diario.aberto and not Events.is_modal_open, "fechado o diário, ele se levanta")

	# O macaco (semente 1): o dossiê aberto enquanto o caderno abria; fechado o
	# dossiê, tudo se dava por fechado, e o Esc abria a pausa em vez de fechar o
	# caderno — ele ficava sentado, preso, entre a pausa e o diário.
	Engine.time_scale = 1.0
	ler.interact(esc.player)
	await _seconds(0.5)
	await _press(&"dossie")
	_check(dossie.visible and not esc.diario.lendo, "o dossiê abre enquanto o caderno abre")
	await _until(func() -> bool: return esc.diario.lendo, 30.0)
	await _press(&"dossie")
	_check(not dossie.visible and esc.diario.lendo and Events.is_modal_open, "fechado o dossiê, o diário continua aberto (e é uma tela)")
	await _press(&"ui_cancel")
	_check(not pause.visible and not esc.diario.lendo, "o Esc fecha o caderno, não abre a pausa")
	Engine.time_scale = 8.0
	await _until(func() -> bool: return esc.player.input_enabled and not esc.diario.aberto, 30.0)
	_check(esc.player.input_enabled and not esc.player.seated and not Events.is_modal_open, "e ele se levanta, livre")


# --- 6. A noite do Dia 5 sem o fogo -------------------------------------------------

## A lareira do Dia 5 não é obrigatória; anotado o dia sem tê-la acendido, "Sentar
## diante do fogo" só existe com o fogo: a fala diz o que falta, e acendê-la abre a
## noite (antes, ele ficava sem saber o que fazer).
func _noite_sem_fogo() -> void:
	var esc := await _dia(5, {&"escreveu_resposta_dia_5": true, &"resposta_dia_5": 0, &"diario": 5, &"comecou_dia_5": true})
	await _entrar(esc)
	var dia5 := esc.find_child("Dia5", true, false)
	var sentar: LugarSono = esc._lugar_sono(5)
	var ditas: Array[String] = []
	var ouvir := func(texto: String, _estilo: Narrator.Style) -> void: ditas.append(texto)
	Narrator.line_started.connect(ouvir)
	await _anotar(esc)
	await _until(func() -> bool: return GameState.get_value(&"sono", 0) == 5 and esc.player.input_enabled, 120.0)
	Narrator.line_started.disconnect(ouvir)
	_check(not sentar.can_interact(esc.player) and ditas.any(func(d: String) -> bool: return d.contains("lareira")),
		"anotado o dia sem o fogo: a fala lembra a lareira %s" % [ditas])
	var acender: AcenderLareira = dia5.get_node("AcenderLareira")
	_check(acender.can_interact(esc.player), "a lareira ainda se acende")
	acender.interact(esc.player)
	await _frames(2)
	await _until(func() -> bool: return esc.player.input_enabled, 30.0)
	_check(sentar.can_interact(esc.player), "com o fogo aceso, \"Sentar diante do fogo\"")
	sentar.interact(esc.player)
	await _until(func() -> bool: return GameState.get_value(&"sonhando") == 5 and esc.player.input_enabled, 120.0)
	_check(GameState.get_value(&"sonhando") == 5, "diante do fogo, o sonho da noite 5")
	await _frames(2)
	_check(not esc.porta.can_interact(esc.player) and not esc.diario.get_node("Ler").visible,
		"no sonho, a porta não oferece \"Ir para casa\" nem o caderno \"Ler o diário\"")
	esc.find_child("TelefoneSonho", true, false).interact(esc.player)
	await _until(func() -> bool: return GameState.get_value(&"sonhando") == 0 and not SceneDirector.hold_black, 90.0)
	await _ir_para_casa(esc)
	await _until(func() -> bool: return GameState.get_value(&"dia") == 6 and not SceneDirector.hold_black and not esc._saindo, 45.0)
	_check(GameState.get_value(&"dia") == 6, "e a noite segue até setembro")


# --- 6b. Examinando quando a ligação leva a Boston ---------------------------------

## O macaco (semente 2): examinando algo enquanto o relato de Keene acabava, a fase
## trocava para Boston com o visualizador aberto sobre um objeto já liberado (erro
## a cada quadro, a tela de exame presa em Boston). E as cartas da noite apareciam
## na mesa uns segundos antes da troca.
func _exame_na_ligacao_de_keene() -> void:
	var esc := await _dia(4, {&"comecou_dia_4": true, &"ligou_agencia_arkham": true, &"ligou_boston": true,
		&"ligou_telegrama_noturno": true, &"narrou_cartao_sexta": true, &"correio_telegrama_pedra": 3, &"correio_julho": 3})
	await _entrar(esc)
	var tel: Telefone = esc.find_child("Telefone", true, false)
	_check(tel.atual() != null and tel.atual().id == &"relato_keene", "sexta-feira: o telefone toca (Keene)")
	tel.interact(esc.player)
	await _frames(2)
	var escrever: WriteReply = esc.find_child("Dia4", true, false).get_node("Escrever")
	var alvo: Examinable = null
	for e: Examinable in esc.find_children("*", "Examinable", true, false):
		if e.is_visible_in_tree() and e.can_interact(esc.player):
			alvo = e
			break
	var viewer: Control = root.get_node("UI/ExamineViewer")
	var escreveu_antes := [false]
	while tel.em_ligacao() or SceneDirector.current_level == ESCRITORIO:
		if is_instance_valid(alvo) and not viewer.visible and not Events.is_modal_open:
			alvo.interact(esc.player)
		if is_instance_valid(escrever) and escrever.can_interact(esc.player):
			escreveu_antes[0] = true
		await get_tree().process_frame
		if SceneDirector.is_busy:
			break
	await _until(func() -> bool: return SceneDirector.current_level.ends_with("boston.tscn") and not SceneDirector.is_busy, 30.0)
	await _frames(3)
	_check(not escreveu_antes[0], "as cartas da noite só depois de Boston")
	_check(SceneDirector.current_level.ends_with("boston.tscn") and not viewer.visible and not Events.is_modal_open,
		"examinando quando a ligação acaba: em Boston, o exame fechado e nenhuma tela presa")


# --- 7. Continuar em Boston -----------------------------------------------------------

## O checkpoint da Boston (a troca de fase salva): sair dali para o menu e
## continuar volta ao corredor da pensão, e a volta a Arkham segue de noite.
func _continuar_em_boston() -> void:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 4)
	for f: StringName in [&"comecou_dia_4", &"ligou_agencia_arkham", &"ligou_boston", &"ligou_telegrama_noturno", &"ligou_relato_keene",
			&"narrou_cartao_sexta", &"leu_telegrama_pedra"]:
		GameState.set_flag(f)
	await SceneDirector.change_level("res://levels/boston/boston.tscn", &"", false)
	await _frames(2)
	await root.quit_to_menu()
	await _frames(2)
	await root.continue_game()
	await _until(func() -> bool: return not SceneDirector.is_busy and SceneDirector.current_level != "", 20.0)
	await _frames(3)
	var boston: Boston = root.find_child("Boston", true, false)
	_check(boston != null and GameState.get_value(&"dia") == 4, "continuar na Boston: o corredor da pensão")
	if boston == null:
		return
	boston.bater.interact(boston.player)
	await _until(func() -> bool: return GameState.has_flag(&"porta_aberta_boston"), 20.0)
	var rapaz: Interlocutor = boston.get_node("%Conversa")
	rapaz.interact(boston.player)
	await _frames(1)
	while rapaz.em_conversa():
		if OpcoesConversa.atual and OpcoesConversa.atual.is_inside_tree():
			OpcoesConversa.atual.confirmar(0)
		await get_tree().process_frame
	await _until(func() -> bool: return boston.saida.can_interact(boston.player), 20.0)
	_check(boston.saida.can_interact(boston.player), "a conversa acaba e a escada leva de volta")
	boston.saida.interact(boston.player)
	await _until(func() -> bool: return SceneDirector.current_level == ESCRITORIO and not SceneDirector.is_busy, 30.0)
	await _frames(3)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	_check(esc.world_env.environment == esc.env_noite, "de volta a Arkham, de noite")
	await _entrar(esc)
	_check((esc.find_child("Dia4", true, false).get_node("Escrever") as WriteReply).can_interact(esc.player), "as cartas da noite esperam")


# --- 8. O macaco ----------------------------------------------------------------------

## Um jogador ao acaso, do Dia 1 ao fim da demo (CAMINHOS=macaco, SEMENTE=n para
## repetir): a cada passo escolhe uma das interações disponíveis (as menos usadas
## primeiro), vai para perto dela, mira de verdade e aperta E; nas telas, escolhe
## qualquer abertura, às vezes amassa a carta, folheia, fecha; no meio das cenas,
## às vezes abre a pausa ou o dossiê, ou aperta E para pular a fala. Acusa: um dia
## que não acaba (travou), o corpo fora do mapa, a mira que não alcança o alvo,
## erros no log.
func _macaco() -> void:
	var semente := int(OS.get_environment("SEMENTE")) if OS.has_environment("SEMENTE") else int(Time.get_unix_time_from_system()) % 100000
	seed(semente)
	print("   semente %d" % semente)
	await _dia(1)
	var usos: Dictionary[String, int] = {}
	var dia := 1
	var desde := 0.0
	var mira_falhou := PackedStringArray()
	var fora_do_mapa := false
	var travou := ""
	var acoes := 0
	var parado := 0.0
	while not main_menu.visible:
		var t0 := Time.get_ticks_msec()
		await _macaco_passo(usos, mira_falhou)
		acoes += 1
		desde += (Time.get_ticks_msec() - t0) / 1000.0 * Engine.time_scale
		var fase := root.get(&"_level") as Node
		var player: Player = fase.find_child("Player", true, false) if fase else null
		if player and (player.global_position.y < -6.0 or absf(player.global_position.x) > 30.0 or absf(player.global_position.z) > 30.0):
			fora_do_mapa = true
			print("   fora do mapa em %s" % player.global_position)
			break
		# Sem controle e sem nenhuma cena conhecida por muito tempo: travou.
		var esc_m := root.find_child("Escritorio", true, false) as Escritorio
		var em_algo := esc_m == null or esc_m._saindo or esc_m.selando or esc_m.postando or esc_m.em_lapso or esc_m._saltando \
			or esc_m.calha.movendo or int(GameState.get_value(&"sonhando", 0)) != 0 or Events.is_modal_open or Narrator.is_speaking()
		if player and not player.input_enabled and not em_algo:
			parado += (Time.get_ticks_msec() - t0) / 1000.0 * Engine.time_scale
			if parado > 90.0:
				travou = "sem controle há %d s, sem cena: %s
      %s" % [parado, _estado_geral(), "
      ".join(_historico)]
				break
		else:
			parado = 0.0
		var agora := int(GameState.get_value(&"dia", 1))
		if agora != dia:
			print("   Dia %d acabou em %d s de jogo (%d ações)" % [dia, desde, acoes])
			dia = agora
			desde = 0.0
			usos.clear()
		elif desde > 1500.0:
			travou = "Dia %d sem acabar depois de %d s de jogo; %s
      %s" % [dia, desde, _estado_geral(), "
      ".join(_historico)]
			break
	_check(travou.is_empty(), "macaco (semente %d): todos os dias acabam %s" % [semente, travou])
	_check(not fora_do_mapa, "macaco: o corpo nunca sai do mapa")
	# Só informativo: o macaco mira de pé (o teste de fumaça confere o alcance de
	# pé e sentado, de toda a sala).
	if not mira_falhou.is_empty():
		print("   (de pé, a mira do macaco não pegou %d alvos, ex.: %s)" % [mira_falhou.size(), mira_falhou.slice(0, 5)])
	_check(main_menu.visible, "macaco: chegou ao fim da demo")


func _estado_geral() -> String:
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	var txt := "fase %s, modal %s, hold %s, busy %s" % [SceneDirector.current_level.get_file(), Events.is_modal_open, SceneDirector.hold_black, SceneDirector.is_busy]
	if esc:
		txt += ", " + _estado(esc) + " pode_ir %s diario %s sono %s sonhando %s" % [esc._pode_ir, GameState.get_value(&"diario"), GameState.get_value(&"sono"), GameState.get_value(&"sonhando")]
	return txt


## Um passo do macaco: resolve a tela aberta, ou espera a cena, ou faz algo.
func _macaco_passo(usos: Dictionary[String, int], mira_falhou: PackedStringArray) -> void:
	if SceneDirector.is_busy or SceneDirector.hold_black:
		await _seconds(0.3)
		return
	var viewer: Control = root.get_node("UI/ExamineViewer")
	if pause.visible:
		await _press(&"ui_cancel")
		return
	if dossie.visible:
		await _press(&"dossie")
		return
	if reader.visible:
		if randf() < 0.3:
			await _press(&"pagina_proxima")
		await _seconds(randf_range(0.1, 0.6))
		await _press(&"ui_cancel")
		return
	if writer.visible:
		if writer._selando:
			await _frames(2)
		elif writer._chosen == null:
			if randf() < 0.1:
				_anotar_acao("escrever: mais tarde")
				await _press(&"ui_cancel")  # mais tarde
			else:
				var opcoes: Array = writer._reply.options
				_anotar_acao("escrever: abertura")
				writer._choose(opcoes[randi() % opcoes.size()])
		elif randf() < 0.2:
			_anotar_acao("escrever: amassa")
			await _press(&"ui_cancel")  # amassa a folha
		else:
			_anotar_acao("escrever: sela")
			writer._finish_writing()
			await writer._seal()
		await _frames(2)
		return
	if viewer.visible:
		await _seconds(randf_range(0.2, 0.8))
		viewer.close()
		return
	if OpcoesConversa.atual and OpcoesConversa.atual.is_inside_tree():
		OpcoesConversa.atual.confirmar(randi() % OpcoesConversa.atual._frases.size())
		await _frames(2)
		return
	var esc := root.find_child("Escritorio", true, false) as Escritorio
	if esc and esc.diario.lendo:
		if randf() < 0.5:
			await _press(&"pagina_proxima")
			await _seconds(0.3)
		await _press(&"ui_cancel")
		return
	var fase := root.get(&"_level") as Node
	var player: Player = fase.find_child("Player", true, false) if fase else null
	if player == null:
		await _frames(2)
		return
	if not player.input_enabled:
		# Uma cena correndo: às vezes a pausa ou o dossiê no meio, ou pular a fala.
		var r := randf()
		if r < 0.03:
			_anotar_acao("na cena: Esc")
			await _press(&"ui_cancel")
		elif r < 0.05:
			_anotar_acao("na cena: Tab")
			await _press(&"dossie")
		await _seconds(0.25)
		return
	if randf() < 0.15 and Narrator.is_speaking():
		await _press(&"interagir")  # sem nada na mira, pula a fala
	if esc and esc._fora() and player.global_position.y < -0.1:
		_anotar_acao("sobe a escada")
		await _subir_a_escada(esc)
		return
	if esc and esc._pode_ir and esc.calha.porta_aberta and randf() < 0.85:
		# Hora de ir: quase sempre desce a escada (às vezes ainda faz algo).
		_anotar_acao("desce a escada")
		await _andar(player, [Vector3(esc.calha.soleira.x, 0, 3.8), esc.escada.global_position], 25.0)
		await _seconds(1.0)
		return
	var alvos := _alvos(fase, player, esc)
	if alvos.is_empty():
		# Nada a fazer: anda um pouco (o sonho acorda sozinho, uma fala termina).
		player.rotate_y(randf_range(-PI, PI))
		Input.action_press(&"mover_frente")
		await _seconds(randf_range(0.2, 0.8))
		Input.action_release(&"mover_frente")
		await _seconds(0.5)
		return
	# As menos usadas primeiro, com um pouco de acaso.
	var peso := {}
	for a in alvos:
		peso[a] = usos.get(str(a.get_path()), 0) + randf() * 1.5
	alvos.sort_custom(func(a: Interactable, b: Interactable) -> bool: return peso[a] < peso[b])
	var alvo: Interactable = alvos[0]
	var caminho := str(alvo.get_path())
	usos[caminho] = usos.get(caminho, 0) + 1
	var mirou := await _ir_ate(player, alvo)
	# A fase pode ter trocado enquanto ele mirava (a ligação de Keene leva a Boston).
	if not is_instance_valid(alvo) or not is_instance_valid(fase) or not alvo.is_inside_tree():
		return
	if mirou:
		_anotar_acao("E em %s (\"%s\")" % [fase.get_path_to(alvo), alvo.prompt])
		await _press(&"interagir")
	else:
		var onde := "%s (dia %s)" % [fase.get_path_to(alvo), GameState.get_value(&"dia")]
		if onde not in mira_falhou:
			mira_falhou.append(onde)
		# Só se ainda vale (sumiu da mira enquanto ele ia até lá: o jogador não o usaria).
		if alvo.is_visible_in_tree() and alvo.can_interact(player):
			_anotar_acao("direto em %s (\"%s\")" % [fase.get_path_to(alvo), alvo.prompt])
			alvo.interact(player)
	await _seconds(randf_range(0.1, 1.0))


## As interações que o jogador pode usar agora, do lado da porta em que ele está.
func _alvos(fase: Node, player: Player, esc: Escritorio) -> Array[Interactable]:
	var lista: Array[Interactable] = []
	for a: Interactable in fase.find_children("*", "Interactable", true, false):
		if not a.is_visible_in_tree() or not a.can_interact(player) or a.get_child_count() == 0:
			continue
		if esc and not esc.calha.porta_aberta and esc._fora() != esc.calha.do_lado_de_fora(a.global_position):
			continue
		lista.append(a)
	return lista


## Põe o jogador num ponto de onde a mira alcança o alvo (como _inalcancaveis), de
## pé (ou sentado, para o que se mira de perto da mesa), e mira. Devolve se a mira
## pegou o alvo.
func _ir_ate(player: Player, alvo: Interactable) -> bool:
	var space := player.get_world_3d().direct_space_state
	var centro := (alvo.get_child(0) as Node3D).global_position
	var chao := player.global_position.y if absf(player.global_position.y - centro.y) < 3.0 else 0.0
	var pontos: Array[Vector3] = []
	for h: float in [1.62]:
		for r: float in [0.6, 0.9, 1.2, 0.4]:
			for i in 16:
				var ang := TAU * i / 16.0
				pontos.append(Vector3(centro.x + cos(ang) * r, chao + h, centro.z + sin(ang) * r))
	pontos.shuffle()
	for origem in pontos:
		if origem.distance_to(centro) > 1.9:
			continue
		var pe := Vector3(origem.x, chao, origem.z)
		if not player.livre(pe):
			continue
		var q := PhysicsRayQueryParameters3D.create(origem, centro, 3, [player.get_rid()])
		q.collide_with_areas = true
		q.hit_from_inside = true
		if space.intersect_ray(q).get("collider") != alvo:
			continue
		player.stand()
		player.global_position = pe
		player.head.position.y = player.eye_height
		await _mirar(player, centro)
		if not is_instance_valid(player) or not is_instance_valid(alvo):
			return false
		if player._target == alvo:
			return true
	return false
