class_name TintaTransicao
extends CanvasLayer
## Entrada do Interlúdio (GDD §5.1a): a caligrafia nervosa da última carta de
## Akeley enche a tela, a tinta se espalha e vira o céu de fim de tarde sobre o
## vale. Montada em código; quem usa a põe na raiz da árvore (resolução nativa,
## acima da UI e abaixo do fade) e espera `tocar()`. Bloqueia o jogador como um
## modal enquanto existe.

const SHADER := preload("res://shaders/tinta.gdshader")
## Parágrafos do fim da carta mostrados no papel.
const PARAGRAFOS := 3

@export var aproximar := 7.0
@export var espalhar := 4.5
@export var secar := 3.5
@export var segurar := 2.5
@export var zoom_final := 6.0

var _modal := false
var _fundo: ColorRect
var _papel: PanelContainer
var _tinta: ColorRect


func _init() -> void:
	layer = 90


func _exit_tree() -> void:
	if _modal:
		_modal = false
		Events.modal_changed.emit(false)


func tocar(doc: DocumentData) -> void:
	_montar(doc)
	_modal = true
	Events.modal_changed.emit(true)
	var t := create_tween().set_parallel()
	t.tween_property(_fundo, "modulate:a", 1.0, 1.5)
	t.tween_property(_papel, "modulate:a", 1.0, 1.5)
	await t.finished
	# O papel ainda não tinha tamanho quando foi montado.
	_papel.pivot_offset = _papel.size * 0.5

	t = create_tween().set_parallel()
	t.tween_property(_papel, "scale", Vector2.ONE * zoom_final, aproximar).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_method(_set_param.bind(&"progresso"), 0.0, 1.0, espalhar).set_delay(aproximar - espalhar * 0.6)
	await t.finished
	_papel.hide()

	t = create_tween()
	t.tween_method(_set_param.bind(&"ceu"), 0.0, 1.0, secar)
	await t.finished
	await get_tree().create_timer(segurar).timeout


## Fundo preto, o papel com o fim da carta e a camada da tinta por cima.
func _montar(doc: DocumentData) -> void:
	_fundo = ColorRect.new()
	_fundo.color = Color.BLACK
	_fundo.modulate.a = 0.0
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fundo)

	_papel = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.85, 0.8, 0.68)
	estilo.set_content_margin_all(56.0)
	_papel.add_theme_stylebox_override(&"panel", estilo)
	_papel.custom_minimum_size = Vector2(800, 0)
	_papel.modulate.a = 0.0
	add_child(_papel)
	_papel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_papel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_papel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.scroll_active = false
	texto.add_theme_color_override(&"default_color", Color(0.13, 0.1, 0.08))
	texto.add_theme_font_size_override(&"normal_font_size", 27)
	texto.install_effect(TremorTextEffect.new())
	DocumentData.apply_fonts(texto, doc.style)
	texto.text = fim_da_carta(doc)
	_papel.add_child(texto)

	_tinta = ColorRect.new()
	_tinta.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var tela := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(16, 9)
	mat.set_shader_parameter(&"aspecto", tela.x / tela.y)
	_tinta.material = mat
	add_child(_tinta)


## Os últimos parágrafos da carta (a despedida e a assinatura).
static func fim_da_carta(doc: DocumentData) -> String:
	var paragrafos := "\n\n".join(doc.resolve_pages()).split("\n\n")
	return "\n\n".join(paragrafos.slice(maxi(0, paragrafos.size() - PARAGRAFOS)))


func _set_param(valor: float, nome: StringName) -> void:
	(_tinta.material as ShaderMaterial).set_shader_parameter(nome, valor)
