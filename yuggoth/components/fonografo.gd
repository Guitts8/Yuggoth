class_name Fonografo
extends Interactable
## A máquina comercial emprestada do prédio da administração (livro cap. III)
## que toca o cilindro de cera de Akeley — o set piece do Dia 3 (GDD §5.1).
##
## Montagem: corneta, manivela e agulha chegam num caixote (flags `fono_*`,
## marcadas por StateInteractable); o cilindro vem no pacote do expresso e é
## posto aqui (`fono_cilindro`). Controle total: tocar e parar quando quiser.
## Tocar marca `tocou_disco`, soma `exposicao`, legenda cada trecho, faz a luz
## pulsar e os papéis tremerem na voz zumbida; ao parar pela primeira vez, o
## zumbido ambiente fica ligado para sempre. Da segunda vez em diante toca a
## gravação longa (💭 GDD: um trecho novo no fim, a voz zumbida diz "Wilmarth").

const PECAS := {&"fono_corneta": "a corneta", &"fono_manivela": "a manivela", &"fono_agulha": "a agulha"}

@export var gravacao: Gravacao
@export var gravacao_longa: Gravacao
## Liga no AudioDirector depois da primeira audição (GDD: zumbido permanente).
@export var zumbido: AudioStream
## Dita uma vez, depois da primeira audição.
@export var narracao_depois: NarrationLine
@export_range(0.0, 1.0, 0.01) var exposicao_primeira := 0.15
@export_range(0.0, 1.0, 0.01) var exposicao_repeticao := 0.03
## Luz que pulsa no ritmo do zumbido enquanto toca.
@export var luz: Light3D
## Objetos (papéis) que tremem enquanto a voz zumbida fala.
@export var tremer: Array[Node3D] = []

var _som: AudioStreamPlayer3D
var _atual: Gravacao
var _trecho := -1
var _luz_base := 0.0
var _repouso: Dictionary[Node3D, Vector3] = {}


func _ready() -> void:
	super()
	_som = AudioStreamPlayer3D.new()
	_som.name = "Som"
	_som.bus = &"Voice"
	_som.unit_size = 3.0
	add_child(_som)
	_som.finished.connect(_terminou)
	GameState.value_changed.connect(_atualizar_prompt.unbind(2))
	_atualizar_prompt()


func tocando() -> bool:
	return _som != null and _som.playing


func faltando() -> PackedStringArray:
	var falta := PackedStringArray()
	for flag: StringName in PECAS:
		if not GameState.has_flag(flag):
			falta.append(PECAS[flag])
	return falta


func _atualizar_prompt() -> void:
	if tocando():
		prompt = "Levantar a agulha"
	elif not faltando().is_empty():
		prompt = "Examinar o fonógrafo"
	elif not GameState.has_flag(&"fono_cilindro"):
		prompt = "Pôr o cilindro de cera"
	elif GameState.has_flag(&"tocou_disco"):
		prompt = "Tocar de novo"
	else:
		prompt = "Dar corda e baixar a agulha"


func _on_interact(_by: Node) -> void:
	if tocando():
		_parar()
		return
	var falta := faltando()
	if not falta.is_empty():
		Events.notice_requested.emit("Ainda falta montar %s." % ", ".join(falta))
		return
	if not GameState.has_flag(&"fono_cilindro"):
		GameState.set_flag(&"fono_cilindro")
		return
	tocar()


func tocar() -> void:
	var primeira := not GameState.has_flag(&"tocou_disco")
	_atual = gravacao if primeira or gravacao_longa == null else gravacao_longa
	GameState.add(&"vezes_disco", 1)
	GameState.add(&"exposicao", exposicao_primeira if primeira else exposicao_repeticao)
	GameState.set_flag(&"tocou_disco")
	if luz:
		_luz_base = luz.light_energy
	for n in tremer:
		_repouso[n] = n.rotation
	_trecho = -1
	_som.stream = _atual.audio
	_som.play()
	_atualizar_prompt()


func _process(_delta: float) -> void:
	if not tocando() or _atual == null:
		return
	var t := _som.get_playback_position()
	var i := _atual.trecho_em(t)
	if i != _trecho:
		_trecho = i
		if i >= 0:
			Events.subtitle_requested.emit(_atual.legendas[i], _atual.fim_do_trecho(i) - t + 0.4)
	var zumbindo := i >= 0 and _atual.tipos[i] == Gravacao.Tipo.ZUMBIDA
	if luz:
		var pulso := 0.5 + 0.5 * sin(t * TAU * 7.0)
		luz.light_energy = _luz_base * (1.0 - 0.35 * pulso if zumbindo else 1.0)
	for n in tremer:
		var tremor := Vector3(0.0, randf_range(-0.03, 0.03), 0.0) if zumbindo else Vector3.ZERO
		n.rotation = _repouso[n] + tremor


## O disco acaba sozinho: a fala é cortada no meio, como no livro.
func _terminou() -> void:
	Events.subtitle_requested.emit("(FALA CORTADA PELO FIM DO DISCO)", 3.0)
	if _atual == gravacao_longa:
		GameState.set_flag(&"ouviu_wilmarth_no_disco")
	_parar()


func _parar() -> void:
	if _som.playing:
		_som.stop()
	if luz:
		luz.light_energy = _luz_base
	for n in _repouso:
		n.rotation = _repouso[n]
	_repouso.clear()
	_atual = null
	_trecho = -1
	# Depois do disco, o zumbido nunca mais vai embora (só a exposição o muda).
	if zumbido and not AudioDirector.is_hum_on():
		AudioDirector.set_hum(zumbido, 6.0)
	if narracao_depois and not GameState.has_flag(narracao_depois.get_said_flag()):
		Narrator.say(narracao_depois)
	_atualizar_prompt()
