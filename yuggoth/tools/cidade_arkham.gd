extends RefCounted
## Arkham em 3D, vista da janela do escritório (docs/PLANO_ESCRITORIO.md, Fase 3d:
## "a parte externa parece feita nas coxas"). O escritório fica num andar alto,
## no morro da Miskatonic; a janela dá para o norte, por cima dos telhados: casas
## coloniais de empena e de telhado holandês (gambrel), de tábuas pintadas, com
## chaminés; sobrados de tijolo no centro; duas igrejas brancas com campanário; a
## torre gótica da universidade; olmos nos quintais; o rio Miskatonic e, ao fundo,
## os morros. Low-poly, faces chapadas, cor por vértice (shaders/cidade.gdshader).
##
## `malhas()` monta as malhas uma vez; `vista(hora)` devolve um Node3D com elas e
## os materiais da hora ("dia", "entardecer", "noite", "chuva"). Usado pelo
## gerador do escritório (tools/gerar_escritorio.gd, `_vista`).

## A rua lá embaixo (o escritório olha a cidade de cima).
const CHAO := -12.0

const PAREDES := [Color(0.86, 0.85, 0.8), Color(0.84, 0.78, 0.62), Color(0.56, 0.62, 0.68),
	Color(0.82, 0.74, 0.5), Color(0.55, 0.24, 0.18), Color(0.78, 0.8, 0.76), Color(0.66, 0.6, 0.5)]
const TIJOLOS := [Color(0.56, 0.3, 0.22), Color(0.5, 0.27, 0.2), Color(0.6, 0.36, 0.26)]
const TELHADOS := [Color(0.26, 0.27, 0.31), Color(0.32, 0.24, 0.2), Color(0.3, 0.33, 0.3), Color(0.22, 0.22, 0.24)]
const FOLHAGEM := [Color(0.22, 0.32, 0.16), Color(0.26, 0.36, 0.18), Color(0.19, 0.28, 0.17)]
const PEDRA := Color(0.56, 0.52, 0.46)

const HORAS := {
	"dia": {
		sol_dir = Vector3(0.45, 0.7, 0.5), sol_cor = Color(0.95, 0.88, 0.74), ambiente = Color(0.34, 0.37, 0.44),
		neblina_cor = Color(0.72, 0.78, 0.86), neblina_de = 18.0, neblina_ate = 100.0, neblina_max = 0.75,
		topo = Color(0.38, 0.56, 0.82), horizonte = Color(0.78, 0.83, 0.88), nuvens = 0.45, nuvem_cor = Color(0.97, 0.97, 0.98), estrelas = 0.0,
		acesas = 0.0, vidro = Color(0.18, 0.22, 0.27),
	},
	"entardecer": {
		sol_dir = Vector3(-0.85, 0.22, 0.35), sol_cor = Color(0.95, 0.56, 0.3), ambiente = Color(0.27, 0.23, 0.33),
		neblina_cor = Color(0.76, 0.55, 0.48), neblina_de = 15.0, neblina_ate = 85.0, neblina_max = 0.8,
		topo = Color(0.25, 0.27, 0.48), horizonte = Color(0.98, 0.6, 0.36), nuvens = 0.5, nuvem_cor = Color(0.98, 0.7, 0.55), estrelas = 0.0,
		acesas = 0.35, vidro = Color(0.13, 0.1, 0.12),
	},
	# A noite um pouco mais clara (Fase 3e: "para conseguirmos ver o quão bom
	# ficou a noite"): o luar nos telhados, o céu do horizonte, a névoa.
	"noite": {
		sol_dir = Vector3(0.2, 0.8, 0.4), sol_cor = Color(0.2, 0.24, 0.36), ambiente = Color(0.06, 0.068, 0.1),
		neblina_cor = Color(0.06, 0.07, 0.11), neblina_de = 18.0, neblina_ate = 85.0, neblina_max = 0.85,
		topo = Color(0.02, 0.03, 0.07), horizonte = Color(0.1, 0.11, 0.16), nuvens = 0.25, nuvem_cor = Color(0.11, 0.12, 0.16), estrelas = 1.0,
		acesas = 1.0, vidro = Color(0.025, 0.03, 0.04),
	},
	"chuva": {
		sol_dir = Vector3(0.2, 0.8, 0.4), sol_cor = Color(0.1, 0.11, 0.15), ambiente = Color(0.05, 0.055, 0.07),
		neblina_cor = Color(0.07, 0.075, 0.095), neblina_de = 6.0, neblina_ate = 48.0, neblina_max = 0.93,
		topo = Color(0.03, 0.035, 0.045), horizonte = Color(0.06, 0.065, 0.08), nuvens = 0.95, nuvem_cor = Color(0.07, 0.075, 0.09), estrelas = 0.0,
		acesas = 0.8, vidro = Color(0.02, 0.025, 0.03),
	},
}

