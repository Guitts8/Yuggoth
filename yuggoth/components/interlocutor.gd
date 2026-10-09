class_name Interlocutor
extends Interactable
## Alguém com quem conversar, em legendas ("Quem: texto", Ligacao). Oferece a
## primeira conversa disponível; sem nenhuma, some da mira. Sob cada legenda, um
## murmúrio de voz sem palavras, com o tom de quem fala. Feita, marca
## `ligou_<id>` e pode terminar com narração, salto no tempo ou troca de fase.
## O Telefone é um Interlocutor com aparelho (campainha, gancho, linha).

## Segundos de legenda por caractere (com um mínimo por fala).
const SEG_POR_CHAR := 0.055
const SEG_MINIMO := 2.4
## Tom da voz (pitch do murmúrio) por quem fala; os outros variam pelo nome.
const TONS := {"Telefonista": 1.35, "Wilmarth": 0.82}

@export var conversas: Array[Ligacao] = []
## Um murmúrio de voz sob cada legenda (em loop, com o tom de quem fala).
@export var voz: AudioStream
@export var voz_db := -14.0
@export_group("Opções")
## Em pessoa (Fase 3e: "opções de diálogo embaixo, como Skyrim"): usar abre as
## conversas disponíveis para escolher (o `prompt` de cada uma) e a despedida;
## depois de cada uma, as que restam. Sem isto, vai a primeira disponível (o telefone).
@export var com_opcoes := false
@export var despedida := "Despedir-se"
@export var prompt_opcoes := "Falar"
## Dita uma vez ao fim de uma conversa em que `fim_depois_de` já foi feita.
@export var narracao_fim: NarrationLine
@export var fim_depois_de: Ligacao

var _em_conversa := false
var _voz: AudioStreamPlayer
var _falas := 0
var _sonho: Tween


func _ready() -> void:
	super()
	_voz = AudioStreamPlayer.new()
	_voz.name = "Voz"
	_voz.stream = voz
	_voz.bus = &"Voice"
	add_child(_voz)
	_atualizar_prompt()


func atual() -> Ligacao:
	for l in conversas:
		if l and l.disponivel():
			return l
	return null


func em_conversa() -> bool:
	return _em_conversa


func can_interact(by: Node) -> bool:
	return super(by) and not _em_conversa and atual() != null


func _process(_delta: float) -> void:
	_atualizar_prompt()


func _atualizar_prompt() -> void:
	var l := atual()
	if l:
		# Com opções, a primeira conversa ainda não feita dá o aviso (a de abrir).
		prompt = prompt_opcoes if com_opcoes and _feitas() > 0 else l.prompt


func _feitas() -> int:
	return conversas.filter(func(l: Ligacao) -> bool: return l and GameState.has_flag(l.get_done_flag())).size()


func _on_interact(_by: Node) -> void:
	var l := atual()
	if l == null:
		return
	if com_opcoes:
		_conversar()
	else:
		_falar(l)


## A conversa com opções: escolhe, ouve, volta às opções que restam, até a
## despedida (ou não sobrar nenhuma).
func _conversar() -> void:
	_em_conversa = true
	while true:
		var disponiveis: Array[Ligacao] = []
		for l in conversas:
			if l and l.disponivel():
				disponiveis.append(l)
		if disponiveis.is_empty():
			break
		var frases := PackedStringArray()
		for l in disponiveis:
			frases.append(l.prompt)
		frases.append(despedida)
		var i := await OpcoesConversa.escolher(self, frases)
		if not is_inside_tree():
			return
		if i < 0 or i >= disponiveis.size():
			break
		await _dizer(disponiveis[i])
		if not is_inside_tree():
			return
	_em_conversa = false
	if narracao_fim and (fim_depois_de == null or GameState.has_flag(fim_depois_de.get_done_flag())) \
			and not GameState.has_flag(narracao_fim.get_said_flag()):
		Narrator.say(narracao_fim)


## Antes da primeira fala (o Telefone tira o fone do gancho). Pode esperar.
func _comecar(_l: Ligacao) -> void:
	pass


## Depois da última fala.
func _terminar(_l: Ligacao) -> void:
	pass


func _falar(l: Ligacao) -> void:
	_em_conversa = true
	await _dizer(l)
	if not is_inside_tree():
		return
	_em_conversa = false
	if not l.fase_depois.is_empty():
		SceneDirector.change_level(l.fase_depois, l.entrada_depois)


## Uma conversa, do começo ao fim (as falas e o que vem depois dela, menos a
## troca de fase).
func _dizer(l: Ligacao) -> void:
	await _comecar(l)
	if not is_inside_tree():
		return
	if l.sonho > 0.0:
		_amolecer(l.sonho, 2.0)
	for fala in l.falas:
		var segundos := maxf(SEG_MINIMO, fala.length() * SEG_POR_CHAR)
		Events.subtitle_requested.emit(fala, segundos)
		_murmurar(fala.get_slice(":", 0).strip_edges(), segundos * 0.85)
		var pulou := await Narrator.esperar_fala(segundos)
		if not is_inside_tree():
			return
		if pulou and fala == l.falas[-1]:
			Events.subtitle_requested.emit("", 0.0)
	_voz.stop()
	if l.sonho > 0.0:
		_amolecer(0.0, 3.0)
	_terminar(l)
	GameState.set_flag(l.get_done_flag())
	if l.cartao_depois:
		await SceneDirector.time_skip(l.cartao_depois)
		if not is_inside_tree():
			return
	if l.narracao_depois:
		if l.fase_depois.is_empty():
			Narrator.say(l.narracao_depois)
		else:
			await Narrator.say(l.narracao_depois)


func _amolecer(ate: float, segundos: float) -> void:
	if _sonho:
		_sonho.kill()
	_sonho = create_tween()
	_sonho.tween_method(func(v: float) -> void: GameState.set_value(&"sonho", v),
		GameState.get_number(&"sonho"), ate, segundos)


## A voz de quem fala, sem palavras, pelo tempo da legenda. Wilmarth (o jogador)
## mais baixo e mais grave.
func _murmurar(quem: String, segundos: float) -> void:
	if _voz.stream == null:
		return
	var tom: float = TONS.get(quem, 0.92 + float(absi(quem.hash()) % 100) / 400.0)
	_voz.pitch_scale = tom
	_voz.volume_db = voz_db - 6.0 if quem == "Wilmarth" else voz_db
	_voz.play(randf() * _voz.stream.get_length())
	_falas += 1
	var esta := _falas
	await get_tree().create_timer(segundos).timeout
	# Só para se a fala seguinte não recomeçou a voz.
	if is_inside_tree() and esta == _falas:
		_voz.stop()


func _exit_tree() -> void:
	# Saindo no meio de uma conversa que amolecia a cena, a cena endurece de novo.
	if _sonho and _sonho.is_valid():
		_sonho.kill()
		GameState.set_value(&"sonho", 0.0)
