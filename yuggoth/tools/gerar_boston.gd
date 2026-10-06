extends "res://tools/gerador_base.gd"
## Monta levels/boston/boston.tscn: o quarto de pensão do funcionário do
## expresso, em Boston, na noite de 20 de julho de 1928 (livro cap. III). Rodar
## da pasta yuggoth/, depois de gerar_escritorio (usa os materiais dele):
##   godot --headless res://tools/gerar_boston.tscn
##
## Coordenadas: quarto de x -2..2 (oeste..leste), z -2,25..2,25 (norte..sul),
## piso em y 0. A porta ao sul; a janela ao norte, para os telhados.

const OUT := "res://levels/boston/boston.tscn"

const W := 2.0
const D := 2.25
const H := 2.7
const JANELA_X := Vector2(0.15, 1.15)
const JANELA_Y := Vector2(0.9, 2.1)
const PORTA_X := -1.0


func _ready() -> void:
	_carregar_materiais()
	_mat("pele", "papel", {world = 6.0, cor = Color(0.95, 0.72, 0.6)})
	_mat("cabelo", "la_escura", {world = 6.0, cor = Color(1.6, 1.2, 0.85)})
	_mat("camisa", "lencol", {world = 3.0, cor = Color(1.08, 1.06, 1.0)})
	_mat("colete", "la_escura", {world = 3.0, cor = Color(1.3, 1.25, 1.5)})
	_mat("parede_pensao", "papel_parede", {world = 1.6, cor = Color(1.05, 0.92, 0.78)})
	_mat("vista_boston", "vista_boston", {unlit = true})

	cena = Node3D.new()
	cena.name = "Boston"
	cena.set_script(load("res://levels/boston/boston.gd"))
	cena.set("linha_chegada", load("res://narrative/narration/boston_chegada.tres"))
	cena.set("som", load(SFX_DIR + "noite.wav"))

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = _env()
	_add(cena, env)

	_quarto()
	_mobilia()
	_funcionario()

	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector3(PORTA_X, 0, 1.6)
	player.rotation_degrees.y = -36
	_add(cena, player)
	var entrada := Marker3D.new()
	entrada.name = "Entrada"
	entrada.position = player.position
	entrada.rotation_degrees.y = -36
	_add(cena, entrada)
	entrada.add_to_group(&"spawn", true)

	_salvar(OUT)


## Noite de julho: escuro fora do círculo do abajur, um pouco de névoa.
func _env() -> Environment:
	var e := _pos(Environment.new())
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.05, 0.045, 0.05)
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.02, 0.02, 0.03)
	e.fog_density = 1.0
	e.fog_depth_begin = 2.5
	e.fog_depth_end = 9.0
	return e


