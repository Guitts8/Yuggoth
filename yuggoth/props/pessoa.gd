@tool
class_name Pessoa
extends Node3D
## Uma pessoa (playtest 11: "eu creio que terei que fazer os modelos de cultista,
## do funcionário e dos mi-go para que fiquem realmente bons e impressionantes, a
## menos que você não tenha tentado muito"). Feita em código, no feitio do PS1, mas
## com cuidado:
## - A cabeça é uma esfera deformada (`_ponto_da_cabeca`): o crânio mais cheio
##   atrás, o maxilar que afina em V até o queixo, as maçãs do rosto, a testa e o
##   arco das sobrancelhas, as órbitas fundas e escuras com os olhos dentro, o nariz
##   em cunha com as narinas, os lábios, as orelhas; o cabelo é uma casca por cima,
##   com a linha do cabelo na testa, nas têmporas e na nuca.
## - O corpo é torneado (anéis elípticos): quadril, cintura, peito, ombros; a camisa
##   com o colarinho e a gravata, o colete com o decote em V e os botões, ou o
##   paletó; as calças com o vinco; os sapatos com a biqueira.
## - Os braços e as pernas são tubos com cotovelo e joelho em pivôs (`pose`), e as
##   mãos têm palma, quatro dedos e o polegar.
## - `manto`: o cultista — o manto de lã até o chão, o capuz fundo com o rosto pálido
##   lá dentro, as mangas largas e as mãos juntas.
## Respira devagar e, com `olhar_alvo`, vira a cabeça para lá (com limite).
## Peças com nome "_" não vão para o .tscn; um filho `Modelo` (o .glb do artista)
## substitui tudo. A frente é o -Z; os pés em y = 0.

enum Pose { PARADO, MAO_NA_PORTA, MAOS_JUNTAS }

@export var altura := 1.75:
	set(v):
		altura = v
		_reconstruir()
@export var pose := Pose.PARADO:
	set(v):
		pose = v
		_reconstruir()
@export var manto := false:
	set(v):
		manto = v
		_reconstruir()
@export var pele := Color(0.86, 0.66, 0.55):
	set(v):
		pele = v
		_reconstruir()
@export var cabelo := Color(0.28, 0.19, 0.12):
	set(v):
		cabelo = v
		_reconstruir()
@export var camisa := Color(0.86, 0.84, 0.78):
	set(v):
		camisa = v
		_reconstruir()
## O colete (ou, com `paleto`, o paletó).
@export var colete := Color(0.24, 0.22, 0.28):
	set(v):
		colete = v
		_reconstruir()
@export var paleto := false:
	set(v):
		paleto = v
		_reconstruir()
@export var calca := Color(0.2, 0.19, 0.22):
	set(v):
		calca = v
		_reconstruir()
@export var gravata := Color(0.35, 0.12, 0.12):
	set(v):
		gravata = v
		_reconstruir()
## O manto do cultista.
@export var la := Color(0.09, 0.08, 0.09):
	set(v):
		la = v
		_reconstruir()
## Para onde a cabeça vira (global; INF = em frente).
var olhar_alvo := Vector3.INF

var _mat: Material
var _cabeca: Node3D
var _peito: Node3D
var _t := 0.0

const SAPATO := Color(0.1, 0.07, 0.06)
const LABIO := Color(0.62, 0.36, 0.34)
const OLHO := Color(0.86, 0.84, 0.8)
const IRIS := Color(0.16, 0.12, 0.1)
const BOTAO := Color(0.55, 0.5, 0.4)
## A altura da cabeça (o centro do crânio) numa pessoa de 1,75 m.
const CABECA_Y := 1.64


func _ready() -> void:
	_reconstruir()


func _process(delta: float) -> void:
	if _peito == null:
		return
	_t += delta
	# A respiração: o peito sobe e desce um pouco.
	_peito.scale = Vector3(1.0 + 0.006 * sin(_t * 1.6), 1.0 + 0.004 * sin(_t * 1.6), 1.0 + 0.012 * sin(_t * 1.6))
	if _cabeca:
		var alvo := Vector2.ZERO
		if olhar_alvo != Vector3.INF and not Engine.is_editor_hint():
			var local := global_transform.affine_inverse() * olhar_alvo - _cabeca.position
			alvo.x = clampf(atan2(-local.x, -local.z), -1.0, 1.0)
			alvo.y = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.4, 0.4)
		var k := 1.0 - exp(-3.0 * delta)
		_cabeca.rotation.y = lerpf(_cabeca.rotation.y, alvo.x + sin(_t * 0.4) * 0.03, k)
		_cabeca.rotation.x = lerpf(_cabeca.rotation.x, alvo.y + sin(_t * 0.31) * 0.02, k)


