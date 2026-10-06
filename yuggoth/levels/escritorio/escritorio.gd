class_name Escritorio
extends Node3D
## O gabinete de Wilmarth (1930) e o escritório da Miskatonic: mesma planta,
## dois vestidos (GDD §5.0, §5.1, §11.1). Enquanto `prologo_concluido` não
## estiver marcado, abre no Prólogo: cartão em tela preta, Wilmarth sentado à
## escrivaninha, e a caixa de cartas que leva de volta a maio.
##
## Depois, o loop dos dias (GDD §5.1): o correio chega, o jogador lê e
## investiga, responde a Akeley (ReplyData com id `resposta_dia_<N>`) e vai
## para casa pela porta — que só abre depois da resposta. Conteúdo de cada dia
## fica em nós com ConditionalNode (`dia == N`) dentro do vestido Miskatonic.
##
## Cena gerada por tools/gerar_escritorio.gd (ver o cabeçalho de lá).

const SONHO_SUBIDA := 2.5
const SONHO_DESCIDA := 4.0

@export var env_1930: Environment
@export var env_dia: Environment
## Ambiente de cada dia (índice = dia); faltando, vale `env_dia`. As luzes e a
## vista da janela de cada dia ficam dentro de `Miskatonic/DiaN`.
@export var ambientes_dia: Array[Environment] = []
@export var som_chuva: AudioStream
## Ambiente do escritório quando o dia não pede outro: cidade distante, sem
## pássaros. Pássaros só onde `sons_dia` pede (dia claro e tranquilo, o Dia 1).
@export var som_padrao: AudioStream
## Ambiente sonoro de cada dia (índice = dia); faltando, vale `som_padrao`.
@export var sons_dia: Array[AudioStream] = []
@export var som_pena: AudioStream
@export var linha_abertura: NarrationLine
@export var linha_cartas: NarrationLine
## Cartão em tela preta ao começar cada dia; índice = dia. O do Dia 1 fecha o Prólogo.
@export var cartoes_dia: Array[NarrationLine] = []
## Dita ao começar cada dia, enquanto a resposta do dia não foi escrita; índice = dia.
@export var linhas_correio: Array[NarrationLine] = []
@export var linha_resposta_selada: NarrationLine
## Dia em que, selada a resposta, a última carta manuscrita leva ao Interlúdio
## (GDD §5.1a): a letra enche a tela e a tinta vira o céu de Vermont.
@export var dia_do_interludio := 6
## A carta que enche a tela nessa transição.
@export var ultima_carta: DocumentData
## Cartão depois da tinta. Na demo o jogo acaba aí e volta ao menu; no jogo
## completo, aqui entra a troca para a fazenda.
@export var linha_fim_demo: NarrationLine
## Segundos depois de ler a folha do relato até o narrador lembrar das cartas.
@export var dica_cartas_apos := 8.0

var _lembrando := false
var _saindo := false
var _saltando := false
var _energias: Dictionary[Light3D, float] = {}

@onready var gabinete: Node3D = $Gabinete1930
@onready var miskatonic: Node3D = $Miskatonic
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var caixa: Examinable = %CaixaCartas
@onready var porta: Interactable = %SairPorta
@onready var relogio: AudioStreamPlayer3D = $Estrutura/Relogio/Tique
@onready var fonografo: Fonografo = %Fonografo
@onready var player: Player = $Player


func _ready() -> void:
	for light: Light3D in gabinete.find_children("*", "Light3D", true, false):
		_energias[light] = light.light_energy
	player.lamp.available = false
	porta.interacted.connect(_on_porta)
	Events.reply_written.connect(_on_reply_written)
	Events.document_closed.connect(_on_document_closed)
	# Depois do disco, o zumbido nunca mais vai embora (vale também em 1930).
	if GameState.has_flag(&"tocou_disco"):
		AudioDirector.set_hum(fonografo.zumbido, 0.0)
	if GameState.has_flag(&"prologo_concluido"):
		_vestir(false)
		_entrar_pela_porta()
		_inicio_do_dia()
	else:
		_vestir(true)
		_prologo()


