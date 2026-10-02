class_name ReplyOption
extends Resource
## Um tom possível da resposta de Wilmarth (GDD §5.1). O valor do tom é o que
## soma em `crenca` e o que fica gravado em GameState sob o id da resposta.

enum Tom { CETICO = -1, CAUTELOSO = 0, CREDULO = 1 }

@export var tom := Tom.CAUTELOSO
## O que o jogador vê ao escolher: a frase que abre a carta.
@export_multiline var resumo := ""
## A carta inteira. Vai para o dossiê depois de escrita.
@export var document: DocumentData
