class_name DocumentData
extends Resource
## Carta, telegrama, recorte ou fotografia legível.
## O texto mostrado é a primeira variante cuja condição vale; senão, `pages`.
## Nenhuma troca de variante é anunciada ao jogador (GDD §6.2).

## Duas mãos (playtest 5): MANUSCRITO é a letra de Akeley (e de quem mais
## escrever à mão), "apertada, arcaica" — Tangerine; WILMARTH, a de Wilmarth
## (respostas, diário, o relato, o rascunho), copperplate — Petit Formal Script
## (playtest 6: a Pinyon não se lia). O jornal e o que não é letra de mão em
## Old Standard, a serifada das publicações do começo do século XX (também a
## fonte padrão da interface). Todas OFL (art/fonts, com a licença ao lado).
enum Style { MANUSCRITO, DATILOGRAFADO, JORNAL, TELEGRAMA, WILMARTH }

const STYLE_FONTS := {
	Style.MANUSCRITO: ["res://art/fonts/Tangerine-Regular.ttf"],
	Style.DATILOGRAFADO: ["Courier New", "Courier", "monospace"],
	Style.JORNAL: ["res://art/fonts/OldStandard-Regular.ttf"],
	Style.TELEGRAMA: ["Courier New", "Courier", "monospace"],
	Style.WILMARTH: ["res://art/fonts/PetitFormalScript-Regular.ttf"],
}
## A serifada de reserva (o que faltar na letra de mão) e da interface.
const SERIFADA := "res://art/fonts/OldStandard-Regular.ttf"
## As letras de mão têm o olho pequeno para o corpo: o tamanho cresce tanto.
const STYLE_SCALE := {
	Style.MANUSCRITO: 1.5,
	Style.WILMARTH: 1.0,
}
## Entrelinha extra das letras de mão (px por 27 px de corpo): a Petit Formal tem
## hastes longas, e as linhas se encostavam.
const STYLE_ENTRELINHA := {
	Style.MANUSCRITO: 0,
	Style.WILMARTH: 7,
}
const FONT_SLOTS: Array[StringName] = [&"normal_font", &"italics_font", &"bold_font", &"bold_italics_font"]

static var _font_cache: Dictionary[String, Font] = {}

@export var id: StringName
@export var title := ""
@export var style := Style.MANUSCRITO
## Páginas em BBCode. Aceita a tag [sussurro]...[/sussurro].
@export_multiline var pages: PackedStringArray = []
## Avaliadas em ordem; a primeira satisfeita vence.
@export var variants: Array[DocumentVariant] = []
## Somado a `exposicao` na primeira leitura.
@export_range(0.0, 1.0, 0.01) var exposure_on_read := 0.0
## Salto no tempo ao fechar pela primeira vez (Dia 6: uma carta chega por dia,
## e lida uma, o correio traz a seguinte). Quem honra é a fase (o escritório).
@export var cartao_depois: NarrationLine


func resolve_pages() -> PackedStringArray:
	var variant := resolve_variant()
	return variant.pages if variant else pages


## A variante em vigor, ou null para o texto original.
func resolve_variant() -> DocumentVariant:
	for variant in variants:
		if variant and (variant.condition == null or variant.condition.is_met()):
			return variant
	return null


## Fonte do estilo em todas as variantes ([i], [b]) de um RichTextLabel. O
## itálico e o negrito são a mesma fonte inclinada e engrossada: a letra de mão
## não tem itálico, e [i] sumia. `size` é o tamanho de base (0 = o do tema, na
## primeira vez); o estilo o aumenta por `STYLE_SCALE`.
static func apply_fonts(label: RichTextLabel, doc_style: Style, size := 0) -> void:
	if size <= 0:
		# O de base fica guardado: aplicar de novo não acumula a escala.
		size = label.get_meta(&"tamanho_base", label.get_theme_font_size(&"normal_font_size"))
	label.set_meta(&"tamanho_base", size)
	var final := roundi(size * float(STYLE_SCALE.get(doc_style, 1.0)))
	for slot in [&"normal_font_size", &"italics_font_size", &"bold_font_size", &"bold_italics_font_size"]:
		label.add_theme_font_size_override(slot, final)
	if STYLE_ENTRELINHA.has(doc_style):
		label.add_theme_constant_override(&"line_separation", roundi(STYLE_ENTRELINHA[doc_style] * final / 27.0))
	for slot in FONT_SLOTS:
		var key := "%d:%s" % [doc_style, slot]
		if not _font_cache.has(key):
			_font_cache[key] = _fonte(doc_style, slot)
		label.add_theme_font_override(slot, _font_cache[key])


static func _fonte(doc_style: Style, slot: StringName) -> Font:
	var nomes: Array = STYLE_FONTS[doc_style]
	var base: Font
	if String(nomes[0]).begins_with("res://"):
		var arquivo := load(nomes[0]) as FontFile
		# O que faltar na letra de mão (um sinal raro) vem de uma serifada.
		var f := arquivo.duplicate() as FontFile
		if nomes[0] != SERIFADA:
			f.fallbacks = [load(SERIFADA)]
		base = f
	else:
		var sistema := SystemFont.new()
		sistema.font_names = PackedStringArray(nomes)
		base = sistema
	if slot == &"normal_font":
		return base
	var v := FontVariation.new()
	v.base_font = base
	if String(slot).contains("italics"):
		# A letra de mão já é inclinada: o [i] inclina só mais um pouco.
		var manuscrita := doc_style in [Style.MANUSCRITO, Style.WILMARTH]
		v.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2 if manuscrita else 0.22, 1), Vector2.ZERO)
	if String(slot).begins_with("bold"):
		v.variation_embolden = 0.7
	return v


## Flag marcada na primeira leitura, ex.: leu_carta_akeley_1.
func get_read_flag() -> StringName:
	return StringName("leu_%s" % id)
