class_name Gravura
extends Control
## A gravura da página da esquerda do livro dos menus, como a cruz radiante das
## páginas de Castlevania: Lords of Shadow 2 — aqui, a pedra negra de Round Hill
## (cap. I: "a grande pedra negra [...] de hieróglifos"), de pé num círculo de
## raios rubros e negros, com o anel de sinais em volta e, embaixo, nos dois
## medalhões, a marca de garra das fotografias de Akeley ("horrivelmente parecida
## com a de um caranguejo"). Desenhada a buril (_draw): massas de tinta,
## hachuras, os sinais claros riscados na pedra.

@export var semente := 1928
## Os dois medalhões com a marca de garra, embaixo.
@export var medalhoes := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var c := Vector2(size.x / 2.0, size.y * (0.42 if medalhoes else 0.5))
	var raio := minf(size.x * 0.46, size.y * (0.4 if medalhoes else 0.48))
	_raios(c, raio, rng)
	_anel(c, raio * 0.62, rng)
	_pedra(c + Vector2(0, raio * 0.08), raio * 0.95, rng)
	if medalhoes:
		for s: float in [-1.0, 1.0]:
			_medalhao(Vector2(size.x / 2.0 + s * size.x * 0.3, size.y * 0.86), minf(size.x * 0.14, size.y * 0.1), s)


## Os raios: finos e longos, alternando a tinta e o rubro, de comprimentos desiguais.
func _raios(c: Vector2, raio: float, rng: RandomNumberGenerator) -> void:
	var n := 64
	for k in n:
		var a := TAU * k / n + rng.randf_range(-0.01, 0.01)
		var d := Vector2(cos(a), sin(a))
		var longo := k % 4 == 0
		var fim := raio * (1.0 if longo else rng.randf_range(0.7, 0.88))
		var cor := Color(Livro.RUBRO, 0.85) if k % 2 == 0 else Color(Livro.TINTA, 0.55)
		var grosso := 2.6 if longo else 1.3
		# Um raio é uma cunha que afina para fora.
		var lado := Vector2(-d.y, d.x) * grosso
		draw_colored_polygon(PackedVector2Array([c + d * raio * 0.66 + lado, c + d * fim, c + d * raio * 0.66 - lado]), cor)
		if longo:
			_losango(c + d * (fim + 7.0), 3.0, Color(Livro.TINTA, 0.8))


