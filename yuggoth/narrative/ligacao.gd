class_name Ligacao
extends Resource
## Um telefonema (Dia 4, livro cap. III): as falas aparecem como legendas, uma
## por vez. Feita (ou atendida), marca `ligou_<id>`. Pode terminar com uma fala
## do narrador e/ou um salto no tempo (cartão em tela preta).

@export var id: StringName
@export var prompt := "Telefonar"
## Disponível quando vale (e enquanto não foi feita).
@export var condition: Condition
## O telefone toca e a ação é atender.
@export var recebida := false
## "Quem: o que diz", em ordem.
@export var falas: PackedStringArray = []
@export var narracao_depois: NarrationLine
## Salto no tempo depois da ligação (ex.: "Sexta-feira, 20 de julho.").
@export var cartao_depois: NarrationLine


func get_done_flag() -> StringName:
	return StringName("ligou_%s" % id)


func disponivel() -> bool:
	return not GameState.has_flag(get_done_flag()) and (condition == null or condition.is_met())
