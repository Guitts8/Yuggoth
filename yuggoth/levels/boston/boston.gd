class_name Boston
extends Node3D
## Vinheta (docs/PLANO_ESCRITORIO.md, Fase 3b/3c; livro cap. III): na noite de
## sexta, 20 de julho, Wilmarth vai a Boston falar com o funcionário do expresso
## do trem 5508, na pensão onde ele mora. Bate à porta do quarto; o rapaz abre
## uma fresta e responde dali (Interlocutor), franco e gentil, sem convidar a
## entrar; a voz de Keene amolece o corredor, e nada de novo. A escada leva de
## volta a Arkham: o escritório já de noite (`anoiteceu_dia_4`).
##
## Cena gerada por tools/gerar_boston.gd.

const ESCRITORIO := "res://levels/escritorio/escritorio.tscn"

@export var linha_chegada: NarrationLine
@export var som: AudioStream
@export var som_rangido: AudioStream
## Quanto a porta abre, em graus (para dentro do quarto).
@export var fresta := 50.0

var _saindo := false

@onready var saida: Interactable = %Saida
@onready var descida: Area3D = %Descida
@onready var folha: Node3D = %Folha
@onready var bater: Interactable = %Bater
@onready var player: Player = $Player


func _ready() -> void:
	player.lamp.available = false
	AudioDirector.play_ambience(som)
	saida.interacted.connect(_voltar)
	descida.body_entered.connect(_on_descida)
	if GameState.has_flag(&"porta_aberta_boston"):
		folha.rotation_degrees.y = fresta
		_tirar_bater()
	else:
		GameState.value_changed.connect(_on_value_changed)
	# A troca de fase pausa a árvore; isto continua quando ela soltar.
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree() and linha_chegada and not GameState.has_flag(linha_chegada.get_said_flag()):
		Narrator.say(linha_chegada)


func _on_value_changed(key: StringName, _value: Variant) -> void:
	if key == &"bateu_boston":
		GameState.value_changed.disconnect(_on_value_changed)
		_abrir()


## Uns segundos de silêncio depois das batidas; o trinco; a porta abre só um pouco.
func _abrir() -> void:
	await get_tree().create_timer(2.2).timeout
	if not is_inside_tree():
		return
	var ranger := AudioStreamPlayer3D.new()
	ranger.stream = som_rangido
	ranger.bus = &"SFX"
	folha.add_child(ranger)
	ranger.play()
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(folha, ^"rotation_degrees:y", fresta, 1.3)
	await t.finished
	if is_inside_tree():
		_tirar_bater()
		GameState.set_flag(&"porta_aberta_boston")


## Usada, a área de bater sai da física: ficava entre a mira e o rosto do rapaz.
func _tirar_bater() -> void:
	bater.visible = false
	(bater.get_node(^"CollisionShape3D") as CollisionShape3D).set_deferred(&"disabled", true)


## Descendo a escada até o patamar, com a conversa feita, ele vai (playtest 8);
## antes dela, a escada é só escada.
func _on_descida(corpo: Node3D) -> void:
	if corpo == player and saida.can_interact(player):
		_voltar(player)


func _voltar(_by: Node) -> void:
	if _saindo:
		return
	_saindo = true
	GameState.set_flag(&"voltou_de_boston")
	GameState.set_flag(&"anoiteceu_dia_4")
	SceneDirector.change_level(ESCRITORIO, &"Porta")
