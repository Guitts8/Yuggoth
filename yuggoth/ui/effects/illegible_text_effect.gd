class_name IllegibleTextEffect
extends RichTextEffect
## [ilegivel]texto[/ilegivel] — letra cerrada que não se consegue ler: a maior
## parte dos caracteres vira outro glifo, sempre o mesmo (não treme, como o
## sussurro); só uma ou outra letra escapa. Parâmetro: [ilegivel legivel=0.15].
## Usado onde o livro diz que havia texto e Wilmarth se recusa a transcrevê-lo.

var bbcode := "ilegivel"


func _process_custom_fx(fx: CharFXTransform) -> bool:
	var legivel := float(fx.env.get("legivel", 0.15))
	var seed := fx.range.x
	# Letra apertada e irregular: cada caractere um pouco fora da linha.
	fx.offset = Vector2(0.0, float(absi(hash(seed * 13)) % 5) - 2.0)
	fx.color.a *= 0.85
	if absi(hash(seed)) % 100 >= int(legivel * 100.0):
		var codigo := fx.glyph_index
		var ts := TextServerManager.get_primary_interface()
		# Espaços continuam espaços: as "palavras" mantêm o formato.
		var c := ts.font_get_char_from_glyph_index(fx.font, 1, codigo)
		if c != 32 and c != 10:
			var letra := 97 + absi(hash(seed * 7 + 3)) % 26
			fx.glyph_index = ts.font_get_glyph_index(fx.font, 1, letra, 0)
	return true
