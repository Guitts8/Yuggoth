extends Node
## Ajudantes dos geradores de cena (gerar_escritorio, gerar_boston): primitivas
## subdivididas, áreas de interação, luzes, condições. Cada gerador é uma cena
## (os componentes precisam dos autoloads) que monta `cena` e a salva.

const MAT_DIR := "res://art/materials/"
const TEX_DIR := "res://art/textures/"
const SFX_DIR := "res://audio/placeholder/"

var cena: Node3D
var m: Dictionary[String, Material] = {}


## Carrega os materiais já gerados (por gerar_escritorio) para usar pelo nome.
func _carregar_materiais() -> void:
	for arquivo in DirAccess.get_files_at(MAT_DIR):
		if arquivo.ends_with(".tres"):
			m[arquivo.get_basename()] = load(MAT_DIR + arquivo)


## Empacota `cena` em `caminho` e sai (código 0 se deu certo).
func _salvar(caminho: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(caminho.get_base_dir()))
	var packed := PackedScene.new()
	var err := packed.pack(cena)
	if err == OK:
		err = ResourceSaver.save(packed, caminho)
	print("%s: %s" % [caminho.get_file().get_basename(), error_string(err)])
	cena.free()
	get_tree().quit(0 if err == OK else 1)

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


## Comum a todos: tonemap fílmico, oclusão de ambiente e um brilho leve nas luzes.
func _pos(e: Environment) -> Environment:
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.15
	e.ssao_enabled = true
	e.ssao_radius = 0.6
	e.ssao_intensity = 1.6
	e.glow_enabled = true
	e.glow_intensity = 0.5
	e.glow_hdr_threshold = 0.9
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


## Várias caixas numa malha só, cada uma com a sua cor de vértice (o psx_lit
## multiplica a textura por ela) e UV 0..1 por face, "para baixo" = -Y (nas
## faces de cima/baixo, +Z). Peça: [tamanho, posição, rotação em graus, cor].
func _lote(parent: Node, name: String, pecas: Array, mat: String) -> MeshInstance3D:
	# [normal, eixo u, eixo v]; u × v = -normal, para a ordem dos vértices sair
	# horária vista de fora (a frente, no Godot).
	const FACES := [
		[Vector3.RIGHT, Vector3.FORWARD, Vector3.DOWN], [Vector3.LEFT, Vector3.BACK, Vector3.DOWN],
		[Vector3.BACK, Vector3.RIGHT, Vector3.DOWN], [Vector3.FORWARD, Vector3.LEFT, Vector3.DOWN],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK], [Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD],
	]
	var verts := PackedVector3Array()
	var normais := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cores := PackedColorArray()
	var indices := PackedInt32Array()
	for p: Array in pecas:
		var meio: Vector3 = p[0] * 0.5
		var base := Basis.from_euler((p[2] as Vector3) * PI / 180.0)
		for f: Array in FACES:
			var n: Vector3 = f[0]
			var u: Vector3 = f[1]
			var v: Vector3 = f[2]
			var i0 := verts.size()
			for c: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var local := n * meio + u * (c.x * 2.0 - 1.0) * meio + v * (c.y * 2.0 - 1.0) * meio
				verts.append(base * local + p[1])
				normais.append(base * n)
				uvs.append(c)
				cores.append(p[3])
			indices.append_array([i0, i0 + 1, i0 + 2, i0, i0 + 2, i0 + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normais
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cores
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = m[mat]
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


func _composta(modo: CompositeCondition.Mode, conds: Array) -> CompositeCondition:
	var c := CompositeCondition.new()
	c.mode = modo
	c.conditions.assign(conds)
	return c


func _flag(chave: StringName, negar := false) -> ValueCondition:
	return _cond_valor(chave, ValueCondition.Op.MAIOR_OU_IGUAL, 1, negar)
