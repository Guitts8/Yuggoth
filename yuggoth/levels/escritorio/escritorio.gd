class_name Escritorio
extends Node3D
## O gabinete de Wilmarth (1930) e o escritório da Miskatonic: mesma planta,
## dois vestidos (GDD §5.0, §5.1, §11.1). Enquanto `prologo_concluido` não
## estiver marcado, abre no Prólogo: cartão em tela preta, Wilmarth sentado à
## escrivaninha, e a caixa de cartas que leva de volta a maio.
##
## Depois, o loop dos dias (GDD §5.1): o correio chega pela fresta, o jogador lê
## e investiga, responde a Akeley (ReplyData com id `resposta_dia_<N>`) e leva a
## carta selada à porta, que é o correio. Postada a resposta do dia, falta só o
## diário (`Diario`): anotado o dia, ele vai para casa — ou, nas noites de
## sonho, adormece à mesa e a sala vira o sonho. Conteúdo de cada dia
## fica em nós com ConditionalNode (`dia == N`) dentro do vestido Miskatonic.
##
## Cena gerada por tools/gerar_escritorio.gd (ver o cabeçalho de lá).

const SONHO_SUBIDA := 2.5
const SONHO_DESCIDA := 4.0
## Onde a folha escrita deita para ser selada: no mata-borrão, o envelope à frente.
const SELAGEM_POS := Vector3(0.05, 0.784, -2.2)
const BEBIDA_CAFE := 1
const BEBIDA_UISQUE := 2

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
## Quando o dia vira noite sem acabar (`anoiteceu_dia_<N>`: a volta de Boston).
@export var env_noite: Environment
@export var som_noite: AudioStream
## Ditas uma vez ao entrar no escritório com a flag marcada (voltando de outra
## fase): flag → linha. Ex.: `voltou_de_boston` → a noite em claro escrevendo cartas.
@export var linhas_volta: Dictionary[StringName, NarrationLine] = {}
@export_group("Diário e sonhos")
## A entrada do diário de cada dia (índice = dia), escrita ao fim dele. Nas
## noites de sonho, a última linha é a que o sono derruba ([queda]).
@export var diario_entradas: Array[DocumentData] = []
## Dita ao postar a resposta do dia: falta anotar o dia.
@export var linha_diario: NarrationLine
## A noite depois de cada dia que tem sonho (chave = o dia que acabou) → a flag
## que acorda (posta pelo próprio sonho: chegar à porta, levantar a agulha...).
@export var sonhos: Dictionary[int, StringName] = {}
@export var env_sonho: Environment
@export var som_sonho: AudioStream
## Sonhos que saem da sala (Fase 3e: a noite 3 revive o disco no bosque da Dark
## Mountain): a sala inteira some enquanto duram, e ele sonha de pé.
@export var sonhos_fora: Array[int] = []
## Environment próprio de uma noite (faltando, `env_sonho`).
@export var ambientes_sonho: Dictionary[int, Environment] = {}
## O que ele se serve antes de anotar o dia (dia → BEBIDA_CAFE ou BEBIDA_UISQUE).
@export var bebidas: Dictionary[int, int] = {}
## Segundos até acordar sozinho, se o jogador não fizer nada.
@export var duracao_sonho := 90.0
@export_group("")
@export var som_pena: AudioStream
## Dobrar a folha, o envelope; o selo batido (Selagem).
@export var som_papel: AudioStream
@export var som_selo: AudioStream
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
## Os saltos no tempo dentro do dia passam na própria sala (passar_tempo).
@export var lapso: Lapso
## Data na folhinha ao começar cada dia (dia do ano de 1928); índice = dia.
@export var datas_dia: Array[int] = []
## Data depois de cada salto no tempo, pelo id do cartão. Faltando, um dia depois.
@export var datas_cartao: Dictionary[StringName, int] = {}

var _lembrando := false
var _saindo := false
var _saltando := false
var _cartao_no_lapso := false
## Durante um salto no tempo dentro do dia (o lapso e o cartão dele).
var em_lapso := false
## Durante a Selagem (a carta sendo dobrada e selada na mesa).
var selando := false
## Pondo a carta na calha do corredor (CalhaCorreio).
var postando := false
var _energias: Dictionary[Light3D, float] = {}
## Environments (recursos compartilhados) escurecidos no meio do sono: voltam
## se a fase sair antes.
var _ambientes: Dictionary[Environment, float] = {}
## A sala escondida durante um sonho fora dela: cada nó e como estava.
var _sala_escondida: Dictionary[Node3D, Array] = {}

