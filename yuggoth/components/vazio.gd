class_name Vazio
extends Node3D
## O sonho estilhaçado (playtest 6: "os livros flutuando, as paredes quebradas e
## estilhaçadas, como as dimensões do desconhecido em Dishonored"). Num grupo de
## sonho dentro da sala: quando o sonho começa (o grupo aparece), as `paredes`
## (quads da Estrutura) somem e no lugar delas fica uma malha de estilhaços do
## mesmo material, com frestas escuras entre eles; perto das `brechas`, os
## estilhaços se soltam devagar, giram e boiam para fora, e o escuro aparece por
## trás. Lá longe, pedaços de prédio boiando; na sala, livros (alguns abertos,
## batendo as folhas) e papéis soltos flutuam. Acabado o sonho, as paredes voltam.
## Tudo é montado aqui, uma vez, determinístico pela `semente`; sem colisão (a da
## sala continua).

## Os quads de parede a estilhaçar (caminhos a partir da raiz da fase).
@export var paredes: PackedStringArray = []
## Onde a parede se rompe (global): quanto mais perto, mais o estilhaço se solta.
@export var brechas: PackedVector3Array = []
@export var raio_brecha := 1.6
## 0 a 1: o quanto se rompe (quanto se afasta, quanto gira).
@export_range(0.0, 1.0, 0.05) var intensidade := 1.0
## Abaixo disto (y global) a parede fica inteira: o lambri continua de pé.
@export var piso_firme := 1.05
@export var livros := 12
@export var papeis := 6
@export var destrocos := 12
@export var semente := 1
## Segundos até os estilhaços chegarem aonde boiam.
@export var abertura := 7.0

const TAMANHO_ESTILHACO := 0.55
const ESPESSURA := 0.09
const CORES_LIVRO := [Color(0.5, 0.13, 0.1), Color(0.16, 0.3, 0.18), Color(0.14, 0.17, 0.36),
	Color(0.42, 0.33, 0.2), Color(0.25, 0.12, 0.2), Color(0.55, 0.45, 0.3)]

var _montado := false
var _ativo := false
var _t := 0.0
## Cada peça que se move: [nó, posição de repouso, deslocamento final, giro final
## (euler), fase, giro contínuo (rad/s), oscila].
var _pecas: Array[Array] = []
var _escondidos: Dictionary[Node3D, bool] = {}


func _ready() -> void:
	_verificar.call_deferred()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENABLED, NOTIFICATION_VISIBILITY_CHANGED:
			_verificar.call_deferred()
		NOTIFICATION_DISABLED:
			_desativar()


func _exit_tree() -> void:
	_desativar()


func _verificar() -> void:
	if not is_inside_tree():
		return
	if is_visible_in_tree() and can_process():
		_ativar()
	else:
		_desativar()


func _ativar() -> void:
	if _ativo:
		return
	if not _montado:
		_montar()
	_ativo = true
	_t = 0.0
	for p in paredes:
		var n := _raiz().get_node_or_null(NodePath(p)) as Node3D
		if n:
			_escondidos[n] = n.visible
			n.visible = false
	_animar(0.0)


func _desativar() -> void:
	if not _ativo:
		return
	_ativo = false
	for n in _escondidos:
		if is_instance_valid(n):
			n.visible = _escondidos[n]
	_escondidos.clear()


func _raiz() -> Node:
	return owner if owner else get_tree().current_scene


func _process(delta: float) -> void:
	if not _ativo:
		return
	_t += delta
	_animar(_t)


func _animar(t: float) -> void:
	# Abrindo: tudo sai do lugar devagar, e só então flutua.
	var k := smoothstep(0.0, 1.0, clampf(t / abertura, 0.0, 1.0))
	for p in _pecas:
		var n: Node3D = p[0]
		var fase: float = p[4]
		var boia := Vector3(sin(t * 0.37 + fase), sin(t * 0.53 + fase * 1.7), cos(t * 0.29 + fase)) * float(p[6])
		n.position = p[1] + (p[2] as Vector3) * k + boia
		n.rotation = (p[3] as Vector3) * k + (p[5] as Vector3) * t


# --- Montagem ----------------------------------------------------------------

