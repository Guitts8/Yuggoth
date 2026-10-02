class_name PauseMenu
extends Control
## Esc durante o jogo. Pausa a árvore; ambiente e zumbido continuam tocando.
## Não abre sobre outro modal (leitor, dossiê...) nem durante troca de fase.

signal quit_to_menu_requested

@export var options_menu: OptionsMenu

@onready var buttons: VBoxContainer = %Buttons
@onready var confirm: ConfirmBox = %Confirm
@onready var resume_button: Button = %Continuar
@onready var options_button: Button = %Opcoes
@onready var menu_button: Button = %MenuPrincipal
@onready var quit_button: Button = %Sair


func _ready() -> void:
	hide()
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_on_options)
	menu_button.pressed.connect(_on_menu)
	quit_button.pressed.connect(_on_quit)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if visible:
		close()
	elif can_open():
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func can_open() -> bool:
	return not Events.is_modal_open and not SceneDirector.is_busy \
		and not SceneDirector.current_level.is_empty()


func open() -> void:
	get_tree().paused = true
	buttons.show()
	show()
	Events.modal_changed.emit(true)
	resume_button.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false
	Events.modal_changed.emit(false)


func _on_options() -> void:
	buttons.hide()
	options_menu.open()
	await options_menu.closed
	buttons.show()
	options_button.grab_focus()


func _on_menu() -> void:
	if await confirm.ask("Voltar ao menu principal? O que não foi salvo se perde.", buttons, "Voltar ao menu", "Cancelar"):
		quit_to_menu_requested.emit()
	else:
		menu_button.grab_focus()


func _on_quit() -> void:
	if await confirm.ask("Sair do jogo? O que não foi salvo se perde.", buttons, "Sair", "Cancelar"):
		get_tree().quit()
	else:
		quit_button.grab_focus()