var _malhas := {}
var _materiais := {}
var _ruido: NoiseTexture2D


## As malhas da cidade: "solido" (casas, telhados, árvores, torre...), "janelas"
## (quadradinhos que acendem; o mostrador da torre também) e "ceu".
func malhas() -> Dictionary:
	if not _malhas.is_empty():
		return _malhas
	var rng := RandomNumberGenerator.new()
	rng.seed = 1928
	var m := Malha.new()
	var j := Malha.new()

	# O chão da cidade (quintais e ruas), o rio e os morros.
	m.quad_h(Vector3(-140, CHAO, -8), Vector3(140, CHAO, -58), Color(0.3, 0.33, 0.24))
	m.quad_h(Vector3(-140, CHAO - 0.6, -58), Vector3(140, CHAO - 0.6, -66), Color(0.42, 0.48, 0.55))
	m.quad_h(Vector3(-140, CHAO, -66), Vector3(140, CHAO, -95), Color(0.28, 0.33, 0.22))
	_morros(m, rng)

	# As ruas de casas, leste–oeste, descendo para o rio.
	for fileira in 7:
		var z := -16.0 - fileira * 6.2
		var x := -48.0 + rng.randf_range(0, 3)
		while x < 48.0:
			var centro := absf(x) < 13.0 and z < -26.0 and z > -46.0
			if rng.randf() < (0.08 if centro else 0.22):
				_olmo(m, Vector3(x + 2.0, CHAO, z - 2.0 + rng.randf_range(-1, 1)), rng, rng.randf_range(0.8, 1.2))
				x += rng.randf_range(4.0, 6.0)
				continue
			var w := rng.randf_range(5.0, 8.0) if not centro else rng.randf_range(7.0, 11.0)
			var d := rng.randf_range(6.0, 8.0)
			var pos := Vector3(x + w / 2, CHAO, z - d / 2)
			if centro and rng.randf() < 0.6:
				_sobrado(m, j, pos, Vector3(w, rng.randf_range(7.0, 9.5), d), rng)
			else:
				_casa(m, j, pos, Vector3(w, rng.randf_range(5.0, 7.0), d), rng)
			# Um olmo no quintal, às vezes, atrás ou entre as casas.
			if rng.randf() < 0.35:
				_olmo(m, Vector3(x + rng.randf_range(0, w), CHAO, z - d - rng.randf_range(0.5, 2.0)), rng, rng.randf_range(0.9, 1.3))
			x += w + rng.randf_range(0.8, 3.0)

	# Olmos grandes do campus, logo abaixo da janela: as copas sobem na vista.
	for k in 6:
		_olmo(m, Vector3(-18.0 + k * 7.0 + rng.randf_range(-1, 1), CHAO - 3.0, -10.0 - rng.randf_range(0, 2)), rng, rng.randf_range(1.2, 1.4))

	_igreja(m, j, Vector3(-14.0, CHAO, -44.0), 0.9)
	_igreja(m, j, Vector3(19.0, CHAO, -54.0), 0.75)
	_torre(m, j, Vector3(7.0, CHAO, -50.0), 0.75)

	_malhas.solido = m.fechar()
	_malhas.janelas = j.fechar()
	var ceu := QuadMesh.new()
	ceu.size = Vector2(420.0, 170.0)
	_malhas.ceu = ceu
	return _malhas


## Um Node3D com a cidade na hora pedida.
func vista(hora: String) -> Node3D:
	malhas()
	var raiz := Node3D.new()
	raiz.name = "Cidade"
	var mats := _mats(hora)
	for parte in ["solido", "janelas"]:
		var mi := MeshInstance3D.new()
		mi.name = parte.capitalize()
		mi.mesh = _malhas[parte]
		mi.material_override = mats[parte]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi)
	var ceu := MeshInstance3D.new()
	ceu.name = "Ceu"
	ceu.mesh = _malhas.ceu
	ceu.material_override = mats.ceu
	ceu.position = Vector3(0, 30.0, -115.0)
	ceu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(ceu)
	return raiz