func _vestir(em_1930: bool) -> void:
	_ativar(gabinete, em_1930)
	_ativar(miskatonic, not em_1930)
	world_env.environment = env_1930 if em_1930 else _ambiente_do_dia()
	# O relógio da parede para de tocar no Dia 2 (GDD §5.1).
	var tocando := em_1930 or dia() < 2
	if tocando and not relogio.playing:
		relogio.play()
	elif not tocando:
		relogio.stop()
	for light in _energias:
		light.light_energy = _energias[light]
	AudioDirector.play_ambience(som_chuva if em_1930 else _som_do_dia())


## Escondido também sai da física e para de processar (interações somem junto).
static func _ativar(node: Node3D, on: bool) -> void:
	node.visible = on
	node.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


# --- Prólogo (GDD §5.0) --------------------------------------------------------

## As sequências abaixo checam is_inside_tree() depois de cada await: a fase
## pode ter sido trocada (menu, load) enquanto esperavam.
func _prologo() -> void:
	player.sit()
	SceneDirector.hold_black = true
	SceneDirector.fade_out(0.0)
	Events.examine_closed.connect(_on_examine_closed)
	# A troca de fase pausa a árvore; isto continua quando ela soltar.
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	AudioDirector.play_sfx(som_pena, -4.0)
	await Narrator.say(linha_abertura, Narrator.Style.CARTAO)
	if not is_inside_tree():
		return
	await SceneDirector.release_black(2.5)
	if not is_inside_tree():
		return
	# A caixa só abre depois da folha do relato; a dica vem depois de lê-la.
	while not GameState.has_flag(&"leu_relato_folha_1") or Events.is_modal_open:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	await get_tree().create_timer(dica_cartas_apos).timeout
	if not is_inside_tree():
		return
	if not _lembrando:
		Narrator.say(linha_cartas)


func _on_examine_closed(target: Examinable) -> void:
	if target != caixa or _lembrando:
		return
	_lembrando = true
	caixa.enabled = false
	_lembrar()


## A sala se reorganiza em volta do jogador: o sonho sobe, a luz morre, os
## vestidos se trocam no escuro e a tarde de maio entra (sem loading visível).
func _lembrar() -> void:
	var subida := create_tween().set_parallel()
	subida.tween_method(_set_sonho, 0.0, 1.0, SONHO_SUBIDA)
	for light in _energias:
		subida.tween_property(light, "light_energy", 0.0, SONHO_SUBIDA)
	AudioDirector.stop_ambience(SONHO_SUBIDA)
	await subida.finished
	if not is_inside_tree():
		return
	await SceneDirector.fade_out(0.8)
	if not is_inside_tree():
		return
	SceneDirector.hold_black = true

	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 1)
	_vestir(false)
	await Narrator.say(_cartao(1), Narrator.Style.CARTAO)
	if not is_inside_tree():
		return

	var descida := create_tween()
	descida.tween_method(_set_sonho, 1.0, 0.0, SONHO_DESCIDA)
	await SceneDirector.release_black(2.0)
	if not is_inside_tree():
		return
	await descida.finished
	if not is_inside_tree():
		return
	SaveSystem.checkpoint()
	_inicio_do_dia()


func _set_sonho(v: float) -> void:
	GameState.set_value(&"sonho", v)


# --- Os dias (GDD §5.1) ------------------------------------------------------------

func dia() -> int:
	return int(GameState.get_value(&"dia", 1))


func _cartao(n: int) -> NarrationLine:
	return cartoes_dia[n] if n < cartoes_dia.size() else null


func _inicio_do_dia() -> void:
	var n := dia()
	if n < linhas_correio.size() and not _respondeu(n):
		Narrator.say(linhas_correio[n])


