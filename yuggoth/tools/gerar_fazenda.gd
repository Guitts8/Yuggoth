extends "res://tools/gerador_base.gd"
## Monta levels/fazenda/fazenda.tscn: a fazenda de Henry Akeley, na encosta da
## Dark Mountain (docs/PLANO_FAZENDA.md, F1 — a planta em bloco). A mesma planta
## serve ao Interlúdio (habitada, setembro de 1928) e ao Ato III (abandonada):
## é feita inteira de uma vez, o exterior, o térreo e o primeiro andar.
## Rodar da pasta yuggoth/, depois de gerar_escritorio (usa os materiais dele):
##   godot --headless res://tools/gerar_fazenda.tscn
##
## O livro (cap. II e VI–VII; traduções nossas): "uma casa branca, de dois andares
## e meio, de tamanho e elegância incomuns para a região", do lado esquerdo de
## quem sobe a estrada para o norte, "do outro lado de um gramado bem tratado que
## ia até a estrada e ostentava uma borda de pedras caiadas", "um caminho
## margeado de pedras até uma porta georgiana entalhada com gosto"; "um
## amontoado de celeiros, galpões e um moinho de vento, contíguos ou ligados por
## arcadas, atrás e à direita"; a caixa de correio de ferro galvanizado junto à
## estrada; o Ford velho "no abrigo grande e aberto"; atrás da casa, "um trecho
## plano de terreno pantanoso e de mata rala", e além dele "uma encosta íngreme,
## de mata fechada, que termina numa crista recortada de folhas" — o cume da
## Dark Mountain. Por dentro: o vestíbulo colonial; à esquerda de quem entra, a
## porta branca de seis painéis com trinco de latão do escritório; a sala de
## jantar logo depois dele, e o puxado da cozinha mais além, na mesma direção;
## em cima, o quarto de hóspedes sobre o escritório e o banheiro no alto da
## escada. A noite do telhado: um cão "subiu no telhado pulando do puxado baixo".
##
## Coordenadas: metros; -Z é o norte, +X o leste. A estrada corre de norte a sul
## em x 28..33; a casa, de frente para ela (leste), em x -3..6, z -6..6; o chão
## do quintal em y 0, o piso do térreo em T0. As construções de trás ficam a
## noroeste; o pântano a oeste (x < -30) e a encosta além de x -64. A área de
## andar é cercada por muros de pedra seca.

const OUT := "res://levels/fazenda/fazenda.tscn"
## As malhas grandes (o chão, as obras, a mata) e a colisão do chão vão em
## recursos binários à parte: no .tscn em texto, a cena passava de 19 MB.
const MALHAS := "res://levels/fazenda/malhas/"
const Cidade = preload("res://tools/cidade_arkham.gd")
const Vistas = preload("res://tools/vistas.gd")

## Tamanho máximo de uma célula das faces geradas (o afim e a luz por vértice).
const CEL := 0.75

# A casa.
const CASA_X := Vector2(-3.0, 6.0)
const CASA_Z := Vector2(-6.0, 6.0)
const E := 0.2  ## parede externa
const EI := 0.12  ## parede interna
const T0 := 0.6  ## piso do térreo (a fundação de pedra aparece embaixo)
const PE0 := 2.9
const LAJE := 0.25
const T1 := T0 + PE0 + LAJE  ## piso do primeiro andar
const PE1 := 2.6
const FORRO := T1 + PE1  ## o forro do primeiro andar (piso do sótão)
const BEIRAL := FORRO + 0.15  ## o alto das paredes
const CUMEEIRA := Vector2(1.5, BEIRAL + 4.2)  ## (x, y) da cumeeira, de norte a sul
## O vestíbulo, no meio, de leste a oeste.
const HALL_Z := 1.4
## A parede que separa os cômodos da frente dos de trás.
const MEIO_X := 1.0
## A escada: sobe para oeste ao longo do lado norte do vestíbulo.
const ESCADA_X := 4.4  ## o primeiro degrau
const DEGRAUS := 16
const PISADA := 0.26
const ESCADA_Z := Vector2(-HALL_Z, -HALL_Z + 1.0)
## As chaminés, na parede do meio: z de cada uma (centro) e meia largura.
const CHAMINE_Z := 3.7
const CHAMINE_MEIA := Vector2(0.6, 0.7)  ## (x, z)
## O puxado da cozinha (o "puxado baixo"), a oeste, atrás da sala de jantar.
const PUXADO_X := Vector2(-9.0, -3.0)
const PUXADO_Z := Vector2(1.0, 6.0)
const PUXADO_ALTO := T0 + 2.5
## A estrada.
const ESTRADA_X := Vector2(28.0, 33.0)
## A área de andar (os muros de pedra).
const LIMITE_X := Vector2(-64.0, 34.0)
const LIMITE_Z := Vector2(-60.0, 40.0)

## Os cães (o livro não lhes dá nome: "my great police dogs"; os nomes são do
## usuário, 2026-10-10). Os quatro primeiros têm comportamento próprio (F4).
const CAES := ["Brutus", "Conan", "Hércules", "Rambo", "Yautja", "Dutch", "Kull", "Kurgan", "Ripley", "Snake", "Riddick", "Sansão"]

var _obras: Dictionary[String, Cidade.Malha] = {}
var _col: Array = []
var _rng := RandomNumberGenerator.new()
var _vistas = Vistas.new()
var _cidade = Cidade.new()
var _relevo := FastNoiseLite.new()


func _ready() -> void:
	_rng.seed = 1928
	_relevo.seed = 9
	_relevo.frequency = 0.012
	_carregar_materiais()
	_mat("tabuado", "tabuado", {world = 1.0})
	_mat("telhado", "telhas", {world = 1.2})
	_mat("grama", "grama", {world = 0.5})
	_mat("estrada", "estrada", {world = 0.45})
	_mat("pedra_campo", "pedra_campo", {world = 0.9})
	_mat("celeiro", "celeiro", {world = 0.9})
	_mat("caiado", "reboco", {world = 2.0, cor = Color(1.3, 1.3, 1.26)})
	_mat("pintura_branca", "grao", {world = 2.0, cor = Color(0.95, 0.93, 0.88)})
	_mat("veneziana", "madeira_clara", {world = 4.0, cor = Color(0.42, 0.62, 0.48)})
	_mat("parede_casa", "reboco", {world = 1.0, cor = Color(1.08, 1.04, 0.95)})
	_mat("forro_sotao", "madeira_clara", {world = 1.2})
	_mat("granito", "reboco", {world = 1.5, cor = Color(0.72, 0.72, 0.72)})
	_mat("ferro_galvanizado", "aco", {world = 3.0, cor = Color(0.72, 0.74, 0.76)})
	_mat("agua", "grao", {unlit = true, world = 1.0, cor = Color(0.2, 0.22, 0.24)})
	_mat("chao_terra", "estrada", {world = 0.6, cor = Color(0.8, 0.72, 0.62)})
	_mat("palha", "papel_pardo", {world = 1.5, cor = Color(1.1, 0.95, 0.6)})

	cena = Node3D.new()
	cena.name = "Fazenda"
	cena.set_script(load("res://levels/fazenda/fazenda.gd"))
	cena.set("som", _sfx("dia_quieto.wav"))

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = _env()
	_add(cena, env)
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	# Tarde de setembro: o sol a sudoeste, já descendo para a montanha.
	sol.rotation_degrees = Vector3(-32, -40, 0)
	sol.light_color = Color(1.0, 0.9, 0.74)
	sol.light_energy = 1.6
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 90.0
	_add(cena, sol)

	_terreno()
	_estrada_e_gramado()
	_muros()
	_casa()
	_puxado()
	_dependencias()
	_canil()
	_ford()
	_moinho()
	_arvores()
	_fechar_obras()
	_colisao(cena, "Colisao", _col)

	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector3(18.0, 0.0, 0.0)
	player.rotation_degrees.y = 90.0
	_add(cena, player)
	# O quintal (no caminho, de frente para a casa), a estrada (junto à caixa de
	# correio) e o vestíbulo.
	_spawn("Quintal", player.position, 90.0)
	_spawn("Estrada", Vector3(30.5, 0.0, 4.0), 0.0)
	_spawn("Vestibulo", Vector3(4.6, T0, 0.4), 90.0)

	_salvar(OUT)


## Tarde de setembro (provisória: a luz e o céu de verdade são a F2).
func _env() -> Environment:
	var e := _pos(Environment.new())
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color(0.36, 0.48, 0.66)
	ceu.sky_horizon_color = Color(0.74, 0.72, 0.66)
	ceu.ground_horizon_color = Color(0.5, 0.5, 0.46)
	ceu.ground_bottom_color = Color(0.2, 0.2, 0.18)
	var sky := Sky.new()
	sky.sky_material = ceu
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.55
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.68, 0.68, 0.64)
	e.fog_density = 0.9
	e.fog_depth_begin = 70.0
	e.fog_depth_end = 380.0
	return e


# --- Ajudantes ----------------------------------------------------------------------

## A malha (de cor por vértice) de um material: tudo o que é fixo e usa esse
## material vira uma malha só, com as faces subdivididas.
func _obra(mat: String) -> Cidade.Malha:
	if not _obras.has(mat):
		_obras[mat] = Cidade.Malha.new()
	return _obras[mat]


## Salva `r` em MALHAS/`nome`.res e devolve o recurso carregado de lá.
func _guardar(r: Resource, nome: String) -> Resource:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MALHAS))
	var caminho := MALHAS + nome + ".res"
	ResourceSaver.save(r, caminho, ResourceSaver.FLAG_COMPRESS)
	return load(caminho)


func _fechar_obras() -> void:
	var g := _group(cena, "Obras")
	for mat in _obras:
		var mi := MeshInstance3D.new()
		mi.name = mat.to_pascal_case()
		mi.mesh = _guardar(_obras[mat].fechar(), "obra_" + mat)
		mi.material_override = m[mat]
		_add(g, mi)


## Um retângulo de `o`, com lados `eu` e `ev`, em células de até CEL.
func _face(mm: Cidade.Malha, o: Vector3, eu: Vector3, ev: Vector3, n: Vector3, cor: Color) -> void:
	var nu := maxi(1, ceili(eu.length() / CEL))
	var nv := maxi(1, ceili(ev.length() / CEL))
	var du := eu / nu
	var dv := ev / nv
	for i in nu:
		for j in nv:
			var a := o + du * i + dv * j
			mm.quad(a, a + du, a + du + dv, a + dv, n, cor)


## Um triângulo, partido ao meio até os lados caberem em ~1,2 m.
func _tri(mm: Cidade.Malha, a: Vector3, b: Vector3, c: Vector3, n: Vector3, cor: Color) -> void:
	if maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a))) <= 1.2:
		mm.tri(a, b, c, n, cor)
		return
	var ab := (a + b) / 2
	var bc := (b + c) / 2
	var ca := (c + a) / 2
	_tri(mm, a, ab, ca, n, cor)
	_tri(mm, ab, b, bc, n, cor)
	_tri(mm, ca, bc, c, n, cor)
	_tri(mm, ab, bc, ca, n, cor)


## Uma caixa fixa (girada `rot` graus) na malha do material; com `col`, entra na
## colisão.
func _bloco(mat: String, tam: Vector3, c: Vector3, cor := Color.WHITE, col := true, rot := Vector3.ZERO) -> void:
	var mm := _obra(mat)
	var b := Basis.from_euler(rot * PI / 180.0)
	var h := tam / 2
	var eixos := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for i in 3:
		var ej: Vector3 = eixos[(i + 1) % 3]
		var ek: Vector3 = eixos[(i + 2) % 3]
		var hj: float = h[(i + 1) % 3]
		var hk: float = h[(i + 2) % 3]
		for s: float in [-1.0, 1.0]:
			var n: Vector3 = eixos[i] * s
			var o := c + b * (n * h[i] - ej * hj - ek * hk)
			_face(mm, o, b * (ej * 2 * hj), b * (ek * 2 * hk), b * n, cor)
	if col:
		_col.append([tam, c, rot] if rot != Vector3.ZERO else [tam, c])


