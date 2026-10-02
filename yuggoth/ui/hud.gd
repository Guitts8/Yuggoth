extends Control
## Retícula, texto de interação e avisos curtos. Sem HUD permanente (GDD §8.3).

var _notice_tween: Tween
var _subtitle_tween: Tween

@onready var reticle: Control = %Reticle
@onready var prompt: Label = %Prompt
@onready var notice: Label = %Notice
@onready var subtitle: Label = %Subtitle


func _ready() -> void:
	prompt.text = ""
	notice.modulate.a = 0.0
	subtitle.text = ""
	reticle.modulate.a = 0.35
	Events.interaction_target_changed.connect(_on_target_changed)
	Events.notice_requested.connect(_on_notice_requested)
	Events.subtitle_requested.connect(_on_subtitle_requested)
	Events.modal_changed.connect(func(is_open: bool) -> void: visible = not is_open)


func _on_target_changed(target: Interactable) -> void:
	prompt.text = target.prompt if target else ""
	reticle.modulate.a = 1.0 if target else 0.35


func _on_notice_requested(text: String) -> void:
	notice.text = text
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_property(notice, "modulate:a", 1.0, 0.6)
	_notice_tween.tween_interval(2.8)
	_notice_tween.tween_property(notice, "modulate:a", 0.0, 1.4)


## Legendas de som (GDD §8.3): sempre visíveis, embaixo, até a próxima ou o tempo acabar.
func _on_subtitle_requested(text: String, seconds: float) -> void:
	subtitle.text = text
	subtitle.modulate.a = 1.0
	if _subtitle_tween:
		_subtitle_tween.kill()
	_subtitle_tween = create_tween()
	_subtitle_tween.tween_interval(seconds)
	_subtitle_tween.tween_property(subtitle, "modulate:a", 0.0, 0.5)
