extends SceneTree
## Gera texturas pixeladas e sons provisórios do escritório. Determinístico
## (mesmas sementes, mesmo resultado). Rodar da pasta yuggoth/:
##   godot --headless --script res://tools/gerar_assets.gd
## Sobrescreve art/textures/*.png e audio/placeholder/*.wav. Os sons são
## placeholders sintetizados; troque pelos definitivos sem mudar o nome.

const TEX_DIR := "res://art/textures/"
const SFX_DIR := "res://audio/placeholder/"
const RATE := 22050


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEX_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SFX_DIR))
	_texturas()
	_sons()
	print("gerar_assets: pronto")
	quit()


# --- Texturas ----------------------------------------------------------------

func _texturas() -> void:
	_save(_madeira(Color(0.36, 0.22, 0.13), 11, 16), "madeira_escura")
	_save(_madeira(Color(0.52, 0.36, 0.22), 12, 0), "madeira_clara")
	_save(_porta(), "porta")
	_save(_assoalho(), "assoalho")
	_save(_papel_parede(), "papel_parede")
	_save(_reboco(), "reboco")
	_save(_tijolo(), "tijolo")
	_save(_lombadas(), "lombadas")
	_save(_cortica(), "cortica")
	_save(_tapete(), "tapete")
	_save(_tecido(Color(0.24, 0.31, 0.21), 21), "estofado")
	_save(_lencol(), "lencol")
	_save(_papel(), "papel")
	_save(_latao(), "latao")
	_save(_cinzas(), "cinzas")
	_save(_caixa_cartas(), "caixa_cartas")
	_save(_mostrador(), "mostrador")
	_save(_vista(false), "vista_noite")
	_save(_vista(true), "vista_dia")
	_save(_vista_entardecer(), "vista_entardecer")
	_save(_gota(), "gota")
	# Correspondência.
	_save(_papel_envelope(), "papel_envelope")
	_save(_selo(), "selo_2c")
	_save(_carimbo(), "carimbo")
	# As fotografias de Akeley (cap. II).
	_save(_foto_pegada(), "foto_pegada")
	_save(_foto_caverna(), "foto_caverna")
	_save(_foto_circulo(), "foto_circulo")
	_save(_foto_pedra(), "foto_pedra")
	_save(_foto_pantano(51, false), "foto_pantano_1")
	_save(_foto_pantano(52, true), "foto_colina")
	_save(_foto_pantano(53, false), "foto_pantano_2")
	_save(_foto_marca(), "foto_marca")
	_save(_foto_casa(), "foto_casa")
	_save(_foto_exercito(), "foto_exercito")


func _save(img: Image, name: String) -> void:
	img.save_png(TEX_DIR + name + ".png")


func _img(w := 64, h := 64) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _noise(seed: int, freq: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed
	n.frequency = freq
	return n


func _shade(c: Color, f: float) -> Color:
	return Color(clampf(c.r * f, 0, 1), clampf(c.g * f, 0, 1), clampf(c.b * f, 0, 1), c.a)


## Veios verticais; `junta` > 0 desenha a junta entre tábuas a cada N px.
func _madeira(base: Color, seed: int, junta: int) -> Image:
	var img := _img()
	var n := _noise(seed, 0.07)
	for y in 64:
		for x in 64:
			var g := n.get_noise_2d(x * 5.0, y * 0.35)
			var veio := sin((x + g * 7.0) * 1.1) * 0.5 + 0.5
			var f := 0.84 + veio * 0.16 + g * 0.08
			if junta > 0 and x % junta == 0:
				f *= 0.55
			img.set_pixel(x, y, _shade(base, f))
	return img


func _porta() -> Image:
	var img := _madeira(Color(0.33, 0.2, 0.12), 13, 0)
	# Duas almofadas (painéis) com sombra embaixo/direita e luz em cima/esquerda.
	for r: Rect2i in [Rect2i(10, 6, 44, 22), Rect2i(10, 36, 44, 22)]:
		for x in range(r.position.x, r.end.x):
			_mul(img, x, r.position.y, 1.3)
			_mul(img, x, r.end.y - 1, 0.55)
		for y in range(r.position.y, r.end.y):
			_mul(img, r.position.x, y, 1.25)
			_mul(img, r.end.x - 1, y, 0.6)
	return img


func _mul(img: Image, x: int, y: int, f: float) -> void:
	img.set_pixel(x, y, _shade(img.get_pixel(x, y), f))


func _assoalho() -> Image:
	var img := _img()
	var n := _noise(14, 0.06)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var base := Color(0.40, 0.27, 0.17)
	for row in 4:
		var offset := rng.randi_range(0, 63)
		var tom := rng.randf_range(0.85, 1.1)
		for y in range(row * 16, row * 16 + 16):
			for x in 64:
				var g := n.get_noise_2d(x * 0.35, y * 5.0 + row * 40)
				var f := tom * (0.86 + g * 0.14 + sin((y + g * 5.0) * 1.3) * 0.05)
				if y % 16 == 0 or (x + offset) % 64 == 0:
					f *= 0.5
				img.set_pixel(x, y, _shade(base, f))
	return img


func _papel_parede() -> Image:
	var img := _img()
	var n := _noise(15, 0.05)
	var base := Color(0.34, 0.38, 0.30)
	for y in 64:
		for x in 64:
			var f := 0.95 + n.get_noise_2d(x, y) * 0.06
			if x % 16 == 0 or x % 16 == 1:
				f *= 1.12  # listra
			# Losango pequeno entre as listras.
			var lx := absi((x % 16) - 8)
			var ly := absi((y % 16) - 8)
			if lx + ly == 3:
				f *= 1.18
			img.set_pixel(x, y, _shade(base, f))
	return img


func _reboco() -> Image:
	var img := _img()
	var n := _noise(16, 0.09)
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, _shade(Color(0.74, 0.70, 0.62), 0.92 + n.get_noise_2d(x, y) * 0.08))
	return img


