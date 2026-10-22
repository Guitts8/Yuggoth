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

## O reespaçamento (playtest 12: "a fazenda está MUITO aglomerada, o canil fica
## perto demais da casa, e o celeiro também"): o canil (com o cercado, a bomba do
## poço e o bebedouro) foi 9 m para o norte, a uns dez metros dos fundos da casa;
## o celeiro (com o galinheiro e o chiqueiro) foi para o noroeste, fechando o
## terreiro; o abrigo do Ford, um pouco para nordeste, com a entrada de carro.
## Deslocamentos a partir da planta antiga (as funções de cada um ainda a usam).
const CANIL_D := Vector3(0, 0, -9)
const CELEIRO_D := Vector3(-4, 0, -17)
const FORD_D := Vector3(3, 0, -3)

var _obras: Dictionary[String, Cidade.Malha] = {}
var _col: Array = []
var _rng := RandomNumberGenerator.new()
var _vistas = Vistas.new()
var _cidade = Cidade.new()
var _relevo := FastNoiseLite.new()
## A grade do terreno (`_terreno`): o chão de verdade entre os pontos dela é plano
## (dois triângulos por célula), não a curva de `_altura`.
var _xs := PackedFloat32Array()
var _zs := PackedFloat32Array()


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
	# Vidro iluminado pela cena (o vidro_janela do escritório é sem luz: brilhava
	# no crepúsculo).
	_mat("vidro_fazenda", "grao", {world = 3.0, cor = Color(0.22, 0.25, 0.28)})
	# O balde de zinco (claro: o ferro_galvanizado parte do aço verde-oliva) e a ração.
	_mat("zinco", "grao", {world = 12.0, cor = Color(0.46, 0.48, 0.5)})
	_mat("racao", "cinzas", {world = 20.0, cor = Color(3.2, 2.5, 1.6)})
	# Os interiores (playtest 11): o papel de cada cômodo, o teto caiado, o assoalho
	# de tábuas largas, o tapete trançado, a colcha.
	_mat("papel_estudo", "papel_parede", {world = 1.2, cor = Color(0.8, 0.86, 0.78)})
	_mat("papel_sala", "papel_flores", {world = 1.3})
	_mat("papel_jantar", "papel_listras", {world = 2.2, cor = Color(0.92, 0.84, 0.8)})
	_mat("papel_vestibulo", "papel_listras", {world = 2.2, cor = Color(0.92, 0.92, 0.86)})
	_mat("papel_quarto", "papel_flores", {world = 1.3, cor = Color(0.86, 0.92, 1.05)})
	_mat("papel_quarto_akeley", "papel_flores", {world = 1.3, cor = Color(0.95, 0.95, 0.85)})
	_mat("teto_casa", "reboco", {world = 0.8, cor = Color(1.32, 1.3, 1.24)})
	_mat("assoalho_largo", "assoalho_largo", {world = 0.75})
	_mat("colcha", "colcha", {world = 2.0})
	_mat("capim", "capim", {})
	(m["capim"] as ShaderMaterial).set_shader_parameter(&"alpha_cut", 0.5)
	ResourceSaver.save(m["capim"], MAT_DIR + "capim.tres")
	_mat("estofado_vinho", "estofado", {world = 3.0, cor = Color(1.6, 0.75, 0.7)})
	_mat("couro", "capa_livro", {world = 3.0, cor = Color(0.8, 0.55, 0.42)})
	_mat("feltro_verde", "estofado", {world = 3.0, cor = Color(0.55, 0.78, 0.55)})
	# A tela de arame do cercado dos cães (R4): só os arames; o resto é vazio.
	_mat("tela_arame", "tela_arame", {world = 5.0})
	(m["tela_arame"] as ShaderMaterial).set_shader_parameter(&"alpha_cut", 0.5)
	ResourceSaver.save(m["tela_arame"], MAT_DIR + "tela_arame.tres")
	_mat("tapete_trancado", "tapete_trancado", {})
	(m["tapete_trancado"] as ShaderMaterial).set_shader_parameter(&"alpha_cut", 0.5)
	ResourceSaver.save(m["tapete_trancado"], MAT_DIR + "tapete_trancado.tres")

	cena = Node3D.new()
	cena.name = "Fazenda"
	cena.set_script(load("res://levels/fazenda/fazenda.gd"))
	cena.set("som", _sfx("dia_quieto.wav"))
	cena.set("linha_fim", load("res://narrative/narration/fim_da_demo.tres"))
	cena.set("linha_inicio", load("res://narrative/narration/akeley_caes.tres"))
	cena.set("som_passaros", _sfx("tarde.wav"))

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = _env()
	_add(cena, env)
	# O sol de fim de tarde de setembro, baixo, a oeste-sudoeste: vai para trás da
	# Dark Mountain (Fazenda._aplicar o apaga aos poucos). As sombras compridas
	# atravessam o gramado para leste.
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	var rumo := Vector3(0.93, -0.12, -0.36).normalized()
	sol.transform.basis = Basis.looking_at(rumo, Vector3.UP)
	sol.light_color = Color(1.0, 0.62, 0.36)
	sol.light_energy = 1.3
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 90.0
	_add(cena, sol)
	_balde()

	_terreno()
	_estrada_e_gramado()
	_muros()
	_casa()
	_puxado()
	_acabamento_interior()
	_dependencias()
	_canil()
	_canil_acabamento()
	_deslocado(FORD_D, _ford)
	_moinho()
	_trilhas()
	_varal()
	_dependencias_acabamento()
	_postes()
	_arvores()
	_arbustos_e_capim()
	_rotina()
	_preparacao()
	_noite_telhado()
	# A luz-guia (playtest 11): azul, fraca, sobre a próxima tarefa.
	var guia := LuzGuia.new()
	guia.name = "LuzGuia"
	_add(cena, guia)
	guia.fontes.assign([cena.get_node("Rotina"), cena.get_node("Preparacao"), cena.get_node("NoiteTelhado")])
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
	# O começo do Interlúdio: Akeley diante do cercado do canil, olhando para o
	# oeste-noroeste — o canil, o celeiro ao fundo, o moinho e a montanha contra o
	# céu da tinta.
	_spawn("Entardecer", Vector3(6.5, 0.0, -14.0), 68.0)

	_salvar(OUT)


## O entardecer de 2 de setembro de 1928 (F2): o céu nas cores do céu da tinta da
## última carta (shaders/tinta.gdshader: o alto escuro, o horizonte alaranjado),
## o vale a leste afogado em névoa (a neblina de altura) e a neblina puxando para
## o sol, a oeste. Fazenda._aplicar leva tudo ao crepúsculo.
func _env() -> Environment:
	var e := _pos(Environment.new())
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color(0.16, 0.18, 0.34)
	ceu.sky_horizon_color = Color(0.88, 0.5, 0.3)
	ceu.sky_curve = 0.12
	ceu.ground_horizon_color = Color(0.44, 0.25, 0.15)
	ceu.ground_bottom_color = Color(0.05, 0.05, 0.06)
	ceu.sun_angle_max = 25.0
	ceu.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = ceu
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.5
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	e.fog_light_color = Color(0.62, 0.46, 0.38)
	e.fog_density = 0.0045
	e.fog_sun_scatter = 0.35
	e.fog_sky_affect = 0.25
	e.fog_height = -4.0
	e.fog_height_density = 0.18
	e.tonemap_exposure = 1.25
	return e


## O balde de ração de Akeley, de ferro galvanizado, cheio de ração, seguro diante
## da câmera (NaMao, sem mãos). Só aparece no Interlúdio.
func _balde() -> void:
	var b := Node3D.new()
	b.name = "Balde"
	b.set_script(load("res://components/na_mao.gd"))
	_add(cena, b)
	var corpo := _cyl(b, "Corpo", 0.15, 0.12, 0.26, Vector3.ZERO, "zinco", 12)
	corpo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A ração por cima da boca, num monte (o cilindro é fechado).
	var racao := _cyl(b, "Racao", 0.06, 0.142, 0.05, Vector3(0, 0.155, 0), "racao", 12)
	racao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cyl(b, "Aro", 0.155, 0.155, 0.025, Vector3(0, 0.13, 0), "ferro", 12)
	# Uma luz fraca e curta do lado da câmera: contra o sol baixo, o balde era
	# uma mancha preta (o truque dos objetos em primeira pessoa).
	var luz := _omni(b, "Luz", Vector3(-0.2, 0.35, 0.4), Color(1.0, 0.82, 0.66), 0.45, 0.9)
	luz.light_cull_mask = 1
	# A alça de arame, em arco sobre a boca.
	for k in 7:
		var a := PI * (k + 0.5) / 7.0
		var alca := _box(b, "Alca%d" % k, Vector3(0.012, 0.012, 0.07), Vector3(0, 0.13 + sin(a) * 0.16, cos(a) * 0.16), "ferro")
		alca.rotation.x = -a + PI / 2
		alca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Playtest 12 ("a animação de pôr ração... fraca"): o que cai da boca do balde
	# inclinado — os grãos de ração pela borda do lado +X (ele despeja para a
	# direita, por cima da tela) e a água pela borda da frente (-Z, no bebedouro).
	b.add_child(_jorro("Jorro", Vector3(0.13, 0.12, 0.0), Vector3(1, 0.2, 0), Color(0.78, 0.56, 0.32), Vector3(0.022, 0.016, 0.018), 130, 0.6, false))
	b.add_child(_jorro("JorroAgua", Vector3(0.0, 0.12, -0.13), Vector3(0, 1, -0.3), Color(0.62, 0.7, 0.76, 0.75), Vector3(0.02, 0.03, 0.02), 90, 0.5, true))
	for c in b.get_children():
		if c is CPUParticles3D:
			c.owner = cena


## Uma placa em D (a portinhola da caixa de correio): o retângulo de `alto_reto` de
## altura e o meio círculo de `raio` em cima, no plano YZ, com `esp` de espessura
## para +X; a origem no meio da borda de baixo.
func _placa_d(pai: Node3D, nome: String, raio: float, alto_reto: float, esp: float, mat: String) -> MeshInstance3D:
	var borda: Array[Vector2] = [Vector2(-raio, 0), Vector2(raio, 0)]
	for i in 9:
		var a := PI * i / 8.0
		borda.append(Vector2(cos(a) * raio, alto_reto + sin(a) * raio))
	var centro := Vector2(0, alto_reto * 0.6)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var p := func(v: Vector2, x: float) -> Vector3: return Vector3(x, v.y, v.x)
	for i in borda.size():
		var a: Vector2 = borda[i]
		var b: Vector2 = borda[(i + 1) % borda.size()]
		for lado: Array in [[esp, Vector3.RIGHT], [0.0, Vector3.LEFT]]:
			st.set_normal(lado[1])
			_tri_st(st, p.call(centro, lado[0]), p.call(a, lado[0]), p.call(b, lado[0]), lado[1])
		var n := Vector3(0, (a + b).y / 2.0 - centro.y, (a + b).x / 2.0).normalized()
		st.set_normal(n)
		_tri_st(st, p.call(a, 0.0), p.call(b, 0.0), p.call(b, esp), n)
		_tri_st(st, p.call(a, 0.0), p.call(b, esp), p.call(a, esp), n)
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	mi.material_override = m[mat]
	_add(pai, mi)
	return mi


## Um triângulo num SurfaceTool com a face para `n` (a ordem dos vértices como a do
## Cidade.Malha: horária vista de fora).
func _tri_st(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	st.set_normal(n)
	for v in [a, b, c]:
		st.add_vertex(v)


## Um jorro de partículas que caem (a ração, a água, os respingos): emite só quando
## a cena liga `emitting`; no mundo (os grãos ficam onde caíram do balde que anda).
func _jorro(nome: String, pos: Vector3, dir: Vector3, cor: Color, tam: Vector3, quantos: int, vida: float, agua: bool) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.name = nome
	e.position = pos
	e.emitting = false
	e.local_coords = false
	e.amount = quantos
	e.lifetime = vida
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	e.emission_sphere_radius = 0.035 if not agua else 0.05
	e.direction = dir
	e.spread = 14.0 if not agua else 9.0
	e.initial_velocity_min = 0.35
	e.initial_velocity_max = 0.8 if not agua else 0.6
	e.gravity = Vector3(0, -9.8, 0)
	e.angular_velocity_min = -360.0
	e.angular_velocity_max = 360.0
	e.scale_amount_min = 0.6
	e.scale_amount_max = 1.3
	var mesh := BoxMesh.new()
	mesh.size = tam
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	if agua:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.1
		mat.metallic_specular = 0.8
	mesh.material = mat
	e.mesh = mesh
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return e


# --- Ajudantes ----------------------------------------------------------------------

## A malha (de cor por vértice) de um material: tudo o que é fixo e usa esse
## material vira uma malha só, com as faces subdivididas.
func _obra(mat: String) -> Cidade.Malha:
	if not _obras.has(mat):
		_obras[mat] = Cidade.Malha.new()
	return _obras[mat]


## Monta o que `f` monta como se estivesse no lugar da planta antiga e o leva `d`
## adiante: as malhas, a colisão e os nós que ele pôs na cena (playtest 12, o
## reespaçamento do celeiro e do abrigo do Ford, que são feitos de muitas peças em
## coordenadas do mundo).
func _deslocado(d: Vector3, f: Callable) -> void:
	var obras := _obras
	_obras = {}
	var col0 := _col.size()
	var nos0 := cena.get_child_count()
	f.call()
	var novas := _obras
	_obras = obras
	for mat in novas:
		if novas[mat].vazio:
			continue
		var arr := (novas[mat].fechar() as ArrayMesh).surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var cor: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		var mm := _obra(mat)
		for t in range(0, v.size(), 3):
			mm.tri(v[t] + d, v[t + 1] + d, v[t + 2] + d, nrm[t], cor[t])
	for i in range(col0, _col.size()):
		_col[i][1] += d
	for i in range(nos0, cena.get_child_count()):
		var n := cena.get_child(i) as Node3D
		if n:
			n.position += d


## Salva `r` em MALHAS/`nome`.res e devolve o recurso carregado de lá.
func _guardar(r: Resource, nome: String) -> Resource:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MALHAS))
	var caminho := MALHAS + nome + ".res"
	ResourceSaver.save(r, caminho, ResourceSaver.FLAG_COMPRESS)
	return load(caminho)


## O lado (m) dos pedaços em que a malha de cada material é partida. Uma malha só
## para a fazenda inteira não deixava o motor descartar nada: fora da vista, fora
## do alcance de um lampião, fora de uma faixa da sombra do sol — cada luz com
## sombra redesenhava a fazenda toda (2026-10-16: a placa integrada travava).
const PEDACO := 12.0
## O que fica além disto (x, z) é "de longe": a sombra do sol não chega lá nem na
## Alta (90 m da câmera, que não sai dos muros). Olhando a Dark Mountain do quintal,
## a mata da encosta inteira entrava na vista e, com o sol baixo atrás dela, também
## na sombra de cada faixa: a placa integrada travava (2026-10-21).
const PERTO_X := Vector2(-110.0, 70.0)
const PERTO_Z := Vector2(-100.0, 80.0)
## As obras de longe e o material de cada uma: pedaços de PEDACO_LONGE, sem sombra.
const LONGE: Dictionary[String, String] = {"bosque_longe": "bosque"}
const PEDACO_LONGE := 48.0


func _perto(x: float, z: float) -> bool:
	return x > PERTO_X.x and x < PERTO_X.y and z > PERTO_Z.x and z < PERTO_Z.y