func _respondeu(n: int) -> bool:
	return GameState.has_flag(StringName("escreveu_resposta_dia_%d" % n))


func _entrar_pela_porta() -> void:
	var marker := get_node_or_null(^"Porta") as Node3D
	if marker:
		player.global_transform = marker.global_transform


func _on_reply_written(reply: ReplyData, _option: ReplyOption) -> void:
	var fala := reply.narracao_depois if reply.narracao_depois else linha_resposta_selada
	var interludio := reply.id == StringName("resposta_dia_%d" % dia_do_interludio)
	if reply.cartao_depois == null and not interludio:
		Narrator.say(fala)
		return
	await Narrator.say(fala)
	if not is_inside_tree():
		return
	if interludio:
		_para_o_interludio()
	else:
		# A carta vai e o tempo passa até a volta do correio (Dia 5).
		await SceneDirector.time_skip(reply.cartao_depois)


## Fim do Dia 6 e da demo: a tinta da última carta, o cartão e o menu.
func _para_o_interludio() -> void:
	_saindo = true
	var tinta := TintaTransicao.new()
	get_tree().root.add_child(tinta)
	# Se a fase sair no meio (menu de pausa), a tinta vai junto.
	tree_exiting.connect(tinta.queue_free)
	await tinta.tocar(ultima_carta)
	if not is_inside_tree():
		return
	await SceneDirector.fade_out(1.5)
	if not is_inside_tree():
		return
	SceneDirector.hold_black = true
	tinta.queue_free()
	await Narrator.say(linha_fim_demo, Narrator.Style.CARTAO)
	if not is_inside_tree():
		return
	Events.quit_to_menu_requested.emit()


func _on_porta(_by: Node) -> void:
	if not _respondeu(dia()):
		Events.notice_requested.emit("Ainda devo uma resposta ao Sr. Akeley.")
		return
	if _saindo:
		return
	_saindo = true
	await SceneDirector.fade_out(1.2)
	if not is_inside_tree():
		return
	SceneDirector.hold_black = true
	# Falas que sobraram do dia que acabou não atravessam para o seguinte.
	Narrator.cancel()
	GameState.add(&"dia", 1)
	_vestir(false)
	_entrar_pela_porta()
	await Narrator.say(_cartao(dia()), Narrator.Style.CARTAO)
	if not is_inside_tree():
		return
	await SceneDirector.release_black(1.5)
	if not is_inside_tree():
		return
	SaveSystem.checkpoint()
	_saindo = false
	_inicio_do_dia()


func _ambiente_do_dia() -> Environment:
	var n := dia()
	if n < ambientes_dia.size() and ambientes_dia[n]:
		return ambientes_dia[n]
	return env_dia


func _som_do_dia() -> AudioStream:
	var n := dia()
	if n < sons_dia.size() and sons_dia[n]:
		return sons_dia[n]
	return som_padrao


## Fala do narrador ao fechar um documento pela primeira vez, se existir
## `narrative/narration/ao_ler_<id>.tres` (ex.: a reação à 2ª carta de Akeley).
## Depois dela, o salto no tempo do documento (`cartao_depois`), se houver.
func _on_document_closed(doc: DocumentData) -> void:
	if doc == null:
		return
	var line: NarrationLine = null
	var path := "res://narrative/narration/ao_ler_%s.tres" % doc.id
	if ResourceLoader.exists(path):
		line = load(path) as NarrationLine
		if line and GameState.has_flag(line.get_said_flag()):
			line = null
	var salto := doc.cartao_depois
	if salto and GameState.has_flag(salto.get_said_flag()):
		salto = null
	if salto == null:
		if line:
			Narrator.say(line)
		return
	# Fechada enquanto o salto anterior ainda clareia: espera a vez.
	while _saltando:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	if GameState.has_flag(salto.get_said_flag()):
		return
	_saltando = true
	if line:
		await Narrator.say(line)
		if not is_inside_tree():
			return
	await SceneDirector.time_skip(salto)
	_saltando = false
