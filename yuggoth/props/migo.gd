@tool
class_name Migo
extends Node3D
## Uma das criaturas (docs/PLANO_ESCRITORIO.md, Fase 3e: "o mi-go que passa na
## janela também deve ter o modelo 3D"). Do livro, cap. I: "coisas rosadas de
## uns cinco pés de comprimento; com corpos de crustáceo que traziam vastos pares
## de barbatanas dorsais ou asas membranosas e vários pares de membros
## articulados, e com uma espécie de elipsoide convoluto, coberto de uma
## multidão de antenas muito curtas, onde normalmente ficaria a cabeça."
##
## Playtest 11 ("terei que fazer os modelos dos mi-go para que fiquem realmente
## bons e impressionantes, a menos que você não tenha tentado muito"): refeito.
## - O corpo é uma casca em placas que se encaixam umas nas outras como as de um
##   camarão (cada placa mais larga na borda de trás, com o sulco escuro entre
##   elas), a crista de espinhos curtos no dorso, a barriga carnosa mais clara, a
##   cauda em leque.
## - A "cabeça" é um elipsoide convoluto de fato: dobras como as de um cérebro ou
##   de um coral (`_dobras`), escuras no fundo dos sulcos, e mais de cem antenas
##   curtas, curvas, de dois segmentos.
## - As asas são membranas de morcego esticadas em quatro dedos ósseos de três
##   falanges; a membrana se refaz a cada quadro (`_asa_malha`), então a asa
##   dobra de verdade — no bater (a ponta fica para trás na subida) e recolhida,
##   colada ao corpo.
## - Quatro pares de membros articulados (coxa, fêmur, tíbia, tarso), com as juntas
##   saltadas, garras nos de trás e pinças no par da frente, que segura coisas.
##
## Provisório feito em código, com cor de vértice (o material PSX iluminado);
## peças com nome "_" não vão para o .tscn. Um filho chamado `Modelo` (o .glb do
## artista) substitui tudo. A frente é o -Z; as asas batem sozinhas.

const COMPRIMENTO := 1.5
const CARNE := Color(0.95, 0.66, 0.6)
const CASCA := Color(0.5, 0.2, 0.22)
const SULCO := Color(0.1, 0.04, 0.05)
const MEMBRANA := Color(0.36, 0.17, 0.2)
const VEIA := Color(0.2, 0.07, 0.09)
const OSSO := Color(0.52, 0.3, 0.3)
const ANTENA := Color(0.72, 0.46, 0.46)
const GARRA := Color(0.18, 0.1, 0.1)

## Segundos por batida de asa (0 = paradas, abertas).
@export var batida := 0.45
## Quanto as asas sobem e descem (graus).
@export var amplitude := 38.0
## Asas recolhidas ao longo do corpo (de pé no chão, parado: playtest 9).
@export var recolhidas := false
## Silhueta: sem luz, quase preta (visto contra o céu, de noite).
@export var silhueta := false:
	set(v):
		silhueta = v
		_reconstruir()

var _asas: Array[MeshInstance3D] = []
var _pernas: Array[Node3D] = []
var _antenas: MeshInstance3D
var _mat: Material
var _t := 0.0
## Quanto a asa está recolhida agora (vai e vem devagar quando `recolhidas` muda).
var _recolher := 0.0


func _ready() -> void:
	_reconstruir()


func _process(delta: float) -> void:
	if _asas.is_empty():
		return
	_t += delta
	_recolher = move_toward(_recolher, 1.0 if recolhidas else 0.0, delta * 1.5)
	var fase := sin(_t * TAU / batida) if batida > 0.0 else 0.0
	for i in _asas.size():
		_asa_malha(_asas[i], -1.0 if i == 0 else 1.0, fase, _recolher)
	for i in _pernas.size():
		var p := _pernas[i]
		p.rotation.x = sin(_t * 4.1 + i * 1.3) * 0.08
		p.rotation.y = sin(_t * 2.7 + i * 2.1) * 0.06
	if _antenas:
		# As antenas tremem, todas juntas, como pelos ao vento.
		_antenas.rotation = Vector3(sin(_t * 9.0) * 0.015, 0.0, sin(_t * 7.3 + 1.0) * 0.015)


