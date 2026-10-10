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
## Provisório em primitivas com cor de vértice (o material PSX iluminado), feito
## em código; peças com nome "_" não vão para o .tscn. Um filho chamado `Modelo`
## (o .glb do artista) substitui tudo. A frente é o -Z; as asas batem sozinhas.

const COMPRIMENTO := 1.5
const ROSADO := Color(0.8, 0.5, 0.5)
const PLACA := Color(0.56, 0.31, 0.33)
const MEMBRANA := Color(0.48, 0.3, 0.33)
const ANTENA := Color(0.66, 0.4, 0.42)

## Segundos por batida de asa (0 = paradas, abertas).
@export var batida := 0.45:
	set(v):
		batida = v
## Quanto as asas sobem e descem (graus).
@export var amplitude := 38.0
## Asas recolhidas ao longo do corpo (de pé no chão, parado: playtest 9).
@export var recolhidas := false
## Silhueta: sem luz, quase preta (visto contra o céu, de noite).
@export var silhueta := false:
	set(v):
		silhueta = v
		_reconstruir()

var _asas: Array[Node3D] = []
var _pernas: Array[Node3D] = []
var _t := 0.0


func _ready() -> void:
	_reconstruir()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _asas.is_empty():
		return
	_t += delta
	var fase := sin(_t * TAU / batida) if batida > 0.0 else 0.0
	for i in _asas.size():
		var lado := -1.0 if i == 0 else 1.0
		if recolhidas:
			_asas[i].rotation = Vector3(deg_to_rad(8.0), lado * deg_to_rad(-20.0), lado * deg_to_rad(-78.0))
			continue
		_asas[i].rotation.z = lado * deg_to_rad(10.0 + amplitude * fase)
	for i in _pernas.size():
		_pernas[i].rotation.x = sin(_t * 5.3 + i * 1.7) * 0.12


func _reconstruir() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if String(c.name).begins_with("_"):
			remove_child(c)
			c.queue_free()
	_asas.clear()
	_pernas.clear()
	if has_node(^"Modelo"):
		return
	var mat := _material()

	# O corpo: segmentos de casca, mais largos no tórax, afinando para trás; as
	# placas mais escuras por cima. E a "cabeça": o elipsoide convoluto com as antenas.
	var corpo := SurfaceTool.new()
	corpo.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segmentos := [[-0.32, 0.17, 0.13], [-0.12, 0.2, 0.15], [0.08, 0.18, 0.13], [0.26, 0.14, 0.1], [0.42, 0.1, 0.07], [0.56, 0.06, 0.045]]
	for i in segmentos.size():
		var s: Array = segmentos[i]
		var largura: float = s[1]
		var altura: float = s[2]
		_elipsoide(corpo, Vector3(0, 0, s[0]), Vector3(largura, altura, 0.12), 7, 4, ROSADO, 0.0, i)
		_elipsoide(corpo, Vector3(0, altura * 0.45, s[0] - 0.01), Vector3(largura * 0.85, altura * 0.55, 0.11), 6, 3, PLACA, 0.0, i + 10)
	var cabeca := Vector3(0, 0.05, -0.56)
	var raio := Vector3(0.2, 0.17, 0.24)
	_elipsoide(corpo, cabeca, raio, 9, 6, ROSADO.lerp(PLACA, 0.3), 0.035, 77)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1931
	for k in 70:
		# Antenas curtas espalhadas pelo elipsoide (menos embaixo).
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 1), rng.randf_range(-1, 0.6)).normalized()
		var base := cabeca + dir * raio
		_espinho(corpo, base, dir, rng.randf_range(0.035, 0.07), 0.006, ANTENA)
	_malha(corpo, "_Corpo", mat, self)

	# Os vastos pares de asas membranosas (ou barbatanas dorsais), presas no
	# tórax por cima: um leque de costelas com a membrana entre elas.
	for lado in [-1.0, 1.0]:
		var pivo := Node3D.new()
		pivo.name = "_Asa%s" % ("E" if lado < 0 else "D")
		pivo.position = Vector3(lado * 0.1, 0.16, -0.12)
		add_child(pivo)
		var asa := SurfaceTool.new()
		asa.begin(Mesh.PRIMITIVE_TRIANGLES)
		_asa(asa, lado)
		_malha(asa, "_Membrana", mat, pivo)
		_asas.append(pivo)

	# Vários pares de membros articulados, por baixo do tórax, com pinças.
	for par in 3:
		for lado in [-1.0, 1.0]:
			var pivo := Node3D.new()
			pivo.name = "_Perna%d%s" % [par, "E" if lado < 0 else "D"]
			pivo.position = Vector3(lado * 0.12, -0.08, -0.3 + par * 0.2)
			add_child(pivo)
			var perna := SurfaceTool.new()
			perna.begin(Mesh.PRIMITIVE_TRIANGLES)
			var a := Vector3.ZERO
			var b := Vector3(lado * 0.22, -0.06, -0.04 + par * 0.03)
			var c := b + Vector3(lado * 0.14, -0.22, -0.08)
			var d := c + Vector3(lado * 0.04, -0.12, -0.1)
			for seg: Array in [[a, b, 0.024], [b, c, 0.018], [c, d, 0.012]]:
				_haste(perna, seg[0], seg[1], seg[2], ROSADO.lerp(PLACA, 0.5))
			# A pinça: dois dedos abertos na ponta.
			_haste(perna, d, d + Vector3(lado * 0.03, -0.02, -0.07), 0.008, PLACA)
			_haste(perna, d, d + Vector3(lado * -0.02, -0.04, -0.06), 0.008, PLACA)
			_malha(perna, "_Malha", mat, pivo)
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
	return mat


