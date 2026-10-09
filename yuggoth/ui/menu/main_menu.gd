class_name MainMenu
extends Control
## Tela de título, um livro aberto (playtest 6): à esquerda o título e a epígrafe
## do conto, à direita o sumário. Só pede; quem começa o jogo (com fade) é o
## GameRoot. As Opções são as páginas seguintes: a folha vira.

signal new_game_requested
signal continue_requested

@export var options_menu: OptionsMenu

@onready var livro: Livro = $Livro
@onready var buttons: VBoxContainer = %Buttons
@onready var confirm: ConfirmBox = %Confirm
@onready var continue_button: Button = %Continuar
@onready var new_game_button: Button = %NovoJogo
@onready var options_button: Button = %Opcoes
@onready var quit_button: Button = %Sair


func _ready() -> void:
	hide()
	continue_button.pressed.connect(continue_requested.emit)
	new_game_button.pressed.connect(_on_new_game)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(get_tree().quit)


func open() -> void:
	continue_button.visible = SaveSystem.has_save()
	buttons.show()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Events.modal_changed.emit(true)
	(continue_button if continue_button.visible else new_game_button).grab_focus()


func close() -> void:
	hide()
	Events.modal_changed.emit(false)


func _on_new_game() -> void:
	if SaveSystem.has_save():
		var ok := await confirm.ask("Começar de novo apaga o progresso salvo.", buttons, "Começar")
		if not ok:
			new_game_button.grab_focus()
			return
	new_game_requested.emit()


func _on_options() -> void:
	var foto := Livro.foto_da_pagina(livro, false)
	buttons.hide()
	options_menu.open(foto)
	await options_menu.closed
	buttons.show()
	options_button.grab_focus()
	await livro.folhear(options_menu.foto_saida, true)
