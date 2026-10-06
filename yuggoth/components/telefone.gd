class_name Telefone
extends Interactable
## Telefone de mesa. Oferece a primeira Ligacao disponível; as que são
## "recebidas" fazem o aparelho tocar até alguém atender. Sem ligação
## disponível, não há interação (nada aparece na mira). Na ligação: o gancho, a
## manivela do magneto (nas que Wilmarth faz), o chiado da linha e, sob cada
## legenda, um murmúrio de voz com o tom de quem fala.

## Segundos de legenda por caractere (com um mínimo por fala).
const SEG_POR_CHAR := 0.055
const SEG_MINIMO := 2.4

## Tom da voz (pitch do murmúrio) por quem fala; os outros variam pelo nome.
const TONS := {"Telefonista": 1.35, "Wilmarth": 0.82}

@export var ligacoes: Array[Ligacao] = []
@export var campainha: AudioStream
@export_group("Som da ligação")
## O fone saindo do gancho e voltando.
@export var gancho: AudioStream
## A manivela do magneto, para chamar a telefonista (ligações feitas).
@export var manivela: AudioStream
## O chiado da linha, em loop, enquanto dura a ligação.
@export var linha: AudioStream
## Um murmúrio de voz sob cada legenda (em loop, com o tom de quem fala).
@export var voz: AudioStream

var _em_ligacao := false
var _toque: AudioStreamPlayer3D
var _linha: AudioStreamPlayer
var _voz: AudioStreamPlayer
var _falas := 0


func _ready() -> void:
	super()
	add_to_group(&"telefone")
	_toque = AudioStreamPlayer3D.new()
	_toque.name = "Campainha"
	_toque.stream = campainha
	_toque.bus = &"SFX"
	_toque.unit_size = 4.0
	add_child(_toque)
	# No ouvido de Wilmarth: 2D.
	_linha = _player("Linha", linha, -20.0)
	_voz = _player("Voz", voz, -14.0)


func _player(nome: String, stream: AudioStream, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = nome
	p.stream = stream
	p.bus = &"Voice"
	p.volume_db = db
	add_child(p)
	return p


func atual() -> Ligacao:
	for l in ligacoes:
		if l and l.disponivel():
			return l
	return null


func em_ligacao() -> bool:
	return _em_ligacao


func can_interact(by: Node) -> bool:
	return super(by) and not _em_ligacao and atual() != null


func _process(_delta: float) -> void:
	var l := atual()
	if l:
		prompt = l.prompt
	var tocar := l != null and l.recebida and not _em_ligacao
	if tocar and not _toque.playing and campainha:
		_toque.play()
	elif not tocar and _toque.playing:
		_toque.stop()


func _on_interact(_by: Node) -> void:
	var l := atual()
	if l:
		_falar(l)


func _falar(l: Ligacao) -> void:
	_em_ligacao = true
	_toque.stop()
	# Ninguém fala ao telefone com o disco tocando: atender levanta a agulha.
	for f: Fonografo in get_tree().get_nodes_in_group(&"fonografo"):
		f.parar()
	AudioDirector.play_sfx(gancho, -6.0)
	if not l.recebida and manivela:
		# Dar manivela: a sineta da telefonista toca do outro lado.
		AudioDirector.play_sfx(manivela, -8.0)
		await get_tree().create_timer(manivela.get_length()).timeout
		if not is_inside_tree():
			return
	if _linha.stream:
		_linha.play()
	for fala in l.falas:
		var segundos := maxf(SEG_MINIMO, fala.length() * SEG_POR_CHAR)
		Events.subtitle_requested.emit(fala, segundos)
		_murmurar(fala.get_slice(":", 0).strip_edges(), segundos * 0.85)
		await get_tree().create_timer(segundos).timeout
		if not is_inside_tree():
			return
	_voz.stop()
	_linha.stop()
	AudioDirector.play_sfx(gancho, -6.0)
	GameState.set_flag(l.get_done_flag())
	if l.cartao_depois:
		await SceneDirector.time_skip(l.cartao_depois)
		if not is_inside_tree():
			return
	if l.narracao_depois:
		Narrator.say(l.narracao_depois)
	_em_ligacao = false


## A voz de quem fala, sem palavras, pelo tempo da legenda. Wilmarth fala na
## sala (mais baixo e mais grave); os outros vêm pela linha.
func _murmurar(quem: String, segundos: float) -> void:
	if _voz.stream == null:
		return
	var tom: float = TONS.get(quem, 0.92 + float(absi(quem.hash()) % 100) / 400.0)
	_voz.pitch_scale = tom
	_voz.volume_db = -20.0 if quem == "Wilmarth" else -14.0
	_voz.play(randf() * _voz.stream.get_length())
	_falas += 1
	var esta := _falas
	await get_tree().create_timer(segundos).timeout
	# Só para se a fala seguinte não recomeçou a voz.
	if is_inside_tree() and esta == _falas:
		_voz.stop()
