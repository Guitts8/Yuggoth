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
	_save(_madeira(Color(0.34, 0.2, 0.12), 11, 0), "madeira_escura")
	_save(_madeira(Color(0.47, 0.32, 0.19), 12, 0), "madeira_clara")
	_save(_porta(), "porta")
	_save(_quadro(), "quadro")
	_save(_diploma(), "diploma")
	_save(_assoalho(), "assoalho")
	_save(_papel_parede(), "papel_parede")
	_save(_reboco(), "reboco")
	_save(_tijolo(), "tijolo")
	_save(_cortica(), "cortica")
	_save(_tapete(), "tapete")
	_save(_tecido(Color(0.24, 0.31, 0.21), 21), "estofado")
	_save(_lencol(), "lencol")
	_save(_papel(), "papel")
	_save(_latao(), "latao")
	_save(_cinzas(), "cinzas")
	_save(_grao(), "grao")
	_save(_papel_pardo(), "papel_pardo")
	_save(_barbante(), "barbante")
	_save(_mostrador(), "mostrador")
	_save(_vista(false), "vista_noite")
	_save(_vista(true), "vista_dia")
	_save(_vista_entardecer(), "vista_entardecer")
	# Boston de noite, da janela da pensão: mais janelas acesas, sem a torre de Arkham.
	_save(_vista_cores(Color(0.03, 0.04, 0.08), Color(0.1, 0.09, 0.12), Color(0.02, 0.02, 0.035), Color(0.015, 0.02, 0.025), false, 0.012, false, 41), "vista_boston")
	_save(_lambri(), "lambri")
	_save(_aco(), "aco")
	_save(_gaveta_arquivo(), "gaveta_arquivo")
	_save(_capa_livro(), "capa_livro")
	_save(_tecido(Color(0.17, 0.16, 0.15), 31), "la_escura")
	_save(_tecido(Color(0.24, 0.2, 0.16), 32), "feltro")
	_save(_cortina(), "cortina")
	_save(_gota(), "gota")
	_save(_chama(), "chama")
	_save(_migo(), "migo")
	# Os sonhos entre os dias (Fase 3b).
	_save(_pegada_garra(), "pegada_garra")
	_save(_vista_circulo(), "vista_circulo")
	_save(_vista_plataforma(), "vista_plataforma")
	_save(_homem_magro(), "homem_magro")
	_save(_pedra_negra(), "pedra_negra")
	_save(_sombra(), "sombra")
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


## Madeira de móvel (Fase 3d: o veio fino, sem as juntas pretas de antes):
## veios verticais finos e ondulados e variação de tom. `junta` > 0 ainda
## desenha a junta entre tábuas a cada N px.
func _madeira(base: Color, seed: int, junta: int, tam := 128) -> Image:
	var img := _img(tam, tam)
	var n := _noise(seed, 0.035)
	var fino := _noise(seed + 100, 0.6)
	for y in tam:
		for x in tam:
			var g := n.get_noise_2d(x * 2.2, y * 0.25)
			# O veio: linhas finas que ondulam com o ruído largo.
			var veio := pow(absf(sin((x + g * 14.0) * 0.9)), 6.0)
			var f := 0.9 + g * 0.1 - veio * 0.12 + fino.get_noise_2d(x * 3.0, y * 0.4) * 0.035
			if junta > 0 and x % junta == 0:
				f *= 0.72
			img.set_pixel(x, y, _shade(base, f))
	return img


func _porta() -> Image:
	var img := _madeira(Color(0.33, 0.2, 0.12), 13, 0, 64)
	# Duas almofadas (painéis) com sombra embaixo/direita e luz em cima/esquerda.
	for r: Rect2i in [Rect2i(10, 6, 44, 22), Rect2i(10, 36, 44, 22)]:
		for x in range(r.position.x, r.end.x):
			_mul(img, x, r.position.y, 1.3)
			_mul(img, x, r.end.y - 1, 0.55)
		for y in range(r.position.y, r.end.y):
			_mul(img, r.position.x, y, 1.25)
			_mul(img, r.end.x - 1, y, 0.6)
	return img


## Paisagem a óleo escurecida pelo verniz (o quadro sobre a lareira, Fase 3d):
## o céu de fim de tarde, morros em camadas, um rio e uma árvore; pinceladas.
func _quadro() -> Image:
	var w := 96
	var h := 64
	var img := _img(w, h)
	var n := _noise(71, 0.08)
	var pincel := _noise(72, 0.35)
	for y in h:
		for x in w:
			var t := float(y) / h
			var c := Color(0.62, 0.52, 0.34).lerp(Color(0.32, 0.36, 0.38), clampf(1.0 - t * 2.2, 0.0, 1.0))
			# Os morros: duas cristas, a de trás mais clara.
			var crista1 := 0.42 + n.get_noise_1d(x * 1.5) * 0.08
			var crista2 := 0.55 + n.get_noise_1d(x * 2.5 + 40.0) * 0.1
			if t > crista1:
				c = Color(0.3, 0.32, 0.24)
			if t > crista2:
				c = Color(0.2, 0.22, 0.14)
			# O rio, uma faixa clara que serpenteia embaixo.
			var rio := 0.8 + sin(x * 0.09) * 0.04
			if absf(t - rio) < 0.025:
				c = Color(0.5, 0.48, 0.38)
			# A árvore à esquerda.
			if x > 14 and x < 30 and t > 0.25 and t < 0.62 and Vector2((x - 22) / 8.0, (t - 0.4) / 0.15).length() < 1.0:
				c = Color(0.16, 0.18, 0.1)
			if x >= 21 and x <= 23 and t >= 0.5 and t < 0.75:
				c = Color(0.14, 0.1, 0.07)
			var f := 0.9 + pincel.get_noise_2d(x * 2.0, y * 0.6) * 0.12
			# O verniz escurece as bordas.
			var borda := minf(minf(x, w - 1 - x) / 14.0, minf(y, h - 1 - y) / 10.0)
			f *= lerpf(0.6, 1.0, clampf(borda, 0.0, 1.0))
			img.set_pixel(x, y, _shade(c, f))
	return img