## Uma parede reta de `de` a `ate` (no plano XZ, ao longo de X ou de Z), de y0 a
## y1, com espessura `esp` e as aberturas [centro ao longo dela, largura, base,
## topo] (alturas absolutas; as que não cruzam y0..y1 não contam, e uma pode
## ficar sobre a outra: a janela do térreo e a do andar de cima).
func _parede(mat: String, de: Vector2, ate: Vector2, y0: float, y1: float, esp: float, aberturas := [], cor := Color.WHITE, col := true) -> void:
	var em_x := is_equal_approx(de.y, ate.y)
	var s0 := minf(de.x, ate.x) if em_x else minf(de.y, ate.y)
	var s1 := maxf(de.x, ate.x) if em_x else maxf(de.y, ate.y)
	var fixo := de.y if em_x else de.x
	var pedaco := func(a: float, b: float, ya: float, yb: float) -> void:
		if b - a < 0.005 or yb - ya < 0.005:
			return
		var meio := (a + b) / 2
		var c := Vector3(meio, (ya + yb) / 2, fixo) if em_x else Vector3(fixo, (ya + yb) / 2, meio)
		var tam := Vector3(b - a, yb - ya, esp) if em_x else Vector3(esp, yb - ya, b - a)
		_bloco(mat, tam, c, cor, col)
	var cortes := PackedFloat32Array([s0, s1])
	var buracos: Array[Array] = []
	for ab: Array in aberturas:
		var base := clampf(ab[2], y0, y1)
		var topo := clampf(ab[3], y0, y1)
		var a0 := clampf(ab[0] - ab[1] / 2, s0, s1)
		var a1 := clampf(ab[0] + ab[1] / 2, s0, s1)
		if topo - base < 0.005 or a1 - a0 < 0.005:
			continue
		buracos.append([a0, a1, base, topo])
		cortes.append(a0)
		cortes.append(a1)
	cortes.sort()
	for i in cortes.size() - 1:
		var a := cortes[i]
		var b := cortes[i + 1]
		if b - a < 0.005:
			continue
		var meio := (a + b) / 2
		var vaos: Array[Vector2] = []
		for bu in buracos:
			if bu[0] <= meio and meio <= bu[1]:
				vaos.append(Vector2(bu[2], bu[3]))
		vaos.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
		var y := y0
		for v in vaos:
			pedaco.call(a, b, y, v.x)
			y = maxf(y, v.y)
		pedaco.call(a, b, y, y1)


## A altura do chão em (x, z): o quintal plano; a leste da estrada o vale cai, e
## do outro lado sobem os morros; ao sul a estrada desce (a subida íngreme por
## onde se chega); a oeste, além do pântano, a encosta da Dark Mountain.
func _altura(x: float, z: float) -> float:
	var h := 0.0
	if x > 34.0:
		h -= minf((x - 34.0) * 0.45, 38.0)
	if x > 140.0:
		h += (x - 140.0) * 0.9
	if z > 26.0:
		h -= (z - 26.0) * 0.16
	if z < -40.0:
		h += (-40.0 - z) * 0.04
	if x < -30.0 and x > -64.0:
		h -= 0.12 * clampf((-30.0 - x) / 4.0, 0.0, 1.0)
	if x < -64.0:
		h += (-64.0 - x) * 0.75 - 0.12
	# Ondulação, crescendo longe do quintal.
	var longe := clampf((Vector2(x - 0.0, z - 0.0).length() - 45.0) / 40.0, 0.0, 1.0)
	h += _relevo.get_noise_2d(x, z) * 3.0 * longe
	return h


## A cor do chão em (x, z) (multiplica a textura da grama).
func _cor_chao(x: float, z: float) -> Color:
	var c := Color(0.42, 0.5, 0.27)  # o quintal
	if x > 6.0 and x < ESTRADA_X.x and absf(z) < 12.0:
		c = Color(0.36, 0.52, 0.24)  # o gramado bem tratado
	elif x > 34.0 or z < -34.0 or z > 34.0:
		c = Color(0.56, 0.53, 0.3)  # o pasto de setembro
	if x < -30.0:
		c = c.lerp(Color(0.27, 0.31, 0.19), clampf((-30.0 - x) / 6.0, 0.0, 1.0))  # o pântano
	if x < -64.0:
		c = Color(0.2, 0.21, 0.15)  # o chão da mata
	# Terra gasta em volta das construções de trás.
	if x > -28.0 and x < -2.0 and z > -22.0 and z < -6.0:
		c = c.lerp(Color(0.46, 0.4, 0.3), 0.5)
	return c * _rng.randf_range(0.92, 1.06)


# --- O terreno ----------------------------------------------------------------------

## Uma grade retilínea (as linhas finas perto, grossas longe, sem fendas entre
## elas), com a altura e a cor de cada ponto; a colisão segue a malha.
func _terreno() -> void:
	var xs := _passos([-260.0, -70.0, 46.0, 210.0], [10.0, 2.0, 8.0])
	var zs := _passos([-230.0, -66.0, 46.0, 230.0], [10.0, 2.0, 10.0])
	var mm := Cidade.Malha.new()
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var x0 := xs[i]
			var x1 := xs[i + 1]
			var z0 := zs[j]
			var z1 := zs[j + 1]
			var a := Vector3(x0, _altura(x0, z0), z0)
			var b := Vector3(x1, _altura(x1, z0), z0)
			var c := Vector3(x1, _altura(x1, z1), z1)
			var d := Vector3(x0, _altura(x0, z1), z1)
			var n := (c - a).cross(b - d).normalized()
			if n.y < 0.0:
				n = -n
			mm.quad(a, b, c, d, n, _cor_chao((x0 + x1) / 2, (z0 + z1) / 2))
	var mi := MeshInstance3D.new()
	mi.name = "Chao"
	mi.mesh = _guardar(mm.fechar(), "chao")
	mi.material_override = m["grama"]
	_add(cena, mi)
	var corpo := StaticBody3D.new()
	corpo.name = "ColisaoChao"
	_add(cena, corpo)
	var forma := CollisionShape3D.new()
	forma.name = "Forma"
	forma.shape = _guardar(mi.mesh.create_trimesh_shape(), "chao_colisao")
	_add(corpo, forma)
	# As poças do pântano.
	var agua := _obra("agua")
	for k in 26:
		var p := Vector3(_rng.randf_range(-60.0, -34.0), 0.0, _rng.randf_range(-55.0, 35.0))
		var r := Vector2(_rng.randf_range(1.0, 3.5), _rng.randf_range(0.8, 2.5))
		var y := _altura(p.x, p.z) + 0.03
		_face(agua, Vector3(p.x - r.x, y, p.z - r.y), Vector3(2 * r.x, 0, 0), Vector3(0, 0, 2 * r.y), Vector3.UP, Color(1, 1, 1) * _rng.randf_range(0.9, 1.1))


## Os pontos de uma grade de `marcos[0]` a `marcos[-1]`, com o passo `passos[i]`
## entre marcos[i] e marcos[i + 1].
func _passos(marcos: Array, passos: Array) -> PackedFloat32Array:
	var r := PackedFloat32Array()
	for i in passos.size():
		var v: float = marcos[i]
		while v < marcos[i + 1] - 0.001:
			r.append(v)
			v += passos[i]
	r.append(marcos[-1])
	return r


# --- A estrada, o gramado, a caixa de correio -------------------------------------------

func _estrada_e_gramado() -> void:
	var g := _group(cena, "Estrada")
	# A estrada de terra, seguindo o chão, em pedaços de 2 m.
	var est := _obra("estrada")
	var z := -230.0
	while z < 230.0:
		var z1 := z + (2.0 if absf(z) < 70.0 else 10.0)
		var xs := [ESTRADA_X.x, (ESTRADA_X.x + ESTRADA_X.y) / 2, ESTRADA_X.y]
		for i in 2:
			var a := Vector3(xs[i], _altura(xs[i], z) + 0.03, z)
			var b := Vector3(xs[i + 1], _altura(xs[i + 1], z) + 0.03, z)
			var c := Vector3(xs[i + 1], _altura(xs[i + 1], z1) + 0.03, z1)
			var d := Vector3(xs[i], _altura(xs[i], z1) + 0.03, z1)
			est.quad(a, b, c, d, Vector3.UP, Color.WHITE)
		z = z1
	# A entrada de carro, da estrada ao abrigo do Ford (ao norte da casa), e o
	# caminho gasto da cozinha ao celeiro.
	_face(est, Vector3(14.5, 0.025, -16.5), Vector3(ESTRADA_X.x - 14.5, 0, 0), Vector3(0, 0, 3.0), Vector3.UP, Color.WHITE)
	_face(_obra("chao_terra"), Vector3(-7.5, 0.02, -8.0), Vector3(1.6, 0, 0), Vector3(0, 0, 9.0), Vector3.UP, Color.WHITE)
	_face(_obra("chao_terra"), Vector3(-16.0, 0.02, -9.6), Vector3(10.0, 0, 0), Vector3(0, 0, 1.6), Vector3.UP, Color.WHITE)

	# O caminho de pedras até a porta (lajes chatas de granito no gramado).
	var x := 7.6
	while x < ESTRADA_X.x - 0.4:
		_bloco("granito", Vector3(0.75, 0.06, 1.05 + _rng.randf_range(-0.1, 0.1)), Vector3(x, 0.03, _rng.randf_range(-0.06, 0.06)),
			Color.WHITE * _rng.randf_range(0.85, 1.08), false, Vector3(0, _rng.randf_range(-6, 6), 0))
		x += 0.85
	# A borda de pedras caiadas: ao longo da estrada (menos o caminho) e dos dois
	# lados do caminho.
	var pedras := []
	for zz in range(-12, 13):
		if absi(zz) <= 1:
			continue
		pedras.append(Vector3(ESTRADA_X.x - 0.5, 0, zz * 0.98))
	var xx := 7.8
	while xx < ESTRADA_X.x - 0.8:
		pedras.append(Vector3(xx, 0, -0.85))
		pedras.append(Vector3(xx, 0, 0.85))
		xx += 0.7
	for p: Vector3 in pedras:
		var r := Vector3(_rng.randf_range(0.13, 0.19), _rng.randf_range(0.08, 0.12), _rng.randf_range(0.12, 0.17))
		_vistas._bola(_obra("caiado"), p + Vector3(0, r.y * 0.6, 0), r, Color.WHITE * _rng.randf_range(0.9, 1.05), _rng)

	# A caixa de correio de ferro galvanizado, num poste, com o nome.
	var cx := _group(g, "CaixaCorreio", Vector3(ESTRADA_X.x - 0.6, 0, 2.4))
	_bloco("madeira_escura", Vector3(0.1, 1.1, 0.1), cx.position + Vector3(0, 0.55, 0))
	_bloco("ferro_galvanizado", Vector3(0.48, 0.22, 0.2), cx.position + Vector3(0.08, 1.2, 0), Color.WHITE, false)
	_bloco("ferro_galvanizado", Vector3(0.48, 0.06, 0.16), cx.position + Vector3(0.08, 1.33, 0), Color.WHITE, false)
	var nome := Label3D.new()
	nome.name = "Nome"
	nome.text = "H. W. AKELEY"
	nome.font_size = 40
	nome.pixel_size = 0.0018
	nome.modulate = Color(0.12, 0.12, 0.12)
	nome.position = Vector3(0.08, 1.2, 0.102)
	_add(cx, nome)


# --- Os muros de pedra seca -------------------------------------------------------------

## Os muros que cercam a área de andar (os campos da Nova Inglaterra): pedras de
## campo empilhadas, sem argamassa.
func _muros() -> void:
	var lx := LIMITE_X
	var lz := LIMITE_Z
	# Oeste (entre o pântano e a mata), norte e sul; ao longo da estrada, dos dois
	# lados, menos o gramado (a borda caiada) e a entrada de carro.
	_muro(Vector2(lx.x, lz.x), Vector2(lx.x, lz.y))
	_muro(Vector2(lx.x, lz.x), Vector2(ESTRADA_X.x - 0.6, lz.x))
	_muro(Vector2(lx.x, lz.y), Vector2(ESTRADA_X.x - 0.6, lz.y))
	_muro(Vector2(ESTRADA_X.x - 0.6, lz.x), Vector2(ESTRADA_X.x - 0.6, -17.0))
	_muro(Vector2(ESTRADA_X.x - 0.6, -13.0), Vector2(ESTRADA_X.x - 0.6, -12.6))
	_muro(Vector2(ESTRADA_X.x - 0.6, 12.6), Vector2(ESTRADA_X.x - 0.6, lz.y))
	_muro(Vector2(ESTRADA_X.y + 0.6, lz.x - 10.0), Vector2(ESTRADA_X.y + 0.6, lz.y + 10.0))
	# A estrada segue para os dois lados; o corpo não (sem muro: só a colisão).
	_col.append([Vector3(ESTRADA_X.y - ESTRADA_X.x + 1.2, 4.0, 0.4), Vector3((ESTRADA_X.x + ESTRADA_X.y) / 2, 2.0, lz.x - 0.3)])
	_col.append([Vector3(ESTRADA_X.y - ESTRADA_X.x + 1.2, 6.0, 0.4), Vector3((ESTRADA_X.x + ESTRADA_X.y) / 2, _altura(30.0, lz.y + 0.3), lz.y + 0.3)])