func _tijolo() -> Image:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var n := _noise(17, 0.2)
	for row in 8:
		var shift := 8 if row % 2 else 0
		for b in 5:
			var tom := Color(0.45, 0.22, 0.16).lerp(Color(0.38, 0.25, 0.2), rng.randf())
			for y in range(row * 8, row * 8 + 8):
				for x in range(b * 16 - shift, b * 16 + 16 - shift):
					var px := posmod(x, 64)
					var junta := y % 8 == 0 or posmod(x + shift, 16) == 0
					var c := Color(0.5, 0.47, 0.42) if junta else _shade(tom, 0.9 + n.get_noise_2d(px, y) * 0.12)
					img.set_pixel(px, y, c)
	return img


func _lombadas() -> Image:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 18
	var cores := [Color(0.42, 0.12, 0.1), Color(0.14, 0.25, 0.16), Color(0.12, 0.15, 0.3),
		Color(0.5, 0.38, 0.18), Color(0.3, 0.2, 0.12), Color(0.22, 0.2, 0.18)]
	var x := 0
	while x < 64:
		var w := rng.randi_range(3, 6)
		var c: Color = cores[rng.randi_range(0, cores.size() - 1)]
		var topo := rng.randi_range(0, 8)  # livros de alturas diferentes
		for xx in range(x, mini(x + w, 64)):
			for y in 64:
				var col := Color(0.06, 0.05, 0.04) if y < topo else c
				if y >= topo and (y == topo + 6 or y == 56):
					col = Color(0.62, 0.5, 0.25)  # faixa dourada
				if xx == x:
					col = _shade(col, 0.6)
				img.set_pixel(xx, y, col)
		x += w
	return img


func _cortica() -> Image:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, _shade(Color(0.56, 0.40, 0.25), rng.randf_range(0.75, 1.15)))
	return img


func _tapete() -> Image:
	var img := _img()
	var n := _noise(20, 0.3)
	for y in 64:
		for x in 64:
			var borda := mini(mini(x, 63 - x), mini(y, 63 - y))
			var c := Color(0.36, 0.1, 0.09)
			if borda < 6:
				c = Color(0.55, 0.42, 0.2)
				if borda == 2:
					c = Color(0.2, 0.12, 0.1)
			elif (absi(x - 32) + absi(y - 32)) % 12 < 2:
				c = Color(0.55, 0.42, 0.2)
			img.set_pixel(x, y, _shade(c, 0.9 + n.get_noise_2d(x, y) * 0.1))
	return img


func _tecido(base: Color, seed: int) -> Image:
	var img := _img()
	var n := _noise(seed, 0.15)
	for y in 64:
		for x in 64:
			var trama := 1.0 if (x + y) % 2 else 0.94
			img.set_pixel(x, y, _shade(base, trama * (0.9 + n.get_noise_2d(x, y) * 0.12)))
	return img


func _lencol() -> Image:
	var img := _img()
	var n := _noise(22, 0.04)
	for y in 64:
		for x in 64:
			var dobra := sin(x * 0.35 + n.get_noise_2d(x, y) * 6.0) * 0.07
			img.set_pixel(x, y, _shade(Color(0.78, 0.77, 0.72), 0.92 + dobra))
	return img


func _papel() -> Image:
	var img := _img()
	var n := _noise(23, 0.08)
	for y in 64:
		for x in 64:
			var f := 0.96 + n.get_noise_2d(x, y) * 0.04
			if y % 6 == 5 and x > 6 and x < 58:
				f *= 0.8  # linhas de escrita
			img.set_pixel(x, y, _shade(Color(0.88, 0.84, 0.72), f))
	return img


func _latao() -> Image:
	var img := _img()
	var n := _noise(24, 0.1)
	for y in 64:
		for x in 64:
			var brilho := 1.0 + pow(maxf(0.0, sin(x * 0.2)), 8.0) * 0.4
			img.set_pixel(x, y, _shade(Color(0.66, 0.5, 0.24), brilho * (0.88 + n.get_noise_2d(x, y) * 0.12)))
	return img


func _cinzas() -> Image:
	var img := _img()
	var n := _noise(25, 0.15)
	for y in 64:
		for x in 64:
			var v := 0.12 + n.get_noise_2d(x, y) * 0.08
			img.set_pixel(x, y, Color(v, v * 0.95, v * 0.9))
	return img


func _caixa_cartas() -> Image:
	var img := _madeira(Color(0.42, 0.3, 0.2), 26, 0)
	# Barbante cruzado no meio da tampa.
	for i in 64:
		for d in 2:
			img.set_pixel(31 + d, i, Color(0.78, 0.7, 0.52))
			img.set_pixel(i, 31 + d, Color(0.78, 0.7, 0.52))
	return img


