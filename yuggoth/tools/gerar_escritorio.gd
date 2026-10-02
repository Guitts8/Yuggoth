extends Node
## Monta levels/escritorio/escritorio.tscn (planta aprovada em 2026-10-02) e os
## materiais em art/materials/. Rodar da pasta yuggoth/, depois de gerar_assets:
##   godot --headless --import
##   godot --headless res://tools/gerar_escritorio.tscn
## (É uma cena, não --script: os componentes precisam dos autoloads.)
##
## É um andaime: sobrescreve a cena e os materiais. Depois que a cena começar a
## ser editada à mão no editor, pare de rodar isto (ou porte a mudança para cá).
##
## Coordenadas: sala interna de x -2,5..2,5 (oeste..leste), z -3..3 (norte..sul),
## piso em y 0, teto em y 3. Norte = -Z, para onde o jogador olha sentado.

const OUT := "res://levels/escritorio/escritorio.tscn"
const MAT_DIR := "res://art/materials/"
const TEX_DIR := "res://art/textures/"
const SFX_DIR := "res://audio/placeholder/"

const W := 2.5  # meia largura
const D := 3.0  # meia profundidade
const H := 3.0  # pé-direito
## Janela norte (abertura na parede).
const JANELA_X := 0.8
const JANELA_Y := Vector2(0.9, 2.4)

var cena: Node3D
var m: Dictionary[String, Material] = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	_materiais()

	cena = Node3D.new()
	cena.name = "Escritorio"
	cena.set_script(load("res://levels/escritorio/escritorio.gd"))
	cena.set("env_1930", _env_1930())
	cena.set("env_dia", _env_dia())
	var ambientes: Array[Environment] = [null, cena.get("env_dia"), _env_entardecer(), _env_noite(), cena.get("env_dia")]
	cena.set("ambientes_dia", ambientes)
	cena.set("som_chuva", load(SFX_DIR + "chuva.wav"))
	cena.set("som_tarde", load(SFX_DIR + "tarde.wav"))
	cena.set("som_pena", load(SFX_DIR + "pena.wav"))
	cena.set("linha_abertura", load("res://narrative/narration/prologo_abertura.tres"))
	cena.set("linha_cartas", load("res://narrative/narration/prologo_cartas.tres"))
	var cartoes: Array[NarrationLine] = [null,
		load("res://narrative/narration/prologo_maio.tres"),
		load("res://narrative/narration/cartao_dia_2.tres"),
		load("res://narrative/narration/cartao_dia_3.tres"),
		load("res://narrative/narration/cartao_dia_4.tres"),
		load("res://narrative/narration/cartao_dia_5.tres")]
	cena.set("cartoes_dia", cartoes)
	var correio: Array[NarrationLine] = [null,
		load("res://narrative/narration/dia1_correio.tres"),
		load("res://narrative/narration/dia2_correio.tres"),
		load("res://narrative/narration/dia3_correio.tres"),
		load("res://narrative/narration/dia4_correio.tres")]
	cena.set("linhas_correio", correio)
	cena.set("linha_resposta_selada", load("res://narrative/narration/resposta_selada.tres"))

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = cena.get("env_1930")
	_add(cena, env)

	_estrutura()
	_mobilia()
	_gabinete_1930()
	_miskatonic()

	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector3(0, 0, -1.3)
	_add(cena, player)
	_spawn("Cadeira", Vector3(0, 0, -1.3))
	_spawn("Porta", Vector3(-1.0, 0, 2.3))

	var packed := PackedScene.new()
	var err := packed.pack(cena)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("gerar_escritorio: ", error_string(err))
	cena.free()
	get_tree().quit(0 if err == OK else 1)


# --- Materiais -----------------------------------------------------------------

func _materiais() -> void:
	_mat("parede", "papel_parede", {world = 1.3})
	_mat("piso", "assoalho", {world = 0.8})
	_mat("teto", "reboco", {world = 1.0})
	_mat("madeira_escura", "madeira_escura", {world = 2.0})
	_mat("madeira_clara", "madeira_clara", {world = 2.0})
	_mat("porta", "porta", {})
	_mat("tijolo", "tijolo", {world = 2.5})
	_mat("lombadas", "lombadas", {scale = Vector2(5, 1)})
	_mat("cortica", "cortica", {world = 2.0})
	_mat("tapete", "tapete", {})
	_mat("estofado", "estofado", {world = 3.0})
	_mat("lencol", "lencol", {world = 1.5})
	_mat("papel", "papel", {world = 4.0})
	_mat("latao", "latao", {world = 3.0})
	_mat("cinzas", "cinzas", {world = 2.0})
	_mat("caixa_cartas", "caixa_cartas", {world = 1.0 / 0.3})
	_mat("mostrador", "mostrador", {})
	_mat("ferro", "cinzas", {world = 4.0, cor = Color(0.5, 0.5, 0.55)})
	_mat("vista_noite", "vista_noite", {unlit = true})
	_mat("vista_dia", "vista_dia", {unlit = true})
	_mat("vista_entardecer", "vista_entardecer", {unlit = true})
	# Correspondência e fotografias (props/envelope.gd, props/fotografia.gd).
	_mat("envelope", "papel_envelope", {world = 6.0})
	_mat("selo", "selo_2c", {})
	_mat("carimbo", "carimbo", {})
	_mat("foto", "foto_pegada", {})
	_mat("cartao_foto", "papel_envelope", {world = 12.0, cor = Color(1.16, 1.14, 1.1)})
	_mat("vidro_aceso", "papel", {unlit = true, cor = Color(1.1, 0.85, 0.5)})


func _mat(name: String, tex: String, o: Dictionary) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/psx_unlit.gdshader" if o.get("unlit", false) else "res://shaders/psx_lit.gdshader")
	mat.set_shader_parameter(&"albedo_tex", load(TEX_DIR + tex + ".png"))
	if o.has("world"):
		mat.set_shader_parameter(&"world_uv", true)
		mat.set_shader_parameter(&"tiles_per_meter", o.world)
	if o.has("scale"):
		mat.set_shader_parameter(&"uv_scale", o.scale)
	if o.has("cor"):
		mat.set_shader_parameter(&"albedo_color", o.cor)
	var path := MAT_DIR + name + ".tres"
	ResourceSaver.save(mat, path, ResourceSaver.FLAG_CHANGE_PATH)
	m[name] = load(path)


func _env_1930() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.11, 0.115, 0.16)
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.02, 0.022, 0.03)
	e.fog_density = 1.0
	e.fog_depth_begin = 2.0
	e.fog_depth_end = 10.0
	return e


## Dia 3: noite no escritório (só o abajur e a lua).
func _env_noite() -> Environment:
	var e := _env_1930()
	e.ambient_light_color = Color(0.15, 0.14, 0.17)
	return e


## Dia 2: fim de tarde, mais escuro e alaranjado.
func _env_entardecer() -> Environment:
	var e := _env_dia()
	e.background_color = Color(0.5, 0.35, 0.3)
	e.ambient_light_color = Color(0.32, 0.25, 0.22)
	e.fog_light_color = Color(0.3, 0.2, 0.16)
	return e


func _env_dia() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.6, 0.66, 0.72)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.42)
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.5, 0.46, 0.4)
	e.fog_density = 0.6
	e.fog_depth_begin = 5.0
	e.fog_depth_end = 18.0
	return e


