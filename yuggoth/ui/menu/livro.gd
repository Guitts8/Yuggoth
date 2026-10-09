class_name Livro
extends Control
## Os menus como páginas de um livro aberto (playtest 6): a capa de couro, as
## duas páginas de papel com a sombra da lombada e o grão, os números de página
## embaixo. O conteúdo vem da cena: os filhos `Esquerda` e `Direita` são postos
## sobre as páginas (o Livro não os move de pai, só os posiciona). A tinta, a
## letra e os botões das páginas vêm do tema do livro (`tema()`).
##
## `folhear(foto, para_tras)` vira uma folha: a `foto` (a página que sai, tirada
## da tela antes da troca: `foto_da_pagina`) se levanta de um lado e deita do
## outro, em branco; a página nova que estava por baixo aparece conforme a folha
## sobe, e a do lado em que ela deita surge depois, com a tinta.

const PAPEL := Color(0.9, 0.85, 0.73)
const PAPEL_BORDA := Color(0.76, 0.69, 0.56)
const COURO := Color(0.26, 0.08, 0.06)
const TINTA := Color(0.16, 0.1, 0.07)
const TINTA_CLARA := Color(0.42, 0.32, 0.24)
const TINTA_FOCO := Color(0.5, 0.08, 0.05)
## Tamanho de uma página (na base de 1080 linhas).
const PAGINA := Vector2(620, 840)
const MARGEM := Vector2(72, 76)
const VIRAR := 0.32

## Os números das páginas, embaixo (vazio = sem número).
@export var numero_esquerda := ""
@export var numero_direita := ""

var _esquerda_pagina: Panel
var _direita_pagina: Panel
var _folha: Control
var _folha_foto: TextureRect
var _folha_sombra: ColorRect

static var _tema: Theme


func _ready() -> void:
	theme = tema()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_montar()
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


func _montar() -> void:
	# Por trás do conteúdo (filhos internos da frente são desenhados antes).
	var capa := Panel.new()
	capa.name = "Capa"
	var sb := StyleBoxFlat.new()
	sb.bg_color = COURO
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.65)
	sb.shadow_size = 40
	sb.shadow_offset = Vector2(0, 14)
	sb.border_color = COURO.darkened(0.35)
	sb.set_border_width_all(3)
	capa.add_theme_stylebox_override(&"panel", sb)
	_interno(capa)
	# As bordas das folhas por baixo das páginas (o miolo do livro).
	for i in 3:
		var maco := Panel.new()
		maco.name = "Maco%d" % i
		var m := StyleBoxFlat.new()
		m.bg_color = PAPEL_BORDA.darkened(0.08 * (3 - i))
		m.set_corner_radius_all(4)
		maco.add_theme_stylebox_override(&"panel", m)
		_interno(maco)
	_esquerda_pagina = _pagina("PaginaEsquerda", true)
	_direita_pagina = _pagina("PaginaDireita", false)
	# A folha que vira: por cima de tudo (filho interno do fim).
	_folha = Control.new()
	_folha.name = "Folha"
	_folha.visible = false
	_folha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = PAPEL
	fundo.add_theme_stylebox_override(&"panel", fs)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_folha.add_child(fundo)
	_folha_foto = TextureRect.new()
	_folha_foto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_folha_foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_folha_foto.stretch_mode = TextureRect.STRETCH_SCALE
	_folha_foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_folha.add_child(_folha_foto)
	_folha_sombra = ColorRect.new()
	_folha_sombra.color = Color(0.1, 0.06, 0.03, 0.0)
	_folha_sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	_folha_sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_folha.add_child(_folha_sombra)
	add_child(_folha, false, Node.INTERNAL_MODE_BACK)


func _interno(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c, false, Node.INTERNAL_MODE_FRONT)


