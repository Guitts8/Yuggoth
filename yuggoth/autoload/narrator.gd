extends Node
## Linhas do narrador, uma por vez, e a decisão de discrepâncias (GDD §6.5).
## A exibição fica no NarrationView, que avisa o fim com finish().

signal line_started(text: String, style: Style)
signal line_finished
## A linha atual foi interrompida (troca de fase, volta ao menu).
signal line_cancelled

enum Style {
	## Sobre o jogo, no alto da tela. Pausa enquanto um modal está aberto.
	LEGENDA,
	## Centralizado e grande, para tela preta (aberturas de capítulo, Prólogo).
	CARTAO,
}

## Teto de discrepâncias por jogada.
const MAX_DISCREPANCIES := 6

var _speaking := false
## Muda a cada cancel(): falas que esperavam na fila de antes são descartadas.
var _generation := 0


## Espera a vez e a exibição completa: `await Narrator.say(linha)` em sequências.
func say(line: NarrationLine, style := Style.LEGENDA) -> void:
	if line == null:
		return
	var generation := _generation
	while _speaking:
		await line_finished
		if generation != _generation:
			return
	var text := resolve(line)
	if text.is_empty() or line_started.get_connections().is_empty():
		return
	_speaking = true
	line_started.emit(text, style)
	await line_finished
	_speaking = false


## Há uma linha na tela (as da fila esperam por ela).
func is_speaking() -> bool:
	return _speaking


## Decide variante e discrepância no momento em que a linha é mostrada.
func resolve(line: NarrationLine) -> String:
	GameState.set_flag(line.get_said_flag())
	var text := line.resolve_text()
	if _is_discrepancy(line) and not line.discrepancy_text.is_empty():
		text = line.discrepancy_text
	return text


func finish() -> void:
	line_finished.emit()


## Some com a linha na tela. Quem esperava por ela segue em frente.
func cancel() -> void:
	_generation += 1
	if _speaking:
		line_cancelled.emit()
		line_finished.emit()


func _is_discrepancy(line: NarrationLine) -> bool:
	if line.discrepancy_exposure < 0.0:
		return false
	var flag := line.get_discrepancy_flag()
	# Uma vez discrepante, sempre discrepante: a cena não pode "desver".
	if GameState.has_flag(flag):
		return true
	if GameState.get_number(&"exposicao") < line.discrepancy_exposure:
		return false
	if GameState.get_number(&"discrepancias") >= MAX_DISCREPANCIES:
		return false
	GameState.add(&"discrepancias", 1)
	GameState.set_flag(flag)
	return true
