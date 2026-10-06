class_name Boston
extends Node3D
## Vinheta (docs/PLANO_ESCRITORIO.md, Fase 3b; livro cap. III): na noite de
## sexta, 20 de julho, Wilmarth vai a Boston falar com o funcionário do expresso
## do trem 5508, no quarto de pensão dele. Três perguntas (Interlocutor), a voz
## de Keene que amolece a sala, e nada de novo. A porta leva de volta a Arkham:
## o escritório já de noite (`anoiteceu_dia_4`), para as cartas da madrugada.
##
## Cena gerada por tools/gerar_boston.gd.

const ESCRITORIO := "res://levels/escritorio/escritorio.tscn"

@export var linha_chegada: NarrationLine
@export var som: AudioStream

var _saindo := false

@onready var saida: Interactable = %Saida
@onready var player: Player = $Player


func _ready() -> void:
	player.lamp.available = false
	AudioDirector.play_ambience(som)
	saida.interacted.connect(_voltar)
	# A troca de fase pausa a árvore; isto continua quando ela soltar.
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree() and linha_chegada and not GameState.has_flag(linha_chegada.get_said_flag()):
		Narrator.say(linha_chegada)


func _voltar(_by: Node) -> void:
	if _saindo:
		return
	_saindo = true
	GameState.set_flag(&"voltou_de_boston")
	GameState.set_flag(&"anoiteceu_dia_4")
	SceneDirector.change_level(ESCRITORIO, &"Porta")