func _quarto() -> void:
	var q := _group(cena, "Quarto")
	var s := 0.2  # as superfícies passam umas das outras por fora (frestas do tremor)
	_quad(q, "Piso", Vector2(2 * W + s, 2 * D + s), Vector3.ZERO, Vector3(-90, 0, 0), "piso")
	_quad(q, "Teto", Vector2(2 * W + s, 2 * D + s), Vector3(0, H, 0), Vector3(90, 0, 0), "teto")
	_quad(q, "ParedeOeste", Vector2(2 * D + s, H + s), Vector3(-W, H / 2, 0), Vector3(0, 90, 0), "parede_pensao")
	_quad(q, "ParedeLeste", Vector2(2 * D + s, H + s), Vector3(W, H / 2, 0), Vector3(0, -90, 0), "parede_pensao")
	_quad(q, "ParedeSul", Vector2(2 * W + s, H + s), Vector3(0, H / 2, D), Vector3(0, 180, 0), "parede_pensao")
	# Norte em pedaços, em volta da janela.
	var t := 0.15
	var oeste := JANELA_X.x + W
	var leste := W - JANELA_X.y
	_box(q, "NorteO", Vector3(oeste + s / 2, H + s, t), Vector3(-W + oeste / 2 - s / 4, H / 2, -D - t / 2), "parede_pensao")
	_box(q, "NorteL", Vector3(leste + s / 2, H + s, t), Vector3(W - leste / 2 + s / 4, H / 2, -D - t / 2), "parede_pensao")
	var larg := JANELA_X.y - JANELA_X.x
	var meio := (JANELA_X.x + JANELA_X.y) / 2
	_box(q, "NorteBaixo", Vector3(larg, JANELA_Y.x, t), Vector3(meio, JANELA_Y.x / 2, -D - t / 2), "parede_pensao")
	_box(q, "NorteAlto", Vector3(larg, H + s / 2 - JANELA_Y.y, t), Vector3(meio, (H + s / 2 + JANELA_Y.y) / 2, -D - t / 2), "parede_pensao")
	var r := 0.1
	_box(q, "RodapeO", Vector3(0.03, r, 2 * D), Vector3(-W + 0.015, r / 2, 0), "madeira_escura")
	_box(q, "RodapeL", Vector3(0.03, r, 2 * D), Vector3(W - 0.015, r / 2, 0), "madeira_escura")
	_box(q, "RodapeN", Vector3(2 * W, r, 0.03), Vector3(0, r / 2, -D + 0.015), "madeira_escura")
	_box(q, "RodapeS", Vector3(2 * W, r, 0.03), Vector3(0, r / 2, D - 0.015), "madeira_escura")

	# Janela de guilhotina e os telhados de Boston à noite.
	var j := _group(q, "Janela", Vector3(meio, 0, -D))
	_box(j, "Peitoril", Vector3(larg + 0.14, 0.05, 0.2), Vector3(0, JANELA_Y.x, 0.03), "madeira_clara")
	_box(j, "Verga", Vector3(larg + 0.1, 0.08, 0.12), Vector3(0, JANELA_Y.y + 0.04, -0.04), "madeira_clara")
	_box(j, "Travessa", Vector3(larg, 0.05, 0.05), Vector3(0, (JANELA_Y.x + JANELA_Y.y) / 2, -0.06), "madeira_clara")
	for lado in [-1, 1]:
		_box(j, "Batente%d" % lado, Vector3(0.06, JANELA_Y.y - JANELA_Y.x, 0.12), Vector3(lado * (larg / 2 + 0.02), (JANELA_Y.x + JANELA_Y.y) / 2, -0.04), "madeira_clara")
	_quad(q, "Vista", Vector2(4.0, 2.4), Vector3(meio, 1.5, -D - 1.0), Vector3.ZERO, "vista_boston")
	_omni(q, "Lua", Vector3(meio, 1.8, -D + 0.3), Color(0.5, 0.6, 0.9), 0.35, 4.0)

	# A porta, por onde Wilmarth entrou e sai.
	var p := _group(q, "Porta", Vector3(PORTA_X, 0, D))
	_box(p, "Folha", Vector3(0.86, 2.05, 0.05), Vector3(0, 1.025, -0.03), "madeira_escura")
	_quad(p, "Frente", Vector2(0.86, 2.05), Vector3(0, 1.025, -0.06), Vector3(0, 180, 0), "porta")
	_box(p, "Macaneta", Vector3(0.05, 0.05, 0.06), Vector3(0.33, 1.0, -0.1), "latao")
	var sair := _area(q, Interactable.new(), "Saida", Vector3(0.86, 2.0, 0.2), Vector3(PORTA_X, 1.05, D - 0.12)) as Interactable
	sair.unique_name_in_owner = true
	sair.prompt = "Voltar a Arkham"
	sair.condition = _flag(&"ligou_boston_reconhecer")

	_colisao(q, "Colisao", [
		[Vector3(2 * W, 0.2, 2 * D), Vector3(0, -0.1, 0)],
		[Vector3(2 * W, 0.2, 2 * D), Vector3(0, H + 0.1, 0)],
		[Vector3(0.2, H, 2 * D), Vector3(-W - 0.1, H / 2, 0)],
		[Vector3(0.2, H, 2 * D), Vector3(W + 0.1, H / 2, 0)],
		[Vector3(2 * W, H, 0.2), Vector3(0, H / 2, D + 0.1)],
		[Vector3(2 * W, H, 0.2), Vector3(0, H / 2, -D - 0.1)],
	])


