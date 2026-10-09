class_name Livro
extends Control
## O arranjo de um menu nas duas páginas do livro dos menus (playtest 6; no
## playtest 7 o livro virou o Necronomicon em 3D, `Necronomicon`): o menu mora
## no SubViewport das páginas, e o Livro põe os filhos `Esquerda` e `Direita` da
## cena, com as margens, sobre a página da esquerda e a da direita (o Livro não
## os move de pai, só os posiciona), e os números de página embaixo. O papel, a
## capa e a folha que vira são do Necronomicon. A tinta, a letra e os botões vêm
## do tema do livro (`tema()`).
##
## `foto_da_pagina()` (antes de trocar a tinta) e `folhear(foto, para_tras)`
## (depois) viram a folha do Necronomicon.

const PAPEL := Color(0.9, 0.85, 0.73)
const TINTA := Color(0.13, 0.07, 0.05)
const TINTA_CLARA := Color(0.4, 0.27, 0.18)
const TINTA_FOCO := Color(0.55, 0.06, 0.04)
## Tamanho de uma página (na textura das páginas, 1240 × 840).
const PAGINA := Vector2(620, 840)
const MARGEM := Vector2(72, 76)

## Os números das páginas, embaixo (vazio = sem número).
@export var numero_esquerda := ""
@export var numero_direita := ""

var _numeros: Array[Label] = []

static var _tema: Theme


func _ready() -> void:
	theme = tema()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t: String in [numero_esquerda, numero_direita]:
		var numero := Label.new()
		numero.text = t
		numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		numero.add_theme_color_override(&"font_color", TINTA_CLARA)
		numero.add_theme_font_size_override(&"font_size", 20)
		numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(numero, false, Node.INTERNAL_MODE_FRONT)
		_numeros.append(numero)
	# As entradas do sumário: só da largura do texto (o sublinhado do foco não
	# atravessa a página).
	for b in find_children("*", "Button", true, false):
		if b.get_parent() is VBoxContainer:
			(b as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resized.connect(_posicionar)
	_posicionar()
	# Depois do primeiro layout (um rótulo com quebra de linha mede alto demais
	# antes de saber a largura, e empurraria o conteúdo para fora da página).
	_posicionar.call_deferred()
	visibility_changed.connect(_posicionar)


## O conteúdo de uma página (os filhos da cena).
func esquerda() -> Control:
	return get_node(^"Esquerda") as Control


func direita() -> Control:
	return get_node(^"Direita") as Control


func _posicionar() -> void:
	var meio := size / 2
	var esq := Rect2(meio - Vector2(PAGINA.x, PAGINA.y / 2), PAGINA)
	var dir := Rect2(meio - Vector2(0, PAGINA.y / 2), PAGINA)
	for c: Array in [[esquerda(), esq], [direita(), dir]]:
		if c[0]:
			var r: Rect2 = c[1]
			_por(c[0], Rect2(r.position + MARGEM, r.size - MARGEM * 2 - Vector2(0, 30)))
	for i in _numeros.size():
		var r: Rect2 = [esq, dir][i]
		_por(_numeros[i], Rect2(r.position + Vector2(r.size.x / 2 - 60, r.size.y - 64), Vector2(120, 30)))


static func _por(c: Control, r: Rect2) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.position = r.position
	c.size = r.size


## As páginas como estão agora, antes de quem sai trocar a tinta (o
## Necronomicon guarda a foto para a folha que vira). `da_esquerda` fica pela
## compatibilidade: a foto é das duas.
static func foto_da_pagina(_livro: Livro, _da_esquerda := false) -> Texture2D:
	return Necronomicon.atual.fotografar() if Necronomicon.atual else null


## Vira a folha do Necronomicon (para a frente: a da direita deita na esquerda).
func folhear(_foto: Texture2D, para_tras := false) -> void:
	if Necronomicon.atual:
		await Necronomicon.atual.virar(para_tras)


## A tinta das páginas: letra serifada escura, botões como entradas de sumário
## (sem caixa; o foco sublinha e avermelha a tinta), réguas e marcas de tinta.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = load("res://art/fonts/OldStandard-Regular.ttf")
	t.default_font_size = 30
	t.set_color(&"font_color", &"Label", TINTA)
	for estado: StringName in [&"font_color", &"font_disabled_color"]:
		t.set_color(estado, &"Button", TINTA if estado == &"font_color" else TINTA_CLARA)
	for estado: StringName in [&"font_focus_color", &"font_hover_color", &"font_hover_pressed_color", &"font_pressed_color"]:
		t.set_color(estado, &"Button", TINTA_FOCO)
	var vazio := StyleBoxEmpty.new()
	vazio.content_margin_left = 6
	vazio.content_margin_right = 6
	vazio.content_margin_top = 4
	vazio.content_margin_bottom = 4
	var foco := StyleBoxFlat.new()
	foco.bg_color = Color(0, 0, 0, 0)
	foco.border_color = TINTA_FOCO
	foco.border_width_bottom = 2
	foco.content_margin_left = 6
	foco.content_margin_right = 6
	foco.content_margin_top = 4
	foco.content_margin_bottom = 4
	for s: StringName in [&"normal", &"disabled", &"pressed"]:
		t.set_stylebox(s, &"Button", vazio)
	for s: StringName in [&"hover", &"focus", &"hover_pressed"]:
		t.set_stylebox(s, &"Button", foco)
	# As réguas dos controles deslizantes: um traço de tinta; a parte cheia, mais escura.
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = Color(TINTA_CLARA, 0.45)
	trilho.content_margin_top = 2
	trilho.content_margin_bottom = 2
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = TINTA
	cheio.content_margin_top = 2
	cheio.content_margin_bottom = 2
	t.set_stylebox(&"slider", &"HSlider", trilho)
	t.set_stylebox(&"grabber_area", &"HSlider", cheio)
	t.set_stylebox(&"grabber_area_highlight", &"HSlider", cheio)
	var focado := StyleBoxFlat.new()
	focado.bg_color = Color(0, 0, 0, 0)
	focado.border_color = Color(TINTA_FOCO, 0.6)
	focado.border_width_bottom = 2
	t.set_stylebox(&"focus", &"HSlider", focado)
	var marca := _marca_tinta()
	t.set_icon(&"grabber", &"HSlider", marca)
	t.set_icon(&"grabber_highlight", &"HSlider", marca)
	t.set_icon(&"grabber_disabled", &"HSlider", marca)
	t.set_color(&"default_color", &"RichTextLabel", TINTA)
	_tema = t
	return t


## A marca do controle deslizante: um losango de tinta.
static func _marca_tinta() -> Texture2D:
	var n := 18
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) / 2.0
	for y in n:
		for x in n:
			var d := absf(x - c) + absf(y - c)
			if d <= c:
				img.set_pixel(x, y, Color(TINTA, clampf(c - d + 0.5, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
