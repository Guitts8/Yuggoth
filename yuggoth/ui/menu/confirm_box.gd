class_name ConfirmBox
extends VBoxContainer
## Pergunta sim/não dentro de um menu, no lugar dos botões dele.
## `if await confirm.ask("Apagar?", botoes): ...` — Esc conta como não.

signal _answered(yes: bool)

var _label: Label
var _yes: Button
var _no: Button


func _ready() -> void:
	hide()
	add_theme_constant_override(&"separation", 24)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = 480
	add_child(_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 40)
	add_child(row)
	_yes = Button.new()
	_no = Button.new()
	row.add_child(_yes)
	row.add_child(_no)
	_yes.pressed.connect(func() -> void: _answered.emit(true))
	_no.pressed.connect(func() -> void: _answered.emit(false))


## Esconde `replacing` enquanto pergunta. O foco começa no "não".
func ask(text: String, replacing: Control, yes_text := "Sim", no_text := "Voltar") -> bool:
	_label.text = text
	_yes.text = yes_text
	_no.text = no_text
	replacing.hide()
	show()
	_no.grab_focus()
	var yes: bool = await _answered
	hide()
	replacing.show()
	return yes


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_answered.emit(false)
		get_viewport().set_input_as_handled()