# --- Ajudantes -----------------------------------------------------------------

func _add(parent: Node, node: Node) -> Node:
	parent.add_child(node)
	node.owner = cena
	return node


func _group(parent: Node, name: String, pos := Vector3.ZERO, rot_y := 0.0) -> Node3D:
	var g := Node3D.new()
	g.name = name
	g.position = pos
	g.rotation_degrees.y = rot_y
	_add(parent, g)
	return g


## Caixa subdividida a cada ~0,5 m (afim e luz por vértice dependem disso).
func _box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.subdivide_width = int(size.x / 0.5)
	mesh.subdivide_height = int(size.y / 0.5)
	mesh.subdivide_depth = int(size.z / 0.5)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = m[mat]
	mi.position = pos
	_add(parent, mi)
	return mi


## Quad virado para +Z antes de `rot` (graus).
func _quad(parent: Node, name: String, size: Vector2, pos: Vector3, rot: Vector3, mat: String) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	mesh.subdivide_width = int(size.x / 0.5)
	mesh.subdivide_depth = int(size.y / 0.5)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = m[mat]
	mi.position = pos
	mi.rotation_degrees = rot
	_add(parent, mi)
	return mi


func _cyl(parent: Node, name: String, top: float, bottom: float, height: float, pos: Vector3, mat: String, sides := 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = m[mat]
	mi.position = pos
	_add(parent, mi)
	return mi


## Corpo estático com uma caixa de colisão por item: [tamanho, posição].
func _colisao(parent: Node, name: String, boxes: Array) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	_add(parent, body)
	for i in boxes.size():
		var shape := CollisionShape3D.new()
		shape.name = "Forma%d" % i
		var box := BoxShape3D.new()
		box.size = boxes[i][0]
		shape.shape = box
		shape.position = boxes[i][1]
		_add(body, shape)
	return body


## Área de interação com forma de caixa.
func _area(parent: Node, area: Area3D, name: String, size: Vector3, pos := Vector3.ZERO) -> Area3D:
	area.name = name
	area.position = pos
	_add(parent, area)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	_add(area, shape)
	return area


func _spawn(name: String, pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = name
	marker.position = pos
	_add(cena, marker)
	marker.add_to_group(&"spawn", true)


func _omni(parent: Node, name: String, pos: Vector3, cor: Color, energy: float, alcance: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = name
	l.position = pos
	l.light_color = cor
	l.light_energy = energy
	l.omni_range = alcance
	_add(parent, l)
	return l


# --- Estrutura (comum aos dois vestidos) ----------------------------------------

func _estrutura() -> void:
	var e := _group(cena, "Estrutura")
	_quad(e, "Piso", Vector2(2 * W, 2 * D), Vector3(0, 0, 0), Vector3(-90, 0, 0), "piso")
	_quad(e, "Teto", Vector2(2 * W, 2 * D), Vector3(0, H, 0), Vector3(90, 0, 0), "teto")
	_quad(e, "ParedeOeste", Vector2(2 * D, H), Vector3(-W, H / 2, 0), Vector3(0, 90, 0), "parede")
	_quad(e, "ParedeLeste", Vector2(2 * D, H), Vector3(W, H / 2, 0), Vector3(0, -90, 0), "parede")
	_quad(e, "ParedeSul", Vector2(2 * W, H), Vector3(0, H / 2, D), Vector3(0, 180, 0), "parede")
	# Norte em pedaços, com espessura, em volta da janela.
	var t := 0.2
	var lado := W - JANELA_X
	_box(e, "ParedeNorteO", Vector3(lado, H, t), Vector3(-JANELA_X - lado / 2, H / 2, -D - t / 2), "parede")
	_box(e, "ParedeNorteL", Vector3(lado, H, t), Vector3(JANELA_X + lado / 2, H / 2, -D - t / 2), "parede")
	_box(e, "ParedeNorteBaixo", Vector3(2 * JANELA_X, JANELA_Y.x, t), Vector3(0, JANELA_Y.x / 2, -D - t / 2), "parede")
	_box(e, "ParedeNorteAlto", Vector3(2 * JANELA_X, H - JANELA_Y.y, t), Vector3(0, (H + JANELA_Y.y) / 2, -D - t / 2), "parede")

	# Rodapé.
	var r := 0.12
	_box(e, "RodapeOeste", Vector3(0.03, r, 2 * D), Vector3(-W + 0.015, r / 2, 0), "madeira_escura")
	_box(e, "RodapeLeste", Vector3(0.03, r, 2 * D), Vector3(W - 0.015, r / 2, 0), "madeira_escura")
	_box(e, "RodapeSul", Vector3(2 * W, r, 0.03), Vector3(0, r / 2, D - 0.015), "madeira_escura")
	_box(e, "RodapeNorte", Vector3(2 * W, r, 0.03), Vector3(0, r / 2, -D + 0.015), "madeira_escura")

	# Janela: caixilho e travessas em cruz.
	var j := _group(e, "Janela", Vector3(0, 0, -D))
	_box(j, "Peitoril", Vector3(2 * JANELA_X + 0.2, 0.06, 0.26), Vector3(0, JANELA_Y.x, 0.02), "madeira_clara")
	_box(j, "Verga", Vector3(2 * JANELA_X + 0.1, 0.1, 0.14), Vector3(0, JANELA_Y.y + 0.05, -0.05), "madeira_clara")
	for s in [-1, 1]:
		_box(j, "Batente%s" % ("O" if s < 0 else "L"), Vector3(0.08, JANELA_Y.y - JANELA_Y.x, 0.14),
			Vector3(s * (JANELA_X + 0.02), (JANELA_Y.x + JANELA_Y.y) / 2, -0.05), "madeira_clara")
	_box(j, "TravessaV", Vector3(0.04, JANELA_Y.y - JANELA_Y.x, 0.04), Vector3(0, (JANELA_Y.x + JANELA_Y.y) / 2, -0.1), "madeira_clara")
	_box(j, "TravessaH", Vector3(2 * JANELA_X, 0.04, 0.04), Vector3(0, 1.7, -0.1), "madeira_clara")

	# Porta (sul, lado oeste) e relógio (sul, lado leste).
	var p := _group(e, "Porta", Vector3(-1.0, 0, D))
	_box(p, "Folha", Vector3(0.92, 2.1, 0.05), Vector3(0, 1.05, -0.03), "madeira_escura")
	_quad(p, "Frente", Vector2(0.92, 2.1), Vector3(0, 1.05, -0.06), Vector3(0, 180, 0), "porta")
	_box(p, "Macaneta", Vector3(0.05, 0.05, 0.06), Vector3(0.36, 1.0, -0.1), "latao")
	_box(p, "BatenteO", Vector3(0.08, 2.2, 0.06), Vector3(-0.5, 1.1, -0.03), "madeira_clara")
	_box(p, "BatenteL", Vector3(0.08, 2.2, 0.06), Vector3(0.5, 1.1, -0.03), "madeira_clara")
	_box(p, "BatenteAlto", Vector3(1.08, 0.08, 0.06), Vector3(0, 2.18, -0.03), "madeira_clara")

	var rel := _group(e, "Relogio", Vector3(1.2, 1.85, D))
	_box(rel, "Caixa", Vector3(0.36, 0.64, 0.12), Vector3(0, 0, -0.06), "madeira_escura")
	_quad(rel, "Mostrador", Vector2(0.26, 0.26), Vector3(0, 0.12, -0.125), Vector3(0, 180, 0), "mostrador")
	var hora := _box(rel, "PonteiroHora", Vector3(0.012, 0.07, 0.01), Vector3(-0.02, 0.15, -0.13), "ferro")
	hora.rotation_degrees.z = 50
	var minuto := _box(rel, "PonteiroMinuto", Vector3(0.01, 0.1, 0.01), Vector3(0.03, 0.16, -0.13), "ferro")
	minuto.rotation_degrees.z = -60
	_box(rel, "Pendulo", Vector3(0.05, 0.05, 0.01), Vector3(0, -0.2, -0.13), "latao")
	var tique := AudioStreamPlayer3D.new()
	tique.name = "Tique"
	tique.stream = load(SFX_DIR + "relogio.wav")
	tique.autoplay = true
	tique.bus = &"SFX"
	tique.volume_db = -12.0
	tique.unit_size = 2.0
	_add(rel, tique)

	_colisao(e, "Colisao", [
		[Vector3(2 * W, 0.2, 2 * D), Vector3(0, -0.1, 0)],
		[Vector3(2 * W, 0.2, 2 * D), Vector3(0, H + 0.1, 0)],
		[Vector3(0.2, H, 2 * D), Vector3(-W - 0.1, H / 2, 0)],
		[Vector3(0.2, H, 2 * D), Vector3(W + 0.1, H / 2, 0)],
		[Vector3(2 * W, H, 0.2), Vector3(0, H / 2, D + 0.1)],
		[Vector3(2 * W, H, 0.2), Vector3(0, H / 2, -D - 0.1)],
	])


# --- Mobília comum ---------------------------------------------------------------

func _mobilia() -> void:
	var mob := _group(cena, "Mobilia")
	_escrivaninha(mob)
	_cadeira(mob)
	_estante(mob)
	_lareira(mob)
	_poltrona(_group(mob, "Poltrona", Vector3(1.6, 0, 0.9), 90), "estofado")
	_quad(mob, "Tapete", Vector2(2.4, 1.8), Vector3(0, 0.006, 0.3), Vector3(-90, 0, 0), "tapete")
	var cab := _group(mob, "Cabideiro", Vector3(-2.1, 0, 2.6))
	_cyl(cab, "Haste", 0.02, 0.02, 1.8, Vector3(0, 0.9, 0), "madeira_escura", 6)
	_cyl(cab, "Pe", 0.02, 0.22, 0.08, Vector3(0, 0.04, 0), "madeira_escura", 6)
	for i in 3:
		var gancho := _box(cab, "Gancho%d" % i, Vector3(0.18, 0.02, 0.02), Vector3(0, 1.72, 0), "latao")
		gancho.rotation_degrees.y = i * 60


func _escrivaninha(parent: Node) -> void:
	var g := _group(parent, "Escrivaninha", Vector3(0, 0, -2.2))
	_box(g, "Tampo", Vector3(1.6, 0.06, 0.8), Vector3(0, 0.75, 0), "madeira_escura")
	for s in [-1, 1]:
		var lado := "O" if s < 0 else "L"
		_box(g, "Gaveteiro" + lado, Vector3(0.42, 0.72, 0.74), Vector3(s * 0.57, 0.36, 0), "madeira_escura")
		for k in 3:
			_box(g, "Puxador%s%d" % [lado, k], Vector3(0.08, 0.02, 0.02), Vector3(s * 0.57, 0.6 - k * 0.22, 0.38), "latao")
	_box(g, "Fundo", Vector3(0.72, 0.5, 0.03), Vector3(0, 0.47, -0.3), "madeira_escura")
	_colisao(g, "Colisao", [[Vector3(1.6, 0.78, 0.8), Vector3(0, 0.39, 0)]])


func _cadeira(parent: Node) -> void:
	# Sem colisão: o jogador começa sentado nela.
	var g := _group(parent, "Cadeira", Vector3(0, 0, -1.3))
	_box(g, "Assento", Vector3(0.46, 0.05, 0.44), Vector3(0, 0.46, 0), "madeira_clara")
	for x in [-0.2, 0.2]:
		for z in [-0.19, 0.19]:
			_box(g, "Perna%d%d" % [signf(x), signf(z)], Vector3(0.04, 0.46, 0.04), Vector3(x, 0.23, z), "madeira_clara")
	_box(g, "Encosto", Vector3(0.46, 0.42, 0.04), Vector3(0, 0.74, 0.2), "madeira_clara")


func _estante(parent: Node) -> void:
	# Parede oeste, metade norte. Uma prateleira tem um vão (esconderijo do Dia 5).
	var g := _group(parent, "Estante", Vector3(-W + 0.18, 0, -2.0))
	var alt := 2.3
	_box(g, "LadoN", Vector3(0.36, alt, 0.04), Vector3(0, alt / 2, -0.78), "madeira_escura")
	_box(g, "LadoS", Vector3(0.36, alt, 0.04), Vector3(0, alt / 2, 0.78), "madeira_escura")
	_box(g, "Fundo", Vector3(0.02, alt, 1.56), Vector3(-0.17, alt / 2, 0), "madeira_escura")
	var prateleiras := [0.06, 0.5, 0.94, 1.38, 1.82, alt - 0.02]
	for i in prateleiras.size():
		_box(g, "Prateleira%d" % i, Vector3(0.36, 0.04, 1.52), Vector3(0, prateleiras[i], 0), "madeira_escura")
	for i in 5:
		var y: float = prateleiras[i] + 0.02 + 0.17
		var largura := 1.5 if i != 2 else 1.05
		var z := 0.0 if i != 2 else -0.22
		_box(g, "Livros%d" % i, Vector3(0.24, 0.34, largura), Vector3(-0.04, y, z), "madeira_escura")
		_quad(g, "Lombadas%d" % i, Vector2(largura, 0.34), Vector3(0.081, y, z), Vector3(0, 90, 0), "lombadas")
	_colisao(g, "Colisao", [[Vector3(0.36, alt, 1.6), Vector3(0, alt / 2, 0)]])


func _lareira(parent: Node) -> void:
	# Parede leste. Abertura de 0,8 m; cinzas no fundo.
	var g := _group(parent, "Lareira", Vector3(W, 0, -0.6))
	var prof := 0.4
	_box(g, "PilarN", Vector3(prof, 0.85, 0.4), Vector3(-prof / 2, 0.425, -0.6), "tijolo")
	_box(g, "PilarS", Vector3(prof, 0.85, 0.4), Vector3(-prof / 2, 0.425, 0.6), "tijolo")
	_box(g, "Chamine", Vector3(prof, H - 0.85, 1.6), Vector3(-prof / 2, (H + 0.85) / 2, 0), "tijolo")
	_box(g, "FundoFogo", Vector3(0.05, 0.85, 0.8), Vector3(-0.03, 0.425, 0), "cinzas")
	_box(g, "Lareiro", Vector3(0.6, 0.05, 1.8), Vector3(-0.3, 0.025, 0), "tijolo")
	_box(g, "Cinzas", Vector3(0.3, 0.06, 0.5), Vector3(-0.2, 0.08, 0), "cinzas")
	_box(g, "Grelha", Vector3(0.3, 0.12, 0.55), Vector3(-0.22, 0.12, 0), "ferro")
	_box(g, "Consolo", Vector3(prof + 0.16, 0.08, 1.9), Vector3(-(prof + 0.16) / 2, 1.15, 0), "madeira_escura")
	for s in [-1, 1]:
		_cyl(g, "Castical%d" % s, 0.025, 0.04, 0.2, Vector3(-0.3, 1.29, s * 0.7), "latao", 6)
	_colisao(g, "Colisao", [[Vector3(0.7, H, 1.9), Vector3(-0.35, H / 2, 0)]])


## Poltrona olhando para -Z local (gire o grupo para orientar).
func _poltrona(g: Node3D, mat: String) -> void:
	_box(g, "Assento", Vector3(0.75, 0.42, 0.72), Vector3(0, 0.21, 0), mat)
	_box(g, "Encosto", Vector3(0.75, 0.9, 0.14), Vector3(0, 0.6, 0.33), mat)
	for s in [-1, 1]:
		_box(g, "Braco%d" % s, Vector3(0.12, 0.62, 0.72), Vector3(s * 0.38, 0.31, 0), mat)
	_colisao(g, "Colisao", [[Vector3(0.9, 1.0, 0.8), Vector3(0, 0.5, 0.05)]])


# --- Vestido: gabinete de casa, 1930, noite --------------------------------------

func _gabinete_1930() -> void:
	var g := _group(cena, "Gabinete1930")
	_quad(g, "Vista", Vector2(5.0, 3.0), Vector3(0, 1.6, -D - 1.2), Vector3.ZERO, "vista_noite")
	_chuva(g)

	# Escrivaninha: a caixa de cartas, a folha do relato, tinteiro e lamparina.
	# A caixa fica no centro de uma repetição da textura (barbante centrado).
	var caixa := _box(g, "Caixa", Vector3(0.32, 0.12, 0.24), Vector3(-0.45, 0.84, -2.25), "caixa_cartas")
	var exam := _area(caixa, Examinable.new(), "CaixaCartas", Vector3(0.4, 0.2, 0.32)) as Examinable
	exam.unique_name_in_owner = true
	exam.prompt = "Examinar"
	exam.title = "As cartas de Henry Akeley"
	exam.description = "Amarradas com barbante. O papel ainda cheira a terra úmida."
	exam.initial_rotation = Vector3(25, 20, 0)

	var folha := _box(g, "Folha", Vector3(0.24, 0.006, 0.32), Vector3(0.12, 0.783, -2.1), "papel")
	folha.rotation_degrees.y = -8
	var leitura := _area(folha, DocumentPickup.new(), "Ler", Vector3(0.3, 0.06, 0.36)) as DocumentPickup
	leitura.prompt = "Ler"
	leitura.take = false
	leitura.document = load("res://narrative/documents/relato_folha_1.tres")
	_cyl(g, "Tinteiro", 0.03, 0.035, 0.05, Vector3(0.36, 0.805, -2.32), "ferro", 6)
	var pena := _box(g, "Pena", Vector3(0.01, 0.01, 0.2), Vector3(0.3, 0.79, -2.12), "lencol")
	pena.rotation_degrees.y = 25

	var lamp := _group(g, "LamparinaMesa", Vector3(0.58, 0.78, -2.42))
	_cyl(lamp, "Base", 0.07, 0.08, 0.03, Vector3(0, 0.015, 0), "latao")
	_cyl(lamp, "Tanque", 0.06, 0.06, 0.08, Vector3(0, 0.07, 0), "latao")
	_cyl(lamp, "Chamine", 0.03, 0.04, 0.16, Vector3(0, 0.19, 0), "vidro_aceso", 6)
	_omni(lamp, "Luz", Vector3(0, 0.28, 0.1), Color(1.0, 0.72, 0.45), 1.8, 5.5)
	_omni(g, "LuzLua", Vector3(0, 2.0, -2.5), Color(0.5, 0.6, 0.9), 0.7, 6.0)

	# Canto sudoeste: poltrona coberta por lençol.
	var coberta := _group(g, "PoltronaCoberta", Vector3(-1.9, 0, 2.2), 135)
	_poltrona(coberta, "lencol")
	var caimento := _box(coberta, "Caimento", Vector3(0.9, 0.04, 0.85), Vector3(0, 0.96, 0.15), "lencol")
	caimento.rotation_degrees.x = 18

	var lareira := _area(g, StateInteractable.new(), "OlharLareira", Vector3(0.5, 0.8, 0.9), Vector3(W - 0.3, 0.45, -0.6)) as StateInteractable
	lareira.prompt = "Olhar"
	lareira.notice = "As cinzas estão frias. Não acendo a lareira desde que voltei."
	var janela := _area(g, StateInteractable.new(), "OlharJanela", Vector3(1.6, 1.5, 0.2), Vector3(0, 1.65, -D)) as StateInteractable
	janela.prompt = "Olhar"
	janela.notice = "Chove sobre Arkham desde o fim da tarde."


func _chuva(parent: Node) -> void:
	var p := GPUParticles3D.new()
	p.name = "Chuva"
	p.position = Vector3(0, 3.2, -D - 0.7)
	p.amount = 160
	p.lifetime = 0.7
	p.visibility_aabb = AABB(Vector3(-2, -4, -1), Vector3(4, 5, 2))
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = Vector3(1.8, 0.1, 0.4)
	proc.direction = Vector3(0.05, -1, 0)
	proc.spread = 2.0
	proc.initial_velocity_min = 6.0
	proc.initial_velocity_max = 7.5
	p.process_material = proc
	var quad := QuadMesh.new()
	quad.size = Vector2(0.015, 0.22)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.albedo_texture = load(TEX_DIR + "gota.png")
	mat.albedo_color = Color(0.55, 0.6, 0.75, 0.7)
	quad.material = mat
	p.draw_pass_1 = quad
	_add(parent, p)


# --- Vestido: escritório da Miskatonic, maio, tarde ---------------------------------

func _miskatonic() -> void:
	var g := _group(cena, "Miskatonic")

	# Quadro de cortiça na parede oeste, metade sul, com recortes.
	var q := _group(g, "QuadroCortica", Vector3(-W, 1.45, 0.7))
	_box(q, "Moldura", Vector3(0.04, 0.95, 1.45), Vector3(0.02, 0, 0), "madeira_clara")
	_quad(q, "Cortica", Vector2(1.35, 0.85), Vector3(0.045, 0, 0), Vector3(0, 90, 0), "cortica")
	var recortes := [[Vector2(0.22, 0.3), Vector2(-0.45, 0.15), 4], [Vector2(0.3, 0.2), Vector2(-0.1, 0.22), -3],
		[Vector2(0.18, 0.26), Vector2(0.25, 0.1), 6], [Vector2(0.26, 0.18), Vector2(0.45, -0.2), -5],
		[Vector2(0.2, 0.22), Vector2(-0.3, -0.22), 2]]
	var docs_recortes := ["recorte_reformer_enchentes", "recorte_herald_lendas", "recorte_reformer_pendrifter"]
	for i in recortes.size():
		var r: Array = recortes[i]
		var quad := _quad(q, "Recorte%d" % i, r[0], Vector3(0.05, r[1].y, r[1].x), Vector3(r[2], 90, 0), "papel")
		if i < docs_recortes.size():
			# Pregados no quadro: entram no dossiê, mas ficam onde estão.
			var leitura := _area(quad, DocumentPickup.new(), "Ler", Vector3(r[0].x, r[0].y, 0.06)) as DocumentPickup
			leitura.prompt = "Ler o recorte"
			leitura.remove_visual = false
			leitura.document = load("res://narrative/documents/%s.tres" % docs_recortes[i])

	# Escrivaninha (todos os dias): tinteiro, pena, mata-borrão.
	_cyl(g, "Tinteiro", 0.03, 0.035, 0.05, Vector3(0.36, 0.805, -2.32), "ferro", 6)
	var pena := _box(g, "Pena", Vector3(0.01, 0.01, 0.2), Vector3(0.3, 0.79, -2.12), "lencol")
	pena.rotation_degrees.y = 25
	_box(g, "MataBorrao", Vector3(0.5, 0.008, 0.36), Vector3(0.05, 0.784, -2.12), "estofado")

	_dias(g)

	# A porta encerra o dia ("ir para casa"); só no escritório.
	var sair := _area(g, Interactable.new(), "SairPorta", Vector3(0.9, 2.0, 0.2), Vector3(-1.0, 1.05, D - 0.12)) as Interactable
	sair.unique_name_in_owner = true
	sair.prompt = "Ir para casa"

	# Canto sudoeste: o armário. A máquina emprestada chega no Dia 3 (_fonografo).
	var a := _group(g, "Armario", Vector3(-2.15, 0, 2.35), 90)
	_box(a, "Movel", Vector3(0.8, 0.9, 0.5), Vector3(0, 0.45, 0), "madeira_escura")
	_box(a, "Juncao", Vector3(0.01, 0.8, 0.01), Vector3(0, 0.45, -0.255), "ferro")
	_colisao(a, "Colisao", [[Vector3(0.8, 0.9, 0.5), Vector3(0, 0.45, 0)]])


# --- Os dias --------------------------------------------------------------------

const MESA := 0.78  # altura do tampo da escrivaninha


func _cond_valor(chave: StringName, op: ValueCondition.Op, valor: float, negar := false) -> ValueCondition:
	var c := ValueCondition.new()
	c.key = chave
	c.op = op
	c.value = valor
	c.negate = negar
	return c


## Grupo que só existe enquanto `cond` vale (ConditionalNode dentro).
func _grupo_se(parent: Node, nome: String, cond: Condition) -> Node3D:
	var g := _group(parent, nome)
	var cn := ConditionalNode.new()
	cn.name = "ConditionalNode"
	cn.condition = cond
	_add(g, cn)
	return g


## Conteúdo que só existe num dia: um grupo com ConditionalNode (`dia == n`).
func _grupo_do_dia(parent: Node, n: int) -> Node3D:
	return _grupo_se(parent, "Dia%d" % n, _cond_valor(&"dia", ValueCondition.Op.IGUAL, n))


func _envelope(parent: Node, nome: String, pos: Vector3, rot_y: float, props: Dictionary) -> Envelope:
	var e := Envelope.new()
	e.name = nome
	for k in props:
		e.set(k, props[k])
	e.position = pos + Vector3(0, e.espessura() * 0.5, 0)
	e.rotation_degrees.y = rot_y
	_add(parent, e)
	return e


func _examinavel(parent: Node, tamanho: Vector3, prompt: String, titulo: String, descricao: String) -> Examinable:
	var ex := _area(parent, Examinable.new(), "Examinar", tamanho) as Examinable
	ex.prompt = prompt
	ex.title = titulo
	ex.description = descricao
	ex.initial_rotation = Vector3(90, 0, 0)
	return ex


func _folha(parent: Node, nome: String, pos: Vector3, rot_y: float, doc: String, prompt: String, some := true, espessura := 0.006) -> DocumentPickup:
	var folha := _box(parent, nome, Vector3(0.22, espessura, 0.3), pos + Vector3(0, espessura * 0.5, 0), "papel")
	folha.rotation_degrees.y = rot_y
	var ler := _area(folha, DocumentPickup.new(), "Ler", Vector3(0.28, 0.08, 0.34)) as DocumentPickup
	ler.prompt = prompt
	ler.remove_visual = some
	ler.document = load("res://narrative/documents/%s.tres" % doc)
	return ler


func _escrever(parent: Node, resposta: String, carta_lida: StringName) -> void:
	var escrever := _area(parent, WriteReply.new(), "Escrever", Vector3(0.36, 0.2, 0.36), Vector3(0.33, 0.85, -2.22)) as WriteReply
	escrever.prompt = "Escrever a Akeley"
	escrever.reply = load("res://narrative/replies/%s.tres" % resposta)
	escrever.condition = _cond_valor(carta_lida, ValueCondition.Op.MAIOR_OU_IGUAL, 1)


## Luz de um dia: vista da janela, sol entrando e preenchimento.
func _luz(parent: Node, vista: String, sol_cor: Color, sol_energia: float, sol_alvo: Vector3, sol_pos: Vector3, preench: float) -> void:
	_quad(parent, "Vista", Vector2(5.0, 3.0), Vector3(0, 1.6, -D - 1.2), Vector3.ZERO, vista)
	var sol := SpotLight3D.new()
	sol.name = "Sol"
	sol.transform = Transform3D(Basis.looking_at(sol_alvo - sol_pos), sol_pos)
	sol.light_color = sol_cor
	sol.light_energy = sol_energia
	sol.spot_range = 11.0
	sol.spot_angle = 30.0
	_add(parent, sol)
	_omni(parent, "Preenchimento", Vector3(0, 2.6, 0.6), Color(1.0, 0.92, 0.8).lerp(sol_cor, 0.4), preench, 7.0)


func _dias(parent: Node) -> void:
	_debate(parent)
	_fotografias(parent)
	_dia_1(parent)
	_dia_2(parent)
	var dia3 := _dia_3(parent)
	_fonografo(parent, dia3)
	_dia_4(parent)
	_telefone(parent)


## Dia 4 (cap. III): a pedra que não chega. O telegrama de quarta-feira, a carta
## ansiosa de julho com a foto do "exército" de pegadas, e o telefone.
func _dia_4(parent: Node) -> void:
	var g := _grupo_do_dia(parent, 4)
	_luz(g, "vista_dia", Color(1.0, 0.9, 0.7), 7.5, Vector3(-0.3, 0, 0.4), Vector3(0.6, 3.6, -D - 1.5), 1.1)
	var telegrama := _box(g, "Telegrama", Vector3(0.2, 0.003, 0.14), Vector3(0.02, MESA + 0.0015, -2.12), "envelope")
	telegrama.rotation_degrees.y = -4
	var ler := _area(telegrama, DocumentPickup.new(), "Ler", Vector3(0.24, 0.06, 0.18)) as DocumentPickup
	ler.prompt = "Ler o telegrama"
	ler.remove_visual = false
	ler.document = load("res://narrative/documents/telegrama_pedra.tres")
	_folha(g, "CartaJulho", Vector3(0.36, MESA + 0.003, -2.02), 10, "carta_akeley_julho", "Ler a carta", false)
	var env := _envelope(g, "Envelope", Vector3(-0.2, MESA, -2.47), 7, {
		remetente = "H. W. Akeley\nGeneral Delivery, Brattleboro, Vt.",
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "JUL 12\n1928",
	})
	_examinavel(env, Vector3(0.2, 0.04, 0.12), "Examinar o envelope", "Envelope de Brattleboro",
		"A letra de Akeley, mais trêmula. Carimbo de Brattleboro, 12 de julho — ele já não confia no correio de Townshend.")
	_escrever(g, "resposta_dia_4", &"ligou_relato_keene")

	# A foto de julho fica junto das outras, dali em diante.
	var julho := _grupo_se(parent, "FotografiaJulho", _cond_valor(&"dia", ValueCondition.Op.MAIOR_OU_IGUAL, 4))
	var foto := Fotografia.new()
	foto.name = "Foto10"
	foto.imagem = load(TEX_DIR + "foto_exercito.png")
	foto.position = Vector3(-0.25, MESA + Fotografia.ESPESSURA * 0.5, -2.33)
	foto.rotation_degrees.y = 6
	_add(julho, foto)
	var ex := _examinavel(foto, Vector3(0.13, 0.03, 0.1), "Examinar a fotografia", "Fotografia — o exército de pegadas",
		"Repulsivamente perturbadora: um verdadeiro exército de pegadas em fila, de frente para uma linha igualmente cerrada e resoluta de pegadas de cães. Tirada depois de uma noite em que os cães se superaram em latidos e uivos.")
	ex.flag = &"viu_foto_exercito"
	ex.exposure = 0.04


## Telefone de parede (caixa de madeira, manivela, fone no gancho), na parede
## leste, ao lado da escrivaninha. Só se usa quando há ligação disponível.
func _telefone(parent: Node) -> void:
	var g := _group(parent, "TelefoneParede", Vector3(W - 0.07, 1.45, -2.25), 90)
	_box(g, "Caixa", Vector3(0.24, 0.38, 0.12), Vector3.ZERO, "madeira_clara")
	for s in [-1, 1]:
		var sineta := _cyl(g, "Sineta%d" % s, 0.035, 0.035, 0.03, Vector3(s * 0.05, 0.14, -0.075), "latao", 8)
		sineta.rotation_degrees.x = 90
	var bocal := _cyl(g, "Bocal", 0.03, 0.015, 0.08, Vector3(0, 0.0, -0.1), "ferro", 8)
	bocal.rotation_degrees.x = 90
	_cyl(g, "Fone", 0.018, 0.022, 0.12, Vector3(-0.15, -0.02, -0.02), "ferro", 8)
	_box(g, "Manivela", Vector3(0.012, 0.08, 0.012), Vector3(0.14, 0.02, -0.03), "ferro")
	var tel := _area(g, Telefone.new(), "Telefone", Vector3(0.36, 0.45, 0.3), Vector3(0, 0, -0.08)) as Telefone
	tel.unique_name_in_owner = true
	tel.campainha = load(SFX_DIR + "campainha.wav")
	var ligs: Array[Ligacao] = []
	for id in ["agencia_arkham", "boston", "telegrama_noturno", "relato_keene"]:
		ligs.append(load("res://narrative/ligacoes/%s.tres" % id))
	tel.ligacoes = ligs


func _flag(chave: StringName, negar := false) -> ValueCondition:
	return _cond_valor(chave, ValueCondition.Op.MAIOR_OU_IGUAL, 1, negar)


## Dia 3 (cap. III): o disco chega de Brattleboro. Noite; abajur na mesa.
func _dia_3(parent: Node) -> Node3D:
	var g := _grupo_do_dia(parent, 3)
	_quad(g, "Vista", Vector2(5.0, 3.0), Vector3(0, 1.6, -D - 1.2), Vector3.ZERO, "vista_noite")
	_omni(g, "Lua", Vector3(0, 2.2, -2.6), Color(0.5, 0.6, 0.9), 0.4, 5.0)
	var abajur := _group(g, "Abajur", Vector3(0.62, MESA, -2.45))
	_cyl(abajur, "Base", 0.07, 0.08, 0.03, Vector3(0, 0.015, 0), "latao")
	_cyl(abajur, "Haste", 0.012, 0.012, 0.3, Vector3(0, 0.18, 0), "latao", 6)
	var cupula := _cyl(abajur, "Cupula", 0.06, 0.14, 0.12, Vector3(0, 0.36, 0), "estofado", 10)
	cupula.rotation_degrees.x = 10
	_omni(abajur, "Luz", Vector3(0, 0.3, 0.12), Color(1.0, 0.8, 0.55), 2.2, 6.0)

	var bilhete := _folha(g, "Bilhete", Vector3(-0.05, MESA + 0.003, -2.16), 8, "bilhete_disco", "Ler o bilhete", false)
	var transcricao := _folha(g, "Transcricao", Vector3(0.25, MESA + 0.003, -2.05), -12, "transcricao_disco", "Ler a transcrição", false)
	transcricao.get_parent().set_meta(&"treme", true)
	bilhete.get_parent().set_meta(&"treme", true)

	# O pacote do expresso, aberto, com o estojo do cilindro de cera.
	var pacote := _group(g, "Pacote", Vector3(-0.42, MESA, -2.38), 14)
	_box(pacote, "Caixa", Vector3(0.24, 0.1, 0.16), Vector3(0, 0.05, 0), "caixa_cartas")
	var etiqueta := Label3D.new()
	etiqueta.name = "Etiqueta"
	etiqueta.text = "AMERICAN RAILWAY EXPRESS\nfrom H. W. AKELEY — BRATTLEBORO, VT.\nto A. N. WILMARTH — ARKHAM, MASS."
	etiqueta.font_size = 40
	etiqueta.pixel_size = 0.00012
	etiqueta.modulate = Color(0.12, 0.1, 0.12)
	etiqueta.outline_size = 0
	etiqueta.position = Vector3(0, 0.05, 0.081)
	etiqueta.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_add(pacote, etiqueta)
	var estojo := _grupo_se(g, "Estojo", _flag(&"fono_cilindro", true))
	estojo.position = Vector3(-0.15, MESA + 0.03, -2.34)
	var tubo := _cyl(estojo, "Tubo", 0.03, 0.03, 0.11, Vector3.ZERO, "envelope", 10)
	tubo.rotation_degrees.z = 90
	_examinavel(tubo, Vector3(0.13, 0.07, 0.07), "Examinar o estojo", "O cilindro de cera",
		"Um cilindro de cera escura, gravado com ditafone, no estojo de papelão. Na tampa, a letra apertada de Akeley: “1º de maio de 1915.”")

	# O caixote da administração, no chão, com as peças da máquina emprestada.
	var caixote := _group(g, "Caixote", Vector3(-1.5, 0, 2.05), 20)
	_box(caixote, "Fundo", Vector3(0.5, 0.02, 0.38), Vector3(0, 0.01, 0), "madeira_clara")
	for s in [-1, 1]:
		_box(caixote, "Lado%d" % s, Vector3(0.02, 0.3, 0.38), Vector3(s * 0.24, 0.15, 0), "madeira_clara")
		_box(caixote, "Frente%d" % s, Vector3(0.5, 0.3, 0.02), Vector3(0, 0.15, s * 0.18), "madeira_clara")
	var rotulo := Label3D.new()
	rotulo.name = "Rotulo"
	rotulo.text = "MISKATONIC UNIVERSITY\nADMINISTRATION BLDG."
	rotulo.font_size = 48
	rotulo.pixel_size = 0.0004
	rotulo.modulate = Color(0.15, 0.1, 0.08)
	rotulo.position = Vector3(0, 0.17, 0.192)
	rotulo.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_add(caixote, rotulo)
	_colisao(caixote, "Colisao", [[Vector3(0.5, 0.3, 0.38), Vector3(0, 0.15, 0)]])
	var pecas := [
		[&"fono_corneta", "Montar a corneta", Vector3(-0.08, 0.12, 0)],
		[&"fono_manivela", "Montar a manivela", Vector3(0.12, 0.08, 0.06)],
		[&"fono_agulha", "Pôr uma agulha", Vector3(0.14, 0.06, -0.08)],
	]
	for p: Array in pecas:
		var peca := _grupo_se(caixote, "Peca_%s" % String(p[0]).trim_prefix("fono_"), _flag(p[0], true))
		peca.position = p[2]
		match p[0]:
			&"fono_corneta":
				var c := _cyl(peca, "Corneta", 0.12, 0.015, 0.3, Vector3.ZERO, "latao", 10)
				c.rotation_degrees.z = 80
			&"fono_manivela":
				_box(peca, "Braco", Vector3(0.14, 0.012, 0.012), Vector3.ZERO, "ferro")
				_cyl(peca, "Punho", 0.01, 0.01, 0.05, Vector3(0.07, 0.025, 0), "madeira_escura", 6)
			&"fono_agulha":
				_cyl(peca, "Lata", 0.025, 0.025, 0.012, Vector3.ZERO, "latao", 8)
		var montar := _area(peca, StateInteractable.new(), "Montar", Vector3(0.22, 0.15, 0.22)) as StateInteractable
		montar.prompt = p[1]
		montar.changes = {p[0]: 1.0}
		montar.additive = false

	_escrever(g, "resposta_dia_3", &"tocou_disco")
	return g


## A máquina comercial emprestada da administração (cap. III), sobre o armário.
## Um fonógrafo de cilindro: o disco de Akeley é um cilindro de cera.
func _fonografo(parent: Node, dia3: Node3D) -> void:
	var g := _grupo_se(parent, "MaquinaFonografo", _cond_valor(&"dia", ValueCondition.Op.MAIOR_OU_IGUAL, 3))
	g.position = Vector3(-2.15, 0.9, 2.35)
	g.rotation_degrees.y = -60
	_box(g, "Caixa", Vector3(0.34, 0.14, 0.24), Vector3(0, 0.07, 0), "madeira_clara")
	var mandril := _cyl(g, "Mandril", 0.028, 0.028, 0.15, Vector3(0, 0.19, 0.02), "ferro", 10)
	mandril.rotation_degrees.z = 90
	var cilindro := _grupo_se(g, "Cilindro", _flag(&"fono_cilindro"))
	var cera := _cyl(cilindro, "Cera", 0.032, 0.032, 0.11, Vector3(0, 0.19, 0.02), "cinzas", 10)
	cera.rotation_degrees.z = 90
	var corneta := _grupo_se(g, "Corneta", _flag(&"fono_corneta"))
	var cone := _cyl(corneta, "Cone", 0.16, 0.015, 0.4, Vector3(0.05, 0.38, -0.12), "latao", 10)
	cone.rotation_degrees = Vector3(-55, 0, 0)
	var manivela := _grupo_se(g, "Manivela", _flag(&"fono_manivela"))
	_box(manivela, "Braco", Vector3(0.012, 0.12, 0.012), Vector3(0.18, 0.08, 0), "ferro")
	var agulha := _grupo_se(g, "Agulha", _flag(&"fono_agulha"))
	_box(agulha, "Diafragma", Vector3(0.05, 0.03, 0.05), Vector3(0, 0.24, 0.0), "latao")

	var f := _area(g, Fonografo.new(), "Fonografo", Vector3(0.4, 0.35, 0.35), Vector3(0, 0.18, 0)) as Fonografo
	f.unique_name_in_owner = true
	f.gravacao = load("res://narrative/gravacoes/disco_1915.tres")
	f.gravacao_longa = load("res://narrative/gravacoes/disco_1915_longo.tres")
	f.zumbido = load(SFX_DIR + "zumbido.wav")
	f.narracao_depois = load("res://narrative/narration/depois_do_disco.tres")
	f.luz = dia3.get_node("Abajur/Luz")
	var tremem: Array[Node3D] = []
	for n in dia3.get_children():
		if n.has_meta(&"treme"):
			tremem.append(n)
	f.tremer = tremem


func _dia_1(parent: Node) -> void:
	var g := _grupo_do_dia(parent, 1)
	_luz(g, "vista_dia", Color(1.0, 0.86, 0.62), 7.0, Vector3(-0.4, 0, 0.6), Vector3(0.8, 3.4, -D - 1.5), 1.0)
	_folha(g, "Carta", Vector3(-0.22, MESA + 0.004, -2.12), 12, "carta_akeley_1", "Ler a carta")
	var env := _envelope(g, "Envelope", Vector3(-0.5, MESA, -2.32), 10, {
		remetente = "H. W. Akeley\nR.F.D. #2, Townshend, Vt.",
		carimbo_data = "MAY 5\n1928",
	})
	_examinavel(env, Vector3(0.2, 0.04, 0.12), "Examinar o envelope", "Envelope de Townshend",
		"Uma letra apertada, de aparência arcaica — de quem obviamente não se misturou muito com o mundo. Selo de dois centavos; carimbo de Townshend, 5 de maio.")
	_escrever(g, "resposta_dia_1", &"leu_carta_akeley_1")


func _dia_2(parent: Node) -> void:
	var g := _grupo_do_dia(parent, 2)
	# Fim de tarde: sol baixo e alaranjado, entrando quase na horizontal.
	_luz(g, "vista_entardecer", Color(1.0, 0.58, 0.32), 5.5, Vector3(-0.6, 0.5, 1.8), Vector3(1.2, 2.2, -D - 1.5), 0.55)
	_folha(g, "Carta", Vector3(0.0, MESA + 0.004, -2.1), -6, "carta_akeley_2", "Ler a carta", true, 0.014)
	var env := _envelope(g, "Envelope", Vector3(-0.2, MESA, -2.47), 6, {
		remetente = "H. W. Akeley\nR.F.D. #2, Townshend, Vt.",
		carimbo_data = "MAY 22\n1928",
		selos = 2,
		volumoso = true,
	})
	_examinavel(env, Vector3(0.2, 0.05, 0.12), "Examinar o envelope", "Envelope gordo de Townshend",
		"A mesma letra apertada. Dois selos — a carta pesa. Carimbo de Townshend, 22 de maio.")
	_escrever(g, "resposta_dia_2", &"leu_carta_akeley_2")


## O debate nos jornais: o rascunho (Dias 1 e 2) e, no Dia 2, as cartas dos
## opositores que ficam sem resposta depois da 2ª carta de Akeley (cap. II).
func _debate(parent: Node) -> void:
	var todas := CompositeCondition.new()
	var encerrado := _cond_valor(&"debate_encerrado", ValueCondition.Op.MAIOR_OU_IGUAL, 1, true)
	var partes: Array[Condition] = [_cond_valor(&"dia", ValueCondition.Op.MENOR_OU_IGUAL, 2), encerrado]
	todas.conditions = partes
	var g := _grupo_se(parent, "Debate", todas)
	_folha(g, "Rascunho", Vector3(0.62, MESA + 0.002, -2.05), -20, "rascunho_editor", "Ler o rascunho", false)

	var op := _grupo_se(g, "Opositores", _cond_valor(&"dia", ValueCondition.Op.IGUAL, 2))
	_folha(op, "CartaLeitor", Vector3(0.42, MESA + 0.002, -2.42), 14, "carta_opositor", "Ler a carta do leitor", false)
	for i in 3:
		_envelope(op, "Opositor%d" % i, Vector3(0.66, MESA + i * 0.0045, -2.44), -8 + i * 9, {
			remetente = "",
			destinatario = "Prof. A. N. Wilmarth\nMiskatonic University\nArkham, Mass.",
			carimbo_cidade = "ARKHAM",
			carimbo_data = "MAY %d\n1928" % (17 + i),
		})
	var deixar := _area(op, StateInteractable.new(), "DeixarSemResposta", Vector3(0.22, 0.05, 0.14), Vector3(0.66, MESA + 0.02, -2.44)) as StateInteractable
	deixar.prompt = "Deixar sem resposta"
	deixar.changes = {&"debate_encerrado": 1.0}
	deixar.additive = false
	deixar.condition = _cond_valor(&"leu_carta_akeley_2", ValueCondition.Op.MAIOR_OU_IGUAL, 1)
	deixar.narration = load("res://narrative/narration/debate_encerrado.tres")


## As fotografias de Akeley (cap. II): chegam no Dia 2 e ficam no escritório.
## [textura, título, descrição, [hotspots: uv, flag, texto, zoom mínimo, exposição]]
const FOTOS := [
	# "A pior de todas era a pegada" (cap. II): a foto que mais apavora Wilmarth.
	["foto_pegada", "Fotografia — a pegada",
		"A pior de todas. Tirada onde o sol batia num trecho de lama, em algum planalto deserto. Não é falsificação barata: os seixos e as folhas de grama dão a escala e não deixam possibilidade de truque de dupla exposição.",
		[[Vector2(0.5, 0.5), &"viu_garra_foto", "Chamei-a de pegada, mas “marca de garra” seria melhor. Era horrivelmente parecida com a de um caranguejo: de uma almofada central, pares de pinças serrilhadas se projetavam em direções opostas — e havia uma ambiguidade quanto à direção.", 0.5, 0.05]],
		{flag = &"viu_foto_pegada", exposure = 0.05}],
	["foto_caverna", "Fotografia — a caverna",
		"Uma exposição longa, em sombra funda: a boca de uma caverna na mata, entupida por um matacão de uma regularidade arredondada.",
		[[Vector2(0.5, 0.85), &"viu_rastros_caverna", "Com a lupa: no chão nu diante da caverna, uma rede densa de rastros curiosos — iguais ao da outra fotografia.", 0.85, 0.03]]],
	["foto_circulo", "Fotografia — o círculo de pedras",
		"Um círculo de pedras de pé, como de druidas, no alto de uma colina selvagem. Ao fundo, um verdadeiro mar de montanhas desabitadas.",
		[[Vector2(0.5, 0.8), &"viu_circulo", "Em volta do círculo a grama está muito batida e gasta. Nem com a lupa encontro uma única pegada.", 0.85, 0.0]]],
	["foto_pedra", "Fotografia — a pedra negra",
		"A grande pedra negra de Round Hill, sobre a mesa do escritório de Akeley: fileiras de livros e um busto de Milton ao fundo. Que princípios geométricos guiaram o corte dela, eu não saberia dizer.",
		[[Vector2(0.58, 0.55), &"viu_hieroglifos", "Distingo poucos hieróglifos, mas um ou dois me dão um choque: o estudo me ensinou a ligá-los aos sussurros mais blasfemos — de coisas que tiveram uma espécie de meia-existência louca antes de a terra ser feita.", 0.85, 0.05]]],
	["foto_pantano_1", "Fotografia — pântano",
		"Uma cena de pântano que parece trazer marcas de uma ocupação escondida e malsã.", []],
	["foto_colina", "Fotografia — colina",
		"Uma cena de colina que parece trazer marcas de uma ocupação escondida e malsã.", []],
	["foto_pantano_2", "Fotografia — pântano",
		"Outra cena de pântano, com as mesmas marcas de uma ocupação escondida e malsã.", []],
	["foto_marca", "Fotografia — marca perto da casa",
		"Uma marca estranha no chão, bem perto da casa de Akeley, fotografada na manhã seguinte a uma noite em que os cães latiram mais do que nunca. Muito borrada.",
		[[Vector2(0.52, 0.58), &"viu_marca_casa", "Não dá para tirar conclusão segura — mas ela parece diabolicamente com a outra marca de garra, a do planalto deserto.", 0.6, 0.02]]],
	["foto_casa", "Fotografia — a casa de Akeley",
		"Uma casa branca e bem cuidada, de dois andares e sótão, com cerca de um século e um quarto; gramado aparado, caminho ladeado de pedras, uma porta georgiana de bom gosto.",
		[[Vector2(0.58, 0.72), &"viu_akeley_foto", "No gramado, vários cães policiais enormes, sentados junto a um homem de rosto agradável e barba grisalha aparada — o próprio Akeley, seu próprio fotógrafo: a pera do disparador na mão direita.", 0.6, 0.0]]],
]


func _fotografias(parent: Node) -> void:
	var g := _grupo_se(parent, "Fotografias", _cond_valor(&"dia", ValueCondition.Op.MAIOR_OU_IGUAL, 2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for i in FOTOS.size():
		var info: Array = FOTOS[i]
		var foto := Fotografia.new()
		foto.name = "Foto%d" % (i + 1)
		foto.imagem = load(TEX_DIR + info[0] + ".png")
		foto.position = Vector3(-0.7 + (i % 3) * 0.15, MESA + Fotografia.ESPESSURA * 0.5 + (i % 2) * 0.0005, -2.47 + (i / 3) * 0.14)
		foto.rotation_degrees.y = rng.randf_range(-9, 9)
		_add(g, foto)
		var ex := _examinavel(foto, Vector3(0.13, 0.03, 0.1), "Examinar a fotografia", info[1], info[2])
		if info.size() > 4:
			ex.flag = info[4].flag
			ex.exposure = info[4].exposure
		for h: Array in info[3]:
			var hs := ExamineHotspot.new()
			hs.name = "Detalhe"
			hs.position = Fotografia.pos_na_imagem(h[0])
			hs.rotation_degrees.x = 90.0
			hs.flag = h[1]
			hs.text = h[2]
			hs.min_zoom = h[3]
			hs.exposure = h[4]
			_add(foto, hs)
