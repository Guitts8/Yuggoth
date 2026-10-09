extends Control
## Wilmarth escreve a Akeley (GDD §5.1). Primeiro o jogador escolhe como a
## carta começa (o tom); depois ela se escreve sozinha, ao som da pena. Antes
## de escolher dá para desistir (Esc) e voltar depois; escolhida, dá para
## amassar a folha (Esc) e começar outra quantas vezes quiser. Só selar decide.

const CHARS_PER_SECOND := 70.0

@export var pen_sound: AudioStream

var _reply: ReplyData
var _chosen: ReplyOption
var _tween: Tween
## Pena arranhando em loop enquanto a carta se escreve.
var _pen: AudioStreamPlayer
var _opened_frame := -1
var _selando := false

@onready var title_label: Label = %Title
@onready var choices: VBoxContainer = %Choices
@onready var body: RichTextLabel = %Body
@onready var footer: Label = %Footer
@onready var paper: Control = $Paper
@onready var dim: ColorRect = $Dim


func _ready() -> void:
	hide()
	_pen = AudioStreamPlayer.new()
	_pen.stream = pen_sound
	_pen.bus = &"SFX"
	_pen.volume_db = -6.0
	_pen.finished.connect(func() -> void:
		if _tween:
			_pen.play())
	add_child(_pen)
	DocumentData.apply_fonts(body, DocumentData.Style.WILMARTH)
	Events.reply_requested.connect(open)


func open(reply: ReplyData) -> void:
	if reply == null or reply.is_done():
		return
	_reply = reply
	_chosen = null
	_opened_frame = Engine.get_process_frames()
	_repor()
	title_label.text = reply.destinatario
	body.text = ""
	body.hide()
	for child in choices.get_children():
		child.queue_free()
	_mostrar_aberturas()
	show()
	Events.modal(self, true)
	_focar_primeira()


func _mostrar_aberturas() -> void:
	for option in _reply.options:
		var button := Button.new()
		button.text = "“%s”" % option.resumo
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose.bind(option))
		# Tinta sobre papel claro (o tema dos menus é claro sobre escuro).
		button.add_theme_color_override(&"font_color", Color(0.3, 0.24, 0.18))
		for state: StringName in [&"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
			button.add_theme_color_override(state, Color(0.06, 0.04, 0.03))
		button.add_theme_font_size_override(&"font_size", 24)
		choices.add_child(button)
	choices.show()
	footer.text = "Como começar a carta?    [Esc] mais tarde"


func _focar_primeira() -> void:
	for child in choices.get_children():
		if not child.is_queued_for_deletion():
			(child as Button).grab_focus()
			return


## Amassa a folha: de volta às aberturas, nada decidido.
func _recomecar() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_pen.stop()
	_chosen = null
	body.text = ""
	body.hide()
	choices.show()
	footer.text = "Como começar a carta?    [Esc] mais tarde"
	_focar_primeira()


func _choose(option: ReplyOption) -> void:
	_chosen = option
	choices.hide()
	body.text = option.document.resolve_pages()[0] if option.document else option.resumo
	body.visible_ratio = 0.0
	body.show()
	footer.text = "[E] escrever de uma vez    [Esc] recomeçar"
	var length := body.get_parsed_text().length()
	_tween = create_tween()
	_tween.tween_property(body, "visible_ratio", 1.0, length / CHARS_PER_SECOND)
	_tween.tween_callback(_finish_writing)
	_pen.play()


func _finish_writing() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	body.visible_ratio = 1.0
	_pen.stop()
	footer.text = "[E] selar o envelope    [Esc] recomeçar"


func _unhandled_input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	if _selando:
		get_viewport().set_input_as_handled()
		return
	if _chosen == null:
		if event.is_action_pressed(&"ui_cancel"):
			_close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"interagir"):
			# [E] escolhe a opção em foco, como no resto do jogo.
			var focused := get_viewport().gui_get_focus_owner() as Button
			if focused and choices.is_ancestor_of(focused):
				focused.pressed.emit()
				get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel"):
		_recomecar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interagir") or event.is_action_pressed(&"ui_accept"):
		if _tween:
			_finish_writing()  # pressa: mostra o resto de uma vez
		else:
			_seal()
		get_viewport().set_input_as_handled()


## Selar decide na hora; a folha some devagar da tela e a carta passa a existir
## na mesa — a fase dobra, envelopa e sela em 3D (Selagem), ouvindo reply_written.
## Dá para esperar: `await _seal()`.
func _seal() -> void:
	if _selando or _reply == null:
		return
	var reply := _reply
	var option := _chosen
	reply.apply(option)
	_selando = true
	footer.text = ""
	var t := create_tween().set_parallel()
	t.tween_property(paper, ^"modulate:a", 0.0, 0.7)
	t.tween_property(dim, ^"modulate:a", 0.0, 0.9)
	await t.finished
	_selando = false
	_close()
	Events.reply_written.emit(reply, option)


func _close() -> void:
	_reply = null
	_chosen = null
	hide()
	_repor()
	Events.modal(self, false)


func _repor() -> void:
	paper.modulate.a = 1.0
	dim.modulate.a = 1.0