func _mostrador() -> Image:
	var img := _img(32, 32)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5)
			var c := Color(0.86, 0.82, 0.7)
			if d.length() > 15.0:
				c = Color(0.25, 0.16, 0.1)
			elif d.length() > 12.5:
				# Marcas das horas.
				var a := fposmod(atan2(d.y, d.x), TAU / 12.0)
				if a < 0.12 or a > TAU / 12.0 - 0.12:
					c = Color(0.1, 0.08, 0.06)
			img.set_pixel(x, y, c)
	return img


## Paisagem atrás da janela: telhados de Arkham.
func _vista(dia: bool) -> Image:
	if dia:
		return _vista_cores(Color(0.58, 0.68, 0.8), Color(0.86, 0.84, 0.74), Color(0.4, 0.33, 0.3), Color(0.28, 0.36, 0.22), true, 0.0)
	return _vista_cores(Color(0.03, 0.04, 0.08), Color(0.08, 0.09, 0.14), Color(0.02, 0.02, 0.035), Color(0.015, 0.02, 0.025), false, 0.004)


## Telhados de Arkham com a paleta dada. `faces` = fachadas com luz e sombra;
## `janelas` = chance de cada pixel de prédio ser uma janela acesa.
func _vista_cores(ceu_alto: Color, ceu_baixo: Color, predio: Color, arvore: Color, faces: bool, janelas: float) -> Image:
	var img := _img(128, 64)
	var n := _noise(27, 0.03)
	var rng := RandomNumberGenerator.new()
	rng.seed = 27
	# Perfil de telhados em degraus, com empenas.
	var alturas := PackedInt32Array()
	alturas.resize(128)
	var x := 0
	while x < 128:
		var w := rng.randi_range(10, 22)
		var h := rng.randi_range(20, 38)
		for i in w:
			if x + i < 128:
				var empena := mini(i, w - 1 - i) / 2
				alturas[x + i] = h + empena
		x += w
	for yy in 64:
		for xx in 128:
			var t := yy / 63.0
			var c := ceu_alto.lerp(ceu_baixo, t)
			var copa := 14 + int(n.get_noise_1d(xx * 3.0) * 8.0)
			if yy > 64 - copa:
				c = _shade(arvore, 0.9 + n.get_noise_2d(xx * 4.0, yy * 4.0) * 0.2)
			if yy > 64 - alturas[xx]:
				c = predio
				if faces:
					c = _shade(predio, 1.1 if xx % 7 < 4 else 0.9)
				if rng.randf() < janelas:
					c = Color(0.55, 0.42, 0.18)  # janela acesa
			img.set_pixel(xx, yy, c)
	return img


## Fim de tarde (Dia 2): céu alaranjado, telhados em contraluz, janelas acendendo.
func _vista_entardecer() -> Image:
	return _vista_cores(Color(0.34, 0.28, 0.4), Color(0.96, 0.6, 0.32), Color(0.13, 0.09, 0.1), Color(0.1, 0.08, 0.08), false, 0.002)


# --- Correspondência -------------------------------------------------------------

func _papel_envelope() -> Image:
	var img := _img()
	var n := _noise(29, 0.07)
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, _shade(Color(0.86, 0.81, 0.68), 0.95 + n.get_noise_2d(x, y) * 0.05))
	return img


## Selo de dois centavos, carmim, perfurado (os americanos comuns de 1928).
func _selo() -> Image:
	var img := _img(32, 40)
	img.fill(Color(0.93, 0.9, 0.84))
	for y in 40:
		for x in 32:
			# Furos da perfuração nas bordas.
			var borda := x == 0 or x == 31 or y == 0 or y == 39
			if borda and ((x + y) % 3 == 0):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			if x >= 3 and x <= 28 and y >= 3 and y <= 36:
				var c := Color(0.66, 0.12, 0.15)
				if x == 4 or x == 27 or y == 4 or y == 35:
					c = Color(0.85, 0.5, 0.5)  # filete
				var d := Vector2((x - 15.5) / 9.0, (y - 18.0) / 11.0)
				if d.length() < 1.0:
					c = Color(0.94, 0.86, 0.82)
					# Busto de perfil (cabeça, pescoço, ombros) dentro do oval.
					var cabeca := Vector2((x - 16.0) / 3.6, (y - 14.0) / 4.4).length() < 1.0
					var nariz := x == 19 and y >= 13 and y <= 14
					var pescoco := x >= 14 and x <= 17 and y >= 18 and y <= 21
					var ombros := Vector2((x - 15.5) / 7.0, (y - 26.0) / 4.5).length() < 1.0
					if cabeca or nariz or pescoco or ombros:
						c = Color(0.62, 0.12, 0.15)
				if y >= 30 and (x <= 8 or x >= 23) and y <= 34:
					c = Color(0.95, 0.88, 0.85)  # algarismo "2" nos cantos
				img.set_pixel(x, y, c)
	return img


## Carimbo: círculo com dupla borda + linhas onduladas de cancelamento. Fundo
## transparente; o texto (cidade, data) é um Label3D por cima, no Envelope.
func _carimbo() -> Image:
	var img := _img(64, 32)
	var rng := RandomNumberGenerator.new()
	rng.seed = 30
	var tinta := Color(0.12, 0.12, 0.2)
	for y in 32:
		for x in 64:
			var d := Vector2(x - 15.5, y - 15.5).length()
			var on := (d > 12.5 and d < 14.5) or (d > 10.0 and d < 10.9)
			if x > 30:
				for k in 5:
					var wy := 6.0 + k * 5.0 + sin(x * 0.35) * 1.4
					if absf(y - wy) < 0.7:
						on = true
			if on and rng.randf() > 0.12:
				img.set_pixel(x, y, Color(tinta, rng.randf_range(0.6, 0.95)))
	return img