func _muro(de: Vector2, ate: Vector2) -> void:
	var pedra := _obra("pedra_campo")
	var compr := de.distance_to(ate)
	var dir := (ate - de) / compr
	var lado := Vector2(-dir.y, dir.x)
	var giro := -rad_to_deg(atan2(dir.y, dir.x))
	for fila in 3:
		var s := _rng.randf_range(0.0, 0.3)
		while s < compr:
			var t := Vector3(_rng.randf_range(0.35, 0.7), _rng.randf_range(0.22, 0.34), _rng.randf_range(0.35, 0.55))
			var p := de + dir * s + lado * _rng.randf_range(-0.12, 0.12)
			var y := _altura(p.x, p.y) + 0.12 + fila * 0.26
			_bloco("pedra_campo", t, Vector3(p.x, y, p.y), Color.WHITE * _rng.randf_range(0.8, 1.1), false,
				Vector3(_rng.randf_range(-6, 6), giro + _rng.randf_range(-12, 12), _rng.randf_range(-6, 6)))
			s += t.x * 0.9
	var meio := (de + ate) / 2
	var ym := _altura(meio.x, meio.y)
	_col.append([Vector3(compr, 2.4, 0.7), Vector3(meio.x, ym + 0.9, meio.y), Vector3(0, giro, 0)])


# --- A casa ------------------------------------------------------------------------------

func _casa() -> void:
	var cx := CASA_X
	var cz := CASA_Z
	# A fundação de pedra, à vista do chão ao piso.
	_parede("pedra_campo", Vector2(cx.x, cz.x + E / 2), Vector2(cx.y, cz.x + E / 2), -0.3, T0, E + 0.06)
	_parede("pedra_campo", Vector2(cx.x, cz.y - E / 2), Vector2(cx.y, cz.y - E / 2), -0.3, T0, E + 0.06)
	_parede("pedra_campo", Vector2(cx.x + E / 2, cz.x + E), Vector2(cx.x + E / 2, cz.y - E), -0.3, T0, E + 0.06)
	_parede("pedra_campo", Vector2(cx.y - E / 2, cz.x + E), Vector2(cx.y - E / 2, cz.y - E), -0.3, T0, E + 0.06)

	# As paredes externas: o tabuado por fora, o reboco por dentro.
	var j0 := [T0 + 0.8, T0 + 2.3]  # as janelas do térreo (peitoril, verga)
	var j1 := [T1 + 0.7, T1 + 2.2]
	var porta := [T0, T0 + 2.35]
	var leste := [[0.0, 1.1] + porta]  # a porta da frente
	var oeste := [[0.0, 1.0] + porta]  # a porta dos fundos (para o pântano)
	for z: float in [-4.8, -2.6, 2.6, 4.8]:
		leste.append([z, 0.9] + j0)
		leste.append([z, 0.9] + j1)
	leste.append([0.0, 0.9] + j1)
	for z: float in [-4.8, -2.6]:
		oeste.append([z, 0.9] + j0)
	for z: float in [-4.8, -2.6, 2.6, 4.8]:
		oeste.append([z, 0.9] + j1)
	oeste.append([0.0, 0.6, T1 + 1.2, T1 + 2.0])  # a janelinha do banheiro
	# A porta da sala de jantar para a cozinha (o puxado), na parede oeste.
	oeste.append([CHAMINE_Z, 0.9] + porta)
	var norte := []
	var sul := []
	for x: float in [4.6, 2.4, -1.0]:
		norte.append([x, 0.9] + j0)
		norte.append([x, 0.9] + j1)
		sul.append([x, 0.9] + j0)
		sul.append([x, 0.9] + j1)
	var fora := 0.14
	var dentro := E - fora
	_parede("tabuado", Vector2(cx.y - fora / 2, cz.x), Vector2(cx.y - fora / 2, cz.y), T0, BEIRAL, fora, leste)
	_parede("tabuado", Vector2(cx.x + fora / 2, cz.x), Vector2(cx.x + fora / 2, cz.y), T0, BEIRAL, fora, oeste)
	_parede("tabuado", Vector2(cx.x, cz.x + fora / 2), Vector2(cx.y, cz.x + fora / 2), T0, BEIRAL, fora, norte)
	_parede("tabuado", Vector2(cx.x, cz.y - fora / 2), Vector2(cx.y, cz.y - fora / 2), T0, BEIRAL, fora, sul)
	for andar: Array in [[T0, T0 + PE0], [T1, FORRO]]:
		_parede("parede_casa", Vector2(cx.y - E + dentro / 2, cz.x + E), Vector2(cx.y - E + dentro / 2, cz.y - E), andar[0], andar[1], dentro, leste, Color.WHITE, false)
		_parede("parede_casa", Vector2(cx.x + E - dentro / 2, cz.x + E), Vector2(cx.x + E - dentro / 2, cz.y - E), andar[0], andar[1], dentro, oeste, Color.WHITE, false)
		_parede("parede_casa", Vector2(cx.x + E, cz.x + E - dentro / 2), Vector2(cx.y - E, cz.x + E - dentro / 2), andar[0], andar[1], dentro, norte, Color.WHITE, false)
		_parede("parede_casa", Vector2(cx.x + E, cz.y - E + dentro / 2), Vector2(cx.y - E, cz.y - E + dentro / 2), andar[0], andar[1], dentro, sul, Color.WHITE, false)
	# Os cantos e o friso do beiral, em tábua branca.
	for x: float in [cx.x, cx.y]:
		for z: float in [cz.x, cz.y]:
			_bloco("pintura_branca", Vector3(0.22, BEIRAL - T0, 0.22), Vector3(x - signf(x - 1.5) * 0.09, (T0 + BEIRAL) / 2, z - signf(z) * 0.09), Color.WHITE, false)
	_bloco("pintura_branca", Vector3(0.06, 0.3, cz.y - cz.x + 0.3), Vector3(cx.y + 0.03, BEIRAL - 0.15, 0), Color.WHITE, false)
	_bloco("pintura_branca", Vector3(0.06, 0.3, cz.y - cz.x + 0.3), Vector3(cx.x - 0.03, BEIRAL - 0.15, 0), Color.WHITE, false)

	_pisos()
	_divisorias()
	_chamines()
	_escada()
	_telhado_casa()
	_porta_georgiana()
	_portas_internas()
	_janelas_da_casa(leste, oeste, norte, sul)
	_moveis()
	# Os degraus de granito da frente e dos fundos, com a rampa por baixo.
	for k in 3:
		_bloco("granito", Vector3(0.4, 0.2 * (k + 1), 2.0 - k * 0.2), Vector3(cx.y + 1.1 - k * 0.4, 0.1 * (k + 1), 0), Color.WHITE, false)
		_bloco("granito", Vector3(0.4, 0.2 * (k + 1), 1.6), Vector3(cx.x - 1.1 + k * 0.4, 0.1 * (k + 1), 0), Color.WHITE, false)
	_rampa(Vector3(cx.y + 1.45, 0, 0), Vector3(cx.y, T0, 0), 2.0)
	_rampa(Vector3(cx.x - 1.45, 0, 0), Vector3(cx.x, T0, 0), 1.6)


## Uma rampa de colisão (invisível) de `de` a `ate`, com `largura`.
func _rampa(de: Vector3, ate: Vector3, largura: float) -> void:
	var d := ate - de
	var plano := Vector2(d.x, d.z)
	var compr := Vector2(plano.length(), d.y).length()
	var giro := rad_to_deg(atan2(-d.x, -d.z))
	var incl := rad_to_deg(atan2(d.y, plano.length()))
	var meio := (de + ate) / 2 - Vector3.UP * 0.1
	_col.append([Vector3(largura, 0.2, compr + 0.3), meio, Vector3(incl, giro, 0)])


## O piso do térreo, a laje (com o vão da escada) e o forro do primeiro andar.
func _pisos() -> void:
	var x0 := CASA_X.x + E
	var x1 := CASA_X.y - E
	var z0 := CASA_Z.x + E
	var z1 := CASA_Z.y - E
	_bloco("piso", Vector3(x1 - x0, 0.1, z1 - z0), Vector3((x0 + x1) / 2, T0 - 0.05, (z0 + z1) / 2))
	# A laje em quatro pedaços em volta do vão (x 0,2..ESCADA_X, z da escada).
	var vao_x := Vector2(ESCADA_X - DEGRAUS * PISADA, ESCADA_X)
	var vao_z := ESCADA_Z
	var pedacos := [
		[Vector2(x0, vao_x.x), Vector2(z0, z1)],
		[Vector2(vao_x.y, x1), Vector2(z0, z1)],
		[Vector2(vao_x.x, vao_x.y), Vector2(z0, vao_z.x)],
		[Vector2(vao_x.x, vao_x.y), Vector2(vao_z.y, z1)],
	]
	for p: Array in pedacos:
		var px: Vector2 = p[0]
		var pz: Vector2 = p[1]
		var c := Vector3((px.x + px.y) / 2, 0, (pz.x + pz.y) / 2)
		_bloco("piso", Vector3(px.y - px.x, 0.06, pz.y - pz.x), c + Vector3(0, T1 - 0.03, 0))
		_bloco("teto", Vector3(px.y - px.x, LAJE - 0.06, pz.y - pz.x), c + Vector3(0, T1 - 0.06 - (LAJE - 0.06) / 2, 0), Color.WHITE, false)
	# O forro (o piso do sótão, que a demo não abre).
	_bloco("teto", Vector3(x1 - x0, 0.08, z1 - z0), Vector3((x0 + x1) / 2, FORRO + 0.04, (z0 + z1) / 2), Color.WHITE, false)
	_bloco("forro_sotao", Vector3(x1 - x0, 0.06, z1 - z0), Vector3((x0 + x1) / 2, FORRO + 0.11, (z0 + z1) / 2), Color.WHITE, false)


## As paredes de dentro, nos dois andares.
func _divisorias() -> void:
	var x0 := CASA_X.x + E
	var x1 := CASA_X.y - E
	var z0 := CASA_Z.x + E
	var z1 := CASA_Z.y - E
	var p0 := [T0, T0 + 2.15]
	var p1 := [T1, T1 + 2.1]
	var chamine := func(lado: float) -> Array:
		return [lado * CHAMINE_Z, 2 * CHAMINE_MEIA.y, -1.0, 99.0]
	# Térreo. O vestíbulo: a porta do escritório (à esquerda de quem entra) e a da
	# sala de estar perto da frente; as da sala de jantar e da sala dos fundos
	# depois da escada.
	_parede("parede_casa", Vector2(x0, HALL_Z), Vector2(x1, HALL_Z), T0, T0 + PE0, EI, [[5.1, 0.9] + p0, [-1.5, 0.9] + p0])
	_parede("parede_casa", Vector2(x0, -HALL_Z), Vector2(x1, -HALL_Z), T0, T0 + PE0, EI, [[5.1, 0.9] + p0, [-1.5, 0.9] + p0])
	# A parede do meio: as chaminés no meio dela; a porta do escritório para a
	# sala de jantar perto do vestíbulo.
	_parede("parede_casa", Vector2(MEIO_X, HALL_Z), Vector2(MEIO_X, z1), T0, T0 + PE0, EI, [chamine.call(1.0), [2.15, 0.9] + p0])
	_parede("parede_casa", Vector2(MEIO_X, z0), Vector2(MEIO_X, -HALL_Z), T0, T0 + PE0, EI, [chamine.call(-1.0)])
	# Primeiro andar. O quarto de hóspedes (sobre o escritório) e o quarto de
	# Akeley (sobre a sala de estar) pela frente; os dois de trás pelo patamar; o
	# banheiro no alto da escada, no fim do corredor.
	var banheiro_x := -1.0
	var patamar := (banheiro_x + ESCADA_X - DEGRAUS * PISADA) / 2
	_parede("parede_casa", Vector2(x0, HALL_Z), Vector2(x1, HALL_Z), T1, FORRO, EI, [[3.0, 0.9] + p1, [patamar, 0.8] + p1])
	_parede("parede_casa", Vector2(x0, -HALL_Z), Vector2(x1, -HALL_Z), T1, FORRO, EI, [[5.1, 0.9] + p1, [patamar, 0.8] + p1])
	_parede("parede_casa", Vector2(banheiro_x, -HALL_Z), Vector2(banheiro_x, HALL_Z), T1, FORRO, EI, [[0.0, 0.8] + p1])
	_parede("parede_casa", Vector2(MEIO_X, HALL_Z), Vector2(MEIO_X, z1), T1, FORRO, EI, [chamine.call(1.0)])
	_parede("parede_casa", Vector2(MEIO_X, z0), Vector2(MEIO_X, -HALL_Z), T1, FORRO, EI, [chamine.call(-1.0)])