## Um diploma emoldurado: o papel creme, o título em linhas escuras, as linhas
## do texto e o selo vermelho embaixo.
func _diploma() -> Image:
	var w := 48
	var h := 64
	var img := _img(w, h)
	var n := _noise(73, 0.1)
	for y in h:
		for x in w:
			var f := 0.95 + n.get_noise_2d(x, y) * 0.04
			var c := Color(0.86, 0.82, 0.7)
			if x < 3 or x > w - 4 or y < 3 or y > h - 4:
				c = Color(0.7, 0.62, 0.45)
			elif (y == 10 or y == 11) and x > 8 and x < w - 9:
				c = Color(0.2, 0.17, 0.14)
			elif y > 18 and y < 44 and y % 4 == 0 and x > 7 and x < w - 8 - (y * 7) % 9:
				c = Color(0.45, 0.42, 0.36)
			if Vector2(x - 34, y - 52).length() < 5.0:
				c = Color(0.6, 0.12, 0.1)
			img.set_pixel(x, y, _shade(c, f))
	return img


func _mul(img: Image, x: int, y: int, f: float) -> void:
	img.set_pixel(x, y, _shade(img.get_pixel(x, y), f))


## Assoalho de tábuas estreitas de carvalho (~8 cm com world 0,8), de
## comprimentos diferentes, emendas desencontradas, cada trecho num tom, o veio
## ao longo da tábua; as frestas escuras, mas não pretas.
func _assoalho() -> Image:
	var tam := 128
	var img := _img(tam, tam)
	var n := _noise(14, 0.05)
	var fino := _noise(114, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var base := Color(0.34, 0.23, 0.15)
	var linhas := 16
	var alt := tam / linhas
	for row in linhas:
		# Duas emendas por fileira, em pontos sorteados.
		var e1 := rng.randi_range(0, tam - 1)
		var e2 := posmod(e1 + rng.randi_range(40, 88), tam)
		var tons := [rng.randf_range(0.82, 1.12), rng.randf_range(0.82, 1.12)]
		for y in range(row * alt, row * alt + alt):
			for x in tam:
				var trecho := 0 if posmod(x - e1, tam) < posmod(e2 - e1, tam) else 1
				var g := n.get_noise_2d(x * 0.3 + trecho * 77.0, y * 3.0 + row * 50)
				var veio := pow(absf(sin((y + g * 4.0) * 2.1 + x * 0.02)), 8.0)
				var f: float = tons[trecho] * (0.9 + g * 0.1 - veio * 0.1 + fino.get_noise_2d(x, y * 2.0) * 0.03)
				if y % alt == 0:
					f *= 0.62
				elif x == e1 or x == e2:
					f *= 0.68
				img.set_pixel(x, y, _shade(base, f))
	return img


## Papel de parede de 1920: listras duplas finas e, entre elas, um ornamento de
## folha (um damasco simples) num verde mais escuro, com a impressão gasta.
func _papel_parede() -> Image:
	var tam := 128
	var img := _img(tam, tam)
	var n := _noise(15, 0.04)
	var gasto := _noise(115, 0.15)
	var base := Color(0.33, 0.37, 0.29)
	for y in tam:
		for x in tam:
			var f := 0.96 + n.get_noise_2d(x, y) * 0.05
			var px := x % 32
			if px == 0 or px == 3:
				f *= 1.1
			# A folha em losango, deslocada meia casa a cada fileira.
			var ox := ((x + (16 if (y / 32) % 2 else 0)) % 32) - 16
			var oy := (y % 32) - 16
			var folha := absf(ox) / 9.0 + absf(oy) / 13.0
			if folha < 1.0 and folha > 0.62:
				f *= 0.84
			elif folha <= 0.25:
				f *= 0.88
			elif ox == 0 and absi(oy) < 12:
				f *= 0.92
			# A impressão gasta: o ornamento esmaece aos pedaços.
			f = lerpf(f, 0.96, clampf(gasto.get_noise_2d(x, y) * 1.5, 0.0, 0.6))
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


## Lambri de madeira escura: duas almofadas lado a lado, com travessas em cima e
## embaixo. Uma repetição = 0,9 m (a altura do lambri, com world_uv).
func _lambri() -> Image:
	var img := _madeira(Color(0.3, 0.18, 0.1), 33, 0, 64)
	for y in 64:
		for x in 64:
			var px := x % 32
			var dentro := px >= 4 and px <= 27 and y >= 12 and y <= 55
			if not dentro:
				_mul(img, x, y, 0.82)  # travessas e montantes
			elif px == 4 or y == 12:
				_mul(img, x, y, 0.55)  # sombra da moldura
			elif px == 27 or y == 55:
				_mul(img, x, y, 1.3)  # luz na borda
	return img


## Aço pintado de verde-oliva, gasto nas quinas (arquivo).
func _aco() -> Image:
	var img := _img()
	var n := _noise(34, 0.12)
	var rng := RandomNumberGenerator.new()
	rng.seed = 34
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, _shade(Color(0.27, 0.3, 0.24), 0.93 + n.get_noise_2d(x, y) * 0.07))
	for i in 12:  # riscos
		var p := Vector2i(rng.randi_range(0, 63), rng.randi_range(0, 63))
		for k in rng.randi_range(2, 6):
			img.set_pixel((p.x + k) % 64, p.y, Color(0.42, 0.42, 0.38))
	return img


## Frente de uma gaveta de arquivo: friso, porta-etiqueta de latão com o cartão
## e o puxador. UV 0..1 numa face.
func _gaveta_arquivo() -> Image:
	var img := _aco()
	for x in 64:
		for y in [0, 1, 62, 63]:
			_mul(img, x, y, 0.45)
	for y in 64:
		for x in [0, 1, 62, 63]:
			_mul(img, x, y, 0.45)
	for y in range(14, 24):
		for x in range(20, 44):
			var borda := y == 14 or y == 23 or x == 20 or x == 43
			img.set_pixel(x, y, Color(0.6, 0.46, 0.22) if borda else Color(0.84, 0.8, 0.68))
	for x in range(24, 40):
		img.set_pixel(x, 19, Color(0.3, 0.28, 0.3))  # a etiqueta escrita
	for y in range(32, 40):
		for x in range(22, 42):
			var c := Color(0.62, 0.5, 0.26) if y < 36 else Color(0.3, 0.24, 0.12)
			img.set_pixel(x, y, c)
	return img


## Couro/pano claro de uma lombada, com duas faixas douradas; a cor de vértice
## tinge cada livro. UV 0..1 por face.
func _capa_livro() -> Image:
	var img := _img(16, 64)
	var n := _noise(35, 0.2)
	for y in 64:
		for x in 16:
			var f := 0.9 + n.get_noise_2d(x * 2.0, y) * 0.1
			var c := Color(0.8, 0.8, 0.78)
			if y in [6, 7, 9, 54, 56, 57]:
				c = Color(1.0, 0.86, 0.5)
			elif y >= 20 and y <= 30 and x >= 4 and x <= 11 and (x + y) % 3 != 0:
				c = Color(0.95, 0.84, 0.55)  # título
			img.set_pixel(x, y, _shade(c, f))
	return img


