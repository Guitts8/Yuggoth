@tool
class_name Cao
extends Node3D
## Um dos cães de Akeley (docs/PLANO_FAZENDA.md, F4): *"meus grandes cães
## policiais"* (cap. II) — pastores-alemães, os "cães policiais" da época. Uns 62
## cm na cernelha; a sela preta sobre o lombo, o castanho nas patas, no peito e na
## cara, o focinho escuro; as orelhas em pé; a cauda farta, baixa.
##
## Provisório em primitivas com cor de vértice (o material PSX iluminado, facetado),
## feito em código, como o Migo; peças com nome "_" não vão para o .tscn. Um filho
## chamado `Modelo` (o .glb do artista) substitui tudo. A frente é o -Z; a origem
## no chão, entre as patas.
##
## A pose é procedural (`pose`, `andar`): as patas articuladas (ombro/quadril e
## joelho), o pescoço, a cabeça, a mandíbula, as orelhas e a cauda são pivôs.

enum Pose { PARADO, SENTADO, DEITADO, LATINDO, ROSNANDO, COMENDO }

const PRETO := Color(0.09, 0.075, 0.07)
const CASTANHO := Color(0.52, 0.36, 0.21)
const CLARO := Color(0.68, 0.53, 0.36)
const FOCINHO := Color(0.12, 0.09, 0.08)

@export var pose := Pose.PARADO
## 0 = parado; 1 = o passo; 2 ou mais = correndo (a pose de pé se anima).
@export_range(0.0, 3.0, 0.05) var andar := 0.0
## Para onde a cabeça olha (graus, em torno da vertical; + para a esquerda).
@export_range(-70.0, 70.0) var olhar := 0.0
## O salto (Yautja por cima da tela, playtest 12): 0 = no chão; 1 = no ar, as
## patas da frente estendidas para a frente e as de trás para trás. `salto_inclina`
## é o corpo: + o focinho para cima (a partida), - para baixo (a chegada).
var salto := 0.0
var salto_inclina := 0.0
## Abanando o rabo (0 a 1): esperando a ração com o balde à vista, comendo.
var abana := 0.0
## Variação de cor (cada cão um pouco diferente): mais preto ou mais castanho.
@export_range(-1.0, 1.0) var pelagem := 0.0:
	set(v):
		pelagem = v
		_reconstruir()
## Escala do cão (os machos maiores).
@export_range(0.85, 1.15) var porte := 1.0:
	set(v):
		porte = v
		scale = Vector3.ONE * v

var _t := 0.0
## Segundos desde o último latido (latir()): a mandíbula abre e fecha com ele.
var _desde_latido := 9.0
var _corpo: Node3D
var _pescoco: Node3D
var _cabeca: Node3D
var _mandibula: Node3D
var _cauda: Node3D
var _orelhas: Array[Node3D] = []
## [ombro/quadril, joelho] de cada pata: FE, FD, TE, TD.
var _patas: Array = []
## O quanto cada pose já entrou (transições suaves).
var _peso: Dictionary = {}
var _semente := 0


func _ready() -> void:
	_semente = hash(name)
	_t = float(_semente % 1000) * 0.013
	_reconstruir()


func _process(delta: float) -> void:
	if _corpo == null:
		return
	_t += delta
	_desde_latido += delta
	for p in Pose.values():
		_peso[p] = move_toward(float(_peso.get(p, 1.0 if p == pose else 0.0)), 1.0 if p == pose else 0.0, delta * 2.5)
	_animar()


