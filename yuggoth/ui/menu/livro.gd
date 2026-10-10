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
## Por baixo do texto de cada página, o que está impresso nela (OrnamentoPagina:
## a moldura, a escrita apagada); por cima, o marcador rubro da entrada escolhida
## (MarcadorFoco). O mouse sobre uma entrada a escolhe (um foco só, nunca dois
## grifados), e a escolhida pulsa ao chegar.
##
## `foto_da_pagina()` (antes de trocar a tinta) e `folhear(foto, para_tras)`
## (depois) viram a folha do Necronomicon.

const PAPEL := Color(0.9, 0.85, 0.73)
const TINTA := Color(0.12, 0.065, 0.045)
const TINTA_CLARA := Color(0.38, 0.25, 0.17)
const RUBRO := Color(0.56, 0.07, 0.04)
const TINTA_FOCO := RUBRO
## Tamanho de uma página (na textura das páginas, 1240 × 840).
const PAGINA := Vector2(620, 840)
const MARGEM := Vector2(74, 78)

const FONTE_TEXTO := "res://art/fonts/IMFellEnglish-Regular.ttf"
const FONTE_ITALICO := "res://art/fonts/IMFellEnglish-Italic.ttf"
const FONTE_VERSALETE := "res://art/fonts/IMFellEnglish-SC.ttf"
const FONTE_GOTICA := "res://art/fonts/GrenzeGotisch.ttf"
const FONTE_TITULO := "res://art/fonts/UnifrakturMaguntia-Book.ttf"

## Os números das páginas, embaixo (vazio = sem número).
@export var numero_esquerda := ""
@export var numero_direita := ""
## O diagrama arcano desbotado atrás do texto de cada página.
@export var circulo_esquerda := false
@export var circulo_direita := false
## A semente das irregularidades impressas (cada menu, as suas páginas).
@export var semente := 1

var _numeros: Array[Label] = []
var _ornamentos: Array[OrnamentoPagina] = []
var _marcador: MarcadorFoco
var _som_foco: AudioStream

static var _tema: Theme


func _ready() -> void:
	theme = tema()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 2:
		var o := OrnamentoPagina.new()
		o.semente = semente * 7 + i
		o.circulo = circulo_esquerda if i == 0 else circulo_direita
		o.escrita_embaixo = i == 1
		add_child(o, false, Node.INTERNAL_MODE_FRONT)
		_ornamentos.append(o)
	for t: String in [numero_esquerda, numero_direita]:
		var numero := Label.new()
		numero.text = t
		numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		numero.add_theme_color_override(&"font_color", RUBRO)
		numero.add_theme_font_override(&"font", load(FONTE_VERSALETE))
		numero.add_theme_font_size_override(&"font_size", 24)
		numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(numero, false, Node.INTERNAL_MODE_FRONT)
		_numeros.append(numero)
	_marcador = MarcadorFoco.new()
	_marcador.livro = self
	add_child(_marcador, false, Node.INTERNAL_MODE_BACK)
	_som_foco = load("res://audio/foley/menu_pena.wav")
	resized.connect(_posicionar)
	_posicionar()
	# Depois do primeiro layout (um rótulo com quebra de linha mede alto demais
	# antes de saber a largura, e empurraria o conteúdo para fora da página).
	_posicionar.call_deferred()
	visibility_changed.connect(_posicionar)
	# Também os controles que o menu cria no próprio _ready (as Opções).
	_preparar_controles.call_deferred()


## O conteúdo de uma página (os filhos da cena).
func esquerda() -> Control:
	return get_node(^"Esquerda") as Control


func direita() -> Control:
	return get_node(^"Direita") as Control


func _preparar_controles() -> void:
	for c: Control in find_children("*", "Control", true, false):
		if not (c is BaseButton or c is Range) or c.has_meta(&"livro_pronto"):
			continue
		c.set_meta(&"livro_pronto", true)
		# As entradas do sumário: só da largura do texto.
		if c is Button and c.get_parent() is VBoxContainer:
			c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c.mouse_entered.connect(func() -> void:
			if c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE:
				c.grab_focus())
		c.focus_entered.connect(_ao_escolher.bind(c))


## A entrada que acaba de ser escolhida pulsa (cresce e assenta) e a pena risca.
func _ao_escolher(c: Control) -> void:
	if not is_visible_in_tree():
		return
	c.pivot_offset = c.size / 2.0
	var t := c.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	c.scale = Vector2.ONE * 1.1
	t.tween_property(c, ^"scale", Vector2.ONE, 0.28)
	if _som_foco and Necronomicon.atual and Necronomicon.atual.pronto():
		AudioDirector.play_sfx(_som_foco, -18.0)


