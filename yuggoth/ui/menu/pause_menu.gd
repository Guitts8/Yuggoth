class_name PauseMenu
extends Control
## Esc durante o jogo. Pausa a árvore; ambiente e zumbido continuam tocando.
## Não abre sobre outro modal (leitor, dossiê...) nem durante troca de fase. Um
## livro aberto (playtest 6): à esquerda a data do dia, à direita o que fazer.

const MESES := ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho",
	"agosto", "setembro", "outubro", "novembro", "dezembro"]

signal quit_to_menu_requested

@export var options_menu: OptionsMenu

@onready var livro: Livro = $Livro
@onready var data: Label = %Data
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
	data.text = data_por_extenso(int(GameState.get_value(&"data", 0)))
	buttons.show()
	show()
	Events.modal(self, true)
	resume_button.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false
	Events.modal(self, false)


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


## "Arkham, 18 de julho de 1928" (dia do ano de 1928, como em GameState.data);
## sem data (o Prólogo), 1930.
static func data_por_extenso(dia_do_ano: int) -> String:
	if dia_do_ano <= 0:
		return "Arkham, 1930"
	var mes := 0
	var dia := dia_do_ano
	while mes < 11 and dia > Lapso.DIAS_NO_MES[mes]:
		dia -= Lapso.DIAS_NO_MES[mes]
		mes += 1
	return "Arkham, %s de %s de 1928" % ["1º" if dia == 1 else str(dia), MESES[mes]]


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
