class_name ReplyData
extends Resource
## Resposta de Wilmarth a Akeley no fim de um dia: o jogador escolhe o tom
## (GDD §5.1). Ao escrever: `crenca` += tom, GameState[id] = tom (-1, 0 ou 1,
## para as cartas seguintes variarem com ValueCondition) e a flag
## `escreveu_<id>` marcada.

@export var id: StringName
@export var destinatario := "Ao Sr. Henry W. Akeley"
@export var options: Array[ReplyOption] = []
## Dita depois de selar, no lugar da fala padrão do escritório.
@export var narracao_depois: NarrationLine
## Salto no tempo depois da fala (ex.: Dia 5, "Em resposta, recebi apenas um
## telegrama..."). Ver SceneDirector.time_skip().
@export var cartao_depois: NarrationLine


func get_done_flag() -> StringName:
	return StringName("escreveu_%s" % id)


func is_done() -> bool:
	return GameState.has_flag(get_done_flag())


func apply(option: ReplyOption) -> void:
	GameState.add(&"crenca", option.tom)
	GameState.set_value(id, int(option.tom))
	GameState.set_flag(get_done_flag())
	if option.document:
		GameState.add_document(option.document)