func _reconstruir() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if String(c.name).begins_with("_"):
			remove_child(c)
			c.queue_free()
	_cabeca = null
	_peito = null
	if has_node(^"Modelo"):
		return
	_mat = _material()
	var raiz := Node3D.new()
	raiz.name = "_Corpo"
	raiz.scale = Vector3.ONE * (altura / 1.75)
	add_child(raiz)

	_peito = Node3D.new()
	_peito.name = "_Peito"
	_peito.position = Vector3(0, 1.0, 0)
	raiz.add_child(_peito)
	var tronco := _st()
	if manto:
		_manto(tronco)
	else:
		_tronco(tronco)
	_malha(tronco, "_Tronco", _peito)

	_cabeca = Node3D.new()
	_cabeca.name = "_Cabeca"
	_cabeca.position = Vector3(0, 1.53, 0.0)
	raiz.add_child(_cabeca)
	var cab := _st()
	_rosto(cab, Vector3(0, CABECA_Y - 1.53, 0))
	if manto:
		_capuz(cab, Vector3(0, CABECA_Y - 1.53, 0))
	else:
		_cabelo(cab, Vector3(0, CABECA_Y - 1.53, 0))
	_malha(cab, "_Malha", _cabeca)

	for lado in [-1.0, 1.0]:
		_braco(raiz, lado)
		if not manto:
			_perna(raiz, lado)


