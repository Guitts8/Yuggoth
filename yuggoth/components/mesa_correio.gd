class_name MesaCorreio
extends Interactable
## A escrivaninha enquanto há correspondência na mão: mirar o tampo e "Pôr na
## mesa" (Correspondencia.pousar). Sem nada na mão, sai da mira e da física —
## não tampa o que está sobre a mesa.

var _forma: CollisionShape3D


func _ready() -> void:
	super()
	_forma = get_node(^"CollisionShape3D")
	_atualizar()


func _physics_process(_delta: float) -> void:
	_atualizar()


func can_interact(by: Node) -> bool:
	return super(by) and Correspondencia.na_mao != null


func _atualizar() -> void:
	var on := Correspondencia.na_mao != null
	if visible != on or _forma.disabled == on:
		visible = on
		_forma.set_deferred(&"disabled", not on)


func _on_interact(_by: Node) -> void:
	Correspondencia.na_mao.pousar()
