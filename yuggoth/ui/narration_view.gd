extends Control
## Mostra as linhas do Narrator como texto que vai sendo escrito.
## Fica numa CanvasLayer acima do fade do SceneDirector, para os cartões
## aparecerem sobre a tela preta, e roda mesmo com a árvore pausada.

const CHARS_PER_SECOND := 38.0
const HOLD_BASE := 2.2
const HOLD_PER_CHAR := 0.035
const FADE_TIME := 0.8

const FADE_PULO := 0.2

var _label: RichTextLabel
var _tween: Tween

@onready var caption: RichTextLabel = %Caption
@onready var card: RichTextLabel = %Card


func _ready() -> void:
	for label: RichTextLabel in [caption, card]:
		label.install_effect(WhisperTextEffect.new())
		label.hide()
	Narrator.line_started.connect(_show_line)
	Narrator.line_cancelled.connect(_cancel)
	Narrator.pular_pedido.connect(_pular)
	Events.modal_changed.connect(_on_modal_changed)


func _show_line(text: String, style: Narrator.Style) -> void:
	_label = card if style == Narrator.Style.CARTAO else caption
	if _label == caption:
		_vestir_voz()
	_label.text = text
	_label.visible_ratio = 0.0
	_label.modulate.a = 1.0
	_label.show()

	var length := _label.get_parsed_text().length()
	_tween = create_tween()
	_tween.tween_property(_label, "visible_ratio", 1.0, length / CHARS_PER_SECOND)
	_tween.tween_interval(HOLD_BASE + length * HOLD_PER_CHAR)
	_tween.tween_property(_label, "modulate:a", 0.0, FADE_TIME)
	_tween.tween_callback(_on_line_done)
	if _label == caption and Events.is_modal_open:
		_on_modal_changed(true)


## A legenda na letra de quem narra: Akeley, na fazenda, com a mão trêmula das
## cartas de agosto em diante; Wilmarth, a fonte da interface.
func _vestir_voz() -> void:
	var akeley := Narrator.voz == Narrator.Voz.AKELEY
	if caption.get_meta(&"akeley", false) == akeley:
		return
	caption.set_meta(&"akeley", akeley)
	if akeley:
		# O que a legenda tinha antes (para voltar à voz de Wilmarth).
		if not caption.has_meta(&"original"):
			var original := {&"line_separation": caption.get_theme_constant(&"line_separation")}
			for slot in DocumentData.FONT_SLOTS:
				original[slot] = caption.get_theme_font(slot) if caption.has_theme_font_override(slot) else null
				original[StringName(String(slot) + "_size")] = caption.get_theme_font_size(StringName(String(slot) + "_size"))
			caption.set_meta(&"original", original)
		DocumentData.apply_fonts(caption, DocumentData.Style.MANUSCRITO)
		if not caption.has_meta(&"tremor"):
			caption.set_meta(&"tremor", true)
			caption.install_effect(TremorTextEffect.new())
		return
	var de: Dictionary = caption.get_meta(&"original", {})
	if de.is_empty():
		return
	for slot in DocumentData.FONT_SLOTS:
		if de[slot]:
			caption.add_theme_font_override(slot, de[slot])
		else:
			caption.remove_theme_font_override(slot)
		caption.add_theme_font_size_override(StringName(String(slot) + "_size"), de[StringName(String(slot) + "_size")])
	caption.add_theme_constant_override(&"line_separation", de[&"line_separation"])


func _cancel() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	if _label:
		_label.hide()
		_label = null


## Espaço pula a fala (`pular_fala`). Era o E sem nada na mira (playtest 7), mas
## o E da ação pulava falas sem querer (playtest 8): agora é um botão só dele.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pular_fala") or event.is_echo():
		return
	if Events.is_modal_open:
		return
	Narrator.pular()


func _pular() -> void:
	if _label == null or _tween == null or not _label.visible:
		return
	_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, FADE_PULO)
	_tween.tween_callback(_on_line_done)


func _on_line_done() -> void:
	_label.hide()
	_label = null
	_tween = null
	Narrator.finish()


## Legendas esperam o jogador fechar documentos e o dossiê; cartões não.
func _on_modal_changed(is_open: bool) -> void:
	if _label != caption or _tween == null:
		return
	caption.visible = not is_open
	if is_open:
		_tween.pause()
	else:
		_tween.play()
