class_name WriteReply
extends Interactable
## Sentar para responder a Akeley. Só aparece quando `condition` vale (ex.: ter
## lido a carta do dia) e enquanto a resposta não foi escrita.

@export var reply: ReplyData


func can_interact(by: Node) -> bool:
	return super(by) and reply != null and not reply.is_done()


func _on_interact(_by: Node) -> void:
	Events.reply_requested.emit(reply)
