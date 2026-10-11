extends Node
## Só para testes — não existe no jogo exportado (some fora de build de
## depuração): segurar F acelera tudo VELOCIDADE vezes (falas do narrador,
## telefonemas, cartões, lapsos, sonhos, animações), com um aviso no canto.
## C troca a vista da janela entre a cidade em 3D e o painel antigo (flag `painel`).
## F2 pula para o dia seguinte (playtest 5: um dia que trava não pode prender o
## teste dos outros): dá o dia corrente por feito e recarrega o escritório na
## manhã seguinte. No Prólogo, pula para o Dia 1. F3 recarrega o escritório no
## mesmo dia, do jeito que o estado está (destrava sem avançar). Longe de F5–F12:
## rodando pelo editor, o jogo repassa essas ao Godot (playtest 6: F8 é o "parar
## o projeto", e fechava o jogo). F4 vai direto ao Interlúdio, como Akeley
## (docs/PLANO_FAZENDA.md; pedido do usuário: "um botão de testes para ir direto
## para a parte da fazenda, pulando o escritório"), de qualquer lugar — também do
## menu; na fazenda, F4 volta ao escritório. Shift+F4: a fazenda só para andar, sem
## ser Akeley (sem o balde, a descida nem o fim). `comandos.ps1 jogar-fazenda` abre
## o jogo já no Interlúdio (o argumento `--fazenda`).

const VELOCIDADE := 8.0
const TECLA := KEY_F
const TECLA_PULAR := KEY_F2
const TECLA_RECARREGAR := KEY_F3
const TECLA_FAZENDA := KEY_F4
const FAZENDA := "res://levels/fazenda/fazenda.tscn"
const ESCRITORIO := "res://levels/escritorio/escritorio.tscn"
## O último dia da demo (Escritorio.dia_do_interludio): dali não se pula.
const ULTIMO_DIA := 6

var _acelerando := false
var _aviso: Label


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	var camada := CanvasLayer.new()
	camada.layer = 128
	add_child(camada)
	_aviso = Label.new()
	_aviso.text = "▶▶ %d×  (teste)" % VELOCIDADE
	_aviso.position = Vector2(24, 20)
	_aviso.add_theme_font_size_override(&"font_size", 22)
	_aviso.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.3))
	_aviso.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override(&"outline_size", 6)
	_aviso.hide()
	camada.add_child(_aviso)
	if "--fazenda" in OS.get_cmdline_user_args():
		# O jogo abrindo: espera o menu chegar e vai direto ao Interlúdio.
		await get_tree().create_timer(0.6).timeout
		interludio()


func _input(event: InputEvent) -> void:
	var tecla := event as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_C:
			var on := not GameState.has_flag(&"painel")
			GameState.set_flag(&"painel", on)
			Events.notice_requested.emit("(teste) Janela: %s" % ("painel antigo" if on else "cidade em 3D"))
		TECLA_PULAR:
			pular_dia()
		TECLA_RECARREGAR:
			recarregar_dia()
		TECLA_FAZENDA:
			if tecla.shift_pressed:
				fazenda()
			elif SceneDirector.current_level == FAZENDA:
				if _pode_mexer():
					_abrir_escritorio("(teste) De volta ao escritório")
			else:
				interludio()


func _process(_delta: float) -> void:
	var segurando := Input.is_physical_key_pressed(TECLA) and get_window().has_focus()
	# Só mexe no time_scale que ele mesmo mudou (o teste de fumaça usa o seu).
	if segurando and not _acelerando:
		_acelerando = true
		Engine.time_scale = VELOCIDADE
	elif not segurando and _acelerando:
		_acelerando = false
		Engine.time_scale = 1.0
	_aviso.visible = _acelerando


## Num jogo em andamento e sem troca de fase no meio.
func _pode_mexer() -> bool:
	if SceneDirector.current_level.is_empty():
		Events.notice_requested.emit("(teste) Comece ou continue um jogo antes.")
		return false
	if SceneDirector.is_busy:
		return false
	if Events.is_modal_open:
		Events.notice_requested.emit("(teste) Feche a janela aberta antes.")
		return false
	return true