@onready var gabinete: Node3D = $Gabinete1930
@onready var miskatonic: Node3D = $Miskatonic
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var caixa: Examinable = %CaixaCartas
@onready var porta: Interactable = %SairPorta
@onready var relogio: AudioStreamPlayer3D = $Estrutura/Relogio/Tique
@onready var fonografo: Fonografo = %Fonografo
@onready var player: Player = $Player
@onready var diario: Diario = %Diario
@onready var calha: CalhaCorreio = %Calha
@onready var bebida: Bebida = %Bebida
## O alto da escada, no fim do corredor: chegar lá, na hora de ir, vira o dia.
@onready var escada: Area3D = %Escada
## A porta vista do corredor (de manhã, ele chega por ali).
@onready var porta_fora: Interactable = %EntrarPorta
## A boca da calha: "Pôr a carta na calha".
@onready var por_na_calha: Interactable = %PorNaCalha

## O dia acabou e falta ir para casa (Fase 3e): a porta abre para o corredor.
var _pode_ir := false
## Com a porta aberta, ele já esteve no corredor: de volta à sala, ela fecha.
var _saiu := false
## O salto no tempo de uma carta postada (Dias 5 e 6): espera ele voltar à sala
## e a porta fechar.
var _salto_pendente: NarrationLine


func _ready() -> void:
	for light: Light3D in gabinete.find_children("*", "Light3D", true, false):
		_energias[light] = light.light_energy
	player.lamp.available = false
	SceneDirector.tempo = self
	porta.interacted.connect(_on_porta)
	porta_fora.interacted.connect(_on_porta_fora)
	por_na_calha.interacted.connect(_on_por_na_calha)
	escada.body_entered.connect(_on_escada)
	diario.get_node(^"Anotar").interacted.connect(_on_anotar)
	diario.get_node(^"Ler").interacted.connect(_on_ler_diario)
	for l: LugarSono in find_children("*", "LugarSono", true, false):
		l.interacted.connect(_on_lugar_sono.bind(l))
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


func _exit_tree() -> void:
	if SceneDirector.tempo == self:
		SceneDirector.tempo = null
	for env in _ambientes:
		env.ambient_light_energy = _ambientes[env]


func _vestir(em_1930: bool) -> void:
	if lapso and not em_1930:
		lapso.mostrar(_data())
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
	GameState.set_value(&"data", _data_inicio())
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


## Uma vez por dia (voltar de outra fase no mesmo dia não repete o correio).
func _inicio_do_dia() -> void:
	var n := dia()
	var comecou := StringName("comecou_dia_%d" % n)
	for flag in linhas_volta:
		var linha := linhas_volta[flag]
		if GameState.has_flag(flag) and not GameState.has_flag(linha.get_said_flag()):
			Narrator.say(linha)
	if not GameState.has_flag(comecou):
		GameState.set_flag(comecou)
		if n < linhas_correio.size() and not _respondeu(n):
			_dizer_ao_entrar(linhas_correio[n])


## De manhã ele chega pelo corredor (Fase 3f): a fala do correio espera a porta
## abrir e o correio aparecer no chão.
func _dizer_ao_entrar(linha: NarrationLine) -> void:
	while _fora() and not calha.porta_aberta:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	Narrator.say(linha)


func _fora() -> bool:
	return calha.do_lado_de_fora(player.global_position)


func _respondeu(n: int) -> bool:
	return GameState.has_flag(StringName("escreveu_resposta_dia_%d" % n))


func _entrar_pela_porta() -> void:
	var marker := get_node_or_null(^"Porta") as Node3D
	if marker:
		player.global_transform = marker.global_transform


