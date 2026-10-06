class_name StateInteractable
extends Interactable
## Altera valores de GameState ao ser usado (avançar dia, marcar flag...).

@export var changes: Dictionary[StringName, float] = {}
## Soma aos valores atuais em vez de substituí-los.
@export var additive := true
@export_multiline var notice := ""
## Dita pelo narrador ao usar (ex.: a frase do livro sobre o que Wilmarth fez).
@export var narration: NarrationLine
## Tocado ao usar (ex.: o fósforo riscado na lareira).
@export var som: AudioStream


func _on_interact(_by: Node) -> void:
	for key in changes:
		if additive:
			GameState.add(key, changes[key])
		else:
			GameState.set_value(key, changes[key])
	if som:
		AudioDirector.play_sfx(som, -4.0)
	if not notice.is_empty():
		Events.notice_requested.emit(notice)
	if narration:
		Narrator.say(narration)
