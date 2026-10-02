class_name WhisperTextEffect
extends RichTextEffect
## [sussurro]texto[/sussurro] — letras tremem, esmaecem e às vezes trocam de glifo.
## Parâmetro opcional: [sussurro forca=0.8]. A intensidade global segue `exposicao`.

var bbcode := "sussurro"

## 0..1, atualizado pelo leitor a partir de GameState.exposicao.
static var intensity := 0.0


func _process_custom_fx(fx: CharFXTransform) -> bool:
	var k := clampf(float(fx.env.get("forca", 0.4)) + intensity, 0.0, 1.5)
	var t := fx.elapsed_time
	var seed := fx.range.x

	fx.offset = Vector2(sin(t * 23.0 + seed * 3.1), cos(t * 19.0 + seed * 1.7)) * k * 1.6
	fx.color.a *= 1.0 - 0.4 * k * (0.5 + 0.5 * sin(t * 2.7 + seed * 0.9))

	# Troca ocasional de glifo por uma letra qualquer, por instantes curtos.
	var slot := int(t * 5.0) + seed * 7
	if absi(hash(slot)) % 100 < int(k * 10.0):
		var letter := 97 + absi(hash(slot * 31 + seed)) % 26
		var ts := TextServerManager.get_primary_interface()
		fx.glyph_index = ts.font_get_glyph_index(fx.font, 1, letter, 0)
	return true