# --- Fotografias de Akeley ----------------------------------------------------------
# Desenhadas em tons de cinza (128x96) e depois "reveladas": desfoque, sépia,
# grão e vinheta. Vagas de propósito (o livro: "apesar de vagas, quase todas").

const FW := 128
const FH := 96


func _foto(base: float) -> Image:
	var img := Image.create(FW, FH, false, Image.FORMAT_RGBA8)
	img.fill(Color(base, base, base))
	return img


func _lum(img: Image, x: int, y: int) -> float:
	return img.get_pixel(x, y).r


func _put(img: Image, x: int, y: int, v: float) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		v = clampf(v, 0.0, 1.0)
		img.set_pixel(x, y, Color(v, v, v))


func _ruido(img: Image, seed: int, freq: float, amp: float, rect := Rect2i(0, 0, FW, FH)) -> void:
	var n := _noise(seed, freq)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_put(img, x, y, _lum(img, x, y) + n.get_noise_2d(x, y) * amp)


func _elipse(img: Image, c: Vector2, r: Vector2, v: float, mistura := 1.0) -> void:
	for y in range(int(c.y - r.y) - 1, int(c.y + r.y) + 2):
		for x in range(int(c.x - r.x) - 1, int(c.x + r.x) + 2):
			var d := Vector2((x - c.x) / r.x, (y - c.y) / r.y).length()
			if d <= 1.0 and x >= 0 and y >= 0 and x < FW and y < FH:
				_put(img, x, y, lerpf(_lum(img, x, y), v, mistura))


func _retangulo(img: Image, r: Rect2i, v: float) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_put(img, x, y, v)


func _linha(img: Image, a: Vector2, b: Vector2, v: float, largura := 1.0) -> void:
	var passos := int(a.distance_to(b) * 2.0) + 1
	for i in passos + 1:
		var p := a.lerp(b, float(i) / passos)
		var w := int(ceil(largura * 0.5))
		for oy in range(-w, w + 1):
			for ox in range(-w, w + 1):
				if Vector2(ox, oy).length() <= largura * 0.5 + 0.2:
					_put(img, int(p.x) + ox, int(p.y) + oy, v)


## A marca de garra do livro: almofada central e pares de pinças serrilhadas
## projetando-se em direções opostas.
func _garra(img: Image, c: Vector2, escala: float, escuro: float) -> void:
	_elipse(img, c + Vector2(-1, -1) * escala, Vector2(9, 7) * escala, escuro + 0.35, 0.6)  # borda iluminada
	_elipse(img, c, Vector2(9, 7) * escala, escuro)
	for lado in [-1.0, 1.0]:
		for k in [-1.0, 1.0]:
			var a := c + Vector2(lado * 8.0, k * 3.0) * escala
			var b := c + Vector2(lado * 30.0, k * 9.0) * escala
			_linha(img, a, b, escuro, 3.0 * escala)
			for t in range(1, 7):
				var p := a.lerp(b, t / 7.0)
				_linha(img, p, p + Vector2(0, -k * 2.5) * escala, escuro, 1.0)