func _montar() -> void:
	_montado = true
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for p in paredes:
		var q := _raiz().get_node_or_null(NodePath(p)) as MeshInstance3D
		if q and q.mesh is QuadMesh:
			_estilhacar(q, rng)
	var centro := _centro_da_sala()
	for i in destrocos:
		_destroco(rng, centro)
	for i in livros:
		_livro(rng, centro, i)
	for i in papeis:
		_papel(rng, centro)


## O meio da sala: a média das paredes estilhaçadas (ou a origem do grupo).
func _centro_da_sala() -> Vector3:
	var c := Vector3.ZERO
	var n := 0
	for p in paredes:
		var q := _raiz().get_node_or_null(NodePath(p)) as Node3D
		if q:
			c += q.global_position
			n += 1
	return to_local(c / n) if n > 0 else Vector3(0, 1.5, 0)


## Um material de parede com a UV da própria malha (a do mundo escorregaria
## pelo estilhaço quando ele se mexe); a UV é a do lugar original na parede.
func _sem_uv_do_mundo(mat: Material) -> Material:
	if not mat is ShaderMaterial:
		return mat
	var m := (mat as ShaderMaterial).duplicate() as ShaderMaterial
	m.set_shader_parameter(&"world_uv", false)
	m.set_shader_parameter(&"uv_scale", Vector2.ONE)
	return m


## A UV que o psx_lit daria a um ponto do mundo com normal `n` (world_uv).
static func _uv_mundo(p: Vector3, n: Vector3, tiles: float) -> Vector2:
	var a := n.abs()
	var q := Vector2(p.z, p.y) if a.x > a.y and a.x > a.z else (Vector2(p.x, p.z) if a.y > a.z else Vector2(p.x, p.y))
	return Vector2(q.x, -q.y) * tiles


func _estilhacar(q: MeshInstance3D, rng: RandomNumberGenerator) -> void:
	var tam := (q.mesh as QuadMesh).size
	var base := q.material_override if q.material_override else q.mesh.surface_get_material(0)
	var tiles := 1.0
	if base is ShaderMaterial and (base as ShaderMaterial).get_shader_parameter(&"world_uv"):
		tiles = float((base as ShaderMaterial).get_shader_parameter(&"tiles_per_meter"))
	var mat := _sem_uv_do_mundo(base)
	var colunas := maxi(2, roundi(tam.x / TAMANHO_ESTILHACO))
	var linhas := maxi(2, roundi(tam.y / TAMANHO_ESTILHACO))
	# A grade com os nós de dentro fora do lugar: estilhaços irregulares.
	var grade: Array[PackedVector2Array] = []
	for j in linhas + 1:
		var linha := PackedVector2Array()
		for i in colunas + 1:
			var p := Vector2(-tam.x / 2 + tam.x * i / colunas, -tam.y / 2 + tam.y * j / linhas)
			if i > 0 and i < colunas and j > 0 and j < linhas:
				p += Vector2(rng.randf_range(-0.3, 0.3) * tam.x / colunas, rng.randf_range(-0.3, 0.3) * tam.y / linhas)
			linha.append(p)
		grade.append(linha)
	var gt := q.global_transform
	var fora := -gt.basis.z.normalized()
	for j in linhas:
		for i in colunas:
			var cantos := [grade[j][i], grade[j][i + 1], grade[j + 1][i + 1], grade[j + 1][i]]
			# Metade dos estilhaços parte a célula em dois triângulos.
			var pedacos := [cantos]
			if rng.randf() < 0.5:
				pedacos = [[cantos[0], cantos[1], cantos[2]], [cantos[0], cantos[2], cantos[3]]]
			for poly: Array in pedacos:
				_estilhaco(q, poly, gt, fora, mat, tiles, rng)


