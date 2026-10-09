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

## Há alguma tela aberta (o espelho de modal_changed, para quem precisa consultar
## em vez de escutar).
var is_modal_open := false

## Quem tem uma tela aberta agora. As telas se sobrepõem (o dossiê aberto enquanto
## o diário abria): com um booleano só, fechar uma dava tudo por fechado, e o Esc
## seguinte abria a pausa em vez de fechar o caderno (o macaco, sessão de tester).
var _modais: Dictionary[Object, bool] = {}


## Uma tela abriu (`aberta`) ou fechou. modal_changed só sai quando muda o todo:
## a primeira que abre, a última que fecha.
func modal(dono: Object, aberta: bool) -> void:
	if aberta:
		_modais[dono] = true
	else:
		_modais.erase(dono)
	_atualizar_modal()


func _process(_delta: float) -> void:
	# Uma tela que sumiu sem fechar (a fase trocada no meio) não fica aberta.
	if not _modais.is_empty():
		for dono: Variant in _modais.keys():
			if not is_instance_valid(dono):
				_modais.erase(dono)
		_atualizar_modal()


func _atualizar_modal() -> void:
	var aberta := not _modais.is_empty()
	if aberta != is_modal_open:
		is_modal_open = aberta
		modal_changed.emit(aberta)