## As duas chaminés de tijolo: as lareiras dos quatro cômodos de baixo (costas
## com costas), e as pilhas que saem pela cumeeira.
func _chamines() -> void:
	for lado: float in [-1.0, 1.0]:
		var z: float = lado * CHAMINE_Z
		var alto := CUMEEIRA.y + 0.9
		_bloco("tijolo", Vector3(2 * CHAMINE_MEIA.x, alto, 2 * CHAMINE_MEIA.y), Vector3(MEIO_X, alto / 2, z))
		# As bocas: a da frente (o escritório, a sala de estar) e a de trás (a
		# sala de jantar, a sala dos fundos), com a pedra da soleira e a cornija.
		for sx: float in [-1.0, 1.0]:
			var face: float = MEIO_X + sx * CHAMINE_MEIA.x
			_bloco("esmalte_preto", Vector3(0.02, 0.75, 0.9), Vector3(face + sx * 0.005, T0 + 0.4, z), Color(0.25, 0.22, 0.2), false)
			_bloco("pedra_lareira", Vector3(0.5, 0.06, 1.5), Vector3(face + sx * 0.25, T0 + 0.03, z), Color.WHITE, false)
			_bloco("pintura_branca", Vector3(0.18, 0.06, 1.6), Vector3(face + sx * 0.09, T0 + 1.25, z), Color.WHITE, false)
			for s2: float in [-1.0, 1.0]:
				_bloco("pintura_branca", Vector3(0.06, 1.22, 0.14), Vector3(face + sx * 0.03, T0 + 0.61, z + s2 * 0.6), Color.WHITE, false)
		# O capelo da pilha.
		_bloco("tijolo", Vector3(2 * CHAMINE_MEIA.x + 0.12, 0.15, 2 * CHAMINE_MEIA.y + 0.12), Vector3(MEIO_X, alto - 0.05, z), Color(0.8, 0.8, 0.8), false)


## A escada do vestíbulo: sobe para oeste rente à parede norte, com o corrimão
## do lado aberto, o pilar no pé; em cima, a balaustrada em volta do vão.
func _escada() -> void:
	var sobe := (T1 - T0) / DEGRAUS
	var largura := ESCADA_Z.y - ESCADA_Z.x
	var zc := (ESCADA_Z.x + ESCADA_Z.y) / 2
	for k in DEGRAUS:
		var x := ESCADA_X - (k + 0.5) * PISADA
		var topo := T0 + (k + 1) * sobe
		_bloco("madeira_escura", Vector3(PISADA, topo - T0, largura), Vector3(x, (T0 + topo) / 2, zc), Color.WHITE, false)
		_bloco("madeira_clara", Vector3(PISADA + 0.03, 0.03, largura), Vector3(x - 0.015, topo + 0.015, zc), Color.WHITE, false)
	var corre := DEGRAUS * PISADA
	_rampa(Vector3(ESCADA_X + 0.25, T0, zc), Vector3(ESCADA_X - corre, T1, zc), largura - 0.1)
	# O corrimão do lado aberto (z = ESCADA_Z.y), inclinado, com os balaústres.
	var a := rad_to_deg(atan2(T1 - T0, corre))
	var z := ESCADA_Z.y - 0.04
	_bloco("madeira_escura", Vector3(Vector2(corre, T1 - T0).length(), 0.07, 0.07), Vector3(ESCADA_X - corre / 2, (T0 + T1) / 2 + 0.9, z), Color.WHITE, false, Vector3(0, 0, -a))
	for k in range(0, DEGRAUS, 1):
		var x := ESCADA_X - (k + 0.5) * PISADA
		var topo := T0 + (k + 1) * sobe
		_bloco("pintura_branca", Vector3(0.035, 0.85, 0.035), Vector3(x, topo + 0.43, z), Color.WHITE, false)
	_bloco("madeira_escura", Vector3(0.14, 1.15, 0.14), Vector3(ESCADA_X + 0.05, T0 + 0.575, z), Color.WHITE, true)
	# O lado do vão, no térreo, embaixo da escada (o armário de baixo da escada).
	_parede("parede_casa", Vector2(ESCADA_X - corre, z + 0.06), Vector2(ESCADA_X - 1.4, z + 0.06), T0, T0 + 1.0, 0.08)
	# Em cima: a balaustrada ao longo do vão e na ponta leste.
	var x0 := ESCADA_X - corre
	_bloco("madeira_escura", Vector3(corre, 0.07, 0.07), Vector3(ESCADA_X - corre / 2 + 0.2, T1 + 0.9, ESCADA_Z.y), Color.WHITE, false)
	_bloco("madeira_escura", Vector3(0.07, 0.07, largura), Vector3(ESCADA_X, T1 + 0.9, zc), Color.WHITE, false)
	var x := x0 + 0.6
	while x < ESCADA_X:
		_bloco("pintura_branca", Vector3(0.035, 0.88, 0.035), Vector3(x, T1 + 0.45, ESCADA_Z.y), Color.WHITE, false)
		x += 0.16
	_col.append([Vector3(corre - 0.6, 1.0, 0.1), Vector3(ESCADA_X - (corre - 0.6) / 2, T1 + 0.5, ESCADA_Z.y)])
	_col.append([Vector3(0.1, 1.0, largura), Vector3(ESCADA_X, T1 + 0.5, zc)])


## O telhado de duas águas da casa, com a cumeeira de norte a sul, e as empenas
## de tabuado ao norte e ao sul, com a janela do sótão (a "meia" casa).
func _telhado_casa() -> void:
	var beiral := 0.45
	var esp := 0.16
	for lado: float in [-1.0, 1.0]:
		var borda: float = CASA_X.x if lado < 0 else CASA_X.y
		var corre := absf(borda - CUMEEIRA.x)
		var sobe := CUMEEIRA.y - BEIRAL
		var ang := atan2(sobe, corre)
		var compr := Vector2(corre, sobe).length() + beiral
		var meio := Vector3((CUMEEIRA.x + borda + lado * beiral * cos(ang)) / 2, (CUMEEIRA.y + BEIRAL - beiral * sin(ang)) / 2 + esp / 2, 0)
		_bloco("telhado", Vector3(compr, esp, CASA_Z.y - CASA_Z.x + 2 * beiral), meio, Color.WHITE, false, Vector3(0, 0, -lado * rad_to_deg(ang)))
		_bloco("pintura_branca", Vector3(0.05, 0.2, CASA_Z.y - CASA_Z.x + 2 * beiral), Vector3(borda + lado * (beiral * cos(ang) + 0.02), BEIRAL - beiral * sin(ang) + 0.02, 0), Color.WHITE, false)
	# A cumeeira.
	_bloco("telhado", Vector3(0.24, 0.12, CASA_Z.y - CASA_Z.x + 2 * beiral), Vector3(CUMEEIRA.x, CUMEEIRA.y + esp + 0.02, 0), Color(0.85, 0.85, 0.85), false)
	# As empenas, por fora e por dentro (o sótão).
	for lado: float in [-1.0, 1.0]:
		var z: float = lado * CASA_Z.y
		var a := Vector3(CASA_X.x, BEIRAL, z)
		var b := Vector3(CASA_X.y, BEIRAL, z)
		var c := Vector3(CUMEEIRA.x, CUMEEIRA.y, z)
		_tri(_obra("tabuado"), a, b, c, Vector3(0, 0, lado), Color.WHITE)
		var dz := Vector3(0, 0, -lado * E)
		_tri(_obra("forro_sotao"), a + dz, b + dz, c + dz, Vector3(0, 0, -lado), Color.WHITE)
		# A janela do sótão: posta por fora da empena (a demo não sobe ao sótão).
		var jz := z + lado * 0.03
		_bloco("pintura_branca", Vector3(0.8, 1.0, 0.06), Vector3(CUMEEIRA.x, BEIRAL + 1.6, jz), Color.WHITE, false)
		_bloco("vidro_janela", Vector3(0.64, 0.84, 0.02), Vector3(CUMEEIRA.x, BEIRAL + 1.6, jz + lado * 0.025), Color.WHITE, false)
		_bloco("pintura_branca", Vector3(0.64, 0.04, 0.03), Vector3(CUMEEIRA.x, BEIRAL + 1.6, jz + lado * 0.04), Color.WHITE, false)
		_bloco("pintura_branca", Vector3(0.04, 0.84, 0.03), Vector3(CUMEEIRA.x, BEIRAL + 1.6, jz + lado * 0.04), Color.WHITE, false)


## A porta georgiana: as pilastras, o entablamento com o frontão, a bandeira de
## vidro em cima; a folha branca de seis almofadas, aberta para dentro.
func _porta_georgiana() -> void:
	var x := CASA_X.y + 0.02
	var larg := 1.1
	var alto := 2.35
	for s: float in [-1.0, 1.0]:
		_bloco("pintura_branca", Vector3(0.1, alto + 0.1, 0.26), Vector3(x + 0.05, T0 + (alto + 0.1) / 2, s * (larg / 2 + 0.16)), Color.WHITE, false)
		_bloco("pintura_branca", Vector3(0.14, 0.12, 0.32), Vector3(x + 0.07, T0 + alto + 0.12, s * (larg / 2 + 0.16)), Color.WHITE, false)
	# O entablamento e o frontão (duas águas rasas).
	_bloco("pintura_branca", Vector3(0.2, 0.22, larg + 0.8), Vector3(x + 0.1, T0 + alto + 0.3, 0), Color.WHITE, false)
	for s: float in [-1.0, 1.0]:
		_bloco("pintura_branca", Vector3(0.22, 0.1, 0.85), Vector3(x + 0.11, T0 + alto + 0.6, s * 0.38), Color.WHITE, false, Vector3(s * 22.0, 0, 0))
	# A bandeira (o vidro sobre a porta, em leque).
	_bloco("vidro_janela", Vector3(0.02, 0.3, larg - 0.1), Vector3(x - 0.06, T0 + alto - 0.17, 0), Color.WHITE, false)
	for k in 5:
		_bloco("pintura_branca", Vector3(0.03, 0.3, 0.025), Vector3(x - 0.05, T0 + alto - 0.17, -0.4 + k * 0.2), Color.WHITE, false, Vector3(-30.0 + k * 15.0, 0, 0))
	# A folha: dobradiça ao sul (aberta, encosta do lado do escritório e deixa o
	# pé da escada livre), abre para dentro (oeste).
	var porta := _group(cena, "PortaFrente", Vector3(CASA_X.y - 0.08, T0, larg / 2 - 0.05), 180.0)
	var folha := _group(porta, "Folha")
	folha.rotation_degrees.y = 100.0
	_folha_seis_almofadas(folha, larg - 0.1, alto - 0.35, "pintura_branca")


## Uma folha de porta de seis almofadas (de 0 a `larg` em +Z, a face para +X),
## com o trinco de latão; a colisão vai junto.
func _folha_seis_almofadas(folha: Node3D, larg: float, alto: float, mat: String) -> void:
	_box(folha, "Madeira", Vector3(0.045, alto, larg), Vector3(0, alto / 2, larg / 2), mat)
	for i in 3:
		for jj in 2:
			var y := alto * (0.2 + i * 0.3)
			var z := larg * (0.28 + jj * 0.44)
			for sx: float in [-1.0, 1.0]:
				_box(folha, "Almofada%d%d%d" % [i, jj, sx + 1], Vector3(0.012, alto * 0.22, larg * 0.32), Vector3(sx * 0.026, y, z), mat)
	_box(folha, "Trinco", Vector3(0.1, 0.04, 0.05), Vector3(0, 1.0, larg - 0.08), "latao")
	_colisao(folha, "Colisao", [[Vector3(0.05, alto, larg), Vector3(0, alto / 2, larg / 2)]])


## As portas de dentro: abertas, encostadas na parede (o Ato III e o Interlúdio
## decidem quais fecham). A do escritório é a "branca de seis almofadas, com
## trinco de latão".
func _portas_internas() -> void:
	var g := _group(cena, "Portas")
	# [nome, dobradiça, eixo da parede ("x" ou "z"), largura, giro aberto]
	var portas := [
		["Escritorio", Vector3(5.1 - 0.42, T0, HALL_Z), "x", 0.84, -95.0],
		["SalaEstar", Vector3(5.1 - 0.42, T0, -HALL_Z), "x", 0.84, 95.0],
		["SalaJantar", Vector3(-1.5 - 0.42, T0, HALL_Z), "x", 0.84, -95.0],
		["SalaFundos", Vector3(-1.5 - 0.42, T0, -HALL_Z), "x", 0.84, 95.0],
		["EscritorioJantar", Vector3(MEIO_X, T0, 2.15 - 0.42), "z", 0.84, 95.0],
		["QuartoHospedes", Vector3(3.0 - 0.42, T1, HALL_Z), "x", 0.84, -95.0],
		["QuartoAkeley", Vector3(5.1 - 0.42, T1, -HALL_Z), "x", 0.84, 95.0],
	]
	for p: Array in portas:
		var grupo := _group(g, p[0], p[1])
		# A folha de seis almofadas é feita com a largura em +Z e a face em +X;
		# numa parede ao longo de X, gira 90° para a largura correr em +X. Aberta,
		# entra no cômodo (giro negativo: para o sul; positivo: para o norte).
		var base := _group(grupo, "Base")
		base.rotation_degrees.y = 90.0 if p[2] == "x" else 0.0
		var folha := _group(base, "Folha")
		folha.rotation_degrees.y = p[4]
		_folha_seis_almofadas(folha, p[3], 2.1, "pintura_branca")


