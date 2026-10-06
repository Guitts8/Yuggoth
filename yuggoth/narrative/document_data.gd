class_name DocumentData
extends Resource
## Carta, telegrama, recorte ou fotografia legível.
## O texto mostrado é a primeira variante cuja condição vale; senão, `pages`.
## Nenhuma troca de variante é anunciada ao jogador (GDD §6.2).

enum Style { MANUSCRITO, DATILOGRAFADO, JORNAL, TELEGRAMA }

const STYLE_FONTS := {
	Style.MANUSCRITO: ["Segoe Script", "Brush Script MT", "cursive"],
	Style.DATILOGRAFADO: ["Courier New", "Courier", "monospace"],
	Style.JORNAL: ["Georgia", "Times New Roman", "serif"],
	Style.TELEGRAMA: ["Courier New", "Courier", "monospace"],
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
## (Segoe Script) não tem itálico, e [i] sumia. Com `size` > 0, fixa o tamanho.
static func apply_fonts(label: RichTextLabel, doc_style: Style, size := 0) -> void:
	if size > 0:
		label.add_theme_font_size_override(&"normal_font_size", size)
	# [i] e [b] usam o mesmo tamanho do texto normal (o tema só define o normal).
	size = label.get_theme_font_size(&"normal_font_size")
	for slot in [&"italics_font_size", &"bold_font_size", &"bold_italics_font_size"]:
		label.add_theme_font_size_override(slot, size)
	for slot in FONT_SLOTS:
		var key := "%d:%s" % [doc_style, slot]
		if not _font_cache.has(key):
			_font_cache[key] = _fonte(doc_style, slot)
		label.add_theme_font_override(slot, _font_cache[key])


static func _fonte(doc_style: Style, slot: StringName) -> Font:
	var base := SystemFont.new()
	base.font_names = PackedStringArray(STYLE_FONTS[doc_style])
	if slot == &"normal_font":
		return base
	var v := FontVariation.new()
	v.base_font = base
	if String(slot).contains("italics"):
		v.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.38 if doc_style == Style.MANUSCRITO else 0.22, 1), Vector2.ZERO)
	if String(slot).begins_with("bold"):
		v.variation_embolden = 0.7
	return v


## Flag marcada na primeira leitura, ex.: leu_carta_akeley_1.
func get_read_flag() -> StringName:
	return StringName("leu_%s" % id)
