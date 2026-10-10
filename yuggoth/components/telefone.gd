class_name Telefone
extends Interlocutor
## Telefone de parede: um Interlocutor com aparelho. As ligações "recebidas"
## fazem o aparelho tocar até alguém atender. Na ligação: o gancho, a manivela
## do magneto (nas que Wilmarth faz) e o chiado da linha; atender levanta a
## agulha do fonógrafo.

@export var campainha: AudioStream
@export_group("Som da ligação")
## O fone saindo do gancho e voltando.
@export var gancho: AudioStream
## A manivela do magneto, para chamar a telefonista (ligações feitas).
@export var manivela: AudioStream
## O chiado da linha, em loop, enquanto dura a ligação.
@export var linha: AudioStream

var _toque: AudioStreamPlayer3D
var _linha: AudioStreamPlayer


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
	_linha = AudioStreamPlayer.new()
	_linha.name = "Linha"
	_linha.stream = linha
	_linha.bus = &"Voice"
	_linha.volume_db = -20.0
	add_child(_linha)


func em_ligacao() -> bool:
	return em_conversa()


func _process(delta: float) -> void:
	super(delta)
	var l := atual()
	var tocar := l != null and l.recebida and not _em_conversa
	if tocar and not _toque.playing and campainha:
		_toque.play()
	elif not tocar and _toque.playing:
		_toque.stop()


func _comecar(l: Ligacao) -> void:
	_toque.stop()
	# Ninguém fala ao telefone com o disco tocando: atender levanta a agulha.
	for f: Fonografo in get_tree().get_nodes_in_group(&"fonografo"):
		f.parar()
	AudioDirector.play_sfx(gancho, -6.0)
	if not l.recebida and l.com_manivela and manivela:
		# Dar manivela: a sineta da telefonista toca do outro lado.
		AudioDirector.play_sfx(manivela, -8.0)
		await get_tree().create_timer(manivela.get_length()).timeout
		if not is_inside_tree():
			return
	if _linha.stream:
		_linha.play()


func _terminar(_l: Ligacao) -> void:
	_linha.stop()
	AudioDirector.play_sfx(gancho, -6.0)