## Selada a resposta, a carta é dobrada, envelopada e selada na mesa, devagar
## (Selagem), e vai para a mão; quem a manda é a porta (_on_porta).
func _on_reply_written(reply: ReplyData, _option: ReplyOption) -> void:
	selando = true
	player.input_enabled = false
	var selagem := Selagem.new()
	var onde := Transform3D(Basis.IDENTITY, SELAGEM_POS)
	await selagem.tocar(miskatonic, onde, reply, player, som_papel, som_selo)
	if not is_inside_tree():
		return
	CartaSaida.criar(miskatonic, reply)
	selagem.queue_free()
	# Selada, ele se levanta com a carta na mão.
	player.stand()
	selando = false
	player.input_enabled = true
	Narrator.say(reply.narracao_depois if reply.narracao_depois else linha_resposta_selada)


func _process(_delta: float) -> void:
	# Num sonho fora da sala, a sala (a porta, o corredor) é do _esconder_sala.
	if not _sala_escondida.is_empty():
		return
	var fora := _fora()
	porta.prompt = "Abrir a porta" if CartaSaida.atual else "Ir para casa"
	# Aberta, a porta não se usa: o corredor está ali. Cada lado tem a sua área.
	# Num sonho, ela não leva a lugar nenhum: não oferece "Ir para casa".
	var fechada := not calha.porta_aberta and not calha.movendo
	_ligar(porta, fechada and not fora and int(GameState.get_value(&"sonhando", 0)) == 0)
	_ligar(porta_fora, fechada and fora)
	_ligar(por_na_calha, CartaSaida.atual != null and calha.porta_aberta and not postando)
	calha.corredor.visible = calha.porta_aberta or calha.movendo or fora
	if not calha.porta_aberta:
		return
	if fora:
		_saiu = true
	# De volta à sala, fora do arco da folha: a porta fecha sozinha atrás dele.
	elif _saiu and not calha.movendo and not postando and calha.fora_do_arco(player.global_position):
		_fechar_atras()


## Uma área que só existe quando vale (some da mira e da conferência de alcance).
static func _ligar(area: Interactable, on: bool) -> void:
	area.enabled = on
	area.visible = on


func _fechar_atras() -> void:
	_saiu = false
	await calha.fechar_sozinha()
	if not is_inside_tree() or _salto_pendente == null:
		return
	# A carta foi; o tempo passa até a volta do correio.
	var salto := _salto_pendente
	_salto_pendente = null
	while _saindo or _saltando or em_lapso or selando:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	_saltando = true
	await SceneDirector.time_skip(salto)
	_saltando = false


## A porta é o correio (Fase 3f, duas ações): com a carta na mão, ele a abre, e
## o corredor é dele; na calha, "Pôr a carta na calha" (_on_por_na_calha). Sem
## carta, o dia só acaba pela porta depois do diário (e do sonho, se houver):
## ela abre, e ele vai para casa pelo corredor.
func _on_porta(_by: Node) -> void:
	if _saindo or _saltando or em_lapso or selando or postando:
		return
	if _pode_ir or CartaSaida.atual:
		_abrir_porta(false)
		return
	if not _respondeu(dia()):
		Events.notice_requested.emit("Ainda devo uma resposta ao Sr. Akeley.")
		return
	var lugar := _lugar_sono(dia())
	if GameState.has_flag(StringName("anotou_dia_%d" % dia())):
		# Anotado o dia, a noite continua noutro lugar (LugarSono).
		if lugar and lugar.linha:
			Narrator.say(lugar.linha)
		return
	# Postada (ou perdida num load, com a mão vazia): falta o diário.
	GameState.set_value(&"diario", dia())
	Events.notice_requested.emit("Antes de ir, anotar o dia no diário.")


## De manhã, do corredor: ele abre a porta e entra quando quiser.
func _on_porta_fora(_by: Node) -> void:
	if _saindo or _saltando or em_lapso or selando or postando:
		return
	_abrir_porta(true)


## Uma cena curta: ele vai à maçaneta e abre; depois, o corredor (ou a sala) é dele.
func _abrir_porta(de_fora: bool) -> void:
	if calha.porta_aberta or calha.movendo:
		return
	player.input_enabled = false
	if de_fora:
		await calha.abrir_de_fora(player)
	else:
		await calha.abrir(player)
	if not is_inside_tree():
		return
	player.input_enabled = true