## A cidade do lapso (Fase 3e, "a janela viva"): com materiais só dela, que o
## Lapso anima de hora em hora (components/lapso.gd); começa em `hora`.
func vista_viva(hora: String) -> Node3D:
	malhas()
	var raiz := Node3D.new()
	raiz.name = "CidadeViva"
	var mats := materiais_para(HORAS[hora])
	for parte in ["solido", "janelas"]:
		var mi := MeshInstance3D.new()
		mi.name = parte.capitalize()
		mi.mesh = _malhas[parte]
		mi.material_override = mats[parte]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi)
	var ceu := MeshInstance3D.new()
	ceu.name = "Ceu"
	ceu.mesh = _malhas.ceu
	ceu.material_override = mats.ceu
	ceu.position = Vector3(0, 30.0, -115.0)
	ceu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(ceu)
	return raiz


## As horas, com a aurora (rosada, o sol baixo a leste), para o lapso.
func horas_do_lapso() -> Dictionary:
	var h := HORAS.duplicate(true)
	h["aurora"] = {
		sol_dir = Vector3(0.9, 0.18, 0.3), sol_cor = Color(0.95, 0.62, 0.58), ambiente = Color(0.22, 0.2, 0.28),
		neblina_cor = Color(0.66, 0.54, 0.58), neblina_de = 12.0, neblina_ate = 80.0, neblina_max = 0.85,
		topo = Color(0.28, 0.3, 0.52), horizonte = Color(0.96, 0.66, 0.6), nuvens = 0.45, nuvem_cor = Color(0.97, 0.74, 0.72), estrelas = 0.15,
		acesas = 0.4, vidro = Color(0.1, 0.08, 0.1),
	}
	return h


func _mats(hora: String) -> Dictionary:
	if not _materiais.has(hora):
		_materiais[hora] = materiais_para(HORAS[hora])
	return _materiais[hora]


## Os materiais (sólido, janelas e céu) para uma luz `h` no formato de HORAS
## (as vistas dos sonhos e de Boston têm as luzes delas, tools/vistas.gd).
func materiais_para(h: Dictionary) -> Dictionary:
	var cidade := load("res://shaders/cidade.gdshader") as Shader
	var solido := ShaderMaterial.new()
	solido.shader = cidade
	var janelas := ShaderMaterial.new()
	janelas.shader = cidade
	janelas.set_shader_parameter(&"janelas", true)
	for mat: ShaderMaterial in [solido, janelas]:
		for k in ["sol_dir", "sol_cor", "ambiente", "neblina_cor", "neblina_de", "neblina_ate", "neblina_max", "acesas", "vidro"]:
			mat.set_shader_parameter(StringName(k), h[k])
	if _ruido == null:
		_ruido = NoiseTexture2D.new()
		_ruido.width = 256
		_ruido.height = 256
		_ruido.seamless = true
		var n := FastNoiseLite.new()
		n.seed = 7
		n.frequency = 0.012
		n.fractal_octaves = 4
		_ruido.noise = n
	var ceu := ShaderMaterial.new()
	ceu.shader = load("res://shaders/ceu.gdshader")
	for k in ["topo", "horizonte", "nuvens", "nuvem_cor", "estrelas"]:
		ceu.set_shader_parameter(StringName(k), h[k])
	ceu.set_shader_parameter(&"ruido", _ruido)
	return {solido = solido, janelas = janelas, ceu = ceu}


# --- As peças ----------------------------------------------------------------------