func _reconstruir() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if String(c.name).begins_with("_"):
			remove_child(c)
			c.queue_free()
	_patas.clear()
	_orelhas.clear()
	_corpo = null
	if has_node(^"Modelo"):
		return
	var mat := _material()
	var preto := PRETO.lerp(CASTANHO, clampf(-pelagem, 0.0, 1.0) * 0.35)
	var castanho := CASTANHO.lerp(PRETO, clampf(pelagem, 0.0, 1.0) * 0.3)

	# O corpo (o pivô no quadril, para sentar girando em volta dele).
	_corpo = _no(self, "_Corpo", Vector3(0, 0.47, 0.27))
	var st := _st()
	# O tronco: anéis elípticos do peito à garupa (y, raio x, raio y), o peito
	# fundo, a cintura recolhida. A sela preta por cima; o castanho embaixo.
	var aneis := [[-0.38, 0.0, 0.07, 0.09], [-0.33, 0.0, 0.11, 0.14], [-0.2, -0.01, 0.135, 0.17], [-0.04, 0.0, 0.125, 0.14],
		[0.1, 0.02, 0.105, 0.105], [0.24, 0.01, 0.115, 0.12], [0.34, -0.01, 0.1, 0.1], [0.4, -0.03, 0.05, 0.06]]
	var lados := 10
	var pontos: Array = []
	for a: Array in aneis:
		var fila: Array = []
		for i in lados:
			var u := TAU * i / lados
			fila.append(Vector3(cos(u) * a[2], a[1] + sin(u) * a[3], a[0] - 0.27))
		pontos.append(fila)
	for j in pontos.size() - 1:
		for i in lados:
			var a: Vector3 = pontos[j][i]
			var b: Vector3 = pontos[j][(i + 1) % lados]
			var c: Vector3 = pontos[j + 1][i]
			var d: Vector3 = pontos[j + 1][(i + 1) % lados]
			var meio := Vector3(0, (a.y + d.y) * 0.5 * 0.2, (a.z + d.z) * 0.5)
			var alto := (a.y + b.y + c.y + d.y) * 0.25
			# A sela: a metade de cima do lombo, do ombro à anca.
			var cor := preto if alto > 0.03 and a.z > -0.62 else castanho
			if alto < -0.08:
				cor = CLARO
			_quad(st, a, b, d, c, cor, meio)
	# As tampas do peito e da garupa.
	for j: int in [0, pontos.size() - 1]:
		var centro := Vector3(0, aneis[j][1], aneis[j][0] - 0.27)
		for i in lados:
			_tri(st, pontos[j][i], pontos[j][(i + 1) % lados], centro, castanho if j == 0 else preto, centro + Vector3(0, 0, 0.1 if j == 0 else -0.1))
	_malha(st, "_Tronco", mat, _corpo)

	# O pescoço e a cabeça (pivô na base do pescoço, sobre o peito).
	_pescoco = _no(_corpo, "_Pescoco", Vector3(0, 0.06, -0.6))
	st = _st()
	_tronco_de_cone(st, Vector3.ZERO, Vector3(0, 0.16, -0.12), 0.085, 0.065, 8, preto, castanho)
	_malha(st, "_Malha", mat, _pescoco)
	_cabeca = _no(_pescoco, "_Cabeca", Vector3(0, 0.17, -0.13))
	st = _st()
	# O crânio, as bochechas castanhas, o focinho comprido e escuro, o nariz.
	_elipsoide(st, Vector3(0, 0.02, -0.03), Vector3(0.075, 0.068, 0.085), 8, 5, castanho, preto, 0.02)
	_tronco_de_cone(st, Vector3(0, 0.0, -0.08), Vector3(0, -0.015, -0.22), 0.05, 0.03, 7, FOCINHO, FOCINHO.lerp(castanho, 0.4))
	_elipsoide(st, Vector3(0, -0.006, -0.225), Vector3(0.022, 0.018, 0.016), 6, 3, Color(0.03, 0.03, 0.03), Color(0.03, 0.03, 0.03), 0.0)
	# Os olhos, escuros, sob a testa.
	for lado in [-1.0, 1.0]:
		_elipsoide(st, Vector3(lado * 0.045, 0.035, -0.09), Vector3(0.012, 0.01, 0.008), 5, 3, Color(0.05, 0.035, 0.02), Color(0.05, 0.035, 0.02), 0.0)
	_malha(st, "_Malha", mat, _cabeca)
	# A mandíbula (abre para latir e rosnar).
	_mandibula = _no(_cabeca, "_Mandibula", Vector3(0, -0.03, -0.07))
	st = _st()
	_tronco_de_cone(st, Vector3.ZERO, Vector3(0, -0.005, -0.13), 0.035, 0.02, 6, FOCINHO.lerp(castanho, 0.3), FOCINHO)
	_malha(st, "_Malha", mat, _mandibula)
	# As orelhas, em pé, pontudas, a ponta mais escura.
	for lado in [-1.0, 1.0]:
		var o := _no(_cabeca, "_Orelha%s" % ("E" if lado < 0 else "D"), Vector3(lado * 0.045, 0.07, -0.015))
		o.rotation.z = lado * -0.18
		st = _st()
		var base := [Vector3(-0.028, 0, 0.012), Vector3(0.028, 0, 0.012), Vector3(0, 0, -0.02)]
		var ponta := Vector3(0, 0.1, 0.005)
		for i in 3:
			_tri(st, base[i], base[(i + 1) % 3], ponta, castanho.lerp(preto, 0.5), Vector3(0, 0.03, 0))
		_malha(st, "_Malha", mat, o)
		_orelhas.append(o)

	# A cauda farta, baixa, com a curva no fim (pivô na garupa).
	_cauda = _no(_corpo, "_Cauda", Vector3(0, -0.02, 0.12))
	st = _st()
	var segs := [[Vector3.ZERO, 0.04], [Vector3(0, -0.12, 0.1), 0.05], [Vector3(0, -0.26, 0.15), 0.045], [Vector3(0, -0.36, 0.2), 0.025]]
	for i in segs.size() - 1:
		_tronco_de_cone(st, segs[i][0], segs[i + 1][0], segs[i][1], segs[i + 1][1], 6, preto, castanho)
	_malha(st, "_Malha", mat, _cauda)

	# As patas: a de cima (do ombro/quadril ao joelho) e a de baixo (ao pé).
	for k in 4:
		var frente := k < 2
		var lado := -1.0 if k % 2 == 0 else 1.0
		var ombro := _no(_corpo, "_Pata%d" % k, Vector3(lado * 0.075, -0.03, -0.53 if frente else -0.01))
		st = _st()
		var joelho := Vector3(0, -0.2, 0.02) if frente else Vector3(0, -0.2, 0.08)
		_tronco_de_cone(st, Vector3(0, 0.04, 0), joelho, 0.06 if frente else 0.075, 0.035, 6, castanho if frente else preto.lerp(castanho, 0.5), castanho)
		_malha(st, "_Malha", mat, ombro)
		var baixo := _no(ombro, "_Baixo", joelho)
		st = _st()
		var pe := Vector3(0, -0.24, -0.01) if frente else Vector3(0, -0.22, -0.06)
		_tronco_de_cone(st, Vector3.ZERO, pe, 0.032, 0.026, 6, castanho, CLARO)
		_elipsoide(st, pe + Vector3(0, 0.0, -0.025), Vector3(0.032, 0.02, 0.045), 6, 3, CLARO, castanho, 0.0)
		_malha(st, "_Malha", mat, baixo)
		_patas.append([ombro, baixo])
	_animar()