func _material() -> Material:
	var mat := (load("res://art/materials/papel.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	mat.set_shader_parameter(&"world_uv", false)
	mat.set_shader_parameter(&"albedo_tex", load("res://art/textures/grao.png"))
	mat.set_shader_parameter(&"albedo_color", Color.WHITE)
	mat.set_shader_parameter(&"facetado", false)
	return mat


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _malha(st: SurfaceTool, nome: String, pai: Node3D) -> MeshInstance3D:
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	mi.material_override = _mat
	pai.add_child(mi)
	return mi


# --- A cabeça ---------------------------------------------------------------------

## Um ponto da cabeça na direção (u em volta, de -Z para +X; v de cima para baixo),
## relativo ao centro do crânio, e a cor dele.
func _ponto_da_cabeca(u: float, v: float) -> Array:
	# Direção: u = 0 é a frente (-Z).
	var sx := sin(u)
	var sz := -cos(u)
	var cy := cos(v)
	var sv := sin(v)
	var y := cy * 0.118
	var frente := maxf(0.0, -sz)
	var r_x := 0.076
	var r_z := 0.098
	# O crânio mais cheio atrás e em cima; a testa reta.
	if sz > 0.0:
		r_z += 0.008 * sz
	# Abaixo do meio, o maxilar afina para o queixo (em V), mais na frente.
	var baixo := clampf(-cy, 0.0, 1.0)
	r_x *= 1.0 - 0.38 * baixo * baixo
	r_z *= 1.0 - 0.22 * baixo * (1.0 - frente * 0.6)
	var p := Vector3(sx * sv * r_x, y, sz * sv * r_z)
	var cor := pele
	var lado := absf(sx)
	# O queixo: avança um pouco e desce.
	if frente > 0.7 and cy < -0.55:
		p.z -= 0.012 * frente * smoothstep(-0.55, -0.85, cy)
	# A testa e o arco das sobrancelhas.
	if frente > 0.6 and cy > 0.05 and cy < 0.32:
		p.z -= 0.006 * frente * (1.0 - absf(cy - 0.18) / 0.14)
	# As órbitas: fundas e escuras, dos dois lados do nariz.
	var orbita := frente * smoothstep(0.42, 0.2, absf(lado - 0.38)) * smoothstep(0.14, 0.02, absf(cy - 0.02))
	p.z += 0.012 * orbita
	cor = cor.lerp(pele.darkened(0.45), orbita * 0.85)
	# As maçãs do rosto.
	var maca := smoothstep(0.25, 0.0, absf(lado - 0.62)) * smoothstep(0.18, 0.0, absf(cy + 0.12)) * frente
	p.x += signf(sx) * 0.006 * maca
	cor = cor.lerp(pele.lerp(Color(0.85, 0.45, 0.4), 0.3), maca * 0.4)
	# A boca: os lábios, um pouco mais escuros, e a linha entre eles.
	var boca := frente * smoothstep(0.3, 0.05, lado) * smoothstep(0.07, 0.0, absf(cy + 0.43))
	cor = cor.lerp(LABIO, boca * 0.75)
	if absf(cy + 0.43) < 0.015 and lado < 0.22 and frente > 0.8:
		cor = LABIO.darkened(0.55)
	# A sombra embaixo do queixo e no pescoço.
	if cy < -0.85:
		cor = cor.darkened(0.25)
	return [p, cor]


func _rosto(st: SurfaceTool, c: Vector3) -> void:
	const LADOS := 22
	const ANEIS := 16
	var pts: Array = []
	for j in ANEIS + 1:
		var fila: Array = []
		for i in LADOS + 1:
			fila.append(_ponto_da_cabeca(TAU * i / LADOS, PI * j / ANEIS))
		pts.append(fila)
	for j in ANEIS:
		for i in LADOS:
			var a: Array = pts[j][i]
			var b: Array = pts[j][i + 1]
			var d: Array = pts[j + 1][i]
			var e: Array = pts[j + 1][i + 1]
			_tri(st, c + a[0], c + d[0], c + b[0], a[1], d[1], b[1], c)
			_tri(st, c + b[0], c + d[0], c + e[0], b[1], d[1], e[1], c)
	# O nariz: uma cunha da raiz (entre as sobrancelhas) à ponta, com as asas e as
	# narinas.
	var raiz := c + Vector3(0, 0.012, -0.096)
	var ponta := c + Vector3(0, -0.03, -0.122)
	var base := c + Vector3(0, -0.042, -0.106)
	var asa_e := c + Vector3(-0.017, -0.036, -0.1)
	var asa_d := c + Vector3(0.017, -0.036, -0.1)
	var dorso := pele.lightened(0.06)
	_tri(st, raiz, asa_e, ponta, dorso, pele, dorso, c)
	_tri(st, raiz, ponta, asa_d, dorso, dorso, pele, c)
	_tri(st, asa_e, base, ponta, pele.darkened(0.2), pele.darkened(0.35), pele, c)
	_tri(st, asa_d, ponta, base, pele.darkened(0.2), pele, pele.darkened(0.35), c)
	# Os olhos, dentro das órbitas: o branco e a íris.
	for s in [-1.0, 1.0]:
		var o := c + Vector3(s * 0.031, 0.003, -0.09)
		_disco(st, o, Vector3(0.0105, 0.0055, 0), Vector3(0, 0, -1), OLHO.darkened(0.15), 8)
		_disco(st, o + Vector3(0, 0, -0.0015), Vector3(0.0045, 0.0045, 0), Vector3(0, 0, -1), IRIS, 6)
		# A pálpebra de cima, uma sombra.
		_disco(st, o + Vector3(0, 0.005, -0.001), Vector3(0.012, 0.0028, 0), Vector3(0, 0, -1), pele.darkened(0.5), 6)
	# As sobrancelhas.
	for s in [-1.0, 1.0]:
		var a := c + Vector3(s * 0.014, 0.022, -0.1)
		var b := c + Vector3(s * 0.05, 0.024, -0.088)
		_tri(st, a, b, b + Vector3(0, -0.006, 0), cabelo, cabelo, cabelo, a + Vector3(0, 0, 0.05))
		_tri(st, a, b + Vector3(0, -0.006, 0), a + Vector3(0, -0.006, 0), cabelo, cabelo, cabelo, a + Vector3(0, 0, 0.05))
	# As orelhas: meio disco achatado de cada lado.
	for s in [-1.0, 1.0]:
		var o := c + Vector3(s * 0.077, -0.005, 0.01)
		_disco(st, o, Vector3(0, 0.03, 0.019), Vector3(s, 0, 0.15).normalized(), pele.darkened(0.08), 8)
		_disco(st, o + Vector3(s * 0.002, 0, 0), Vector3(0, 0.018, 0.01), Vector3(s, 0, 0.15).normalized(), pele.darkened(0.35), 6)
	# O pescoço.
	_tubo(st, [c + Vector3(0, -0.07, 0.015), c + Vector3(0, -0.17, 0.02)], [Vector2(0.045, 0.048), Vector2(0.05, 0.05)], [pele.darkened(0.2), pele.darkened(0.1)], 10)


## O cabelo curto: uma casca sobre o crânio, acima da linha do cabelo (alta na
## testa, descendo nas têmporas e até a nuca atrás), com volume em cima e a risca.
func _cabelo(st: SurfaceTool, c: Vector3) -> void:
	const LADOS := 22
	const ANEIS := 12
	var linha := func(u: float) -> float:
		# Quanto o cabelo desce (v, de 0 no alto a PI): pouco na frente, muito atrás.
		var atras := (1.0 - cos(u)) * 0.5
		# Na testa alto; nas têmporas desce até o alto da orelha; atrás, até a nuca.
		return 0.98 + 1.42 * pow(atras, 1.6)
	var pts: Array = []
	for j in ANEIS + 1:
		var fila: Array = []
		for i in LADOS + 1:
			var u := TAU * i / LADOS
			var v: float = float(linha.call(u)) * float(j) / ANEIS
			var p: Vector3 = _ponto_da_cabeca(u, v)[0]
			var grosso := 0.003 + 0.02 * pow(1.0 - float(j) / ANEIS, 1.5) * (0.7 + 0.3 * cos(u))
			p += p.normalized() * grosso
			# A risca, do lado esquerdo.
			if absf(sin(u) + 0.35) < 0.08 and cos(u) < 0.3 and j < ANEIS / 2:
				p -= p.normalized() * 0.004
			fila.append(p)
		pts.append(fila)
	for j in ANEIS:
		for i in LADOS:
			var t := float(j) / ANEIS
			# Mais claro no alto, onde a luz bate; na borda, esfuma na pele (a linha
			# do cabelo não é um corte).
			var t2 := float(j + 1) / ANEIS
			var cor_a := cabelo.lightened(0.1 * (1.0 - t)).lerp(pele.darkened(0.3), smoothstep(0.75, 1.0, t) * 0.45)
			var cor_b := cabelo.darkened(0.1 * t2).lerp(pele.darkened(0.3), smoothstep(0.75, 1.0, t2) * 0.45)
			_tri(st, c + pts[j][i], c + pts[j + 1][i], c + pts[j][i + 1], cor_a, cor_b, cor_a, c)
			_tri(st, c + pts[j][i + 1], c + pts[j + 1][i], c + pts[j + 1][i + 1], cor_a, cor_b, cor_b, c)
			# A borda de baixo da casca, para não se ver por baixo dela.
			if j == ANEIS - 1:
				var dentro_a: Vector3 = pts[j + 1][i] * 0.94
				var dentro_b: Vector3 = pts[j + 1][i + 1] * 0.94
				_tri(st, c + pts[j + 1][i], c + dentro_a, c + pts[j + 1][i + 1], cor_b, cor_b, cor_b, c + Vector3(0, 0.2, 0))
				_tri(st, c + pts[j + 1][i + 1], c + dentro_a, c + dentro_b, cor_b, cor_b, cor_b, c + Vector3(0, 0.2, 0))


## O capuz do cultista: uma casca larga em volta da cabeça, aberta na frente (o
## rosto lá no fundo), escura por dentro, caindo sobre os ombros.
func _capuz(st: SurfaceTool, c: Vector3) -> void:
	const LADOS := 20
	const ANEIS := 12
	var pts: Array = []
	for j in ANEIS + 1:
		var fila: Array = []
		var v := PI * 0.86 * float(j) / ANEIS
		for i in LADOS + 1:
			var u := TAU * i / LADOS
			var n := Vector3(sin(u) * sin(v), cos(v), -cos(u) * sin(v))
			var r := Vector3(0.11, 0.135, 0.125)
			# A ponta do capuz, para trás e para cima.
			var p := n * r + Vector3(0, 0.012, 0.01)
			if n.z > 0.3 and n.y > 0.2:
				p += Vector3(0, 0.02, 0.025) * n.z * n.y
			# A frente do capuz avança: o rosto fica no fundo, na sombra.
			if n.z < 0.0:
				p.z += n.z * 0.035
			# Embaixo abre sobre os ombros.
			if j > ANEIS * 0.6:
				var k := (float(j) / ANEIS - 0.6) / 0.4
				p.x *= 1.0 + 0.9 * k
				p.z *= 1.0 + 0.5 * k
				p.y -= 0.05 * k
			fila.append(p)
		pts.append(fila)
	for j in ANEIS:
		for i in LADOS:
			var u := TAU * (i + 0.5) / LADOS
			var v := PI * 0.86 * (j + 0.5) / ANEIS
			# A abertura do rosto: na frente, da testa ao queixo.
			var frente := cos(u)
			if frente > 0.72 and v > 0.98 and v < 2.3:
				continue
			var cor := la.lightened(0.05 + 0.04 * sin(u * 3.0))
			# Por fora e por dentro (o dentro, quase preto).
			_tri(st, c + pts[j][i], c + pts[j + 1][i], c + pts[j][i + 1], cor, cor, cor, c)
			_tri(st, c + pts[j][i + 1], c + pts[j + 1][i], c + pts[j + 1][i + 1], cor, cor, cor, c)
			var escuro := la.darkened(0.7)
			var longe := c + Vector3(0, 0, 3.0)
			_tri(st, c + pts[j][i], c + pts[j][i + 1], c + pts[j + 1][i], escuro, escuro, escuro, longe * 0.0 + c - (pts[j][i] as Vector3) * 3.0)
			_tri(st, c + pts[j][i + 1], c + pts[j + 1][i + 1], c + pts[j + 1][i], escuro, escuro, escuro, c - (pts[j][i + 1] as Vector3) * 3.0)


# --- O corpo ----------------------------------------------------------------------

## Um anel elíptico do tronco: [y (do peito), meia largura, meia profundidade,
## deslocamento z].
func _torno(st: SurfaceTool, aneis: Array, lados: int, cores: Array, decote := -1) -> void:
	var pts: Array = []
	for an: Array in aneis:
		var fila: Array = []
		for i in lados + 1:
			var u := TAU * i / lados
			fila.append(Vector3(sin(u) * an[1], an[0], -cos(u) * an[2] + an[3]))
		pts.append(fila)
	for j in aneis.size() - 1:
		for i in lados:
			var u := TAU * (i + 0.5) / lados
			# O decote em V: a partir do anel `decote`, cada vez mais aberto para cima.
			if decote >= 0 and j >= decote and cos(u) > 0.96 - 0.16 * (j - decote):
				continue
			var eixo := Vector3(0, (aneis[j][0] + aneis[j + 1][0]) * 0.5, aneis[j][3])
			_tri(st, pts[j][i], pts[j + 1][i], pts[j][i + 1], cores[j], cores[j + 1], cores[j], eixo)
			_tri(st, pts[j][i + 1], pts[j + 1][i], pts[j + 1][i + 1], cores[j], cores[j + 1], cores[j + 1], eixo)


## O tronco vestido (relativo ao `_Peito`, em y = 1,0): a camisa, o colarinho e a
## gravata, o colete (decote em V, botões) ou o paletó.
func _tronco(st: SurfaceTool) -> void:
	# A camisa, do quadril aos ombros, e o alto dos ombros fechando no pescoço.
	var aneis := [[-0.08, 0.165, 0.105, 0.0], [0.05, 0.15, 0.1, 0.0], [0.2, 0.165, 0.11, -0.005], [0.33, 0.18, 0.112, -0.01],
		[0.43, 0.19, 0.1, 0.0], [0.5, 0.15, 0.08, 0.01], [0.54, 0.06, 0.055, 0.015]]
	var cores: Array = []
	for an: Array in aneis:
		cores.append(camisa.darkened(0.06 if an[0] < 0.1 else 0.0))
	_torno(st, aneis, 16, cores)
	# O colarinho e a gravata.
	for s in [-1.0, 1.0]:
		var a := Vector3(s * 0.005, 0.55, -0.058)
		_tri(st, a, Vector3(s * 0.055, 0.565, -0.035), Vector3(s * 0.03, 0.51, -0.075), camisa.lightened(0.1), camisa, camisa.lightened(0.05), Vector3(0, 0.5, 0.2))
	var g0 := Vector3(0, 0.535, -0.078)
	_tri(st, g0 + Vector3(-0.016, 0, 0), g0 + Vector3(0.016, 0, 0), g0 + Vector3(0, -0.03, -0.004), gravata.lightened(0.1), gravata.lightened(0.1), gravata, Vector3(0, 0.4, 0.3))
	_tri(st, g0 + Vector3(-0.012, -0.02, -0.003), g0 + Vector3(0.012, -0.02, -0.003), g0 + Vector3(0, -0.31, -0.03), gravata, gravata, gravata.darkened(0.25), Vector3(0, 0.3, 0.3))
	_tri(st, g0 + Vector3(0, -0.31, -0.03), g0 + Vector3(-0.022, -0.27, -0.03), g0 + Vector3(0.022, -0.27, -0.03), gravata.darkened(0.25), gravata, gravata, Vector3(0, 0.3, 0.3))
	# O cinto e as calças até o alto da coxa.
	_torno(st, [[-0.1, 0.168, 0.107, 0.0], [-0.06, 0.168, 0.107, 0.0]], 16, [SAPATO.lightened(0.05), SAPATO.lightened(0.05)])
	_torno(st, [[-0.2, 0.17, 0.11, 0.0], [-0.1, 0.168, 0.108, 0.0]], 16, [calca, calca])
	# O colete: um pouco maior que a camisa, aberto em V na frente do peito.
	var col := [[-0.07, 0.172, 0.112, 0.0], [0.05, 0.158, 0.107, 0.0], [0.2, 0.172, 0.117, -0.005], [0.33, 0.186, 0.118, -0.01],
		[0.43, 0.196, 0.105, 0.0], [0.505, 0.156, 0.086, 0.01]]
	if paleto:
		col = [[-0.24, 0.19, 0.12, 0.0], [-0.07, 0.18, 0.118, 0.0], [0.05, 0.168, 0.114, 0.0], [0.2, 0.182, 0.124, -0.005], [0.33, 0.196, 0.124, -0.01], [0.44, 0.205, 0.108, 0.0], [0.5, 0.16, 0.086, 0.01]]
	var cores_c: Array = []
	for k in col.size():
		cores_c.append(colete.lightened(0.04 * k))
	_torno(st, col, 16, cores_c, 2)
	# O V do decote (a borda do colete) e os botões.
	for k in 4:
		var y := 0.0 + k * 0.075
		_disco(st, Vector3(0, y, -0.114 - 0.002 * k), Vector3(0.007, 0.007, 0), Vector3(0, 0, -1), BOTAO, 6)


## O manto do cultista (relativo ao `_Peito`): do chão (largo, arrastando) aos
## ombros, com as dobras verticais.
func _manto(st: SurfaceTool) -> void:
	var aneis := [[-1.0, 0.33, 0.3, 0.02], [-0.7, 0.28, 0.24, 0.01], [-0.3, 0.22, 0.17, 0.0], [0.05, 0.19, 0.13, 0.0],
		[0.3, 0.2, 0.13, -0.005], [0.44, 0.21, 0.12, 0.0], [0.52, 0.15, 0.09, 0.01], [0.56, 0.07, 0.06, 0.015]]
	var pts: Array = []
	const LADOS := 18
	for an: Array in aneis:
		var fila: Array = []
		for i in LADOS + 1:
			var u := TAU * i / LADOS
			# As dobras: a lã cai em pregas, mais fundas embaixo.
			var prega := 1.0 + 0.07 * sin(u * 6.0) * clampf(-an[0], 0.0, 1.0)
			fila.append(Vector3(sin(u) * an[1] * prega, an[0], -cos(u) * an[2] * prega + an[3]))
		pts.append(fila)
	for j in aneis.size() - 1:
		for i in LADOS:
			var u := TAU * (i + 0.5) / LADOS
			var sombra := 0.5 + 0.5 * sin(u * 6.0)
			var c0 := la.lightened(0.08 * sombra)
			var c1 := la.lightened(0.05 * sombra)
			var eixo := Vector3(0, (aneis[j][0] + aneis[j + 1][0]) * 0.5, 0)
			_tri(st, pts[j][i], pts[j + 1][i], pts[j][i + 1], c0, c1, c0, eixo)
			_tri(st, pts[j][i + 1], pts[j + 1][i], pts[j + 1][i + 1], c0, c1, c1, eixo)
	# A barra, por dentro (vista de perto, embaixo).
	for i in LADOS:
		_tri(st, pts[0][i], pts[0][i + 1], Vector3(0, -1.0, 0), la.darkened(0.6), la.darkened(0.6), la.darkened(0.8), Vector3(0, 0, 0))


# --- Os membros -------------------------------------------------------------------

## Um braço: o ombro (pivô), o braço, o cotovelo (pivô), o antebraço e a mão. A
## pose dobra os pivôs.
func _braco(raiz: Node3D, lado: float) -> void:
	var ombro := Node3D.new()
	ombro.name = "_Ombro%s" % ("E" if lado < 0 else "D")
	ombro.position = Vector3(lado * 0.2, 1.44, 0.0)
	raiz.add_child(ombro)
	var cotovelo := Node3D.new()
	cotovelo.name = "_Cotovelo"
	cotovelo.position = Vector3(0, -0.29, 0)
	ombro.add_child(cotovelo)
	var manga := la.lightened(0.04) if manto else (colete if paleto else camisa)
	var st := _st()
	if manto:
		_tubo(st, [Vector3(0, 0.02, 0), Vector3(0, -0.29, 0)], [Vector2(0.06, 0.06), Vector2(0.075, 0.075)], [manga, manga.darkened(0.1)], 10)
	else:
		_tubo(st, [Vector3(0, 0.02, 0), Vector3(0, -0.15, 0.0), Vector3(0, -0.29, 0)], [Vector2(0.052, 0.055), Vector2(0.045, 0.048), Vector2(0.04, 0.042)], [manga, manga, manga.darkened(0.08)], 10)
	_malha(st, "_Braco", ombro)
	st = _st()
	if manto:
		# A manga larga do manto, aberta no punho.
		_tubo(st, [Vector3(0, 0, 0), Vector3(0, -0.25, 0)], [Vector2(0.075, 0.075), Vector2(0.1, 0.1)], [manga.darkened(0.1), manga.darkened(0.2)], 10)
	else:
		_tubo(st, [Vector3(0, 0, 0), Vector3(0, -0.13, -0.005), Vector3(0, -0.24, 0)], [Vector2(0.04, 0.042), Vector2(0.038, 0.04), Vector2(0.032, 0.033)], [manga.darkened(0.08), manga, manga], 10)
		# O punho da camisa.
		_tubo(st, [Vector3(0, -0.225, 0), Vector3(0, -0.255, 0)], [Vector2(0.036, 0.037), Vector2(0.036, 0.037)], [camisa.lightened(0.05), camisa.lightened(0.05)], 10)
	_mao(st, Vector3(0, -0.26, 0), lado)
	_malha(st, "_Antebraco", cotovelo)
	# A pose.
	match pose:
		Pose.PARADO:
			ombro.rotation = Vector3(0.05, 0, lado * 0.08)
			cotovelo.rotation = Vector3(0.18, 0, 0)
		Pose.MAO_NA_PORTA:
			if lado < 0:
				# O braço esquerdo para a frente e para cima, a mão na borda da porta.
				ombro.rotation = Vector3(1.05, -0.25, lado * 0.15)
				cotovelo.rotation = Vector3(0.75, 0, 0)
			else:
				ombro.rotation = Vector3(0.05, 0, lado * 0.08)
				cotovelo.rotation = Vector3(0.2, 0, 0)
		Pose.MAOS_JUNTAS:
			# As mãos juntas diante da barriga, metidas nas mangas.
			ombro.rotation = Vector3(0.15, 0, lado * 0.04)
			cotovelo.rotation = Vector3(1.35, lado * 0.95, 0)


## A mão: a palma, quatro dedos um pouco curvos e o polegar.
func _mao(st: SurfaceTool, p: Vector3, lado: float) -> void:
	var palma := [p, p + Vector3(0, -0.085, -0.005)]
	_tubo(st, palma, [Vector2(0.033, 0.014), Vector2(0.036, 0.012)], [pele.darkened(0.05), pele], 8)
	for k in 4:
		var x := lerpf(-0.026, 0.026, k / 3.0) * -lado
		var comp := 0.06 if k == 1 or k == 2 else 0.05
		var b := p + Vector3(x, -0.085, -0.004)
		var m := b + Vector3(x * 0.1, -comp * 0.55, -0.01)
		var f := m + Vector3(0, -comp * 0.45, -0.014)
		_tubo(st, [b, m, f], [Vector2(0.0075, 0.0075), Vector2(0.0068, 0.0068), Vector2(0.006, 0.006)], [pele, pele, pele.lightened(0.05)], 5)
	var t0 := p + Vector3(-lado * 0.03, -0.03, -0.01)
	_tubo(st, [t0, t0 + Vector3(-lado * 0.018, -0.03, -0.016), t0 + Vector3(-lado * 0.022, -0.055, -0.024)], [Vector2(0.009, 0.009), Vector2(0.0078, 0.0078), Vector2(0.0068, 0.0068)], [pele, pele, pele], 5)


## Uma perna: a coxa e a canela nas calças com o vinco, e o sapato.
func _perna(raiz: Node3D, lado: float) -> void:
	var quadril := Node3D.new()
	quadril.name = "_Quadril%s" % ("E" if lado < 0 else "D")
	quadril.position = Vector3(lado * 0.09, 0.84, 0)
	raiz.add_child(quadril)
	var st := _st()
	var pts := [Vector3(0, 0.0, 0), Vector3(0, -0.4, -0.01), Vector3(0, -0.44, -0.01), Vector3(0, -0.8, 0.0)]
	_tubo(st, pts, [Vector2(0.078, 0.08), Vector2(0.06, 0.062), Vector2(0.058, 0.06), Vector2(0.052, 0.055)], [calca, calca.darkened(0.05), calca.darkened(0.05), calca.darkened(0.12)], 10)
	# O vinco, na frente: uma aresta clara.
	_tri(st, Vector3(0, -0.05, -0.081), Vector3(0, -0.78, -0.056), Vector3(0.004, -0.42, -0.064), calca.lightened(0.12), calca.lightened(0.1), calca.lightened(0.12), Vector3(0, -0.4, 0.1))
	# O sapato: a gáspea, a biqueira arredondada, o salto.
	var s0 := Vector3(0, -0.8, 0.0)
	_tubo(st, [s0 + Vector3(0, -0.01, 0.06), s0 + Vector3(0, -0.04, -0.02), s0 + Vector3(0, -0.06, -0.12), s0 + Vector3(0, -0.07, -0.16)],
		[Vector2(0.045, 0.04), Vector2(0.048, 0.05), Vector2(0.042, 0.03), Vector2(0.03, 0.018)], [SAPATO, SAPATO.lightened(0.08), SAPATO.lightened(0.12), SAPATO.lightened(0.15)], 8)
	_malha(st, "_Perna", quadril)


# --- Primitivas -------------------------------------------------------------------

## Um tubo pela poligonal `pts`, com seção elíptica (raios x lateral, y frontal)
## por ponto e uma cor por ponto; as pontas fechadas.
func _tubo(st: SurfaceTool, pts: Array, raios: Array, cores: Array, lados: int) -> void:
	var aneis: Array = []
	for k in pts.size():
		var dir: Vector3
		if k == 0:
			dir = (pts[1] as Vector3) - (pts[0] as Vector3)
		elif k == pts.size() - 1:
			dir = (pts[k] as Vector3) - (pts[k - 1] as Vector3)
		else:
			dir = (pts[k + 1] as Vector3) - (pts[k - 1] as Vector3)
		dir = dir.normalized()
		var lat := dir.cross(Vector3(0, 0, 1))
		if lat.length() < 0.1:
			lat = dir.cross(Vector3(1, 0, 0))
		lat = lat.normalized()
		var fre := lat.cross(dir).normalized()
		var r: Vector2 = raios[k]
		var fila: Array = []
		for i in lados + 1:
			var u := TAU * i / lados
			fila.append((pts[k] as Vector3) + lat * cos(u) * r.x + fre * sin(u) * r.y)
		aneis.append(fila)
	for k in pts.size() - 1:
		var eixo := ((pts[k] as Vector3) + (pts[k + 1] as Vector3)) * 0.5
		for i in lados:
			_tri(st, aneis[k][i], aneis[k + 1][i], aneis[k][i + 1], cores[k], cores[k + 1], cores[k], eixo)
			_tri(st, aneis[k][i + 1], aneis[k + 1][i], aneis[k + 1][i + 1], cores[k], cores[k + 1], cores[k + 1], eixo)
	for ponta in [0, pts.size() - 1]:
		var centro: Vector3 = pts[ponta]
		var fora: Vector3 = centro + (centro - (pts[1] as Vector3 if ponta == 0 else pts[ponta - 1] as Vector3)).normalized() * 0.001
		for i in lados:
			_tri(st, aneis[ponta][i], aneis[ponta][i + 1], fora, cores[ponta], cores[ponta], cores[ponta], centro - (fora - centro) * 50.0)


## Um disco elíptico (raios em x e y do plano) virado para `normal`.
func _disco(st: SurfaceTool, c: Vector3, raio: Vector3, normal: Vector3, cor: Color, lados: int) -> void:
	var lat := normal.cross(Vector3.UP)
	if lat.length() < 0.1:
		lat = normal.cross(Vector3.RIGHT)
	lat = lat.normalized()
	var cima := lat.cross(normal).normalized()
	var rx := raio.x if raio.x > 0.0 else raio.z
	var ry := raio.y
	for i in lados:
		var u0 := TAU * i / lados
		var u1 := TAU * (i + 1) / lados
		var a := c + lat * cos(u0) * rx + cima * sin(u0) * ry
		var b := c + lat * cos(u1) * rx + cima * sin(u1) * ry
		_tri(st, c + normal * 0.0005, a, b, cor, cor, cor, c - normal)


## Um triângulo com a face para longe de `dentro` e uma cor por vértice.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, dentro: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.dot((a + b + c) / 3.0 - dentro) > 0.0:
		var t := b
		b = c
		c = t
		var tc := cb
		cb = cc
		cc = tc
	for par: Array in [[a, ca], [b, cb], [c, cc]]:
		var v: Vector3 = par[0]
		st.set_color(par[1])
		st.set_uv(Vector2(v.x + v.z, v.y) * 3.0)
		st.add_vertex(v)