func _reconstruir() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if String(c.name).begins_with("_"):
			remove_child(c)
			c.queue_free()
	_asas.clear()
	_pernas.clear()
	_antenas = null
	if has_node(^"Modelo"):
		return
	_mat = _material()

	var corpo := SurfaceTool.new()
	corpo.begin(Mesh.PRIMITIVE_TRIANGLES)
	_carapaca(corpo)
	_malha(corpo, "_Corpo", self)

	# A cabeça: o elipsoide convoluto e, à parte (tremem), as antenas.
	var centro := Vector3(0, 0.06, -0.6)
	var raio := Vector3(0.24, 0.2, 0.28)
	var cabeca := SurfaceTool.new()
	cabeca.begin(Mesh.PRIMITIVE_TRIANGLES)
	_elipsoide_convoluto(cabeca, centro, raio)
	_malha(cabeca, "_Cabeca", self)
	var ant := SurfaceTool.new()
	ant.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1931
	for k in 140:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.35, 1), rng.randf_range(-1, 0.5)).normalized()
		var base := centro + dir * raio * (1.0 + 0.1 * _dobras(dir))
		var curva := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * 0.4
		_antena(ant, base, dir, rng.randf_range(0.03, 0.085), curva)
	_antenas = _malha(ant, "_Antenas", self)

	# As asas: refeitas a cada quadro (_asa_malha).
	for lado in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		mi.name = "_Asa%s" % ("E" if lado < 0 else "D")
		mi.mesh = ArrayMesh.new()
		mi.material_override = _mat
		mi.position = Vector3(lado * 0.14, 0.2, -0.2)
		add_child(mi)
		_asas.append(mi)
		_asa_malha(mi, lado, 0.0, 1.0 if recolhidas else 0.0)
	_recolher = 1.0 if recolhidas else 0.0

	# Quatro pares de membros articulados, por baixo, do tórax para trás.
	for par in 4:
		for lado in [-1.0, 1.0]:
			var pivo := Node3D.new()
			pivo.name = "_Perna%d%s" % [par, "E" if lado < 0 else "D"]
			pivo.position = Vector3(lado * 0.15, -0.1, -0.36 + par * 0.17)
			add_child(pivo)
			var perna := SurfaceTool.new()
			perna.begin(Mesh.PRIMITIVE_TRIANGLES)
			_membro(perna, lado, par)
			_malha(perna, "_Malha", pivo)
			_pernas.append(pivo)