func _estilhaco(q: MeshInstance3D, poly: Array, gt: Transform3D, fora: Vector3, mat: Material, tiles: float, rng: RandomNumberGenerator) -> void:
	var meio := Vector2.ZERO
	for c: Vector2 in poly:
		meio += c / poly.size()
	var centro_mundo := gt * Vector3(meio.x, meio.y, 0)
	# Quanto se solta: perto de uma brecha, e acima do lambri.
	var k := 0.0
	for b in brechas:
		k = maxf(k, clampf(1.0 - centro_mundo.distance_to(b) / raio_brecha, 0.0, 1.0))
	k = pow(k, 1.2) * intensidade
	var na_parede := absf(fora.y) < 0.5
	if na_parede and centro_mundo.y < piso_firme:
		k = 0.0
	# No meio da brecha, o estilhaço já se foi: o escuro.
	if k > 0.82 and rng.randf() < 0.55:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal_mundo := gt.basis.z.normalized()
	# As frestas: cada estilhaço um pouco menor que a célula.
	var encolhe := 0.94 if k > 0.0 else 0.975
	var pts: Array[Vector3] = []
	for c: Vector2 in poly:
		var l := meio + (c - meio) * encolhe
		pts.append(Vector3(l.x - meio.x, l.y - meio.y, 0))
	var n := pts.size()
	var tras := Vector3(0, 0, -ESPESSURA)
	var cor_frente := Color(1, 1, 1)
	var cor_lado := Color(0.45, 0.42, 0.4)
	# A frente (para dentro da sala, +Z) com a UV de onde estava na parede.
	for i in range(1, n - 1):
		for v in [pts[0], pts[i + 1], pts[i]]:
			st.set_color(cor_frente)
			st.set_uv(_uv_mundo(gt * (v + Vector3(meio.x, meio.y, 0)), normal_mundo, tiles))
			st.add_vertex(v)
	# Os lados e o fundo (o reboco quebrado, mais escuro).
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		for v in [a, b, b + tras, a, b + tras, a + tras]:
			st.set_color(cor_lado)
			st.set_uv(Vector2(v.x + v.z, v.y) * tiles)
			st.add_vertex(v)
	for i in range(1, n - 1):
		for v in [pts[0] + tras, pts[i] + tras, pts[i + 1] + tras]:
			st.set_color(cor_lado * 0.7)
			st.set_uv(Vector2(v.x, v.y) * tiles)
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Estilhaco"
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)
	mi.global_transform = Transform3D(gt.basis.orthonormalized(), centro_mundo)
	var repouso := mi.position
	var desloca := to_local(centro_mundo + fora * (k * (1.6 + rng.randf() * 2.2))
		+ Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 1.0), rng.randf_range(-1, 1)) * k * 0.7) - repouso
	var base_rot := mi.rotation
	if k == 0.0:
		# Inteiro: não sai do lugar (só as frestas aparecem).
		_pecas.append([mi, repouso, Vector3.ZERO, base_rot, 0.0, Vector3.ZERO, 0.0])
		return
	var giro := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * deg_to_rad(55.0) * k
	var deriva := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.04 * k
	_pecas.append([mi, repouso, desloca, base_rot + giro, rng.randf() * TAU, deriva, 0.05 * k])


## Um pedaço de prédio boiando no escuro, longe da sala.
func _destroco(rng: RandomNumberGenerator, centro: Vector3) -> void:
	var mats := ["parede", "tijolo", "madeira_escura", "lambri", "pedra_lareira"]
	var mat := _sem_uv_do_mundo(load("res://art/materials/%s.tres" % mats[rng.randi() % mats.size()]))
	var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1.0), rng.randf_range(-1, 1)).normalized()
	if dir.length() < 0.1:
		dir = Vector3.UP
	var pos := centro + dir * rng.randf_range(5.0, 9.0)
	var tam := Vector3(rng.randf_range(0.4, 2.2), rng.randf_range(0.3, 1.6), rng.randf_range(0.15, 0.6))
	var caixa := BoxMesh.new()
	caixa.size = tam
	caixa.subdivide_width = int(tam.x / 0.5)
	caixa.subdivide_height = int(tam.y / 0.5)
	var mi := MeshInstance3D.new()
	mi.name = "Destroco"
	mi.mesh = caixa
	mi.material_override = mat
	add_child(mi)
	mi.position = pos
	# Já estão lá desde o começo do sonho (não se abrem com os estilhaços).
	var rot := Vector3(rng.randf(), rng.randf(), rng.randf()) * TAU
	mi.rotation = rot
	_pecas.append([mi, pos, Vector3.ZERO, rot, rng.randf() * TAU,
		Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.05, 0.25])