## Cada material vira uma cena (`obra_<mat>.scn`, binária) com um MeshInstance3D
## por pedaço de PEDACO × PEDACO, instanciada em Obras (as de LONGE, por pedaço de
## PEDACO_LONGE e sem sombra).
func _fechar_obras() -> void:
	var g := _group(cena, "Obras")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MALHAS))
	for mat in _obras:
		var arr := (_obras[mat].fechar() as ArrayMesh).surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var cor: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		var lado := PEDACO_LONGE if LONGE.has(mat) else PEDACO
		var baldes: Dictionary[Vector2i, PackedInt32Array] = {}
		for t in range(0, v.size(), 3):
			var c := (v[t] + v[t + 1] + v[t + 2]) / 3.0
			var k := Vector2i(floori(c.x / lado), floori(c.z / lado))
			if not baldes.has(k):
				baldes[k] = PackedInt32Array()
			baldes[k].append(t)
		var raiz := Node3D.new()
		raiz.name = mat.to_pascal_case()
		for k in baldes:
			var pv := PackedVector3Array()
			var pn := PackedVector3Array()
			var pc := PackedColorArray()
			for t in baldes[k]:
				for i in 3:
					pv.append(v[t + i])
					pn.append(nrm[t + i])
					pc.append(cor[t + i])
			var a := []
			a.resize(Mesh.ARRAY_MAX)
			a[Mesh.ARRAY_VERTEX] = pv
			a[Mesh.ARRAY_NORMAL] = pn
			a[Mesh.ARRAY_COLOR] = pc
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			var mi := MeshInstance3D.new()
			mi.name = "P%d_%d" % [k.x, k.y]
			mi.mesh = am
			mi.material_override = m[LONGE.get(mat, mat)]
			if LONGE.has(mat):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			raiz.add_child(mi)
			mi.owner = raiz
		var packed := PackedScene.new()
		packed.pack(raiz)
		raiz.free()
		var caminho := MALHAS + "obra_" + mat + ".scn"
		ResourceSaver.save(packed, caminho, ResourceSaver.FLAG_COMPRESS)
		var inst := (ResourceLoader.load(caminho, "", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene).instantiate()
		g.add_child(inst)
		inst.owner = cena


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
		# Playtest 11 (R4): a encosta do outro lado do vale sobe até uns 70 m e daí
		# só devagar (subia sem parar, um paredão de 500 m que tapava o céu do leste).
		h += minf((x - 140.0) * 0.9, 70.0) + maxf(x - 218.0, 0.0) * 0.12
	# Os morros do outro lado do vale com relevo (eram uma rampa lisa), as lombadas
	# e os sulcos crescendo com a distância.
	if x > 110.0:
		h += _relevo.get_noise_2d(x * 0.6 + 300.0, z * 0.6) * 16.0 * clampf((x - 110.0) / 90.0, 0.0, 1.0)
	if z > 26.0:
		h -= (z - 26.0) * 0.16
	if z < -40.0:
		h += (-40.0 - z) * 0.04
	if x < -30.0 and x > -64.0:
		h -= 0.12 * clampf((-30.0 - x) / 4.0, 0.0, 1.0)
	if x < -64.0:
		# A encosta da Dark Mountain até a crista (x -260), e do outro lado desce.
		h += minf(-64.0 - x, 196.0) * 0.75 - 0.12
		if x < -260.0:
			h -= (-260.0 - x) * 0.45
	# Ondulação, crescendo longe do quintal.
	var longe := clampf((Vector2(x - 0.0, z - 0.0).length() - 45.0) / 40.0, 0.0, 1.0)
	h += _relevo.get_noise_2d(x, z) * 3.0 * longe
	# Os morros em volta do vale, ao longe (playtest 10: da descida do céu, além
	# das bordas do terreno se via um "mar" escuro).
	var d := Vector2(x, z).length()
	if d > 240.0:
		h += (d - 240.0) * 0.16 + _relevo.get_noise_2d(x * 0.35, z * 0.35) * 22.0 * clampf((d - 240.0) / 120.0, 0.0, 1.0)
		# A crista recortada (R4): um relevo mais miúdo por cima.
		h += _relevo.get_noise_2d(x * 1.3 + 50.0, z * 1.3) * 7.0 * clampf((d - 240.0) / 120.0, 0.0, 1.0)
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
	# Terra gasta no terreiro, entre os fundos da casa, o canil e o celeiro (as
	# trilhas, mais gastas, são `_trilhas`).
	if x > -32.0 and x < 6.0 and z > -40.0 and z < -7.0:
		var borda := minf(minf(x + 32.0, 6.0 - x), minf(z + 40.0, -7.0 - z))
		c = c.lerp(Color(0.46, 0.4, 0.3), 0.32 * clampf(borda / 5.0, 0.0, 1.0))
	return c * _rng.randf_range(0.92, 1.06)


# --- O terreno ----------------------------------------------------------------------

## Uma grade retilínea (as linhas finas perto, grossas longe, sem fendas entre
## elas), com a altura e a cor de cada ponto; a colisão segue a malha.
func _terreno() -> void:
	var xs := _passos([-700.0, -260.0, -70.0, 46.0, 210.0, 700.0], [40.0, 10.0, 2.0, 8.0, 40.0])
	var zs := _passos([-700.0, -230.0, -66.0, 46.0, 230.0, 700.0], [40.0, 10.0, 2.0, 10.0, 40.0])
	_xs = xs
	_zs = zs
	# A colisão segue a malha inteira; a de se ver parte em perto (com sombra) e
	# longe (sem: os morros em volta e a encosta além da sombra).
	var todo := Cidade.Malha.new()
	var mm := Cidade.Malha.new()
	var longe := Cidade.Malha.new()
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
			var cor := _cor_chao((x0 + x1) / 2, (z0 + z1) / 2)
			todo.quad(a, b, c, d, n, cor)
			(mm if _perto((x0 + x1) / 2, (z0 + z1) / 2) else longe).quad(a, b, c, d, n, cor)
	var mi := MeshInstance3D.new()
	mi.name = "Chao"
	mi.mesh = _guardar(mm.fechar(), "chao")
	mi.material_override = m["grama"]
	_add(cena, mi)
	var mi_longe := MeshInstance3D.new()
	mi_longe.name = "ChaoLonge"
	mi_longe.mesh = _guardar(longe.fechar(), "chao_longe")
	mi_longe.material_override = m["grama"]
	mi_longe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(cena, mi_longe)
	var corpo := StaticBody3D.new()
	corpo.name = "ColisaoChao"
	_add(cena, corpo)
	var forma := CollisionShape3D.new()
	forma.name = "Forma"
	forma.shape = _guardar((todo.fechar() as ArrayMesh).create_trimesh_shape(), "chao_colisao")
	_add(corpo, forma)
	# As poças do pântano.
	# Playtest 11 (R4): cada poça é um polígono torto na altura do ponto mais baixo
	# dela — o chão mais alto a cobre, e a margem sai irregular (eram retângulos
	# chapados, uns boiando).
	var agua := _obra("agua")
	for k in 26:
		var p := Vector3(_rng.randf_range(-60.0, -34.0), 0.0, _rng.randf_range(-55.0, 35.0))
		var r := Vector2(_rng.randf_range(1.5, 4.5), _rng.randf_range(1.2, 3.5))
		var borda: Array[Vector3] = []
		var y := _altura(p.x, p.z)
		for i in 12:
			var a := TAU * i / 12
			var q := Vector3(p.x + cos(a) * r.x * _rng.randf_range(0.7, 1.15), 0, p.z + sin(a) * r.y * _rng.randf_range(0.7, 1.15))
			borda.append(q)
			y = minf(y, _altura(q.x, q.z))
		var tom := Color(1, 1, 1) * _rng.randf_range(0.9, 1.1)
		for i in 12:
			agua.tri(Vector3(p.x, y + 0.06, p.z), borda[i] + Vector3(0, y + 0.06, 0), borda[(i + 1) % 12] + Vector3(0, y + 0.06, 0), Vector3.UP, tom)



## A altura do chão de verdade em (x, z): a malha do terreno (as células da grade
## são planas, partidas em dois triângulos como `Cidade.Malha.quad`), não a curva de
## `_altura` — longe, entre pontos a 10 e a 40 m, as duas se afastam metros
## (playtest 12, depois: "algumas arvores não estão encostando o chão").
func _chao_em(x: float, z: float) -> float:
	if _xs.size() < 2 or _zs.size() < 2:
		return _altura(x, z)
	var i := clampi(_xs.bsearch(x) - 1, 0, _xs.size() - 2)
	var j := clampi(_zs.bsearch(z) - 1, 0, _zs.size() - 2)
	var x0 := _xs[i]
	var x1 := _xs[i + 1]
	var z0 := _zs[j]
	var z1 := _zs[j + 1]
	var u := clampf((x - x0) / (x1 - x0), 0.0, 1.0)
	var v := clampf((z - z0) / (z1 - z0), 0.0, 1.0)
	var ha := _altura(x0, z0)
	var hb := _altura(x1, z0)
	var hc := _altura(x1, z1)
	var hd := _altura(x0, z1)
	# Os triângulos (a, b, c) e (a, c, d).
	if u >= v:
		return ha + u * (hb - ha) + v * (hc - hb)
	return ha + v * (hd - ha) + u * (hc - hd)


## Onde assenta um tronco de `raio` em (x, z): o ponto mais baixo do chão em volta
## dele, um pouco enterrado (numa encosta, o lado de baixo não fica no ar).
func _pe(x: float, z: float, raio: float) -> Vector3:
	var y := _chao_em(x, z)
	for k in 6:
		var a := TAU * k / 6.0
		y = minf(y, _chao_em(x + cos(a) * raio, z + sin(a) * raio))
	return Vector3(x, y - 0.12, z)


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
	var entrada := Vector3(14.5, 0.025, -16.5) + FORD_D
	_face(est, entrada, Vector3(ESTRADA_X.x - entrada.x, 0, 0), Vector3(0, 0, 3.0), Vector3.UP, Color.WHITE)

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
	# Playtest 11 (R4): a caixa rural de tampo abaulado (a de 1915), a portinhola na
	# ponta da estrada com o puxador, a bandeirinha vermelha baixada, e a mão-francesa
	# do poste.
	var cb := cx.position + Vector3(0.08, 0, 0)
	_bloco("ferro_galvanizado", Vector3(0.48, 0.16, 0.2), cb + Vector3(0, 1.17, 0), Color.WHITE, false)
	var arco := _obra("ferro_galvanizado")
	for i in 8:
		var a0 := PI * i / 8
		var a1 := PI * (i + 1) / 8
		var p0 := Vector3(0, 1.25 + sin(a0) * 0.1, cos(a0) * 0.1)
		var p1 := Vector3(0, 1.25 + sin(a1) * 0.1, cos(a1) * 0.1)
		var nn := Vector3(0, sin((a0 + a1) / 2), cos((a0 + a1) / 2))
		arco.quad(cb + p0 + Vector3(-0.24, 0, 0), cb + p0 + Vector3(0.24, 0, 0), cb + p1 + Vector3(0.24, 0, 0), cb + p1 + Vector3(-0.24, 0, 0), nn, Color.WHITE)
		# A tampa do fundo (a da frente é a portinhola, à parte) e o escuro de dentro.
		arco.tri(cb + Vector3(-0.24, 1.25, 0), cb + p0 + Vector3(-0.24, 0, 0), cb + p1 + Vector3(-0.24, 0, 0), Vector3.LEFT, Color(0.85, 0.85, 0.85))
		_obra("esmalte_preto").tri(cb + Vector3(0.232, 1.25, 0), cb + p0 + Vector3(0.232, 0, 0), cb + p1 + Vector3(0.232, 0, 0), Vector3.RIGHT, Color(0.3, 0.3, 0.3))
	_bloco("esmalte_preto", Vector3(0.004, 0.155, 0.19), cb + Vector3(0.237, 1.17, 0), Color(0.3, 0.3, 0.3), false)
	# A portinhola (playtest 12: abrir a caixa era só um som): a placa em D presa
	# embaixo, que cai para a estrada, com o trinco de mola em cima.
	var porta := _group(cx, "Portinhola", Vector3(0.08 + 0.245, 1.09, 0))
	_placa_d(porta, "Placa", 0.1, 0.16, 0.01, "ferro_galvanizado")
	_box(porta, "Trinco", Vector3(0.014, 0.04, 0.03), Vector3(0.008, 0.13, 0), "ferro")
	_box(porta, "Puxador", Vector3(0.02, 0.014, 0.05), Vector3(0.014, 0.2, 0), "ferro")
	_bloco("pintura_branca", Vector3(0.26, 0.02, 0.012), cb + Vector3(-0.02, 1.14, -0.107), Color(0.75, 0.12, 0.1), false)
	_bloco("pintura_branca", Vector3(0.08, 0.07, 0.012), cb + Vector3(0.12, 1.12, -0.108), Color(0.75, 0.12, 0.1), false)
	_bloco("madeira_escura", Vector3(0.06, 0.06, 0.32), cx.position + Vector3(0, 0.98, 0), Color.WHITE, false, Vector3(-40, 0, 0))
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
	_muro(Vector2(ESTRADA_X.x - 0.6, lz.x), Vector2(ESTRADA_X.x - 0.6, -17.0 + FORD_D.z))
	_muro(Vector2(ESTRADA_X.x - 0.6, -13.0 + FORD_D.z), Vector2(ESTRADA_X.x - 0.6, -12.6))
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
	_bloco("assoalho_largo", Vector3(x1 - x0, 0.1, z1 - z0), Vector3((x0 + x1) / 2, T0 - 0.05, (z0 + z1) / 2))
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
		_bloco("assoalho_largo", Vector3(px.y - px.x, 0.06, pz.y - pz.x), c + Vector3(0, T1 - 0.03, 0))
		_bloco("teto_casa", Vector3(px.y - px.x, LAJE - 0.06, pz.y - pz.x), c + Vector3(0, T1 - 0.06 - (LAJE - 0.06) / 2, 0), Color.WHITE, false)
	# O forro (o piso do sótão, que a demo não abre).
	_bloco("teto_casa", Vector3(x1 - x0, 0.08, z1 - z0), Vector3((x0 + x1) / 2, FORRO + 0.04, (z0 + z1) / 2), Color.WHITE, false)
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
	_parede("papel_vestibulo", Vector2(ESCADA_X - corre, z + 0.06), Vector2(ESCADA_X - 1.4, z + 0.06), T0, T0 + 1.0, 0.08)
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
		_bloco("vidro_fazenda", Vector3(0.64, 0.84, 0.02), Vector3(CUMEEIRA.x, BEIRAL + 1.6, jz + lado * 0.025), Color.WHITE, false)
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
	_bloco("vidro_fazenda", Vector3(0.02, 0.3, larg - 0.1), Vector3(x - 0.06, T0 + alto - 0.17, 0), Color.WHITE, false)
	for k in 5:
		_bloco("pintura_branca", Vector3(0.03, 0.3, 0.025), Vector3(x - 0.05, T0 + alto - 0.17, -0.4 + k * 0.2), Color.WHITE, false, Vector3(-30.0 + k * 15.0, 0, 0))
	# A folha: dobradiça ao sul. Playtest 11: aberta para dentro, ficava atravessada
	# no vestíbulo e tapava a porta do escritório (o percurso da fazenda ficava
	# preso ali); agora aberta para fora, de lado, na beira dos degraus.
	var porta := _group(cena, "PortaFrente", Vector3(CASA_X.y - 0.08, T0, larg / 2 - 0.05), 180.0)
	var folha := _group(porta, "Folha")
	folha.rotation_degrees.y = -88.0
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
		# A tramela de ferro na face de dentro da folha B, perto da borda: pendurada,
		# e fechadas as folhas, gira por cima da junta (playtest 12).
		if s > 0.0:
			var dentro := -signf(base.z.dot(fora))
			var tramela := _group(dob, "Tranca", Vector3(larg / 2 - 0.035, 0.0, dentro * 0.026))
			_box(tramela, "Barra", Vector3(0.016, 0.15, 0.01), Vector3(0, -0.065, 0), "ferro")
			_box(tramela, "Pino", Vector3(0.012, 0.012, 0.016), Vector3.ZERO, "ferro")


## Os móveis de cada cômodo (playtest 11: "modelos toscos e sem nenhum acabamento
## ou cuidado"). Peças de casa de fazenda da Nova Inglaterra dos anos 1920, feitas
## de muitas partes (pernas torneadas, saias, gavetas com puxadores, espaldares
## de travessas, livros um a um), e dispostas com as passagens livres: de cada
## porta ao meio de cada cômodo e às outras portas (o percurso da fazenda,
## `SHOT_MODO=percurso`, confere).
func _moveis() -> void:
	var y := T0
	# O escritório de Akeley (sudeste): a mesa grande de trabalho no meio, com os
	# papéis; a escrivaninha de tampo de couro contra a parede leste, entre as
	# janelas (o lampião); as estantes cheias contra o vestíbulo; a poltrona de
	# orelhas junto ao fogo, no canto; o armarinho do fonógrafo contra a parede sul,
	# entre as janelas; o tapete trançado. Playtest 12: a mesa ia até perto da parede
	# sul, as cadeiras ficavam no meio da passagem e o armarinho no canto sudeste —
	# não se chegava às venezianas da janela sul nem ao canto das seteiras. Agora as
	# cadeiras ficam enfiadas na mesa e na escrivaninha, e há passagem em volta da
	# mesa e ao longo da parede sul (`tests/alcance_test`).
	_tapete_redondo(Vector3(3.4, y, 3.7), Vector2(2.6, 1.9))
	_mesa(Vector3(3.45, y, 3.45), 0.0, Vector3(1.2, 0.76, 0.85), "madeira_escura")
	for k in 7:
		var papel := Vector3(3.07 + (k % 4) * 0.26, y + 0.765 + k * 0.002, 3.25 + (k / 4) * 0.3)
		_bloco("papel", Vector3(0.21, 0.003, 0.28), papel, Color.WHITE, false, Vector3(0, -12.0 + k * 9.0, 0))
	_cadeira_espaldar(Vector3(3.45, y, 4.02), 0.0)
	_escrivaninha(Vector3(5.42, y, 3.7), 90.0)
	_cadeira_espaldar(Vector3(5.08, y, 3.7), -90.0)
	_estante(Vector3(2.45, y, HALL_Z + 0.24), 180.0, 1.3, 2.2)
	_estante(Vector3(3.8, y, HALL_Z + 0.24), 180.0, 1.3, 2.2)
	_poltrona_orelhas(Vector3(1.9, y, 5.05), 10.0, "estofado")
	_mesinha(Vector3(2.55, y, 5.45), 0.0)
	_armarinho(Vector3(3.5, y, CASA_Z.y - E - 0.26), 0.0)
	# A sala de estar (nordeste): o sofá de encosto curvo contra a parede norte,
	# as duas poltronas viradas para a lareira, a mesa redonda do meio com o
	# pano de crochê, a cadeira de balanço, o tapete. A porta (x 5,1) fica livre.
	_tapete_redondo(Vector3(3.3, y, -3.8), Vector2(2.8, 2.2))
	_sofa(Vector3(3.5, y, -5.35), 180.0, 2.0)
	_poltrona_orelhas(Vector3(2.35, y, -2.35), 30.0, "estofado_vinho")
	_poltrona_orelhas(Vector3(2.35, y, -5.0), 150.0, "estofado_vinho")
	_mesa_redonda(Vector3(3.4, y, -3.7), 0.42)
	_cadeira_balanco(Vector3(5.25, y, -4.7), 118.0)
	_mesinha(Vector3(5.5, y, -3.6), 0.0)
	# A sala de jantar (sudoeste): a mesa de seis lugares, as cadeiras de espaldar,
	# o aparador com a louça sob a janela, o armário de canto. O caminho da porta
	# do vestíbulo à da cozinha passa pela ponta oeste da mesa.
	_tapete_redondo(Vector3(-0.9, y, 3.75), Vector2(2.6, 1.8))
	_mesa(Vector3(-0.8, y, 3.75), 0.0, Vector3(1.6, 0.76, 0.9), "madeira_escura")
	for i in 3:
		for s: float in [-1.0, 1.0]:
			_cadeira_espaldar(Vector3(-1.35 + i * 0.55, y, 3.75 + s * 0.68), 0.0 if s > 0 else 180.0)
	_aparador(Vector3(-1.0, y, 5.55), 0.0, 1.6)
	# A sala dos fundos (noroeste), a oficina: o armário dos rifles (aberto: a F6
	# tira um), a bancada com a morsa e as ferramentas (a munição, a F6), as
	# prateleiras de vidros, as botas e os casacos de trabalho.
	_armario_rifles(Vector3(-1.0, y, -5.52))
	_bancada(Vector3(-2.3, y, -3.0), -90.0)
	_prateleiras(Vector3(0.3, y, -5.62), 180.0)
	_bloco("papelao_escuro", Vector3(0.6, 0.5, 0.5), Vector3(0.45, y + 0.25, -2.25))
	_bloco("papelao_escuro", Vector3(0.45, 0.35, 0.4), Vector3(0.4, y + 0.675, -2.25), Color(0.9, 0.85, 0.8), false, Vector3(0, 12, 0))
	# O vestíbulo: a mesinha de entrada (o lampião), o cabideiro com os casacos e
	# o chapéu, o porta-guarda-chuvas, a passadeira, o espelho.
	_bloco("passadeira", Vector3(5.6, 0.008, 0.9), Vector3(2.0, y + 0.004, 0.35), Color.WHITE, false)
	_mesa(Vector3(0.6, y, 1.08), 90.0, Vector3(0.9, 0.8, 0.4), "madeira_escura")
	_cabideiro(Vector3(-2.35, y, 1.0))
	_bloco("ferro", Vector3(0.26, 0.6, 0.26), Vector3(-2.4, y + 0.3, -0.95), Color(0.8, 0.8, 0.8))
	_bloco("madeira_escura", Vector3(0.6, 0.85, 0.04), Vector3(0.6, y + 1.65, HALL_Z - EI / 2 - 0.03))
	_bloco("vidro_fazenda", Vector3(0.5, 0.75, 0.01), Vector3(0.6, y + 1.65, HALL_Z - EI / 2 - 0.055), Color(1.6, 1.6, 1.7), false)

	# Primeiro andar. O quarto de hóspedes (sobre o escritório; Wilmarth dorme aqui
	# no Ato III): a cama de ferro com a colcha, o guarda-roupa, o lavatório com o
	# jarro e a bacia, a cadeira.
	var y1 := T1
	_cama_ferro(Vector3(3.5, y1, 4.75), 0.0)
	_guarda_roupa(Vector3(1.6, y1, 2.1), -90.0)
	_lavatorio(Vector3(5.5, y1, 2.3), 90.0)
	_cadeira_espaldar(Vector3(5.1, y1, 3.75), 90.0)
	_tapete_redondo(Vector3(3.5, y1, 3.0), Vector2(1.6, 1.0))
	# O quarto de Akeley (sobre a sala de estar): a cama, a cômoda com o espelho, a
	# mesinha de cabeceira, o baú aos pés da cama.
	_cama_ferro(Vector3(3.5, y1, -4.75), 180.0)
	_comoda(Vector3(1.55, y1, -2.4), -90.0)
	_mesinha(Vector3(4.6, y1, -5.4), 0.0)
	_bloco("madeira_escura", Vector3(0.9, 0.5, 0.45), Vector3(3.5, y1 + 0.25, -3.55))
	_tapete_redondo(Vector3(3.5, y1, -3.2), Vector2(1.6, 1.0))
	# O banheiro: a banheira de pés, a pia de coluna, a privada de caixa alta.
	_banheira(Vector3(-2.35, y1, 0.45))
	_pia_coluna(Vector3(-1.45, y1, -1.0), 180.0)
	_privada(Vector3(-1.5, y1, 1.05), 0.0)
	# Os quartos de trás: o de costura (sudoeste) — a cama estreita, a máquina de
	# costura de pedal, o manequim — e o de guardados (noroeste): baús e caixas.
	_cama_ferro(Vector3(-1.2, y1, 4.85), 0.0, 0.95)
	_maquina_costura(Vector3(-2.35, y1, 2.4), -90.0)
	_bloco("madeira_escura", Vector3(0.9, 0.55, 0.5), Vector3(-2.2, y1 + 0.275, -5.3))
	_bloco("couro", Vector3(0.8, 0.45, 0.48), Vector3(-1.25, y1 + 0.225, -5.3), Color.WHITE, true, Vector3(0, 8, 0))
	_bloco("papelao_escuro", Vector3(0.6, 0.5, 0.6), Vector3(-1.3, y1 + 0.7, -5.3), Color(0.95, 0.9, 0.82), false, Vector3(0, -6, 0))
	_guarda_roupa(Vector3(0.45, y1, -3.0), 90.0)


# --- As peças ------------------------------------------------------------------------

## Uma caixa de uma peça de móvel, em coordenadas da peça (origem no chão, o -Z é a
## frente) posta em `p`, girada `giro` graus.
func _parte(mat: String, tam: Vector3, local: Vector3, p: Vector3, giro: float, cor := Color.WHITE, inclina := Vector3.ZERO) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
	_bloco(mat, tam, p + b * local, cor, false, Vector3(inclina.x, giro + inclina.y, inclina.z))


## A colisão de uma peça: uma caixa (em coordenadas da peça).
func _colide(tam: Vector3, local: Vector3, p: Vector3, giro: float) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
	_col.append([tam, p + b * local, Vector3(0, giro, 0)])


## Uma perna torneada: a base quadrada, o fuso com os anéis, o pé.
func _perna_torneada(mat: String, x: float, z: float, alto: float, grossa: float, p: Vector3, giro: float) -> void:
	_parte(mat, Vector3(grossa, alto * 0.22, grossa), Vector3(x, alto - alto * 0.11, z), p, giro)
	_parte(mat, Vector3(grossa * 0.7, alto * 0.5, grossa * 0.7), Vector3(x, alto * 0.53, z), p, giro)
	_parte(mat, Vector3(grossa * 0.95, alto * 0.05, grossa * 0.95), Vector3(x, alto * 0.75, z), p, giro)
	_parte(mat, Vector3(grossa * 0.95, alto * 0.05, grossa * 0.95), Vector3(x, alto * 0.3, z), p, giro)
	_parte(mat, Vector3(grossa * 0.6, alto * 0.25, grossa * 0.6), Vector3(x, alto * 0.14, z), p, giro)


## Uma mesa: o tampo com a borda, a saia, as quatro pernas torneadas.
func _mesa(p: Vector3, giro: float, tam: Vector3, mat: String) -> void:
	var a := tam.y
	_parte(mat, Vector3(tam.x, 0.035, tam.z), Vector3(0, a - 0.0175, 0), p, giro)
	_parte(mat, Vector3(tam.x - 0.02, 0.012, tam.z - 0.02), Vector3(0, a - 0.041, 0), p, giro, Color(0.8, 0.8, 0.8))
	for s: float in [-1.0, 1.0]:
		_parte(mat, Vector3(tam.x - 0.16, 0.11, 0.022), Vector3(0, a - 0.1, s * (tam.z / 2 - 0.07)), p, giro)
		_parte(mat, Vector3(0.022, 0.11, tam.z - 0.16), Vector3(s * (tam.x / 2 - 0.07), a - 0.1, 0), p, giro)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_perna_torneada(mat, sx * (tam.x / 2 - 0.07), sz * (tam.z / 2 - 0.07), a - 0.035, 0.06, p, giro)
	_colide(Vector3(tam.x, a, tam.z), Vector3(0, a / 2, 0), p, giro)


## A mesa redonda do centro (pé de coluna com três pés), com o pano de crochê.
func _mesa_redonda(p: Vector3, raio: float) -> void:
	_cilindro("madeira_escura", p + Vector3(0, 0.74, 0), raio, 0.035, 14)
	_cilindro("lencol", p + Vector3(0, 0.762, 0), raio * 0.62, 0.006, 12, Color(1.1, 1.08, 1.0))
	_cilindro("madeira_escura", p + Vector3(0, 0.4, 0), 0.05, 0.62, 8)
	_cilindro("madeira_escura", p + Vector3(0, 0.6, 0), 0.07, 0.05, 8)
	for k in 3:
		var a := TAU * k / 3.0
		_parte("madeira_escura", Vector3(0.05, 0.05, 0.34), Vector3(0, 0.06, -0.16), p, rad_to_deg(a), Color.WHITE, Vector3(-14, 0, 0))
	_col.append([Vector3(raio * 1.6, 0.76, raio * 1.6), p + Vector3(0, 0.38, 0)])


## Uma cadeira de espaldar de travessas, o assento de palhinha.
func _cadeira_espaldar(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	_parte(m, Vector3(0.42, 0.035, 0.4), Vector3(0, 0.45, 0), p, giro)
	_parte("palha", Vector3(0.36, 0.01, 0.34), Vector3(0, 0.472, 0), p, giro, Color(0.75, 0.62, 0.42))
	for sx: float in [-1.0, 1.0]:
		_parte(m, Vector3(0.035, 0.45, 0.035), Vector3(sx * 0.18, 0.225, -0.17), p, giro)
		# Os pés de trás sobem e viram os montantes do espaldar, um pouco inclinados.
		_parte(m, Vector3(0.035, 1.0, 0.035), Vector3(sx * 0.18, 0.5, 0.18), p, giro, Color.WHITE, Vector3(-4, 0, 0))
		_parte(m, Vector3(0.02, 0.02, 0.36), Vector3(sx * 0.18, 0.16, 0), p, giro)
	_parte(m, Vector3(0.36, 0.02, 0.02), Vector3(0, 0.16, -0.17), p, giro)
	for k in 3:
		_parte(m, Vector3(0.34, 0.05, 0.018), Vector3(0, 0.62 + k * 0.13, 0.19 + k * 0.009), p, giro, Color.WHITE, Vector3(-4, 0, 0))
	_colide(Vector3(0.44, 0.9, 0.44), Vector3(0, 0.45, 0), p, giro)


## A cadeira de balanço: os arcos no chão, o espaldar alto de fusos.
func _cadeira_balanco(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	for sx: float in [-1.0, 1.0]:
		for k in 5:
			var t := -0.4 + k * 0.2
			_parte(m, Vector3(0.03, 0.03, 0.22), Vector3(sx * 0.22, 0.03 + t * t * 0.18, t), p, giro, Color.WHITE, Vector3(rad_to_deg(t * 0.7), 0, 0))
		_parte(m, Vector3(0.035, 0.42, 0.035), Vector3(sx * 0.21, 0.27, -0.16), p, giro)
		_parte(m, Vector3(0.035, 1.05, 0.035), Vector3(sx * 0.21, 0.6, 0.2), p, giro, Color.WHITE, Vector3(-10, 0, 0))
		_parte(m, Vector3(0.04, 0.03, 0.42), Vector3(sx * 0.23, 0.68, 0.02), p, giro)
	_parte(m, Vector3(0.44, 0.035, 0.42), Vector3(0, 0.48, 0), p, giro)
	for k in 5:
		_parte(m, Vector3(0.02, 0.5, 0.02), Vector3(-0.14 + k * 0.07, 0.82, 0.23), p, giro, Color.WHITE, Vector3(-10, 0, 0))
	_parte(m, Vector3(0.44, 0.06, 0.03), Vector3(0, 1.08, 0.27), p, giro, Color.WHITE, Vector3(-10, 0, 0))
	_colide(Vector3(0.5, 1.0, 0.8), Vector3(0, 0.5, 0), p, giro)


## A poltrona de orelhas: o assento com a almofada, o encosto alto com as orelhas,
## os braços enrolados, os pés curtos torneados.
func _poltrona_orelhas(p: Vector3, giro: float, tecido: String) -> void:
	_parte(tecido, Vector3(0.78, 0.3, 0.72), Vector3(0, 0.3, 0.0), p, giro)
	_parte(tecido, Vector3(0.6, 0.12, 0.6), Vector3(0, 0.51, -0.04), p, giro, Color(1.08, 1.08, 1.08))
	_parte(tecido, Vector3(0.78, 0.8, 0.16), Vector3(0, 0.82, 0.3), p, giro, Color(0.95, 0.95, 0.95), Vector3(-6, 0, 0))
	_parte(tecido, Vector3(0.6, 0.16, 0.12), Vector3(0, 1.26, 0.32), p, giro, Color(0.95, 0.95, 0.95), Vector3(-6, 0, 0))
	for sx: float in [-1.0, 1.0]:
		_parte(tecido, Vector3(0.12, 0.24, 0.66), Vector3(sx * 0.36, 0.6, -0.02), p, giro)
		_parte(tecido, Vector3(0.15, 0.08, 0.66), Vector3(sx * 0.37, 0.73, -0.02), p, giro, Color(1.05, 1.05, 1.05))
		# A orelha: o encosto se dobra para a frente dos dois lados, no alto.
		_parte(tecido, Vector3(0.1, 0.45, 0.28), Vector3(sx * 0.35, 1.05, 0.18), p, giro, Color(0.9, 0.9, 0.9), Vector3(0, sx * -20, 0))
		for sz: float in [-1.0, 1.0]:
			_parte("madeira_escura", Vector3(0.05, 0.15, 0.05), Vector3(sx * 0.33, 0.075, sz * 0.3), p, giro)
	_colide(Vector3(0.8, 1.2, 0.8), Vector3(0, 0.6, 0), p, giro)


## O sofá de encosto curvo (camelback): o corpo, as três almofadas, o encosto que
## sobe no meio, os braços enrolados, os pés torneados.
func _sofa(p: Vector3, giro: float, compr: float) -> void:
	var t := "estofado_vinho"
	_parte(t, Vector3(compr, 0.28, 0.78), Vector3(0, 0.3, 0), p, giro)
	for k in 3:
		_parte(t, Vector3(compr / 3 - 0.04, 0.11, 0.6), Vector3(-compr / 3 + k * compr / 3, 0.495, -0.05), p, giro, Color(1.08, 1.08, 1.08))
	for k in 7:
		var x := -compr / 2 + 0.15 + k * (compr - 0.3) / 6
		var u := 1.0 - absf(x) / (compr / 2)
		_parte(t, Vector3((compr - 0.3) / 6 + 0.01, 0.42 + 0.22 * u, 0.16), Vector3(x, 0.6 + 0.11 * u, 0.33), p, giro, Color(0.94, 0.94, 0.94), Vector3(-8, 0, 0))
	for sx: float in [-1.0, 1.0]:
		_parte(t, Vector3(0.16, 0.3, 0.72), Vector3(sx * (compr / 2 - 0.08), 0.6, 0.0), p, giro)
		_parte(t, Vector3(0.2, 0.1, 0.72), Vector3(sx * (compr / 2 - 0.07), 0.76, 0.0), p, giro, Color(1.05, 1.05, 1.05))
		for sz: float in [-1.0, 1.0]:
			_parte("madeira_escura", Vector3(0.05, 0.16, 0.05), Vector3(sx * (compr / 2 - 0.08), 0.08, sz * 0.32), p, giro)
	_colide(Vector3(compr, 1.0, 0.8), Vector3(0, 0.5, 0), p, giro)


## Uma estante: as laterais, o fundo, o cimo com a cornija, o rodapé e as
## prateleiras cheias de livros (um a um, de alturas, grossuras e cores
## diferentes, um ou outro deitado ou inclinado).
func _estante(p: Vector3, giro: float, larg: float, alto: float) -> void:
	var m := "madeira_escura"
	var fundo := 0.34
	for sx: float in [-1.0, 1.0]:
		_parte(m, Vector3(0.03, alto, fundo), Vector3(sx * (larg / 2 - 0.015), alto / 2, 0), p, giro)
	_parte(m, Vector3(larg, alto, 0.015), Vector3(0, alto / 2, fundo / 2 - 0.008), p, giro, Color(0.7, 0.7, 0.7))
	_parte(m, Vector3(larg + 0.08, 0.06, fundo + 0.05), Vector3(0, alto + 0.03, -0.01), p, giro)
	_parte(m, Vector3(larg + 0.12, 0.04, fundo + 0.08), Vector3(0, alto + 0.08, -0.02), p, giro)
	_parte(m, Vector3(larg, 0.1, fundo), Vector3(0, 0.05, 0), p, giro)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.x * 100 + p.z * 31)
	var cores := [Color(0.55, 0.18, 0.14), Color(0.22, 0.32, 0.2), Color(0.36, 0.24, 0.14), Color(0.2, 0.2, 0.28), Color(0.6, 0.46, 0.26), Color(0.3, 0.14, 0.12), Color(0.15, 0.13, 0.12)]
	var prats := 5
	for k in prats:
		var py := 0.1 + k * (alto - 0.12) / prats
		_parte(m, Vector3(larg - 0.06, 0.025, fundo - 0.02), Vector3(0, py, 0), p, giro)
		var x := -larg / 2 + 0.05
		var limite := (alto - 0.12) / prats - 0.06
		while x < larg / 2 - 0.08:
			var w := rng.randf_range(0.022, 0.05)
			var h := rng.randf_range(0.18, minf(0.3, limite))
			var d := rng.randf_range(0.15, 0.24)
			var c: Color = cores[rng.randi_range(0, cores.size() - 1)] * rng.randf_range(0.85, 1.2)
			if rng.randf() < 0.05:
				# Um deitado em cima dos outros.
				_parte("capa_livro", Vector3(h, w, d), Vector3(x + h / 2, py + 0.0125 + w / 2, -0.02), p, giro, c)
				x += h + 0.01
				continue
			var inclina := -8.0 if rng.randf() < 0.06 else 0.0
			_parte("capa_livro", Vector3(w, h, d), Vector3(x + w / 2, py + 0.0125 + h / 2, -fundo / 2 + d / 2 + 0.03), p, giro, c, Vector3(0, 0, inclina))
			x += w + 0.002
			if rng.randf() < 0.04:
				x += 0.06
	_colide(Vector3(larg, alto, fundo), Vector3(0, alto / 2, 0), p, giro)


## A escrivaninha de pedestal de Akeley: o tampo de couro verde, as duas colunas de
## gavetas com puxadores de latão, a gaveta do meio, o rodapé.
func _escrivaninha(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	var larg := 1.2
	var fundo := 0.62
	var a := 0.78
	_parte(m, Vector3(larg + 0.04, 0.035, fundo + 0.04), Vector3(0, a - 0.0175, 0), p, giro)
	_parte("feltro", Vector3(larg - 0.12, 0.004, fundo - 0.12), Vector3(0, a + 0.001, 0), p, giro, Color(0.55, 0.8, 0.55))
	for sx: float in [-1.0, 1.0]:
		var x := sx * (larg / 2 - 0.2)
		_parte(m, Vector3(0.38, a - 0.05, fundo), Vector3(x, (a - 0.05) / 2 + 0.01, 0), p, giro)
		for k in 3:
			var gy := 0.14 + k * 0.21
			_parte(m, Vector3(0.33, 0.18, 0.02), Vector3(x, gy, -fundo / 2 - 0.01), p, giro, Color(1.12, 1.12, 1.12))
			_parte("latao", Vector3(0.07, 0.015, 0.02), Vector3(x, gy + 0.02, -fundo / 2 - 0.026), p, giro)
	_parte(m, Vector3(larg - 0.82, 0.1, 0.02), Vector3(0, a - 0.09, -fundo / 2 - 0.01), p, giro, Color(1.12, 1.12, 1.12))
	_parte("latao", Vector3(0.06, 0.015, 0.02), Vector3(0, a - 0.085, -fundo / 2 - 0.026), p, giro)
	# Em cima: o mata-borrão, o tinteiro, os papéis.
	_parte("papel", Vector3(0.21, 0.003, 0.28), Vector3(-0.25, a + 0.004, 0.0), p, giro, Color.WHITE, Vector3(0, 7, 0))
	_parte("papel", Vector3(0.21, 0.003, 0.28), Vector3(-0.22, a + 0.007, 0.03), p, giro, Color.WHITE, Vector3(0, -5, 0))
	_parte("esmalte_preto", Vector3(0.06, 0.05, 0.06), Vector3(0.12, a + 0.025, 0.12), p, giro)
	_colide(Vector3(larg, a, fundo), Vector3(0, a / 2, 0), p, giro)


## O armarinho do fonógrafo e dos discos (no Ato III, o fonógrafo de Akeley): as
## portinhas, a tampa.
func _armarinho(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	_parte(m, Vector3(0.6, 0.85, 0.48), Vector3(0, 0.45, 0), p, giro)
	_parte(m, Vector3(0.66, 0.035, 0.54), Vector3(0, 0.89, 0), p, giro)
	for sx: float in [-1.0, 1.0]:
		_parte(m, Vector3(0.27, 0.6, 0.02), Vector3(sx * 0.145, 0.43, -0.25), p, giro, Color(1.12, 1.12, 1.12))
		_parte("latao", Vector3(0.015, 0.05, 0.02), Vector3(sx * 0.03, 0.5, -0.265), p, giro)
	_colide(Vector3(0.6, 0.9, 0.5), Vector3(0, 0.45, 0), p, giro)


## Uma mesinha de canto (de cabeceira): o tampo, a gaveta, as pernas finas.
func _mesinha(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	_parte(m, Vector3(0.45, 0.03, 0.4), Vector3(0, 0.7, 0), p, giro)
	_parte(m, Vector3(0.4, 0.12, 0.35), Vector3(0, 0.62, 0), p, giro)
	_parte(m, Vector3(0.3, 0.08, 0.02), Vector3(0, 0.62, -0.18), p, giro, Color(1.12, 1.12, 1.12))
	_parte("latao", Vector3(0.03, 0.02, 0.02), Vector3(0, 0.62, -0.195), p, giro)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_parte(m, Vector3(0.035, 0.56, 0.035), Vector3(sx * 0.18, 0.28, sz * 0.15), p, giro)
	_parte(m, Vector3(0.36, 0.02, 0.3), Vector3(0, 0.18, 0), p, giro)
	_colide(Vector3(0.45, 0.72, 0.4), Vector3(0, 0.36, 0), p, giro)


## O aparador: o corpo de portas e gavetas, o tampo, o espelho de trás, a louça.
func _aparador(p: Vector3, giro: float, larg: float) -> void:
	var m := "madeira_escura"
	_parte(m, Vector3(larg, 0.82, 0.45), Vector3(0, 0.45, 0), p, giro)
	_parte(m, Vector3(larg + 0.05, 0.035, 0.5), Vector3(0, 0.88, 0), p, giro)
	for k in 3:
		var x := -larg / 3 + k * larg / 3
		_parte(m, Vector3(larg / 3 - 0.05, 0.14, 0.02), Vector3(x, 0.74, -0.235), p, giro, Color(1.12, 1.12, 1.12))
		_parte("latao", Vector3(0.06, 0.015, 0.02), Vector3(x, 0.75, -0.25), p, giro)
		_parte(m, Vector3(larg / 3 - 0.05, 0.48, 0.02), Vector3(x, 0.36, -0.235), p, giro, Color(1.12, 1.12, 1.12))
		_parte("latao", Vector3(0.015, 0.05, 0.02), Vector3(x + larg / 6 - 0.06, 0.4, -0.25), p, giro)
	_parte(m, Vector3(larg, 0.06, 0.45), Vector3(0, 0.03, 0), p, giro)
	# O espaldar de trás com a prateleirinha e os pratos em pé.
	_parte(m, Vector3(larg, 0.4, 0.03), Vector3(0, 1.1, 0.21), p, giro)
	_parte(m, Vector3(larg, 0.025, 0.12), Vector3(0, 1.12, 0.15), p, giro)
	for k in 5:
		var x := -larg / 2 + 0.2 + k * (larg - 0.4) / 4
		_cilindro_deitado("porcelana", p + Basis.from_euler(Vector3(0, deg_to_rad(giro), 0)) * Vector3(x, 1.26, 0.17), 0.11, 0.012, giro)
	_cilindro("porcelana", p + Basis.from_euler(Vector3(0, deg_to_rad(giro), 0)) * Vector3(-larg / 4, 0.98, 0.0), 0.07, 0.16, 10)
	_colide(Vector3(larg, 0.9, 0.5), Vector3(0, 0.45, 0), p, giro)


## O armário dos rifles: o corpo alto, aberto na frente (as portas de vidro abertas
## contra a parede), o cabide de rifles por dentro, a gaveta da munição embaixo.
func _armario_rifles(p: Vector3) -> void:
	var m := "madeira_escura"
	# Contra a parede norte, a frente para o sul.
	var giro := 180.0
	_parte(m, Vector3(1.4, 1.9, 0.05), Vector3(0, 0.95, 0.18), p, giro, Color(0.75, 0.75, 0.75))
	for sx: float in [-1.0, 1.0]:
		_parte(m, Vector3(0.05, 1.9, 0.4), Vector3(sx * 0.68, 0.95, 0), p, giro)
		# A porta de vidro aberta, quase encostada na parede ao lado.
		_parte(m, Vector3(0.66, 1.4, 0.03), Vector3(sx * 0.95, 1.15, -0.42), p, giro, Color.WHITE, Vector3(0, sx * -75.0, 0))
		_parte("vidro_fazenda", Vector3(0.54, 1.25, 0.01), Vector3(sx * 0.95, 1.15, -0.44), p, giro, Color(1.4, 1.4, 1.5), Vector3(0, sx * -75.0, 0))
	_parte(m, Vector3(1.48, 0.08, 0.46), Vector3(0, 1.94, -0.02), p, giro)
	_parte(m, Vector3(1.4, 0.45, 0.4), Vector3(0, 0.225, 0), p, giro)
	_parte(m, Vector3(1.3, 0.16, 0.02), Vector3(0, 0.32, -0.205), p, giro, Color(1.12, 1.12, 1.12))
	_parte("latao", Vector3(0.08, 0.015, 0.02), Vector3(0, 0.33, -0.22), p, giro)
	# O cabide: a régua de baixo com os encaixes e a de cima com os entalhes.
	_parte(m, Vector3(1.3, 0.05, 0.18), Vector3(0, 0.48, 0.05), p, giro, Color(1.15, 1.15, 1.15))
	_parte(m, Vector3(1.3, 0.04, 0.1), Vector3(0, 1.45, 0.1), p, giro, Color(1.15, 1.15, 1.15))
	# Playtest 11 (R5): o fundo forrado de feltro verde, a cimalha com o frontão, a
	# travessa de cada porta de vidro.
	_parte("feltro_verde", Vector3(1.3, 1.38, 0.01), Vector3(0, 1.2, 0.15), p, giro)
	_parte(m, Vector3(1.4, 0.12, 0.03), Vector3(0, 2.04, -0.2), p, giro, Color(1.1, 1.1, 1.1))
	_parte(m, Vector3(1.56, 0.03, 0.5), Vector3(0, 1.995, -0.02), p, giro)
	for sx: float in [-1.0, 1.0]:
		_parte(m, Vector3(0.6, 0.03, 0.04), Vector3(sx * 0.95, 1.15, -0.44), p, giro, Color.WHITE, Vector3(0, sx * -75.0, 0))
	# Dois rifles de alavanca e uma espingarda de dois canos que ficam (o rifle de
	# caça grossa é o da F6, no vão do meio), de pé com a coronha na régua de baixo.
	_arma_de_pe(Vector3(-0.52, 0.505, 0.07), p, giro, false, Color(1.25, 1.1, 0.95))
	_arma_de_pe(Vector3(-0.3, 0.505, 0.07), p, giro, true, Color(1.05, 0.9, 0.8))
	_arma_de_pe(Vector3(0.42, 0.505, 0.07), p, giro, false, Color(0.95, 0.85, 0.78))
	# A caixa de cartuchos esquecida na prateleira de baixo.
	_parte("papelao_escuro", Vector3(0.14, 0.06, 0.09), Vector3(0.2, 0.48, -0.08), p, giro, Color(1.3, 0.95, 0.7))
	_col.append([Vector3(1.45, 1.95, 0.45), p + Vector3(0, 0.975, 0)])


## Uma arma longa de pé num cabide (a coronha em `base`, o cano para cima; a
## frente da peça, onde ficam a alavanca e o guarda-mato, para -Z local): a
## soleira, a coronha, o punho, a caixa da culatra, a alavanca em argola (ou, na
## espingarda, o guarda-mato e os dois canos), a telha, o cano e o depósito.
func _arma_de_pe(base: Vector3, p: Vector3, giro: float, espingarda: bool, cor: Color) -> void:
	var m := "madeira_escura"
	var f := "ferro"
	var o := base
	_parte(f, Vector3(0.042, 0.012, 0.1), o + Vector3(0, 0.006, -0.01), p, giro)
	_parte(m, Vector3(0.04, 0.27, 0.1), o + Vector3(0, 0.145, -0.01), p, giro, cor, Vector3(5, 0, 0))
	_parte(m, Vector3(0.034, 0.1, 0.05), o + Vector3(0, 0.33, 0.0), p, giro, cor)
	var culatra := 0.12 if espingarda else 0.16
	_parte(f, Vector3(0.044 if espingarda else 0.042, culatra, 0.07), o + Vector3(0, 0.38 + culatra / 2, 0.0), p, giro, Color(0.9, 0.9, 0.9))
	var cima := 0.38 + culatra
	if espingarda:
		_parte(f, Vector3(0.008, 0.07, 0.008), o + Vector3(0, 0.42, -0.05), p, giro)
		_parte(m, Vector3(0.05, 0.22, 0.045), o + Vector3(0, cima + 0.15, -0.012), p, giro, cor)
		for sx: float in [-1.0, 1.0]:
			_parte(f, Vector3(0.022, 0.7, 0.022), o + Vector3(sx * 0.012, cima + 0.35, 0.015), p, giro)
		return
	_parte(f, Vector3(0.01, 0.13, 0.01), o + Vector3(0, 0.4, -0.065), p, giro)
	_parte(f, Vector3(0.01, 0.01, 0.04), o + Vector3(0, 0.34, -0.045), p, giro)
	_parte(f, Vector3(0.01, 0.01, 0.04), o + Vector3(0, 0.465, -0.045), p, giro)
	_parte(m, Vector3(0.036, 0.28, 0.034), o + Vector3(0, cima + 0.14, -0.012), p, giro, cor)
	_parte(f, Vector3(0.022, 0.64, 0.022), o + Vector3(0, cima + 0.32, 0.015), p, giro)
	_parte(f, Vector3(0.019, 0.52, 0.019), o + Vector3(0, cima + 0.26, -0.014), p, giro, Color(0.85, 0.85, 0.85))
	for y: float in [0.3, 0.5]:
		_parte(f, Vector3(0.03, 0.012, 0.05), o + Vector3(0, cima + y, 0.0), p, giro)


## A bancada da oficina: o tampo grosso, as pernas com a travessa, a prateleira de
## baixo, a morsa, as ferramentas na parede (o martelo, o serrote, as chaves).
func _bancada(p: Vector3, giro: float) -> void:
	var m := "madeira_clara"
	_parte(m, Vector3(1.8, 0.07, 0.7), Vector3(0, 0.815, 0), p, giro)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_parte(m, Vector3(0.08, 0.78, 0.08), Vector3(sx * 0.82, 0.39, sz * 0.28), p, giro)
	_parte(m, Vector3(1.7, 0.03, 0.6), Vector3(0, 0.2, 0), p, giro, Color(0.85, 0.85, 0.85))
	# A morsa de ferro na ponta.
	_parte("ferro", Vector3(0.18, 0.12, 0.12), Vector3(0.7, 0.9, -0.33), p, giro)
	_parte("ferro", Vector3(0.03, 0.03, 0.2), Vector3(0.7, 0.9, -0.48), p, giro)
	# As ferramentas largadas: a lata de óleo, os pregos, uma plaina.
	_parte("ferro", Vector3(0.24, 0.07, 0.07), Vector3(-0.5, 0.885, -0.15), p, giro, Color(1.2, 1.1, 1.0))
	_parte("madeira_escura", Vector3(0.05, 0.03, 0.3), Vector3(-0.2, 0.865, 0.1), p, giro)
	_colide(Vector3(1.8, 0.85, 0.7), Vector3(0, 0.425, 0), p, giro)


## As prateleiras de parede da oficina, com os vidros, as latas e as caixas.
func _prateleiras(p: Vector3, giro: float) -> void:
	var m := "madeira_clara"
	for k in 3:
		var y := 1.0 + k * 0.42
		_parte(m, Vector3(1.0, 0.025, 0.26), Vector3(0, y, 0), p, giro)
		for j in 5:
			var x := -0.4 + j * 0.2
			if (j + k) % 3 == 0:
				_parte("papelao_escuro", Vector3(0.15, 0.13, 0.16), Vector3(x, y + 0.08, 0), p, giro, Color(0.95, 0.9, 0.8))
			else:
				_cilindro("vidro_fazenda" if j % 2 else "ferro", p + Basis.from_euler(Vector3(0, deg_to_rad(giro), 0)) * Vector3(x, y + 0.1, 0), 0.045, 0.17, 8, Color(1.4, 1.35, 1.2))
	for sx: float in [-1.0, 1.0]:
		_parte(m, Vector3(0.025, 0.25, 0.22), Vector3(sx * 0.45, 0.88, 0.0), p, giro)


## O cabideiro do vestíbulo: a haste torneada, os ganchos, um casaco pendurado e o
## chapéu de feltro.
func _cabideiro(p: Vector3) -> void:
	_cilindro("madeira_escura", p + Vector3(0, 0.9, 0), 0.025, 1.8, 8)
	for k in 4:
		var a := TAU * k / 4.0
		_bloco("madeira_escura", Vector3(0.28, 0.03, 0.03), p + Vector3(cos(a) * 0.1, 0.06, sin(a) * 0.1), Color.WHITE, false, Vector3(0, -rad_to_deg(a), -8))
		_bloco("madeira_escura", Vector3(0.12, 0.02, 0.02), p + Vector3(cos(a) * 0.07, 1.72, sin(a) * 0.07), Color.WHITE, false, Vector3(0, -rad_to_deg(a), 30))
	_bloco("la_escura", Vector3(0.42, 0.95, 0.16), p + Vector3(0.0, 1.2, -0.12), Color(0.8, 0.75, 0.7), false, Vector3(0, 10, 0))
	_cilindro("la_escura", p + Vector3(0.1, 1.85, 0.05), 0.11, 0.025, 10, Color(0.7, 0.62, 0.55))
	_cilindro("la_escura", p + Vector3(0.1, 1.9, 0.05), 0.075, 0.09, 10, Color(0.7, 0.62, 0.55))
	_col.append([Vector3(0.45, 1.8, 0.45), p + Vector3(0, 0.9, 0)])


## A cama de ferro: a cabeceira e os pés de tubos com as barras, o estrado, o
## colchão, a colcha de retalhos dobrada no pé, o travesseiro.
func _cama_ferro(p: Vector3, giro: float, larg := 1.25) -> void:
	var comp := 1.95
	var f := "ferro"
	var preto := Color(0.45, 0.45, 0.48)
	for lado: float in [1.0, -1.0]:
		var z := lado * comp / 2
		var alto := 1.15 if lado > 0 else 0.8
		for sx: float in [-1.0, 1.0]:
			_parte(f, Vector3(0.035, alto, 0.035), Vector3(sx * larg / 2, alto / 2, z), p, giro, preto)
			_parte("latao", Vector3(0.05, 0.05, 0.05), Vector3(sx * larg / 2, alto + 0.02, z), p, giro)
		_parte(f, Vector3(larg, 0.03, 0.03), Vector3(0, alto - 0.04, z), p, giro, preto)
		_parte(f, Vector3(larg, 0.025, 0.025), Vector3(0, 0.38, z), p, giro, preto)
		for k in 7:
			var x := -larg / 2 + (k + 1) * larg / 8
			_parte(f, Vector3(0.015, alto - 0.42, 0.015), Vector3(x, 0.38 + (alto - 0.42) / 2, z), p, giro, preto)
	_parte("madeira_escura", Vector3(larg - 0.04, 0.06, comp - 0.04), Vector3(0, 0.36, 0), p, giro)
	_parte("lencol", Vector3(larg - 0.06, 0.18, comp - 0.08), Vector3(0, 0.48, 0), p, giro)
	_parte("colcha", Vector3(larg - 0.02, 0.05, comp * 0.62), Vector3(0, 0.595, -comp * 0.17), p, giro)
	_parte("colcha", Vector3(larg + 0.02, 0.32, 0.03), Vector3(0, 0.46, -comp / 2 + 0.03), p, giro, Color(0.9, 0.9, 0.9))
	for sx: float in [-1.0, 1.0]:
		_parte("colcha", Vector3(0.03, 0.32, comp * 0.62), Vector3(sx * (larg / 2 + 0.005), 0.46, -comp * 0.17), p, giro, Color(0.9, 0.9, 0.9))
	_parte("lencol", Vector3(larg * 0.8, 0.1, 0.36), Vector3(0, 0.62, comp / 2 - 0.3), p, giro, Color(1.1, 1.1, 1.08))
	_colide(Vector3(larg + 0.05, 0.7, comp + 0.05), Vector3(0, 0.35, 0), p, giro)


## O guarda-roupa: as duas portas com almofadas, a cornija, a gaveta do pé.
func _guarda_roupa(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	_parte(m, Vector3(1.0, 1.95, 0.55), Vector3(0, 1.0, 0), p, giro)
	_parte(m, Vector3(1.1, 0.08, 0.62), Vector3(0, 2.0, -0.02), p, giro)
	for sx: float in [-1.0, 1.0]:
		_parte(m, Vector3(0.46, 1.4, 0.02), Vector3(sx * 0.24, 1.2, -0.285), p, giro, Color(1.12, 1.12, 1.12))
		_parte(m, Vector3(0.34, 0.5, 0.01), Vector3(sx * 0.24, 1.5, -0.298), p, giro, Color(0.9, 0.9, 0.9))
		_parte(m, Vector3(0.34, 0.5, 0.01), Vector3(sx * 0.24, 0.85, -0.298), p, giro, Color(0.9, 0.9, 0.9))
		_parte("latao", Vector3(0.015, 0.06, 0.02), Vector3(sx * 0.03, 1.2, -0.3), p, giro)
	_parte(m, Vector3(0.94, 0.25, 0.02), Vector3(0, 0.3, -0.285), p, giro, Color(1.12, 1.12, 1.12))
	_colide(Vector3(1.0, 2.0, 0.55), Vector3(0, 1.0, 0), p, giro)


## A cômoda com o espelho: as quatro gavetas de puxadores, o tampo, o espelho
## oval na moldura.
func _comoda(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	_parte(m, Vector3(1.1, 0.9, 0.5), Vector3(0, 0.47, 0), p, giro)
	_parte(m, Vector3(1.16, 0.035, 0.54), Vector3(0, 0.935, 0), p, giro)
	for k in 4:
		var gy := 0.15 + k * 0.2
		_parte(m, Vector3(1.0, 0.17, 0.02), Vector3(0, gy, -0.255), p, giro, Color(1.12, 1.12, 1.12))
		for sx: float in [-1.0, 1.0]:
			_parte("latao", Vector3(0.05, 0.015, 0.02), Vector3(sx * 0.27, gy + 0.02, -0.27), p, giro)
	_parte(m, Vector3(0.7, 0.85, 0.04), Vector3(0, 1.4, 0.2), p, giro)
	_parte("vidro_fazenda", Vector3(0.58, 0.72, 0.01), Vector3(0, 1.4, 0.175), p, giro, Color(1.7, 1.7, 1.8))
	_colide(Vector3(1.1, 0.95, 0.5), Vector3(0, 0.47, 0), p, giro)


## O lavatório: o móvel de mármore com a portinha, o jarro na bacia, a toalha.
func _lavatorio(p: Vector3, giro: float) -> void:
	var m := "madeira_escura"
	_parte(m, Vector3(0.75, 0.75, 0.45), Vector3(0, 0.38, 0), p, giro)
	_parte("granito", Vector3(0.8, 0.03, 0.5), Vector3(0, 0.775, 0), p, giro, Color(1.4, 1.38, 1.32))
	_parte(m, Vector3(0.8, 0.18, 0.03), Vector3(0, 0.88, 0.22), p, giro)
	_parte(m, Vector3(0.6, 0.5, 0.02), Vector3(0, 0.35, -0.225), p, giro, Color(1.12, 1.12, 1.12))
	var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
	_cilindro("porcelana", p + b * Vector3(0, 0.82, 0), 0.19, 0.08, 14)
	_cilindro("porcelana", p + b * Vector3(0, 0.95, 0), 0.075, 0.2, 10)
	_cilindro("porcelana", p + b * Vector3(0, 1.07, 0), 0.055, 0.05, 10)
	_parte("lencol", Vector3(0.03, 0.42, 0.25), Vector3(0.4, 0.5, 0), p, giro, Color(1.1, 1.1, 1.06))
	_colide(Vector3(0.8, 0.8, 0.5), Vector3(0, 0.4, 0), p, giro)


## A banheira de pés: o casco de bordas arredondadas, a borda, os quatro pés de
## garra, a torneira.
func _banheira(p: Vector3) -> void:
	var comp := 1.55
	_bloco("porcelana", Vector3(0.7, 0.42, comp - 0.2), p + Vector3(0, 0.38, 0), Color.WHITE, false)
	for s: float in [-1.0, 1.0]:
		_bloco("porcelana", Vector3(0.62, 0.42, 0.12), p + Vector3(0, 0.4, s * (comp / 2 - 0.06)), Color.WHITE, false)
		_bloco("porcelana", Vector3(0.08, 0.07, comp - 0.1), p + Vector3(s * 0.36, 0.62, 0), Color(1.1, 1.1, 1.1), false)
		_bloco("porcelana", Vector3(0.7, 0.07, 0.08), p + Vector3(0, 0.62, s * (comp / 2 - 0.04)), Color(1.1, 1.1, 1.1), false)
	_bloco("agua", Vector3(0.6, 0.01, comp - 0.25), p + Vector3(0, 0.5, 0), Color(0.6, 0.65, 0.7), false)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_bloco("ferro", Vector3(0.07, 0.16, 0.07), p + Vector3(sx * 0.26, 0.08, sz * (comp / 2 - 0.2)), Color(0.5, 0.5, 0.5), false)
	_bloco("latao", Vector3(0.04, 0.2, 0.04), p + Vector3(0, 0.75, comp / 2 - 0.05), Color.WHITE, false)
	_col.append([Vector3(0.75, 0.65, comp), p + Vector3(0, 0.33, 0)])


## A pia de coluna, com as torneiras.
func _pia_coluna(p: Vector3, giro: float) -> void:
	_cilindro("porcelana", p + Vector3(0, 0.38, 0), 0.08, 0.76, 10)
	_parte("porcelana", Vector3(0.55, 0.12, 0.42), Vector3(0, 0.82, 0), p, giro)
	_parte("porcelana", Vector3(0.55, 0.12, 0.05), Vector3(0, 0.94, 0.19), p, giro)
	for sx: float in [-1.0, 1.0]:
		_parte("latao", Vector3(0.03, 0.06, 0.03), Vector3(sx * 0.1, 0.91, 0.12), p, giro)
	_colide(Vector3(0.55, 0.9, 0.45), Vector3(0, 0.45, 0), p, giro)


## A privada de caixa alta: a bacia, o assento de madeira, a caixa de descarga no
## alto da parede, o cano e a corrente.
func _privada(p: Vector3, giro: float) -> void:
	_cilindro("porcelana", p + Vector3(0, 0.2, 0), 0.17, 0.4, 12)
	_parte("madeira_escura", Vector3(0.38, 0.03, 0.45), Vector3(0, 0.415, -0.03), p, giro)
	_parte("madeira_escura", Vector3(0.45, 0.28, 0.2), Vector3(0, 1.95, 0.18), p, giro)
	_parte("ferro", Vector3(0.04, 1.45, 0.04), Vector3(0, 1.1, 0.2), p, giro, Color(0.8, 0.8, 0.8))
	_parte("ferro", Vector3(0.008, 0.45, 0.008), Vector3(0.18, 1.6, 0.1), p, giro, Color(0.8, 0.8, 0.8))
	_colide(Vector3(0.42, 0.45, 0.55), Vector3(0, 0.22, 0), p, giro)


## A máquina de costura de pedal: o gabinete de ferro fundido, o pedal, a cabeça
## preta da máquina.
func _maquina_costura(p: Vector3, giro: float) -> void:
	_parte("madeira_escura", Vector3(0.9, 0.03, 0.45), Vector3(0, 0.76, 0), p, giro)
	for sx: float in [-1.0, 1.0]:
		_parte("ferro", Vector3(0.04, 0.74, 0.4), Vector3(sx * 0.4, 0.38, 0), p, giro, Color(0.5, 0.5, 0.52))
	_parte("ferro", Vector3(0.5, 0.03, 0.25), Vector3(0, 0.1, -0.02), p, giro, Color(0.5, 0.5, 0.52), Vector3(10, 0, 0))
	_parte("esmalte_preto", Vector3(0.38, 0.12, 0.14), Vector3(0, 0.84, 0.05), p, giro)
	_parte("esmalte_preto", Vector3(0.1, 0.28, 0.12), Vector3(0.15, 0.95, 0.05), p, giro)
	_parte("esmalte_preto", Vector3(0.3, 0.08, 0.1), Vector3(0.02, 1.07, 0.05), p, giro)
	_colide(Vector3(0.9, 0.8, 0.45), Vector3(0, 0.4, 0), p, giro)


## O tapete trançado redondo (oval), no chão do cômodo.
func _tapete_redondo(p: Vector3, tam: Vector2) -> void:
	var t := MeshInstance3D.new()
	t.name = "Tapete%d" % _col.size()
	var plano := PlaneMesh.new()
	plano.size = tam
	plano.subdivide_width = 3
	plano.subdivide_depth = 3
	t.mesh = plano
	t.material_override = m["tapete_trancado"]
	t.position = p + Vector3(0, 0.006, 0)
	t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(_group_tapetes(), t)


func _group_tapetes() -> Node3D:
	if cena.has_node(^"Tapetes"):
		return cena.get_node(^"Tapetes") as Node3D
	return _group(cena, "Tapetes")


## Um cilindro fixo em pé (o centro em `c`), na malha do material.
func _cilindro(mat: String, c: Vector3, raio: float, alto: float, lados := 10, cor := Color.WHITE) -> void:
	var mm := _obra(mat)
	var y0 := c.y - alto / 2
	var y1 := c.y + alto / 2
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var p0 := Vector3(c.x + cos(a0) * raio, 0, c.z + sin(a0) * raio)
		var p1 := Vector3(c.x + cos(a1) * raio, 0, c.z + sin(a1) * raio)
		var n := Vector3(cos((a0 + a1) / 2), 0, sin((a0 + a1) / 2))
		mm.quad(Vector3(p0.x, y0, p0.z), Vector3(p1.x, y0, p1.z), Vector3(p1.x, y1, p1.z), Vector3(p0.x, y1, p0.z), n, cor)
		mm.tri(Vector3(c.x, y1, c.z), Vector3(p0.x, y1, p0.z), Vector3(p1.x, y1, p1.z), Vector3.UP, cor)
		mm.tri(Vector3(c.x, y0, c.z), Vector3(p1.x, y0, p1.z), Vector3(p0.x, y0, p0.z), Vector3.DOWN, cor)


## Um disco em pé (um prato encostado), virado para a frente da peça (`giro`).
func _cilindro_deitado(mat: String, c: Vector3, raio: float, esp: float, giro: float) -> void:
	var mm := _obra(mat)
	var b := Basis.from_euler(Vector3(deg_to_rad(-12), deg_to_rad(giro), 0))
	var frente := b * Vector3(0, 0, -1)
	var lados := 12
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var p0 := c + b * Vector3(cos(a0) * raio, sin(a0) * raio, 0)
		var p1 := c + b * Vector3(cos(a1) * raio, sin(a1) * raio, 0)
		mm.tri(c - frente * esp, p0 - frente * esp, p1 - frente * esp, -frente, Color.WHITE)
		mm.tri(c, p1, p0, frente, Color(0.95, 0.95, 0.95))


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
	_bloco("assoalho_largo", Vector3(px.y - px.x - 0.2, 0.1, pz.y - pz.x - 0.2), Vector3((px.x + px.y) / 2 + 0.1, T0 - 0.05, (pz.x + pz.y) / 2))
	_bloco("teto_casa", Vector3(px.y - px.x - 0.2, 0.08, pz.y - pz.x - 0.2), Vector3((px.x + px.y) / 2 + 0.1, alto + 0.04, (pz.x + pz.y) / 2), Color.WHITE, false)
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
	_cozinha()
	# Os degraus de granito da porta do quintal (norte) e da porta do galpão (oeste),
	# com a rampa de colisão por baixo. Playtest 12 ("algumas portas só funcionam para
	# sair e não para entrar"): as rampas eram curtas e paravam no meio da fundação —
	# descia-se por elas, mas subindo o corpo empacava na quina da pedra.
	for k in 3:
		var fundo := -1.35 + 0.45 * k + 0.225 - 0.04
		_bloco("granito", Vector3(1.3, 0.2 * (k + 1), 0.45), Vector3(-6.5, 0.1 * (k + 1), pz.x + fundo), Color.WHITE * (0.92 + k * 0.04), false)
		_bloco("granito", Vector3(0.45, 0.2 * (k + 1), 1.2), Vector3(px.x + fundo, 0.1 * (k + 1), 4.6), Color.WHITE * (0.92 + k * 0.04), false)
	# A rampa chega ao piso na face de fora da fundação (a pedra ficava acima dela).
	_rampa(Vector3(-6.5, 0, pz.x - 1.9), Vector3(-6.5, T0, pz.x - 0.04), 1.1)
	_rampa(Vector3(px.x - 1.9, 0, 4.6), Vector3(px.x - 0.04, T0, 4.6), 1.0)


# --- As dependências: o galpão de lenha, a arcada, o celeiro, o galinheiro --------------

func _dependencias() -> void:
	_galpao_lenha()
	_arcada()
	_deslocado(CELEIRO_D, func() -> void:
		_celeiro()
		_celeiro_acabamento()
		_galinheiro())


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
	# A lenha (playtest 11, R4): as toras rachadas empilhadas contra a parede de
	# trás, de ponta para o norte — o corte claro à vista, a casca escura dos lados —,
	# cada fila desencontrada da de baixo; duas pilhas, a da esquerda mais baixa.
	var lenha := _obra("madeira_clara")
	for fila in 7:
		var xx := x.x + 0.3 + (0.1 if fila % 2 else 0.0)
		while xx < x.y - 0.3:
			var r := _rng.randf_range(0.075, 0.11)
			if fila < (4 if xx < x.x + 1.5 else 7):
				var c := Vector3(xx, 0.1 + fila * 0.185 + _rng.randf_range(-0.015, 0.015), z.y - 0.5 + _rng.randf_range(-0.06, 0.06))
				_tora(lenha, c, r, _rng.randf_range(0.48, 0.6))
			xx += r * 2.1
	_col.append([Vector3(3.8, 1.3, 0.6), Vector3(x.x + 2.2, 0.65, z.y - 0.5)])
	# O cepo (um toco de tronco largo), o machado cravado nele e as achas largadas
	# em volta.
	var cepo := Vector3(-11.0, 0, 2.6)
	_cilindro("madeira_escura", cepo + Vector3(0, 0.22, 0), 0.26, 0.44, 9, Color(0.95, 0.85, 0.75))
	_cilindro("madeira_clara", cepo + Vector3(0, 0.442, 0), 0.24, 0.006, 9, Color(1.15, 0.95, 0.68))
	_col.append([Vector3(0.5, 0.45, 0.5), cepo + Vector3(0, 0.225, 0)])
	_bloco("madeira_clara", Vector3(0.04, 0.75, 0.04), cepo + Vector3(0.12, 0.78, 0), Color.WHITE, false, Vector3(0, 0, -35))
	_bloco("ferro", Vector3(0.18, 0.1, 0.025), cepo + Vector3(-0.06, 0.5, 0), Color(0.75, 0.75, 0.75), false, Vector3(0, 0, -35))
	for k in 5:
		var a := _rng.randf() * TAU
		var p := cepo + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.45, 0.9)
		_tora(lenha, p + Vector3(0, 0.07, 0), _rng.randf_range(0.06, 0.08), _rng.randf_range(0.35, 0.45))
	# O serrote de arco pendurado na parede oeste, por dentro.
	var serrote := Vector3(x.x + 0.16, 1.55, 3.6)
	for s: float in [-1.0, 1.0]:
		_bloco("madeira_clara", Vector3(0.025, 0.42, 0.03), serrote + Vector3(0, 0, s * 0.32), Color.WHITE, false, Vector3(s * 8.0, 0, 0))
	_bloco("madeira_clara", Vector3(0.025, 0.03, 0.62), serrote, Color.WHITE, false)
	_bloco("ferro", Vector3(0.008, 0.03, 0.7), serrote + Vector3(0, -0.2, 0), Color(0.8, 0.8, 0.8), false)
	_bloco("ferro", Vector3(0.006, 0.006, 0.66), serrote + Vector3(0, 0.19, 0), Color(0.6, 0.6, 0.6), false)


## Uma tora deitada (de leste a oeste), a ponta clara do corte para o norte.
func _face_toras(lenha: Cidade.Malha, c: Vector3) -> void:
	lenha.caixa(Vector3(0.24, 0.22, 0.6), c, Color(0.75, 0.6, 0.45) * _rng.randf_range(0.8, 1.1))


## A arcada coberta do galpão de lenha ao celeiro (o "ligados por arcadas").
func _arcada() -> void:
	var x := Vector2(-12.6, -9.4)
	# Playtest 12: o celeiro foi para longe; a arcada ficou um alpendre na frente do
	# galpão (ia até o celeiro, 9 m ao norte).
	var z := Vector2(-5.0, PUXADO_Z.x)
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
	# Nós à parte (F5: "Fechar o celeiro" as corre para o meio; Rotina.portao).
	var portao_g := _group(cena, "PortaoCeleiro", Vector3(cumeeira.x, 0, z.y + 0.1))
	portao_g.set_meta(&"porta_teste", ["o portão do celeiro", Vector3(cumeeira.x, 0, z.y + 1.8) + CELEIRO_D, Vector3(cumeeira.x, 0, z.y) + CELEIRO_D, Vector3(cumeeira.x, 0, z.y - 2.4) + CELEIRO_D])
	var leste := _group(cena, "_TesteCeleiroLeste")
	leste.set_meta(&"porta_teste", ["a porta do celeiro (leste)", Vector3(x.y + 1.6, 0, -12.0) + CELEIRO_D, Vector3(x.y, 0, -12.0) + CELEIRO_D, Vector3(x.y - 1.6, 0, -12.0) + CELEIRO_D])
	for s: float in [-1.0, 1.0]:
		var folha := _group(portao_g, "Folha%s" % ("O" if s < 0 else "L"), Vector3(s * (1.8 + 0.95), 0, 0))
		folha.set_meta(&"fechada", Vector3(s * 0.925, 0, 0))
		_box(folha, "Tabuas", Vector3(1.85, 3.9, 0.08), Vector3(0, 1.95, 0), "celeiro")
		var travessa := _box(folha, "Travessa", Vector3(1.85, 0.1, 0.09), Vector3(0, 1.95, 0.01), "pintura_branca")
		travessa.rotation_degrees.z = s * 64.0
		# As roldanas no trilho e o puxador de ferro na borda de dentro; e o suporte
		# da tranca (playtest 12: fechado o portão, a tranca cai nos dois).
		for d: float in [-0.6, 0.6]:
			_cyl(folha, "Roldana%d" % int(d * 10), 0.06, 0.06, 0.03, Vector3(d, 3.92, 0.04), "ferro", 8).rotation_degrees.x = 90.0
		_box(folha, "Puxador", Vector3(0.04, 0.32, 0.04), Vector3(-s * 0.84, 1.15, 0.07), "ferro")
		_box(folha, "Suporte", Vector3(0.14, 0.04, 0.08), Vector3(-s * 0.32, 1.08, 0.08), "ferro")
		_box(folha, "SuporteBorda", Vector3(0.14, 0.12, 0.02), Vector3(-s * 0.32, 1.12, 0.135), "ferro")
	_bloco("ferro", Vector3(7.6, 0.08, 0.08), Vector3(cumeeira.x, 3.95, z.y + 0.12), Color.WHITE, false)
	# A tranca: uma trave de carvalho encostada na parede, a leste do portão; fechadas
	# as folhas, ela cai atravessada nos suportes (`fechada`, a pose no portão).
	var tranca := _group(portao_g, "Tranca", Vector3(2.55, 1.05, 0.12))
	tranca.rotation_degrees = Vector3(0, 0, 76.0)
	tranca.set_meta(&"travada", Transform3D(Basis.IDENTITY, Vector3(0, 1.15, 0.085)))
	_box(tranca, "Trave", Vector3(1.5, 0.1, 0.07), Vector3.ZERO, "madeira_escura")
	for d: float in [-0.6, 0.6]:
		_box(tranca, "Cinta%d" % int(d * 10), Vector3(0.05, 0.11, 0.08), Vector3(d, 0, 0), "ferro")
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
	_carroca(Vector3(-11.3, 0, -15.0))
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
	# Playtest 12: o cercado não tinha por onde entrar (e a porta do galinheiro dá
	# para ele): a cancela no lado sul, diante da porta, aberta contra a cerca.
	_cerca(Vector2(x.x, z.y), Vector2(x.x, z.y + 4.0), "madeira_escura")
	_cerca(Vector2(x.x, z.y + 4.0), Vector2(-26.2, z.y + 4.0), "madeira_escura")
	_cerca(Vector2(-24.9, z.y + 4.0), Vector2(x.y, z.y + 4.0), "madeira_escura")
	_cerca(Vector2(x.y, z.y + 4.0), Vector2(x.y, z.y), "madeira_escura")
	for k in 3:
		_bloco("madeira_escura", Vector3(0.03, 0.1, 1.2), Vector3(-24.82, 0.35 + k * 0.33, z.y + 4.0 - 0.62), Color(0.85, 0.85, 0.85), false)
	_bloco("madeira_escura", Vector3(0.035, 1.05, 0.08), Vector3(-24.82, 0.6, z.y + 4.0 - 1.18), Color(0.8, 0.8, 0.8), false)
	var teste := _group(cena, "_TesteGalinheiro")
	teste.set_meta(&"porta_teste", ["a cancela do chiqueiro", Vector3(-25.55, 0, z.y + 5.4) + CELEIRO_D, Vector3(-25.55, 0, z.y + 4.0) + CELEIRO_D, Vector3(-25.55, 0, z.y + 2.2) + CELEIRO_D])
	var teste2 := _group(cena, "_TesteGalinheiro2")
	teste2.set_meta(&"porta_teste", ["o galinheiro", Vector3(-25.5, 0, z.y + 1.6) + CELEIRO_D, Vector3(-25.5, 0, z.y) + CELEIRO_D, Vector3(-25.5, 0, z.y - 1.6) + CELEIRO_D])


## Uma cerca de mourões e três tábuas de `de` a `ate`.
func _cerca(de: Vector2, ate: Vector2, mat: String) -> void:
	var compr := de.distance_to(ate)
	var dir := (ate - de) / compr
	var giro := -rad_to_deg(atan2(dir.y, dir.x))
	var n := maxi(1, ceili(compr / 2.0))
	for i in n + 1:
		var p := de + dir * compr * i / n
		_bloco(mat, Vector3(0.12, 1.25, 0.12), Vector3(p.x, 0.62, p.y), Color.WHITE * _rng.randf_range(0.85, 1.1), false,
			Vector3(_rng.randf_range(-2, 2), giro + _rng.randf_range(-8, 8), _rng.randf_range(-2, 2)))
	var meio := (de + ate) / 2
	# Playtest 11 (R4): as tábuas pregadas de um lado dos mourões (não através
	# deles), cada uma de um tom, meio torta.
	var lado := Vector2(-dir.y, dir.x) * 0.075
	for k in 3:
		_bloco(mat, Vector3(compr, 0.1, 0.03), Vector3(meio.x + lado.x, 0.35 + k * 0.33 + _rng.randf_range(-0.02, 0.02), meio.y + lado.y),
			Color(0.9, 0.9, 0.9) * _rng.randf_range(0.85, 1.1), false, Vector3(0, giro, _rng.randf_range(-0.6, 0.6)))
	_col.append([Vector3(compr, 1.4, 0.2), Vector3(meio.x, 0.7, meio.y), Vector3(0, giro, 0)])


# --- O canil ---------------------------------------------------------------------------

## O canil dos doze cães: um galpão baixo e comprido de doze baias, cada uma com
## a portinhola e a plaquinha com o nome; o cercado de tela na frente.
func _canil() -> void:
	var g := _group(cena, "Canil")
	var x := Vector2(-8.0, 2.8) + Vector2.ONE * CANIL_D.x
	var z := Vector2(-13.0, -10.5) + Vector2.ONE * CANIL_D.z
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
	var fz := -7.0 + CANIL_D.z
	var vao := Vector2(-1.0, 0.4) + Vector2.ONE * CANIL_D.x
	var cantos := [Vector2(x.x, z.y), Vector2(x.x, fz), Vector2(vao.x, fz)]
	_tela(cantos[0], cantos[1])
	_tela(cantos[1], cantos[2])
	_tela(Vector2(vao.y, fz), Vector2(x.y, fz))
	_tela(Vector2(x.y, fz), Vector2(x.y, z.y))
	# Os mourões do vão, mais grossos, e o batente do trinco.
	for xx: float in [vao.x, vao.y]:
		_bloco("madeira_escura", Vector3(0.14, 1.6, 0.14), Vector3(xx, 0.8, fz), Color(0.9, 0.88, 0.85), false)
	_bloco("ferro", Vector3(0.05, 0.1, 0.05), Vector3(vao.y - 0.06, 0.75, fz + 0.04), Color(0.6, 0.6, 0.6), false)
	# A porteira, fechada (F6: "Abrir a porteira" a gira para dentro do cercado e
	# os cães ficam soltos): a dobradiça na ponta oeste do vão.
	var porteira := _group(cena, "Porteira", Vector3(vao.x, 0, fz))
	for k in 3:
		_box(porteira, "Tabua%d" % k, Vector3(1.3, 0.1, 0.04), Vector3(0.65, 0.3 + k * 0.35, 0), "madeira_escura")
	for xx: float in [0.05, 1.25]:
		_box(porteira, "Montante%d" % int(xx), Vector3(0.08, 1.1, 0.05), Vector3(xx, 0.6, 0), "madeira_escura")
	var diag := _box(porteira, "Diagonal", Vector3(1.4, 0.08, 0.035), Vector3(0.65, 0.65, 0.01), "madeira_escura")
	diag.rotation_degrees.z = 32.0
	_box(porteira, "Tela", Vector3(1.14, 0.98, 0.004), Vector3(0.65, 0.63, -0.03), "tela_arame")
	# O trinco de aldrava: a lingueta presa num pino na ponta da porteira, que cai
	# no batente do mourão (a animação de abrir a ergue).
	var trinco := _group(porteira, "Trinco", Vector3(1.22, 0.75, 0.035))
	_box(trinco, "Lingueta", Vector3(0.2, 0.03, 0.025), Vector3(0.08, 0, 0), "ferro")
	_box(trinco, "Pegador", Vector3(0.025, 0.06, 0.025), Vector3(0.16, 0.035, 0), "ferro")
	_cyl(porteira, "Pino", 0.012, 0.012, 0.05, Vector3(1.22, 0.75, 0.035), "ferro", 6).rotation_degrees.x = 90.0
	# Playtest 12: a porteira fechada barra o corpo (era só de enfeite: passava-se
	# por ela). Abre para dentro do cercado (o giro positivo).
	_colisao(porteira, "Colisao", [[Vector3(1.32, 1.2, 0.08), Vector3(0.66, 0.6, 0)]])
	porteira.set_meta(&"porta_teste", ["a porteira do cercado", Vector3((vao.x + vao.y) / 2, 0, fz + 1.4), Vector3((vao.x + vao.y) / 2, 0, fz), Vector3((vao.x + vao.y) / 2, 0, fz - 1.4)])
	_caes(x, Vector2(z.y + 0.6, fz - 0.5))
	var matilha := cena.get_node("Caes") as Matilha
	matilha.porteira_dentro = Vector3((vao.x + vao.y) / 2, 0, fz - 0.9)
	matilha.porteira_fora = Vector3((vao.x + vao.y) / 2, 0, fz + 1.0)
	# A porteira aberta (100°) vai da dobradiça até uns 1,3 m para dentro: a volta
	# fica além da ponta dela.
	matilha.porteira_volta = Vector3(vao.x - 0.2, 0, fz - 2.1)


## A rotina do entardecer (F5; docs/PLANO_FAZENDA.md, "A tratativa", 1): a gamela
## comprida rente à tela da frente do cercado (por dentro), com a ração que corre
## por ela; o bebedouro de zinco no canto leste; a bomba manual do poço, de ferro,
## numa laje de pedra, perto do canil; o balde que fica no chão; a braçada de lenha
## diante dos olhos (NaMao); a lenha arrumada na lareira do escritório; as áreas; e
## a `Rotina`, que dá a ordem.
const GAMELA_Z := -7.29 + CANIL_D.z
const GAMELA_X := Vector2(-7.6, -1.4)


func _rotina() -> void:
	var g := _group(cena, "RotinaPecas")
	var caes := cena.get_node("Caes") as Matilha
	var balde := cena.get_node("Balde") as NaMao
	# A gamela: duas tábuas e o fundo, em pés curtos.
	var gx := (GAMELA_X.x + GAMELA_X.y) / 2
	var gl := GAMELA_X.y - GAMELA_X.x
	_bloco("madeira_escura", Vector3(gl, 0.04, 0.3), Vector3(gx, 0.14, GAMELA_Z), Color.WHITE, false)
	for s: float in [-1.0, 1.0]:
		_bloco("madeira_escura", Vector3(gl, 0.14, 0.04), Vector3(gx, 0.2, GAMELA_Z + s * 0.15), Color(0.9, 0.9, 0.9), false)
	for xx: float in [GAMELA_X.x + 0.2, gx, GAMELA_X.y - 0.2]:
		_bloco("madeira_escura", Vector3(0.08, 0.12, 0.3), Vector3(xx, 0.06, GAMELA_Z), Color(0.8, 0.8, 0.8), false)
	# A ração corre do leste para o oeste: o pivô na ponta leste, escala em x.
	var racao := _group(g, "RacaoGamela", Vector3(GAMELA_X.y - 0.05, 0.17, GAMELA_Z))
	_box(racao, "Racao", Vector3(gl - 0.1, 0.035, 0.22), Vector3(-(gl - 0.1) / 2, 0, 0), "racao")
	racao.scale.x = 0.001
	# Os lugares dos cães ao longo dela (por dentro, de frente para a tela).
	var lugares := PackedVector3Array()
	var n := 11
	for i in n:
		lugares.append(Vector3(lerpf(GAMELA_X.y - 0.35, GAMELA_X.x + 0.35, float(i) / (n - 1)), 0, GAMELA_Z - 0.55))
	caes.gamela = lugares
	caes.gamela_frente = Vector3(0, 0, 1)
	# O bebedouro de zinco, no canto leste do cercado, e a água que sobe nele.
	# Rente à tela (playtest 12, depois: a água vai por cima dela).
	var beb := Vector3(2.42, 0, -9.85) + CANIL_D
	_cyl(g, "Bebedouro", 0.32, 0.28, 0.26, beb + Vector3(0, 0.13, 0), "zinco", 12)
	var agua := _group(g, "AguaBebedouro", beb + Vector3(0, 0.03, 0))
	_cyl(agua, "Agua", 0.29, 0.29, 0.2, Vector3(0, 0.1, 0), "agua", 12)
	agua.scale.y = 0.05
	# A bomba manual do poço: a laje, o corpo de ferro, a bica e a alavanca.
	# Playtest 12: ao sol (atrás do canil, na sombra comprida dele, ficava no escuro),
	# a uns passos da ponta da frente do cercado.
	var poco := Vector3(5.6, 0, -16.6)
	_bloco("pedra_campo", Vector3(0.9, 0.16, 0.9), poco + Vector3(0, 0.08, 0))
	# A bomba de balancim (a "pitcher pump"): o cano que sai da laje, o corpo de
	# ferro fundido, a bica para a frente (+Z), e a alavanca presa no pivô do alto,
	# para trás e para cima.
	var bomba := _group(g, "Bomba", poco)
	_cyl(bomba, "Cano", 0.045, 0.05, 0.42, Vector3(0, 0.37, 0), "ferro", 8)
	_cyl(bomba, "Corpo", 0.1, 0.11, 0.5, Vector3(0, 0.83, 0), "ferro", 10)
	_cyl(bomba, "Anel", 0.12, 0.12, 0.04, Vector3(0, 0.6, 0), "ferro", 10)
	_cyl(bomba, "Tampa", 0.07, 0.11, 0.06, Vector3(0, 1.11, 0), "ferro", 10)
	var bica := _cyl(bomba, "Bica", 0.03, 0.04, 0.26, Vector3(0, 0.95, 0.19), "ferro", 6)
	bica.rotation_degrees.x = 100.0
	_box(bomba, "Suporte", Vector3(0.05, 0.16, 0.05), Vector3(0, 1.2, -0.07), "ferro")
	var pivo := _group(bomba, "Alavanca", Vector3(0, 1.26, -0.07))
	pivo.rotation_degrees.x = 22.0
	_box(pivo, "Braco", Vector3(0.035, 0.035, 0.62), Vector3(0, 0, -0.3), "ferro")
	_box(pivo, "Punho", Vector3(0.05, 0.05, 0.12), Vector3(0, 0, -0.6), "madeira_escura")
	var haste := _box(bomba, "Haste", Vector3(0.025, 0.12, 0.025), Vector3(0, 1.2, 0.03), "ferro")
	_col.append([Vector3(0.25, 1.3, 0.25), poco + Vector3(0, 0.65, 0)])
	# Playtest 12 ("tirar água do poço... fraca"): o jato que sai da bica a cada
	# golpe da alavanca (o pivô na boca da bica, escala em y até a água do balde) e
	# os respingos onde ele bate.
	var mat_jato := StandardMaterial3D.new()
	mat_jato.albedo_color = Color(0.72, 0.8, 0.86, 0.82)
	mat_jato.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_jato.roughness = 0.08
	mat_jato.metallic_specular = 0.9
	var jato := _group(bomba, "Jato", Vector3(0, 0.905, 0.335))
	var fio := MeshInstance3D.new()
	fio.name = "Fio"
	var cil := CylinderMesh.new()
	cil.top_radius = 0.022
	cil.bottom_radius = 0.016
	cil.height = 1.0
	cil.radial_segments = 6
	cil.rings = 1
	cil.material = mat_jato
	fio.mesh = cil
	fio.position = Vector3(0, -0.5, 0)
	fio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(jato, fio)
	jato.scale.y = 0.001
	jato.visible = false
	var respingos := _jorro("Respingos", Vector3(0, 0.72, 0.37), Vector3(0, 1, 0), Color(0.66, 0.74, 0.8, 0.7), Vector3(0.012, 0.012, 0.012), 40, 0.35, true)
	respingos.spread = 70.0
	respingos.initial_velocity_min = 0.4
	respingos.initial_velocity_max = 0.9
	_add(bomba, respingos)
	# O balde deixado no chão, ao lado do bebedouro, por fora da tela (de pé diante
	# do bebedouro, Akeley o pousa à frente e à esquerda).
	var no_chao := _group(g, "BaldeNoChao", Vector3(3.3, 0, -9.3) + CANIL_D)
	_cyl(no_chao, "Corpo", 0.15, 0.12, 0.26, Vector3(0, 0.13, 0), "zinco", 12)
	_cyl(no_chao, "Aro", 0.155, 0.155, 0.025, Vector3(0, 0.26, 0), "ferro", 12)
	no_chao.visible = false
	# A água no balde (some ao despejar).
	var agua_balde := _cyl(balde, "Agua", 0.135, 0.135, 0.03, Vector3(0, 0.1, 0), "agua", 12)
	agua_balde.visible = false
	# A braçada de lenha, diante dos olhos (sem mãos), como o balde.
	var bracada := Node3D.new()
	bracada.name = "Bracada"
	bracada.set_script(load("res://components/na_mao.gd"))
	_add(cena, bracada)
	bracada.set("posicao", Vector3(0.05, -0.42, -0.7))
	bracada.set("rotacao", Vector3(10, 0, 0))
	for k in 5:
		var tora := _box(bracada, "Tora%d" % k, Vector3(0.11, 0.11, 0.5), Vector3((k % 3 - 1) * 0.12, (k / 3) * 0.1, 0), "madeira_clara")
		tora.rotation_degrees.y = (k * 7.0) - 14.0
		tora.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var luz := _omni(bracada, "Luz", Vector3(-0.2, 0.35, 0.4), Color(1.0, 0.82, 0.66), 0.45, 0.9)
	luz.light_cull_mask = 1
	# A lenha arrumada na lareira do escritório (a boca a leste da chaminé do sul),
	# rente à boca, na pedra da soleira.
	var boca := Vector3(MEIO_X + CHAMINE_MEIA.x + 0.1, T0 + 0.11, CHAMINE_Z)
	var na_lareira := _group(g, "LenhaLareira", boca)
	# Três na boca, uma sobre as outras, e duas de reserva na pedra, ao lado (as
	# cinco da braçada, uma a uma: playtest 12).
	var arrumacao := [[Vector3(0, 0, -0.07), 4.0], [Vector3(0.02, 0, 0.07), -6.0], [Vector3(0.01, 0.09, 0.0), 12.0],
		[Vector3(0.28, 0.0, 0.62), 84.0], [Vector3(0.3, 0.09, 0.6), 96.0]]
	for k in 5:
		var t := _box(na_lareira, "Tora%d" % k, Vector3(0.1, 0.1, 0.5), arrumacao[k][0], "madeira_clara")
		t.rotation_degrees.y = arrumacao[k][1]
	na_lareira.visible = false

	# As áreas.
	var area := func(nome: String, prompt: String, tam: Vector3, pos: Vector3) -> Interactable:
		var a := _area(g, Interactable.new(), nome, tam, pos) as Interactable
		a.prompt = prompt
		return a
	# A gamela e o bebedouro ficam dentro do cercado; Akeley, fora: as áreas passam
	# por cima da tela (a colisão dela tampava a mira).
	var por_racao: Interactable = area.call("PorRacao", "Pôr a ração", Vector3(gl, 0.9, 1.0), Vector3(gx, 0.5, GAMELA_Z + 0.22))
	var bombear: Interactable = area.call("Bombear", "Encher o balde na bomba", Vector3(0.6, 1.2, 0.6), poco + Vector3(0, 0.9, 0))
	var encher: Interactable = area.call("EncherBebedouro", "Encher o bebedouro", Vector3(0.9, 0.9, 0.9), beb + Vector3(0.3, 0.45, 0))
	var pegar: Interactable = area.call("PegarLenha", "Pegar a lenha", Vector3(3.6, 1.2, 0.8), Vector3(-11.0, 0.7, PUXADO_Z.y - 0.9))
	var por_lenha: Interactable = area.call("PorLenha", "Pôr a lenha na lareira", Vector3(0.6, 0.8, 1.0), boca + Vector3(0, 0.35, 0))
	var celeiro: Interactable = area.call("FecharCeleiro", "Fechar o portão do celeiro", Vector3(3.6, 2.4, 0.8), Vector3(-15.0, 1.4, -7.6) + CELEIRO_D)
	var caixa: Interactable = area.call("AbrirCaixa", "Abrir a caixa de correio", Vector3(0.6, 0.45, 0.45), Vector3(ESTRADA_X.x - 0.52, 1.25, 2.4))

	var r := Rotina.new()
	r.name = "Rotina"
	_add(cena, r)
	r.matilha = caes
	r.balde = balde
	r.bracada = bracada as NaMao
	r.por_racao = por_racao
	r.bombear = bombear
	r.encher_bebedouro = encher
	r.pegar_lenha = pegar
	r.por_lenha = por_lenha
	r.fechar_celeiro = celeiro
	r.abrir_caixa = caixa
	r.racao_gamela = racao
	r.racao_balde = balde.get_node("Racao")
	r.agua_balde = agua_balde
	r.agua_bebedouro = agua
	r.balde_no_chao = no_chao
	r.lenha_lareira = na_lareira
	var portao: Array[Node3D] = []
	var fechado := PackedVector3Array()
	for f in cena.get_node("PortaoCeleiro").get_children():
		if f.has_meta(&"fechada"):
			portao.append(f)
			fechado.append(f.get_meta(&"fechada"))
	r.tranca = cena.get_node("PortaoCeleiro/Tranca")
	r.tranca_fechada = r.tranca.get_meta(&"travada")
	r.caixa_portinhola = cena.get_node("Estrada/CaixaCorreio/Portinhola")
	r.bomba_alavanca = pivo
	r.bomba_haste = haste
	r.jato = jato
	r.respingos = respingos
	# Pendurado pela alça no gancho da bica, a boca logo abaixo dela.
	r.balde_na_bica = poco + Vector3(0, 0.64, 0.37)
	# De pé do lado leste da bomba: a alavanca à direita, a bica à esquerda.
	r.diante_da_bomba = poco + Vector3(0.7, 0, -0.05)
	# Junto da tela do leste, por fora (o corpo encosta nela a 0,36 m).
	r.diante_do_bebedouro = Vector3(2.8 + 0.45, 0, beb.z) + Vector3(CANIL_D.x, 0, 0)
	r.tela_bebedouro = Vector3(2.8, 0, beb.z) + Vector3(CANIL_D.x, 0, 0)
	r.dentro_bebedouro = Vector3.LEFT
	r.tela_racao = Vector3(GAMELA_X.x, 0, -7.0 + CANIL_D.z)
	r.dentro_racao = Vector3.FORWARD
	# O alto das pilhas de lenha do galpão (de onde ele tira as achas).
	r.lenha_pilha = PackedVector3Array([Vector3(-10.7, 1.2, 5.45), Vector3(-10.25, 1.18, 5.42), Vector3(-10.95, 1.0, 5.45),
		Vector3(-9.9, 1.22, 5.45), Vector3(-10.5, 1.0, 5.4)])
	r.diante_da_lenha = Vector3(-10.5, 0, 4.25)
	r.ajoelhar_lareira = boca + Vector3(0.85, -0.11, 0)
	r.portao = portao
	r.portao_fechado = fechado
	# Ao longo da tela, por fora, junto dela (o balde vai por cima da régua).
	var ao_longo := -7.0 + CANIL_D.z + 0.45
	r.caminho_racao = PackedVector3Array([Vector3(GAMELA_X.y + 0.3, 0, ao_longo), Vector3(GAMELA_X.x + 0.4, 0, ao_longo)])
	r.som_racao = _sfx("racao.wav")
	r.som_bomba = _sfx("bomba_poco.wav")
	r.som_bebedouro = _sfx("agua_bebedouro.wav")
	r.som_lenha_pegar = _sfx("lenha_pegar.wav")
	r.som_lenha_largar = _sfx("lenha_largar.wav")
	r.som_portao = _sfx("portao_correr.wav")
	r.som_caixa = _sfx("caixa_correio.wav")
	r.som_trinco = _sfx("porta_trinco.wav")
	r.som_baque = _sfx("menu_baque.wav")
	r.som_sem_passaros = _sfx("dia_quieto.wav")
	var lembretes: Dictionary[StringName, NarrationLine] = {}
	for chave: String in ["racao", "agua", "lenha", "lenha_bracada", "celeiro"]:
		lembretes[StringName(chave)] = load("res://narrative/narration/akeley_%s.tres" % chave)
	r.lembretes = lembretes
	r.linha_caixa = load("res://narrative/narration/akeley_caixa.tres")
	r.linha_yautja = load("res://narrative/narration/akeley_yautja.tres")
	r.linha_chamar = load("res://narrative/narration/akeley_chamar.tres")
	r.linha_nao_voltou = load("res://narrative/narration/akeley_nao_voltou.tres")


## A preparação para a noite (F6; "A tratativa", 2): os lampiões de querosene dos
## quatro cômodos do térreo, as venezianas do escritório e da sala (áreas por
## dentro de cada janela), o rifle de repetição no armário da sala dos fundos e a
## munição na bancada, o telefone de parede do vestíbulo, o fogo da lareira do
## escritório (a lenha da rotina), a lua e as nuvens; e a `Preparacao`.
func _preparacao() -> void:
	var g := _group(cena, "PreparacaoPecas")
	var caes := cena.get_node("Caes") as Matilha
	var chama_tex: Texture2D = load("res://art/textures/chama.png")
	var mat_chama := StandardMaterial3D.new()
	mat_chama.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_chama.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat_chama.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat_chama.billboard_keep_scale = true
	mat_chama.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat_chama.albedo_texture = chama_tex

	# Os lampiões: o pé de latão, o depósito, o colarinho, a chaminé de vidro, a
	# chama no pavio e a luz quente.
	var lampioes: Array[Lampiao] = []
	var lugares := [["Escritorio", Vector3(5.45, T0 + 0.78, 3.25), true], ["Vestibulo", Vector3(0.6, T0 + 0.8, 1.0), false],
		["SalaEstar", Vector3(3.4, T0 + 0.765, -3.7), false], ["Cozinha", Vector3(-5.8, T0 + 0.76, 3.2), false]]
	for l: Array in lugares:
		var lp := _area(g, Lampiao.new(), "Lampiao%s" % l[0], Vector3(0.3, 0.5, 0.3), l[1] + Vector3(0, 0.22, 0)) as Lampiao
		var forma := lp.get_child(0) as Node3D
		forma.position = Vector3.ZERO
		# Playtest 11 (R5): o lampião torneado de verdade — o pé em sino, o
		# depósito bojudo de querosene com o friso, o queimador de latão com a
		# galeria, a rodinha do pavio, e a chaminé de vidro com o bojo.
		_torneado(lp, "Latao", [Vector2(0.0, -0.22), Vector2(0.075, -0.22), Vector2(0.078, -0.212), Vector2(0.05, -0.2),
			Vector2(0.03, -0.17), Vector2(0.035, -0.162), Vector2(0.06, -0.15), Vector2(0.078, -0.125), Vector2(0.082, -0.105),
			Vector2(0.074, -0.085), Vector2(0.05, -0.075), Vector2(0.028, -0.07), Vector2(0.03, -0.055), Vector2(0.036, -0.05),
			Vector2(0.036, -0.035), Vector2(0.03, -0.03), Vector2(0.0, -0.03)], "latao", 14)
		_box(lp, "Rodinha", Vector3(0.008, 0.022, 0.022), Vector3(0.042, -0.045, 0), "latao")
		_cyl(lp, "Eixo", 0.003, 0.003, 0.012, Vector3(0.036, -0.045, 0), "latao", 6).rotation_degrees.z = 90.0
		var vidro := _torneado(lp, "Vidro", [Vector2(0.028, -0.032), Vector2(0.03, -0.02), Vector2(0.046, 0.01), Vector2(0.05, 0.035),
			Vector2(0.044, 0.06), Vector2(0.024, 0.09), Vector2(0.022, 0.16), Vector2(0.024, 0.17)], "vidro_fazenda", 14)
		var q := QuadMesh.new()
		q.size = Vector2(0.035, 0.06)
		q.center_offset = Vector3(0, 0.03, 0)
		q.material = mat_chama
		var chama := MeshInstance3D.new()
		chama.name = "Chama"
		chama.mesh = q
		chama.position = Vector3(0, -0.04, 0)
		chama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(lp, chama)
		var luz := _omni(lp, "Luz", Vector3(0, 0.05, 0), Color(1.0, 0.72, 0.42), 1.4, 6.5)
		luz.shadow_enabled = l[2]
		luz.omni_attenuation = 1.3
		lp.luz = luz
		lp.chama = chama
		lp.vidro = vidro
		lp.vidro_aceso = m["vidro_aceso"]
		lp.vidro_apagado = m["vidro_fazenda"]
		lp.apagavel = false
		lp.som_fosforo = _sfx("fosforo.wav")
		lp.som_vidro = _sfx("lampiao.wav")
		lp.textura_chama = chama_tex
		lampioes.append(lp)

	# As venezianas: o escritório (sudeste) e a sala de estar (nordeste), térreo.
	var janelas := {0: Vector3.RIGHT, 2: Vector3.RIGHT, 15: Vector3.FORWARD, 17: Vector3.FORWARD,
		4: Vector3.RIGHT, 6: Vector3.RIGHT, 21: Vector3.BACK, 23: Vector3.BACK}
	var venezianas: Array[Venezianas] = []
	for n: int in janelas:
		var jn := cena.get_node("Janelas/Janela%d" % n) as Node3D
		var fora: Vector3 = janelas[n]
		var ao_longo := Vector3(-fora.z, 0, fora.x).abs()
		var tam := ao_longo * 1.0 + fora.abs() * 0.4 + Vector3.UP * 1.4
		var v := _area(g, Venezianas.new(), "FecharJanela%d" % n, tam, jn.position - fora * 0.45) as Venezianas
		var folhas: Array[Node3D] = [jn.get_node("VenezianaA"), jn.get_node("VenezianaB")]
		v.folhas = folhas
		v.som = _sfx("veneziana.wav")
		v.som_tranca = _sfx("porta_trinco.wav")
		v.fora = fora
		venezianas.append(v)

	# O rifle de repetição de caça grossa: no armário, em pé; e na mão (NaMao).
	# Em pé no vão do meio do cabide, a coronha na régua de baixo, a alavanca para a
	# sala.
	var no_armario := _group(g, "RifleArmario", Vector3(-1.03, T0 + 0.93, -5.56))
	_rifle(no_armario)
	no_armario.rotation_degrees = Vector3(88, 180, 0)
	var rifle := Node3D.new()
	rifle.name = "Rifle"
	rifle.set_script(load("res://components/rifle.gd"))
	_add(cena, rifle)
	# Na mão, atravessado diante do corpo, o cano para a esquerda e para cima (como
	# se leva um rifle carregado dentro de casa): a culatra, a alavanca e a coronha
	# à vista no canto de baixo.
	rifle.set("posicao", Vector3(0.14, -0.21, -0.44))
	rifle.set("rotacao", Vector3(10, 34, 10))
	var corpo := _group(rifle, "Corpo")
	_rifle(corpo)
	corpo.position = Vector3(0, 0, 0.1)
	for c in corpo.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var luz_r := _omni(rifle, "Luz", Vector3(-0.2, 0.3, 0.3), Color(1.0, 0.82, 0.66), 0.35, 0.9)
	luz_r.light_cull_mask = 1
	# A munição na bancada: as caixas de cartuchos.
	for k in 3:
		_bloco("papelao_escuro", Vector3(0.16, 0.07, 0.1), Vector3(-2.3 + (k - 1) * 0.18, T0 + 0.885 + (k % 2) * 0.0, -3.2), Color(1.1, 0.9, 0.7), false)
	var pegar_rifle := _area(g, Interactable.new(), "PegarRifle", Vector3(1.4, 1.6, 0.45), Vector3(-1.0, T0 + 1.0, -5.15)) as Interactable
	pegar_rifle.prompt = "Pegar o rifle"
	var carregar := _area(g, Interactable.new(), "CarregarRifle", Vector3(0.6, 0.3, 0.4), Vector3(-2.3, T0 + 0.95, -3.2)) as Interactable
	carregar.prompt = "Carregar o rifle"

	# O telefone de parede do vestíbulo (a linha que eles cortam).
	var tel := _group(g, "Telefone", Vector3(2.4, T0 + 1.45, HALL_Z - EI / 2 - 0.06))
	# Playtest 11 (R5): o telefone de parede de manivela, de carvalho — a caixa
	# alta com a tampa almofadada e o friso, as duas campainhas de latão em cima, o
	# braço com o bocal em corneta, a prateleira inclinada embaixo, a manivela do
	# magneto do lado direito, o fone no gancho do lado esquerdo, com o fio.
	_box(tel, "Caixa", Vector3(0.24, 0.42, 0.1), Vector3.ZERO, "madeira_clara")
	_box(tel, "Almofada", Vector3(0.18, 0.2, 0.012), Vector3(0, -0.04, -0.054), "madeira_clara")
	_box(tel, "Cornija", Vector3(0.27, 0.025, 0.115), Vector3(0, 0.22, -0.005), "madeira_escura")
	_box(tel, "Base", Vector3(0.27, 0.025, 0.115), Vector3(0, -0.22, -0.005), "madeira_escura")
	for s: float in [-1.0, 1.0]:
		var camp := _cyl(tel, "Campainha%d" % int(s + 1), 0.026, 0.038, 0.03, Vector3(s * 0.055, 0.145, -0.068), "latao", 12)
		camp.rotation_degrees.x = 90
	_box(tel, "Badalo", Vector3(0.006, 0.04, 0.006), Vector3(0, 0.13, -0.072), "ferro")
	_box(tel, "Braco", Vector3(0.02, 0.02, 0.07), Vector3(0, 0.05, -0.085), "esmalte_preto")
	var bocal := _cyl(tel, "Bocal", 0.034, 0.014, 0.06, Vector3(0, 0.05, -0.14), "esmalte_preto", 10)
	bocal.rotation_degrees.x = 90
	var prateleira := _box(tel, "Prateleira", Vector3(0.24, 0.015, 0.1), Vector3(0, -0.115, -0.09), "madeira_escura")
	prateleira.rotation_degrees.x = -12.0
	# A manivela, num pivô no eixo (playtest 12: ele dá manivela, à toa).
	_cyl(tel, "EixoManivela", 0.008, 0.008, 0.03, Vector3(0.135, -0.02, 0), "ferro", 6).rotation_degrees.z = 90
	var manivela := _group(tel, "Manivela", Vector3(0.152, -0.02, 0))
	_box(manivela, "Braco", Vector3(0.008, 0.07, 0.01), Vector3(0, -0.03, 0), "ferro")
	_cyl(manivela, "Punho", 0.009, 0.009, 0.03, Vector3(0.014, -0.06, 0), "madeira_escura", 6).rotation_degrees.z = 90
	# O gancho (um pivô: sobe quando o fone sai) e o fone pendurado nele (um grupo:
	# vai à orelha). O fio desce do fone até a caixa.
	var gancho := _group(tel, "Gancho", Vector3(-0.122, 0.06, -0.02))
	_box(gancho, "Braco", Vector3(0.04, 0.012, 0.012), Vector3(-0.018, 0, 0), "ferro")
	var fone := _group(tel, "Fone", Vector3(-0.155, 0.05, -0.025))
	_cyl(fone, "Corpo", 0.016, 0.02, 0.12, Vector3(0, -0.055, 0), "esmalte_preto", 8)
	_cyl(fone, "Boca", 0.028, 0.02, 0.02, Vector3(0, -0.125, 0), "esmalte_preto", 10)
	_box(tel, "Fio", Vector3(0.006, 0.2, 0.006), Vector3(-0.13, -0.17, -0.02), "esmalte_preto")
	var telefone := _area(g, Interactable.new(), "TirarFone", Vector3(0.4, 0.5, 0.25), tel.position + Vector3(0, 0, -0.08)) as Interactable
	telefone.prompt = "Tirar o fone do gancho"

	# O fogo da lareira do escritório (sobre a lenha da rotina).
	var boca := Vector3(MEIO_X + CHAMINE_MEIA.x + 0.1, T0 + 0.11, CHAMINE_Z)
	var acender := _area(g, AcenderLareira.new(), "AcenderLareira", Vector3(0.5, 0.8, 1.0), boca + Vector3(0.1, 0.35, 0)) as AcenderLareira
	acender.prompt = "Acender a lareira"
	acender.ajoelhar = boca + Vector3(0.85, -0.11, 0)
	acender.lenha = boca
	acender.chama = chama_tex
	acender.som_riscar = _sfx("fosforo.wav")
	acender.changes = {Preparacao.FLAG_LAREIRA: 1.0}
	acender.additive = false
	acender.condition = _flag(Preparacao.FLAG_LAREIRA, true)
	var aceso := _grupo_se(g, "FogoLareira", _flag(Preparacao.FLAG_LAREIRA))
	var fogo := Fogo.new()
	fogo.name = "Chamas"
	fogo.position = boca + Vector3(0, 0.02, 0)
	_add(aceso, fogo)
	var chamas: Array[Node3D] = []
	for k in 5:
		var q := QuadMesh.new()
		q.size = Vector2(0.16, 0.3)
		q.center_offset = Vector3(0, 0.15, 0)
		q.material = mat_chama
		var mi := MeshInstance3D.new()
		mi.name = "Chama%d" % k
		mi.mesh = q
		mi.position = Vector3(0, 0.02, -0.18 + k * 0.09)
		mi.scale = Vector3.ONE * (0.75 + 0.4 * sin(k * 1.9 + 0.4) ** 2)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(fogo, mi)
		chamas.append(mi)
	fogo.chamas = chamas
	acender.fogo = fogo
	var luz_f := _omni(fogo, "Luz", Vector3(0.35, 0.35, 0), Color(1.0, 0.58, 0.28), 2.2, 6.0)
	luz_f.shadow_enabled = true
	luz_f.omni_attenuation = 1.2
	fogo.luz = luz_f
	fogo.energia = 2.2
	var crepitar := AudioStreamPlayer3D.new()
	crepitar.name = "Crepitar"
	crepitar.stream = _sfx("lareira.wav")
	crepitar.autoplay = true
	crepitar.bus = &"Ambience"
	_add(fogo, crepitar)

	# A porteira do cercado.
	var soltar := _area(g, Interactable.new(), "AbrirPorteira", Vector3(1.4, 1.2, 0.6), Vector3(-0.35, 0.7, -6.85) + CANIL_D) as Interactable
	soltar.prompt = "Abrir a porteira (soltar os cães)"
	# Entrar no cercado e sair dele (playtest 12, depois: a porteira fechada barrava
	# o corpo e não se entrava mais), uma área de cada lado.
	var porteira := cena.get_node("Porteira") as Node3D
	for de_dentro: bool in [false, true]:
		var passar := _area(g, PassarPorteira.new(), "SairDoCercado" if de_dentro else "EntrarNoCercado", Vector3(1.4, 1.2, 0.3),
			porteira.position + Vector3(0.7, 0.7, -0.2 if de_dentro else 0.2)) as PassarPorteira
		passar.de_dentro = de_dentro
		passar.porteira = porteira
		passar.trinco = porteira.get_node("Trinco")
		passar.matilha = caes
		passar.soltar = soltar
		passar.som_trinco = _sfx("porta_trinco.wav")
		passar.som_porteira = _sfx("porteira.wav")

	# A lua cheia (longe, a leste, atrás dos morros) e as nuvens que a engolem: sem
	# névoa (estão no céu), sem luz.
	var lua := MeshInstance3D.new()
	lua.name = "Lua"
	var esfera := SphereMesh.new()
	esfera.radius = 22.0
	esfera.height = 44.0
	esfera.radial_segments = 16
	esfera.rings = 8
	lua.mesh = esfera
	var mat_lua := StandardMaterial3D.new()
	mat_lua.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_lua.albedo_color = Color(0.95, 0.92, 0.78)
	mat_lua.disable_fog = true
	lua.material_override = mat_lua
	lua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(cena, lua)
	# As nuvens: um banco de bolhas achatadas, escuras como o céu da noite, que
	# corre do norte e passa diante da lua (sem arestas: eram retângulos).
	var nuvens := _group(cena, "Nuvens")
	var mat_n := StandardMaterial3D.new()
	mat_n.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_n.albedo_color = Color(0.05, 0.05, 0.07)
	mat_n.disable_fog = true
	var rng_n := RandomNumberGenerator.new()
	rng_n.seed = 77
	for k in 14:
		var mi := MeshInstance3D.new()
		mi.name = "Nuvem%d" % k
		var bolha := SphereMesh.new()
		var r := rng_n.randf_range(45.0, 85.0)
		bolha.radius = r
		bolha.height = r * 2.0
		bolha.radial_segments = 12
		bolha.rings = 6
		mi.mesh = bolha
		mi.material_override = mat_n
		mi.position = Vector3(rng_n.randf_range(-30.0, 30.0), rng_n.randf_range(-50.0, 50.0), k * 55.0 - 380.0)
		mi.scale = Vector3(0.6, rng_n.randf_range(0.3, 0.5), 1.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(nuvens, mi)

	var p := Preparacao.new()
	p.name = "Preparacao"
	_add(cena, p)
	p.matilha = caes
	p.lampioes = lampioes
	p.venezianas = venezianas
	p.rifle = rifle as Rifle
	p.rifle_armario = no_armario
	p.pegar_rifle = pegar_rifle
	p.carregar_rifle = carregar
	p.acender_lareira = acender
	p.soltar_caes = soltar
	p.porteira = cena.get_node("Porteira")
	p.trinco = cena.get_node("Porteira/Trinco")
	p.telefone = telefone
	p.fone = tel.get_node("Fone")
	p.gancho = tel.get_node("Gancho")
	p.manivela = tel.get_node("Manivela")
	p.cartuchos_caixa = Vector3(-2.3, T0 + 0.93, -3.2)
	p.som_manivela = _sfx("telefone_manivela.wav")
	p.som_trinco = _sfx("porta_trinco.wav")
	# Diante da boca, na pedra da lareira (ele para a ~0,35 m do alvo: o alvo fica
	# além, ao sul, e ele deita no meio da boca, entre a lareira e a mesa).
	p.diante_do_fogo = Vector3(2.4, T0, CHAMINE_Z + 0.25)
	# Por dentro da porta do escritório (do vestíbulo): por onde Conan entra; e a
	# passagem ao norte da mesa grande, por onde ele a contorna até o fogo.
	caes.porta_do_fogo = Vector3(5.1, T0, HALL_Z + 0.6)
	caes.passagem_do_fogo = Vector3(2.45, T0, 2.6)
	caes.porta_do_fogo_fora = Vector3(5.1, T0, HALL_Z - 0.75)
	caes.comodo_do_fogo = AABB(Vector3(MEIO_X + 0.06, T0 - 0.3, HALL_Z + 0.06), Vector3(CASA_X.y - E - MEIO_X - 0.06, 1.2, CASA_Z.y - E - HALL_Z - 0.06))
	p.lua = lua
	p.nuvens = nuvens
	# A leste, longe: nasce por trás da crista dos morros do outro lado do vale (a
	# ~33° acima do horizonte da fazenda) e sobe; o banco de nuvens vem do norte.
	p.lua_de = Vector3(900, 560, -100)
	p.lua_ate = Vector3(900, 860, -100)
	p.nuvens_de = Vector3(880, 860, -900)
	p.nuvens_ate = Vector3(880, 860, 120)
	p.som_rifle = _sfx("rifle_pegar.wav")
	p.som_cartucho = _sfx("cartucho.wav")
	p.som_alavanca = _sfx("alavanca_rifle.wav")
	p.som_porteira = _sfx("porteira.wav")
	p.som_gancho = _sfx("telefone_gancho.wav")
	var lembretes: Dictionary[StringName, NarrationLine] = {
		&"lampioes": load("res://narrative/narration/akeley_lampioes.tres"),
		&"venezianas": load("res://narrative/narration/akeley_venezianas.tres"),
		&"rifle": load("res://narrative/narration/akeley_rifle_lembrete.tres"),
		&"lareira": load("res://narrative/narration/akeley_lareira.tres"),
		&"caes": load("res://narrative/narration/akeley_caes_soltar.tres"),
	}
	p.lembretes = lembretes
	p.linha_lampiao = load("res://narrative/narration/akeley_luz.tres")
	p.linha_rifle = load("res://narrative/narration/akeley_rifle.tres")
	p.linha_telefone = load("res://narrative/narration/akeley_telefone.tres")
	p.linha_lua = load("res://narrative/narration/akeley_lua.tres")


## A noite do telhado (F7; "A tratativa", 3 e 4): a poltrona do escritório, o
## relógio do consolo, a poeira do forro, as vidraças do escritório (uma estoura:
## os cacos), as lascas da estante, o clarão na mata, as seteiras (o escritório e a
## sala de estar) e os sons do telhado.
func _noite_telhado() -> void:
	var g := _group(cena, "NoiteTelhadoPecas")
	var caes := cena.get_node("Caes") as Matilha
	var prep := cena.get_node("Preparacao") as Preparacao
	var pecas := cena.get_node("PreparacaoPecas")
	# De onde vêm as balas: o sudeste, do outro lado da estrada; os cães correm
	# por ali latindo para lá.
	caes.frente = AABB(Vector3(6.5, 0, 1.0), Vector3(12.0, 1, 14.0))
	caes.frente_alvo = Vector3(34.0, 1.0, 30.0)

	# A poltrona de orelhas junto ao fogo (gerar_fazenda._moveis).
	var assento := Vector3(1.9, T0, 5.05)
	var boca := Vector3(MEIO_X + CHAMINE_MEIA.x + 0.1, T0 + 0.75, CHAMINE_Z)
	# Maior que a poltrona (a colisão dela tapava a mira).
	var sentar := _area(g, Interactable.new(), "Sentar", Vector3(1.3, 1.4, 1.3), assento + Vector3(0, 0.7, 0)) as Interactable
	sentar.prompt = "Sentar e esperar"

	# O relógio do consolo da lareira, de frente para a sala: a caixa de madeira
	# de ombros arredondados, o mostrador, os ponteiros, os pés.
	var rel := _group(g, "RelogioConsolo", Vector3(MEIO_X + CHAMINE_MEIA.x + 0.1, T0 + 1.28, CHAMINE_Z - 0.35))
	rel.rotation_degrees.y = -90.0
	_box(rel, "Caixa", Vector3(0.24, 0.2, 0.1), Vector3(0, 0.11, 0), "madeira_escura")
	var topo := _cyl(rel, "Ombros", 0.12, 0.12, 0.1, Vector3(0, 0.21, 0), "madeira_escura", 12)
	topo.rotation_degrees.x = 90.0
	topo.scale = Vector3(1.0, 1.0, 0.45)
	var mostrador := _cyl(rel, "Mostrador", 0.07, 0.07, 0.01, Vector3(0, 0.17, -0.051), "papel", 14)
	mostrador.rotation_degrees.x = 90.0
	_cyl(rel, "Aro", 0.078, 0.078, 0.008, Vector3(0, 0.17, -0.049), "latao", 14).rotation_degrees.x = 90.0
	var horas := _box(rel, "Horas", Vector3(0.006, 0.04, 0.002), Vector3(0.008, 0.18, -0.058), "ferro")
	horas.rotation_degrees.z = -20.0
	var minutos := _box(rel, "Minutos", Vector3(0.004, 0.06, 0.002), Vector3(-0.004, 0.196, -0.059), "ferro")
	minutos.rotation_degrees.z = 8.0
	for sx: float in [-1.0, 1.0]:
		_box(rel, "Pe%d" % int(sx + 1), Vector3(0.04, 0.015, 0.08), Vector3(sx * 0.1, 0.008, 0), "latao")
	var tique := AudioStreamPlayer3D.new()
	tique.name = "Tique"
	tique.stream = _sfx("relogio.wav")
	tique.bus = &"SFX"
	tique.volume_db = -8.0
	tique.unit_size = 2.0
	tique.max_distance = 14.0
	tique.position = Vector3(0, 0.15, 0)
	_add(rel, tique)

	# Os sons do telhado: o que anda por cima (o baque, as unhas, a luta) e o
	# zumbido — o mesmo do disco.
	var alto := Vector3(3.5, 8.8, 3.8)
	var som_telhado := AudioStreamPlayer3D.new()
	som_telhado.name = "SomTelhado"
	som_telhado.bus = &"SFX"
	som_telhado.unit_size = 9.0
	som_telhado.max_distance = 90.0
	som_telhado.position = alto
	_add(g, som_telhado)
	var zumbido := AudioStreamPlayer3D.new()
	zumbido.name = "Zumbido"
	zumbido.stream = _sfx("zumbido.wav")
	zumbido.bus = &"SFX"
	zumbido.unit_size = 10.0
	zumbido.max_distance = 120.0
	zumbido.position = alto
	_add(g, zumbido)

	# A poeira do forro do escritório: o pó fino que desce devagar e as lascas de
	# caiação, que caem de uma vez.
	var poeira: Array[CPUParticles3D] = []
	for fina: bool in [true, false]:
		var e := CPUParticles3D.new()
		e.name = "Poeira" if fina else "Calica"
		e.position = Vector3(3.45, T0 + PE0 - 0.04, 3.7)
		e.emitting = false
		e.one_shot = true
		e.explosiveness = 0.55 if fina else 0.8
		e.amount = 160 if fina else 18
		e.lifetime = 4.0 if fina else 1.2
		e.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		e.emission_box_extents = Vector3(2.0, 0.02, 1.9)
		e.direction = Vector3.DOWN
		e.spread = 15.0
		e.initial_velocity_min = 0.05
		e.initial_velocity_max = 0.3 if fina else 0.6
		e.gravity = Vector3(0, -0.45, 0) if fina else Vector3(0, -9.8, 0)
		e.damping_min = 0.2 if fina else 0.0
		e.damping_max = 0.6 if fina else 0.0
		e.scale_amount_min = 0.5
		e.scale_amount_max = 1.4
		var q := QuadMesh.new()
		q.size = Vector2(0.018, 0.018) if fina else Vector2(0.03, 0.022)
		var mt := StandardMaterial3D.new()
		mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mt.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mt.albedo_color = Color(0.5, 0.47, 0.42, 0.7) if fina else Color(0.62, 0.6, 0.55, 1.0)
		q.material = mt
		e.mesh = q
		_add(g, e)
		poeira.append(e)

	# As vidraças do escritório (as janelas eram sem vidro): um vidro que se vê
	# através, entre as duas folhas da guilhotina, em cada uma das quatro.
	var mat_vidro := StandardMaterial3D.new()
	mat_vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vidro.albedo_color = Color(0.62, 0.68, 0.72, 0.1)
	mat_vidro.roughness = 0.06
	mat_vidro.metallic_specular = 0.9
	mat_vidro.cull_mode = BaseMaterial3D.CULL_DISABLED
	var vidracas := {}
	for n: int in [4, 6, 21, 23]:
		var jn := cena.get_node("Janelas/Janela%d" % n) as Node3D
		var fora := Vector3.RIGHT if n < 9 else Vector3.BACK
		var ao_longo := Vector3(-fora.z, 0, fora.x).abs()
		var v := MeshInstance3D.new()
		v.name = "Vidraca%d" % n
		var bm := BoxMesh.new()
		bm.size = ao_longo * 0.9 + Vector3.UP * 1.5 + fora.abs() * 0.006
		v.mesh = bm
		v.material_override = mat_vidro
		v.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		v.position = jn.position - fora * (E / 2)
		_add(g, v)
		vidracas[n] = v
	# Os cacos da que estoura (a 23, ao sul, junto à poltrona): triângulos de
	# vidro achatados (deitam no assoalho onde caem).
	var mat_caco := StandardMaterial3D.new()
	mat_caco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_caco.albedo_color = Color(0.78, 0.84, 0.86, 0.5)
	mat_caco.roughness = 0.05
	mat_caco.metallic_specular = 1.0
	mat_caco.cull_mode = BaseMaterial3D.CULL_DISABLED
	var v23: Node3D = vidracas[23]
	var cacos := _group(g, "Estilhacos")
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for k in 18:
		var mi := MeshInstance3D.new()
		mi.name = "Caco%d" % k
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_normal(Vector3.UP)
		var r := rng.randf_range(0.025, 0.07) * (1.6 if k == 0 else 1.0)
		for j in 3:
			var a := TAU * j / 3.0 + rng.randf_range(-0.6, 0.6)
			st.add_vertex(Vector3(cos(a), 0, sin(a)) * r * rng.randf_range(0.6, 1.3))
		mi.mesh = st.commit()
		mi.material_override = mat_caco
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = v23.position + Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.7, 0.7), 0)
		mi.set_meta(&"chao", T0 + 0.004 + rng.randf() * 0.004)
		_add(cacos, mi)

	# As lascas da estante, onde a terceira bala bate.
	var estante := Vector3(2.42, T0 + 1.5, HALL_Z + 0.4)
	var lascas := CPUParticles3D.new()
	lascas.name = "Lascas"
	lascas.position = estante
	lascas.emitting = false
	lascas.one_shot = true
	lascas.explosiveness = 0.95
	lascas.amount = 26
	lascas.lifetime = 1.4
	lascas.direction = Vector3(0, 0.3, 1)
	lascas.spread = 55.0
	lascas.initial_velocity_min = 1.2
	lascas.initial_velocity_max = 3.2
	lascas.gravity = Vector3(0, -9.8, 0)
	lascas.scale_amount_min = 0.5
	lascas.scale_amount_max = 1.5
	var qb := BoxMesh.new()
	qb.size = Vector3(0.02, 0.006, 0.05)
	var ml := StandardMaterial3D.new()
	ml.albedo_color = Color(0.55, 0.38, 0.22)
	qb.material = ml
	lascas.mesh = qb
	_add(g, lascas)

	# O clarão longe, na mata do sudeste: uma luz e um brilho (sem névoa).
	var clarao := _group(g, "Clarao", Vector3(22.0, 1.8, 30.0))
	var lc := _omni(clarao, "Luz", Vector3.ZERO, Color(1.0, 0.78, 0.45), 9.0, 14.0)
	lc.omni_attenuation = 1.0
	var bq := QuadMesh.new()
	bq.size = Vector2(1.6, 1.6)
	var mb := StandardMaterial3D.new()
	mb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mb.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mb.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mb.disable_fog = true
	mb.albedo_color = Color(1.0, 0.8, 0.5)
	mb.albedo_texture = LuzGuia._textura()
	bq.material = mb
	var brilho := MeshInstance3D.new()
	brilho.name = "Brilho"
	brilho.mesh = bq
	brilho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(clarao, brilho)

	# As seteiras: o escritório (a leste e ao sul) e a sala de estar (a leste e
	# ao norte) — "varri toda a volta da casa". O lampião do cômodo apagado antes.
	var lamp_esc := pecas.get_node("LampiaoEscritorio") as Lampiao
	var lamp_sala := pecas.get_node("LampiaoSalaEstar") as Lampiao
	var seteiras: Array[Venezianas] = []
	var atirar: Array[Interactable] = []
	var lampiao_de: Array[Lampiao] = []
	for par: Array in [[6, Vector3.RIGHT, lamp_esc], [21, Vector3.BACK, lamp_esc], [2, Vector3.RIGHT, lamp_sala], [15, Vector3.FORWARD, lamp_sala]]:
		var v := pecas.get_node("FecharJanela%d" % par[0]) as Venezianas
		var fora: Vector3 = par[1]
		var ao_longo := Vector3(-fora.z, 0, fora.x).abs()
		var a := _area(g, Interactable.new(), "Atirar%d" % par[0], ao_longo * 1.0 + fora.abs() * 0.4 + Vector3.UP * 1.4, v.position) as Interactable
		a.prompt = "Atirar pela janela"
		a.set_meta(&"fora", fora)
		seteiras.append(v)
		atirar.append(a)
		lampiao_de.append(par[2])

	var n := NoiteTelhado.new()
	n.name = "NoiteTelhado"
	_add(cena, n)
	n.matilha = caes
	n.preparacao = prep
	n.sentar = sentar
	n.assento = assento
	n.diante = boca
	n.relogio = tique
	n.som_telhado = som_telhado
	n.som_zumbido = zumbido
	# Quem sobe: da beira do puxado baixo (a oeste) ao telhado da casa, por cima da
	# cumeeira, até o alto do escritório.
	n.caminho_telhado = PackedVector3Array([Vector3(-6.5, PUXADO_ALTO + 0.4, 3.6), Vector3(-2.6, BEIRAL + 0.6, 3.6),
		Vector3(CUMEEIRA.x, CUMEEIRA.y + 0.1, 3.8), alto])
	n.poeira = poeira
	n.janela_bala = pecas.get_node("FecharJanela23") as Venezianas
	n.vidraca = v23
	n.estilhacos = cacos
	n.para_dentro = Vector3.FORWARD
	n.bate_tabuado = Vector3(3.5, T0 + 1.2, CASA_Z.y + 0.15)
	n.bate_estante = estante
	n.lascas = lascas
	n.clarao = clarao
	n.mata_frente = Vector3(24.0, 2.0, 32.0)
	n.seteiras = seteiras
	n.atirar = atirar
	n.lampiao_de = lampiao_de
	var apagar: Array[Lampiao] = [lamp_esc, lamp_sala]
	n.apagar = apagar
	n.som_noite = _sfx("noite.wav")
	n.som_sem_grilos = _sfx("vento.wav")
	n.som_baque = _sfx("baque_telhado.wav")
	n.som_unhas = _sfx("unhas_telhado.wav")
	n.som_luta = _sfx("luta_telhado.wav")
	n.som_poeira = _sfx("poeira.wav")
	n.som_tiro = _sfx("tiro_rifle.wav")
	n.som_tiro_longe = _sfx("tiro_longe.wav")
	n.som_vidro = _sfx("vidro_estoura.wav")
	n.som_lascas = _sfx("estilhaco_madeira.wav")
	n.som_alavanca = _sfx("alavanca_rifle.wav")
	n.som_cartucho = _sfx("cartucho_chao.wav")
	var frases: Dictionary[StringName, NarrationLine] = {}
	for id: String in ["nuvens", "pousou", "correram", "subiu", "luta", "cheiro", "balas", "apaguei", "seteiras", "encerrar"]:
		frases[StringName(id)] = load("res://narrative/narration/akeley_%s.tres" % id)
	n.frases = frases
	var lembretes: Dictionary[StringName, NarrationLine] = {}
	for id: String in ["sentar", "apagar", "atirar"]:
		lembretes[StringName(id)] = load("res://narrative/narration/akeley_%s.tres" % id)
	n.lembretes = lembretes

## O rifle de repetição de alavanca (provisório em primitivas, ao longo de -Z): a
## coronha, a caixa da culatra, a alavanca em argola, o depósito tubular e o cano.
func _rifle(pai: Node3D) -> void:
	# Playtest 11 (R5): o rifle de alavanca de caça grossa, peça a peça (ao longo de
	# -Z; a culatra na origem): a coronha com o punho estreito, o salto e a soleira
	# de ferro; a caixa da culatra com o cão e o gatilho; a alavanca em argola; a
	# telha de madeira; o cano e o depósito tubular com as braçadeiras; as miras.
	var m := "madeira_escura"
	var f := "ferro"
	_box(pai, "Punho", Vector3(0.034, 0.05, 0.11), Vector3(0, -0.02, 0.1), m)
	var coronha := _box(pai, "Coronha", Vector3(0.04, 0.085, 0.27), Vector3(0, -0.045, 0.28), m)
	coronha.rotation_degrees.x = -6.0
	_box(pai, "Pente", Vector3(0.036, 0.03, 0.22), Vector3(0, -0.012, 0.28), m)
	_box(pai, "Soleira", Vector3(0.042, 0.12, 0.012), Vector3(0, -0.05, 0.42), f)
	_box(pai, "Culatra", Vector3(0.042, 0.075, 0.16), Vector3(0, -0.005, -0.03), f)
	_box(pai, "Janela", Vector3(0.044, 0.02, 0.06), Vector3(0, 0.005, -0.04), "latao")
	# O cão, num pivô na base (playtest 12: engatilha quando a alavanca volta).
	var cao := _group(pai, "Cao", Vector3(0, 0.03, 0.05))
	cao.rotation_degrees.x = 25.0
	_box(cao, "Peca", Vector3(0.012, 0.03, 0.02), Vector3(0, 0.012, -0.004), f)
	_box(pai, "Gatilho", Vector3(0.006, 0.025, 0.006), Vector3(0, -0.058, 0.02), f)
	# A alavanca: a argola sob a culatra e o punho, num pivô na frente (playtest 12:
	# ela abre e fecha de verdade, ao carregar e entre os tiros).
	var alav := _group(pai, "Alavanca", Vector3(0, -0.045, -0.06))
	_box(alav, "Frente", Vector3(0.01, 0.05, 0.01), Vector3(0, -0.02, 0.0), f)
	_box(alav, "Baixo", Vector3(0.01, 0.01, 0.13), Vector3(0, -0.045, 0.06), f)
	_box(alav, "Tras", Vector3(0.01, 0.045, 0.01), Vector3(0, -0.023, 0.125), f)
	# A portinhola de carregar, no lado direito da culatra (por onde os cartuchos
	# entram no depósito), e a boca do cano (o clarão do tiro).
	_box(pai, "Portinhola", Vector3(0.004, 0.018, 0.034), Vector3(0.0225, -0.024, 0.0), "latao")
	var boca := Marker3D.new()
	boca.name = "Boca"
	boca.position = Vector3(0, 0.02, -0.725)
	_add(pai, boca)
	_box(pai, "Telha", Vector3(0.036, 0.034, 0.3), Vector3(0, -0.006, -0.26), m)
	var cano := _cyl(pai, "Cano", 0.011, 0.012, 0.62, Vector3(0, 0.02, -0.41), f, 8)
	cano.rotation_degrees.x = 90
	var deposito := _cyl(pai, "Deposito", 0.0095, 0.0095, 0.56, Vector3(0, -0.006, -0.38), f, 8)
	deposito.rotation_degrees.x = 90
	for z: float in [-0.42, -0.64]:
		_box(pai, "Bracadeira%d" % int(-z * 100), Vector3(0.03, 0.05, 0.012), Vector3(0, 0.007, z), f)
	_box(pai, "MiraFrente", Vector3(0.004, 0.014, 0.01), Vector3(0, 0.037, -0.705), f)
	_box(pai, "MiraTras", Vector3(0.02, 0.01, 0.012), Vector3(0, 0.035, -0.18), f)


## Os doze cães (F4, o começo: a presença) no cercado diante das baias, esperando
## a ração ao entardecer: a maioria virada para o leste, de onde Akeley vem com o
## balde; Rambo, que não come, olhando a mata (GDD §5.1a). Cada um um pouco
## diferente (a pelagem, o porte). O comportamento vem depois (docs/PLANO_FAZENDA.md).
func _caes(x: Vector2, z: Vector2) -> void:
	var g := Matilha.new()
	g.name = "Caes"
	_add(cena, g)
	g.cercado = AABB(Vector3(x.x + 0.4, 0, z.x), Vector3(x.y - x.x - 0.8, 1.0, z.y - z.x))
	# O quintal onde andam soltos: dos fundos do canil à frente da casa.
	g.quintal = AABB(Vector3(-14.0, 0, -23.0), Vector3(36.0, 1, 37.0))
	var latidos: Array[AudioStream] = []
	for i in 6:
		latidos.append(_sfx("cao_latido_%d.wav" % (i + 1)))
	g.latidos = latidos
	g.rosnado = _sfx("cao_rosnado.wav")
	g.arreganho = _sfx("cao_arreganho.wav")
	g.choramingo = _sfx("cao_choramingo.wav")
	g.ganido = _sfx("cao_ganido.wav")
	g.latidos_longe = _sfx("cao_latidos_longe.wav")
	var papeis := {"Brutus": CaoIA.Papel.SEGUIR, "Conan": CaoIA.Papel.FOGO, "Hércules": CaoIA.Papel.MATA, "Rambo": CaoIA.Papel.JANELA}
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.32, 0.55, 0.85)
	var poses := {
		"Brutus": [Cao.Pose.PARADO, 0.0], "Conan": [Cao.Pose.PARADO, 10.0], "Hércules": [Cao.Pose.SENTADO, -15.0],
		"Rambo": [Cao.Pose.PARADO, 180.0], "Yautja": [Cao.Pose.PARADO, 150.0], "Dutch": [Cao.Pose.SENTADO, 20.0],
		"Kull": [Cao.Pose.DEITADO, -40.0], "Kurgan": [Cao.Pose.PARADO, -25.0], "Ripley": [Cao.Pose.SENTADO, 5.0],
		"Snake": [Cao.Pose.DEITADO, 60.0], "Riddick": [Cao.Pose.PARADO, 35.0], "Sansão": [Cao.Pose.SENTADO, -5.0],
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = 1928
	for i in CAES.size():
		var nome: String = CAES[i]
		var corpo := CaoIA.new()
		corpo.name = nome
		corpo.papel = papeis.get(nome, CaoIA.Papel.MATILHA)
		var c := Cao.new()
		c.name = "Visual"
		var p: Array = poses[nome]
		c.pose = p[0]
		c.pelagem = rng.randf_range(-0.7, 0.7)
		c.porte = rng.randf_range(0.92, 1.08)
		c.olhar = rng.randf_range(-15.0, 15.0)
		# Espalhados pelo cercado, os da frente mais perto da tela (Brutus também:
		# só segue Akeley depois de solto).
		var px := lerpf(x.x + 0.8, x.y - 0.6, (i + rng.randf_range(-0.3, 0.3)) / (CAES.size() - 1))
		var pz := lerpf(z.x, z.y, rng.randf())
		_add(g, corpo)
		corpo.position = Vector3(px, 0.0, pz)
		# 0° = de frente para o leste (+X); a frente do cão é o -Z.
		corpo.rotation_degrees.y = -90.0 + p[1] + rng.randf_range(-8.0, 8.0)
		_add(corpo, c)
		var col := CollisionShape3D.new()
		col.name = "Forma"
		col.shape = forma
		# A base da caixa rente à origem (o chão sob as patas).
		col.position = Vector3(0, forma.size.y * 0.5 + 0.005, 0)
		_add(corpo, col)


func _tela(de: Vector2, ate: Vector2) -> void:
	var compr := de.distance_to(ate)
	var dir := (ate - de) / compr
	var giro := -rad_to_deg(atan2(dir.y, dir.x))
	var n := maxi(1, ceili(compr / 2.2))
	for i in n + 1:
		var p := de + dir * compr * i / n
		_bloco("madeira_escura", Vector3(0.1, 1.5, 0.1), Vector3(p.x, 0.75, p.y), Color.WHITE * _rng.randf_range(0.85, 1.1), false,
			Vector3(_rng.randf_range(-2, 2), giro, _rng.randf_range(-2, 2)))
	var meio := (de + ate) / 2
	# Playtest 11 (R4): a tela de verdade — a malha de losangos de arame (dos dois
	# lados), presa entre a tábua de baixo (para os cães não cavarem) e a régua de
	# cima.
	_bloco("madeira_escura", Vector3(compr, 0.06, 0.06), Vector3(meio.x, 1.47, meio.y), Color(0.9, 0.9, 0.9), false, Vector3(0, giro, 0))
	_bloco("madeira_escura", Vector3(compr, 0.18, 0.035), Vector3(meio.x, 0.09, meio.y), Color(0.8, 0.8, 0.8), false, Vector3(0, giro, 0))
	var tela := _obra("tela_arame")
	var lado := Vector3(-dir.y, 0, dir.x)
	var a := Vector3(de.x, 0.17, de.y)
	var b := Vector3(ate.x, 0.17, ate.y)
	var alto := Vector3(0, 1.28, 0)
	for s: float in [-1.0, 1.0]:
		tela.quad(a, b, b + alto, a + alto, lado * s, Color.WHITE)
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
	_bloco("vidro_fazenda", Vector3(0.03, 0.42, 1.25), f + Vector3(0.45, 1.33, 0), Color.WHITE, false)
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
	# Playtest 11 (R4): as dezoito pás de chapa em leque (radiais, não um aro), entre
	# o aro de dentro e o de fora, com os raios de ferro até o cubo.
	var roda := cubo + Vector3(0.34, 0, 0)
	for i in 18:
		var a := TAU * i / 18
		var radial := Vector3(0, sin(a), cos(a))
		_bloco("ferro_galvanizado", Vector3(0.015, 1.0, 0.26), roda + radial * 0.88, Color.WHITE * (0.9 + 0.12 * sin(a * 3.0)), false,
			Vector3(90.0 - rad_to_deg(a), 0, 0))
	for r: float in [0.38, 1.36]:
		for i in 18:
			var a := TAU * (i + 0.5) / 18
			var radial := Vector3(0, sin(a), cos(a))
			_bloco("ferro", Vector3(0.03, 2.0 * r * sin(PI / 18) + 0.02, 0.035), roda + radial * r, Color(0.7, 0.7, 0.7), false, Vector3(-rad_to_deg(a), 0, 0))
	for i in 6:
		var a := TAU * i / 6
		_bloco("ferro", Vector3(0.025, 1.0, 0.025), roda + Vector3(0.02, sin(a), cos(a)) * 0.5, Color(0.7, 0.7, 0.7), false, Vector3(90.0 - rad_to_deg(a), 0, 0))
	_cilindro("ferro", roda + Vector3(0.05, 0, 0), 0.12, 0.12, 8)
	# O leme: a haste e a chapa de cauda com as nervuras.
	_bloco("ferro_galvanizado", Vector3(2.4, 0.9, 0.03), cubo + Vector3(-1.6, 0.1, 0), Color.WHITE, false)
	for k in 3:
		_bloco("ferro", Vector3(2.3, 0.025, 0.04), cubo + Vector3(-1.6, -0.25 + k * 0.35, 0), Color(0.7, 0.7, 0.7), false)
	_bloco("madeira_clara", Vector3(2.0, 0.08, 0.08), cubo + Vector3(-0.9, 0, 0), Color.WHITE, false)
	# A plataforma de tábuas sob a cabeça, a escada por uma das faces até ela, a
	# vara da bomba descendo pelo meio da torre e a caixa d'água de aduelas ao pé.
	_bloco("madeira_clara", Vector3(1.7, 0.06, 1.7), base + Vector3(0, alto - 0.55, 0), Color(0.75, 0.75, 0.75), false)
	for s: float in [-1.0, 1.0]:
		_viga("madeira_clara", base + Vector3(s * 0.2, 0, abre - 0.05), base + Vector3(s * 0.2, alto - 0.5, 0.4), 0.05, Color(0.8, 0.8, 0.8))
	var k2 := 0.4
	while k2 < alto - 0.6:
		var t := k2 / (alto - 0.5)
		_bloco("madeira_clara", Vector3(0.44, 0.035, 0.035), base + Vector3(0, k2, lerpf(abre - 0.05, 0.4, t) + 0.02), Color(0.8, 0.8, 0.8), false)
		k2 += 0.36
	_bloco("ferro", Vector3(0.03, alto - 0.4, 0.03), base + Vector3(0, (alto - 0.4) / 2 + 0.3, 0), Color(0.6, 0.6, 0.6), false)
	_cilindro("ferro", base + Vector3(0, 0.35, 0), 0.08, 0.7, 8)
	var caixa := base + Vector3(2.7, 0, 1.2)
	_cilindro("madeira_clara", caixa + Vector3(0, 0.75, 0), 0.95, 1.5, 14, Color(0.85, 0.78, 0.7))
	_cilindro("agua", caixa + Vector3(0, 1.4, 0), 0.9, 0.02, 14)
	for y: float in [0.25, 0.75, 1.3]:
		_cilindro("ferro", caixa + Vector3(0, y, 0), 0.965, 0.05, 14, Color(0.6, 0.6, 0.6))
	_col.append([Vector3(1.9, 1.5, 1.9), caixa + Vector3(0, 0.75, 0)])
	_viga("ferro", base + Vector3(0.1, 0.5, 0.1), caixa + Vector3(-0.9, 1.35, -0.3), 0.04, Color(0.55, 0.55, 0.55))


# --- As árvores -----------------------------------------------------------------------

## Os olmos grandes do gramado, os bordos ao longo da estrada, as macieiras ao
## norte; as bétulas e as árvores mortas do pântano; e a mata fechada da
## encosta, até a crista recortada da Dark Mountain.
func _arvores() -> void:
	var mm := _obra("bosque")
	var troncos: Array[Vector3] = []
	# Os olmos do gramado (altos, de copa em vaso) e os bordos ao longo da
	# estrada, com as primeiras folhas de setembro amarelando.
	for p0: Vector3 in [Vector3(12.0, 0, 9.0), Vector3(22.0, 0, -9.0), Vector3(-6.0, 0, 11.0)]:
		var p := _pe(p0.x, p0.z, 0.4)
		_arvore(mm, p, _rng.randf_range(13.0, 15.0), 4.6, Color(0.2, 0.3, 0.14), true)
		troncos.append(p)
	var z := -56.0
	while z < 38.0:
		if absf(z) > 2.5 and absf(z + 15.0 - FORD_D.z) > 3.0:
			var p := Vector3(ESTRADA_X.x - 1.6 + _rng.randf_range(-0.4, 0.4), 0, z)
			p = _pe(p.x, p.z, 0.3)
			var folha := Color(0.24, 0.32, 0.14) if _rng.randf() < 0.7 else Color(0.5, 0.4, 0.14)
			_arvore(mm, p, _rng.randf_range(8.0, 10.5), 3.0, folha)
			troncos.append(p)
		z += _rng.randf_range(9.0, 14.0)
	for i in 8:
		var p := Vector3(16.0 + (i % 4) * 4.0 + _rng.randf_range(-0.6, 0.6), 0, -32.0 - (i / 4) * 5.0)
		p = _pe(p.x, p.z, 0.2)
		_macieira(mm, p)
		troncos.append(p)
	# Na beira do pântano, uma fileira de cicutas de perto (playtest 11).
	for i in 12:
		var p := Vector3(_rng.randf_range(-36.0, -31.0), 0, -44.0 + i * 7.0 + _rng.randf_range(-2.0, 2.0))
		if _ocupado(p.x, p.z):
			p.x -= 3.5
		p = _pe(p.x, p.z, 0.3)
		_abeto_perto(mm, p, _rng.randf_range(9.0, 14.0))
		troncos.append(p)
	# O pântano: bétulas ralas e troncos mortos, touceiras de juncos.
	for i in 45:
		var p := Vector3(_rng.randf_range(-62.0, -34.0), 0, _rng.randf_range(-58.0, 38.0))
		p = _pe(p.x, p.z, 0.2)
		if _rng.randf() < 0.6:
			_betula(mm, p, _rng.randf_range(6.0, 9.0), true)
		else:
			_morta(mm, p)
		troncos.append(p)
	for i in 140:
		var p := Vector3(_rng.randf_range(-63.0, -30.0), 0, _rng.randf_range(-58.0, 38.0))
		p = _pe(p.x, p.z, 0.25)
		var taboa := _rng.randf() < 0.4
		for k in 6:
			var q := p + Vector3(_rng.randf_range(-0.25, 0.25), 0, _rng.randf_range(-0.25, 0.25))
			var h := _rng.randf_range(0.5, 1.3)
			mm.piramide(_rng.randf_range(0.025, 0.045), h, q, 3, Color(0.42, 0.4, 0.2) * _rng.randf_range(0.8, 1.15))
			# As taboas: a espiga parda no alto de uma haste (R4).
			if taboa and k % 2 == 0:
				mm.caixa(Vector3(0.012, h * 0.95, 0.012), q + Vector3(0.05, h * 0.47, 0), Color(0.4, 0.38, 0.2))
				mm.caixa(Vector3(0.045, 0.17, 0.045), q + Vector3(0.05, h * 0.95, 0), Color(0.3, 0.19, 0.1))
	# A mata da encosta: cicutas e bétulas, densa, até a crista (o fim do terreno).
	# A de longe (além de PERTO_X/PERTO_Z) mais simples e sem sombra.
	var mata_longe := _obra("bosque_longe")
	for i in 1100:
		var p := Vector3(_rng.randf_range(-258.0, -66.0), 0, _rng.randf_range(-228.0, 228.0))
		p = _pe(p.x, p.z, 0.35) - Vector3(0, 0.08, 0)
		var perto := _perto(p.x, p.z)
		if _rng.randf() < 0.22:
			if perto:
				_betula(mm, p, _rng.randf_range(8.0, 12.0), false)
			else:
				_betula_longe(mata_longe, p, _rng.randf_range(8.0, 12.0))
		else:
			var alt := _rng.randf_range(9.0, 16.0)
			var cor := Color(0.08, 0.13, 0.09) * _rng.randf_range(0.8, 1.25)
			if perto:
				_vistas._abeto(mm, p, alt, cor, _rng)
			else:
				_abeto_longe(mata_longe, p, alt, cor)
	# Do outro lado do vale (leste), bosques nos morros, mais ralos.
	for i in 260:
		var p := Vector3(_rng.randf_range(60.0, 205.0), 0, _rng.randf_range(-228.0, 228.0))
		p = _pe(p.x, p.z, 0.35) - Vector3(0, 0.08, 0)
		var alt := _rng.randf_range(8.0, 13.0)
		var cor := Color(0.1, 0.15, 0.09) * _rng.randf_range(0.8, 1.2)
		if _perto(p.x, p.z):
			_vistas._abeto(mm, p, alt, cor, _rng)
		else:
			_abeto_longe(mata_longe, p, alt, cor)
	# Os troncos do quintal e do pântano barram o corpo.
	for p in troncos:
		_col.append([Vector3(0.5, 3.0, 0.5), p + Vector3(0, 1.5, 0)])


## Uma bétula: o tronco fino e pálido com os nós escuros; perto, a copa rala em
## três bolas pequenas; longe (a encosta), dois fusos.
func _betula(mm: Cidade.Malha, p: Vector3, alt: float, perto: bool) -> void:
	mm.caixa(Vector3(0.14, alt, 0.14), p + Vector3(0, alt / 2, 0), Color(0.74, 0.72, 0.66))
	for k in 3:
		mm.caixa(Vector3(0.15, 0.06, 0.15), p + Vector3(0, _rng.randf_range(0.8, alt - 1.0), 0), Color(0.12, 0.12, 0.12))
	var folha := Color(0.26, 0.34, 0.15) if _rng.randf() < 0.85 else Color(0.5, 0.46, 0.18)
	if perto:
		# Playtest 11 (R4): de perto, os galhos finos subindo do tronco e a copa
		# rala de tufos pequenos nas pontas (eram três bolas).
		for k in 5:
			var y := alt * _rng.randf_range(0.45, 0.8)
			var a := _rng.randf() * TAU
			var dir := Vector3(cos(a) * 0.6, 1.0, sin(a) * 0.6).normalized()
			var de := p + Vector3(0, y, 0)
			var fim := de + dir * alt * _rng.randf_range(0.18, 0.3)
			_galho(mm, de, fim, 0.04, 0.015, Color(0.7, 0.68, 0.62))
			_tufo(mm, fim, _rng.randf_range(0.45, 0.7), folha)
			_tufo(mm, de.lerp(fim, 0.55) + Vector3(0, 0.15, 0), _rng.randf_range(0.35, 0.5), folha * 0.9)
		_tufo(mm, p + Vector3(0, alt * 0.98, 0), 0.55, folha)
	else:
		mm.bipiramide(alt * 0.13, alt * 0.45, p + Vector3(0, alt * 0.74, 0), 5, folha, _rng.randf() * TAU)
		mm.bipiramide(alt * 0.1, alt * 0.3, p + Vector3(0.3, alt * 0.52, 0), 5, folha * 0.9, _rng.randf() * TAU)


## Uma cicuta de longe: três cones de cinco lados, sem o tronco (escondido pelos
## de baixo). Tira do sorteio os mesmos números de Vistas._abeto, para o resto da
## fazenda não mudar de lugar.
func _abeto_longe(mm: Cidade.Malha, p: Vector3, alt: float, cor: Color) -> void:
	for k in 4:
		var r := alt * (0.18 - k * 0.04) * _rng.randf_range(0.9, 1.1)
		if k < 3:
			mm.piramide(r, alt * 0.36, p + Vector3(0, alt * (0.12 + k * 0.24), 0), 5, cor * (1.0 + k * 0.08))


## Uma bétula de longe: o tronco pálido num fuso de três lados e a copa num só.
## O mesmo sorteio de _betula (sem `perto`).
func _betula_longe(mm: Cidade.Malha, p: Vector3, alt: float) -> void:
	mm.piramide(0.12, alt, p, 3, Color(0.74, 0.72, 0.66))
	for k in 3:
		_rng.randf_range(0.8, alt - 1.0)
	var folha := Color(0.26, 0.34, 0.15) if _rng.randf() < 0.85 else Color(0.5, 0.46, 0.18)
	mm.bipiramide(alt * 0.14, alt * 0.6, p + Vector3(0, alt * 0.68, 0), 4, folha, _rng.randf() * TAU)
	_rng.randf()


## Um tronco morto do pântano, sem casca, com dois galhos quebrados.
func _morta(mm: Cidade.Malha, p: Vector3) -> void:
	var alt := _rng.randf_range(2.5, 5.5)
	var cor := Color(0.42, 0.4, 0.36)
	# Playtest 11 (R4): o tronco que afina e se inclina, a ponta lascada, e dois ou
	# três galhos quebrados, tortos.
	var topo := p + Vector3(_rng.randf_range(-0.4, 0.4), alt, _rng.randf_range(-0.4, 0.4))
	_galho(mm, p + Vector3(0, -0.2, 0), topo, 0.16, 0.05, cor)
	for k in _rng.randi_range(2, 3):
		var de := p.lerp(topo, _rng.randf_range(0.35, 0.8))
		var a := _rng.randf() * TAU
		var fim := de + Vector3(cos(a), _rng.randf_range(0.2, 0.9), sin(a)).normalized() * _rng.randf_range(0.6, 1.4)
		_galho(mm, de, fim, 0.06, 0.02, cor * 0.9)


# --- O acabamento dos interiores (playtest 11) --------------------------------------

## Os cômodos da casa e do puxado, para o acabamento: [nome, x (de, até), z (de,
## até), piso, teto, papel, lambri (altura do lambri; 0 = sem), {lado: aberturas}].
## As aberturas são as de `_parede` ([centro ao longo da parede, largura, base,
## topo]); "n" e "s" correm em X (z fixo), "o" e "l" em Z (x fixo). As que vão ao
## teto (a chaminé) só cortam o papel; as que vão ao piso (as portas) cortam o
## rodapé e ganham alizar; as outras (as janelas) ganham alizar e peitoril.
func _comodos() -> Array:
	var p0 := func(c: float, l := 0.9) -> Array: return [c, l, T0, T0 + 2.15]
	var p1 := func(c: float, l := 0.9) -> Array: return [c, l, T1, T1 + 2.1]
	var j0 := func(c: float) -> Array: return [c, 0.9, T0 + 0.8, T0 + 2.3]
	var j1 := func(c: float) -> Array: return [c, 0.9, T1 + 0.7, T1 + 2.2]
	var cham := func(c: float) -> Array: return [c, 2 * CHAMINE_MEIA.y, -9.0, 99.0]
	var banheiro_x := -1.0
	var patamar := (banheiro_x + ESCADA_X - DEGRAUS * PISADA) / 2
	var fx := Vector2(MEIO_X + EI / 2, CASA_X.y - E)   # os cômodos da frente
	var tx := Vector2(CASA_X.x + E, MEIO_X - EI / 2)   # os de trás
	var sz := Vector2(HALL_Z + EI / 2, CASA_Z.y - E)   # ao sul do vestíbulo
	var nz := Vector2(CASA_Z.x + E, -HALL_Z - EI / 2)  # ao norte
	var hz := Vector2(-HALL_Z + EI / 2, HALL_Z - EI / 2)
	var t0 := T0 + PE0
	return [
		["Escritorio", fx, sz, T0, t0, "papel_estudo", 0.0,
			{"n": [p0.call(5.1)], "o": [p0.call(2.15), cham.call(CHAMINE_Z)], "l": [j0.call(2.6), j0.call(4.8)], "s": [j0.call(4.6), j0.call(2.4)]}],
		["SalaEstar", fx, nz, T0, t0, "papel_sala", 0.0,
			{"s": [p0.call(5.1)], "o": [cham.call(-CHAMINE_Z)], "l": [j0.call(-4.8), j0.call(-2.6)], "n": [j0.call(4.6), j0.call(2.4)]}],
		["SalaJantar", tx, sz, T0, t0, "papel_jantar", 0.95,
			{"n": [p0.call(-1.5)], "l": [p0.call(2.15), cham.call(CHAMINE_Z)], "o": [[CHAMINE_Z, 0.9, T0, T0 + 2.35]], "s": [j0.call(-1.0)]}],
		["SalaFundos", tx, nz, T0, t0, "parede_casa", 1.1,
			{"s": [p0.call(-1.5)], "l": [cham.call(-CHAMINE_Z)], "o": [j0.call(-4.8), j0.call(-2.6)], "n": [j0.call(-1.0)]}],
		["Vestibulo", Vector2(CASA_X.x + E, CASA_X.y - E), hz, T0, t0, "papel_vestibulo", 0.95,
			{"n": [p0.call(5.1), p0.call(-1.5)], "s": [p0.call(5.1), p0.call(-1.5)], "l": [[0.0, 1.1, T0, T0 + 2.35]], "o": [[0.0, 1.0, T0, T0 + 2.35]]}],
		["QuartoHospedes", fx, sz, T1, FORRO, "papel_quarto", 0.0,
			{"n": [p1.call(3.0)], "o": [cham.call(CHAMINE_Z)], "l": [j1.call(2.6), j1.call(4.8)], "s": [j1.call(4.6), j1.call(2.4)]}],
		["QuartoAkeley", fx, nz, T1, FORRO, "papel_quarto_akeley", 0.0,
			{"s": [p1.call(5.1)], "o": [cham.call(-CHAMINE_Z)], "l": [j1.call(-4.8), j1.call(-2.6)], "n": [j1.call(4.6), j1.call(2.4)]}],
		["QuartoCostura", tx, sz, T1, FORRO, "papel_sala", 0.0,
			{"n": [p1.call(patamar, 0.8)], "l": [cham.call(CHAMINE_Z)], "o": [j1.call(2.6), j1.call(4.8)], "s": [j1.call(-1.0)]}],
		["QuartoGuardados", tx, nz, T1, FORRO, "papel_vestibulo", 0.0,
			{"s": [p1.call(patamar, 0.8)], "l": [cham.call(-CHAMINE_Z)], "o": [j1.call(-4.8), j1.call(-2.6)], "n": [j1.call(-1.0)]}],
		["Banheiro", Vector2(CASA_X.x + E, banheiro_x - EI / 2), hz, T1, FORRO, "caiado", 1.2,
			{"l": [p1.call(0.0, 0.8)], "o": [[0.0, 0.6, T1 + 1.2, T1 + 2.0]]}],
		["CorredorDeCima", Vector2(banheiro_x + EI / 2, CASA_X.y - E), hz, T1, FORRO, "papel_vestibulo", 0.0,
			{"n": [p1.call(5.1), p1.call(patamar, 0.8)], "s": [p1.call(3.0), p1.call(patamar, 0.8)], "l": [j1.call(0.0)], "o": [p1.call(0.0, 0.8)]}],
		["Cozinha", Vector2(PUXADO_X.x + 0.2, CASA_X.x), Vector2(PUXADO_Z.x + 0.2, PUXADO_Z.y - 0.2), T0, PUXADO_ALTO, "caiado", 1.0,
			{"n": [p0.call(-6.5), [-4.5, 0.8, T0 + 0.9, T0 + 2.1]], "s": [[-5.0, 0.8, T0 + 0.9, T0 + 2.1], [-7.6, 0.8, T0 + 0.9, T0 + 2.1]],
			"o": [p0.call(4.6)], "l": [[CHAMINE_Z, 0.9, T0, T0 + 2.35]]}],
	]


## O acabamento de cada cômodo: o papel (um forro fino por dentro de cada parede,
## recortado nas aberturas), o lambri com a moldura por cima (onde há), o rodapé,
## a cimalha no teto, os alizares das portas e das janelas e os peitoris, e a luz
## de rebatimento (os interiores ficavam quase pretos de dia).
func _acabamento_interior() -> void:
	var luzes := _group(cena, "LuzesDeDentro")
	for c: Array in _comodos():
		var x: Vector2 = c[1]
		var z: Vector2 = c[2]
		var y0: float = c[3]
		var y1: float = c[4]
		var papel: String = c[5]
		var lambri: float = c[6]
		var lados: Dictionary = c[7]
		# [lado, de, até, para dentro]
		for lado: Array in [["n", Vector2(x.x, z.x), Vector2(x.y, z.x), Vector3.BACK], ["s", Vector2(x.x, z.y), Vector2(x.y, z.y), Vector3.FORWARD],
				["o", Vector2(x.x, z.x), Vector2(x.x, z.y), Vector3.RIGHT], ["l", Vector2(x.y, z.x), Vector2(x.y, z.y), Vector3.LEFT]]:
			var aberturas: Array = lados.get(lado[0], [])
			_revestir_parede(lado[1], lado[2], lado[3], y0, y1, papel, lambri, aberturas)
		# A luz de rebatimento, sem sombra, no meio do cômodo, perto do teto.
		var luz := OmniLight3D.new()
		luz.name = "Luz%s" % c[0]
		luz.position = Vector3((x.x + x.y) / 2, y1 - 0.5, (z.x + z.y) / 2)
		luz.light_color = Color(1.0, 0.86, 0.72)
		luz.light_energy = 0.32
		luz.omni_range = maxf(x.y - x.x, z.y - z.x) * 0.85 + 1.0
		luz.omni_attenuation = 0.8
		luz.shadow_enabled = false
		luz.light_specular = 0.0
		_add(luzes, luz)


## O forro de uma parede vista de dentro de um cômodo (de `de` a `ate`, com a face
## para `dentro`): o papel, o lambri e a moldura, o rodapé, a cimalha e os
## alizares e peitoris das aberturas.
func _revestir_parede(de: Vector2, ate: Vector2, dentro: Vector3, y0: float, y1: float, papel: String, lambri: float, aberturas: Array) -> void:
	const FINO := 0.006
	var em_x := is_equal_approx(de.y, ate.y)
	var desloca := Vector2(dentro.x, dentro.z) * (FINO / 2 + 0.002)
	var a := de + desloca
	var b := ate + desloca
	# O papel (e, embaixo, o lambri), recortados nas aberturas; sem colisão.
	if lambri > 0.0:
		_parede("lambri", a, b, y0, y0 + lambri, FINO, aberturas, Color.WHITE, false)
		_parede(papel, a, b, y0 + lambri, y1, FINO, aberturas, Color.WHITE, false)
	else:
		_parede(papel, a, b, y0, y1, FINO, aberturas, Color.WHITE, false)
	var s0 := minf(de.x, ate.x) if em_x else minf(de.y, ate.y)
	var s1 := maxf(de.x, ate.x) if em_x else maxf(de.y, ate.y)
	var fixo := de.y if em_x else de.x
	# Um sarrafo ao longo da parede, de s a t, na altura y (centro), com seção
	# (alto, fundo) saindo da parede para dentro.
	var sarrafo := func(mat: String, s: float, t: float, y: float, alto: float, fundo: float) -> void:
		if t - s < 0.01:
			return
		var meio := (s + t) / 2
		var c := Vector3(meio, y, fixo) if em_x else Vector3(fixo, y, meio)
		c += dentro * (fundo / 2 + 0.004)
		var tam := Vector3(t - s, alto, fundo) if em_x else Vector3(fundo, alto, t - s)
		_bloco(mat, tam, c, Color.WHITE, false)
	# Os trechos sem porta (para o rodapé e a moldura do lambri) e sem nada que vá
	# ao teto (para a cimalha).
	var livres := func(corta: Callable) -> Array:
		var trechos := [Vector2(s0, s1)]
		for ab: Array in aberturas:
			if not corta.call(ab):
				continue
			var novos := []
			for tr: Vector2 in trechos:
				var c0: float = ab[0] - ab[1] / 2
				var c1: float = ab[0] + ab[1] / 2
				if c1 <= tr.x or c0 >= tr.y:
					novos.append(tr)
					continue
				if c0 > tr.x:
					novos.append(Vector2(tr.x, c0))
				if c1 < tr.y:
					novos.append(Vector2(c1, tr.y))
			trechos = novos
		return trechos
	var e_porta := func(ab: Array) -> bool: return float(ab[2]) <= y0 + 0.02 and float(ab[3]) < y1
	var vai_ao_teto := func(ab: Array) -> bool: return float(ab[3]) >= y1 - 0.02
	for tr: Vector2 in livres.call(func(ab: Array) -> bool: return e_porta.call(ab) or vai_ao_teto.call(ab)):
		sarrafo.call("madeira_escura", tr.x, tr.y, y0 + 0.09, 0.18, 0.022)
		sarrafo.call("madeira_escura", tr.x, tr.y, y0 + 0.19, 0.025, 0.03)
		if lambri > 0.0:
			sarrafo.call("madeira_escura", tr.x, tr.y, y0 + lambri, 0.05, 0.035)
	for tr: Vector2 in livres.call(vai_ao_teto):
		sarrafo.call("pintura_branca", tr.x, tr.y, y1 - 0.05, 0.1, 0.06)
		sarrafo.call("pintura_branca", tr.x, tr.y, y1 - 0.12, 0.03, 0.025)
	# A espessura da parede nos vãos (o forro do batente): sem ela via-se o reboco
	# cru. Nas paredes externas a espessura é E; nas de dentro, EI — e o forro de
	# uma porta de dentro vem de um lado só (do cômodo que a tem ao norte ou a
	# oeste), para os dois não brigarem no mesmo lugar.
	var externa := absf(fixo - (CASA_X.x + E)) < 0.02 or absf(fixo - (CASA_X.y - E)) < 0.02 or absf(fixo - (CASA_Z.x + E)) < 0.02  or absf(fixo - (CASA_Z.y - E)) < 0.02 or absf(fixo - (PUXADO_X.x + 0.2)) < 0.02 or absf(fixo - (PUXADO_Z.x + 0.2)) < 0.02  or absf(fixo - (PUXADO_Z.y - 0.2)) < 0.02
	var esp := E if externa else EI
	var este_lado := dentro == Vector3.BACK or dentro == Vector3.RIGHT
	for ab: Array in aberturas:
		if vai_ao_teto.call(ab):
			continue
		var porta: bool = e_porta.call(ab)
		if porta and not externa and not este_lado:
			continue
		if porta and externa and absf(fixo - (CASA_X.x)) < 0.02:
			continue
		var fundo := esp if porta else esp * 0.55
		var v0: float = ab[0] - ab[1] / 2
		var v1: float = ab[0] + ab[1] / 2
		var vb: float = ab[2]
		var vt: float = ab[3]
		var fora := -dentro
		var forro := func(s: float, t: float, ya: float, yb: float) -> void:
			var meio := (s + t) / 2
			var c := Vector3(meio, (ya + yb) / 2, fixo) if em_x else Vector3(fixo, (ya + yb) / 2, meio)
			c += fora * (fundo / 2 - 0.002)
			var tam := Vector3(t - s, yb - ya, fundo) if em_x else Vector3(fundo, yb - ya, t - s)
			_bloco("pintura_branca", tam, c, Color.WHITE, false)
		forro.call(v0, v0 + 0.02, vb, vt)
		forro.call(v1 - 0.02, v1, vb, vt)
		forro.call(v0, v1, vt - 0.02, vt)
		if not porta:
			forro.call(v0, v1, vb, vb + 0.02)
	# Os alizares: dos dois lados e em cima de portas e janelas; o peitoril das
	# janelas.
	for ab: Array in aberturas:
		if vai_ao_teto.call(ab):
			continue
		var c0: float = ab[0] - ab[1] / 2
		var c1: float = ab[0] + ab[1] / 2
		var base: float = ab[2]
		var topo: float = ab[3]
		var porta: bool = e_porta.call(ab)
		var desce := base if porta else base - 0.1
		for borda: float in [c0 - 0.045, c1 + 0.045]:
			sarrafo.call("pintura_branca", borda - 0.045, borda + 0.045, (desce + topo + 0.09) / 2, topo + 0.09 - desce, 0.022)
		sarrafo.call("pintura_branca", c0 - 0.11, c1 + 0.11, topo + 0.08, 0.16, 0.028)
		sarrafo.call("pintura_branca", c0 - 0.13, c1 + 0.13, topo + 0.17, 0.03, 0.045)
		if not porta:
			sarrafo.call("pintura_branca", c0 - 0.08, c1 + 0.08, base - 0.015, 0.035, 0.07)


## A cozinha do puxado (playtest 11): o fogão de ferro a lenha com o forno, a
## chapa, a prateleira de esquentar e a chaminé de lata até o teto; a pia de
## pedra-sabão sob a janela, com a bomba de mão; a mesa de pinho com as cadeiras;
## o guarda-louça aberto com os pratos e as xícaras; a caixa de lenha.
func _cozinha() -> void:
	var y := T0
	var pz := PUXADO_Z
	# O fogão, contra a parede sul, a chaminé subindo até o teto.
	var f := Vector3(-4.4, y, pz.y - 0.62)
	var g := 0.0
	_parte("esmalte_preto", Vector3(1.05, 0.62, 0.62), Vector3(0, 0.46, 0), f, g)
	_parte("ferro", Vector3(1.12, 0.04, 0.68), Vector3(0, 0.79, 0), f, g, Color(0.55, 0.55, 0.58))
	for k in 4:
		_cilindro("ferro", f + Vector3(-0.38 + k * 0.25, 0.815, 0.05), 0.09, 0.01, 10, Color(0.4, 0.4, 0.42))
	_parte("esmalte_preto", Vector3(1.05, 0.5, 0.06), Vector3(0, 1.06, 0.3), f, g)
	_parte("esmalte_preto", Vector3(1.05, 0.04, 0.28), Vector3(0, 1.3, 0.17), f, g)
	for sx: float in [-1.0, 1.0]:
		_parte("ferro", Vector3(0.42, 0.34, 0.02), Vector3(sx * 0.24, 0.48, -0.32), f, g, Color(0.5, 0.5, 0.52))
		_parte("latao", Vector3(0.08, 0.02, 0.03), Vector3(sx * 0.24, 0.62, -0.34), f, g)
		for sz: float in [-1.0, 1.0]:
			_parte("esmalte_preto", Vector3(0.06, 0.16, 0.06), Vector3(sx * 0.46, 0.08, sz * 0.25), f, g)
	_cilindro("ferro", f + Vector3(0.25, (1.32 + PUXADO_ALTO - y) / 2, 0.22), 0.075, PUXADO_ALTO - y - 1.32, 10, Color(0.42, 0.42, 0.44))
	# A chaleira e a frigideira.
	_cilindro("ferro", f + Vector3(-0.15, 0.89, 0.0), 0.1, 0.13, 10, Color(0.6, 0.6, 0.62))
	_cilindro("ferro", f + Vector3(0.3, 0.83, -0.05), 0.14, 0.03, 12, Color(0.35, 0.35, 0.37))
	_colide(Vector3(1.1, 0.85, 0.7), Vector3(0, 0.42, 0), f, g)
	# A caixa de lenha ao lado.
	var lc := Vector3(-3.55, y, pz.y - 0.45)
	_parte("madeira_clara", Vector3(0.6, 0.5, 0.5), Vector3(0, 0.25, 0), lc, 0.0)
	var lenha := _obra("madeira_clara")
	for k in 6:
		_face_toras(lenha, lc + Vector3(-0.18 + (k % 3) * 0.15, 0.56 + (k / 3) * 0.12, 0.0))
	_colide(Vector3(0.6, 0.6, 0.5), Vector3(0, 0.3, 0), lc, 0.0)
	# A pia de pedra-sabão sob a janela sul, com a bomba de mão e o balde.
	var pia := Vector3(-5.6, y, pz.y - 0.35)
	_parte("pedra_lareira", Vector3(1.1, 0.12, 0.55), Vector3(0, 0.82, 0), pia, g, Color(0.75, 0.78, 0.76))
	_parte("pedra_lareira", Vector3(0.8, 0.02, 0.38), Vector3(0, 0.885, 0), pia, g, Color(0.5, 0.52, 0.5))
	_parte("madeira_clara", Vector3(1.05, 0.76, 0.5), Vector3(0, 0.38, 0.02), pia, g)
	for sx: float in [-1.0, 1.0]:
		_parte("madeira_clara", Vector3(0.48, 0.6, 0.02), Vector3(sx * 0.25, 0.38, -0.24), pia, g, Color(1.1, 1.1, 1.1))
	var bomba := pia + Vector3(0.3, 0.88, 0.15)
	_cilindro("ferro", bomba + Vector3(0, 0.18, 0), 0.05, 0.36, 8, Color(0.4, 0.42, 0.4))
	_bloco("ferro", Vector3(0.03, 0.03, 0.18), bomba + Vector3(0, 0.3, -0.1), Color(0.4, 0.42, 0.4), false, Vector3(-10, 0, 0))
	_bloco("ferro", Vector3(0.025, 0.025, 0.3), bomba + Vector3(0, 0.42, 0.1), Color(0.4, 0.42, 0.4), false, Vector3(25, 0, 0))
	_colide(Vector3(1.1, 0.9, 0.55), Vector3(0, 0.45, 0), pia, g)
	# A mesa de pinho, as cadeiras.
	_mesa(Vector3(-5.8, y, 3.25), 90.0, Vector3(1.3, 0.76, 0.8), "madeira_clara")
	for s: float in [-1.0, 1.0]:
		_cadeira_espaldar(Vector3(-5.8 + s * 0.6, y, 3.25 + 0.25), 90.0 * s)
	_cadeira_espaldar(Vector3(-5.8, y, 4.15), 0.0)
	# O guarda-louça aberto contra a parede do vestíbulo... (a leste, junto da
	# porta da sala de jantar): as prateleiras com pratos em pé e xícaras.
	var gl := Vector3(-3.32, y, 1.9)
	var gg := 90.0
	_parte("madeira_escura", Vector3(1.2, 0.85, 0.45), Vector3(0, 0.43, 0), gl, gg)
	_parte("madeira_escura", Vector3(1.26, 0.035, 0.5), Vector3(0, 0.87, 0), gl, gg)
	for sx: float in [-1.0, 1.0]:
		_parte("madeira_escura", Vector3(0.56, 0.6, 0.02), Vector3(sx * 0.29, 0.43, -0.23), gl, gg, Color(1.12, 1.12, 1.12))
		_parte("madeira_escura", Vector3(0.03, 1.1, 0.28), Vector3(sx * 0.59, 1.45, 0.08), gl, gg)
	_parte("madeira_escura", Vector3(1.2, 1.1, 0.02), Vector3(0, 1.45, 0.21), gl, gg, Color(0.75, 0.75, 0.75))
	_parte("madeira_escura", Vector3(1.26, 0.05, 0.32), Vector3(0, 2.02, 0.07), gl, gg)
	var b := Basis.from_euler(Vector3(0, deg_to_rad(gg), 0))
	for k in 3:
		var py := 1.05 + k * 0.33
		_parte("madeira_escura", Vector3(1.16, 0.02, 0.26), Vector3(0, py, 0.08), gl, gg)
		for j in 6:
			var x := -0.45 + j * 0.18
			if k == 1:
				_cilindro("porcelana", gl + b * Vector3(x, py + 0.045, 0.06), 0.035, 0.07, 8)
			else:
				_cilindro_deitado("porcelana", gl + b * Vector3(x, py + 0.1, 0.14), 0.09, 0.01, gg)
	_colide(Vector3(1.2, 2.0, 0.5), Vector3(0, 1.0, 0.0), gl, gg)


## Uma árvore de folha larga (playtest 11: as de antes pareciam cogumelos): o
## tronco que afina, com o pé alargado; quatro ou cinco galhos-mestres abrindo do
## alto do fuste (em vaso, no olmo: mais em pé), cada um com dois galhos finos; e a
## copa feita de muitos tufos irregulares nas pontas, escuros embaixo e claros em
## cima, com vãos entre eles por onde se vê o céu.
func _arvore(mm: Cidade.Malha, p: Vector3, alt: float, raio: float, folha: Color, vaso := false) -> void:
	var tronco := Color(0.27, 0.23, 0.19)
	var fuste := alt * (0.4 if vaso else 0.3)
	var topo := p + Vector3(0, fuste, 0)
	_galho(mm, p + Vector3(0, -0.2, 0), p + Vector3(0, 0.5, 0), 0.38, 0.24, tronco * 0.9)
	_galho(mm, p + Vector3(0, 0.5, 0), topo, 0.24, 0.17, tronco)
	var n := _rng.randi_range(4, 5)
	for k in n:
		var ang := TAU * k / n + _rng.randf_range(-0.35, 0.35)
		var incl := deg_to_rad(_rng.randf_range(22.0, 34.0) if vaso else _rng.randf_range(38.0, 58.0))
		var dir := Vector3(cos(ang) * sin(incl), cos(incl), sin(ang) * sin(incl))
		var compr := alt * _rng.randf_range(0.3, 0.38)
		var fim := topo + dir * compr
		_galho(mm, topo, fim, 0.15, 0.07, tronco)
		_tufo(mm, fim + Vector3(0, raio * 0.15, 0), raio * _rng.randf_range(0.38, 0.5), folha)
		for j in 2:
			var a2 := ang + (j - 0.5) * _rng.randf_range(0.8, 1.3)
			var d2 := (Vector3(cos(a2) * 0.8, 0.9, sin(a2) * 0.8) + dir).normalized()
			var fim2 := fim + d2 * compr * _rng.randf_range(0.4, 0.6)
			_galho(mm, fim, fim2, 0.07, 0.03, tronco)
			_tufo(mm, fim2, raio * _rng.randf_range(0.32, 0.46), folha)
	# O alto da copa.
	for k in 3:
		var c := topo + Vector3(_rng.randf_range(-raio, raio) * 0.3, alt * _rng.randf_range(0.42, 0.55), _rng.randf_range(-raio, raio) * 0.3)
		_tufo(mm, c, raio * _rng.randf_range(0.4, 0.55), folha)


## Um galho (ou o tronco): um tronco de cone de seis lados de `a` a `b`.
func _galho(mm: Cidade.Malha, a: Vector3, b: Vector3, r0: float, r1: float, cor: Color) -> void:
	var eixo := (b - a).normalized()
	var lado := eixo.cross(Vector3.FORWARD if absf(eixo.z) < 0.9 else Vector3.RIGHT).normalized()
	var frente := lado.cross(eixo).normalized()
	const N := 6
	for i in N:
		var u0 := TAU * i / N
		var u1 := TAU * (i + 1) / N
		var d0 := lado * cos(u0) + frente * sin(u0)
		var d1 := lado * cos(u1) + frente * sin(u1)
		var sombra := 0.85 + 0.15 * sin(u0)
		mm.quad(a + d0 * r0, a + d1 * r0, b + d1 * r1, b + d0 * r1, (d0 + d1).normalized(), cor * sombra)


## Um tufo de folhagem: uma bola irregular, achatada embaixo, escura por baixo e
## clara por cima (a luz do céu), com a cor variando um pouco.
func _tufo(mm: Cidade.Malha, c: Vector3, r: float, folha: Color) -> void:
	const LADOS := 8
	const ANEIS := 5
	var pts: Array = []
	var tom := folha * _rng.randf_range(0.88, 1.12)
	for j in ANEIS + 1:
		var v := PI * j / ANEIS
		var fila: Array = []
		for i in LADOS:
			var u := TAU * i / LADOS
			var d := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var k := _rng.randf_range(0.82, 1.15) if j > 0 and j < ANEIS else 1.0
			var q := d * r * k
			if q.y < 0.0:
				q.y *= 0.55
			fila.append(c + q)
		pts.append(fila)
	for j in ANEIS:
		var luz := lerpf(1.12, 0.6, float(j) / ANEIS)
		for i in LADOS:
			var a: Vector3 = pts[j][i]
			var b: Vector3 = pts[j][(i + 1) % LADOS]
			var cc: Vector3 = pts[j + 1][i]
			var d: Vector3 = pts[j + 1][(i + 1) % LADOS]
			var nn := ((a + b + cc + d) / 4.0 - c).normalized()
			mm.quad(a, b, d, cc, nn, tom * luz * _rng.randf_range(0.92, 1.06))


## A macieira do pomar: baixa, o tronco torto, os galhos abertos quase deitados, a
## copa larga de tufos menores, e uma ou outra maçã vermelha.
func _macieira(mm: Cidade.Malha, p: Vector3) -> void:
	var tronco := Color(0.3, 0.24, 0.18)
	var topo := p + Vector3(_rng.randf_range(-0.2, 0.2), 1.2, _rng.randf_range(-0.2, 0.2))
	_galho(mm, p, topo, 0.15, 0.11, tronco)
	var folha := Color(0.24, 0.34, 0.16)
	for k in 4:
		var ang := TAU * k / 4 + _rng.randf_range(-0.4, 0.4)
		var incl := deg_to_rad(_rng.randf_range(55.0, 70.0))
		var dir := Vector3(cos(ang) * sin(incl), cos(incl), sin(ang) * sin(incl))
		var fim := topo + dir * _rng.randf_range(1.4, 1.9)
		_galho(mm, topo, fim, 0.08, 0.04, tronco)
		_tufo(mm, fim + Vector3(0, 0.3, 0), _rng.randf_range(0.75, 1.0), folha)
		_tufo(mm, topo.lerp(fim, 0.5) + Vector3(0, 0.6, 0), _rng.randf_range(0.7, 0.9), folha)
		for m2 in 3:
			var maca := fim + Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.4, 0.2), _rng.randf_range(-0.6, 0.6))
			mm.caixa(Vector3(0.09, 0.09, 0.09), maca, Color(0.55, 0.1, 0.07))
	_tufo(mm, topo + Vector3(0, 1.1, 0), 1.0, folha)


## Um abeto (cicuta) de perto, na beira do pântano: o tronco, e as saias de ramos
## caídas, sete andares que afinam até a ponta, cada uma meio torta.
func _abeto_perto(mm: Cidade.Malha, p: Vector3, alt: float) -> void:
	_galho(mm, p + Vector3(0, -0.2, 0), p + Vector3(0, alt * 0.95, 0), 0.22, 0.04, Color(0.22, 0.16, 0.12))
	var verde := Color(0.1, 0.17, 0.11) * _rng.randf_range(0.85, 1.15)
	for k in 7:
		var t := float(k) / 7.0
		var y := alt * (0.18 + t * 0.72)
		var r := alt * 0.22 * (1.0 - t * 0.85) * _rng.randf_range(0.9, 1.1)
		var c := p + Vector3(_rng.randf_range(-0.1, 0.1), y - alt * 0.08, _rng.randf_range(-0.1, 0.1))
		mm.piramide(r, alt * 0.2, c, 9, verde * (0.8 + 0.25 * t))
		# A saia cai: um anel mais escuro, abaixo da borda.
		mm.piramide(r * 1.05, alt * 0.05, c - Vector3(0, alt * 0.03, 0), 9, verde * 0.6)


## Um arbusto (o lilás junto da casa, os de beira de cerca): tufos baixos juntos.
func _arbusto(mm: Cidade.Malha, p: Vector3, r: float) -> void:
	var folha := Color(0.24, 0.37, 0.16)
	var lenho := Color(0.25, 0.2, 0.16)
	for k in 5:
		var a := TAU * k / 5.0 + _rng.randf_range(-0.3, 0.3)
		var fim := p + Vector3(cos(a) * r * 0.5, r * _rng.randf_range(0.9, 1.4), sin(a) * r * 0.5)
		_galho(mm, p, fim, 0.03, 0.015, lenho)
		_tufo(mm, fim, r * _rng.randf_range(0.28, 0.4), folha)
	# A massa da moita, do chão para cima (sem o pé à mostra: não é árvore).
	for k in 12:
		var c := p + Vector3(_rng.randf_range(-r, r) * 0.75, r * _rng.randf_range(0.2, 1.0), _rng.randf_range(-r, r) * 0.75)
		_tufo(mm, c, r * _rng.randf_range(0.3, 0.45), folha * _rng.randf_range(0.85, 1.2))


## Os arbustos em volta da casa (os lilases dos dois lados dos degraus da frente
## e nos cantos) e os tufos de capim alto pelo quintal (um MultiMesh, sem colisão:
## o gramado deixava de ser um pano liso).
## Onde há construção, cercado ou trilha (x, z): o capim e as árvores não nascem
## ali. [x de, x até, z de, z até].
const OCUPADO := [
	[-4.0, 8.0, -7.0, 7.0],  # a casa e os degraus
	[-13.5, -3.0, -5.5, 7.0],  # o puxado, o galpão de lenha, o alpendre
	[-8.6, 3.4, -23.0, -15.4],  # o canil e o cercado
	[4.9, 6.3, -17.3, -15.9],  # a bomba do poço
	[-26.0, -12.0, -39.0, -24.0],  # o celeiro
	[-32.0, -24.0, -37.0, -23.0],  # o galinheiro e o chiqueiro
	[11.4, 18.6, -21.6, -14.4],  # o abrigo do Ford
	[17.0, 28.0, -19.6, -16.4],  # a entrada de carro
	[-33.0, -27.0, -9.0, -2.5],  # o moinho e a caixa d'água
	[-17.6, -16.4, -15.0, -7.0],  # o varal
]


func _ocupado(x: float, z: float) -> bool:
	for o: Array in OCUPADO:
		if x > o[0] and x < o[1] and z > o[2] and z < o[3]:
			return true
	for t: Array in _trilhas_feitas:
		var a: Vector2 = t[0]
		var b: Vector2 = t[1]
		var p := Vector2(x, z)
		var u := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 0.0001), 0.0, 1.0)
		if p.distance_to(a.lerp(b, u)) < t[2] * 0.5 + 0.2:
			return true
	return false


## As trilhas de terra batida do terreiro (playtest 12, com o reespaçamento): da
## porta da cozinha à porteira do cercado e ao portão do celeiro, do galpão de lenha
## à trilha do celeiro, da porteira à bomba do poço, e da entrada de carro ao canil.
var _trilhas_feitas: Array = []


func _trilhas() -> void:
	var cozinha := Vector2(-6.5, -1.3)
	var porteira := Vector2(-0.3, -15.4)
	var celeiro := Vector2(-19.0, -24.4)
	var cruz := Vector2(-10.5, -10.5)
	for linha: Array in [
			[[cozinha, Vector2(-5.0, -7.0), Vector2(-2.0, -12.5), porteira], 1.3],
			[[cozinha, Vector2(-8.0, -6.0), cruz, Vector2(-15.5, -18.0), celeiro], 1.5],
			[[Vector2(-11.0, 0.6), Vector2(-10.6, -4.0), cruz], 1.1],
			[[Vector2(0.6, -15.4), Vector2(3.4, -15.9), Vector2(5.0, -16.4)], 1.0],
			[[Vector2(17.5, -16.4), Vector2(11.0, -14.2), Vector2(6.0, -14.6), Vector2(3.0, -15.3)], 1.2]]:
		var pts: Array = linha[0]
		for i in pts.size() - 1:
			_trilha(pts[i], pts[i + 1], linha[1])


## Uma trilha de terra de `a` a `b` (x, z), de `largura`, seguindo o chão e
## ondulando de leve nas beiras; mais gasta no meio (os dois sulcos dos pés).
func _trilha(a: Vector2, b: Vector2, largura: float) -> void:
	_trilhas_feitas.append([a, b, largura])
	var terra := _obra("chao_terra")
	var compr := a.distance_to(b)
	var dir := (b - a) / compr
	var lado := Vector2(-dir.y, dir.x)
	var n := maxi(1, ceili(compr / 0.9))
	# Um pouco além das pontas: as trilhas se encontram sem fresta.
	var de := a - dir * 0.4
	var passo := (compr + 0.8) / n
	for i in n:
		var s0 := float(i) * passo
		var s1 := s0 + passo
		var faixas := [[-0.5, -0.18, 0.9], [-0.18, 0.18, 1.0], [0.18, 0.5, 0.9]]
		for f: Array in faixas:
			var w0: float = f[0]
			var w1: float = f[1]
			var p := func(s: float, w: float) -> Vector3:
				var onda := sin((de.x + de.y) * 3.1 + s * 0.9 + w * 7.0) * 0.12 * absf(w) * 2.0
				var q := de + dir * s + lado * (w * largura + onda)
				return Vector3(q.x, _altura(q.x, q.y) + 0.02 + (0.004 if absf(w) < 0.2 else 0.0), q.y)
			var cor := Color(0.95, 0.9, 0.85) * float(f[2]) * (0.94 + 0.06 * sin(s0 * 1.7 + w0 * 5.0))
			terra.quad(p.call(s0, w0), p.call(s1, w0), p.call(s1, w1), p.call(s0, w1), Vector3.UP, cor)


## Um varal entre dois postes em T, junto à porta da cozinha, com a roupa de cama
## e uns panos esquecidos no pregador (o lugar ficou vazio com o reespaçamento).
func _varal() -> void:
	var a := Vector3(-17.0, 0, -7.5)
	var b := Vector3(-17.0, 0, -14.5)
	for p: Vector3 in [a, b]:
		_bloco("madeira_escura", Vector3(0.1, 2.1, 0.1), p + Vector3(0, 1.05, 0), Color(0.85, 0.8, 0.75))
		_bloco("madeira_escura", Vector3(0.9, 0.08, 0.08), p + Vector3(0, 2.0, 0), Color(0.85, 0.8, 0.75), false)
	for s: float in [-0.35, 0.35]:
		var antes := a + Vector3(s, 2.0, 0)
		for k in 6:
			var t := (k + 1) / 6.0
			var q := (a + Vector3(s, 2.0, 0)).lerp(b + Vector3(s, 2.0, 0), t) - Vector3(0, 0.25 * 4.0 * t * (1.0 - t), 0)
			_viga("ferro", antes, q, 0.008, Color(0.5, 0.5, 0.5))
			antes = q
	# Os panos: um lençol comprido e dois panos de prato, no fio de leste.
	for pano: Array in [[0.3, 1.6, 1.1, Color(1.0, 0.98, 0.92)], [0.62, 0.45, 0.5, Color(0.75, 0.82, 0.95)], [0.78, 0.4, 0.45, Color(0.95, 0.8, 0.75)]]:
		var t: float = pano[0]
		var q := (a + Vector3(0.35, 2.0, 0)).lerp(b + Vector3(0.35, 2.0, 0), t) - Vector3(0, 0.25 * 4.0 * t * (1.0 - t), 0)
		var larg: float = pano[1]
		var alto: float = pano[2]
		_bloco("pintura_branca", Vector3(0.02, alto, larg), q + Vector3(0.01, -alto / 2, 0), pano[3], false, Vector3(0, 0, 4.0))


func _arbustos_e_capim() -> void:
	var mm := _obra("bosque")
	for pt: Vector3 in [Vector3(6.8, 0, 2.4), Vector3(6.8, 0, -2.4), Vector3(6.7, 0, 5.2), Vector3(6.7, 0, -5.3),
			Vector3(-3.6, 0, -5.6), Vector3(2.0, 0, 6.8), Vector3(7.4, 0, 7.2), Vector3(-9.6, 0, 6.6)]:
		_arbusto(mm, pt, _rng.randf_range(0.8, 1.1))
		_col.append([Vector3(1.0, 1.4, 1.0), pt + Vector3(0, 0.7, 0)])
	# O capim: tufos de três folhas cruzadas, onde não há casa, caminho nem estrada.
	var tufo := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := PI * k / 3.0
		var d := Vector3(cos(a), 0, sin(a)) * 0.3
		var cima := Vector3.UP * 0.55
		# Os dois lados de cada folha (o material é de um lado só).
		for lado: Array in [[-d, d], [d, -d]]:
			var p0: Vector3 = lado[0]
			var p1: Vector3 = lado[1]
			var u0 := 0.0 if lado[0] == -d else 1.0
			var u1 := 1.0 - u0
			for v: Array in [[p0, Vector2(u0, 1)], [p1, Vector2(u1, 1)], [p1 + cima, Vector2(u1, 0)], [p0, Vector2(u0, 1)], [p1 + cima, Vector2(u1, 0)], [p0 + cima, Vector2(u0, 0)]]:
				st.set_uv(v[1])
				st.set_normal(Vector3.UP)
				st.add_vertex(v[0])
	st.commit(tufo)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = tufo
	var pontos: Array[Transform3D] = []
	var tentativas := 0
	while pontos.size() < 1600 and tentativas < 9000:
		tentativas += 1
		var x := _rng.randf_range(-30.0, 27.0)
		var z := _rng.randf_range(-45.0, 34.0)
		if x > CASA_X.x - 1.0 and x < CASA_X.y + 2.0 and z > CASA_Z.x - 1.0 and z < CASA_Z.y + 1.0:
			continue
		if x > PUXADO_X.x - 4.5 and x < CASA_X.x and z > PUXADO_Z.x - 1.0 and z < PUXADO_Z.y + 1.0:
			continue
		if _ocupado(x, z):
			continue
		if absf(z) < 1.4 and x > 6.0:
			continue  # o caminho da frente
		var esc := _rng.randf_range(0.5, 1.1)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(esc, esc * _rng.randf_range(0.7, 1.3), esc))
		pontos.append(Transform3D(b, Vector3(x, _chao_em(x, z) - 0.02, z)))
	# Sem tela (o gerador roda headless), o MultiMesh não guarda as posições: elas
	# vão na meta e a fase as põe ao carregar (Fazenda._capim).
	var dados := PackedFloat32Array()
	for t in pontos:
		dados.append_array([t.basis.x.x, t.basis.y.x, t.basis.z.x, t.origin.x, t.basis.x.y, t.basis.y.y, t.basis.z.y, t.origin.y,
			t.basis.x.z, t.basis.y.z, t.basis.z.z, t.origin.z])
	var mi := MultiMeshInstance3D.new()
	mi.set_meta(&"instancias", dados)
	mi.name = "Capim"
	mi.multimesh = multi
	mi.material_override = m["capim"]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(cena, mi)


