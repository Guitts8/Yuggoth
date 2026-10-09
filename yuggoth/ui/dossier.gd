extends Control
## Dossiê: todos os documentos coletados, para releitura a qualquer momento.
## Reler é como o jogador descobre que um texto mudou (GDD §6.2).

@onready var list: ItemList = %List


func _ready() -> void:
	hide()
	list.item_activated.connect(_open_document)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dossie"):
		if visible:
			close()
		elif not Events.is_modal_open:
			open()
		else:
			return
	elif visible and event.is_action_pressed(&"ui_cancel"):
		close()
	elif visible and event.is_action_pressed(&"interagir") and list.is_anything_selected():
		_open_document(list.get_selected_items()[0])
	else:
		return
	get_viewport().set_input_as_handled()


func open() -> void:
	list.clear()
	for doc in GameState.dossier:
		list.add_item(doc.title)
	show()
	Events.modal(self, true)
	if list.item_count > 0:
		list.select(0)
		list.grab_focus()


func close() -> void:
	hide()
	Events.modal(self, false)


func _open_document(index: int) -> void:
	var doc := GameState.dossier[index]
	close()
	Events.document_requested.emit(doc)