## Veludo vinho, com pregas verticais.
func _cortina() -> Image:
	var img := _img()
	var n := _noise(36, 0.05)
	for y in 64:
		for x in 64:
			var prega := sin(x * TAU / 16.0 + n.get_noise_2d(x, y) * 1.5) * 0.18
			img.set_pixel(x, y, _shade(Color(0.36, 0.11, 0.1), 0.86 + prega))
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


## Grão neutro, quase branco (Fase 3e): para malhas que levam a cor no vértice
## (o bosque do disco, o mi-go) — a textura só dá o ruído, sem riscos.
func _grao() -> Image:
	var img := _img()
	var n := _noise(31, 0.21)
	var fino := _noise(32, 0.9)
	for y in 64:
		for x in 64:
			var v := 0.86 + n.get_noise_2d(x, y) * 0.1 + fino.get_noise_2d(x, y) * 0.06
			img.set_pixel(x, y, Color(v, v, v))
	return img


## Papel pardo de embrulho (o pacote do expresso): fibras compridas e vincos.
func _papel_pardo() -> Image:
	var img := _img()
	var fibra := _noise(26, 0.5)
	var mancha := _noise(27, 0.05)
	for y in 64:
		for x in 64:
			var f := 0.92 + fibra.get_noise_2d(x * 0.3, y * 2.0) * 0.08 + mancha.get_noise_2d(x, y) * 0.07
			# Dois vincos do embrulho.
			if absi(x - 21) < 1 or absi(y - 44) < 1:
				f *= 0.86
			elif x == 22 or y == 45:
				f *= 1.06
			img.set_pixel(x, y, _shade(Color(0.6, 0.45, 0.29), f))
	return img


## Barbante de algodão: fios torcidos em diagonal.
func _barbante() -> Image:
	var img := _img(16, 16)
	for y in 16:
		for x in 16:
			var torcido := 0.85 + 0.15 * sin((x + y) * PI / 2.0)
			img.set_pixel(x, y, _shade(Color(0.8, 0.7, 0.5), torcido))
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


const VW := 256
const VH := 128
## A torre da Miskatonic na vista: centro e largura do fuste, em pixels. A janela,
## vista da cadeira, mostra mais ou menos as colunas 58..198 e as linhas 0..100.
const TORRE_X := 152
const TORRE_L := 14


## Telhados de Arkham com a paleta dada, e a torre gótica da universidade.
## `faces` = fachadas com luz e sombra; `janelas` = chance de cada pixel de
## prédio ser uma janela acesa (e o mostrador da torre aceso).
func _vista_cores(ceu_alto: Color, ceu_baixo: Color, predio: Color, arvore: Color, faces: bool, janelas: float, torre := true, semente := 27) -> Image:
	var img := _img(VW, VH)
	var n := _noise(semente, 0.015)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	# Perfil de telhados: casas de duas águas e de mansarda, com chaminés.
	var alturas := PackedInt32Array()
	alturas.resize(VW)
	var x := 0
	while x < VW:
		var w := rng.randi_range(18, 40)
		var h := rng.randi_range(36, 68)
		var mansarda := rng.randf() < 0.35
		var chamine := rng.randi_range(3, w - 6)
		for i in w:
			if x + i < VW:
				var meio := mini(i, w - 1 - i)
				var telhado := mini(meio, 6) * 2 if mansarda else meio * 2 / 3
				alturas[x + i] = h + telhado
				if i >= chamine and i < chamine + 3:
					alturas[x + i] += 7
		x += w
	for yy in VH:
		for xx in VW:
			var c := ceu_alto.lerp(ceu_baixo, yy / float(VH - 1))
			var copa := 28 + int(n.get_noise_1d(xx * 3.0) * 16.0)
			if yy > VH - copa:
				c = _shade(arvore, 0.9 + n.get_noise_2d(xx * 4.0, yy * 4.0) * 0.2)
			if yy > VH - alturas[xx]:
				c = predio
				if faces:
					c = _shade(predio, 1.1 if xx % 14 < 8 else 0.9)
				if rng.randf() < janelas:
					c = Color(0.55, 0.42, 0.18)  # janela acesa
			img.set_pixel(xx, yy, c)
	if torre:
		_torre(img, predio, faces, janelas > 0.0)
	return img


## A torre gótica da Miskatonic: fuste com contrafortes, campanário com mostrador
## e janela ogival, pináculos nos cantos e a agulha.
func _torre(img: Image, cor: Color, faces: bool, acesa: bool) -> void:
	var meia := TORRE_L / 2
	var topo_fuste := 44
	var luz := func(px: int) -> Color:
		if not faces:
			return cor
		return _shade(cor, 1.12 if px < TORRE_X else 0.86)
	# Fuste, alargando para os contrafortes embaixo.
	for yy in range(topo_fuste, VH):
		var larg := meia + (2 if yy > 80 else 0)
		for xx in range(TORRE_X - larg, TORRE_X + larg):
			img.set_pixel(xx, yy, luz.call(xx))
	# Cornija do campanário.
	for xx in range(TORRE_X - meia - 1, TORRE_X + meia + 1):
		img.set_pixel(xx, topo_fuste, _shade(cor, 0.7))
	# Mostrador (aceso à noite) e janela ogival embaixo dele.
	var centro := Vector2(TORRE_X - 0.5, 52.5)
	for yy in range(48, 58):
		for xx in range(TORRE_X - 5, TORRE_X + 5):
			var d := Vector2(xx, yy).distance_to(centro)
			if d < 4.2:
				img.set_pixel(xx, yy, Color(0.85, 0.72, 0.4) if acesa else _shade(cor, 1.35 if faces else 1.2))
			elif d < 5.0:
				img.set_pixel(xx, yy, _shade(cor, 0.6))
	for yy in range(62, 76):
		var meia_janela := 2 if yy > 64 else (1 if yy > 62 else 0)
		for xx in range(TORRE_X - meia_janela, TORRE_X + meia_janela):
			img.set_pixel(xx, yy, Color(0.4, 0.3, 0.14) if acesa else _shade(cor, 0.55))
	# Pináculos nos cantos.
	for s in [-1, 1]:
		var px: int = TORRE_X + s * meia - (1 if s > 0 else 0)
		for yy in range(30, topo_fuste):
			var w := 1 if yy < 36 else 2
			for k in w:
				img.set_pixel(px - s * k, yy, luz.call(px))
	# Agulha, afinando até o remate.
	for yy in range(8, topo_fuste):
		var meia_agulha := int(round((yy - 8) / float(topo_fuste - 8) * (meia - 2)))
		for xx in range(TORRE_X - meia_agulha - 1, TORRE_X + meia_agulha + 1):
			img.set_pixel(xx, yy, luz.call(xx))
	for yy in range(3, 8):
		img.set_pixel(TORRE_X - 1, yy, cor)


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


