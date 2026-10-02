class_name DocumentPickup
extends Interactable
## Abre um documento no leitor e, opcionalmente, guarda no dossiê.

@export var document: DocumentData
## Guarda no dossiê.
@export var take := true
## Some da cena ao guardar. Desligado para o que fica no lugar (recortes
## pregados no quadro, papéis que ele só copia).
@export var remove_visual := true
## Nó visual removido junto ao pegar (ex.: o mesh do papel). Vazio = o pai.
@export var visual: Node3D


func _ready() -> void:
	super()
	# Já guardado (save carregado, fase recarregada): não volta para a mesa.
	if take and remove_visual and document in GameState.dossier:
		_get_visual().queue_free()


func _get_visual() -> Node3D:
	return visual if visual else get_parent() as Node3D


func _on_interact(_by: Node) -> void:
	if document == null:
		push_warning("%s sem document." % get_path())
		return
	if take:
		GameState.add_document(document)
		if remove_visual and _get_visual():
			_get_visual().queue_free()
	Events.document_requested.emit(document)
