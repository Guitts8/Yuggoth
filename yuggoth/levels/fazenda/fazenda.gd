class_name Fazenda
extends Node3D
## A fazenda de Henry Akeley, na encosta da Dark Mountain (docs/PLANO_FAZENDA.md).
## A mesma planta serve ao Interlúdio (habitada, setembro de 1928, jogando como
## Akeley) e ao Ato III (abandonada, Wilmarth). F1: a planta em bloco — anda-se
## por tudo (o quintal, a casa nos dois andares, as dependências), ainda sem os
## beats.
##
## Cena gerada por tools/gerar_fazenda.gd.

@export var som: AudioStream

@onready var player: Player = $Player


func _ready() -> void:
	player.lamp.available = false
	if som:
		AudioDirector.play_ambience(som)
