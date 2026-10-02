class_name NarrationLine
extends Resource
## Frase do narrador: Wilmarth escrevendo o relato (GDD §3.1, §6.5).
## O texto é a primeira variante cuja condição vale; senão, `text`.
## Com `exposicao` alta a linha pode virar discrepância: o narrador afirma uma
## coisa e a cena mostra outra. Quem decide é o Narrator; a cena reage ao flag
## `discrepancia_<id>` (ex.: com um ConditionalNode).

@export var id: StringName
## BBCode. Aceita [sussurro]...[/sussurro].
@export_multiline var text := ""
@export var variants: Array[NarrationVariant] = []

@export_group("Discrepância")
## Exposição mínima para virar discrepância. Negativo = nunca; 0 = sempre
## (respeitando o limite por jogada).
@export_range(-1.0, 1.0, 0.05) var discrepancy_exposure := -1.0
## Dito no lugar do texto quando vira discrepância. Vazio = o mesmo texto;
## só a cena muda.
@export_multiline var discrepancy_text := ""


func resolve_text() -> String:
	for variant in variants:
		if variant and (variant.condition == null or variant.condition.is_met()):
			return variant.text
	return text


func get_said_flag() -> StringName:
	return StringName("narrou_%s" % id)


func get_discrepancy_flag() -> StringName:
	return StringName("discrepancia_%s" % id)