## Casa colonial de tábuas: corpo, telhado de empena ou holandês (gambrel), chaminé,
## janelas na fachada que dá para a janela do escritório (+Z) e às vezes um alpendre.
func _casa(m: Malha, j: Malha, pos: Vector3, tam: Vector3, rng: RandomNumberGenerator) -> void:
	var parede: Color = PAREDES[rng.randi_range(0, PAREDES.size() - 1)] * rng.randf_range(0.9, 1.05)
	parede.a = 1.0
	var telhado: Color = TELHADOS[rng.randi_range(0, TELHADOS.size() - 1)]
	m.caixa(tam, pos + Vector3(0, tam.y / 2, 0), parede)
	var topo := pos + Vector3(0, tam.y, 0)
	var meio := tam.z / 2 + 0.35
	var alto := rng.randf_range(2.6, 3.8)
	var perfil: Array
	if rng.randf() < 0.4:
		# Gambrel: a água de baixo íngreme, a de cima mansa.
		perfil = [Vector2(-meio, 0), Vector2(-meio * 0.62, alto * 0.7), Vector2(0, alto), Vector2(meio * 0.62, alto * 0.7), Vector2(meio, 0)]
	else:
		perfil = [Vector2(-meio, 0), Vector2(0, alto), Vector2(meio, 0)]
	m.prisma(tam.x + 0.4, perfil, topo, telhado, parede)
	if rng.randf() < 0.75:
		var tij: Color = TIJOLOS[rng.randi_range(0, TIJOLOS.size() - 1)]
		m.caixa(Vector3(0.6, alto + 1.2, 0.6), topo + Vector3(rng.randf_range(-0.35, 0.35) * tam.x, (alto + 1.2) / 2 - 0.4, rng.randf_range(-0.6, 0.6)), tij)
	_janelas(j, pos, tam, 2 if tam.y < 6.0 else 3, rng)
	if rng.randf() < 0.3:
		m.caixa(Vector3(tam.x * 0.6, 0.15, 1.6), pos + Vector3(0, 2.6, tam.z / 2 + 0.8), telhado)


## Sobrado comercial de tijolo, de telhado plano com cornija (o centro, perto do rio).
func _sobrado(m: Malha, j: Malha, pos: Vector3, tam: Vector3, rng: RandomNumberGenerator) -> void:
	var tij: Color = TIJOLOS[rng.randi_range(0, TIJOLOS.size() - 1)] * rng.randf_range(0.9, 1.1)
	tij.a = 1.0
	m.caixa(tam, pos + Vector3(0, tam.y / 2, 0), tij)
	m.caixa(Vector3(tam.x + 0.5, 0.5, tam.z + 0.5), pos + Vector3(0, tam.y + 0.25, 0), tij * 0.8)
	_janelas(j, pos, tam, int(tam.y / 3.2), rng)


## As janelas da fachada +Z, em grade: cada uma pode acender à noite (cor r).
func _janelas(j: Malha, pos: Vector3, tam: Vector3, andares: int, rng: RandomNumberGenerator) -> void:
	var colunas := maxi(2, int(tam.x / 2.4))
	for a in andares:
		var y := pos.y + 1.6 + a * (tam.y - 1.0) / maxf(andares, 1)
		for c in colunas:
			var x := pos.x - tam.x / 2 + (c + 0.5) * tam.x / colunas
			var acende := rng.randf_range(0.7, 1.0) if rng.randf() < 0.35 else 0.0
			j.quad_v(Vector3(x, y, pos.z + tam.z / 2 + 0.03), Vector2(0.9, 1.3), Color(acende, 0, 0))


## Igreja de madeira branca: a nave de empena e, na frente, a torre com o
## campanário e a agulha.
func _igreja(m: Malha, j: Malha, pos: Vector3, escala: float) -> void:
	var branco := Color(0.92, 0.91, 0.88)
	var nave := Vector3(9.0, 8.0, 15.0) * escala
	m.caixa(nave, pos + Vector3(0, nave.y / 2, 0), branco)
	m.prisma(nave.z + 0.4, [Vector2(-nave.x / 2 - 0.3, 0), Vector2(0, 5.0 * escala), Vector2(nave.x / 2 + 0.3, 0)], pos + Vector3(0, nave.y, 0), TELHADOS[0], branco, true)
	var torre := pos + Vector3(0, 0, nave.z / 2 + 1.5 * escala)
	var lado := 3.2 * escala
	m.caixa(Vector3(lado, 13.0 * escala, lado), torre + Vector3(0, 6.5 * escala, 0), branco)
	m.caixa(Vector3(lado * 0.8, 3.5 * escala, lado * 0.8), torre + Vector3(0, 14.75 * escala, 0), branco * 0.92)
	m.piramide(lado * 0.42, 9.0 * escala, torre + Vector3(0, 16.5 * escala, 0), 8, branco)
	for k in 3:
		j.quad_v(torre + Vector3(0, (3.0 + k * 3.5) * escala, lado / 2 + 0.03), Vector2(0.8, 1.8) * escala, Color(0.5 if k == 0 else 0.0, 0, 0))