func _revelar(img: Image, seed: int, desfoque := 1) -> Image:
	for i in desfoque:
		var copia := img.duplicate() as Image
		for y in FH:
			for x in FW:
				var soma := 0.0
				var n := 0
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						var xx := clampi(x + ox, 0, FW - 1)
						var yy := clampi(y + oy, 0, FH - 1)
						soma += copia.get_pixel(xx, yy).r
						n += 1
				_put(img, x, y, soma / n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out := Image.create(FW, FH, false, Image.FORMAT_RGBA8)
	for y in FH:
		for x in FW:
			var v := _lum(img, x, y) + rng.randf_range(-0.04, 0.04)
			var d := Vector2((x - FW * 0.5) / FW, (y - FH * 0.5) / FH).length()
			v *= clampf(1.15 - d * d * 1.6, 0.0, 1.0)
			out.set_pixel(x, y, Color(v * 1.02, v * 0.9, v * 0.72))
	return out


func _foto_pegada() -> Image:
	var img := _foto(0.45)
	_ruido(img, 41, 0.06, 0.18)
	_ruido(img, 42, 0.4, 0.08)
	for y in FH:  # sol batendo no barro, mais forte no alto
		for x in FW:
			_put(img, x, y, _lum(img, x, y) + (1.0 - y / float(FH)) * 0.12)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 28:  # seixos
		var c := Vector2(rng.randf_range(4, 124), rng.randf_range(4, 92))
		var r := rng.randf_range(1.0, 2.6)
		_elipse(img, c + Vector2(1, 1), Vector2(r, r * 0.8), 0.25)
		_elipse(img, c, Vector2(r, r * 0.8), 0.78)
	for i in 40:  # folhas de grama nas bordas
		var x := rng.randf_range(0, 128)
		var base_y := 96.0 if x > 20 and x < 108 else rng.randf_range(20, 96)
		_linha(img, Vector2(x, base_y), Vector2(x + rng.randf_range(-4, 4), base_y - rng.randf_range(8, 18)), 0.75, 1.0)
	_garra(img, Vector2(64, 48), 1.0, 0.16)
	return _revelar(img, 41)


func _foto_caverna() -> Image:
	var img := _foto(0.2)
	_ruido(img, 43, 0.05, 0.1)
	_ruido(img, 44, 0.3, 0.06, Rect2i(0, 0, FW, 60))
	_elipse(img, Vector2(64, 44), Vector2(28, 19), 0.04)  # boca da caverna
	for y in range(28, 66):  # matacão arredondado, luz no alto à esquerda
		for x in range(46, 84):
			var d := Vector2((x - 64.0) / 17.0, (y - 48.0) / 16.0)
			if d.length() <= 1.0:
				_put(img, x, y, 0.36 - (d.x + d.y) * 0.08)
	_ruido(img, 45, 0.2, 0.06, Rect2i(0, 66, FW, 30))
	for y in range(66, 96):
		for x in FW:
			_put(img, x, y, _lum(img, x, y) + 0.08)
	var rng := RandomNumberGenerator.new()
	rng.seed = 43
	for i in 24:  # a rede de rastros: só se vê de perto
		_garra(img, Vector2(rng.randf_range(28, 100), rng.randf_range(72, 92)), 0.16, 0.13)
	return _revelar(img, 43)


func _foto_circulo() -> Image:
	var img := _foto(0.8)
	for y in 40:
		for x in FW:
			_put(img, x, y, 0.84 - y * 0.004)
	var serras := [[0.58, 30.0, 61], [0.47, 38.0, 62], [0.4, 46.0, 63]]
	for s: Array in serras:  # mar de montanhas desabitadas
		var n := _noise(s[2], 0.04)
		for x in FW:
			var topo := int(s[1] + n.get_noise_1d(x) * 8.0)
			for y in range(topo, 62):
				_put(img, x, y, s[0])
	_retangulo(img, Rect2i(0, 60, FW, 36), 0.5)
	_ruido(img, 46, 0.25, 0.08, Rect2i(0, 60, FW, 36))
	for y in range(60, 96):  # grama batida e gasta em volta do círculo
		for x in FW:
			var d := Vector2((x - 64.0) / 38.0, (y - 76.0) / 11.0).length()
			if d > 0.75 and d < 1.2:
				_put(img, x, y, _lum(img, x, y) + 0.12)
	for i in 9:  # pedras de pé
		var a := TAU * i / 9.0
		var p := Vector2(64 + cos(a) * 34.0, 76 + sin(a) * 9.0)
		var h := 11.0 + sin(a) * 4.0
		var w := 4 + int(sin(a) + 1.0)
		_retangulo(img, Rect2i(int(p.x), int(p.y - h), w, int(h)), 0.22)
		_retangulo(img, Rect2i(int(p.x), int(p.y - h), 1, int(h)), 0.4)
	return _revelar(img, 46)


func _foto_pedra() -> Image:
	var img := _foto(0.3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	for fila in 2:  # fileiras de livros ao fundo
		var x := 0
		while x < FW:
			var w := rng.randi_range(3, 6)
			_retangulo(img, Rect2i(x, 4 + fila * 26, w, 22), rng.randf_range(0.18, 0.45))
			x += w + 1
		_retangulo(img, Rect2i(0, 26 + fila * 26, FW, 3), 0.15)
	_retangulo(img, Rect2i(0, 62, FW, 34), 0.4)  # a mesa
	_ruido(img, 48, 0.08, 0.06, Rect2i(0, 62, FW, 34))
	# Busto de Milton, à esquerda.
	_elipse(img, Vector2(22, 34), Vector2(8, 10), 0.82)
	_elipse(img, Vector2(20, 32), Vector2(4, 5), 0.9, 0.5)
	for y in range(44, 64):
		var meia := 6 + (y - 44) * 0.6
		_retangulo(img, Rect2i(int(22 - meia), y, int(meia * 2), 1), 0.76)
	# A pedra negra: superfície curva irregular, de pé, cerca de 1 x 2 pés.
	var n := _noise(49, 0.12)
	for y in range(22, 80):
		for x in range(50, 96):
			var d := Vector2((x - 73.0) / 20.0, (y - 51.0) / 28.0)
			var borda := 1.0 + n.get_noise_2d(x, y) * 0.18
			if d.length() < borda:
				_put(img, x, y, 0.09 + maxf(0.0, -d.x) * 0.18)
	for i in 30:  # hieróglifos meio apagados
		var p := Vector2(rng.randf_range(60, 88), rng.randf_range(32, 72))
		_linha(img, p, p + Vector2(rng.randf_range(-2, 2), rng.randf_range(1, 3)), 0.24, 1.0)
	return _revelar(img, 47)


## Pântanos e colinas "com traços de ocupação escondida e malsã".
func _foto_pantano(seed: int, colina: bool) -> Image:
	var img := _foto(0.74)
	var n := _noise(seed, 0.035)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for x in FW:
		var topo := int((30.0 if colina else 46.0) + n.get_noise_1d(x) * (18.0 if colina else 5.0))
		for y in range(topo, FH):
			_put(img, x, y, 0.3)
	_ruido(img, seed + 1, 0.2, 0.08, Rect2i(0, 30, FW, 66))
	if not colina:
		_retangulo(img, Rect2i(0, 66, FW, 14), 0.42)  # lâmina d'água
		for i in 14:  # árvores mortas
			var x := rng.randf_range(4, 124)
			_linha(img, Vector2(x, 66), Vector2(x + rng.randf_range(-2, 2), rng.randf_range(24, 46)), 0.12, 1.4)
		for i in 50:  # juncos
			var x := rng.randf_range(0, 128)
			_linha(img, Vector2(x, 96), Vector2(x, rng.randf_range(80, 90)), 0.2, 1.0)
	for i in 3:  # marcas que não deviam estar ali
		_garra(img, Vector2(rng.randf_range(30, 100), rng.randf_range(82, 92)), 0.2, 0.18)
	return _revelar(img, seed, 2)


func _foto_marca() -> Image:
	var img := _foto(0.5)
	_ruido(img, 54, 0.1, 0.12)
	_retangulo(img, Rect2i(0, 0, FW, 18), 0.82)  # base da casa, caiada
	_retangulo(img, Rect2i(0, 18, FW, 3), 0.3)
	_garra(img, Vector2(66, 56), 0.9, 0.22)
	return _revelar(img, 54, 3)  # muito borrada


func _foto_casa() -> Image:
	var img := _foto(0.8)
	_retangulo(img, Rect2i(0, 60, FW, 36), 0.52)  # gramado
	_ruido(img, 55, 0.3, 0.07, Rect2i(0, 60, FW, 36))
	for x in range(34, 95):  # telhado de duas águas com sótão
		var h := 14 - absi(x - 64) / 3
		_retangulo(img, Rect2i(x, 20 - h, 1, h + 4), 0.28)
	_retangulo(img, Rect2i(36, 22, 57, 40), 0.9)  # casa branca de dois andares
	_retangulo(img, Rect2i(80, 4, 5, 12), 0.35)  # chaminé
	for fila in 2:
		for col in 5:
			if fila == 1 and col == 2:
				continue
			_retangulo(img, Rect2i(40 + col * 11, 27 + fila * 16, 5, 7), 0.25)
	_retangulo(img, Rect2i(60, 46, 8, 16), 0.2)  # porta georgiana
	_elipse(img, Vector2(64, 46), Vector2(5, 3), 0.55)  # bandeira em leque
	for y in range(62, 96):  # caminho com pedras na borda
		var meia := 4.0 + (y - 62) * 0.35
		_retangulo(img, Rect2i(int(64 - meia), y, int(meia * 2), 1), 0.68)
		if y % 4 == 0:
			_put(img, int(64 - meia) - 1, y, 0.92)
			_put(img, int(64 + meia), y, 0.92)
	_elipse(img, Vector2(14, 40), Vector2(14, 22), 0.2)  # árvores
	_elipse(img, Vector2(116, 44), Vector2(13, 19), 0.22)
	var caes := [Vector2(38, 76), Vector2(48, 82), Vector2(86, 78), Vector2(96, 84), Vector2(76, 86)]
	for c: Vector2 in caes:  # cães policiais enormes
		_elipse(img, c, Vector2(5, 2.5), 0.15)
		_elipse(img, c + Vector2(5, -2), Vector2(2, 2), 0.15)
		_linha(img, c + Vector2(-3, 1), c + Vector2(-3, 4), 0.15, 1.0)
		_linha(img, c + Vector2(3, 1), c + Vector2(3, 4), 0.15, 1.0)
	# Akeley: barba grisalha aparada, a pera do disparador na mão direita.
	_retangulo(img, Rect2i(70, 66, 5, 14), 0.18)
	_elipse(img, Vector2(72.5, 63), Vector2(2.2, 2.6), 0.78)
	_elipse(img, Vector2(72.5, 65), Vector2(1.8, 1.2), 0.6)
	_linha(img, Vector2(75, 72), Vector2(80, 74), 0.1, 1.0)
	_elipse(img, Vector2(80.5, 74), Vector2(1.2, 1.2), 0.1)
	return _revelar(img, 55)


## Julho (cap. III): "um verdadeiro exército de pegadas, em fila, de frente para
## uma linha igualmente cerrada e resoluta de pegadas de cães".
func _foto_exercito() -> Image:
	var img := _foto(0.5)
	_ruido(img, 56, 0.08, 0.14)
	_ruido(img, 57, 0.5, 0.06)
	var rng := RandomNumberGenerator.new()
	rng.seed = 56
	for fila in 2:  # duas filas de garras, à esquerda
		for i in 7:
			var c := Vector2(30 + fila * 12 + rng.randf_range(-2, 2), 12 + i * 12 + rng.randf_range(-2, 2))
			_garra(img, c, 0.28, 0.2)
	for fila in 2:  # duas filas de patas de cão, à direita, de frente
		for i in 8:
			var c := Vector2(86 + fila * 11 + rng.randf_range(-2, 2), 10 + i * 11 + rng.randf_range(-2, 2))
			_elipse(img, c, Vector2(2.6, 3.0), 0.22)
			for d in 4:
				var a := -PI * 0.5 + (d - 1.5) * 0.5
				_elipse(img, c + Vector2(cos(a) * 4.0 - 3.0, sin(a) * 4.0), Vector2(1.1, 1.1), 0.22)
	return _revelar(img, 56)


## Risco de chuva (para partículas): branco translúcido vertical.
func _gota() -> Image:
	var img := _img(4, 16)
	for y in 16:
		for x in 4:
			var a := 0.0
			if x == 1 or x == 2:
				a = 0.55 * sin(PI * y / 15.0)
			img.set_pixel(x, y, Color(0.8, 0.85, 0.95, a))
	return img


# --- Sons --------------------------------------------------------------------

func _sons() -> void:
	_wav(_chuva(), "chuva", true)
	_wav(_relogio(), "relogio", true)
	_wav(_pena(), "pena", false)
	_wav(_tarde(), "tarde", true)
	for i in 3:
		_wav(_passo(40 + i), "passo_madeira_%d" % (i + 1), false)
	# O disco de 1915 (cap. III): os tempos vêm das gravações em narrative/gravacoes.
	_wav(_disco("res://narrative/gravacoes/disco_1915.tres", 60), "disco", false)
	_wav(_disco("res://narrative/gravacoes/disco_1915_longo.tres", 60), "disco_longo", false)
	_wav(_zumbido(), "zumbido", true)
	_wav(_campainha(), "campainha", true)


## Grava WAV 16-bit mono. `loop` escreve o .import com loop ligado.
func _wav(samples: PackedFloat32Array, name: String, loop: bool) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	var path := SFX_DIR + name + ".wav"
	wav.save_to_wav(path)
	var imp := path + ".import"
	if loop and not FileAccess.file_exists(imp):
		var f := FileAccess.open(imp, FileAccess.WRITE)
		f.store_string("[remap]\n\nimporter=\"wav\"\ntype=\"AudioStreamWAV\"\n\n[params]\n\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n")


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Filtro passa-baixa de um polo, no lugar.
func _lowpass(b: PackedFloat32Array, cutoff: float) -> void:
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var y := 0.0
	for i in b.size():
		y += a * (b[i] - y)
		b[i] = y


## Emenda o fim no começo (crossfade) para o loop não estalar.
func _seamless(b: PackedFloat32Array, fade_s: float) -> PackedFloat32Array:
	var f := int(fade_s * RATE)
	var out := b.slice(0, b.size() - f)
	for i in f:
		var t := float(i) / f
		out[i] = out[i] * t + b[b.size() - f + i] * (1.0 - t)
	return out


func _chuva() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 30
	var b := _buf(6.5)
	for i in b.size():
		b[i] = rng.randf_range(-1, 1)
	_lowpass(b, 1800.0)
	var gotas := _buf(6.5)
	for k in 220:
		var at := rng.randi_range(0, gotas.size() - 400)
		var amp := rng.randf_range(0.1, 0.5)
		for j in 300:
			gotas[at + j] += rng.randf_range(-1, 1) * amp * exp(-j / 40.0)
	_lowpass(gotas, 3500.0)
	for i in b.size():
		b[i] = b[i] * 0.5 + gotas[i]
	return _seamless(b, 0.5)


func _clique(b: PackedFloat32Array, at: int, tom: float, amp: float, rng: RandomNumberGenerator) -> void:
	for j in 600:
		var env := exp(-j / 70.0)
		b[at + j] += (sin(TAU * tom * j / RATE) * 0.6 + rng.randf_range(-1, 1) * 0.4) * env * amp


func _relogio() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var b := _buf(2.0)
	_clique(b, 0, 2400.0, 0.35, rng)
	_clique(b, RATE, 1900.0, 0.3, rng)
	return b


func _pena() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 32
	var b := _buf(3.5)
	var hp := 0.0
	var prev := 0.0
	for i in b.size():
		var t := float(i) / RATE
		# Traços: rajadas de atrito com pausas, como letras sendo escritas.
		var traco := maxf(0.0, sin(t * 9.0 + sin(t * 2.3) * 3.0))
		var pausa := 0.0 if fmod(t, 1.1) > 0.85 else 1.0
		var r := rng.randf_range(-1, 1)
		hp = 0.92 * (hp + r - prev)  # passa-alta simples
		prev = r
		b[i] = hp * traco * pausa * 0.35
	var fim := int(0.2 * RATE)
	for i in fim:
		b[b.size() - fim + i] *= 1.0 - float(i) / fim
	return b


func _tarde() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var b := _buf(8.5)
	for i in b.size():
		b[i] = rng.randf_range(-1, 1) * 0.12
	_lowpass(b, 400.0)  # cidade distante
	for k in 9:  # pássaros: varreduras curtas de seno
		var at := rng.randi_range(0, b.size() - RATE)
		var f0 := rng.randf_range(2600, 3600)
		var notas := rng.randi_range(2, 4)
		for nota in notas:
			var start := at + nota * int(0.14 * RATE)
			var dur := int(0.09 * RATE)
			for j in dur:
				var t := float(j) / dur
				var f := f0 + sin(t * PI) * 900.0
				b[start + j] += sin(TAU * f * j / RATE) * sin(t * PI) * 0.08
	return _seamless(b, 0.5)


## Lê inícios, tipos e duração de um .tres de Gravacao sem carregá-lo (o .tres
## aponta para o .wav que ainda vamos gerar).
func _trechos(path: String) -> Dictionary:
	var texto := FileAccess.get_file_as_string(path)
	var achar := func(chave: String) -> PackedStringArray:
		var re := RegEx.create_from_string(chave + r" = \w+\(([^)]*)\)")
		var m := re.search(texto)
		return m.get_string(1).split(",", false) if m else PackedStringArray()
	var re_dur := RegEx.create_from_string(r"duracao = ([0-9.]+)")
	var inicios: Array[float] = []
	for v in achar.call("inicios"):
		inicios.append(v.strip_edges().to_float())
	var tipos: Array[int] = []
	for v in achar.call("tipos"):
		tipos.append(v.strip_edges().to_int())
	return {inicios = inicios, tipos = tipos, duracao = re_dur.search(texto).get_string(1).to_float()}


## Ressonador de dois polos (formante) aplicado a uma amostra.
class Formante:
	var y1 := 0.0
	var y2 := 0.0
	func passar(x: float, freq: float, banda: float) -> float:
		var r := exp(-PI * banda / RATE)
		var a1 := 2.0 * r * cos(TAU * freq / RATE)
		var a2 := -r * r
		var y := x * (1.0 - r) + a1 * y1 + a2 * y2
		y2 = y1
		y1 = y
		return y


## Placeholder do disco: chiado e estalos de cilindro de cera; trechos humanos
## como murmúrio de vogais (pulso glotal + formantes por sílaba); trechos
## zumbidos como serra vibrando em batida de asa. Banda de 300 Hz a 3 kHz.
func _disco(path: String, seed: int) -> PackedFloat32Array:
	var info := _trechos(path)
	var inicios: Array[float] = info.inicios
	var tipos: Array[int] = info.tipos
	var b := _buf(info.duracao)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var vogais := [[700.0, 1200.0], [400.0, 2000.0], [550.0, 900.0], [300.0, 2300.0], [600.0, 1700.0]]
	var f1 := Formante.new()
	var f2 := Formante.new()
	var fase := 0.0
	var silaba := 0.2
	var silaba_t := 0.0
	var vogal: Array = vogais[0]
	var estalo := 0.0
	var k := 0
	for i in b.size():
		var t := float(i) / RATE
		while k + 1 < inicios.size() and inicios[k + 1] <= t:
			k += 1
		var tipo := tipos[k]
		# Chiado e estalos do cilindro, sempre.
		var s := rng.randf_range(-1, 1) * 0.05
		if rng.randf() < 6.0 / RATE:
			estalo = rng.randf_range(0.2, 0.5)
		s += estalo * rng.randf_range(-1, 1)
		estalo *= 0.97
		# Sílabas: troca de vogal e envelope.
		silaba_t += 1.0 / RATE
		if silaba_t >= silaba:
			silaba_t = 0.0
			silaba = rng.randf_range(0.12, 0.26)
			vogal = vogais[rng.randi_range(0, vogais.size() - 1)]
		var env := sin(PI * silaba_t / silaba)
		# Pausa entre frases a cada ~2,5 s.
		if fmod(t - inicios[k], 2.6) > 2.2:
			env = 0.0
		if tipo == 1:  # voz humana, culta
			var f0 := 118.0 + sin(t * 1.3) * 10.0
			fase += f0 / RATE
			var pulso := 1.0 if fmod(fase, 1.0) < 0.08 else 0.0
			var v := f1.passar(pulso, vogal[0], 90.0) + f2.passar(pulso, vogal[1], 140.0) * 0.6
			s += v * env * 0.6
		elif tipo == 2:  # imitação zumbida da fala
			var f0 := 175.0 + sin(t * TAU * 28.0) * 25.0
			fase += f0 / RATE
			var serra := fmod(fase, 1.0) * 2.0 - 1.0
			var v := f1.passar(serra, vogal[0], 160.0) * 0.3 + serra * 0.25
			s += v * (0.35 + 0.65 * env) * (0.7 + 0.3 * sin(t * TAU * 24.0))
		else:  # sons indistinguíveis
			s += rng.randf_range(-1, 1) * 0.12 * (0.5 + 0.5 * sin(t * 3.0))
		b[i] = s
	# Banda estreita de cilindro de cera: passa-alta e passa-baixa simples.
	var hp := 0.0
	var prev := 0.0
	for i in b.size():
		hp = 0.96 * (hp + b[i] - prev)
		prev = b[i]
		b[i] = hp
	_lowpass(b, 3000.0)
	return b


## O zumbido que fica depois do disco: drone grave com batida de inseto.
func _zumbido() -> PackedFloat32Array:
	var b := _buf(10.5)
	var fase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		fase += (55.0 + sin(t * 0.7) * 1.5) / RATE
		var serra := fmod(fase, 1.0) * 2.0 - 1.0
		var asa := 0.75 + 0.25 * sin(t * TAU * 24.0)
		b[i] = (serra * 0.35 + sin(TAU * 110.0 * t) * 0.25) * asa * (0.8 + 0.2 * sin(t * 0.9))
	_lowpass(b, 400.0)
	return _seamless(b, 0.5)


## Campainha de telefone de 1928: duas sinetas batidas por um martelo (~20 Hz),
## dois segundos tocando, três de silêncio (em loop).
func _campainha() -> PackedFloat32Array:
	var b := _buf(5.0)
	for i in int(2.0 * RATE):
		var t := float(i) / RATE
		var golpe := 0.5 + 0.5 * signf(sin(TAU * 20.0 * t))
		var sino := sin(TAU * 1180.0 * t) * 0.5 + sin(TAU * 1460.0 * t) * 0.35 + sin(TAU * 2950.0 * t) * 0.15
		b[i] = sino * (0.4 + 0.6 * golpe) * 0.6 * minf(1.0, (2.0 - t) * 8.0)
	return b


func _passo(seed: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := _buf(0.35)
	for i in b.size():
		var env := exp(-i / 500.0)
		b[i] = (rng.randf_range(-1, 1) * 0.7 + sin(TAU * 90.0 * i / RATE) * 0.6) * env
	_lowpass(b, 900.0)
	# Rangido leve da tábua, às vezes.
	if rng.randf() < 0.6:
		var f := rng.randf_range(300, 500)
		for i in range(1500, 5500):
			b[i] += sin(TAU * f * i / RATE + sin(i * 0.002) * 4.0) * 0.05 * sin(PI * (i - 1500) / 4000.0)
	return b