## O vulto que passa pela janela no Dia 5: corpo curvado, membros finos e uma
## asa de morcego meio aberta, borrados pela chuva. Fora do contorno, alfa 0
## (o shader descarta); a forma nunca é nítida o bastante para se confirmar.
func _sombra() -> Image:
	var img := _img(32, 48)
	var n := _noise(61, 0.18)
	var corpo := func(x: float, y: float) -> float:
		var d := Vector2((x - 15.0) / 7.5, (y - 28.0) / 13.0).length()
		# Asa: um leque saindo do alto das costas, para a esquerda.
		var a := Vector2(x - 13.0, y - 20.0)
		var asa := 1.0 if a.x < 0 and a.length() < 15.0 and absf(a.angle() + PI * 0.75) < 0.45 else 0.0
		# Membros: riscos finos para baixo e para a frente.
		var membro := 0.0
		for k in 3:
			var x0 := 12.0 + k * 4.0
			if y > 36 and absf(x - (x0 + (y - 36) * (0.35 * (k - 1)))) < 0.9:
				membro = 1.0
		return maxf(maxf(1.0 - d, 0.0) * 3.0, maxf(asa, membro))
	for y in 48:
		for x in 32:
			var v: float = corpo.call(float(x), float(y)) + n.get_noise_2d(x, y) * 0.45
			var c := Color(0.32, 0.25, 0.26).lerp(Color(0.42, 0.3, 0.3), n.get_noise_2d(x * 3.0, y * 3.0) * 0.5 + 0.5)
			c.a = 1.0 if v > 0.55 else 0.0
			img.set_pixel(x, y, c)
	return img


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
	_wav(_tarde(false), "dia_quieto", true)
	_wav(_noite(), "noite", true)
	for i in 3:
		_wav(_passo(40 + i), "passo_madeira_%d" % (i + 1), false)
	# O disco de 1915 (cap. III): os tempos vêm das gravações em narrative/gravacoes.
	_wav(_disco("res://narrative/gravacoes/disco_1915.tres", 60), "disco", false)
	_wav(_disco("res://narrative/gravacoes/disco_1915_longo.tres", 60), "disco_longo", false)
	_wav(_zumbido(), "zumbido", true)
	_wav(_campainha(), "campainha", true)
	# O correio (Escritório v2, Fase 3): pela fresta, na mão, aberto.
	_wav(_fresta(), "correio_fresta", false)
	_wav(_pacote(), "pacote_chao", false)
	_wav(_papel_mao(50), "papel_pegar", false)
	_wav(_rasgo(), "papel_rasgando", false)
	_wav(_selo_batido(), "selo_batido", false)
	# O telefone (Dia 4): gancho, manivela, a linha e um murmúrio de voz.
	_wav(_gancho(), "telefone_gancho", false)
	_wav(_manivela(), "telefone_manivela", false)
	_wav(_linha_telefone(), "telefone_linha", true)
	_wav(_voz_telefone(), "telefone_voz", true)
	# A mesma voz sem palavras, em pessoa (sem a banda do telefone).
	_wav(_voz_telefone(false), "voz_sala", true)
	# A lareira (noites dos Dias 5 e 6).
	_wav(_fosforo(), "fosforo", false)
	_wav(_lareira(), "lareira", true)
	_wav(_sonho_drone(), "sonho", true)
	# Boston: bater à porta da pensão, a porta que abre uma fresta.
	_wav(_batidas(), "batidas_porta", false)
	_wav(_rangido(), "porta_rangendo", false)
	# A calha de correio no corredor (Fase 3d) e a porta do escritório fechando.
	_wav(_calha(), "calha_correio", false)
	_wav(_trinco(), "porta_trinco", false)
	# O café e o uísque antes do diário (Fase 3d).
	_wav(_servir(), "servir", false)
	_wav(_gaveta(), "gaveta", false)
	# A marca de lama que se forma no chão, no sonho da noite 2 (Fase 3f).
	_wav(_lama(), "lama", false)


## Uma marca de lama se formando no chão: um estalo úmido e baixo, e bolhas.
func _lama() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	var b := _buf(0.7)
	for i in b.size():
		var t := float(i) / RATE
		var env := exp(-t * 8.0) * minf(1.0, t * 150.0)
		var tom := sin(TAU * (150.0 - 80.0 * t) * t) * 0.5
		b[i] = (rng.randf_range(-1, 1) * 0.6 + tom) * env * 0.7
	_lowpass(b, 800.0)
	for k in 4:
		_clique(b, int(rng.randf_range(0.06, 0.4) * RATE), rng.randf_range(400.0, 800.0), 0.1, rng)
	return b


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


## Cidade distante; com `passaros`, o canto da tarde tranquila (só o Dia 1).
## Pássaros nunca à noite nem em dia tenso: o padrão do escritório é sem eles.
func _tarde(passaros := true) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var b := _buf(16.0)
	for i in b.size():
		b[i] = rng.randf_range(-1, 1) * 0.12
	_lowpass(b, 400.0)  # cidade distante
	# Pássaros: poucos e longe (varreduras curtas de seno), não um bando na janela.
	for k in (4 if passaros else 0):
		var at := rng.randi_range(0, b.size() - RATE)
		var f0 := rng.randf_range(2400, 3200)
		var notas := rng.randi_range(2, 4)
		for nota in notas:
			var start := at + nota * int(0.14 * RATE)
			var dur := int(0.09 * RATE)
			for j in dur:
				var t := float(j) / dur
				var f := f0 + sin(t * PI) * 900.0
				b[start + j] += sin(TAU * f * j / RATE) * sin(t * PI) * 0.04
	return _seamless(b, 0.5)


## Noite no escritório: quase silêncio, o prédio assentando e um vento fraco
## que sobe e desce lá fora. Nenhum bicho.
func _noite() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 34
	var b := _buf(12.0)
	for i in b.size():
		b[i] = rng.randf_range(-1, 1) * 0.05
	_lowpass(b, 180.0)
	var vento := _buf(12.0)
	for i in vento.size():
		vento[i] = rng.randf_range(-1, 1)
	_lowpass(vento, 500.0)
	for i in b.size():
		var t := float(i) / RATE
		var rajada := maxf(0.0, sin(t * TAU / 12.0 * 2.0 + 0.6) * 0.6 + sin(t * TAU / 12.0 * 3.0) * 0.4)
		b[i] += vento[i] * rajada * 0.07
	return _seamless(b, 1.0)


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