## A torre gótica da Miskatonic: o fuste de pedra com contrafortes, o campanário
## com o mostrador (claro de dia, aceso à noite), os pináculos e a agulha; e um
## prédio da universidade junto dela. `e` é a escala.
func _torre(m: Malha, j: Malha, pos: Vector3, e: float) -> void:
	m.caixa(Vector3(4.0, 22.0, 4.0) * e, pos + Vector3(0, 11.0, 0) * e, PEDRA)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			m.caixa(Vector3(0.8, 18.0, 0.8) * e, pos + Vector3(sx * 2.1, 9.0, sz * 2.1) * e, PEDRA * 0.9)
			m.piramide(0.45 * e, 3.2 * e, pos + Vector3(sx * 2.1, 22.0, sz * 2.1) * e, 4, PEDRA * 0.85)
	m.caixa(Vector3(3.4, 4.0, 3.4) * e, pos + Vector3(0, 24.0, 0) * e, PEDRA)
	m.piramide(2.2 * e, 11.0 * e, pos + Vector3(0, 26.0, 0) * e, 8, TELHADOS[0])
	# O mostrador (cor g) e as ogivas (acendem à noite, cor r).
	j.quad_v(pos + Vector3(0, 24.2, 1.73) * e, Vector2(2.0, 2.0) * e, Color(1.0, 1.0, 0))
	for k in 3:
		j.quad_v(pos + Vector3(0, 6.0 + k * 5.0, 2.03) * e, Vector2(0.9, 2.6) * e, Color(0.8 if k == 1 else 0.0, 0, 0))
	var predio := pos + Vector3(-10.0, 0, 1.0) * e
	var tam := Vector3(16.0, 11.0, 8.0) * e
	m.caixa(tam, predio + Vector3(0, tam.y / 2, 0), PEDRA * 0.95)
	m.prisma(tam.x + 0.4, [Vector2(-tam.z / 2 - 0.3, 0), Vector2(0, 4.0 * e), Vector2(tam.z / 2 + 0.3, 0)], predio + Vector3(0, tam.y, 0), TELHADOS[0], PEDRA * 0.95)
	_janelas(j, predio, tam, 3, RandomNumberGenerator.new())

## Um olmo: o tronco e a copa larga, em vaso, de três bipirâmides tortas.
func _olmo(m: Malha, base: Vector3, rng: RandomNumberGenerator, escala: float) -> void:
	var tronco := Color(0.24, 0.2, 0.16)
	m.caixa(Vector3(0.5, 5.0, 0.5) * Vector3(escala, escala, escala), base + Vector3(0, 2.5 * escala, 0), tronco)
	var folha: Color = FOLHAGEM[rng.randi_range(0, FOLHAGEM.size() - 1)]
	for k in 3:
		var c := base + Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(6.0, 8.5), rng.randf_range(-1.6, 1.6)) * escala
		m.bipiramide(rng.randf_range(2.4, 3.4) * escala, rng.randf_range(2.6, 3.6) * escala, c, 6, folha * rng.randf_range(0.85, 1.1), rng.randf() * TAU)


## Os morros do outro lado do rio: uma crista irregular, de leste a oeste.
func _morros(m: Malha, rng: RandomNumberGenerator) -> void:
	var cor := Color(0.24, 0.3, 0.22)
	var anterior := Vector3(-160, CHAO, -90)
	var alt_ant := 10.0
	var x := -160.0
	while x < 160.0:
		var prox := x + rng.randf_range(10.0, 22.0)
		var alt := rng.randf_range(8.0, 22.0)
		var z := -90.0 + rng.randf_range(-6, 6)
		var a := Vector3(x, CHAO, anterior.z)
		var b := Vector3(prox, CHAO, z)
		m.quad(a, b, b + Vector3(0, alt, -4), a + Vector3(0, alt_ant, -4), Vector3(0, 0.45, 1).normalized(), cor * rng.randf_range(0.9, 1.1))
		anterior = b
		alt_ant = alt
		x = prox