func _posicionar() -> void:
	var meio := size / 2
	var esq := Rect2(meio - Vector2(PAGINA.x, PAGINA.y / 2), PAGINA)
	var dir := Rect2(meio - Vector2(0, PAGINA.y / 2), PAGINA)
	for c: Array in [[esquerda(), esq], [direita(), dir]]:
		if c[0]:
			var r: Rect2 = c[1]
			_por(c[0], Rect2(r.position + MARGEM, r.size - MARGEM * 2 - Vector2(0, 34)))
	for i in _ornamentos.size():
		_por(_ornamentos[i], [esq, dir][i])
	for i in _numeros.size():
		var r: Rect2 = [esq, dir][i]
		_por(_numeros[i], Rect2(r.position + Vector2(r.size.x / 2 - 60, r.size.y - 96), Vector2(120, 32)))


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


## A fonte gótica das entradas, mais grossa que a de fábrica (a variável vai do
## fino ao negro).
static func gotica(peso := 560) -> Font:
	var f := FontVariation.new()
	f.base_font = load(FONTE_GOTICA)
	var ts := TextServerManager.get_primary_interface()
	f.variation_opentype = {ts.name_to_tag("wght"): peso}
	return f


## A tinta das páginas: a letra de livro antigo, as entradas em gótico (sem caixa;
## a escolhida avermelha e o marcador a ladeia), réguas e marcas de tinta.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = load(FONTE_TEXTO)
	t.default_font_size = 30
	t.set_color(&"font_color", &"Label", TINTA)
	t.set_font(&"font", &"Button", gotica())
	t.set_font_size(&"font_size", &"Button", 46)
	for estado: StringName in [&"font_color", &"font_disabled_color"]:
		t.set_color(estado, &"Button", TINTA if estado == &"font_color" else TINTA_CLARA)
	# Só a escolhida avermelha (o mouse sobre uma entrada a escolhe; passar por cima
	# de outra com o teclado não deixa duas grifadas).
	t.set_color(&"font_hover_color", &"Button", TINTA)
	for estado: StringName in [&"font_focus_color", &"font_hover_pressed_color", &"font_pressed_color"]:
		t.set_color(estado, &"Button", RUBRO)
	var vazio := StyleBoxEmpty.new()
	vazio.content_margin_left = 10
	vazio.content_margin_right = 10
	vazio.content_margin_top = 0
	vazio.content_margin_bottom = 0
	for s: StringName in [&"normal", &"disabled", &"pressed", &"hover", &"focus", &"hover_pressed"]:
		t.set_stylebox(s, &"Button", vazio)
	# As réguas dos controles deslizantes: um traço de tinta; a parte cheia, mais escura.
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = Color(TINTA_CLARA, 0.4)
	trilho.content_margin_top = 1.5
	trilho.content_margin_bottom = 1.5
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = TINTA
	cheio.content_margin_top = 2
	cheio.content_margin_bottom = 2
	var cheio_foco := StyleBoxFlat.new()
	cheio_foco.bg_color = RUBRO
	cheio_foco.content_margin_top = 2
	cheio_foco.content_margin_bottom = 2
	t.set_stylebox(&"slider", &"HSlider", trilho)
	t.set_stylebox(&"grabber_area", &"HSlider", cheio)
	t.set_stylebox(&"grabber_area_highlight", &"HSlider", cheio_foco)
	t.set_stylebox(&"focus", &"HSlider", StyleBoxEmpty.new())
	t.set_icon(&"grabber", &"HSlider", _marca_tinta(TINTA))
	t.set_icon(&"grabber_highlight", &"HSlider", _marca_tinta(RUBRO))
	t.set_icon(&"grabber_disabled", &"HSlider", _marca_tinta(TINTA_CLARA))
	t.set_color(&"default_color", &"RichTextLabel", TINTA)
	_tema = t
	return t


## A marca do controle deslizante: um losango de tinta.
static func _marca_tinta(cor: Color) -> Texture2D:
	var n := 20
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) / 2.0
	for y in n:
		for x in n:
			var d := absf(x - c) + absf(y - c) * 0.8
			if d <= c:
				img.set_pixel(x, y, Color(cor, clampf(c - d + 0.5, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
