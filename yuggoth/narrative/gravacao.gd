class_name Gravacao
extends Resource
## Uma gravação com legendas (o disco de Akeley, GDD §5.1 / livro cap. III).
## Cada trecho tem início (s), tipo de voz e legenda. O áudio provisório é
## sintetizado a partir destes trechos (tools/gerar_assets.gd); o definitivo
## só precisa respeitar os mesmos tempos.

enum Tipo { RUIDO, HUMANA, ZUMBIDA }

@export var audio: AudioStream
## Início de cada trecho, em segundos, em ordem.
@export var inicios: PackedFloat32Array = []
## Tipo de voz de cada trecho (Tipo).
@export var tipos: PackedInt32Array = []
## Legenda de cada trecho.
@export var legendas: PackedStringArray = []
## Onde a gravação acaba (o corte abrupto do disco).
@export var duracao := 60.0


func trecho_em(t: float) -> int:
	var i := -1
	for k in inicios.size():
		if inicios[k] <= t:
			i = k
	return i


func fim_do_trecho(i: int) -> float:
	return inicios[i + 1] if i + 1 < inicios.size() else duracao