## O acabamento do celeiro (playtest 11): o rodapé de pedra, as faixas brancas em
## volta do portão e das janelinhas, os beirais e as tábuas da empena, a porta do
## palheiro com a moldura e a cruz, e o lanternim de venezianas na cumeeira, com o
## cata-vento.
func _celeiro_acabamento() -> void:
	var x := Vector2(-21.0, -9.0)
	var z := Vector2(-21.0, -8.0)
	var alto := 5.0
	var cume := Vector2((x.x + x.y) / 2, alto + 3.6)
	var branco := "pintura_branca"
	# O rodapé de pedra.
	for s: float in [-1.0, 1.0]:
		var zf: float = z.y if s > 0 else z.x
		for seg: Vector2 in ([Vector2(x.x, cume.x - 1.85), Vector2(cume.x + 1.85, x.y)] if s > 0 else [x]):
			_bloco("pedra_campo", Vector3(seg.y - seg.x, 0.3, 0.2), Vector3((seg.x + seg.y) / 2, 0.15, zf + s * 0.02), Color.WHITE, false)
		var xf: float = x.y if s > 0 else x.x
		_bloco("pedra_campo", Vector3(0.2, 0.3, z.y - z.x), Vector3(xf + s * 0.02, 0.15, (z.x + z.y) / 2), Color.WHITE, false)
	# A moldura do portão.
	for s: float in [-1.0, 1.0]:
		_bloco(branco, Vector3(0.16, 3.9, 0.05), Vector3(cume.x + s * 1.88, 1.95, z.y + 0.02), Color.WHITE, false)
	_bloco(branco, Vector3(3.92, 0.16, 0.05), Vector3(cume.x, 3.86, z.y + 0.02), Color.WHITE, false)
	# As janelinhas: a moldura branca.
	for jn: Array in [[Vector3(-12.0, 1.9, z.x - 0.02), true], [Vector3(x.x - 0.02, 1.9, -14.5), false], [Vector3(x.y + 0.02, 1.9, -17.5), false]]:
		var c: Vector3 = jn[0]
		var em_x: bool = jn[1]
		for s: float in [-1.0, 1.0]:
			_bloco(branco, Vector3(0.08, 0.9, 0.04) if em_x else Vector3(0.04, 0.9, 0.08), c + (Vector3(s * 0.34, 0, 0) if em_x else Vector3(0, 0, s * 0.34)), Color.WHITE, false)
			_bloco(branco, Vector3(0.76, 0.08, 0.04) if em_x else Vector3(0.04, 0.08, 0.76), c + Vector3(0, s * 0.43, 0), Color.WHITE, false)
	# A porta do palheiro: a moldura e a cruz brancas, e o gancho da polia em cima.
	var pp := Vector3(cume.x, alto + 1.1, z.y + 0.065)
	for s: float in [-1.0, 1.0]:
		_bloco(branco, Vector3(0.1, 1.7, 0.04), pp + Vector3(s * 0.82, 0, 0), Color.WHITE, false)
		_bloco(branco, Vector3(1.74, 0.1, 0.04), pp + Vector3(0, s * 0.82, 0), Color.WHITE, false)
		_bloco(branco, Vector3(2.15, 0.08, 0.03), pp + Vector3(0, 0, 0.01), Color.WHITE, false, Vector3(0, 0, s * 45.0))
	_bloco("madeira_escura", Vector3(0.14, 0.14, 1.0), Vector3(cume.x, cume.y - 0.5, z.y + 0.45), Color.WHITE, false)
	# As tábuas brancas da empena (ao longo das águas) e os beirais.
	var ang := rad_to_deg(atan2(cume.y - alto, cume.x - x.x))
	var rampa := Vector2(cume.x - x.x, cume.y - alto).length() + 0.4
	for s: float in [-1.0, 1.0]:
		var zf: float = (z.y + 0.42) if s > 0 else (z.x - 0.42)
		for lado: float in [-1.0, 1.0]:
			var meio := Vector3(cume.x + lado * (cume.x - x.x) / 2, (alto + cume.y) / 2 + 0.05, zf)
			_bloco(branco, Vector3(rampa, 0.2, 0.05), meio, Color.WHITE, false, Vector3(0, 0, -lado * ang))
	for lado: float in [-1.0, 1.0]:
		var xb: float = (x.y + 0.35) if lado > 0 else (x.x - 0.35)
		_bloco(branco, Vector3(0.05, 0.18, z.y - z.x + 0.8), Vector3(xb, alto - 0.12, (z.x + z.y) / 2), Color.WHITE, false)
	# O lanternim: a caixa de venezianas, o telhadinho de quatro águas, o cata-vento.
	var lt := Vector3(cume.x, cume.y + 0.45, (z.x + z.y) / 2)
	_bloco("celeiro", Vector3(1.1, 0.9, 1.1), lt, Color.WHITE, false)
	for s: float in [-1.0, 1.0]:
		for k in 4:
			_bloco(branco, Vector3(0.9, 0.04, 0.03), lt + Vector3(0, -0.3 + k * 0.18, s * 0.565), Color.WHITE, false, Vector3(-30.0 * s, 0, 0))
			_bloco(branco, Vector3(0.03, 0.04, 0.9), lt + Vector3(s * 0.565, -0.3 + k * 0.18, 0), Color.WHITE, false, Vector3(0, 0, 30.0 * s))
	_obra("telhado").piramide(0.95, 0.7, lt + Vector3(0, 0.45, 0), 4, Color.WHITE)
	_bloco("ferro", Vector3(0.03, 0.9, 0.03), lt + Vector3(0, 1.5, 0), Color(0.5, 0.5, 0.5), false)
	_bloco("ferro", Vector3(0.6, 0.06, 0.02), lt + Vector3(0.05, 1.8, 0), Color(0.5, 0.5, 0.5), false, Vector3(0, 25, 0))
	_bloco("ferro", Vector3(0.14, 0.14, 0.02), lt + Vector3(-0.25, 1.8, 0.1), Color(0.5, 0.5, 0.5), false, Vector3(0, 25, 45))
	for s: float in [-1.0, 1.0]:
		_bloco("ferro", Vector3(0.36, 0.015, 0.015), lt + Vector3(0, 1.62, 0), Color(0.5, 0.5, 0.5), false, Vector3(0, 45.0 + s * 45.0, 0))


