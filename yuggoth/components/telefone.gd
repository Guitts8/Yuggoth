class_name Telefone
extends Interactable
## Telefone de mesa. Oferece a primeira Ligacao disponível; as que são
## "recebidas" fazem o aparelho tocar até alguém atender. Sem ligação
## disponível, não há interação (nada aparece na mira).

## Segundos de legenda por caractere (com um mínimo por fala).
const SEG_POR_CHAR := 0.055
const SEG_MINIMO := 2.4

@export var ligacoes: Array[Ligacao] = []
@export var campainha: AudioStream

var _em_ligacao := false
var _toque: AudioStreamPlayer3D


func _ready() -> void:
	super()
	add_to_group(&"telefone")
	_toque = AudioStreamPlayer3D.new()
	_toque.name = "Campainha"
	_toque.stream = campainha
	_toque.bus = &"SFX"
	_toque.unit_size = 4.0
	add_child(_toque)


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
	for fala in l.falas:
		var segundos := maxf(SEG_MINIMO, fala.length() * SEG_POR_CHAR)
		Events.subtitle_requested.emit(fala, segundos)
		await get_tree().create_timer(segundos).timeout
		if not is_inside_tree():
			return
	GameState.set_flag(l.get_done_flag())
	if l.cartao_depois:
		await SceneDirector.time_skip(l.cartao_depois)
		if not is_inside_tree():
			return
	if l.narracao_depois:
		Narrator.say(l.narracao_depois)
	_em_ligacao = false