## Na calha do corredor, a carta vai (CalhaCorreio.por_na_calha). A resposta do
## dia deixa só o diário por fazer (a do Dia 6 encerra a demo); as outras (Dias
## 5 e 6) saltam no tempo até a volta do correio — quando ele voltar à sala e a
## porta fechar (_fechar_atras).
func _on_por_na_calha(_by: Node) -> void:
	var carta := CartaSaida.atual
	if carta == null or postando or _saindo:
		return
	var reply := carta.reply
	postando = true
	player.input_enabled = false
	await calha.por_na_calha(carta, player)
	if not is_inside_tree():
		return
	carta.postar()
	postando = false
	if reply.id == StringName("resposta_dia_%d" % dia_do_interludio):
		_para_o_interludio()
		return
	player.input_enabled = true
	if reply.id == StringName("resposta_dia_%d" % dia()):
		GameState.set_value(&"diario", dia())
		Narrator.say(linha_diario)
	elif reply.cartao_depois:
		_salto_pendente = reply.cartao_depois


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


## O diário (docs/PLANO_ESCRITORIO.md, "A passagem para o sonho"), a última
## coisa de cada dia, dos Dias 1 a 5: postada a resposta do dia (`diario` = o
## dia), Wilmarth senta e a entrada se escreve. Noite sem sonho: fecha o
## caderno, levanta, e o dia acaba. Noite de sonho: a última linha falha, ele
## adormece à mesa e a sala vira o sonho, sem tela preta; acorda de manhã
## debruçado no diário. O jogador nunca sabe de antemão qual das duas será.
## Antes de escrever, ele se serve (Fase 3d, `bebidas`: café ou uísque). E nem
## toda noite de sonho é no diário: com um LugarSono para a noite, a entrada
## termina inteira, ele se levanta, e o sono vem lá (ouvindo o disco, diante do
## fogo; _on_lugar_sono).
func _on_anotar(_by: Node) -> void:
	if _saindo or _saltando or em_lapso or selando:
		return
	_saindo = true
	var n := dia()
	GameState.set_value(&"diario", 0)
	GameState.set_flag(StringName("anotou_dia_%d" % n))
	# Falas que sobraram do dia não atravessam a noite.
	Narrator.cancel()
	player.input_enabled = false
	var entrada := _entrada(n)
	if entrada:
		GameState.add_document(entrada)
	var lugar := _lugar_sono(n)
	var sonha := sonhos.has(n) and lugar == null
	if bebidas.has(n):
		await _sentar_a_mesa()
		if not is_inside_tree():
			return
		if bebidas[n] == BEBIDA_UISQUE:
			await bebida.uisque(player)
		else:
			await bebida.cafe(player)
		if not is_inside_tree():
			return
	await diario.anotar(entrada, _entrada(n - 1), player, sonha)
	if not is_inside_tree():
		return
	if sonha:
		await _sonhar(n)
	else:
		await diario.fechar(player)
		if not is_inside_tree():
			return
		player.stand()
		if lugar:
			# A noite ainda não acabou: o que ele quer fazer antes de ir.
			GameState.set_value(&"sono", n)
			if lugar.linha:
				Narrator.say(lugar.linha)
			_saindo = false
			player.input_enabled = true
			return
		await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return
	_hora_de_ir()


## Senta na cadeira da escrivaninha (onde o diário abre) e olha o tampo.
func _sentar_a_mesa() -> void:
	var sentar := diario.cadeira(player)
	var t := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"global_position", sentar, 1.2)
	player.seated = true
	await player.olhar_para(diario.pagina() + Vector3(0.25, 0, 0), 1.4, sentar).finished


func _lugar_sono(noite: int) -> LugarSono:
	for l: LugarSono in get_tree().get_nodes_in_group(&"lugar_sono"):
		if l.noite == noite and is_ancestor_of(l):
			return l
	return null