## Um latido: a cabeça dá um tranco para cima e a mandíbula abre e fecha (quem
## toca o som é quem chama: CaoIA). Sem chamadas, a pose LATINDO só ergue a cabeça.
func latir() -> void:
	_desde_latido = 0.0


## A pose de agora, misturando as poses pelo peso de cada uma (as transições).
func _animar() -> void:
	if _corpo == null:
		return
	var p := func(x: int) -> float: return float(_peso.get(x, 1.0 if x == pose else 0.0))
	var sentado: float = p.call(Pose.SENTADO)
	var deitado: float = p.call(Pose.DEITADO)
	var latindo: float = p.call(Pose.LATINDO)
	var rosnando: float = p.call(Pose.ROSNANDO)
	var comendo: float = p.call(Pose.COMENDO)
	var de_pe := 1.0 - maxf(sentado, deitado)
	var anda := andar * de_pe * (1.0 - comendo)
	var correndo := clampf(andar - 1.2, 0.0, 1.0) * de_pe

	# O passo: cada pata na sua fase (o passo em quatro tempos; correndo, as
	# diagonais juntas, o trote largo).
	var freq := lerpf(1.6, 2.6, correndo) * (0.6 + 0.4 * clampf(andar, 0.0, 1.0))
	var fase := _t * TAU * freq
	var fases := [0.25, 0.75, 0.0, 0.5] if correndo < 0.5 else [0.0, 0.5, 0.5, 0.0]
	var amp := lerpf(0.42, 0.75, correndo) * clampf(anda, 0.0, 1.0)
	for k in 4:
		var f: float = fase + fases[k] * TAU
		var cima: Node3D = _patas[k][0]
		var baixo: Node3D = _patas[k][1]
		var frente := k < 2
		var balanca := sin(f) * amp
		var dobra := maxf(0.0, -cos(f)) * amp * (1.1 if frente else -0.9)
		# Sentado: as de trás dobradas sob a garupa; deitado: todas dobradas, as da
		# frente estendidas para a frente.
		# (Sentado, o corpo gira para trás no quadril: as da frente compensam, para
		# ficar de pé no chão.)
		var rx_sent := -0.55 if frente else 1.25
		var rx_deit := 1.35 if frente else 1.4
		var bx_sent := 0.0 if frente else -2.1
		var bx_deit := 0.6 if frente else -2.4
		cima.rotation.x = balanca * de_pe * (1.0 - salto) + rx_sent * sentado + rx_deit * deitado - 0.08 * rosnando * (1.0 if frente else -1.0) \
			+ salto * (1.15 if frente else -1.05)
		baixo.rotation.x = dobra * de_pe * (1.0 - salto) + bx_sent * sentado + bx_deit * deitado + salto * (-0.35 if frente else 0.25)
	# O corpo: o balanço do passo; sentado, inclina para trás em volta do
	# quadril; deitado, desce até o chão.
	var bob := absf(sin(fase)) * 0.018 * anda * (1.0 + correndo)
	_corpo.position.y = 0.47 + bob - 0.06 * sentado - 0.31 * deitado - 0.04 * rosnando - 0.03 * comendo
	_corpo.rotation.x = 0.55 * sentado - 0.04 * comendo + sin(fase * 2.0) * 0.015 * anda + 0.4 * salto_inclina
	# A cabeça: olhando; latindo, erguida, a mandíbula batendo em rajadas;
	# rosnando, baixa e para a frente; comendo, no chão.
	# O latido: abre rápido, fecha em ~0,25 s.
	var latido := 0.0
	if _desde_latido < 0.28:
		latido = sin(_desde_latido / 0.28 * PI) if _desde_latido > 0.03 else _desde_latido / 0.03
	latindo = maxf(latindo, latido * 0.6)
	# (Sentado, o corpo já inclina 0,55 para trás: o pescoço desfaz quase tudo.)
	_pescoco.rotation.x = 0.18 * latindo - 0.35 * rosnando - 1.15 * comendo - 0.4 * sentado - 0.25 * deitado - 0.12 * correndo + sin(fase) * 0.04 * anda \
		+ comendo * (0.1 * sin(_t * TAU * 0.55) + 0.25 * maxf(0.0, sin(_t * 0.37 + _semente % 7) - 0.8) * 5.0) - 0.1 * salto
	_pescoco.rotation.y = deg_to_rad(olhar) * 0.5
	_cabeca.rotation.y = deg_to_rad(olhar) * 0.5
	_cabeca.rotation.x = 0.15 * latindo * latido + 0.12 * rosnando + 0.25 * deitado
	_mandibula.rotation.x = 0.55 * latido * latindo + (0.18 + 0.04 * sin(_t * 31.0)) * rosnando + absf(sin(_t * TAU * 1.6)) * 0.2 * comendo
	# As orelhas: em pé; deitam um pouco rosnando, giram para o som.
	for i in _orelhas.size():
		var lado := -1.0 if i == 0 else 1.0
		_orelhas[i].rotation.x = 0.55 * rosnando + 0.25 * deitado
		_orelhas[i].rotation.z = lado * (-0.18 - 0.2 * rosnando) + sin(_t * 0.9 + i * 2.0) * 0.04
	# A cauda: baixa, balança andando; rosnando, dura e reta; sentado, no chão.
	_cauda.rotation.x = 0.05 - 0.35 * rosnando + 0.6 * sentado + 0.45 * deitado - 0.25 * correndo
	# Abanando (a ração à vista, comendo): mais depressa, mais largo, a cauda mais alta.
	_cauda.rotation.x -= 0.25 * abana
	_cauda.rotation.z = sin(_t * TAU * (0.6 + anda + 2.2 * abana)) * (0.12 + 0.18 * anda + 0.3 * abana) * (1.0 - rosnando)


