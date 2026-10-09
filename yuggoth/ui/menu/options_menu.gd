class_name OptionsMenu
extends Control
## Opções mínimas do marco E: volumes, mouse e tela — duas páginas do livro dos
## menus (Livro): o som à esquerda, o mouse e a tela à direita. Muda Settings ao
## vivo; grava no disco ao fechar. Quem abre passa a foto da página que sai (a
## folha vira); ao fechar, `foto_saida` é a da página esquerda, para quem abriu
## virar de volta.

signal closed

## [chave em Settings, rótulo, mínimo, máximo, passo, formato do valor]
## A última coluna: a página (esquerda = o som).
const SLIDERS := [
	[&"volume_Master", "Volume geral", 0.0, 1.0, 0.05, "%d%%", true],
	[&"volume_Music", "Música", 0.0, 1.0, 0.05, "%d%%", true],
	[&"volume_Ambience", "Ambiente", 0.0, 1.0, 0.05, "%d%%", true],
	[&"volume_SFX", "Efeitos", 0.0, 1.0, 0.05, "%d%%", true],
	[&"volume_Voice", "Vozes", 0.0, 1.0, 0.05, "%d%%", true],
	[&"sensibilidade", "Sensibilidade", 0.25, 3.0, 0.05, "%.2f×", false],
]
const TOGGLES := [
	[&"inverter_y", "Inverter eixo vertical"],
	[&"tela_cheia", "Tela cheia"],
]

var _sliders: Dictionary[StringName, HSlider] = {}
var _toggles: Dictionary[StringName, Button] = {}
## A página esquerda como estava ao fechar (para quem abriu virar a folha de volta).
var foto_saida: Texture2D

@onready var livro: Livro = $Livro
@onready var rows: VBoxContainer = %Rows
@onready var rows_esquerda: VBoxContainer = %RowsEsquerda
@onready var back_button: Button = %Voltar
@onready var reset_button: Button = %Restaurar


func _ready() -> void:
	hide()
	for s: Array in SLIDERS:
		_add_slider(s[0], s[1], s[2], s[3], s[4], s[5], rows_esquerda if s[6] else rows)
	for t: Array in TOGGLES:
		_add_toggle(t[0], t[1])
	back_button.pressed.connect(close)
	reset_button.pressed.connect(func() -> void:
		Settings.reset_to_defaults()
		_refresh())


## `foto`: a página direita de quem abriu, que vira e deita à esquerda.
func open(foto: Texture2D = null) -> void:
	_refresh()
	show()
	_sliders.values()[0].grab_focus()
	await livro.folhear(foto)


func close() -> void:
	Settings.save_settings()
	foto_saida = Livro.foto_da_pagina(livro, true)
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	for key in _sliders:
		_sliders[key].set_value_no_signal(Settings.get_value(key))
		_sliders[key].value_changed.emit(_sliders[key].value)
	for key in _toggles:
		_toggles[key].set_pressed_no_signal(Settings.get_value(key))
		_toggles[key].toggled.emit(_toggles[key].button_pressed)


func _add_slider(key: StringName, label: String, min_value: float, max_value: float, step: float, format: String, pagina: VBoxContainer) -> void:
	var row := _add_row(label, pagina)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.custom_minimum_size.x = 180
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var readout := Label.new()
	readout.custom_minimum_size.x = 76
	readout.add_theme_font_size_override(&"font_size", 22)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(readout)
	var percent := format.ends_with("%%")
	slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value(key, v)
		readout.text = (format % (roundi(v * 100.0) if percent else v)).replace(".", ","))
	_sliders[key] = slider


## Botão de texto ("Sim"/"Não"): o CheckButton padrão some na escala de 1080p.
func _add_toggle(key: StringName, label: String) -> void:
	var row := _add_row(label, rows)
	var toggle := Button.new()
	toggle.toggle_mode = true
	toggle.custom_minimum_size.x = 90
	toggle.toggled.connect(func(on: bool) -> void:
		Settings.set_value(key, on)
		toggle.text = "Sim" if on else "Não")
	row.add_child(toggle)
	# "Ligado" não pode parecer foco: o texto já diz o estado.
	for style: StringName in [&"pressed", &"hover_pressed"]:
		toggle.add_theme_stylebox_override(style, toggle.get_theme_stylebox(&"normal"))
	_toggles[key] = toggle


func _add_row(label: String, pagina: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	var name_label := Label.new()
	name_label.text = label
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override(&"font_size", 24)
	row.add_child(name_label)
	pagina.add_child(row)
	return row