## As janelas da casa (guilhotina de seis por seis: o caixilho, as travessas, o
## vidro) e as venezianas verdes abertas contra a parede. As venezianas são nós
## à parte (F6: fechá-las).
func _janelas_da_casa(leste: Array, oeste: Array, norte: Array, sul: Array) -> void:
	var g := _group(cena, "Janelas")
	var n := 0
	for lado: Array in [[leste, Vector3.RIGHT, CASA_X.y], [oeste, Vector3.LEFT, CASA_X.x], [norte, Vector3.FORWARD, CASA_Z.x], [sul, Vector3.BACK, CASA_Z.y]]:
		for ab: Array in lado[0]:
			var alto: float = ab[3] - ab[2]
			if ab[2] <= T0 + 0.01 or alto < 0.9:
				continue  # as portas (e a janelinha do banheiro, à parte)
			var fora: Vector3 = lado[1]
			var c := Vector3(lado[2], 0, ab[0]) if fora.x != 0 else Vector3(ab[0], 0, lado[2])
			c.y = (ab[2] + ab[3]) / 2
			_janela(g, "Janela%d" % n, c, fora, ab[1], alto)
			n += 1
	# A janelinha do banheiro (sem venezianas).
	_janela(g, "JanelaBanheiro", Vector3(CASA_X.x, T1 + 1.6, 0.0), Vector3.LEFT, 0.6, 0.8, false)


func _janela(g: Node3D, nome: String, c: Vector3, fora: Vector3, larg: float, alto: float, venezianas := true) -> void:
	var ao_longo := Vector3(-fora.z, 0, fora.x).abs()
	var esp := fora.abs()
	var meio := c - fora * (E / 2)
	# O caixilho em volta do vão (por fora), o peitoril, a verga.
	var moldura := 0.09
	for s: float in [-1.0, 1.0]:
		_bloco("pintura_branca", esp * 0.05 + ao_longo * moldura + Vector3.UP * (alto + 2 * moldura), c + fora * 0.02 + ao_longo * s * (larg / 2 + moldura / 2), Color.WHITE, false)
	_bloco("pintura_branca", esp * 0.08 + ao_longo * (larg + 0.3) + Vector3.UP * 0.06, c + fora * 0.04 + Vector3.UP * (-alto / 2 - 0.03), Color.WHITE, false)
	_bloco("pintura_branca", esp * 0.08 + ao_longo * (larg + 0.34) + Vector3.UP * 0.14, c + fora * 0.04 + Vector3.UP * (alto / 2 + 0.07), Color.WHITE, false)
	# As duas folhas da guilhotina, sem vidro (o vidro opaco do PSX não deixava ver
	# lá fora, e na noite do telhado as janelas são seteiras): as travessas, seis
	# por seis.
	for k in 2:
		var cy := c.y - alto / 4 + k * alto / 2
		var p := Vector3(meio.x, cy, meio.z) + fora * (0.02 - k * 0.04)
		_bloco("pintura_branca", esp * 0.035 + ao_longo * larg + Vector3.UP * 0.035, p + Vector3.UP * (alto / 4 - 0.0175), Color.WHITE, false)
		_bloco("pintura_branca", esp * 0.035 + ao_longo * larg + Vector3.UP * 0.035, p - Vector3.UP * (alto / 4 - 0.0175), Color.WHITE, false)
		_bloco("pintura_branca", esp * 0.03 + ao_longo * larg + Vector3.UP * 0.02, p, Color.WHITE, false)
		for s: float in [-1.0, 1.0]:
			_bloco("pintura_branca", esp * 0.035 + ao_longo * 0.035 + Vector3.UP * (alto / 2), p + ao_longo * s * (larg / 2 - 0.0175), Color.WHITE, false)
			_bloco("pintura_branca", esp * 0.03 + ao_longo * 0.02 + Vector3.UP * (alto / 2), p + ao_longo * s * larg / 6, Color.WHITE, false)
	# O vidro barra o corpo (não a mira, que vê através: a janela é seteira na F7).
	_col.append([esp * 0.1 + ao_longo * larg + Vector3.UP * alto, meio])
	if not venezianas:
		return
	var vg := _group(g, nome, Vector3(c.x, c.y, c.z))
	var a := Vector3(-fora.z, 0, fora.x)
	for s: float in [-1.0, 1.0]:
		# A dobradiça na borda do vão, rente ao tabuado. A base põe o +X local
		# para o meio do vão (fechada, a folha cobre a metade dela); aberta, gira
		# 170° para fora e deita contra a parede (`aberta`, em graus, para a F6).
		var dob := _group(vg, "Veneziana%s" % ("A" if s < 0 else "B"))
		dob.position = a * s * (larg / 2 + 0.01) + fora * 0.06
		var x := -s * a
		var base := Basis(x, Vector3.UP, x.cross(Vector3.UP))
		var aberta := -170.0 if base.z.dot(fora) > 0.0 else 170.0
		dob.basis = base * Basis(Vector3.UP, deg_to_rad(aberta))
		dob.set_meta(&"aberta", aberta)
		_box(dob, "Folha", Vector3(larg / 2, alto, 0.035), Vector3(larg / 4, 0, 0), "veneziana")
		for k in 3:
			_box(dob, "Ripa%d" % k, Vector3(larg / 2 - 0.06, 0.03, 0.012), Vector3(larg / 4, -alto / 3 + k * alto / 3, 0.022 * signf(base.z.dot(fora))), "veneziana")


## Os móveis de bloco de cada cômodo (o acabamento vem depois; o que importa
## agora é a escala e por onde se anda).
func _moveis() -> void:
	var y := T0
	# O escritório (sudeste): a mesa grande do meio, a poltrona no canto mais
	# escuro (sudoeste, longe da porta e das janelas), as estantes contra o
	# vestíbulo, a escrivaninha sob a janela, o suporte do fonógrafo no canto.
	_movel("madeira_escura", Vector3(1.6, 0.06, 0.95), Vector3(3.4, y + 0.75, 3.8))
	for s: Vector2 in [Vector2(-0.7, -0.4), Vector2(0.7, -0.4), Vector2(-0.7, 0.4), Vector2(0.7, 0.4)]:
		_bloco("madeira_escura", Vector3(0.07, 0.72, 0.07), Vector3(3.4 + s.x, y + 0.36, 3.8 + s.y), Color.WHITE, false)
	_col.append([Vector3(1.6, 0.78, 0.95), Vector3(3.4, y + 0.39, 3.8)])
	_poltrona(Vector3(1.75, y, 5.15), 135.0)
	_movel("madeira_escura", Vector3(2.8, 2.2, 0.35), Vector3(3.2, y + 1.1, HALL_Z + 0.25))
	_movel("madeira_escura", Vector3(0.6, 0.78, 1.2), Vector3(5.45, y + 0.39, 3.7))
	_movel("madeira_escura", Vector3(0.5, 0.9, 0.5), Vector3(5.45, y + 0.45, 1.85))
	# A sala de estar (nordeste): o sofá (onde Noyes ronca no Ato III), as
	# poltronas, a mesinha, o tapete.
	_movel("estofado", Vector3(2.0, 0.45, 0.85), Vector3(3.6, y + 0.225, -5.2))
	_movel("estofado", Vector3(2.0, 0.5, 0.2), Vector3(3.6, y + 0.65, -5.55), Color.WHITE, false)
	_poltrona(Vector3(2.0, y, -2.6), 45.0)
	_poltrona(Vector3(5.0, y, -2.6), -45.0)
	_movel("madeira_escura", Vector3(1.0, 0.45, 0.6), Vector3(3.6, y + 0.225, -3.8))
	_bloco("tapete", Vector3(3.0, 0.01, 2.2), Vector3(3.6, y + 0.005, -3.8), Color.WHITE, false)
	# A sala de jantar (sudoeste): a mesa e as cadeiras, o aparador.
	_movel("madeira_escura", Vector3(2.0, 0.06, 1.0), Vector3(-1.0, y + 0.75, 3.8))
	_col.append([Vector3(2.0, 0.78, 1.0), Vector3(-1.0, y + 0.39, 3.8)])
	for i in 3:
		for s: float in [-1.0, 1.0]:
			_cadeira(Vector3(-1.7 + i * 0.7, y, 3.8 + s * 0.75), 0.0 if s > 0 else 180.0)
	_movel("madeira_escura", Vector3(1.6, 0.9, 0.45), Vector3(-1.0, y + 0.45, 5.5))
	# A sala dos fundos (noroeste): o armário dos rifles, a bancada, as caixas.
	_movel("madeira_escura", Vector3(1.4, 1.9, 0.4), Vector3(-1.0, y + 0.95, -5.5))
	_movel("madeira_clara", Vector3(1.8, 0.85, 0.7), Vector3(-2.3, y + 0.425, -3.0), Color.WHITE, true, Vector3(0, 90, 0))
	_movel("papelao_escuro", Vector3(0.6, 0.5, 0.5), Vector3(0.2, y + 0.25, -2.2))
	# O vestíbulo: a mesinha de entrada e o cabide.
	_movel("madeira_escura", Vector3(0.4, 0.8, 0.9), Vector3(0.6, y + 0.4, 1.1))
	# Primeiro andar. O quarto de hóspedes (sobre o escritório): a cama, o
	# guarda-roupa, o lavatório, a cadeira.
	var y1 := T1
	_cama(Vector3(3.5, y1, 4.6), 0.0)
	_movel("madeira_escura", Vector3(1.0, 2.0, 0.55), Vector3(1.75, y1 + 1.0, 2.0))
	_movel("madeira_clara", Vector3(0.7, 0.8, 0.45), Vector3(5.5, y1 + 0.4, 2.3))
	_cadeira(Vector3(5.0, y1, 3.6), -90.0)
	# O quarto de Akeley (sobre a sala de estar): a cama, a cômoda.
	_cama(Vector3(3.5, y1, -4.6), 180.0)
	_movel("madeira_escura", Vector3(1.2, 1.0, 0.5), Vector3(1.75, y1 + 0.5, -2.3))
	# O banheiro: a banheira, a pia, a privada.
	_movel("porcelana", Vector3(0.75, 0.55, 1.6), Vector3(-2.35, y1 + 0.275, 0.4))
	_movel("porcelana", Vector3(0.45, 0.8, 0.35), Vector3(-1.4, y1 + 0.4, -1.1))
	_movel("porcelana", Vector3(0.4, 0.42, 0.55), Vector3(-1.45, y1 + 0.21, 1.0))
	# Os quartos de trás: um de costura (sudoeste), um de guardados (noroeste).
	_cama(Vector3(-1.2, y1, 4.8), 0.0)
	_movel("papelao_escuro", Vector3(0.8, 0.6, 0.6), Vector3(-2.2, y1 + 0.3, -5.2))
	_movel("papelao_escuro", Vector3(0.6, 0.5, 0.6), Vector3(-1.3, y1 + 0.25, -5.2))
	_movel("madeira_clara", Vector3(0.5, 1.6, 1.2), Vector3(0.6, y1 + 0.8, -3.0))


func _movel(mat: String, tam: Vector3, c: Vector3, cor := Color.WHITE, col := true, rot := Vector3.ZERO) -> void:
	_bloco(mat, tam, c, cor, col, rot)


## A poltrona grande (o assento, o encosto alto, os braços), virada para `giro`.
func _poltrona(p: Vector3, giro: float) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
	var r := Vector3(0, giro, 0)
	_bloco("estofado", Vector3(0.8, 0.45, 0.8), p + b * Vector3(0, 0.225, 0), Color.WHITE, false, r)
	_bloco("estofado", Vector3(0.8, 0.75, 0.18), p + b * Vector3(0, 0.8, 0.33), Color.WHITE, false, r)
	for s: float in [-1.0, 1.0]:
		_bloco("estofado", Vector3(0.14, 0.25, 0.8), p + b * Vector3(s * 0.38, 0.55, 0), Color.WHITE, false, r)
	_col.append([Vector3(0.8, 1.2, 0.8), p + Vector3(0, 0.6, 0), r])


func _cadeira(p: Vector3, giro: float) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
	var r := Vector3(0, giro, 0)
	_bloco("madeira_escura", Vector3(0.42, 0.04, 0.42), p + b * Vector3(0, 0.45, 0), Color.WHITE, false, r)
	_bloco("madeira_escura", Vector3(0.42, 0.5, 0.04), p + b * Vector3(0, 0.72, 0.19), Color.WHITE, false, r)
	for s: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_bloco("madeira_escura", Vector3(0.04, 0.45, 0.04), p + b * Vector3(s.x * 0.18, 0.225, s.y * 0.18), Color.WHITE, false, r)
	_col.append([Vector3(0.45, 0.9, 0.45), p + Vector3(0, 0.45, 0), r])