## O anel dos sinais: dois círculos e, entre eles, glifos de alfabeto nenhum.
func _anel(c: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	draw_circle(c, r, Color(Livro.PAPEL, 1.0))
	draw_arc(c, r, 0.0, TAU, 96, Color(Livro.TINTA, 0.9), 3.0, true)
	draw_arc(c, r * 0.86, 0.0, TAU, 96, Color(Livro.TINTA, 0.75), 1.4, true)
	draw_arc(c, r * 0.83, 0.0, TAU, 96, Color(Livro.RUBRO, 0.7), 1.0, true)
	var n := 28
	for k in n:
		var a := TAU * k / n
		var p := c + Vector2(cos(a), sin(a)) * r * 0.93
		_glifo(p, a, rng, Color(Livro.TINTA, 0.85))
	# O fundo de dentro, hachurado em diagonal (a sombra do céu atrás da pedra).
	for k in range(-20, 21):
		var x := k * r * 0.07
		var h := sqrt(maxf(0.0, pow(r * 0.8, 2) - x * x))
		if h > 2.0:
			draw_line(c + Vector2(x - h * 0.3, -h), c + Vector2(x + h * 0.3, h), Color(Livro.TINTA, 0.16), 1.0, true)


## A pedra: uma estela negra, larga na base, o alto quebrado em diagonal, um
## pouco tombada; a luz da esquerda em hachuras claras; os hieróglifos riscados
## em colunas desiguais (que o tempo apagou aqui e ali).
func _pedra(c: Vector2, alto: float, rng: RandomNumberGenerator) -> void:
	var w := alto * 0.44
	var h := alto * 0.86
	var topo := c.y - h * 0.55
	var base := c.y + h * 0.45
	var contorno := PackedVector2Array([
		Vector2(c.x - w * 0.52, base),
		Vector2(c.x - w * 0.5, c.y + h * 0.1),
		Vector2(c.x - w * 0.44, topo + h * 0.22),
		Vector2(c.x - w * 0.36, topo + h * 0.07),
		Vector2(c.x - w * 0.12, topo - h * 0.02),
		Vector2(c.x + w * 0.06, topo + h * 0.05),
		Vector2(c.x + w * 0.22, topo + h * 0.02),
		Vector2(c.x + w * 0.4, topo + h * 0.17),
		Vector2(c.x + w * 0.44, c.y - h * 0.05),
		Vector2(c.x + w * 0.5, base),
	])
	# O chão: um monte de terra hachurado e a relva em tufos.
	for k in 8:
		var y := base + 3.0 + k * 3.6
		var meia := w * (1.25 - k * 0.11)
		draw_line(Vector2(c.x - meia, y), Vector2(c.x + meia, y), Color(Livro.TINTA, 0.6 - k * 0.06), 1.3, true)
	for k in 9:
		var x := c.x + rng.randf_range(-w * 1.1, w * 1.1)
		for f in 3:
			draw_line(Vector2(x, base + 4.0), Vector2(x + (f - 1) * 3.0, base - 5.0 - f % 2 * 3.0), Color(Livro.TINTA, 0.65), 1.0, true)
	draw_colored_polygon(contorno, Color(0.07, 0.045, 0.035))
	draw_polyline(contorno + PackedVector2Array([contorno[0]]), Color(Livro.TINTA, 1.0), 2.2, true)
	# A face da esquerda, na luz: uma faixa estreita de hachuras claras.
	var luz := Color(Livro.PAPEL, 0.5)
	for k in 30:
		var y := topo + 8.0 + k * (h - 12.0) / 30.0
		var linha := PackedVector2Array([Vector2(c.x - w * 0.6, y + 5.0), Vector2(c.x - w * 0.3, y - 5.0)])
		for trecho in Geometry2D.intersect_polyline_with_polygon(linha, contorno):
			draw_polyline(trecho, luz, 1.0, true)
	# A aresta entre as duas faces.
	draw_line(Vector2(c.x - w * 0.33, topo + h * 0.08), Vector2(c.x - w * 0.36, base), Color(0.32, 0.22, 0.15, 0.7), 1.3, true)
	# Os hieróglifos: colunas na face da frente, sinais claros de tamanhos desiguais.
	var cor := Color(0.8, 0.64, 0.42, 0.75)
	var x := c.x - w * 0.22
	while x < c.x + w * 0.36:
		var y := topo + h * (0.16 + rng.randf_range(0.0, 0.06))
		while y < base - h * 0.08:
			var p := Vector2(x + rng.randf_range(-1.5, 1.5), y)
			if Geometry2D.is_point_in_polygon(p, contorno) and rng.randf() > 0.12:
				_glifo(p, -PI / 2.0, rng, cor, rng.randf_range(0.35, 0.55))
			y += h * rng.randf_range(0.045, 0.075)
		x += w * 0.115
	# Uma rachadura que desce do alto quebrado.
	var rachadura := PackedVector2Array()
	var q := Vector2(c.x + w * 0.1, topo + h * 0.04)
	for k in 7:
		rachadura.append(q)
		q += Vector2(rng.randf_range(-4.0, 4.0), h * 0.05)
	draw_polyline(rachadura, Color(0.0, 0.0, 0.0, 0.9), 1.4, true)


## Um medalhão: o círculo com a moldura, as hachuras e a marca de garra no meio.
func _medalhao(c: Vector2, r: float, lado: float) -> void:
	draw_circle(c, r, Color(Livro.PAPEL, 1.0))
	for k in range(-10, 11):
		var x := k * r * 0.1
		var h := sqrt(maxf(0.0, r * r * 0.72 - x * x))
		draw_line(c + Vector2(x, -h), c + Vector2(x, h), Color(Livro.TINTA, 0.12), 1.0, true)
	draw_arc(c, r, 0.0, TAU, 64, Color(Livro.TINTA, 0.95), 2.6, true)
	draw_arc(c, r * 0.86, 0.0, TAU, 64, Color(Livro.RUBRO, 0.85), 1.2, true)
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		_losango(c + Vector2(cos(a), sin(a)) * r * 0.93, 2.2, Color(Livro.TINTA, 0.9))
	_garra(c, r * 0.62, lado)


## A marca de garra: a almofada no meio e pares de pinças serrilhadas saindo em
## direções opostas — e a ambiguidade de para que lado ela vai.
func _garra(c: Vector2, r: float, lado: float) -> void:
	var tinta := Color(0.08, 0.05, 0.04)
	draw_circle(c, r * 0.22, tinta)
	for s: float in [-1.0, 1.0]:
		for p: float in [-1.0, 1.0]:
			var a := (0.0 if s > 0.0 else PI) + p * 0.42 + lado * 0.1
			var d := Vector2(cos(a), sin(a))
			var base := c + d * r * 0.18
			var ponta := c + d * r * 0.95 + Vector2(-d.y, d.x) * p * r * 0.12
			var largura := Vector2(-d.y, d.x) * r * 0.1
			draw_colored_polygon(PackedVector2Array([base + largura, ponta, base - largura]), tinta)
			# Os dentes da pinça.
			for k in 3:
				var q := base.lerp(ponta, 0.35 + k * 0.18)
				draw_line(q, q + Vector2(-d.y, d.x) * -p * r * 0.1, tinta, 1.4, true)


func _losango(c: Vector2, r: float, cor: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), cor)


## Um sinal de alfabeto nenhum, de dois a quatro traços, girado com o anel.
func _glifo(c: Vector2, ang: float, rng: RandomNumberGenerator, cor: Color, escala := 1.0) -> void:
	var t := Transform2D(ang + PI / 2.0, c)
	for k in rng.randi_range(2, 4):
		var a := Vector2(rng.randf_range(-5, 5), rng.randf_range(-7, 7)) * escala
		var b := Vector2(rng.randf_range(-5, 5), rng.randf_range(-7, 7)) * escala
		draw_line(t * a, t * b, cor, 1.5 * maxf(escala, 0.8), true)
	if rng.randf() < 0.35:
		draw_circle(t * (Vector2(rng.randf_range(-3, 3), -8) * escala), 1.6 * escala, cor)
