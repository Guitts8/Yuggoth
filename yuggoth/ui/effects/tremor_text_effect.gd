class_name TremorTextEffect
extends RichTextEffect
## [tremulo]texto[/tremulo] — letra de mão trêmula: cada caractere um pouco fora
## do lugar, sempre o mesmo (é tinta no papel, não se mexe). Parâmetro opcional:
## [tremulo forca=0.5]. Para as cartas de Akeley de agosto em diante, "numa letra
## que se tornara lamentavelmente trêmula" (livro, cap. IV).

var bbcode := "tremulo"


func _process_custom_fx(fx: CharFXTransform) -> bool:
	var k := float(fx.env.get("forca", 0.5))
	var seed := fx.range.x
	fx.offset = Vector2(float(absi(hash(seed * 31)) % 5) - 2.0, float(absi(hash(seed * 17)) % 7) - 3.0) * k
	fx.transform = fx.transform.rotated_local(deg_to_rad((float(absi(hash(seed * 7)) % 9) - 4.0) * k * 2.0))
	return true