func _cama(p: Vector3, giro: float) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
	var r := Vector3(0, giro, 0)
	_bloco("lencol", Vector3(1.2, 0.25, 1.95), p + b * Vector3(0, 0.5, 0), Color.WHITE, false, r)
	_bloco("la_escura", Vector3(1.25, 0.06, 1.3), p + b * Vector3(0, 0.64, -0.3), Color.WHITE, false, r)
	_bloco("madeira_escura", Vector3(1.3, 1.1, 0.08), p + b * Vector3(0, 0.55, 1.0), Color.WHITE, false, r)
	_bloco("madeira_escura", Vector3(1.3, 0.7, 0.08), p + b * Vector3(0, 0.35, -1.0), Color.WHITE, false, r)
	_col.append([Vector3(1.3, 0.7, 2.05), p + Vector3(0, 0.35, 0), r])


# --- O puxado da cozinha ------------------------------------------------------------------

## O puxado baixo (de um andar só), atrás da sala de jantar: a cozinha, com o
## fogão de ferro, a pia de pedra-sabão, a mesa; a despensa no canto (as
## máscaras de gás, F6); a porta para o quintal de trás e a do galpão de lenha.
func _puxado() -> void:
	var px := PUXADO_X
	var pz := PUXADO_Z
	var alto := PUXADO_ALTO
	var porta := [T0, T0 + 2.15]
	var j := [T0 + 0.9, T0 + 2.1]
	var norte := [[-6.5, 0.9] + porta, [-4.5, 0.8] + j]
	var sul := [[-5.0, 0.8] + j, [-7.6, 0.8] + j]
	var oeste := [[4.6, 0.9] + porta]
	_parede("pedra_campo", Vector2(px.x, pz.x + E / 2), Vector2(px.y, pz.x + E / 2), -0.3, T0, E + 0.06)
	_parede("pedra_campo", Vector2(px.x, pz.y - E / 2), Vector2(px.y, pz.y - E / 2), -0.3, T0, E + 0.06)
	_parede("pedra_campo", Vector2(px.x + E / 2, pz.x), Vector2(px.x + E / 2, pz.y), -0.3, T0, E + 0.06)
	_parede("tabuado", Vector2(px.x, pz.x + 0.07), Vector2(px.y, pz.x + 0.07), T0, alto, 0.14, norte)
	_parede("tabuado", Vector2(px.x, pz.y - 0.07), Vector2(px.y, pz.y - 0.07), T0, alto, 0.14, sul)
	_parede("tabuado", Vector2(px.x + 0.07, pz.x), Vector2(px.x + 0.07, pz.y), T0, alto, 0.14, oeste)
	_parede("parede_casa", Vector2(px.x + 0.14, pz.x + 0.17), Vector2(px.y, pz.x + 0.17), T0, alto, 0.06, norte, Color.WHITE, false)
	_parede("parede_casa", Vector2(px.x + 0.14, pz.y - 0.17), Vector2(px.y, pz.y - 0.17), T0, alto, 0.06, sul, Color.WHITE, false)
	_parede("parede_casa", Vector2(px.x + 0.17, pz.x + 0.2), Vector2(px.x + 0.17, pz.y - 0.2), T0, alto, 0.06, oeste, Color.WHITE, false)
	_bloco("piso", Vector3(px.y - px.x - 0.2, 0.1, pz.y - pz.x - 0.2), Vector3((px.x + px.y) / 2 + 0.1, T0 - 0.05, (pz.x + pz.y) / 2))
	_bloco("teto", Vector3(px.y - px.x - 0.2, 0.08, pz.y - pz.x - 0.2), Vector3((px.x + px.y) / 2 + 0.1, alto + 0.04, (pz.x + pz.y) / 2), Color.WHITE, false)
	var gj := _group(cena, "JanelasPuxado")
	_janela(gj, "JanelaN", Vector3(-4.5, (j[0] + j[1]) / 2, pz.x), Vector3.FORWARD, 0.8, j[1] - j[0])
	_janela(gj, "JanelaS1", Vector3(-5.0, (j[0] + j[1]) / 2, pz.y), Vector3.BACK, 0.8, j[1] - j[0])
	_janela(gj, "JanelaS2", Vector3(-7.6, (j[0] + j[1]) / 2, pz.y), Vector3.BACK, 0.8, j[1] - j[0])
	# A despensa, no canto noroeste.
	var dx := -7.3
	var dz := 3.0
	_parede("parede_casa", Vector2(dx, pz.x + 0.2), Vector2(dx, dz), T0, alto, 0.1, [[2.0, 0.75, T0, T0 + 2.05]])
	_parede("parede_casa", Vector2(px.x + 0.2, dz), Vector2(dx, dz), T0, alto, 0.1)
	_movel("madeira_clara", Vector3(1.4, 1.9, 0.35), Vector3(-8.1, T0 + 0.95, pz.x + 0.42))
	# O telhado de duas águas, a cumeeira de leste a oeste, mais baixo que o beiral
	# da casa: é dele que o cão pula para o telhado grande.
	var meio_z := (pz.x + pz.y) / 2
	var corre := (pz.y - pz.x) / 2
	var sobe := 1.9
	var ang := atan2(sobe, corre)
	var beiral := 0.35
	for s: float in [-1.0, 1.0]:
		var compr := Vector2(corre, sobe).length() + beiral
		var c := Vector3((px.x + px.y) / 2 - 0.2, alto + sobe / 2 - beiral * sin(ang) / 2 + 0.08, meio_z + s * (corre + beiral * cos(ang)) / 2)
		_bloco("telhado", Vector3(px.y - px.x + 0.4, 0.14, compr), c, Color.WHITE, false, Vector3(s * rad_to_deg(ang), 0, 0))
	var a := Vector3(px.x, alto, pz.x)
	var b := Vector3(px.x, alto, pz.y)
	var t := Vector3(px.x, alto + sobe, meio_z)
	_tri(_obra("tabuado"), a, b, t, Vector3.LEFT, Color.WHITE)
	_tri(_obra("forro_sotao"), a + Vector3(0.14, 0, 0), b + Vector3(0.14, 0, 0), t + Vector3(0.14, 0, 0), Vector3.RIGHT, Color.WHITE)
	# A cozinha: o fogão de ferro com a chaminé de lata, a pia sob a janela, a
	# mesa, o armário.
	_movel("esmalte_preto", Vector3(1.1, 0.8, 0.65), Vector3(-4.4, T0 + 0.4, pz.y - 0.6))
	_bloco("ferro", Vector3(0.14, alto - T0 - 0.8, 0.14), Vector3(-4.4, (T0 + 0.8 + alto) / 2, pz.y - 0.75), Color.WHITE, false)
	_movel("pedra_lareira", Vector3(1.0, 0.85, 0.55), Vector3(-5.0, T0 + 0.425, pz.y - 0.5))
	_movel("madeira_clara", Vector3(1.4, 0.75, 0.8), Vector3(-5.8, T0 + 0.375, 3.2))
	_movel("madeira_escura", Vector3(0.45, 2.0, 1.2), Vector3(-3.5, T0 + 1.0, 1.9))
	# Os degraus da porta do quintal (norte) e a rampa.
	_bloco("granito", Vector3(1.2, 0.3, 0.45), Vector3(-6.5, 0.15, pz.x - 0.25), Color.WHITE, false)
	_rampa(Vector3(-6.5, 0, pz.x - 1.1), Vector3(-6.5, T0, pz.x + 0.1), 1.1)
	# Os degraus da porta do galpão (oeste).
	_rampa(Vector3(px.x - 1.0, 0, 4.6), Vector3(px.x + 0.1, T0, 4.6), 1.0)


# --- As dependências: o galpão de lenha, a arcada, o celeiro, o galinheiro --------------

func _dependencias() -> void:
	_galpao_lenha()
	_arcada()
	_celeiro()
	_galinheiro()


## O galpão de lenha (encostado no puxado, a oeste): aberto para o norte, a
## lenha empilhada, o cepo e o machado. Onde a coisa morta evapora (Interlúdio
## beat 6) e onde a pedra negra espera no Ato III.
func _galpao_lenha() -> void:
	var x := Vector2(-13.0, PUXADO_X.x)
	var z := PUXADO_Z
	var alto := 2.6
	_parede("celeiro", Vector2(x.x, z.y - 0.06), Vector2(x.y, z.y - 0.06), 0.0, alto, 0.12)
	_parede("celeiro", Vector2(x.x + 0.06, z.x), Vector2(x.x + 0.06, z.y), 0.0, alto, 0.12)
	_bloco("chao_terra", Vector3(x.y - x.x, 0.04, z.y - z.x), Vector3((x.x + x.y) / 2, 0.02, (z.x + z.y) / 2), Color.WHITE, false)
	# Um telhado de uma água, caindo para o norte (a boca).
	var ang := atan2(0.7, z.y - z.x)
	var compr := Vector2(z.y - z.x, 0.7).length() + 0.5
	_bloco("telhado", Vector3(x.y - x.x + 0.3, 0.12, compr), Vector3((x.x + x.y) / 2, alto + 0.35, (z.x + z.y) / 2 - 0.2), Color.WHITE, false, Vector3(rad_to_deg(ang), 0, 0))
	for xx: float in [x.x + 0.1, (x.x + x.y) / 2]:
		_bloco("madeira_escura", Vector3(0.14, alto - 0.3, 0.14), Vector3(xx, (alto - 0.3) / 2, z.x + 0.1))
	# A lenha: fileiras de toras cortadas contra a parede de trás.
	var lenha := _obra("madeira_clara")
	for fila in 5:
		for k in 14:
			var c := Vector3(x.x + 0.4 + k * 0.27, 0.13 + fila * 0.24, z.y - 0.5)
			_face_toras(lenha, c)
	_col.append([Vector3(3.8, 1.3, 0.6), Vector3(x.x + 2.2, 0.65, z.y - 0.5)])
	_movel("madeira_escura", Vector3(0.45, 0.45, 0.45), Vector3(-11.0, 0.225, 2.6))
	_bloco("madeira_clara", Vector3(0.04, 0.75, 0.04), Vector3(-11.0, 0.7, 2.6), Color.WHITE, false, Vector3(20, 0, 10))
	_bloco("ferro", Vector3(0.03, 0.12, 0.18), Vector3(-11.08, 0.45, 2.6), Color.WHITE, false, Vector3(20, 0, 10))


## Uma tora deitada (de leste a oeste), a ponta clara do corte para o norte.
func _face_toras(lenha: Cidade.Malha, c: Vector3) -> void:
	lenha.caixa(Vector3(0.24, 0.22, 0.6), c, Color(0.75, 0.6, 0.45) * _rng.randf_range(0.8, 1.1))


## A arcada coberta do galpão de lenha ao celeiro (o "ligados por arcadas").
func _arcada() -> void:
	var x := Vector2(-12.6, -9.4)
	var z := Vector2(-8.0, PUXADO_Z.x)
	var alto := 2.7
	var zz := z.x
	while zz <= z.y + 0.01:
		for xx: float in [x.x, x.y]:
			_bloco("pintura_branca", Vector3(0.16, alto, 0.16), Vector3(xx, alto / 2, zz))
		zz += 3.0
	_bloco("telhado", Vector3(x.y - x.x + 0.6, 0.14, z.y - z.x + 0.4), Vector3((x.x + x.y) / 2, alto + 0.07, (z.x + z.y) / 2), Color.WHITE, false)
	for xx: float in [x.x, x.y]:
		_bloco("pintura_branca", Vector3(0.14, 0.24, z.y - z.x), Vector3(xx, alto - 0.12, (z.x + z.y) / 2), Color.WHITE, false)


