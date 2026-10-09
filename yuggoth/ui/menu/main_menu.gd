class_name MainMenu
extends Control
## Tela de título, um livro aberto (playtest 6; o Necronomicon na sessão do
## menu): à esquerda a gravura da pedra negra e a epígrafe do conto, à direita o
## título e o sumário. Só pede; quem começa o jogo (com fade) é o GameRoot —
## mas antes a tinta da entrada escolhida toma a tela (Necronomicon.mergulhar).
## As Opções são as páginas seguintes: a folha vira.

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

## Uma escolha em andamento (o mergulho): outro clique não pede de novo.
var _indo := false


func _ready() -> void:
	hide()
	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(get_tree().quit)


## `abertura`: o jogo começando — o livro chega fechado e a capa se abre.
func open(abertura := false) -> void:
	_indo = false
	if Necronomicon.atual:
		Necronomicon.atual.abertura_pedida = abertura
	continue_button.visible = SaveSystem.has_save()
	buttons.show()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Events.modal(self, true)
	(continue_button if continue_button.visible else new_game_button).grab_focus()


func close() -> void:
	hide()
	Events.modal(self, false)


func _on_continue() -> void:
	if _indo:
		return
	_indo = true
	await _mergulhar(continue_button)
	continue_requested.emit()


func _on_new_game() -> void:
	if _indo:
		return
	if SaveSystem.has_save():
		var ok := await confirm.ask("Começar de novo apaga o progresso salvo.", buttons, "Começar")
		if not ok:
			new_game_button.grab_focus()
			return
	_indo = true
	await _mergulhar(new_game_button)
	new_game_requested.emit()


func _mergulhar(de: Control) -> void:
	if Necronomicon.atual:
		await Necronomicon.atual.mergulhar(de)


func _on_options() -> void:
	# A tinta deste menu sai das páginas (estão todos no mesmo livro); a das
	# Opções chega com a folha virando.
	var foto := Livro.foto_da_pagina(livro, false)
	livro.hide()
	options_menu.open(foto)
	await options_menu.closed
	livro.show()
	options_button.grab_focus()
	await livro.folhear(options_menu.foto_saida, true)