func _material() -> Material:
	if silhueta:
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/psx_unlit.gdshader")
		m.set_shader_parameter(&"albedo_color", Color(0.05, 0.04, 0.05))
		m.set_shader_parameter(&"albedo_tex", load("res://art/textures/grao.png"))
		return m
	var mat := (load("res://art/materials/papel.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	mat.set_shader_parameter(&"world_uv", false)
	mat.set_shader_parameter(&"albedo_tex", load("res://art/textures/grao.png"))
	mat.set_shader_parameter(&"albedo_color", Color.WHITE)
	return mat


func _malha(st: SurfaceTool, nome: String, pai: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	mi.material_override = _mat
	pai.add_child(mi)
	return mi


# --- O corpo ----------------------------------------------------------------------

## A casca: um tubo ao longo de Z, da nuca à cauda, em placas que se encaixam.
## Cada placa vai de um anel apertado (a frente, por baixo da anterior) a um anel
## largo (a borda de trás, que cobre a seguinte); entre elas o sulco escuro. Em
## cima a casca, embaixo a carne; a crista de espinhos no dorso; o leque da cauda.
func _carapaca(st: SurfaceTool) -> void:
	const LADOS := 16
	# [z da frente da placa, largura, altura] — da nuca à cauda.
	var placas := [[-0.42, 0.2, 0.17], [-0.3, 0.25, 0.2], [-0.17, 0.27, 0.215], [-0.04, 0.265, 0.205],
		[0.08, 0.24, 0.185], [0.19, 0.21, 0.16], [0.29, 0.175, 0.13], [0.38, 0.14, 0.1], [0.46, 0.11, 0.078],
		[0.53, 0.085, 0.06], [0.59, 0.064, 0.045]]
	var anel := func(z: float, larg: float, alto: float, escala: float) -> Array:
		var pts: Array = []
		for i in LADOS + 1:
			var u := TAU * i / LADOS
			# A barriga mais chata que o dorso.
			var y := sin(u) * alto * (1.0 if sin(u) > 0.0 else 0.72)
			pts.append(Vector3(cos(u) * larg * escala, y * escala, z))
		return pts
	var cor_de := func(p: Vector3, alto: float, borda: float) -> Color:
		var dorso := clampf(p.y / maxf(alto, 0.01) * 1.4 + 0.3, 0.0, 1.0)
		return CARNE.lerp(CASCA, dorso).lerp(SULCO, borda)
	for k in placas.size():
		var pl: Array = placas[k]
		var z0: float = pl[0]
		var z1: float = placas[k + 1][0] + 0.025 if k + 1 < placas.size() else z0 + 0.06
		var larg: float = pl[1]
		var alto: float = pl[2]
		var frente: Array = anel.call(z0, larg, alto, 0.9)
		var meio: Array = anel.call(lerpf(z0, z1, 0.55), larg, alto, 1.0)
		var tras: Array = anel.call(z1, larg, alto, 1.04)
		var dentro: Array = anel.call(z1 + 0.004, larg, alto, 0.86)
		for i in LADOS:
			for faixa: Array in [[frente, meio, 0.35, 0.0], [meio, tras, 0.0, 0.25], [tras, dentro, 0.25, 0.9]]:
				var a: Vector3 = faixa[0][i]
				var b: Vector3 = faixa[0][i + 1]
				var c: Vector3 = faixa[1][i]
				var d: Vector3 = faixa[1][i + 1]
				var eixo := Vector3(0, 0, (a.z + c.z) * 0.5)
				_tri_c(st, a, c, b, [cor_de.call(a, alto, faixa[2]), cor_de.call(c, alto, faixa[3]), cor_de.call(b, alto, faixa[2])], eixo)
				_tri_c(st, b, c, d, [cor_de.call(b, alto, faixa[2]), cor_de.call(c, alto, faixa[3]), cor_de.call(d, alto, faixa[3])], eixo)
		# A crista: um espinho curto no alto de cada placa, e dois menores dos lados.
		var topo := Vector3(0, alto * 1.02, lerpf(z0, z1, 0.6))
		_espinho(st, topo, Vector3(0, 0.85, 0.5).normalized(), 0.05 * larg / 0.2, 0.012, CASCA.darkened(0.3))
		for s in [-1.0, 1.0]:
			var lado := Vector3(s * larg * 0.7, alto * 0.72, lerpf(z0, z1, 0.6))
			_espinho(st, lado, Vector3(s * 0.6, 0.7, 0.4).normalized(), 0.025, 0.007, CASCA.darkened(0.3))
	# A nuca, fechando a frente da casca por baixo da cabeça.
	var nuca: Array = anel.call(-0.42, 0.2, 0.17, 0.9)
	for i in LADOS:
		_tri_c(st, nuca[i], nuca[i + 1], Vector3(0, 0, -0.46), [CARNE, CARNE, CARNE.darkened(0.2)], Vector3(0, 0, -0.3))
	# O leque da cauda: cinco lâminas abertas, como a de um camarão.
	var ponta := Vector3(0, 0.0, 0.66)
	for j in 5:
		var ang := deg_to_rad(-50.0 + j * 25.0)
		var dir := Vector3(sin(ang), -0.05, cos(ang))
		var lado := Vector3(cos(ang), 0, -sin(ang)) * 0.035
		var fim := ponta + dir * (0.16 if j == 2 else 0.13)
		for s in [1.0, -1.0]:
			_tri_c(st, ponta, fim + lado, fim - lado, [CASCA, CASCA.lerp(SULCO, 0.4), CASCA.lerp(SULCO, 0.4)], ponta + Vector3(0, -s * 0.05, 0))


## As dobras do elipsoide (de -1 a 1) na direção `n`: sulcos sinuosos que se
## cruzam, como as circunvoluções de um cérebro.
static func _dobras(n: Vector3) -> float:
	var a := sin(n.x * 9.0 + sin(n.y * 7.0) * 1.7 + n.z * 4.0)
	var b := sin(n.z * 11.0 + sin(n.x * 6.0) * 1.9 - n.y * 5.0)
	return clampf((a * b) * 1.4 + sin(n.y * 13.0 + n.x * 3.0) * 0.35, -1.0, 1.0)


## A cabeça: um elipsoide fino (muitos anéis) com as dobras — os sulcos fundos e
## escuros, as cristas claras.
func _elipsoide_convoluto(st: SurfaceTool, centro: Vector3, raio: Vector3) -> void:
	const LADOS := 22
	const ANEIS := 16
	var pts: Array = []
	var cores: Array = []
	for j in ANEIS + 1:
		var v := PI * j / ANEIS
		var fila: Array = []
		var fila_c: Array = []
		for i in LADOS:
			var u := TAU * i / LADOS
			var n := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var d := _dobras(n)
			fila.append(centro + n * raio * (1.0 + 0.11 * d))
			fila_c.append(SULCO.lerp(CARNE.lerp(CASCA, 0.25), smoothstep(-0.9, 0.6, d)))
		pts.append(fila)
		cores.append(fila_c)
	for j in ANEIS:
		for i in LADOS:
			var i2 := (i + 1) % LADOS
			_tri_c(st, pts[j][i], pts[j][i2], pts[j + 1][i], [cores[j][i], cores[j][i2], cores[j + 1][i]], centro)
			_tri_c(st, pts[j][i2], pts[j + 1][i2], pts[j + 1][i], [cores[j][i2], cores[j + 1][i2], cores[j + 1][i]], centro)


## Uma antena curta e curva: dois segmentos que afinam, a ponta mais clara.
func _antena(st: SurfaceTool, base: Vector3, dir: Vector3, comprimento: float, curva: Vector3) -> void:
	var meio := base + dir * comprimento * 0.55
	var dir2 := (dir + curva).normalized()
	var ponta := meio + dir2 * comprimento * 0.45
	_haste(st, base, meio, 0.0045, ANTENA.darkened(0.15), 0.6)
	_haste(st, meio, ponta, 0.0027, ANTENA, 0.2)


# --- As asas ----------------------------------------------------------------------

## Refaz a asa de um lado: quatro dedos ósseos de três falanges abertos em leque a
## partir do ombro, a membrana esticada entre eles (com a borda de fuga recortada
## entre as pontas) e presa ao flanco. `fase` -1..1 é o bater (embaixo..em cima);
## `recolher` 0..1 fecha o leque e cola a asa ao corpo.
func _asa_malha(mi: MeshInstance3D, lado: float, fase: float, recolher: float) -> void:
	# Cada dedo: [direção aberta (no plano da asa), comprimento das três falanges].
	var dedos := [[Vector3(0.55, 0.25, -0.8), [0.34, 0.32, 0.27]], [Vector3(1.0, 0.15, -0.25), [0.43, 0.4, 0.35]],
		[Vector3(1.0, 0.05, 0.3), [0.4, 0.37, 0.3]], [Vector3(0.65, -0.05, 0.9), [0.32, 0.27, 0.21]]]
	var subida := deg_to_rad(10.0 + amplitude * fase) * (1.0 - recolher)
	# Na subida a ponta fica para trás (a asa dobra no punho); na descida, estica.
	var dobra := (0.35 + 0.25 * fase) * (1.0 - recolher) + 1.25 * recolher
	var rot := Basis(Vector3(0, 0, 1), lado * subida)
	var pontos: Array = []
	for d: Array in dedos:
		var aberta: Vector3 = d[0]
		var dir := Vector3(lado * aberta.x, aberta.y, aberta.z).normalized()
		# Recolhida: os dedos se juntam apontando para trás, rente ao flanco.
		dir = dir.lerp(Vector3(lado * 0.18, -0.25, 1.0).normalized(), recolher).normalized()
		var p := Vector3.ZERO
		var fila: Array = [p]
		var falanges: Array = d[1]
		for f in falanges.size():
			var curva := Basis(Vector3(0, 1, 0), lado * -dobra * (0.25 + 0.3 * f)).rotated(Vector3(0, 0, 1), lado * -0.18 * f * (1.0 - recolher))
			p += rot * (curva * dir) * float(falanges[f]) * (1.0 - 0.25 * recolher)
			fila.append(p)
		pontos.append(fila)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A membrana entre dedos vizinhos: por falange, um quad; a borda de fuga cede.
	for k in pontos.size() - 1:
		var a: Array = pontos[k]
		var b: Array = pontos[k + 1]
		for f in 3:
			var a0: Vector3 = a[f]
			var a1: Vector3 = a[f + 1]
			var b0: Vector3 = b[f]
			var b1: Vector3 = b[f + 1]
			if f == 2:
				# O recorte entre as pontas: a membrana não chega até a ponta.
				var meio := (a1 + b1) * 0.5
				meio = meio.lerp((a0 + b0) * 0.5, 0.45)
				_membrana(st, a0, a1, meio, b0, lado)
				_membrana(st, b0, meio, b1, b1, lado)
			else:
				_membrana(st, a0, a1, b1, b0, lado)
	# A membrana do último dedo até o flanco (presa ao corpo até o meio dele).
	var ult: Array = pontos[pontos.size() - 1]
	var flanco := [Vector3(0, -0.04, 0.18), Vector3(lado * -0.04, -0.08, 0.42)]
	_membrana(st, ult[0], ult[1], flanco[0], flanco[0], lado)
	_membrana(st, ult[1], ult[2], flanco[1], flanco[0], lado)
	# Os ossos dos dedos, com os nós das juntas.
	for fila: Array in pontos:
		for f in 3:
			_haste(st, fila[f], fila[f + 1], 0.014 - f * 0.003, OSSO, 0.75)
		_espinho(st, fila[3], (fila[3] - fila[2]).normalized(), 0.04, 0.006, GARRA)
	mi.mesh = st.commit()


## Um pedaço de membrana (quad a-b-c-d), dos dois lados, com uma veia mais escura
## perto do osso.
func _membrana(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, _lado: float) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-10:
		n = (c - a).cross(d - a)
	n = n.normalized() * 0.1
	var centro := (a + b + c + d) * 0.25
	for s: float in [1.0, -1.0]:
		var dentro: Vector3 = centro + n * s
		_tri_c(st, a, b, c, [VEIA, VEIA, MEMBRANA], dentro)
		if not d.is_equal_approx(c):
			_tri_c(st, a, c, d, [VEIA, MEMBRANA, MEMBRANA], dentro)


# --- Os membros -------------------------------------------------------------------

## Um membro articulado: coxa, fêmur, tíbia e tarso, cada um afinando, com o nó da
## junta; o par da frente acaba numa pinça grande (segura coisas), os outros numa
## garra.
func _membro(st: SurfaceTool, lado: float, par: int) -> void:
	var frente := par == 0
	var abre := 0.2 + par * 0.06
	# Abertas para os lados e baixas, como as de um caranguejo.
	var pts := [Vector3.ZERO,
		Vector3(lado * 0.1, 0.0, 0.0),
		Vector3(lado * (0.27 + abre * 0.15), 0.07, -0.05 + par * 0.03),
		Vector3(lado * (0.4 + abre * 0.2), -0.1, -0.09 + par * 0.05),
		Vector3(lado * (0.46 + abre * 0.2), -0.26, -0.12 + par * 0.06)]
	if frente:
		# O par da frente vem para diante, dobrado, como quem carrega.
		pts = [Vector3.ZERO, Vector3(lado * 0.08, 0.0, -0.06), Vector3(lado * 0.22, 0.04, -0.26),
			Vector3(lado * 0.2, -0.14, -0.42), Vector3(lado * 0.12, -0.16, -0.56)]
	var grossuras := [0.045, 0.038, 0.029, 0.019]
	for i in 4:
		var cor := CASCA.lerp(CARNE, 0.35 if i % 2 == 0 else 0.1)
		_haste(st, pts[i], pts[i + 1], grossuras[i], cor, 0.7)
		if i > 0:
			_no_junta(st, pts[i], grossuras[i - 1] * 1.25, CASCA.lerp(SULCO, 0.25))
	var fim: Vector3 = pts[4]
	var dir: Vector3 = (fim - (pts[3] as Vector3)).normalized()
	if frente:
		# A pinça: a palma inchada e os dois dedos, um deles curvo.
		_no_junta(st, fim, 0.03, CASCA)
		var lado_v: Vector3 = dir.cross(Vector3.UP).normalized()
		_haste(st, fim, fim + dir * 0.09 + lado_v * 0.025, 0.012, CASCA.darkened(0.2), 0.3)
		_haste(st, fim, fim + dir * 0.08 - lado_v * 0.02 + Vector3(0, -0.02, 0), 0.01, CASCA.darkened(0.2), 0.3)
		_espinho(st, fim + dir * 0.09 + lado_v * 0.025, (dir - lado_v * 0.6).normalized(), 0.03, 0.006, GARRA)
	else:
		_espinho(st, fim, dir, 0.05, 0.009, GARRA)


## O nó de uma junta: um losango pequeno (oito faces).
func _no_junta(st: SurfaceTool, c: Vector3, r: float, cor: Color) -> void:
	var eixos := [Vector3(r, 0, 0), Vector3(-r, 0, 0), Vector3(0, r, 0), Vector3(0, -r, 0), Vector3(0, 0, r), Vector3(0, 0, -r)]
	for sx in [0, 1]:
		for sy in [2, 3]:
			for sz in [4, 5]:
				_tri_c(st, c + eixos[sx], c + eixos[sy], c + eixos[sz], [cor, cor, cor], c)


# --- Primitivas -------------------------------------------------------------------

## Uma haste de seção hexagonal de `a` a `b`, afinando para `fim` (fração da
## grossura) na ponta.
func _haste(st: SurfaceTool, a: Vector3, b: Vector3, grossura: float, cor: Color, fim := 0.7) -> void:
	var eixo := (b - a).normalized()
	var lado := eixo.cross(Vector3.UP)
	if lado.length() < 0.01:
		lado = eixo.cross(Vector3.RIGHT)
	lado = lado.normalized()
	var cima := lado.cross(eixo).normalized()
	var meio := (a + b) * 0.5
	const N := 6
	for i in N:
		var u0 := TAU * i / N
		var u1 := TAU * (i + 1) / N
		var c0 := (lado * cos(u0) + cima * sin(u0)) * grossura
		var c1 := (lado * cos(u1) + cima * sin(u1)) * grossura
		var escuro := cor.darkened(0.25 if sin(u0) < 0.0 else 0.0)
		_tri_c(st, a + c0, a + c1, b + c0 * fim, [escuro, escuro, cor], meio)
		_tri_c(st, a + c1, b + c1 * fim, b + c0 * fim, [escuro, cor, cor], meio)


## Um espinho fino que afina até a ponta.
func _espinho(st: SurfaceTool, base: Vector3, dir: Vector3, comprimento: float, grossura: float, cor: Color) -> void:
	var lado := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized() * grossura
	var cima := lado.cross(dir).normalized() * grossura
	var ponta := base + dir * comprimento
	for par: Array in [[lado, cima], [cima, -lado], [-lado, -cima], [-cima, lado]]:
		_tri_c(st, base + par[0], base + par[1], ponta, [cor, cor, cor.lightened(0.15)], base - dir * 0.01)


## Um triângulo com a face para longe de `dentro` e uma cor por vértice.
func _tri_c(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, cores: Array, dentro: Vector3) -> void:
	var n := (b - a).cross(c - a)
	var ca: Color = cores[0]
	var cb: Color = cores[1]
	var cc: Color = cores[2]
	if n.dot((a + b + c) / 3.0 - dentro) > 0.0:
		var t := b
		b = c
		c = t
		var tc := cb
		cb = cc
		cc = tc
		n = -n
	n = -n.normalized()
	for par: Array in [[a, ca], [b, cb], [c, cc]]:
		var v: Vector3 = par[0]
		st.set_color(par[1])
		st.set_normal(n)
		st.set_uv(Vector2(v.x, v.z) * 2.0)
		st.add_vertex(v)