## Monta triângulos com normal por face e cor por vértice. A face da frente do
## Godot é a de giro horário vista de fora: cada triângulo é virado para que a
## normal pedida aponte para fora.
class Malha:
	var st := SurfaceTool.new()
	var vazio := true

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	func tri(a: Vector3, b: Vector3, c: Vector3, normal: Vector3, cor: Color) -> void:
		if (b - a).cross(c - a).dot(normal) > 0.0:
			var t := b
			b = c
			c = t
		for v in [a, b, c]:
			st.set_normal(normal)
			st.set_color(cor)
			st.add_vertex(v)
		vazio = false

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, cor: Color) -> void:
		tri(a, b, c, normal, cor)
		tri(a, c, d, normal, cor)

	## Um retângulo deitado (normal para cima), de canto a canto.
	func quad_h(a: Vector3, b: Vector3, cor: Color) -> void:
		quad(a, Vector3(b.x, a.y, a.z), b, Vector3(a.x, a.y, b.z), Vector3.UP, cor)

	## Um retângulo em pé virado para +Z, centrado em `c`.
	func quad_v(c: Vector3, tam: Vector2, cor: Color) -> void:
		var w := tam.x / 2
		var h := tam.y / 2
		quad(c + Vector3(-w, -h, 0), c + Vector3(w, -h, 0), c + Vector3(w, h, 0), c + Vector3(-w, h, 0), Vector3.BACK, cor)

	## Caixa sem a face de baixo, centrada em `c`.
	func caixa(tam: Vector3, c: Vector3, cor: Color) -> void:
		var h := tam / 2
		var p := func(x: float, y: float, z: float) -> Vector3: return c + Vector3(x * h.x, y * h.y, z * h.z)
		quad(p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), Vector3.BACK, cor)
		quad(p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(-1, 1, -1), Vector3.FORWARD, cor)
		quad(p.call(1, -1, -1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(1, 1, -1), Vector3.RIGHT, cor)
		quad(p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), Vector3.LEFT, cor)
		quad(p.call(-1, 1, -1), p.call(1, 1, -1), p.call(1, 1, 1), p.call(-1, 1, 1), Vector3.UP, cor)

	## Um telhado: o `perfil` (z, y) estendido ao longo de X por `largura`, com as
	## empenas nas pontas na cor `empena`. `girar` põe a cumeeira de norte a sul.
	func prisma(largura: float, perfil: Array, base: Vector3, cor: Color, empena: Color, girar := false) -> void:
		var w := largura / 2
		var em := func(x: float, pz: Vector2) -> Vector3:
			return base + (Vector3(pz.x, pz.y, x) if girar else Vector3(x, pz.y, pz.x))
		var ex := Vector3.BACK if girar else Vector3.RIGHT
		for i in perfil.size() - 1:
			var a: Vector2 = perfil[i]
			var b: Vector2 = perfil[i + 1]
			var lado := b - a
			var n2 := Vector2(lado.y, -lado.x).normalized()
			if n2.y < 0.0:
				n2 = -n2
			var n := (Vector3(n2.x, n2.y, 0) if girar else Vector3(0, n2.y, n2.x)).normalized()
			quad(em.call(-w, a), em.call(w, a), em.call(w, b), em.call(-w, b), n, cor)
		for s in [-1.0, 1.0]:
			for i in range(1, perfil.size() - 1):
				tri(em.call(s * w, perfil[0]), em.call(s * w, perfil[i]), em.call(s * w, perfil[i + 1]), ex * s, empena)

	## Pirâmide de `lados` lados (uma agulha, um pináculo), da base em `c` para cima.
	func piramide(raio: float, alt: float, c: Vector3, lados: int, cor: Color) -> void:
		var topo := c + Vector3(0, alt, 0)
		for i in lados:
			var a0 := TAU * i / lados + PI / lados
			var a1 := TAU * (i + 1) / lados + PI / lados
			var p0 := c + Vector3(cos(a0), 0, sin(a0)) * raio
			var p1 := c + Vector3(cos(a1), 0, sin(a1)) * raio
			var meio := (p0 + p1) / 2 - c
			var n := Vector3(meio.x, raio * raio / alt, meio.z).normalized()
			tri(p0, p1, topo, n, cor)

	## Duas pirâmides base com base (uma copa de árvore), girada `giro`.
	func bipiramide(raio: float, alt: float, c: Vector3, lados: int, cor: Color, giro: float) -> void:
		for s in [-1.0, 1.0]:
			var ponta := c + Vector3(0, alt * 0.5 * s, 0)
			for i in lados:
				var a0 := TAU * i / lados + giro
				var a1 := TAU * (i + 1) / lados + giro
				var p0 := c + Vector3(cos(a0), 0, sin(a0)) * raio
				var p1 := c + Vector3(cos(a1), 0, sin(a1)) * raio
				var n := ((p0 + p1) / 2 - c + Vector3(0, raio * raio / alt * s, 0)).normalized()
				tri(p0, p1, ponta, n, cor * (1.0 if s > 0 else 0.8))

	func fechar() -> ArrayMesh:
		return st.commit()