## A noite de sonho longe do diário (LugarSono): ele vai até lá, senta, faz o
## que o lugar pede (o disco toca, um gole), e o sono vem como à mesa.
func _on_lugar_sono(_by: Node, lugar: LugarSono) -> void:
	if _saindo or _saltando or em_lapso or selando or postando:
		return
	_saindo = true
	player.input_enabled = false
	Narrator.cancel()
	GameState.set_value(&"sono", 0)
	# O disco começa antes do sono: ele vai ao fonógrafo e baixa a agulha.
	if lugar.fonografo and lugar.diante:
		await player.conduzir([lugar.diante.global_position], lugar.fonografo.global_position + Vector3.UP * 0.15)
		if not is_inside_tree():
			return
		if not lugar.fonografo.tocando():
			lugar.fonografo.tocar()
		await get_tree().create_timer(1.2).timeout
		if not is_inside_tree():
			return
	# Pela frente da poltrona, contornando-a se ele vem por trás (playtest 5: ele a
	# atravessava); dali, senta.
	var assento := lugar.assento.global_position
	assento.y = player.global_position.y
	await player.conduzir(_caminho_ao_assento(lugar), lugar.olhar.global_position)
	if not is_inside_tree():
		return
	player.seated = true
	var senta := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	senta.tween_property(player, ^"global_position", assento, 0.9)
	await player.olhar_para(lugar.olhar.global_position, 0.9, assento).finished
	if not is_inside_tree():
		return
	if lugar.fonografo and not lugar.fonografo.tocando():
		lugar.fonografo.tocar()
	if lugar.copo:
		await bebida.gole(player, lugar.copo)
		if not is_inside_tree():
			return
		await player.olhar_para(lugar.olhar.global_position, 1.0).finished
	if lugar.escutar > 0.0:
		await get_tree().create_timer(lugar.escutar).timeout
		if not is_inside_tree():
			return
	await _sonhar(lugar.noite)
	if not is_inside_tree():
		return
	await _levantar_do_assento(lugar)
	if not is_inside_tree():
		return
	_hora_de_ir()


## A frente do assento (o -Z do marcador) e o lado dele (+X), no chão.
func _eixos_do_assento(lugar: LugarSono) -> Array[Vector3]:
	var b := lugar.assento.global_basis
	var frente := -b.z
	frente.y = 0.0
	var lado := b.x
	lado.y = 0.0
	return [frente.normalized(), lado.normalized()]


## Os pontos por onde ele chega diante do assento: se vem por trás ou pelo lado
## do móvel, contorna pelo canto da frente mais perto dele.
func _caminho_ao_assento(lugar: LugarSono) -> Array:
	var eixos := _eixos_do_assento(lugar)
	var centro := lugar.assento.global_position
	var de := player.global_position - centro
	de.y = 0.0
	var saida := _saida_do_assento(lugar)
	if de.dot(eixos[0]) > 0.45:
		return [saida]
	var lado := signf(de.dot(eixos[1]))
	if lado == 0.0:
		lado = 1.0
	var canto := centro + eixos[0] * 0.95 + eixos[1] * lado * 0.8
	return [canto, saida]


## Um lugar livre diante do assento, onde ele fica de pé ao levantar: sentado, o
## corpo está dentro da colisão do móvel, e a física o prenderia ali (playtest 5:
## travava na frente da poltrona ao acordar).
func _saida_do_assento(lugar: LugarSono) -> Vector3:
	var eixos := _eixos_do_assento(lugar)
	# O marcador está no chão da sala (no pé do móvel).
	var centro := lugar.assento.global_position
	for k: Vector2 in [Vector2(0.75, 0), Vector2(0.9, 0), Vector2(0.75, -0.45), Vector2(0.75, 0.45),
			Vector2(1.1, 0), Vector2(1.0, -0.7), Vector2(1.0, 0.7), Vector2(1.3, 0), Vector2(0.4, -0.8), Vector2(0.4, 0.8)]:
		var p := centro + eixos[0] * k.x + eixos[1] * k.y
		if player.livre(p):
			return p
	return centro + eixos[0] * 0.9


## Levanta do assento (LugarSono) e dá o passo à frente, para fora do móvel.
func _levantar_do_assento(lugar: LugarSono) -> void:
	var saida := _saida_do_assento(lugar)
	player.stand()
	player.debrucado = 0.0
	var olhar := saida + _eixos_do_assento(lugar)[0] * 2.0 + Vector3.UP * 1.5
	await player.conduzir([saida], olhar, 0.7)


