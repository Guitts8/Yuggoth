class_name OpcoesConversa
extends CanvasLayer
## As escolhas de uma conversa em pessoa (docs/PLANO_ESCRITORIO.md, Fase 3e:
## "opções de diálogo aparecendo embaixo para escolher, como Skyrim"): uma
## coluna de frases embaixo da tela, em resolução nativa; [W]/[S] ou as setas
## (ou o mouse) escolhem, [E]/Enter/clique confirmam, Esc é a última (sair).
##
## `var i := await OpcoesConversa.escolher(quem, frases)`: o índice escolhido.
## Montada em código, na raiz da árvore; modal enquanto aberta.

## A aberta agora (os testes escolhem por ela).
static var atual: OpcoesConversa

const COR := Color(0.78, 0.74, 0.66)
const COR_FOCO := Color(1.0, 0.94, 0.78)

signal escolhida(indice: int)

var _frases: PackedStringArray
var _rotulos: Array[Label] = []
var _foco := 0
var _aberta_em := -1


static func escolher(quem: Node, frases: PackedStringArray) -> int:
	var o := OpcoesConversa.new()
	o._frases = frases
	quem.get_tree().root.add_child(o)
	var i: int = await o.escolhida
	return i


func _ready() -> void:
	layer = 45
	atual = self
	_aberta_em = Engine.get_process_frames()
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.55)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	var altura := 30.0 + _frases.size() * 34.0
	fundo.offset_top = -altura - 24.0
	fundo.offset_bottom = -24.0
	add_child(fundo)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coluna.offset_left = 0.0
	coluna.offset_top = 14.0
	coluna.alignment = BoxContainer.ALIGNMENT_BEGIN
	coluna.add_theme_constant_override(&"separation", 6)
	fundo.add_child(coluna)
	for i in _frases.size():
		var l := Label.new()
		l.text = _frases[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.add_theme_font_size_override(&"font_size", 22)
		l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override(&"outline_size", 6)
		l.mouse_entered.connect(_focar.bind(i))
		l.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_confirmar(i))
		coluna.add_child(l)
		_rotulos.append(l)
	_focar(0)
	Events.modal_changed.emit(true)


func _exit_tree() -> void:
	if atual == self:
		atual = null


func _unhandled_input(event: InputEvent) -> void:
	# A tecla que abriu (interagir) não confirma de cara.
	if Engine.get_process_frames() == _aberta_em:
		return
	if event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"mover_frente"):
		_focar(wrapi(_foco - 1, 0, _frases.size()))
	elif event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"mover_tras"):
		_focar(wrapi(_foco + 1, 0, _frases.size()))
	elif event.is_action_pressed(&"interagir") or event.is_action_pressed(&"ui_accept"):
		_confirmar(_foco)
	elif event.is_action_pressed(&"ui_cancel"):
		_confirmar(_frases.size() - 1)
	else:
		return
	get_viewport().set_input_as_handled()


func _focar(i: int) -> void:
	_foco = i
	for k in _rotulos.size():
		var em := k == i
		_rotulos[k].add_theme_color_override(&"font_color", COR_FOCO if em else COR)
		_rotulos[k].text = ("›  %s  ‹" if em else "%s") % _frases[k]


## Escolhe a frase `i` (também pelos testes).
func confirmar(i: int) -> void:
	_confirmar(i)


func _confirmar(i: int) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if atual == self:
		atual = null
	Events.modal_changed.emit(false)
	escolhida.emit(i)
	queue_free()