## Atrito de papel: ruído com passa-alta, para os sons do correio.
func _atrito(b: PackedFloat32Array, de: int, ate: int, amp: Callable, rng: RandomNumberGenerator) -> void:
	var hp := 0.0
	var prev := 0.0
	for i in range(de, mini(ate, b.size())):
		var r := rng.randf_range(-1, 1)
		hp = 0.85 * (hp + r - prev)
		prev = r
		b[i] += hp * amp.call(float(i - de) / (ate - de))


## Um envelope empurrado por baixo da porta: arrasta na soleira e bate de leve no chão.
func _fresta() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	var b := _buf(1.1)
	_atrito(b, 0, int(0.55 * RATE), func(t: float) -> float: return 0.3 * sin(PI * t) * (0.7 + 0.3 * sin(t * 40.0)), rng)
	var tapa := int(0.62 * RATE)
	for j in 2500:
		b[tapa + j] += rng.randf_range(-1, 1) * 0.45 * exp(-j / 260.0)
	_lowpass(b, 5000.0)
	return b


## Um pacote pousado no chão do corredor: baque surdo e o papelão rangendo.
func _pacote() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 48
	var b := _buf(0.8)
	for i in b.size():
		var env := exp(-i / 900.0)
		b[i] = (rng.randf_range(-1, 1) * 0.6 + sin(TAU * 70.0 * i / RATE) * 0.8) * env
	_lowpass(b, 600.0)
	_atrito(b, int(0.08 * RATE), int(0.45 * RATE), func(t: float) -> float: return 0.06 * (1.0 - t), rng)
	return b


