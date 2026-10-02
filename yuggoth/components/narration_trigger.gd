class_name NarrationTrigger
extends Area3D
## Fala uma linha do narrador quando o jogador entra na área (GDD §6.5).

@export var line: NarrationLine
@export var condition: Condition
## Não fala de novo se a linha já foi dita (vale entre saves).
@export var once := true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # "mundo", onde está o corpo do Player.
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if line == null or not body.is_in_group(&"player"):
		return
	if once and GameState.has_flag(line.get_said_flag()):
		return
	if condition and not condition.is_met():
		return
	if once:
		set_deferred(&"monitoring", false)
	Narrator.say(line)