## O celeiro grande, de tábuas vermelhas gastas: o portão de correr aberto ao
## sul, o palheiro em cima, as baias; o telhado de duas águas de norte a sul.
func _celeiro() -> void:
	var x := Vector2(-21.0, -9.0)
	var z := Vector2(-21.0, -8.0)
	var alto := 5.0
	var cumeeira := Vector2((x.x + x.y) / 2, alto + 3.6)
	var portao := [[cumeeira.x, 3.6, 0.0, 3.8]]
	_parede("celeiro", Vector2(x.x, z.y - 0.08), Vector2(x.y, z.y - 0.08), 0.0, alto, 0.16, portao)
	_parede("celeiro", Vector2(x.x, z.x + 0.08), Vector2(x.y, z.x + 0.08), 0.0, alto, 0.16, [[-12.0, 0.6, 1.5, 2.3]])
	_parede("celeiro", Vector2(x.x + 0.08, z.x), Vector2(x.x + 0.08, z.y), 0.0, alto, 0.16, [[-14.5, 0.6, 1.5, 2.3]])
	_parede("celeiro", Vector2(x.y - 0.08, z.x), Vector2(x.y - 0.08, z.y), 0.0, alto, 0.16, [[-12.0, 1.0, 0.0, 2.1], [-17.5, 0.6, 1.5, 2.3]])
	for lado: float in [-1.0, 1.0]:
		var zf: float = z.y if lado > 0 else z.x
		var a := Vector3(x.x, alto, zf)
		var b := Vector3(x.y, alto, zf)
		var t := Vector3(cumeeira.x, cumeeira.y, zf)
		_tri(_obra("celeiro"), a, b, t, Vector3(0, 0, lado), Color.WHITE)
		_tri(_obra("celeiro"), a - Vector3(0, 0, lado * 0.16), b - Vector3(0, 0, lado * 0.16), t - Vector3(0, 0, lado * 0.16), Vector3(0, 0, -lado), Color(0.7, 0.7, 0.7))
	# A porta do palheiro, na empena sul (escura, fechada).
	_bloco("madeira_escura", Vector3(1.6, 1.6, 0.06), Vector3(cumeeira.x, alto + 1.1, z.y + 0.03), Color.WHITE, false)
	# O portão de correr, aberto: as duas folhas encostadas na parede, no trilho.
	for s: float in [-1.0, 1.0]:
		_bloco("celeiro", Vector3(1.85, 3.9, 0.08), Vector3(cumeeira.x + s * (1.8 + 0.95), 1.95, z.y + 0.1), Color(0.9, 0.9, 0.9))
		_bloco("pintura_branca", Vector3(1.85, 0.1, 0.09), Vector3(cumeeira.x + s * (1.8 + 0.95), 1.95, z.y + 0.11), Color.WHITE, false, Vector3(0, 0, s * 64.0))
	_bloco("ferro", Vector3(7.6, 0.08, 0.08), Vector3(cumeeira.x, 3.95, z.y + 0.12), Color.WHITE, false)
	# Os beirais pintados de branco nos cantos.
	for xx: float in [x.x, x.y]:
		for zz: float in [z.x, z.y]:
			_bloco("pintura_branca", Vector3(0.2, alto, 0.2), Vector3(xx, alto / 2, zz), Color.WHITE, false)
	# O telhado.
	var esp := 0.16
	var beiral := 0.4
	for lado: float in [-1.0, 1.0]:
		var borda: float = x.x if lado < 0 else x.y
		var corre := absf(borda - cumeeira.x)
		var sobe := cumeeira.y - alto
		var ang := atan2(sobe, corre)
		var compr := Vector2(corre, sobe).length() + beiral
		var meio := Vector3((cumeeira.x + borda + lado * beiral * cos(ang)) / 2, (cumeeira.y + alto - beiral * sin(ang)) / 2 + esp / 2, (z.x + z.y) / 2)
		_bloco("telhado", Vector3(compr, esp, z.y - z.x + 2 * beiral), meio, Color.WHITE, false, Vector3(0, 0, -lado * rad_to_deg(ang)))
	# O chão de terra, o palheiro sobre a metade norte (num tablado em pilares),
	# a palha, as baias a oeste, a carroça.
	_bloco("chao_terra", Vector3(x.y - x.x, 0.04, z.y - z.x), Vector3(cumeeira.x, 0.02, (z.x + z.y) / 2), Color(0.85, 0.85, 0.85), false)
	_bloco("madeira_clara", Vector3(x.y - x.x - 0.3, 0.14, 5.0), Vector3(cumeeira.x, 3.0, z.x + 2.6), Color.WHITE, false)
	for xx: float in [x.x + 1.0, cumeeira.x - 2.0, cumeeira.x + 2.0, x.y - 1.0]:
		_bloco("madeira_escura", Vector3(0.2, 2.95, 0.2), Vector3(xx, 1.475, z.x + 5.0))
	_bloco("palha", Vector3(x.y - x.x - 1.0, 1.0, 4.4), Vector3(cumeeira.x, 3.55, z.x + 2.5), Color.WHITE, false)
	for k in 3:
		var zb := z.x + 6.2 + k * 2.0
		_bloco("madeira_escura", Vector3(2.4, 1.3, 0.08), Vector3(x.x + 1.3, 0.65, zb))
	_movel("madeira_clara", Vector3(1.6, 0.6, 3.0), Vector3(-11.2, 0.8, -15.0))
	_movel("palha", Vector3(1.2, 0.8, 0.8), Vector3(-18.5, 0.4, -10.0), Color.WHITE, true, Vector3(0, 15, 0))
	# Um portão de verdade não tem colisão no vão; as folhas abertas, sim.


## O galinheiro e o chiqueiro, num galpão baixo de uma água encostado no celeiro
## (a oeste), com o cercado dos porcos na frente. (No Ato III: nem um cacarejo,
## nem um grunhido.)
func _galinheiro() -> void:
	var x := Vector2(-27.0, -21.0)
	var z := Vector2(-19.0, -11.0)
	var alto := 2.4
	_parede("celeiro", Vector2(x.x, z.y - 0.06), Vector2(x.y, z.y - 0.06), 0.0, alto, 0.12, [[-25.5, 0.8, 0.0, 1.9], [-22.8, 0.6, 1.1, 1.7]])
	_parede("celeiro", Vector2(x.x, z.x + 0.06), Vector2(x.y, z.x + 0.06), 0.0, alto, 0.12)
	_parede("celeiro", Vector2(x.x + 0.06, z.x), Vector2(x.x + 0.06, z.y), 0.0, alto, 0.12, [[-15.0, 0.6, 1.1, 1.7]])
	var ang := atan2(0.8, x.y - x.x)
	_bloco("telhado", Vector3(Vector2(x.y - x.x, 0.8).length() + 0.5, 0.12, z.y - z.x + 0.5), Vector3((x.x + x.y) / 2 - 0.2, alto + 0.45, (z.x + z.y) / 2), Color.WHITE, false, Vector3(0, 0, rad_to_deg(ang)))
	# O cercado dos porcos (ao sul): mourões e três tábuas.
	var cerca := [Vector2(x.x, z.y), Vector2(x.x, z.y + 4.0), Vector2(x.y, z.y + 4.0), Vector2(x.y, z.y)]
	for i in 3:
		_cerca(cerca[i], cerca[i + 1], "madeira_escura")


## Uma cerca de mourões e três tábuas de `de` a `ate`.
func _cerca(de: Vector2, ate: Vector2, mat: String) -> void:
	var compr := de.distance_to(ate)
	var dir := (ate - de) / compr
	var giro := -rad_to_deg(atan2(dir.y, dir.x))
	var n := maxi(1, ceili(compr / 2.0))
	for i in n + 1:
		var p := de + dir * compr * i / n
		_bloco(mat, Vector3(0.12, 1.2, 0.12), Vector3(p.x, 0.6, p.y), Color.WHITE, false)
	var meio := (de + ate) / 2
	for k in 3:
		_bloco(mat, Vector3(compr, 0.1, 0.03), Vector3(meio.x, 0.35 + k * 0.33, meio.y), Color(0.9, 0.9, 0.9), false, Vector3(0, giro, 0))
	_col.append([Vector3(compr, 1.4, 0.2), Vector3(meio.x, 0.7, meio.y), Vector3(0, giro, 0)])


# --- O canil ---------------------------------------------------------------------------

## O canil dos doze cães: um galpão baixo e comprido de doze baias, cada uma com
## a portinhola e a plaquinha com o nome; o cercado de tela na frente.
func _canil() -> void:
	var g := _group(cena, "Canil")
	var x := Vector2(-8.0, 2.8)
	var z := Vector2(-13.0, -10.5)
	var alto := 1.7
	var baia := (x.y - x.x) / CAES.size()
	var bocas := []
	for i in CAES.size():
		bocas.append([x.x + (i + 0.5) * baia, 0.5, 0.0, 0.7])
	_parede("celeiro", Vector2(x.x, z.y - 0.05), Vector2(x.y, z.y - 0.05), 0.0, alto - 0.3, 0.1, bocas)
	_parede("celeiro", Vector2(x.x, z.x + 0.05), Vector2(x.y, z.x + 0.05), 0.0, alto, 0.1)
	for xx: float in [x.x + 0.05, x.y - 0.05]:
		_parede("celeiro", Vector2(xx, z.x), Vector2(xx, z.y), 0.0, alto - 0.15, 0.1)
	var ang := atan2(0.3, z.y - z.x)
	_bloco("telhado", Vector3(x.y - x.x + 0.4, 0.1, Vector2(z.y - z.x, 0.3).length() + 0.5), Vector3((x.x + x.y) / 2, alto - 0.1, (z.x + z.y) / 2 + 0.1), Color.WHITE, false, Vector3(rad_to_deg(ang), 0, 0))
	for i in CAES.size():
		var cx := x.x + (i + 0.5) * baia
		if i > 0:
			_bloco("celeiro", Vector3(0.06, alto - 0.35, z.y - z.x - 0.2), Vector3(x.x + i * baia, (alto - 0.35) / 2, (z.x + z.y) / 2), Color(0.85, 0.85, 0.85), false)
		_bloco("palha", Vector3(baia - 0.15, 0.08, 1.2), Vector3(cx, 0.04, (z.x + z.y) / 2 - 0.2), Color.WHITE, false)
		var placa := _group(g, "Placa%s" % CAES[i], Vector3(cx, 1.0, z.y + 0.01))
		_box(placa, "Tabua", Vector3(0.62, 0.14, 0.02), Vector3.ZERO, "madeira_clara")
		var nome := Label3D.new()
		nome.name = "Nome"
		nome.text = CAES[i]
		nome.font_size = 48
		nome.pixel_size = 0.0016
		nome.modulate = Color(0.1, 0.07, 0.05)
		nome.position = Vector3(0, 0, 0.012)
		_add(placa, nome)
	# O cercado de tela na frente: mourões, a tela (três arames, provisória) e a
	# porteira aberta.
	var fz := -7.0
	var cantos := [Vector2(x.x, z.y), Vector2(x.x, fz), Vector2(-1.0, fz)]
	_tela(cantos[0], cantos[1])
	_tela(cantos[1], cantos[2])
	_tela(Vector2(0.4, fz), Vector2(x.y, fz))
	_tela(Vector2(x.y, fz), Vector2(x.y, z.y))
	_bloco("madeira_escura", Vector3(1.3, 1.1, 0.05), Vector3(-1.0, 0.65, fz + 0.65), Color.WHITE, false, Vector3(0, 90, 0))


func _tela(de: Vector2, ate: Vector2) -> void:
	var compr := de.distance_to(ate)
	var dir := (ate - de) / compr
	var giro := -rad_to_deg(atan2(dir.y, dir.x))
	var n := maxi(1, ceili(compr / 2.2))
	for i in n + 1:
		var p := de + dir * compr * i / n
		_bloco("madeira_escura", Vector3(0.1, 1.4, 0.1), Vector3(p.x, 0.7, p.y), Color.WHITE, false)
	var meio := (de + ate) / 2
	for k in 4:
		_bloco("ferro", Vector3(compr, 0.015, 0.015), Vector3(meio.x, 0.15 + k * 0.38, meio.y), Color.WHITE, false, Vector3(0, giro, 0))
	_col.append([Vector3(compr, 1.4, 0.12), Vector3(meio.x, 0.7, meio.y), Vector3(0, giro, 0)])


# --- O abrigo do Ford ------------------------------------------------------------------

