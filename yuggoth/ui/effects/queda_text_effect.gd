class_name QuedaTextEffect
extends RichTextEffect
## [queda]texto[/queda] — a linha que o sono derruba: cada letra um pouco mais
## abaixo, mais torta e mais clara que a anterior, como a mão de quem adormece
## escrevendo (o diário, nas noites de sonho). Fixa, não treme. Parâmetro
## opcional: [queda forca=1.0].

var bbcode := "queda"


func _process_custom_fx(fx: CharFXTransform) -> bool:
	var k := float(fx.env.get("forca", 1.0))
	var i := fx.relative_index
	fx.offset = deslocamento(i, k)
	fx.transform = fx.transform.rotated_local(deg_to_rad(minf(i * 0.4 * k, 16.0)))
	fx.color.a *= clampf(1.0 - i * 0.012 * k, 0.4, 1.0)
	return true


## Quanto a letra `i` do bloco desce (e escorrega para a direita), em pixels.
static func deslocamento(i: int, forca := 1.0) -> Vector2:
	return Vector2(i * 0.12, i * i * 0.014) * forca