## Um livro flutuando na sala; um em três, aberto, batendo as folhas.
func _livro(rng: RandomNumberGenerator, centro: Vector3, i: int) -> void:
	var g := Node3D.new()
	g.name = "Livro"
	add_child(g)
	var capa := _sem_uv_do_mundo(load("res://art/materials/capa_livro.tres"))
	var papel := _sem_uv_do_mundo(load("res://art/materials/papel.tres"))
	var cor: Color = CORES_LIVRO[i % CORES_LIVRO.size()]
	var tam := Vector3(rng.randf_range(0.14, 0.2), rng.randf_range(0.2, 0.27), rng.randf_range(0.03, 0.06))
	var aberto := i % 3 == 0
	if aberto:
		for s in [-1, 1]:
			var metade := Node3D.new()
			metade.name = "Metade%d" % (s + 1)
			g.add_child(metade)
			metade.rotation.y = s * deg_to_rad(rng.randf_range(20.0, 40.0))
			var c := _caixa(Vector3(tam.x, tam.y, 0.008), capa, cor)
			metade.add_child(c)
			c.position = Vector3(s * tam.x / 2, 0, 0)
			var folhas := _caixa(Vector3(tam.x * 0.95, tam.y * 0.95, tam.z * 0.4), papel, Color(1, 1, 1))
			metade.add_child(folhas)
			folhas.position = Vector3(s * tam.x / 2, 0, tam.z * 0.2 + 0.004)
	else:
		g.add_child(_caixa(tam, capa, cor))
		var miolo := _caixa(Vector3(tam.x * 0.96, tam.y * 0.96, tam.z * 0.9), papel, Color(1, 1, 1))
		g.add_child(miolo)
		miolo.position = Vector3(0.006, 0, 0)
	var pos := centro + Vector3(rng.randf_range(-1.9, 1.9), rng.randf_range(-0.4, 1.0), rng.randf_range(-2.4, 2.4))
	pos.y = maxf(pos.y, centro.y - 0.3)
	g.position = pos
	var rot := Vector3(rng.randf(), rng.randf(), rng.randf()) * TAU
	g.rotation = rot
	# Os livros sobem da estante para o ar devagar, junto com a abertura.
	var desce := Vector3(0, -rng.randf_range(0.4, 0.9), 0)
	_pecas.append([g, pos + desce, -desce, rot, rng.randf() * TAU,
		Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.12, 0.12])
	if aberto:
		var bate := g.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		var m1 := g.get_child(0) as Node3D
		var m2 := g.get_child(1) as Node3D
		var a := rng.randf_range(0.9, 1.6)
		bate.tween_property(m1, ^"rotation:y", -deg_to_rad(70.0), a)
		bate.parallel().tween_property(m2, ^"rotation:y", deg_to_rad(70.0), a)
		bate.tween_property(m1, ^"rotation:y", -deg_to_rad(15.0), a)
		bate.parallel().tween_property(m2, ^"rotation:y", deg_to_rad(15.0), a)


## Uma folha solta, girando devagar no ar.
func _papel(rng: RandomNumberGenerator, centro: Vector3) -> void:
	var folha := _caixa(Vector3(0.21, 0.29, 0.002), _sem_uv_do_mundo(load("res://art/materials/papel.tres")), Color(1, 1, 1))
	folha.name = "Folha"
	add_child(folha)
	var pos := centro + Vector3(rng.randf_range(-2.0, 2.0), rng.randf_range(-0.2, 1.1), rng.randf_range(-2.4, 2.4))
	folha.position = pos
	var rot := Vector3(rng.randf(), rng.randf(), rng.randf()) * TAU
	_pecas.append([folha, pos, Vector3.ZERO, rot, rng.randf() * TAU,
		Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.3, 0.2])


func _caixa(tam: Vector3, mat: Material, cor: Color) -> MeshInstance3D:
	var caixa := BoxMesh.new()
	caixa.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = caixa
	mi.material_override = mat
	if cor != Color(1, 1, 1) and mat is ShaderMaterial:
		var m := (mat as ShaderMaterial).duplicate() as ShaderMaterial
		m.set_shader_parameter(&"albedo_color", cor)
		mi.material_override = m
	return mi
