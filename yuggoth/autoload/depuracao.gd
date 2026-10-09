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
## o projeto", e fechava o jogo).

const VELOCIDADE := 8.0
const TECLA := KEY_F
const TECLA_PULAR := KEY_F2
const TECLA_RECARREGAR := KEY_F3
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
	if n >= ULTIMO_DIA:
		Events.notice_requested.emit("(teste) O Dia %d é o último da demo." % n)
		return
	# O correio do dia que está na sala: aberto, com tudo tirado de dentro.
	for c: Correspondencia in get_tree().get_nodes_in_group(&"correspondencia"):
		if c.can_process() and c.get_visual().is_visible_in_tree():
			_abrir(c)
			for solta in c.soltar:
				_abrir(solta)
	var resposta := StringName("resposta_dia_%d" % n)
	if GameState.get_value(resposta) == null:
		GameState.set_value(resposta, 0)
	for flag: String in ["comecou_dia_%d", "escreveu_resposta_dia_%d", "anotou_dia_%d"]:
		GameState.set_flag(StringName(flag % n))
	if n == 3:
		for flag: StringName in [&"fono_corneta", &"fono_manivela", &"fono_agulha", &"fono_cilindro", &"tocou_disco"]:
			GameState.set_flag(flag)
	for chave: StringName in [&"sono", &"sonhando", &"diario"]:
		GameState.set_value(chave, 0)
	GameState.set_value(&"sonho", 0.0)
	GameState.set_value(&"dia", n + 1)
	var datas := _datas_dia()
	if n + 1 < datas.size():
		GameState.set_value(&"data", datas[n + 1])
	_abrir_escritorio("(teste) Pulado para o Dia %d" % (n + 1))


## Recarrega o escritório no dia corrente, com o estado como está.
func recarregar_dia() -> void:
	if not _pode_mexer():
		return
	for chave: StringName in [&"sono", &"sonhando"]:
		GameState.set_value(chave, 0)
	GameState.set_value(&"sonho", 0.0)
	_abrir_escritorio("(teste) Dia %d recarregado" % int(GameState.get_value(&"dia", 1)))


func _abrir(c: Correspondencia) -> void:
	GameState.set_value(c.chave(), Correspondencia.ABERTO)
	if not c.retirar.is_empty():
		GameState.set_value(StringName("%s_tiradas" % c.chave()), c.retirar.size())


func _abrir_escritorio(aviso: String) -> void:
	Engine.time_scale = 1.0
	_acelerando = false
	await SceneDirector.change_level(ESCRITORIO, &"Porta")
	Events.notice_requested.emit(aviso)


## `datas_dia` do Escritorio, lido da cena sem instanciá-la (pode-se pular de
## outra fase, como Boston).
func _datas_dia() -> Array:
	var estado := (load(ESCRITORIO) as PackedScene).get_state()
	for i in estado.get_node_property_count(0):
		if estado.get_node_property_name(0, i) == &"datas_dia":
			return estado.get_node_property_value(0, i)
	return []
