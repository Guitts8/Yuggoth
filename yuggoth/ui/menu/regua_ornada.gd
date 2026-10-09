class_name ReguaOrnada
extends Control
## A régua entre o título e o resto de uma página do livro dos menus: dois traços
## que afinam para fora, o losango rubro no meio e um pontinho de cada lado.

@export var largura := 260.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y <= 0.0:
		custom_minimum_size.y = 18.0
	resized.connect(queue_redraw)


func _draw() -> void:
	var c := size / 2.0
	var meia := minf(largura, size.x) / 2.0
	for s: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([c + Vector2(s * 12, -1.8), c + Vector2(s * meia, 0), c + Vector2(s * 12, 1.8)]), Color(Livro.TINTA, 0.85))
		_losango(c + Vector2(s * (meia * 0.45), 0), 2.6, Color(Livro.TINTA, 0.9))
		draw_circle(c + Vector2(s * (meia + 8.0), 0), 2.0, Color(Livro.RUBRO, 0.9))
	_losango(c, 6.5, Livro.RUBRO)
	_losango(c, 2.4, Color(Livro.PAPEL, 0.9))


func _losango(c: Vector2, r: float, cor: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), cor)