## Papel na mão (pegar, pousar, tirar uma fotografia do envelope).
func _papel_mao(seed: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := _buf(0.4)
	_atrito(b, 0, b.size(), func(t: float) -> float: return 0.22 * sin(PI * t) * (0.5 + 0.5 * absf(sin(t * 23.0))), rng)
	_lowpass(b, 6000.0)
	return b


## A espátula correndo pela dobra do envelope: rasgos curtos, irregulares.
func _rasgo() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 49
	var b := _buf(0.9)
	# Uma fibra cedendo a cada ~20 ms: umas estalam, outras só arrastam.
	var fibras := PackedFloat32Array()
	for k in 40:
		fibras.append(1.0 if rng.randf() > 0.6 else 0.35)
	_atrito(b, int(0.05 * RATE), int(0.8 * RATE), func(t: float) -> float:
		return 0.38 * minf(1.0, t * 12.0) * (1.0 - t * 0.5) * fibras[mini(int(t * 40.0), 39)], rng)
	return b


## O selo colado com a palma da mão sobre o envelope, na mesa: um tapa abafado.
func _selo_batido() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	var b := _buf(0.45)
	for i in b.size():
		var env := exp(-i / 450.0)
		b[i] = (rng.randf_range(-1, 1) * 0.8 + sin(TAU * 120.0 * i / RATE) * 0.5) * env * 0.8
	_lowpass(b, 1400.0)
	_atrito(b, int(0.02 * RATE), int(0.2 * RATE), func(t: float) -> float: return 0.05 * (1.0 - t), rng)
	return b


## Passa-alta de um polo, no lugar (o que sobra tirando o grave).
func _highpass(b: PackedFloat32Array, cutoff: float) -> void:
	var grave := b.duplicate()
	_lowpass(grave, cutoff)
	for i in b.size():
		b[i] -= grave[i]


## Ressonador de dois polos (um formante), da entrada para a saída.
func _ressoar(x: PackedFloat32Array, out: PackedFloat32Array, de: int, ate: int, freq: float, banda: float, ganho: float) -> void:
	var r := exp(-PI * banda / RATE)
	var a1 := 2.0 * r * cos(TAU * freq / RATE)
	var a2 := -r * r
	var y1 := 0.0
	var y2 := 0.0
	for i in range(de, ate):
		var y := (1.0 - r) * x[i] + a1 * y1 + a2 * y2
		y2 = y1
		y1 = y
		out[i] += y * ganho


## O fone saindo e voltando ao gancho: dois estalos metálicos.
func _gancho() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 52
	var b := _buf(0.3)
	_clique(b, 0, 1700.0, 0.5, rng)
	_clique(b, int(0.09 * RATE), 2300.0, 0.3, rng)
	return b


## A manivela do magneto chamando a telefonista: o zumbido do dínamo e as
## sinetas batendo junto.
func _manivela() -> PackedFloat32Array:
	var b := _buf(1.3)
	for i in b.size():
		var t := float(i) / RATE
		var volta := 0.5 + 0.5 * sin(TAU * 3.0 * t)  # a mão girando
		var dinamo := signf(sin(TAU * 18.0 * (1.0 + 0.2 * volta) * t)) * 0.15
		var sino := (sin(TAU * 1180.0 * t) * 0.5 + sin(TAU * 1460.0 * t) * 0.3) * (0.5 + 0.5 * signf(sin(TAU * 18.0 * t)))
		b[i] = (dinamo + sino * 0.35) * volta * minf(1.0, (1.3 - t) * 6.0) * minf(1.0, t * 20.0)
	_lowpass(b, 4000.0)
	return b


## A linha interurbana de 1928: chiado na banda do telefone, estalos de vez em quando.
func _linha_telefone() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	var b := _buf(5.0)
	for i in b.size():
		b[i] = rng.randf_range(-1, 1) * 0.12
	for k in 40:
		var at := rng.randi_range(0, b.size() - 300)
		var amp := rng.randf_range(0.1, 0.45)
		for j in 200:
			b[at + j] += rng.randf_range(-1, 1) * amp * exp(-j / 30.0)
	# Um zumbido elétrico baixo da rede.
	for i in b.size():
		b[i] += sin(TAU * 60.0 * i / RATE) * 0.03
	_highpass(b, 300.0)
	_lowpass(b, 3000.0)
	return _seamless(b, 0.3)


## Uma voz ao longe, sem palavra nenhuma (a legenda diz o que é dito), tocada com
## o tom de quem fala. De propósito diferente das vozes do disco (que precisam
## impactar): soprada e abafada — quase só ar nos formantes, um fio de tom acima
## do da voz do disco, sílabas curtas e apressadas; na linha, o chiado e a
## saturação do microfone de carvão.
func _voz_telefone(na_linha := true) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 54
	var b := _buf(6.0)
	var excita := PackedFloat32Array()
	excita.resize(b.size())
	var fase := 0.0
	var tom := 0.18 if na_linha else 0.3
	for i in b.size():
		var t := float(i) / RATE
		var f0 := 165.0 + sin(t * 2.3) * 18.0
		fase += f0 / RATE
		excita[i] = rng.randf_range(-1, 1) * (1.0 - tom) + sin(TAU * fase) * tom
	const VOGAIS := [Vector2(800, 1250), Vector2(500, 1700), Vector2(380, 2100), Vector2(620, 1000)]
	var i := 0
	while i < b.size():
		var dur := int(rng.randf_range(0.07, 0.15) * RATE)
		var fim := mini(i + dur, b.size())
		var v: Vector2 = VOGAIS[rng.randi_range(0, VOGAIS.size() - 1)]
		_ressoar(excita, b, i, fim, v.x, 260.0, 1.0)
		_ressoar(excita, b, i, fim, v.y, 320.0, 0.8)
		for j in range(i, fim):
			b[j] *= pow(sin(PI * float(j - i) / (fim - i)), 0.6)
		i = fim
		# Pausas mais longas entre os grupos de sílabas.
		if rng.randf() < 0.35:
			i += int(rng.randf_range(0.12, 0.4) * RATE)
	_highpass(b, 450.0 if na_linha else 140.0)
	_lowpass(b, 2400.0 if na_linha else 3800.0)
	var pico := 0.0
	for s in b:
		pico = maxf(pico, absf(s))
	for k in b.size():
		var s := b[k] / maxf(pico, 0.001)
		if na_linha:
			# Carvão: satura e chia.
			s = tanh(s * 2.5) * 0.8 + rng.randf_range(-1, 1) * 0.05
		b[k] = clampf(s, -1.0, 1.0) * 0.45
	return _seamless(b, 0.2)

## O fósforo riscado e a lenha pegando: atrito curto, depois o sopro do fogo.
func _fosforo() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	var b := _buf(1.6)
	_atrito(b, 0, int(0.14 * RATE), func(t: float) -> float: return 0.5 * sin(PI * t), rng)
	var sopro := _buf(1.6)
	for i in range(int(0.12 * RATE), sopro.size()):
		var t := float(i) / RATE - 0.12
		sopro[i] = rng.randf_range(-1, 1) * minf(1.0, t * 3.0) * exp(-maxf(0.0, t - 0.5) * 2.0) * 0.5
	_lowpass(sopro, 500.0)
	for i in b.size():
		b[i] += sopro[i]
	return b


## Três batidas com os nós dos dedos numa porta de madeira.
func _batidas() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 59
	var b := _buf(1.2)
	for k in 3:
		var at := int((0.05 + k * 0.26 + (0.04 if k == 2 else 0.0)) * RATE)
		for j in 2600:
			var env := exp(-j / 260.0)
			b[at + j] += (sin(TAU * 140.0 * j / RATE) * 0.7 + rng.randf_range(-1, 1) * 0.5) * env * 0.8
	_lowpass(b, 1800.0)
	return b



## A carta na calha de correio: a tampinha de latão da boca, e o papel que
## escorrega tubo abaixo, cada vez mais longe e mais abafado.
func _calha() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	var b := _buf(1.9)
	var tinido := _buf(1.9)
	for j in int(0.02 * RATE):
		tinido[j] = rng.randf_range(-1, 1) * exp(-j / 60.0)
	_ressoar(tinido, b, 0, int(0.5 * RATE), 2300.0, 40.0, 1.6)
	_ressoar(tinido, b, 0, int(0.5 * RATE), 3650.0, 60.0, 0.9)
	var desce := _buf(1.9)
	_atrito(desce, int(0.12 * RATE), int(1.8 * RATE), func(t: float) -> float:
		return 0.32 * exp(-t * 2.8) * (0.55 + 0.45 * absf(sin(t * 26.0))), rng)
	# O tubo de metal dá corpo ao papel; e o longe abafa.
	_ressoar(desce, b, 0, desce.size(), 900.0, 120.0, 2.2)
	for i in b.size():
		b[i] += desce[i] * 0.5
	_lowpass(b, 5200.0)
	return b


## Líquido servido: o jorro (ruído filtrado que borbulha) enchendo devagar —
## o tom sobe à medida que o recipiente enche.
func _servir() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 63
	var b := _buf(1.5)
	var jorro := _buf(1.5)
	for i in jorro.size():
		var t := float(i) / jorro.size()
		var env := minf(t * 12.0, 1.0) * minf((1.0 - t) * 8.0, 1.0)
		jorro[i] = rng.randf_range(-1, 1) * env * (0.6 + 0.4 * absf(sin(t * 90.0)))
	for k in 4:
		var de := int(k * 0.35 * RATE)
		_ressoar(jorro, b, de, mini(de + int(0.4 * RATE), b.size()), 420.0 + k * 160.0, 90.0, 1.4)
	_lowpass(b, 3000.0)
	return b


## Uma gaveta de madeira correndo, e o baque no fim.
func _gaveta() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	var b := _buf(0.7)
	var fim := int(0.45 * RATE)
	for i in fim:
		var t := float(i) / fim
		b[i] += rng.randf_range(-1, 1) * 0.25 * sin(PI * t) * (0.7 + 0.3 * sin(t * 60.0))
	_lowpass(b, 700.0)
	for j in int(0.2 * RATE):
		b[fim + j] += (rng.randf_range(-1, 1) * 0.4 + sin(TAU * 110.0 * j / RATE) * 0.6) * exp(-j / 500.0)
	_lowpass(b, 1500.0)
	return b


## A porta fechando: o baque da folha no batente e o trinco.
func _trinco() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 62
	var b := _buf(0.6)
	for i in int(0.4 * RATE):
		b[i] += (rng.randf_range(-1, 1) * 0.5 + sin(TAU * 85.0 * i / RATE) * 0.9) * exp(-i / 700.0)
	_lowpass(b, 900.0)
	_clique(b, int(0.03 * RATE), 1800.0, 0.35, rng)
	_clique(b, int(0.09 * RATE), 2400.0, 0.2, rng)
	return b

## Uma porta velha abrindo devagar: um rangido que sobe e cai, com o trinco antes.
func _rangido() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 60
	var b := _buf(1.6)
	_clique(b, 0, 1500.0, 0.4, rng)
	var fase := 0.0
	for i in range(int(0.25 * RATE), int(1.5 * RATE)):
		var t := float(i) / RATE - 0.25
		var f := 330.0 + sin(t * 2.4) * 120.0 + sin(t * 17.0) * 15.0
		fase += f / RATE
		var dente := fmod(fase, 1.0) * 2.0 - 1.0
		var env := sin(PI * t / 1.25) * (0.6 + 0.4 * absf(sin(t * 9.0)))
		b[i] += (dente * 0.3 + rng.randf_range(-1, 1) * 0.08) * env
	_lowpass(b, 2500.0)
	return b


## O fundo dos sonhos: um grave que bate devagar (duas notas quase iguais) e um
## sopro que vem e vai.
func _sonho_drone() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 58
	var b := _buf(12.0)
	var sopro := _buf(12.0)
	for i in sopro.size():
		sopro[i] = rng.randf_range(-1, 1)
	_lowpass(sopro, 300.0)
	for i in b.size():
		var t := float(i) / RATE
		var grave := sin(TAU * 55.0 * t) * 0.3 + sin(TAU * 58.2 * t) * 0.3 + sin(TAU * 110.4 * t) * 0.08
		b[i] = grave + sopro[i] * 2.5 * (0.5 + 0.5 * sin(TAU * t / 6.0))
	return _seamless(b, 1.0)


## Lenha queimando: o ronco grave das chamas e estalos soltos.
func _lareira() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 56
	var b := _buf(8.0)
	for i in b.size():
		b[i] = rng.randf_range(-1, 1)
	_lowpass(b, 160.0)
	for i in b.size():
		b[i] *= 2.2
	var estalos := _buf(8.0)
	for k in 70:
		var at := rng.randi_range(0, estalos.size() - 900)
		var amp := rng.randf_range(0.08, 0.5) if rng.randf() < 0.85 else rng.randf_range(0.6, 0.9)
		var dec := rng.randf_range(15.0, 60.0)
		for j in 800:
			estalos[at + j] += rng.randf_range(-1, 1) * amp * exp(-j / dec)
	_lowpass(estalos, 5000.0)
	for i in b.size():
		b[i] = b[i] * 0.5 + estalos[i]
	return _seamless(b, 0.4)


## Silhueta de longe de uma das criaturas voando (livro: corpo de crustáceo,
## asas membranosas, a cabeça um elipsoide de anéis em vez de rosto). Contra o
## céu da janela, só a forma: um cinza-violáceo escuro, um pouco acima do céu.
func _migo() -> Image:
	var img := _img(48, 32)
	var cor := Color(0.14, 0.125, 0.15)
	var pinta := func(x: float, y: float) -> void:
		if x >= 0 and y >= 0 and x < 48 and y < 32:
			img.set_pixel(int(x), int(y), cor)
	var risco := func(a: Vector2, b: Vector2) -> void:
		for k in 24:
			var p := a.lerp(b, k / 23.0)
			pinta.call(p.x, p.y)
	# Corpo de crustáceo: segmentos que afinam para trás, caídos.
	for k in 6:
		var c := Vector2(24.0 - k * 2.6, 16.0 + k * 1.3)
		var r := Vector2(2.6 - k * 0.3, 1.8 - k * 0.2)
		for y in 32:
			for x in 48:
				if Vector2((x - c.x) / r.x, (y - c.y) / r.y).length() < 1.0:
					pinta.call(x, y)
	# A "cabeça": um elipsoide de dobras, com antenas curtas eriçadas.
	for y in 32:
		for x in 48:
			if Vector2((x - 29.0) / 2.4, (y - 14.0) / 2.0).length() < 1.0 and (x + y) % 3 != 0:
				pinta.call(x, y)
	for k in 5:
		risco.call(Vector2(29.5 + k * 0.5, 12.5), Vector2(30.0 + k * 1.2, 10.0 - (k % 2)))
	# Asas largas e esfarrapadas, com nervuras, abertas para cima.
	var ombro := Vector2(23, 14)
	for asa: Array in [[Vector2(3, 3), Vector2(13, 0)], [Vector2(40, 1), Vector2(31, 0)]]:
		var a: Vector2 = asa[0]
		var b: Vector2 = asa[1]
		for y in 32:
			for x in 48:
				var p := Vector2(x, y)
				# Dentro do triângulo ombro-a-b (coordenadas baricêntricas).
				var v0 := b - ombro
				var v1 := a - ombro
				var v2 := p - ombro
				var den := v0.x * v1.y - v1.x * v0.y
				var u := (v2.x * v1.y - v1.x * v2.y) / den
				var w := (v0.x * v2.y - v2.x * v0.y) / den
				if u >= 0 and w >= 0 and u + w <= 1.0 and not (u + w > 0.8 and (x * 7 + y * 3) % 4 == 0):
					pinta.call(x, y)
		risco.call(ombro, a)
		risco.call(ombro, (a + b) * 0.5)
	# Pernas compridas pendendo, articuladas; as da frente com pinças.
	for k in 4:
		var base := Vector2(21.0 + k * 2.0, 17.0)
		var joelho := base + Vector2(-1.0 + k * 0.6, 6.0)
		risco.call(base, joelho)
		risco.call(joelho, joelho + Vector2(1.5 + k * 0.4, 6.0 - k))
	for k in 2:
		var base := Vector2(28.0, 16.0 + k)
		var ponta := base + Vector2(9.0, 4.0 + k * 3.0)
		risco.call(base, ponta)
		risco.call(ponta, ponta + Vector2(1.5, -2.0))
		risco.call(ponta, ponta + Vector2(2.0, 1.0))
	return img

## Pinta com `cor` os pixels de `img` onde `dentro(x, y)` vale.
func _pintar(img: Image, cor: Color, dentro: Callable) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if dentro.call(float(x), float(y)):
				img.set_pixel(x, y, cor)


## Distância de p ao segmento a-b.
static func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a.lerp(b, t))