## Folhear o diário (Fase 3d): ele senta, o caderno abre no último par escrito;
## fechado, volta ao lugar e ele se levanta.
func _on_ler_diario(_by: Node) -> void:
	if _saindo or _saltando or em_lapso or selando:
		return
	player.input_enabled = false
	await diario.ler(player)
	if not is_inside_tree():
		return
	await diario.fechar(player)
	if not is_inside_tree():
		return
	player.stand()
	player.input_enabled = true


func _entrada(n: int) -> DocumentData:
	return diario_entradas[n] if n > 0 and n < diario_entradas.size() else null


## O dia acabou (anotado sem sonho; ou de manhã, acordado do sonho): falta ir
## para casa (Fase 3e). A porta, sem carta, abre para o corredor; descer a escada
## do fim dele vira o dia (_on_escada).
func _hora_de_ir() -> void:
	player.stand()
	player.debrucado = 0.0
	player.fov_forcado = 0.0
	_pode_ir = true
	_saindo = false
	player.input_enabled = true
	Events.notice_requested.emit("Hora de ir para casa.")


func _on_escada(body: Node3D) -> void:
	if body == player and _pode_ir and calha.porta_aberta and not _saindo:
		_pode_ir = false
		_fim_do_dia()


func _fim_do_dia() -> void:
	_saindo = true
	_pode_ir = false
	await SceneDirector.fade_out(1.2)
	if not is_inside_tree():
		return
	SceneDirector.hold_black = true
	Narrator.cancel()
	# A sala de amanhã: o caderno no lugar, a manhã desfeita, a porta fechada,
	# Wilmarth de pé no alto da escada, chegando (Fase 3f).
	lapso.desfazer_manha()
	diario.repor()
	calha.fechar_ja()
	_saiu = false
	_salto_pendente = null
	player.conduzido = false
	player.stand()
	player.debrucado = 0.0
	player.fov_forcado = 0.0
	GameState.set_value(&"sono", 0)
	GameState.add(&"dia", 1)
	GameState.set_value(&"data", _data_inicio())
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
	player.input_enabled = true
	_inicio_do_dia()


## A noite depois do dia `noite` (docs/PLANO_ESCRITORIO.md, "A passagem para o
## sonho"): Wilmarth adormece à mesa e a sala vira a do sonho em volta dele
## (`sonhando` = noite: o conteúdo dos dias some, o grupo `Sonhos/NoiteN`
## aparece; a estética crua no máximo). Ele anda por ela até a flag de
## `sonhos[noite]` (acordar), ou o tempo acabar; então o sono pesa, escurece,
## e ele acorda de manhã, debruçado no diário (e depois vai para casa).
func _sonhar(noite: int) -> void:
	var acordar: StringName = sonhos[noite]
	await _adormecer(noite)
	if not is_inside_tree():
		return
	player.input_enabled = true
	var t := 0.0
	while t < duracao_sonho and not (GameState.has_flag(acordar) and not Events.is_modal_open and not Narrator.is_speaking()):
		await get_tree().process_frame
		if not is_inside_tree():
			return
		t += get_process_delta_time()
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	player.input_enabled = false
	await SceneDirector.fade_out(3.0)
	if not is_inside_tree():
		return
	SceneDirector.hold_black = true
	Narrator.cancel()
	await _acordar(noite)