## Uma peça torneada (revolução de `perfil`, [raio, altura] de baixo para cima) em
## volta do Y, com `lados` faces; a normal de cada face aponta para fora.
func _torneado(pai: Node3D, nome: String, perfil: Array, mat: String, lados: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in perfil.size() - 1:
		var a: Vector2 = perfil[k]
		var b: Vector2 = perfil[k + 1]
		for i in lados:
			var u0 := TAU * i / lados
			var u1 := TAU * (i + 1) / lados
			var p00 := Vector3(cos(u0) * a.x, a.y, sin(u0) * a.x)
			var p01 := Vector3(cos(u1) * a.x, a.y, sin(u1) * a.x)
			var p10 := Vector3(cos(u0) * b.x, b.y, sin(u0) * b.x)
			var p11 := Vector3(cos(u1) * b.x, b.y, sin(u1) * b.x)
			var meio := Vector3(0, (a.y + b.y) / 2, 0)
			for tri: Array in [[p00, p10, p01], [p01, p10, p11]]:
				var t0: Vector3 = tri[0]
				var t1: Vector3 = tri[1]
				var t2: Vector3 = tri[2]
				var n := (t1 - t0).cross(t2 - t0)
				if n.length_squared() < 1e-12:
					continue
				var centro := (t0 + t1 + t2) / 3.0
				# Para fora do eixo; nas faces quase horizontais, para cima/baixo.
				var fora := Vector3(centro.x, 0, centro.z)
				if fora.length() < 1e-4:
					fora = Vector3(0, signf(centro.y - meio.y) if absf(centro.y - meio.y) > 1e-5 else 1.0, 0)
				if n.dot(fora) > 0.0:
					var tmp := t1
					t1 = t2
					t2 = tmp
				for v: Vector3 in [t0, t1, t2]:
					st.set_uv(Vector2(atan2(v.z, v.x) / TAU, v.y * 4.0))
					st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	mi.material_override = m[mat]
	_add(pai, mi)
	return mi



# --- As dependências e o quintal (playtest 11, R4) -----------------------------------

## Uma viga (uma caixa de seção `esp`) de `a` a `b`, em qualquer direção.
func _viga(mat: String, a: Vector3, b: Vector3, esp: float, cor := Color.WHITE) -> void:
	var d := b - a
	var comp := d.length()
	if comp < 0.001:
		return
	var y := d / comp
	var x := y.cross(Vector3.UP if absf(y.y) < 0.99 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	_bloco(mat, Vector3(esp, comp, esp), (a + b) / 2, cor, false, Basis(x, y, z).get_euler() * 180.0 / PI)


## As ripas sobre as juntas das tábuas (o "board and batten" dos galpões da Nova
## Inglaterra), de `de` a `ate` na face de fora de uma parede (a normal `fora`), de
## `y0` a `y1`, uma a cada `passo`; numa abertura ([centro ao longo da parede,
## largura, base, topo], como as de `_parede`), só acima e abaixo dela.
func _ripas(de: Vector2, ate: Vector2, fora: Vector3, y0: float, y1: float, aberturas := [], passo := 0.42) -> void:
	var compr := de.distance_to(ate)
	var dir := (ate - de) / compr
	var giro := rad_to_deg(atan2(fora.x, fora.z))
	var s := passo * 0.5
	while s < compr - 0.05:
		var p := de + dir * s
		var ao_longo: float = p.x if absf(dir.x) > 0.5 else p.y
		var trechos := [Vector2(y0, y1)]
		for a: Array in aberturas:
			if absf(ao_longo - float(a[0])) < float(a[1]) / 2 + 0.04:
				trechos = [Vector2(y0, a[2]), Vector2(a[3], y1)]
		for t: Vector2 in trechos:
			if t.y - t.x > 0.06:
				_bloco("celeiro", Vector3(0.06, t.y - t.x, 0.025), Vector3(p.x, (t.x + t.y) / 2, p.y) + fora * 0.012,
					Color(0.78, 0.78, 0.78), false, Vector3(0, giro, 0))
		s += passo


## Uma janelinha de galpão vista de fora, em `c` (o meio do vão, na face de fora da
## parede de normal `fora`): o vidro escuro um pouco para dentro, o caixilho em cruz
## e, com `moldura`, a moldura branca e o peitoril.
func _janelinha(c: Vector3, fora: Vector3, larg: float, alto: float, moldura := true) -> void:
	var giro := rad_to_deg(atan2(fora.x, fora.z))
	var b := Basis.from_euler(Vector3(0, deg_to_rad(giro), 0))
	var rot := Vector3(0, giro, 0)
	_bloco("vidro_fazenda", Vector3(larg, alto, 0.01), c + b * Vector3(0, 0, -0.05), Color(0.8, 0.85, 0.9), false, rot)
	_bloco("pintura_branca", Vector3(0.035, alto, 0.03), c + b * Vector3(0, 0, -0.035), Color(0.9, 0.9, 0.9), false, rot)
	_bloco("pintura_branca", Vector3(larg, 0.035, 0.03), c + b * Vector3(0, 0, -0.035), Color(0.9, 0.9, 0.9), false, rot)
	if moldura:
		for s: float in [-1.0, 1.0]:
			_bloco("pintura_branca", Vector3(0.07, alto + 0.14, 0.035), c + b * Vector3(s * (larg / 2 + 0.035), 0, 0.012), Color.WHITE, false, rot)
			_bloco("pintura_branca", Vector3(larg + 0.14, 0.07, 0.035), c + b * Vector3(0, s * (alto / 2 + 0.035), 0.012), Color.WHITE, false, rot)
		_bloco("pintura_branca", Vector3(larg + 0.22, 0.04, 0.09), c + b * Vector3(0, -alto / 2 - 0.085, 0.04), Color.WHITE, false, rot)


## Uma tora de lenha deitada ao longo de Z, de `compr`: os lados de casca escura e
## as pontas claras do corte.
func _tora(mm: Cidade.Malha, c: Vector3, r: float, compr: float) -> void:
	const N := 7
	var casca := Color(0.42, 0.32, 0.24) * _rng.randf_range(0.75, 1.1)
	var corte := Color(1.2, 1.0, 0.7) * _rng.randf_range(0.85, 1.1)
	var giro := _rng.randf() * TAU
	var h := Vector3(0, 0, compr / 2)
	for i in N:
		var u0 := giro + TAU * i / N
		var u1 := giro + TAU * (i + 1) / N
		var p0 := Vector3(cos(u0) * r, sin(u0) * r, 0)
		var p1 := Vector3(cos(u1) * r, sin(u1) * r, 0)
		mm.quad(c + p0 - h, c + p1 - h, c + p1 + h, c + p0 + h, ((p0 + p1) / 2).normalized(), casca)
		for s: float in [-1.0, 1.0]:
			mm.tri(c + h * s, c + p0 + h * s, c + p1 + h * s, Vector3(0, 0, s), corte)


## Uma roda de raios de madeira com o aro de ferro, de eixo em X, em `c`.
func _roda(c: Vector3, raio: float) -> void:
	var aro := _obra("ferro")
	const N := 14
	for i in N:
		var a0 := TAU * i / N
		var a1 := TAU * (i + 1) / N
		var d0 := Vector3(0, sin(a0), cos(a0))
		var d1 := Vector3(0, sin(a1), cos(a1))
		var nn := ((d0 + d1) / 2).normalized()
		for s: float in [-1.0, 1.0]:
			var w := Vector3(s * 0.035, 0, 0)
			aro.quad(c + d0 * raio + w, c + d1 * raio + w, c + d1 * (raio - 0.07) + w, c + d0 * (raio - 0.07) + w, Vector3(s, 0, 0), Color(0.7, 0.6, 0.5))
		aro.quad(c + d0 * raio + Vector3(-0.035, 0, 0), c + d1 * raio + Vector3(-0.035, 0, 0), c + d1 * raio + Vector3(0.035, 0, 0), c + d0 * raio + Vector3(0.035, 0, 0), nn, Color(0.55, 0.55, 0.55))
	for i in 10:
		var a := TAU * i / 10
		_bloco("madeira_clara", Vector3(0.035, raio - 0.08, 0.035), c + Vector3(0, sin(a), cos(a)) * (raio - 0.04) / 2, Color(0.75, 0.65, 0.55), false,
			Vector3(90.0 - rad_to_deg(a), 0, 0))
	_bloco("madeira_escura", Vector3(0.16, 0.12, 0.12), c, Color.WHITE, false)


## A carroça de tábuas do celeiro, ao longo de Z: o leito com os taipais, as quatro
## rodas de raios (as de trás maiores), os eixos e a lança caída no chão.
func _carroca(p: Vector3) -> void:
	var m2 := "madeira_clara"
	_bloco(m2, Vector3(1.3, 0.07, 2.8), p + Vector3(0, 0.88, 0), Color(0.85, 0.8, 0.72), false)
	for s: float in [-1.0, 1.0]:
		_bloco(m2, Vector3(0.04, 0.32, 2.8), p + Vector3(s * 0.63, 1.07, 0), Color(0.8, 0.75, 0.7), false)
		_bloco(m2, Vector3(1.3, 0.32, 0.04), p + Vector3(0, 1.07, s * 1.38), Color(0.8, 0.75, 0.7), false)
		for k in 3:
			_bloco("ferro", Vector3(0.05, 0.36, 0.03), p + Vector3(s * 0.66, 1.07, -1.0 + k), Color(0.6, 0.6, 0.6), false)
	for fz: Array in [[-0.95, 0.42], [0.95, 0.52]]:
		var zr: float = fz[0]
		var r: float = fz[1]
		_bloco("madeira_escura", Vector3(1.75, 0.09, 0.09), p + Vector3(0, r, zr), Color.WHITE, false)
		for s: float in [-1.0, 1.0]:
			_roda(p + Vector3(s * 0.8, r, zr), r)
	_viga("madeira_clara", p + Vector3(0, 0.42, -1.1), p + Vector3(0.1, 0.05, -2.8), 0.07)
	_col.append([Vector3(1.8, 1.25, 3.0), p + Vector3(0, 0.62, 0)])


## O acabamento do canil: as ripas, as cantoneiras e as testeiras brancas, o rodapé
## de pedra atrás e dos lados, os caibros sob o beiral, as portinholas de cada baia
## (articuladas no alto: umas escoradas abertas, outras caídas), as vasilhas com água.
func _canil_acabamento() -> void:
	var x := Vector2(-8.0, 2.8) + Vector2.ONE * CANIL_D.x
	var z := Vector2(-13.0, -10.5) + Vector2.ONE * CANIL_D.z
	var alto := 1.7
	var baia := (x.y - x.x) / CAES.size()
	var bocas := []
	for i in CAES.size():
		bocas.append([x.x + (i + 0.5) * baia, 0.5, 0.0, 0.7])
	_ripas(Vector2(x.x, z.y), Vector2(x.y, z.y), Vector3.BACK, 0.02, alto - 0.3, bocas, 0.3)
	_ripas(Vector2(x.x, z.x), Vector2(x.y, z.x), Vector3.FORWARD, 0.18, alto)
	for s: float in [-1.0, 1.0]:
		var xf: float = x.y if s > 0 else x.x
		_ripas(Vector2(xf, z.x), Vector2(xf, z.y), Vector3(s, 0, 0), 0.18, alto - 0.15)
		_bloco("pedra_campo", Vector3(0.14, 0.18, z.y - z.x + 0.1), Vector3(xf + s * 0.03, 0.09, (z.x + z.y) / 2), Color.WHITE, false)
	_bloco("pedra_campo", Vector3(x.y - x.x + 0.1, 0.18, 0.14), Vector3((x.x + x.y) / 2, 0.09, z.x - 0.03), Color.WHITE, false)
	var branco := "pintura_branca"
	for xf: float in [x.x, x.y]:
		_bloco(branco, Vector3(0.1, alto - 0.3, 0.1), Vector3(xf, (alto - 0.3) / 2, z.y), Color.WHITE, false)
		_bloco(branco, Vector3(0.1, alto, 0.1), Vector3(xf, alto / 2, z.x), Color.WHITE, false)
	# O telhado de uma água cai para a frente (o sul): a testeira da frente, a de
	# trás, e os caibros à vista sob o beiral.
	var ang := rad_to_deg(atan2(0.3, z.y - z.x))
	var meio_x := (x.x + x.y) / 2
	_bloco(branco, Vector3(x.y - x.x + 0.42, 0.13, 0.03), Vector3(meio_x, 1.37, z.y + 0.37), Color.WHITE, false, Vector3(ang, 0, 0))
	_bloco(branco, Vector3(x.y - x.x + 0.42, 0.13, 0.03), Vector3(meio_x, 1.75, z.x - 0.17), Color.WHITE, false, Vector3(ang, 0, 0))
	var xc := x.x + 0.2
	while xc < x.y:
		_bloco("madeira_escura", Vector3(0.05, 0.08, 0.42), Vector3(xc, 1.38, z.y + 0.18), Color(0.8, 0.8, 0.8), false, Vector3(ang, 0, 0))
		xc += 0.6
	# As portinholas.
	for i in CAES.size():
		var cx := x.x + (i + 0.5) * baia
		var giro := -_rng.randf_range(55.0, 80.0) if (i * 7) % 3 != 0 else -_rng.randf_range(2.0, 10.0)
		var g := deg_to_rad(giro)
		var c := Vector3(cx, 0.72, z.y + 0.03) + Vector3(0, -0.36 * cos(g), -0.36 * sin(g))
		_bloco("madeira_escura", Vector3(0.5, 0.72, 0.03), c, Color(0.95, 0.85, 0.8), false, Vector3(giro, 0, 0))
		_bloco("ferro", Vector3(0.52, 0.03, 0.04), Vector3(cx, 0.72, z.y + 0.03), Color(0.6, 0.6, 0.6), false)
	# As vasilhas com água, de zinco, dentro do cercado.
	for p: Vector3 in [Vector3(-6.6, 0, -9.3) + CANIL_D, Vector3(-2.9, 0, -9.6) + CANIL_D]:
		_cilindro("zinco", p + Vector3(0, 0.05, 0), 0.19, 0.1, 10, Color(0.9, 0.9, 0.9))
		_cilindro("agua", p + Vector3(0, 0.085, 0), 0.17, 0.01, 10)


## O resto do acabamento das dependências (R4): o galpão de lenha, o celeiro por
## dentro e as janelinhas, o galinheiro e o chiqueiro, o abrigo do Ford, a estrada
## com os sulcos; e a luz de dentro dos galpões, que acompanha o dia.
func _dependencias_acabamento() -> void:
	var luzes := cena.get_node("LuzesDeDentro")
	var luz := func(nome: String, p: Vector3, energia: float, alcance: float) -> void:
		var l := _omni(luzes, nome, p, Color(1.0, 0.85, 0.7), energia, alcance)
		l.light_specular = 0.0
		l.omni_attenuation = 0.8
	# O galpão de lenha: as ripas por fora, a cantoneira branca, a luz.
	_ripas(Vector2(-13.0, PUXADO_Z.y), Vector2(PUXADO_X.x, PUXADO_Z.y), Vector3.BACK, 0.0, 2.6)
	_ripas(Vector2(-13.0, PUXADO_Z.x), Vector2(-13.0, PUXADO_Z.y), Vector3.LEFT, 0.0, 2.6)
	_bloco("pintura_branca", Vector3(0.1, 2.6, 0.1), Vector3(-13.0, 1.3, PUXADO_Z.y), Color.WHITE, false)
	luz.call("Galpao", Vector3(-11.0, 2.0, 3.8), 0.3, 5.0)
	_deslocado(CELEIRO_D, func() -> void:
		_celeiro_dentro()
		_galinheiro_acabamento())
	luz.call("Celeiro", Vector3(-15.0, 3.6, -11.5) + CELEIRO_D, 0.45, 10.0)
	luz.call("Palheiro", Vector3(-15.0, 4.8, -18.0) + CELEIRO_D, 0.25, 7.0)
	# O abrigo do Ford: as ripas da parede do fundo.
	_deslocado(FORD_D, func() -> void:
		_ripas(Vector2(9.0, -18.0), Vector2(15.0, -18.0), Vector3.FORWARD, 0.0, 2.6))
	_estrada_acabamento()


## O celeiro por dentro: a estrutura à vista (os esteios junto às paredes, as
## linhas de amarração com as mãos-francesas, os caibros e a cumeeira), a escada do
## palheiro, os fardos de feno no palheiro e no chão, o feno solto, as frentes das
## baias e as manjedouras, o forcado, os latões de leite; as janelinhas com o vidro
## e a porta do lado leste, aberta, encostada na parede.
func _celeiro_dentro() -> void:
	var x := Vector2(-21.0, -9.0)
	var z := Vector2(-21.0, -8.0)
	var alto := 5.0
	var cume := Vector2(-15.0, alto + 3.6)
	var m2 := "madeira_escura"
	var cor := Color(0.85, 0.78, 0.7)
	var zz := z.x + 1.0
	while zz < z.y - 0.5:
		for xx: float in [x.x + 0.26, x.y - 0.26]:
			_bloco(m2, Vector3(0.2, alto, 0.2), Vector3(xx, alto / 2, zz), cor, false)
			var s := 1.0 if xx < cume.x else -1.0
			_viga(m2, Vector3(xx + s * 0.1, alto - 1.2, zz), Vector3(xx + s * 1.1, alto - 0.2, zz), 0.12, cor)
		_bloco(m2, Vector3(x.y - x.x - 0.3, 0.2, 0.2), Vector3(cume.x, alto - 0.1, zz), cor, false)
		zz += 3.0
	var zc := z.x + 0.4
	while zc < z.y - 0.2:
		for borda: float in [x.x, x.y]:
			_viga(m2, Vector3(borda, alto - 0.1, zc), Vector3(cume.x, cume.y - 0.16, zc), 0.1, cor * 0.9)
		zc += 1.3
	_bloco(m2, Vector3(0.14, 0.22, z.y - z.x), Vector3(cume.x, cume.y - 0.22, (z.x + z.y) / 2), cor, false)
	# A escada do palheiro (a borda dele em z -15.9, a 3 m).
	var pe := Vector3(-14.4, 0.0, -15.25)
	var topo := Vector3(-14.4, 3.45, -15.95)
	for s: float in [-1.0, 1.0]:
		_viga("madeira_clara", pe + Vector3(s * 0.22, 0, 0), topo + Vector3(s * 0.22, 0, 0), 0.06, Color(0.8, 0.75, 0.7))
	for k in 10:
		_bloco("madeira_clara", Vector3(0.44, 0.04, 0.04), pe.lerp(topo, (k + 1) / 11.0), Color(0.8, 0.75, 0.7), false)
	# Os fardos: a frente da meda no palheiro, em duas fiadas, e uma pilha no chão.
	for fiada in 2:
		for k in 8:
			var b := Vector3(-19.4 + k * 1.0 + _rng.randf_range(-0.08, 0.08) + fiada * 0.4, 3.27 + fiada * 0.4, -16.1 + _rng.randf_range(-0.05, 0.05))
			if fiada == 1 and k > 5:
				continue
			_bloco("palha", Vector3(0.9, 0.4, 0.45), b, Color(1.05, 1.0, 0.88) * _rng.randf_range(0.85, 1.05), false, Vector3(0, _rng.randf_range(-6, 6), 0))
	for k in 3:
		var b := Vector3(-20.3, 0.2 + (k / 2) * 0.4, -9.4 + (k % 2) * 0.55 + (k / 2) * 0.25)
		_bloco("palha", Vector3(0.45, 0.4, 0.9), b, Color(1.05, 1.0, 0.88) * _rng.randf_range(0.85, 1.05), false, Vector3(0, _rng.randf_range(-8, 8), 0))
	_col.append([Vector3(0.6, 0.8, 1.6), Vector3(-20.3, 0.4, -9.1)])
	for k in 7:
		_bloco("palha", Vector3(_rng.randf_range(0.8, 1.6), 0.025, _rng.randf_range(0.6, 1.2)),
			Vector3(_rng.randf_range(-20.0, -16.0), 0.05, _rng.randf_range(-20.0, -10.0)), Color(0.9, 0.85, 0.75), false, Vector3(0, _rng.randf_range(0, 180), 0))
	# As baias (as divisórias já existem, em z -14.8, -12.8, -10.8): os esteios da
	# frente, a travessa, e as manjedouras contra a parede oeste.
	for zb: float in [-14.8, -12.8, -10.8]:
		_bloco(m2, Vector3(0.14, 1.5, 0.14), Vector3(-18.45, 0.75, zb), cor, false)
	_bloco(m2, Vector3(0.08, 0.1, 4.1), Vector3(-18.45, 1.45, -12.8), cor, false)
	for zb: float in [-14.8, -12.8]:
		_bloco(m2, Vector3(0.5, 0.45, 1.6), Vector3(-20.55, 0.85, zb + 1.0), cor, false)
		_bloco("palha", Vector3(0.42, 0.06, 1.5), Vector3(-20.55, 1.08, zb + 1.0), Color.WHITE, false)
		_col.append([Vector3(0.5, 1.1, 1.6), Vector3(-20.55, 0.55, zb + 1.0)])
	# O forcado encostado na parede leste, perto do portão.
	var cabo0 := Vector3(-9.6, 0.02, -9.6)
	var cabo1 := Vector3(-9.25, 1.55, -9.6)
	_viga("madeira_clara", cabo0, cabo1, 0.035, Color(0.85, 0.75, 0.6))
	var d := (cabo1 - cabo0).normalized()
	_bloco("ferro", Vector3(0.03, 0.03, 0.2), cabo1, Color(0.6, 0.6, 0.6), false)
	for k in 4:
		var bt := cabo1 + Vector3(0, 0, (k - 1.5) * 0.06)
		_viga("ferro", bt, bt + d * 0.32, 0.012, Color(0.6, 0.6, 0.6))
	# Os latões de leite.
	for p: Vector3 in [Vector3(-10.0, 0, -8.7), Vector3(-10.42, 0, -8.8)]:
		_cilindro("zinco", p + Vector3(0, 0.25, 0), 0.16, 0.5, 10)
		_cilindro("zinco", p + Vector3(0, 0.55, 0), 0.1, 0.1, 10)
		_cilindro("zinco", p + Vector3(0, 0.62, 0), 0.115, 0.04, 10, Color(0.85, 0.85, 0.85))
	_col.append([Vector3(0.8, 0.65, 0.4), Vector3(-10.2, 0.32, -8.75)])
	# As janelinhas (a moldura branca é do _celeiro_acabamento).
	_janelinha(Vector3(-12.0, 1.9, z.x), Vector3.FORWARD, 0.6, 0.8, false)
	_janelinha(Vector3(x.x, 1.9, -14.5), Vector3.LEFT, 0.6, 0.8, false)
	_janelinha(Vector3(x.y, 1.9, -17.5), Vector3.RIGHT, 0.6, 0.8, false)
	# A porta do lado leste: a moldura branca e a folha de tábuas aberta, encostada
	# na parede ao norte do vão.
	for s: float in [-1.0, 1.0]:
		_bloco("pintura_branca", Vector3(0.04, 2.2, 0.1), Vector3(x.y + 0.02, 1.1, -12.0 + s * 0.55), Color.WHITE, false)
	_bloco("pintura_branca", Vector3(0.04, 0.1, 1.2), Vector3(x.y + 0.02, 2.15, -12.0), Color.WHITE, false)
	_bloco("celeiro", Vector3(0.05, 2.05, 0.98), Vector3(x.y + 0.06, 1.04, -13.08), Color(0.9, 0.9, 0.9), false)
	for y: float in [0.4, 1.0, 1.6]:
		_bloco("pintura_branca", Vector3(0.02, 0.08, 0.9), Vector3(x.y + 0.095, y, -13.08), Color.WHITE, false)


## O galinheiro e o chiqueiro: as ripas, as cantoneiras, as janelinhas, a porta
## aberta, o buraco das galinhas com a rampa; no cercado, a lama e o cocho.
func _galinheiro_acabamento() -> void:
	var x := Vector2(-27.0, -21.0)
	var z := Vector2(-19.0, -11.0)
	var alto := 2.4
	_ripas(Vector2(x.x, z.y), Vector2(x.y, z.y), Vector3.BACK, 0.0, alto, [[-25.5, 0.8, 0.0, 1.9], [-22.8, 0.6, 1.1, 1.7], [-24.0, 0.3, 0.0, 0.5]])
	_ripas(Vector2(x.x, z.x), Vector2(x.y, z.x), Vector3.FORWARD, 0.0, alto)
	_ripas(Vector2(x.x, z.x), Vector2(x.x, z.y), Vector3.LEFT, 0.0, alto, [[-15.0, 0.6, 1.1, 1.7]])
	for zf: float in [z.x, z.y]:
		_bloco("pintura_branca", Vector3(0.1, alto, 0.1), Vector3(x.x, alto / 2, zf), Color.WHITE, false)
	_janelinha(Vector3(-22.8, 1.4, z.y), Vector3.BACK, 0.6, 0.6)
	_janelinha(Vector3(x.x, 1.4, -15.0), Vector3.LEFT, 0.6, 0.6)
	# A porta: a moldura e a folha aberta contra a parede, a oeste do vão.
	for s: float in [-1.0, 1.0]:
		_bloco("pintura_branca", Vector3(0.08, 1.98, 0.04), Vector3(-25.5 + s * 0.44, 0.99, z.y + 0.02), Color.WHITE, false)
	_bloco("pintura_branca", Vector3(0.96, 0.08, 0.04), Vector3(-25.5, 1.94, z.y + 0.02), Color.WHITE, false)
	_bloco("celeiro", Vector3(0.78, 1.88, 0.04), Vector3(-26.36, 0.95, z.y + 0.07), Color(0.9, 0.9, 0.9), false)
	# O buraco das galinhas e a rampa com as travessinhas.
	_bloco("esmalte_preto", Vector3(0.28, 0.32, 0.02), Vector3(-24.0, 0.3, z.y + 0.005), Color.WHITE, false)
	_bloco("madeira_clara", Vector3(0.3, 0.025, 0.85), Vector3(-24.0, 0.13, z.y + 0.42), Color(0.85, 0.8, 0.7), false, Vector3(17, 0, 0))
	for k in 4:
		_bloco("madeira_clara", Vector3(0.3, 0.02, 0.02), Vector3(-24.0, 0.2 - k * 0.055, z.y + 0.2 + k * 0.18), Color(0.8, 0.75, 0.65), false)
	# O chiqueiro: a lama e o cocho.
	_bloco("chao_terra", Vector3(5.8, 0.02, 3.8), Vector3(-24.0, 0.012, z.y + 2.0), Color(0.62, 0.52, 0.42), false)
	_bloco("madeira_escura", Vector3(1.3, 0.22, 0.4), Vector3(-22.6, 0.11, z.y + 3.4), Color(0.9, 0.85, 0.8), false)
	_bloco("chao_terra", Vector3(1.2, 0.01, 0.3), Vector3(-22.6, 0.222, z.y + 3.4), Color(0.45, 0.38, 0.3), false)


## A estrada (R4): os dois sulcos das rodas, mais escuros, a faixa de capim no meio e
## a grama comendo as beiras, tudo ondulando um pouco ao longo do caminho.
func _estrada_acabamento() -> void:
	var meio := (ESTRADA_X.x + ESTRADA_X.y) / 2
	var sulco := _obra("estrada")
	var capim := _obra("grama")
	var faixas := [[meio - 0.9, 0.38, sulco, Color(0.6, 0.55, 0.52), 0.045], [meio + 0.52, 0.38, sulco, Color(0.6, 0.55, 0.52), 0.045],
		[meio - 0.3, 0.6, capim, Color(0.5, 0.56, 0.3), 0.05], [ESTRADA_X.x - 0.05, 0.45, capim, Color(0.42, 0.5, 0.27), 0.05],
		[ESTRADA_X.y - 0.4, 0.45, capim, Color(0.42, 0.5, 0.27), 0.05]]
	var z := -230.0
	while z < 230.0:
		var z1 := z + (2.0 if absf(z) < 70.0 else 10.0)
		for f: Array in faixas:
			var w: float = f[1]
			var dy: float = f[4]
			var x0 := float(f[0]) + sin(z * 0.11 + w * 9.0) * 0.12
			var x1 := float(f[0]) + sin(z1 * 0.11 + w * 9.0) * 0.12
			var a := Vector3(x0, _altura(x0, z) + dy, z)
			var b := Vector3(x0 + w, _altura(x0 + w, z) + dy, z)
			var c := Vector3(x1 + w, _altura(x1 + w, z1) + dy, z1)
			var d := Vector3(x1, _altura(x1, z1) + dy, z1)
			(f[2] as Cidade.Malha).quad(a, b, c, d, Vector3.UP, f[3])
		z = z1


## A linha do telefone (a que "eles cortam", livro): os postes de castanheiro ao
## longo da estrada, do lado da casa, com a cruzeta, os isoladores de vidro e os fios
## que caem um pouco entre um e outro; e o ramal que atravessa o gramado até a
## parede leste da casa.
func _postes() -> void:
	var xp := ESTRADA_X.x - 1.3
	var topos: Array[Vector3] = []
	var z := -220.0
	while z <= 220.0:
		var p := Vector3(xp + _rng.randf_range(-0.15, 0.15), _altura(xp, z), z)
		var inclina := Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(-1.5, 1.5))
		_bloco("madeira_escura", Vector3(0.2, 7.2, 0.2), p + Vector3(0, 3.5, 0), Color(0.8, 0.75, 0.7), false, inclina)
		_bloco("madeira_escura", Vector3(1.3, 0.1, 0.1), p + Vector3(0, 6.75, 0), Color(0.85, 0.8, 0.75), false)
		for s: float in [-1.0, 1.0]:
			_cilindro("vidro_fazenda", p + Vector3(s * 0.5, 6.86, 0), 0.04, 0.12, 6, Color(1.4, 1.8, 1.6))
		topos.append(p + Vector3(0, 6.92, 0))
		if absf(z) < 60.0:
			_col.append([Vector3(0.25, 7.0, 0.25), p + Vector3(0, 3.5, 0)])
		z += 36.0
	var fio := func(a: Vector3, b: Vector3, cai: float) -> void:
		var antes := a
		for k in 4:
			var t := (k + 1) / 4.0
			var q := a.lerp(b, t) - Vector3(0, cai * 4.0 * t * (1.0 - t), 0)
			_viga("esmalte_preto", antes, q, 0.014)
			antes = q
	for i in topos.size() - 1:
		for s: float in [-1.0, 1.0]:
			fio.call(topos[i] + Vector3(s * 0.5, 0, 0), topos[i + 1] + Vector3(s * 0.5, 0, 0), 0.45)
	# O ramal: do poste mais perto da casa até o isolador na parede leste, no alto.
	var perto := topos[0]
	for t: Vector3 in topos:
		if absf(t.z) < absf(perto.z):
			perto = t
	var parede := Vector3(CASA_X.y + 0.15, T1 + 1.6, -1.6)
	_bloco("ferro", Vector3(0.3, 0.03, 0.03), parede + Vector3(-0.15, 0, 0), Color(0.6, 0.6, 0.6), false)
	_cilindro("vidro_fazenda", parede + Vector3(0, 0.05, 0), 0.04, 0.1, 6, Color(1.4, 1.8, 1.6))
	fio.call(perto + Vector3(-0.5, 0, 0), parede + Vector3(0, 0.08, 0), 0.9)