func _malha(st: SurfaceTool, nome: String, mat: Material, pai: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## Um elipsoide de poucos polígonos; `ruga` desloca os vértices para dentro e
## para fora (o "convoluto" da cabeça).
func _elipsoide(st: SurfaceTool, centro: Vector3, raio: Vector3, lados: int, aneis: int, cor: Color, ruga: float, semente: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var pontos: Array = []
	for j in aneis + 1:
		var fila: Array = []
		var v := PI * j / aneis
		for i in lados:
			var u := TAU * i / lados
			var n := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var r := 1.0 + (rng.randf_range(-1.0, 1.0) * ruga / maxf(raio.x, 0.01) if j > 0 and j < aneis else 0.0)
			fila.append(centro + n * raio * r)
		pontos.append(fila)
	for j in aneis:
		for i in lados:
			var a: Vector3 = pontos[j][i]
			var b: Vector3 = pontos[j][(i + 1) % lados]
			var c: Vector3 = pontos[j + 1][i]
			var d: Vector3 = pontos[j + 1][(i + 1) % lados]
			_tri(st, a, b, c, cor, centro)
			_tri(st, b, d, c, cor, centro)


## Uma haste de seção quadrada de `a` a `b` (um segmento de perna, um espinho).
func _haste(st: SurfaceTool, a: Vector3, b: Vector3, grossura: float, cor: Color) -> void:
	var eixo := (b - a).normalized()
	var lado := eixo.cross(Vector3.UP)
	if lado.length() < 0.01:
		lado = eixo.cross(Vector3.RIGHT)
	lado = lado.normalized() * grossura
	var cima := lado.cross(eixo).normalized() * grossura
	var cantos := [lado + cima, -lado + cima, -lado - cima, lado - cima]
	var meio := (a + b) * 0.5
	for i in 4:
		var p0: Vector3 = a + cantos[i]
		var p1: Vector3 = a + cantos[(i + 1) % 4]
		var q0: Vector3 = b + cantos[i] * 0.7
		var q1: Vector3 = b + cantos[(i + 1) % 4] * 0.7
		_tri(st, p0, p1, q0, cor, meio)
		_tri(st, p1, q1, q0, cor, meio)


## Uma antena curta: um espinho fino que afina até a ponta.
func _espinho(st: SurfaceTool, base: Vector3, dir: Vector3, comprimento: float, grossura: float, cor: Color) -> void:
	var lado := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized() * grossura
	var cima := lado.cross(dir).normalized() * grossura
	var ponta := base + dir * comprimento
	for par: Array in [[lado, cima], [cima, -lado], [-lado, -cima], [-cima, lado]]:
		_tri(st, base + par[0], base + par[1], ponta, cor, base - dir * 0.01)


## A asa: costelas que saem da raiz em leque e a membrana entre elas, dos dois
## lados (vista de cima e de baixo).
func _asa(st: SurfaceTool, lado: float) -> void:
	var raiz := Vector3.ZERO
	var pontas := [Vector3(lado * 0.55, 0.12, -0.42), Vector3(lado * 1.05, 0.1, -0.2), Vector3(lado * 1.25, 0.04, 0.12),
		Vector3(lado * 1.0, -0.02, 0.42), Vector3(lado * 0.55, -0.04, 0.58), Vector3(lado * 0.2, -0.02, 0.5)]
	for i in pontas.size() - 1:
		var a: Vector3 = pontas[i]
		var b: Vector3 = pontas[i + 1]
		# A borda entre duas costelas cede um pouco (o recorte da membrana).
		var meio := (a + b) * 0.5 * 0.86
		for tri: Array in [[raiz, a, meio], [raiz, meio, b]]:
			_tri(st, tri[0], tri[1], tri[2], MEMBRANA, Vector3(0, -1, 0))
			_tri(st, tri[0], tri[2], tri[1], MEMBRANA, Vector3(0, 1, 0))
	for p: Vector3 in pontas:
		_haste(st, raiz, p, 0.012, PLACA)


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
		st.set_uv(Vector2(v.x, v.z) * 2.0)
		st.add_vertex(v)