## A última linha falhou (Diario.anotar): o sono pesa à mesa. As pálpebras caem
## e abrem devagar, a lâmpada baixa, o relógio parado volta a bater; ele encosta
## na cadeira e, de olhos quase fechados, no quase escuro, a sala vira a do
## sonho — sem tela preta. As luzes do sonho sobem enquanto os olhos abrem.
func _adormecer(noite: int) -> void:
	var palpebras := Palpebras.new()
	add_child(palpebras)
	relogio.play()
	var luzes := _luzes_acesas()
	var env := world_env.environment
	var ambiente := env.ambient_light_energy
	_ambientes[env] = ambiente
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_method(_set_sonho, 0.0, 0.35, 7.0)
	for l in luzes:
		t.tween_property(l, ^"light_energy", luzes[l] * 0.4, 7.0)
	for k: Array in [[0.55, 1.6], [0.1, 1.3], [0.8, 2.0], [0.3, 2.0]]:
		await palpebras.fechar(k[0], k[1])
		if not is_inside_tree():
			return

	# Encosta na cadeira; a sala some no escuro.
	player.fov_forcado = 0.0
	var encosta := player.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	encosta.tween_property(player, ^"debrucado", 0.0, 3.0)
	encosta.tween_property(player.head, ^"rotation:x", deg_to_rad(-4.0), 3.0)
	t = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_method(_set_sonho, 0.35, 1.0, 3.0)
	for l in luzes:
		t.tween_property(l, ^"light_energy", 0.0, 3.0)
	t.tween_property(env, ^"ambient_light_energy", ambiente * 0.05, 3.0)
	palpebras.fechar(0.93, 3.0)
	await t.finished
	if not is_inside_tree():
		return

	# A troca, no quase escuro. O disco que embalou o sono para (a noite do
	# disco) — e continua no sonho, de onde parou.
	var disco := -1.0
	for f: Fonografo in get_tree().get_nodes_in_group(&"fonografo"):
		disco = maxf(disco, f.posicao())
	get_tree().call_group(&"fonografo", &"parar")
	GameState.set_value(&"sonhando", noite)
	if noite in sonhos_fora:
		_esconder_sala(true)
		player.stand()
		player.seated = false
	if disco >= 0.0:
		for f: Fonografo in get_tree().get_nodes_in_group(&"fonografo"):
			if f.is_visible_in_tree():
				f.tocar(disco)
	env.ambient_light_energy = ambiente
	_ambientes.erase(env)
	for l in luzes:
		l.light_energy = luzes[l]
	var env_noite_sonho: Environment = ambientes_sonho.get(noite, env_sonho)
	world_env.environment = env_noite_sonho
	AudioDirector.play_ambience(som_sonho, 2.5)
	var acender := _luzes_acesas()
	var sonho_ambiente := env_noite_sonho.ambient_light_energy
	_ambientes[env_noite_sonho] = sonho_ambiente
	env_noite_sonho.ambient_light_energy = 0.0
	t = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	for l in acender:
		l.light_energy = 0.0
		t.tween_property(l, ^"light_energy", acender[l], 3.5)
	t.tween_property(env_noite_sonho, ^"ambient_light_energy", sonho_ambiente, 3.5)
	await palpebras.fechar(0.0, 3.5)
	if not is_inside_tree():
		return
	if t.is_running():
		await t.finished
	_ambientes.erase(env_noite_sonho)
	palpebras.queue_free()


## Some com a sala (estrutura, móveis e tudo da Miskatonic menos os sonhos) para
## um sonho fora dela; e a devolve como estava.
func _esconder_sala(esconder: bool) -> void:
	if not esconder:
		for n in _sala_escondida:
			n.visible = _sala_escondida[n][0]
			n.process_mode = _sala_escondida[n][1]
		_sala_escondida.clear()
		return
	var nos: Array[Node3D] = [$Estrutura as Node3D, $Mobilia as Node3D]
	for n in miskatonic.get_children():
		if n is Node3D and n.name != &"Sonhos":
			nos.append(n)
	for n in nos:
		_sala_escondida[n] = [n.visible, n.process_mode]
		_ativar(n, false)