func _mobilia() -> void:
	var mob := _group(cena, "Mobilia")
	# Cama de ferro junto à parede oeste.
	var cama := _group(mob, "Cama", Vector3(-1.5, 0, -0.75))
	_box(cama, "Colchao", Vector3(0.9, 0.18, 1.9), Vector3(0, 0.5, 0), "lencol")
	_box(cama, "Coberta", Vector3(0.94, 0.04, 1.3), Vector3(0, 0.6, 0.28), "la_escura")
	_box(cama, "Travesseiro", Vector3(0.6, 0.1, 0.3), Vector3(0, 0.63, -0.75), "lencol")
	for z in [-0.97, 0.97]:
		var alto := 1.0 if z < 0 else 0.75
		for x in [-0.45, 0.45]:
			_cyl(cama, "Pe%d%d" % [signf(x), signf(z)], 0.018, 0.018, alto, Vector3(x, alto / 2, z), "ferro", 6)
		var barra := _cyl(cama, "Barra%d" % signf(z), 0.015, 0.015, 0.9, Vector3(0, alto - 0.05, z), "ferro", 6)
		barra.rotation_degrees.z = 90
	_colisao(cama, "Colisao", [[Vector3(0.95, 0.65, 1.95), Vector3(0, 0.33, 0)]])

	# A mesa junto à janela, com o abajur de cúpula de pano.
	var mesa := _group(mob, "Mesa", Vector3(0.5, 0, -1.2))
	_box(mesa, "Tampo", Vector3(0.8, 0.04, 0.6), Vector3(0, 0.74, 0), "madeira_escura")
	for x in [-0.36, 0.36]:
		for z in [-0.26, 0.26]:
			_box(mesa, "Perna%d%d" % [signf(x), signf(z)], Vector3(0.04, 0.72, 0.04), Vector3(x, 0.36, z), "madeira_escura")
	_colisao(mesa, "Colisao", [[Vector3(0.8, 0.76, 0.6), Vector3(0, 0.38, 0)]])
	var abajur := _group(mesa, "Abajur", Vector3(-0.22, 0.76, -0.16))
	_cyl(abajur, "Base", 0.06, 0.07, 0.03, Vector3(0, 0.015, 0), "latao", 8)
	_cyl(abajur, "Haste", 0.01, 0.01, 0.3, Vector3(0, 0.17, 0), "latao", 6)
	_cyl(abajur, "Cupula", 0.07, 0.13, 0.15, Vector3(0, 0.33, 0), "vidro_aceso", 8)
	var luz := _omni(abajur, "Luz", Vector3(0, 0.3, 0), Color(1.0, 0.74, 0.48), 1.9, 5.0)
	luz.shadow_enabled = true
	luz.omni_attenuation = 1.3
	# Na mesa: o boné do expresso ao lado, um copo e um jornal dobrado.
	_cyl(mesa, "Copo", 0.03, 0.025, 0.09, Vector3(0.18, 0.805, 0.12), "vidro_verde", 8)
	var jornal := _box(mesa, "Jornal", Vector3(0.3, 0.008, 0.22), Vector3(0.05, 0.764, 0.05), "papel")
	jornal.rotation_degrees.y = 14

	# As duas cadeiras: a do rapaz (leste, de frente para a sala) e a vazia.
	for c: Array in [["CadeiraRapaz", Vector3(1.05, 0, -1.15), 90.0], ["CadeiraVazia", Vector3(-0.05, 0, -1.2), -90.0]]:
		var cad := _group(mob, c[0], c[1], c[2])
		_box(cad, "Assento", Vector3(0.44, 0.04, 0.42), Vector3(0, 0.46, 0), "madeira_clara")
		for x in [-0.19, 0.19]:
			for z in [-0.18, 0.18]:
				_box(cad, "Perna%d%d" % [signf(x), signf(z)], Vector3(0.035, 0.46, 0.035), Vector3(x, 0.23, z), "madeira_clara")
		_box(cad, "Encosto", Vector3(0.44, 0.4, 0.035), Vector3(0, 0.7, 0.19), "madeira_clara")
		_colisao(cad, "Colisao", [[Vector3(0.45, 0.9, 0.45), Vector3(0, 0.45, 0)]])

	# Lavatório na parede leste: o móvel, a bacia e o jarro.
	var lav := _group(mob, "Lavatorio", Vector3(W - 0.25, 0, 0.7))
	_box(lav, "Movel", Vector3(0.45, 0.8, 0.5), Vector3(0, 0.4, 0), "madeira_escura")
	_cyl(lav, "Bacia", 0.17, 0.11, 0.08, Vector3(0, 0.84, 0), "lencol", 10)
	_cyl(lav, "Jarro", 0.05, 0.07, 0.22, Vector3(0.12, 0.91, 0.14), "lencol", 8)
	_colisao(lav, "Colisao", [[Vector3(0.45, 0.8, 0.5), Vector3(0, 0.4, 0)]])

	# O gancho na parede leste, com o paletó e o boné do American Railway Express.
	var gancho := _group(mob, "Gancho", Vector3(W - 0.03, 1.7, 1.55))
	_box(gancho, "Tabua", Vector3(0.03, 0.08, 0.5), Vector3.ZERO, "madeira_escura")
	var paleto := _box(gancho, "Paleto", Vector3(0.1, 0.75, 0.42), Vector3(-0.07, -0.36, 0.08), "colete")
	paleto.rotation_degrees.x = 3
	_cyl(gancho, "Bone", 0.09, 0.1, 0.07, Vector3(-0.08, 0.02, -0.15), "colete", 8)
	_box(gancho, "Pala", Vector3(0.1, 0.01, 0.07), Vector3(-0.16, -0.01, -0.15), "ferro")