## A marca de garra na lama (livro, cap. II: "de uma almofada central, pares de
## pinças serrilhadas se projetavam em direções opostas"). Topo da marca para -Y.
## Fresca e úmida (playtest 5: "as pegadas pouco visíveis"): a lama escura, a
## borda molhada que brilha à luz fria, e respingos em volta.
func _pegada_garra() -> Image:
	var img := _img(64, 64)
	img.fill(Color(0, 0, 0, 0))
	var c := 31.5
	var marca := func(x: float, y: float) -> bool:
		var p := Vector2(x, y)
		if Vector2((x - c) / 9.0, (y - c) / 7.2).length() < 1.0:
			return true
		for lado in [-1.0, 1.0]:
			for k in [-1.0, 1.0]:
				var a := Vector2(c + lado * 7.0, c + k * 4.0)
				var b := Vector2(c + lado * 28.0, c + k * 13.0)
				if _dist_seg(p, a, b) < 2.4:
					return true
				# Os dentes da serra, para dentro.
				for t in range(1, 5):
					var d := a.lerp(b, t / 5.0)
					if _dist_seg(p, d, d + Vector2(0, -k * 4.4)) < 1.3:
						return true
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	var respingos: Array[Vector3] = []
	for i in 14:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(12.0, 30.0)
		respingos.append(Vector3(c + cos(ang) * r, c + sin(ang) * r * 0.7, rng.randf_range(0.8, 2.0)))
	var dentro := func(x: float, y: float) -> bool:
		if marca.call(x, y):
			return true
		for s in respingos:
			if Vector2(x - s.x, y - s.y).length() < s.z:
				return true
		return false
	var lama := Color(0.06, 0.045, 0.035)
	var molhada := Color(0.5, 0.52, 0.55)
	for y in 64:
		for x in 64:
			if not dentro.call(x + 0.5, y + 0.5):
				continue
			# A borda de cima e da esquerda (onde a luz bate) brilha, molhada.
			var borda: bool = not dentro.call(x - 0.5, y - 0.5) or not dentro.call(x + 0.5, y - 1.5)
			img.set_pixel(x, y, molhada if borda else lama)
	return img