func _material() -> Material:
	var mat := (load("res://art/materials/papel.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	mat.set_shader_parameter(&"world_uv", false)
	mat.set_shader_parameter(&"albedo_tex", load("res://art/textures/grao.png"))
	mat.set_shader_parameter(&"albedo_color", Color.WHITE)
	return mat


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _no(pai: Node3D, nome: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = nome
	n.position = pos
	pai.add_child(n)
	return n


func _malha(st: SurfaceTool, nome: String, mat: Material, pai: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## Um tronco de cone de `a` a `b` (raios `ra`, `rb`); a metade de cima com
## `cor_cima`, a de baixo com `cor_baixo` (a sela e o ventre).
func _tronco_de_cone(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, lados: int, cor_cima: Color, cor_baixo: Color) -> void:
	var eixo := (b - a).normalized()
	var lado := eixo.cross(Vector3.UP)
	if lado.length() < 0.01:
		lado = eixo.cross(Vector3.FORWARD)
	lado = lado.normalized()
	var cima := lado.cross(eixo).normalized()
	if cima.y < 0.0:
		cima = -cima
	var meio := (a + b) * 0.5
	for i in lados:
		var u0 := TAU * i / lados
		var u1 := TAU * (i + 1) / lados
		var d0 := lado * cos(u0) + cima * sin(u0)
		var d1 := lado * cos(u1) + cima * sin(u1)
		var cor := cor_cima if sin((u0 + u1) * 0.5) > 0.0 else cor_baixo
		_quad(st, a + d0 * ra, a + d1 * ra, b + d1 * rb, b + d0 * rb, cor, meio)
	# As pontas fechadas.
	for par: Array in [[a, ra, -eixo], [b, rb, eixo]]:
		var c: Vector3 = par[0]
		for i in lados:
			var u0 := TAU * i / lados
			var u1 := TAU * (i + 1) / lados
			_tri(st, c + (lado * cos(u0) + cima * sin(u0)) * par[1], c + (lado * cos(u1) + cima * sin(u1)) * par[1], c, cor_baixo, c - par[2] * 0.05)


## Um elipsoide de poucos polígonos, `cor_cima` em cima, `cor_baixo` embaixo
## (quando y passa de `corte` acima do centro).
func _elipsoide(st: SurfaceTool, centro: Vector3, raio: Vector3, lados: int, aneis: int, cor_baixo: Color, cor_cima: Color, corte: float) -> void:
	var pontos: Array = []
	for j in aneis + 1:
		var fila: Array = []
		var v := PI * j / aneis
		for i in lados:
			var u := TAU * i / lados
			fila.append(centro + Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u)) * raio)
		pontos.append(fila)
	for j in aneis:
		for i in lados:
			var a: Vector3 = pontos[j][i]
			var b: Vector3 = pontos[j][(i + 1) % lados]
			var c: Vector3 = pontos[j + 1][i]
			var d: Vector3 = pontos[j + 1][(i + 1) % lados]
			var cor := cor_cima if (a.y + d.y) * 0.5 - centro.y > corte else cor_baixo
			_tri(st, a, b, c, cor, centro)
			_tri(st, b, d, c, cor, centro)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, cor: Color, dentro: Vector3) -> void:
	_tri(st, a, b, c, cor, dentro)
	_tri(st, a, c, d, cor, dentro)


## Um triângulo com a face para longe de `dentro` (a ordem certa para o cull).
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, cor: Color, dentro: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.dot((a + b + c) / 3.0 - dentro) > 0.0:
		var t := b
		b = c
		c = t
		n = -n
	n = -n.normalized()
	for v in [a, b, c]:
		st.set_color(cor)
		st.set_normal(n)
		st.set_uv(Vector2(v.x + v.y, v.z) * 3.0)
		st.add_vertex(v)