## O abrigo grande e aberto (o livro: "capacious, unguarded"), ao norte da casa,
## com a entrada de carro da estrada; dentro, o Ford velho e surrado de Akeley
## (o Modelo T: o capô, o para-brisa, a capota de lona, as rodas de raios).
func _ford() -> void:
	var x := Vector2(9.0, 15.0)
	var z := Vector2(-18.0, -12.0)
	var alto := 2.6
	for xx: float in [x.x, (x.x + x.y) / 2, x.y]:
		for zz: float in [z.x, z.y]:
			_bloco("madeira_escura", Vector3(0.18, alto, 0.18), Vector3(xx, alto / 2, zz))
	_parede("celeiro", Vector2(x.x, z.x + 0.06), Vector2(x.y, z.x + 0.06), 0.0, alto, 0.12)
	var meio_z := (z.x + z.y) / 2
	var corre := (z.y - z.x) / 2
	var ang := atan2(1.1, corre)
	for s: float in [-1.0, 1.0]:
		var compr := Vector2(corre, 1.1).length() + 0.4
		_bloco("telhado", Vector3(x.y - x.x + 0.5, 0.12, compr), Vector3((x.x + x.y) / 2, alto + 0.55, meio_z + s * (corre + 0.3) / 2), Color.WHITE, false, Vector3(s * rad_to_deg(ang), 0, 0))
	for xx: float in [x.x - 0.25, x.y + 0.25]:
		_tri(_obra("celeiro"), Vector3(xx, alto, z.x), Vector3(xx, alto, z.y), Vector3(xx, alto + 1.1, meio_z), Vector3(signf(xx - 12.0), 0, 0), Color.WHITE)
	# O Ford (de frente para o leste, a estrada).
	var f := Vector3(12.0, 0, meio_z)
	_bloco("esmalte_preto", Vector3(1.0, 0.45, 0.75), f + Vector3(0.95, 0.85, 0), Color.WHITE, false)  # o capô
	_bloco("esmalte_preto", Vector3(1.5, 0.55, 1.35), f + Vector3(-0.3, 0.85, 0), Color.WHITE, false)  # a carroceria
	_bloco("la_escura", Vector3(1.4, 0.06, 1.4), f + Vector3(-0.35, 1.75, 0), Color.WHITE, false)  # a capota
	for s: float in [-1.0, 1.0]:
		_bloco("ferro", Vector3(0.04, 0.6, 0.04), f + Vector3(-1.0, 1.45, s * 0.66), Color.WHITE, false)
		_bloco("ferro", Vector3(0.04, 0.6, 0.04), f + Vector3(0.35, 1.45, s * 0.66), Color.WHITE, false)
	_bloco("vidro_janela", Vector3(0.03, 0.42, 1.25), f + Vector3(0.45, 1.33, 0), Color.WHITE, false)
	_bloco("latao", Vector3(0.06, 0.4, 0.6), f + Vector3(1.47, 0.9, 0), Color(0.6, 0.6, 0.6), false)  # o radiador
	for rx: float in [1.0, -0.9]:
		for s: float in [-1.0, 1.0]:
			_cilindro_ford(f + Vector3(rx, 0.38, s * 0.7))
	_col.append([Vector3(2.8, 1.8, 1.6), f + Vector3(0.1, 0.9, 0)])


func _cilindro_ford(c: Vector3) -> void:
	var roda := _obra("esmalte_preto")
	for i in 10:
		var a0 := TAU * i / 10
		var a1 := TAU * (i + 1) / 10
		var p0 := c + Vector3(cos(a0), sin(a0), 0) * 0.38
		var p1 := c + Vector3(cos(a1), sin(a1), 0) * 0.38
		var d := Vector3(0, 0, 0.06)
		roda.quad(p0 - d, p1 - d, p1 + d, p0 + d, ((p0 + p1) / 2 - c).normalized(), Color(0.2, 0.2, 0.2))
		roda.tri(c + d, p0 + d, p1 + d, Vector3.BACK, Color(0.5, 0.42, 0.3))
		roda.tri(c - d, p0 - d, p1 - d, Vector3.FORWARD, Color(0.5, 0.42, 0.3))


# --- O moinho -------------------------------------------------------------------------

## O moinho de vento de torre de madeira (quatro pernas em treliça), a roda de
## pás e o leme, atrás das dependências.
func _moinho() -> void:
	var base := Vector3(-30.0, 0, -6.0)
	var alto := 12.0
	var abre := 1.6
	for s: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var pe := base + Vector3(s.x * abre, 0, s.y * abre)
		var topo := base + Vector3(s.x * 0.35, alto, s.y * 0.35)
		var meio := (pe + topo) / 2
		var d := topo - pe
		var rx := rad_to_deg(atan2(d.z, d.y))
		var rz := -rad_to_deg(atan2(d.x, d.y))
		_bloco("madeira_clara", Vector3(0.14, d.length(), 0.14), meio, Color(0.8, 0.8, 0.8), false, Vector3(rx, 0, rz))
	# As travessas, de andar em andar.
	for k in 5:
		var y := 1.5 + k * 2.2
		var w := lerpf(abre, 0.35, y / alto) * 2
		for lado in 4:
			var giro := lado * 90.0
			var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
			_bloco("madeira_clara", Vector3(w, 0.08, 0.06), base + Vector3(0, y, 0) + b * Vector3(0, 0, w / 2), Color(0.8, 0.8, 0.8), false, Vector3(0, giro, 0))
	_col.append([Vector3(2 * abre, 3.0, 2 * abre), base + Vector3(0, 1.5, 0)])
	# A roda (virada para o leste, ao vento do vale) e o leme.
	var cubo := base + Vector3(0.5, alto + 0.4, 0)
	_bloco("ferro", Vector3(0.6, 0.3, 0.3), cubo, Color.WHITE, false)
	for i in 18:
		var a := TAU * i / 18
		var p := cubo + Vector3(0.3, sin(a) * 1.25, cos(a) * 1.25)
		_bloco("ferro_galvanizado", Vector3(0.02, 1.5, 0.32), p, Color.WHITE, false, Vector3(rad_to_deg(-a), 0, 0))
	_bloco("ferro_galvanizado", Vector3(2.4, 0.9, 0.03), cubo + Vector3(-1.6, 0.1, 0), Color.WHITE, false)
	_bloco("madeira_clara", Vector3(2.0, 0.08, 0.08), cubo + Vector3(-0.9, 0, 0), Color.WHITE, false)


# --- As árvores -----------------------------------------------------------------------

## Os olmos grandes do gramado, os bordos ao longo da estrada, as macieiras ao
## norte; as bétulas e as árvores mortas do pântano; e a mata fechada da
## encosta, até a crista recortada da Dark Mountain.
func _arvores() -> void:
	var mm := _obra("bosque")
	var troncos: Array[Vector3] = []
	# Os olmos do gramado (altos, de copa em vaso) e os bordos ao longo da
	# estrada, com as primeiras folhas de setembro amarelando.
	for p: Vector3 in [Vector3(12.0, 0, 9.0), Vector3(22.0, 0, -9.0), Vector3(-6.0, 0, 11.0)]:
		_arvore(mm, p, _rng.randf_range(13.0, 15.0), 4.6, Color(0.2, 0.3, 0.14))
		troncos.append(p)
	var z := -56.0
	while z < 38.0:
		if absf(z) > 2.5 and absf(z + 15.0) > 3.0:
			var p := Vector3(ESTRADA_X.x - 1.6 + _rng.randf_range(-0.4, 0.4), 0, z)
			var folha := Color(0.24, 0.32, 0.14) if _rng.randf() < 0.7 else Color(0.5, 0.4, 0.14)
			_arvore(mm, p, _rng.randf_range(8.0, 10.5), 3.0, folha)
			troncos.append(p)
		z += _rng.randf_range(9.0, 14.0)
	for i in 8:
		var p := Vector3(16.0 + (i % 4) * 4.0 + _rng.randf_range(-0.6, 0.6), 0, -32.0 - (i / 4) * 5.0)
		_macieira(mm, p)
		troncos.append(p)
	# O pântano: bétulas ralas e troncos mortos, touceiras de juncos.
	for i in 45:
		var p := Vector3(_rng.randf_range(-62.0, -34.0), 0, _rng.randf_range(-58.0, 38.0))
		p.y = _altura(p.x, p.z)
		if _rng.randf() < 0.6:
			_betula(mm, p, _rng.randf_range(6.0, 9.0), true)
		else:
			_morta(mm, p)
		troncos.append(p)
	for i in 140:
		var p := Vector3(_rng.randf_range(-63.0, -30.0), 0, _rng.randf_range(-58.0, 38.0))
		p.y = _altura(p.x, p.z)
		for k in 6:
			var q := p + Vector3(_rng.randf_range(-0.25, 0.25), 0, _rng.randf_range(-0.25, 0.25))
			mm.piramide(_rng.randf_range(0.025, 0.045), _rng.randf_range(0.5, 1.3), q, 3, Color(0.42, 0.4, 0.2) * _rng.randf_range(0.8, 1.15))
	# A mata da encosta: cicutas e bétulas, densa, até a crista (o fim do terreno).
	for i in 1100:
		var p := Vector3(_rng.randf_range(-258.0, -66.0), 0, _rng.randf_range(-228.0, 228.0))
		p.y = _altura(p.x, p.z) - 0.2
		if _rng.randf() < 0.22:
			_betula(mm, p, _rng.randf_range(8.0, 12.0), false)
		else:
			_vistas._abeto(mm, p, _rng.randf_range(9.0, 16.0), Color(0.08, 0.13, 0.09) * _rng.randf_range(0.8, 1.25), _rng)
	# Do outro lado do vale (leste), bosques nos morros, mais ralos.
	for i in 260:
		var p := Vector3(_rng.randf_range(60.0, 205.0), 0, _rng.randf_range(-228.0, 228.0))
		p.y = _altura(p.x, p.z) - 0.2
		_vistas._abeto(mm, p, _rng.randf_range(8.0, 13.0), Color(0.1, 0.15, 0.09) * _rng.randf_range(0.8, 1.2), _rng)
	# Os troncos do quintal e do pântano barram o corpo.
	for p in troncos:
		_col.append([Vector3(0.5, 3.0, 0.5), p + Vector3(0, 1.5, 0)])


## Uma árvore de copa redonda (olmo, bordo): o tronco, três galhos abrindo em
## vaso, a copa em bolas de folhagem.
func _arvore(mm: Cidade.Malha, p: Vector3, alt: float, raio: float, folha: Color) -> void:
	var tronco := Color(0.27, 0.23, 0.19)
	var fuste := alt * 0.42
	mm.caixa(Vector3(0.42, fuste, 0.42), p + Vector3(0, fuste / 2, 0), tronco)
	for k in 3:
		var ang := TAU * k / 3 + _rng.randf_range(-0.4, 0.4)
		var dir := Vector3(cos(ang), 0, sin(ang))
		var compr := alt * 0.32
		var meio := p + Vector3(0, fuste, 0) + dir * compr * 0.3 + Vector3.UP * compr * 0.42
		_bloco("bosque", Vector3(0.22, compr, 0.22), meio, tronco, false, Vector3(rad_to_deg(dir.z) * 0.6, 0, -rad_to_deg(dir.x) * 0.6))
	for k in 7:
		var c := p + Vector3(_rng.randf_range(-raio, raio) * 0.55, alt * _rng.randf_range(0.62, 0.86), _rng.randf_range(-raio, raio) * 0.55)
		var r := raio * _rng.randf_range(0.42, 0.6)
		_vistas._bola(mm, c, Vector3(r, r * 0.75, r), folha * _rng.randf_range(0.85, 1.15), _rng)


## Uma bétula: o tronco fino e pálido com os nós escuros; perto, a copa rala em
## três bolas pequenas; longe (a encosta), dois fusos.
func _betula(mm: Cidade.Malha, p: Vector3, alt: float, perto: bool) -> void:
	mm.caixa(Vector3(0.14, alt, 0.14), p + Vector3(0, alt / 2, 0), Color(0.74, 0.72, 0.66))
	for k in 3:
		mm.caixa(Vector3(0.15, 0.06, 0.15), p + Vector3(0, _rng.randf_range(0.8, alt - 1.0), 0), Color(0.12, 0.12, 0.12))
	var folha := Color(0.26, 0.34, 0.15) if _rng.randf() < 0.85 else Color(0.5, 0.46, 0.18)
	if perto:
		for k in 3:
			var c := p + Vector3(_rng.randf_range(-0.6, 0.6), alt * _rng.randf_range(0.6, 0.92), _rng.randf_range(-0.6, 0.6))
			var r := _rng.randf_range(0.7, 1.1)
			_vistas._bola(mm, c, Vector3(r, r * 1.2, r), folha * _rng.randf_range(0.85, 1.1), _rng)
	else:
		mm.bipiramide(alt * 0.13, alt * 0.45, p + Vector3(0, alt * 0.74, 0), 5, folha, _rng.randf() * TAU)
		mm.bipiramide(alt * 0.1, alt * 0.3, p + Vector3(0.3, alt * 0.52, 0), 5, folha * 0.9, _rng.randf() * TAU)


func _macieira(mm: Cidade.Malha, p: Vector3) -> void:
	mm.caixa(Vector3(0.22, 1.4, 0.22), p + Vector3(0, 0.7, 0), Color(0.3, 0.24, 0.18))
	mm.bipiramide(_rng.randf_range(1.6, 2.1), 2.0, p + Vector3(0, 2.4, 0), 6, Color(0.24, 0.34, 0.16) * _rng.randf_range(0.9, 1.1), _rng.randf() * TAU)


## Um tronco morto do pântano, sem casca, com dois galhos quebrados.
func _morta(mm: Cidade.Malha, p: Vector3) -> void:
	var alt := _rng.randf_range(2.5, 5.5)
	var cor := Color(0.42, 0.4, 0.36)
	mm.caixa(Vector3(0.22, alt, 0.22), p + Vector3(0, alt / 2, 0), cor)
	mm.caixa(Vector3(1.2, 0.1, 0.1), p + Vector3(0.5, alt * 0.7, 0), cor * 0.9)
	mm.caixa(Vector3(0.1, 0.1, 0.9), p + Vector3(0, alt * 0.5, 0.4), cor * 0.9)