## Céu de noite em gradiente (para as vistas dos sonhos).
func _ceu(img: Image, alto: Color, baixo: Color) -> void:
	for y in img.get_height():
		var c := alto.lerp(baixo, y / float(img.get_height() - 1))
		for x in img.get_width():
			img.set_pixel(x, y, c)


## Sonho da noite do Dia 2: um morro selvagem e, no alto, o círculo de pedras de pé.
func _vista_circulo() -> Image:
	var img := _img(VW, VH)
	_ceu(img, Color(0.03, 0.04, 0.08), Color(0.08, 0.09, 0.12))
	var morro := func(x: float) -> float: return 72.0 - 30.0 * exp(-pow((x - 140.0) / 60.0, 2.0))
	_pintar(img, Color(0.02, 0.025, 0.025), func(x: float, y: float) -> bool: return y > morro.call(x))
	for i in 9:
		var x := 112.0 + i * 7.0
		var topo: float = morro.call(x) - 7.0 - float(i % 3) * 2.0
		_pintar(img, Color(0.17, 0.17, 0.19), func(px: float, py: float) -> bool:
			return px >= x and px < x + 3.0 and py >= topo and py < morro.call(x) + 1.0)
	return img


## Sonho da noite do Dia 4: a plataforma de Keene à noite, um poste de luz e o
## trem parado com as janelas acesas.
func _vista_plataforma() -> Image:
	var img := _img(VW, VH)
	_ceu(img, Color(0.02, 0.025, 0.05), Color(0.06, 0.06, 0.08))
	# O trem: um vagão comprido, com a fileira de janelas acesas.
	_pintar(img, Color(0.03, 0.03, 0.035), func(x: float, y: float) -> bool: return x > 30 and y > 46 and y < 96)
	_pintar(img, Color(0.5, 0.38, 0.16), func(x: float, y: float) -> bool:
		return x > 34 and y > 56 and y < 70 and int(x) % 22 < 13)
	# A plataforma, e o poste com a sua auréola.
	_pintar(img, Color(0.07, 0.065, 0.06), func(x: float, y: float) -> bool: return y >= 96)
	_pintar(img, Color(0.05, 0.05, 0.05), func(x: float, y: float) -> bool: return absf(x - 200.0) < 1.5 and y > 30 and y < 96)
	for y in VH:
		for x in VW:
			var d := Vector2(x - 200.0, y - 30.0).length()
			if d < 16.0:
				var c := img.get_pixel(x, y).lerp(Color(0.9, 0.75, 0.45), (1.0 - d / 16.0) * 0.8)
				img.set_pixel(x, y, c)
	return img


## O homem magro de costas, na plataforma: casaco escuro, cabelo cor de areia.
func _homem_magro() -> Image:
	var img := _img(16, 40)
	img.fill(Color(0, 0, 0, 0))
	_pintar(img, Color(0.05, 0.045, 0.045), func(x: float, y: float) -> bool:
		var meia := 3.2 if y > 9 else 0.0
		if y > 9 and y < 37:
			meia = 3.6 - (y - 9) * 0.03
		return y > 9 and y < 38 and absf(x - 7.5) < meia and not (y > 30 and absf(x - 7.5) < 0.6))
	_pintar(img, Color(0.5, 0.38, 0.22), func(x: float, y: float) -> bool:
		return Vector2((x - 7.5) / 2.3, (y - 6.0) / 3.2).length() < 1.0)
	return img


## A pedra negra de Round Hill: quase preta, com hieróglifos rasos que pegam luz.
func _pedra_negra() -> Image:
	var img := _img()
	var n := _noise(64, 0.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	for y in 64:
		for x in 64:
			var v := 0.06 + n.get_noise_2d(x, y) * 0.03
			img.set_pixel(x, y, Color(v, v, v * 1.05))
	for fila in 6:
		var x := 4
		while x < 58:
			var y := 6 + fila * 10
			var glifo := rng.randi_range(0, 3)
			for k in 6:
				var px := x + (k if glifo % 2 == 0 else (k % 3) * 2)
				var py := y + (k / 2 if glifo < 2 else 5 - k)
				if px < 64 and py < 64:
					img.set_pixel(px, py, Color(0.16, 0.16, 0.18))
			x += rng.randi_range(6, 9)
	return img


## Chama (para billboards): gota com borda irregular, amarela embaixo, vermelha na ponta.
func _chama() -> Image:
	var img := _img(16, 32)
	var n := _noise(57, 0.25)
	for y in 32:
		for x in 16:
			var alto := 1.0 - y / 31.0  # 0 embaixo, 1 em cima
			var largura := 7.0 * sqrt(maxf(0.0, 1.0 - alto)) * (0.6 + 0.4 * sin(alto * PI * 0.9 + 0.5))
			var d := absf(x - 7.5) + n.get_noise_2d(x * 2.0, y) * 2.0
			var c := Color(1.0, 0.85, 0.35).lerp(Color(0.95, 0.35, 0.08), alto)
			c.a = 1.0 if d < largura else 0.0
			img.set_pixel(x, y, c)
	return img


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