## O funcionário, sentado na cadeira dele, as mãos na mesa (frente para -Z antes
## de girar o grupo). Boneco provisório de primitivas: um rapaz de camisa e
## colete, cabelo curto (docs/ARTE.md).
func _funcionario() -> void:
	var f := _group(cena, "Funcionario", Vector3(1.05, 0, -1.15), 90)
	for x in [-0.1, 0.1]:
		var lado := "E" if x < 0 else "D"
		_box(f, "Sapato" + lado, Vector3(0.1, 0.08, 0.24), Vector3(x, 0.04, -0.42), "esmalte_preto")
		_box(f, "Canela" + lado, Vector3(0.11, 0.42, 0.12), Vector3(x, 0.27, -0.4), "colete")
		_box(f, "Coxa" + lado, Vector3(0.14, 0.13, 0.44), Vector3(x, 0.53, -0.21), "colete")
	_box(f, "Quadril", Vector3(0.36, 0.16, 0.24), Vector3(0, 0.55, 0.02), "colete")
	_box(f, "Camisa", Vector3(0.37, 0.5, 0.21), Vector3(0, 0.86, 0.04), "camisa")
	_box(f, "Colete", Vector3(0.385, 0.32, 0.225), Vector3(0, 0.8, 0.04), "colete")
	_cyl(f, "Pescoco", 0.05, 0.05, 0.09, Vector3(0, 1.15, 0.04), "pele", 6)
	_cyl(f, "Cabeca", 0.085, 0.092, 0.2, Vector3(0, 1.29, 0.03), "pele", 8)
	_cyl(f, "Cabelo", 0.06, 0.098, 0.08, Vector3(0, 1.41, 0.045), "cabelo", 8)
	for x in [-0.034, 0.034]:
		_box(f, "Olho%d" % signf(x), Vector3(0.022, 0.012, 0.01), Vector3(x, 1.31, -0.058), "esmalte_preto")
	_box(f, "Nariz", Vector3(0.022, 0.04, 0.03), Vector3(0, 1.28, -0.085), "pele")
	for x in [-0.235, 0.235]:
		var lado := "E" if x < 0 else "D"
		_box(f, "Braco" + lado, Vector3(0.09, 0.3, 0.1), Vector3(x, 0.95, 0.04), "camisa")
		_box(f, "Antebraco" + lado, Vector3(0.08, 0.08, 0.3), Vector3(x * 0.92, 0.79, -0.13), "camisa")
		_box(f, "Mao" + lado, Vector3(0.08, 0.05, 0.1), Vector3(x * 0.85, 0.785, -0.32), "pele")
	_colisao(f, "Colisao", [[Vector3(0.5, 1.45, 0.6), Vector3(0, 0.72, -0.1)]])

	var fala := _area(f, Interlocutor.new(), "Conversa", Vector3(0.6, 1.0, 0.6), Vector3(0, 1.0, -0.05)) as Interlocutor
	fala.unique_name_in_owner = true
	var conversas: Array[Ligacao] = []
	for id in ["boston_homem", "boston_voz", "boston_reconhecer"]:
		conversas.append(load("res://narrative/ligacoes/%s.tres" % id))
	fala.conversas = conversas
	fala.voz = load(SFX_DIR + "voz_sala.wav")
	fala.voz_db = -12.0