## Uma página: o papel, o grão, a sombra da lombada do lado de dentro e o número.
func _pagina(nome: String, da_esquerda: bool) -> Panel:
	var p := Panel.new()
	p.name = nome
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPEL
	if da_esquerda:
		sb.corner_radius_top_left = 4
		sb.corner_radius_bottom_left = 4
	else:
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
	p.add_theme_stylebox_override(&"panel", sb)
	_interno(p)
	var grao := TextureRect.new()
	grao.name = "Grao"
	var ruido := FastNoiseLite.new()
	ruido.seed = 3 if da_esquerda else 4
	ruido.frequency = 0.08
	var tex := NoiseTexture2D.new()
	tex.noise = ruido
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	grao.texture = tex
	grao.stretch_mode = TextureRect.STRETCH_TILE
	grao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grao.set_anchors_preset(Control.PRESET_FULL_RECT)
	grao.modulate = Color(0.55, 0.42, 0.28, 0.07)
	grao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(grao)
	# A sombra da lombada: escura no meio do livro, sumindo para fora.
	var lombada := TextureRect.new()
	lombada.name = "Lombada"
	var g := Gradient.new()
	g.set_color(0, Color(0.15, 0.08, 0.03, 0.42))
	g.set_color(1, Color(0.15, 0.08, 0.03, 0.0))
	g.add_point(0.35, Color(0.15, 0.08, 0.03, 0.12))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 64
	gt.height = 4
	gt.fill_from = Vector2(1, 0) if da_esquerda else Vector2(0, 0)
	gt.fill_to = Vector2(0, 0) if da_esquerda else Vector2(1, 0)
	lombada.texture = gt
	lombada.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lombada.stretch_mode = TextureRect.STRETCH_SCALE
	lombada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lombada.anchor_top = 0.0
	lombada.anchor_bottom = 1.0
	if da_esquerda:
		lombada.anchor_left = 1.0
		lombada.anchor_right = 1.0
		lombada.offset_left = -90
	else:
		lombada.offset_right = 90
	p.add_child(lombada)
	var numero := Label.new()
	numero.name = "Numero"
	numero.text = numero_esquerda if da_esquerda else numero_direita
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.add_theme_color_override(&"font_color", TINTA_CLARA)
	numero.add_theme_font_size_override(&"font_size", 20)
	numero.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	numero.offset_left = -60
	numero.offset_right = 60
	numero.offset_top = -52
	numero.offset_bottom = -24
	p.add_child(numero)
	return p


func _posicionar() -> void:
	var meio := size / 2
	var esq := Rect2(meio - Vector2(PAGINA.x, PAGINA.y / 2), PAGINA)
	var dir := Rect2(meio - Vector2(0, PAGINA.y / 2), PAGINA)
	_por(_esquerda_pagina, esq)
	_por(_direita_pagina, dir)
	_por(get_node(^"Capa") as Control, Rect2(esq.position - Vector2(26, 22), Vector2(PAGINA.x * 2 + 52, PAGINA.y + 44)))
	for i in 3:
		var d := (3 - i) * 4.0
		_por(get_node("Maco%d" % i) as Control, Rect2(esq.position + Vector2(-d, d * 0.6), Vector2(PAGINA.x * 2 + d * 2, PAGINA.y)))
	for c: Array in [[esquerda(), esq], [direita(), dir]]:
		if c[0]:
			var r: Rect2 = c[1]
			_por(c[0], Rect2(r.position + MARGEM, r.size - MARGEM * 2 - Vector2(0, 30)))


static func _por(c: Control, r: Rect2) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.position = r.position
	c.size = r.size


## A página `pagina` como está na tela agora (o último quadro desenhado).
static func foto_da_pagina(livro: Livro, da_esquerda: bool) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	var vp := livro.get_viewport()
	var img := vp.get_texture().get_image()
	if img == null:
		return null
	var pagina := livro._esquerda_pagina if da_esquerda else livro._direita_pagina
	var escala := Vector2(img.get_size()) / vp.get_visible_rect().size
	var r := pagina.get_global_rect()
	var corte := Rect2i(Vector2i(r.position * escala), Vector2i(r.size * escala)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if corte.size.x <= 0 or corte.size.y <= 0:
		return null
	return ImageTexture.create_from_image(img.get_region(corte))


## Vira uma folha. Para a frente: a `foto` (a página direita que sai) se levanta
## da direita e deita na esquerda; a página direita nova aparece por baixo dela, e
## a esquerda, em branco, ganha a tinta depois. Para trás, o contrário.
func folhear(foto: Texture2D, para_tras := false) -> void:
	var sai := _esquerda_pagina if para_tras else _direita_pagina
	var chega := _direita_pagina if para_tras else _esquerda_pagina
	var tinta_chega := direita() if para_tras else esquerda()
	tinta_chega.modulate.a = 0.0
	_folha_foto.texture = foto
	_folha_foto.visible = foto != null
	_folha.visible = true
	_folha.size = sai.size
	_folha.position = sai.position
	# Gira na lombada: o lado de dentro da página.
	_folha.pivot_offset = Vector2(sai.size.x if para_tras else 0.0, 0)
	_folha.scale = Vector2.ONE
	_folha_sombra.color.a = 0.0
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(_folha, ^"scale:x", 0.0, VIRAR).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_folha_sombra, ^"color:a", 0.35, VIRAR)
	await t.finished
	if not is_inside_tree():
		return
	# Do outro lado da lombada, o verso: em branco.
	_folha_foto.visible = false
	_folha.position = chega.position
	_folha.pivot_offset = Vector2(0.0 if para_tras else chega.size.x, 0)
	t = create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(_folha, ^"scale:x", 1.0, VIRAR).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_folha_sombra, ^"color:a", 0.0, VIRAR)
	await t.finished
	if not is_inside_tree():
		return
	_folha.visible = false
	t = create_tween()
	t.tween_property(tinta_chega, ^"modulate:a", 1.0, 0.25)
	await t.finished


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
