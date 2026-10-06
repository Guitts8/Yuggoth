class_name Ligacao
extends Resource
## Uma conversa em legendas — ao telefone (Dia 4, livro cap. III) ou em pessoa
## (Interlocutor: o funcionário do expresso, em Boston): as falas aparecem uma
## por vez. Feita (ou atendida), marca `ligou_<id>`. Pode terminar com uma fala
## do narrador, um salto no tempo e/ou uma troca de fase.

@export var id: StringName
@export var prompt := "Telefonar"
## Disponível quando vale (e enquanto não foi feita).
@export var condition: Condition
## O telefone toca e a ação é atender.
@export var recebida := false
## "Quem: o que diz", em ordem.
@export var falas: PackedStringArray = []
## A cena amolece enquanto dura (GameState.sonho até este valor, e volta): a voz
## de Keene que deixava o funcionário tonto e sonolento.
@export_range(0.0, 1.0, 0.05) var sonho := 0.0
@export var narracao_depois: NarrationLine
## Salto no tempo depois da conversa (ex.: "Sexta-feira, 20 de julho.").
@export var cartao_depois: NarrationLine
## Fase para onde se vai depois (ex.: de noite, a Boston), e o ponto de entrada.
@export_file("*.tscn") var fase_depois := ""
@export var entrada_depois: StringName


func get_done_flag() -> StringName:
	return StringName("ligou_%s" % id)


func disponivel() -> bool:
	return not GameState.has_flag(get_done_flag()) and (condition == null or condition.is_met())
