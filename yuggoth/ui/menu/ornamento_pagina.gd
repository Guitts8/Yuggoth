class_name OrnamentoPagina
extends Control
## O que está impresso em toda página do livro dos menus, por baixo do texto (à
## maneira das páginas de Castlevania: Lords of Shadow 2): a moldura de filete
## duplo com florões nos cantos e no meio das bordas, rubricada; a escrita de
## outra mão, apagada pelo tempo, num canto; e, se `circulo`, um diagrama arcano
## desbotado atrás do conteúdo. Tudo desenhado (_draw), na tinta do Livro.

## A semente das irregularidades (a escrita apagada muda de página para página).
@export var semente := 1
## O diagrama desbotado atrás do conteúdo.
@export var circulo := false
## O canto da escrita apagada: 0 em cima, 1 embaixo.
@export var escrita_embaixo := false

const DENTRO := 34.0
const FILETE := 9.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-DENTRO)
	if r.size.x <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	if circulo:
		_circulo_arcano(r.get_center() + Vector2(0, 40), minf(r.size.x, r.size.y) * 0.4, rng)
	_escrita_apagada(r, rng)
	_moldura(r)


## O filete duplo: o de fora grosso, o de dentro fino; nos cantos, um quadrado
## com um losango rubro e duas volutas; no meio de cima e de baixo, o florão.
func _moldura(r: Rect2) -> void:
	var tinta := Color(Livro.TINTA, 0.82)
	var fina := Color(Livro.TINTA, 0.6)
	var dentro := r.grow(-FILETE)
	draw_rect(r, tinta, false, 2.6, true)
	draw_rect(dentro, fina, false, 1.2, true)
	for canto: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var para_dentro := (r.get_center() - canto).sign()
		var q := Rect2(canto + Vector2(minf(0.0, para_dentro.x), minf(0.0, para_dentro.y)) * FILETE, Vector2.ONE * FILETE)
		draw_rect(q.grow(1.0), Color(Livro.PAPEL, 1.0))
		draw_rect(q, tinta, false, 1.4, true)
		var meio := q.get_center()
		_losango(meio, 3.2, Livro.RUBRO)
		# As volutas, para dentro, ao longo das duas bordas.
		for eixo: Vector2 in [Vector2(para_dentro.x, 0), Vector2(0, para_dentro.y)]:
			# A voluta enrola para dentro da página (o outro eixo).
			var dentro_da_pagina := Vector2(0, para_dentro.y) if eixo.y == 0.0 else Vector2(para_dentro.x, 0)
			var fim := meio + eixo * (FILETE + 30.0)
			draw_line(meio + eixo * FILETE * 0.7, fim, fina, 1.1, true)
			_voluta(fim + dentro_da_pagina * 7.0, 5.0, (-dentro_da_pagina).angle(), fina)
	for y: float in [r.position.y, r.end.y]:
		_florao(Vector2(r.get_center().x, y + (FILETE / 2.0 if y == r.position.y else -FILETE / 2.0)))
	for x: float in [r.position.x, r.end.x]:
		_losango(Vector2(x + (FILETE / 2.0 if x == r.position.x else -FILETE / 2.0), r.get_center().y), 4.0, Livro.RUBRO)


## O florão do meio da borda: um losango rubro entre dois traços que afinam.
func _florao(c: Vector2) -> void:
	draw_rect(Rect2(c - Vector2(40, 6), Vector2(80, 12)), Color(Livro.PAPEL, 1.0))
	for s: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([c + Vector2(s * 9, -1.6), c + Vector2(s * 38, 0), c + Vector2(s * 9, 1.6)]), Color(Livro.TINTA, 0.85))
		_losango(c + Vector2(s * 20, 0), 2.2, Color(Livro.TINTA, 0.85))
	_losango(c, 5.5, Livro.RUBRO)


func _losango(c: Vector2, r: float, cor: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), cor)


## Uma voluta: a espiral de pena que fecha um traço.
func _voluta(c: Vector2, r: float, ang: float, cor: Color) -> void:
	var pts := PackedVector2Array()
	for k in 22:
		var t := float(k) / 21.0
		var a := ang + PI * 0.5 + t * TAU * 1.1
		pts.append(c + Vector2(cos(a), sin(a)) * r * (1.0 - t * 0.75))
	draw_polyline(pts, cor, 1.1, true)


## Linhas de uma letra apertada que o tempo apagou: só a cadência dos traços.
func _escrita_apagada(r: Rect2, rng: RandomNumberGenerator) -> void:
	var cor := Color(Livro.TINTA, 0.07)
	var largura := r.size.x * rng.randf_range(0.42, 0.55)
	var x0 := r.position.x + FILETE + 18.0 + (0.0 if rng.randf() < 0.5 else r.size.x - largura - FILETE * 2.0 - 36.0)
	var linhas := rng.randi_range(5, 8)
	var y0 := (r.end.y - FILETE - 30.0 - linhas * 17.0) if escrita_embaixo else (r.position.y + FILETE + 30.0)
	for l in linhas:
		var y := y0 + l * 17.0
		var x := x0 + (rng.randf_range(10.0, 40.0) if l == 0 else 0.0)
		var fim := x0 + largura * (rng.randf_range(0.55, 0.9) if l == linhas - 1 else rng.randf_range(0.92, 1.0))
		while x < fim:
			var palavra := rng.randf_range(14.0, 46.0)
			var pts := PackedVector2Array()
			var n := int(palavra / 3.0)
			for k in n:
				var px := x + palavra * k / maxf(1.0, n - 1.0)
				pts.append(Vector2(px, y + sin(k * 2.3 + l) * 2.2 - (4.0 if rng.randf() < 0.12 else 0.0)))
			draw_polyline(pts, cor, 1.3, true)
			x += palavra + rng.randf_range(6.0, 10.0)


## Um círculo de invocação desbotado: anéis, a estrela, as marcas em volta.
func _circulo_arcano(c: Vector2, raio: float, rng: RandomNumberGenerator) -> void:
	var cor := Color(Livro.TINTA, 0.075)
	var rubro := Color(Livro.RUBRO, 0.07)
	draw_arc(c, raio, 0.0, TAU, 96, cor, 2.0, true)
	draw_arc(c, raio * 0.92, 0.0, TAU, 96, cor, 1.0, true)
	draw_arc(c, raio * 0.62, 0.0, TAU, 72, rubro, 1.6, true)
	for k in 5:
		var a := -PI / 2.0 + TAU * k / 5.0
		var b := -PI / 2.0 + TAU * (k + 2) / 5.0
		draw_line(c + Vector2(cos(a), sin(a)) * raio * 0.92, c + Vector2(cos(b), sin(b)) * raio * 0.92, cor, 1.2, true)
	for k in 36:
		var a := TAU * k / 36.0
		var d := Vector2(cos(a), sin(a))
		if k % 3 == 0:
			_glifo(c + d * raio * 0.96, rng, cor)
		else:
			draw_line(c + d * raio * 0.92, c + d * raio * (0.95 if k % 3 == 1 else 0.97), cor, 1.0, true)


## Um sinal de alfabeto nenhum: dois ou três traços curtos.
func _glifo(c: Vector2, rng: RandomNumberGenerator, cor: Color) -> void:
	for k in rng.randi_range(2, 3):
		var a := Vector2(rng.randf_range(-5, 5), rng.randf_range(-6, 6))
		var b := Vector2(rng.randf_range(-5, 5), rng.randf_range(-6, 6))
		draw_line(c + a, c + b, cor, 1.2, true)
