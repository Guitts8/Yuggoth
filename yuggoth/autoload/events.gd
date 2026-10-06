extends Node
## Barramento global de sinais. Estado narrativo vive em GameState, não aqui.

signal document_requested(doc: DocumentData)
signal document_closed(doc: DocumentData)
signal examine_requested(target: Examinable)
signal examine_closed(target: Examinable)
signal modal_changed(is_open: bool)
signal interaction_target_changed(target: Interactable)
signal notice_requested(text: String)
signal lamp_changed(intensity: float)
signal reply_requested(reply: ReplyData)
signal reply_written(reply: ReplyData, option: ReplyOption)
## Legenda de um som (voz no disco, ruídos); some depois de `seconds`.
signal subtitle_requested(text: String, seconds: float)
## Uma fase encerrou o jogo (fim da demo): o GameRoot volta ao menu principal.
signal quit_to_menu_requested

## Espelho do último modal_changed, para quem precisa consultar em vez de escutar.
var is_modal_open := false


func _ready() -> void:
	modal_changed.connect(func(is_open: bool) -> void: is_modal_open = is_open)