## De manhã, debruçado na mesa (no escuro do fim do sonho): a sala do dia, o
## diário aberto com a linha borrada, a aurora pela janela — ou largado onde o
## sono o pegou (LugarSono). Os olhos abrem, ele se ergue — e então o dia
## seguinte (_fim_do_dia).
func _acordar(noite: int) -> void:
	get_tree().call_group(&"fonografo", &"parar")
	_esconder_sala(false)
	GameState.set_value(&"sonhando", 0)
	GameState.set_value(&"sonho", 0.0)
	world_env.environment = _ambiente_do_dia()
	AudioDirector.play_ambience(_som_do_dia(), 2.0)
	lapso.amanhecer()
	# O fogo da noite (se houve) se apagou enquanto ele dormia.
	GameState.set_flag(StringName("lareira_dia_%d" % noite), false)
	var lugar := _lugar_sono(noite)
	player.seated = true
	if lugar:
		# A altura do marcador (o chão da sala), não a de onde o sonho o deixou:
		# o chão do bosque não é o da sala.
		player.global_position = lugar.assento.global_position
		player.debrucado = 0.0
		# A cabeça tombada para o peito.
		player.olhar_para(lugar.olhar.global_position + Vector3.DOWN * 0.9, 0.01)
	else:
		player.global_position = diario.cadeira(player)
		player.debrucado = 1.0
		player.olhar_para(diario.pagina(), 0.01)
	# A cabeça desce sozinha (Player._update_head). Os olhos, fechados, abrem
	# como fecharam ao adormecer, ao contrário: pesados, piscando, devagar.
	var palpebras := Palpebras.new()
	palpebras.fechado = 1.0
	add_child(palpebras)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	await SceneDirector.release_black(0.0)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	for k: Array in [[0.7, 2.0], [0.97, 1.3], [0.45, 2.0], [0.85, 1.4], [0.0, 2.6]]:
		await palpebras.fechar(k[0], k[1])
		if not is_inside_tree():
			return
	palpebras.queue_free()
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return
	var t := player.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"debrucado", 0.0, 2.5)
	t.tween_property(player.head, ^"rotation:x", deg_to_rad(-12.0), 2.5)
	if lugar:
		player.olhar_para(lugar.olhar.global_position, 2.5)
	await t.finished
	if not is_inside_tree():
		return
	await get_tree().create_timer(1.2).timeout


## As luzes visíveis da Miskatonic e a energia de cada uma.
func _luzes_acesas() -> Dictionary[Light3D, float]:
	var luzes: Dictionary[Light3D, float] = {}
	for l: Light3D in miskatonic.find_children("*", "Light3D", true, false):
		if l.is_visible_in_tree():
			luzes[l] = l.light_energy
	return luzes


## O dia virou noite sem acabar (Dia 4: a volta de Boston): noiteceu_dia_<N>.
func _anoiteceu() -> bool:
	return GameState.has_flag(StringName("anoiteceu_dia_%d" % dia()))


## Data de hoje na folhinha (dia do ano de 1928).
func _data() -> int:
	return int(GameState.get_value(&"data", _data_inicio()))


func _data_inicio() -> int:
	var n := dia()
	return datas_dia[n] if n < datas_dia.size() else 1


## Vira Wilmarth, devagar, para a janela, de onde o tempo se vê passar.
func _olhar_a_janela() -> void:
	player.olhar_para(Vector3(0.0, 1.55, -3.0), 1.6)


## SceneDirector.time_skip, no escritório: o lapso na própria sala, sem tela
## preta. O jogador fica parado; o cartão aparece no primeiro escuro (é aí que
## o que chega aparece, pela flag `narrou_<cartão>`).
func passar_tempo(cartao: NarrationLine) -> void:
	var de := _data()
	var ate: int = datas_cartao.get(cartao.id, de + 1)
	em_lapso = true
	# Uma cena em curso (ajoelhado acendendo a lareira quando a ligação acaba)
	# termina antes: as duas brigariam pelo corpo e pela cabeça.
	while player.em_cena():
		await get_tree().process_frame
		if not is_inside_tree():
			return
	player.input_enabled = false
	_olhar_a_janela()
	# A fala que veio antes (ex.: a de depois de selar) termina primeiro: o cartão
	# precisa entrar no escuro do lapso, não depois dele.
	while Narrator.is_speaking():
		await get_tree().process_frame
		if not is_inside_tree():
			return
	_cartao_no_lapso = true
	await lapso.passar(de, ate, func() -> void:
		await Narrator.say(cartao, Narrator.Style.CARTAO)
		_cartao_no_lapso = false)
	if not is_inside_tree():
		return
	GameState.set_value(&"data", ate)
	while _cartao_no_lapso:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	player.input_enabled = true
	em_lapso = false


func _ambiente_do_dia() -> Environment:
	var n := dia()
	if _anoiteceu() and env_noite:
		return env_noite
	if n < ambientes_dia.size() and ambientes_dia[n]:
		return ambientes_dia[n]
	return env_dia


func _som_do_dia() -> AudioStream:
	var n := dia()
	if _anoiteceu() and som_noite:
		return som_noite
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