## Dá o dia corrente por feito (correio aberto, resposta escrita e postada, dia
## anotado) e abre o escritório na manhã seguinte. O que os dias seguintes
## esperam de um dia pulado vai junto (o fonógrafo montado e tocado, no Dia 3).
func pular_dia() -> void:
	if not _pode_mexer():
		return
	if not GameState.has_flag(&"prologo_concluido"):
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", 1)
		_abrir_escritorio("(teste) Prólogo pulado: Dia 1")
		return
	var n := int(GameState.get_value(&"dia", 1))
	# Na fazenda, F2 dá a rotina do entardecer por feita (F5).
	if SceneDirector.current_level == FAZENDA:
		var faz := get_tree().root.find_child("Fazenda", true, false)
		var rotina := faz.get("rotina") as Rotina if faz else null
		if rotina:
			rotina.pular()
			Events.notice_requested.emit("(teste) Rotina do entardecer pulada")
		return
	if n >= ULTIMO_DIA:
		Events.notice_requested.emit("(teste) O Dia %d é o último da demo." % n)
		return
	# O correio do dia que está na sala: aberto, com tudo tirado de dentro.
	for c: Correspondencia in get_tree().get_nodes_in_group(&"correspondencia"):
		if c.can_process() and c.get_visual().is_visible_in_tree():
			_abrir(c)
			for solta in c.soltar:
				_abrir(solta)
	# A resposta que fecha o dia (a renovação, no Dia 5 — playtest 8).
	var respostas: Dictionary = _propriedade(&"respostas_do_dia", {})
	var resposta: StringName = respostas.get(n, StringName("resposta_dia_%d" % n))
	if GameState.get_value(resposta) == null:
		GameState.set_value(resposta, 0)
	GameState.set_flag(StringName("escreveu_%s" % resposta))
	for flag: String in ["comecou_dia_%d", "anotou_dia_%d"]:
		GameState.set_flag(StringName(flag % n))
	if n == 3:
		for flag: StringName in [&"fono_corneta", &"fono_manivela", &"fono_agulha", &"fono_cilindro", &"tocou_disco"]:
			GameState.set_flag(flag)
	for chave: StringName in [&"sono", &"sonhando", &"diario"]:
		GameState.set_value(chave, 0)
	GameState.set_value(&"sonho", 0.0)
	GameState.set_value(&"dia", n + 1)
	var datas: Array = _propriedade(&"datas_dia", [])
	if n + 1 < datas.size():
		GameState.set_value(&"data", datas[n + 1])
	_abrir_escritorio("(teste) Pulado para o Dia %d" % (n + 1))


## Recarrega o escritório no dia corrente, com o estado como está. Uma carta
## selada e ainda não postada volta à mão (a resposta já conta como escrita: sem
## ela, não haveria o que postar).
func recarregar_dia() -> void:
	if not _pode_mexer():
		return
	var escritorio := get_tree().root.find_children("*", "Escritorio", true, false)
	var carta: ReplyData = escritorio[0].carta_por_postar if not escritorio.is_empty() else null
	for chave: StringName in [&"sono", &"sonhando"]:
		GameState.set_value(chave, 0)
	GameState.set_value(&"sonho", 0.0)
	await _abrir_escritorio("(teste) Dia %d recarregado" % int(GameState.get_value(&"dia", 1)))
	escritorio = get_tree().root.find_children("*", "Escritorio", true, false)
	if carta and not escritorio.is_empty():
		escritorio[0].carta_por_postar = carta
		CartaSaida.criar(escritorio[0].miskatonic, carta)


## Vai à fazenda (o quintal) ou, estando nela, volta ao escritório no mesmo dia.
func fazenda() -> void:
	if not _pode_mexer():
		return
	if SceneDirector.current_level == FAZENDA:
		await _abrir_escritorio("(teste) De volta ao escritório")
		return
	Engine.time_scale = 1.0
	_acelerando = false
	await SceneDirector.change_level(FAZENDA, &"Quintal")
	Events.notice_requested.emit("(teste) A fazenda de Akeley (F4 volta)")


## O Interlúdio direto, como Akeley: o estado do fim do Dia 6 (a carta registrada
## postada), 2 de setembro, e a fazenda com a descida do céu (sem a tinta). Do
## menu, da pausa ou de qualquer fase.
func interludio() -> void:
	if SceneDirector.is_busy:
		return
	Engine.time_scale = 1.0
	_acelerando = false
	for nome in ["MainMenu", "PauseMenu"]:
		var menu := get_tree().root.find_child(nome, true, false)
		if menu and menu.visible and menu.has_method(&"close"):
			menu.close()
	for n in get_tree().root.get_children():
		if n is TintaTransicao:
			n.queue_free()
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", ULTIMO_DIA)
	for flag: StringName in [&"comecou_dia_6", &"leu_carta_akeley_quarta", &"escreveu_resposta_dia_6", &"interludio"]:
		GameState.set_flag(flag)
	GameState.set_value(&"resposta_dia_6", 1)
	GameState.set_value(&"data", Lapso.dia_do_ano(9, 2))
	await SceneDirector.change_level(FAZENDA, &"Entardecer")
	Events.notice_requested.emit("(teste) O Interlúdio: Akeley, 2 de setembro (F4 volta ao escritório)")


func _abrir(c: Correspondencia) -> void:
	GameState.set_value(c.chave(), Correspondencia.ABERTO)
	if not c.retirar.is_empty():
		GameState.set_value(StringName("%s_tiradas" % c.chave()), c.retirar.size())


func _abrir_escritorio(aviso: String) -> void:
	Engine.time_scale = 1.0
	_acelerando = false
	await SceneDirector.change_level(ESCRITORIO, &"Porta")
	Events.notice_requested.emit(aviso)


## Uma propriedade do Escritorio (`datas_dia`, `respostas_do_dia`), lida da cena
## sem instanciá-la (pode-se pular de outra fase, como Boston).
func _propriedade(nome: StringName, padrao: Variant) -> Variant:
	var estado := (load(ESCRITORIO) as PackedScene).get_state()
	for i in estado.get_node_property_count(0):
		if estado.get_node_property_name(0, i) == nome:
			return estado.get_node_property_value(0, i)
	return padrao
