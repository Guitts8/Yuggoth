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

static var _font_cache: Dictionary[String, SystemFont] = {}

@export var id: StringName
@export var title := ""
@export var style := Style.MANUSCRITO
## Páginas em BBCode. Aceita a tag [sussurro]...[/sussurro].
@export_multiline var pages: PackedStringArray = []
## Avaliadas em ordem; a primeira satisfeita vence.
@export var variants: Array[DocumentVariant] = []
## Somado a `exposicao` na primeira leitura.
@export_range(0.0, 1.0, 0.01) var exposure_on_read := 0.0


func resolve_pages() -> PackedStringArray:
	for variant in variants:
		if variant and (variant.condition == null or variant.condition.is_met()):
			return variant.pages
	return pages


## Fonte do estilo em todas as variantes ([i], [b]) de um RichTextLabel.
static func apply_fonts(label: RichTextLabel, doc_style: Style) -> void:
	# [i] e [b] usam o mesmo tamanho do texto normal (o tema só define o normal).
	var size := label.get_theme_font_size(&"normal_font_size")
	for slot in [&"italics_font_size", &"bold_font_size", &"bold_italics_font_size"]:
		label.add_theme_font_size_override(slot, size)
	for slot in FONT_SLOTS:
		var key := "%d:%s" % [doc_style, slot]
		if not _font_cache.has(key):
			var font := SystemFont.new()
			font.font_names = PackedStringArray(STYLE_FONTS[doc_style])
			font.font_italic = String(slot).contains("italics")
			font.font_weight = 700 if String(slot).begins_with("bold") else 400
			_font_cache[key] = font
		label.add_theme_font_override(slot, _font_cache[key])


## Flag marcada na primeira leitura, ex.: leu_carta_akeley_1.
func get_read_flag() -> StringName:
	return StringName("leu_%s" % id)
