extends "res://tools/gerador_base.gd"
## Monta levels/boston/boston.tscn: o corredor da pensão onde mora o funcionário
## do expresso, em Boston, na noite de 20 de julho de 1928 (livro cap. III).
## Wilmarth bate à porta do quarto; o rapaz abre uma fresta e responde dali,
## franco e gentil, sem convidar a entrar. Rodar da pasta yuggoth/, depois de
## gerar_escritorio (usa os materiais dele):
##   godot --headless res://tools/gerar_boston.tscn
##
## Coordenadas: corredor de x -0,7..0,7, z -3,5..3 (norte..sul), piso em y 0. A
## escada ao sul (por onde se chega e se vai); a porta do rapaz na parede leste;
## o quarto dele atrás dela (só se vê pela fresta). A folha gira para dentro do
## quarto (+X): rotação positiva em Y, com a dobradiça ao norte.

const OUT := "res://levels/boston/boston.tscn"

const W := 0.7
const D_N := 3.5
const D_S := 3.0
const H := 2.6
## A porta do quarto, na parede leste: de z PORTA_Z.x (dobradiça) a PORTA_Z.y.
const PORTA_Z := Vector2(-1.95, -1.05)
const PORTA_H := 2.05
## Quanto a porta abre, em graus: uma fresta.
const FRESTA := 50.0


func _ready() -> void:
	_carregar_materiais()
	_mat("pele", "papel", {world = 6.0, cor = Color(0.95, 0.72, 0.6)})
	_mat("cabelo", "la_escura", {world = 6.0, cor = Color(1.6, 1.2, 0.85)})
	_mat("camisa", "lencol", {world = 3.0, cor = Color(1.08, 1.06, 1.0)})
	_mat("colete", "la_escura", {world = 3.0, cor = Color(1.3, 1.25, 1.5)})
	_mat("parede_pensao", "papel_parede", {world = 1.6, cor = Color(1.05, 0.92, 0.78)})

	cena = Node3D.new()
	cena.name = "Boston"
	cena.set_script(load("res://levels/boston/boston.gd"))
	cena.set("linha_chegada", load("res://narrative/narration/boston_chegada.tres"))
	cena.set("som", load(SFX_DIR + "noite.wav"))
	cena.set("som_rangido", load(SFX_DIR + "porta_rangendo.wav"))
	cena.set("fresta", FRESTA)

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = _env()
	_add(cena, env)

	_corredor()
	_porta_do_quarto()
	_quarto()
	_funcionario()

	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector3(0, 0, 2.3)
	_add(cena, player)
	var entrada := Marker3D.new()
	entrada.name = "Entrada"
	entrada.position = player.position
	_add(cena, entrada)
	entrada.add_to_group(&"spawn", true)

	_salvar(OUT)


## Noite de julho: o corredor na penumbra de uma arandela; a luz quente do
## quarto vaza pela fresta.
func _env() -> Environment:
	var e := _pos(Environment.new())
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.045, 0.04, 0.045)
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.02, 0.02, 0.025)
	e.fog_density = 1.0
	e.fog_depth_begin = 3.0
	e.fog_depth_end = 9.0
	return e


func _corredor() -> void:
	var c := _group(cena, "Corredor")
	var s := 0.2
	var comp := D_N + D_S
	var meio_z := (D_S - D_N) / 2
	_quad(c, "Piso", Vector2(2 * W + s, comp + s), Vector3(0, 0, meio_z), Vector3(-90, 0, 0), "piso")
	_quad(c, "Passadeira", Vector2(0.8, comp - 0.4), Vector3(0, 0.005, meio_z), Vector3(-90, 0, 0), "tapete")
	_quad(c, "Teto", Vector2(2 * W + s, comp + s), Vector3(0, H, meio_z), Vector3(90, 0, 0), "teto")
	_quad(c, "ParedeOeste", Vector2(comp + s, H + s), Vector3(-W, H / 2, meio_z), Vector3(0, 90, 0), "parede_pensao")
	# Leste em pedaços, em volta da porta do rapaz.
	var sul := D_S - PORTA_Z.y
	_quad(c, "LesteSul", Vector2(sul + s / 2, H + s), Vector3(W, H / 2, (D_S + PORTA_Z.y) / 2 + s / 4), Vector3(0, -90, 0), "parede_pensao")
	var norte := PORTA_Z.x + D_N
	_quad(c, "LesteNorte", Vector2(norte + s / 2, H + s), Vector3(W, H / 2, (-D_N + PORTA_Z.x) / 2 - s / 4), Vector3(0, -90, 0), "parede_pensao")
	_quad(c, "LesteAlto", Vector2(PORTA_Z.y - PORTA_Z.x, H + s / 2 - PORTA_H), Vector3(W, (H + s / 2 + PORTA_H) / 2, (PORTA_Z.x + PORTA_Z.y) / 2), Vector3(0, -90, 0), "parede_pensao")
	# Rodapé.
	for lado in [-1, 1]:
		_box(c, "Rodape%d" % lado, Vector3(0.03, 0.1, comp), Vector3(lado * (W - 0.015), 0.05, meio_z), "madeira_escura")

	# A janelinha do fim do corredor, para os telhados de Boston — em 3D (Fase
	# 3e): a parede norte em pedaços em volta do vão, e a cidade lá fora.
	var vao := Vector2(0.31, 0.41)  # meia largura, meia altura
	var centro := 1.55
	var resto := W + s / 2 - vao.x
	for sx in [-1, 1]:
		_quad(c, "ParedeNorte%d" % (sx + 1), Vector2(resto, H + s), Vector3(sx * (vao.x + resto / 2), H / 2, -D_N), Vector3.ZERO, "parede_pensao")
	_quad(c, "ParedeNorteBaixo", Vector2(2 * vao.x, centro - vao.y), Vector3(0, (centro - vao.y) / 2, -D_N), Vector3.ZERO, "parede_pensao")
	_quad(c, "ParedeNorteAlto", Vector2(2 * vao.x, H + s / 2 - centro - vao.y), Vector3(0, (H + s / 2 + centro + vao.y) / 2, -D_N), Vector3.ZERO, "parede_pensao")
	# O vão tem a espessura da parede.
	for sx in [-1, 1]:
		_box(c, "Vao%d" % (sx + 1), Vector3(0.02, 2 * vao.y, 0.2), Vector3(sx * (vao.x + 0.01), centro, -D_N - 0.1), "parede_pensao")
	for sy in [-1, 1]:
		_box(c, "VaoH%d" % (sy + 1), Vector3(2 * vao.x, 0.02, 0.2), Vector3(0, centro + sy * (vao.y + 0.01), -D_N - 0.1), "parede_pensao")
	var cidade: Node3D = preload("res://tools/vistas.gd").new().boston()
	cidade.position = Vector3(0, 0, -D_N - 0.2)
	_add(c, cidade)
	for filho in cidade.get_children():
		filho.owner = cena
	var j := _group(c, "Janela", Vector3(0, 0, -D_N + 0.02))
	_box(j, "Moldura", Vector3(0.72, 0.05, 0.06), Vector3(0, 1.12, 0.02), "madeira_clara")
	_box(j, "Verga", Vector3(0.72, 0.05, 0.06), Vector3(0, 1.98, 0.02), "madeira_clara")
	_box(j, "Travessa", Vector3(0.62, 0.03, 0.03), Vector3(0, 1.55, 0.02), "madeira_clara")
	for lado in [-1, 1]:
		_box(j, "Batente%d" % lado, Vector3(0.05, 0.86, 0.06), Vector3(lado * 0.335, 1.55, 0.02), "madeira_clara")

	# Portas de outros quartos, fechadas, na parede oeste.
	for z in [-2.2, 0.6]:
		var p := _group(c, "OutraPorta%d" % int(z * 10), Vector3(-W + 0.005, 0, z), 90)
		_quad(p, "Frente", Vector2(0.86, PORTA_H), Vector3(0, PORTA_H / 2, 0.001), Vector3.ZERO, "porta")
		_box(p, "Macaneta", Vector3(0.05, 0.05, 0.06), Vector3(0.33, 1.0, 0.03), "latao")

	# A arandela entre as portas: a única luz do corredor.
	var arandela := _group(c, "Arandela", Vector3(-W + 0.02, 1.75, -0.8), 90)
	_box(arandela, "Espelho", Vector3(0.1, 0.16, 0.02), Vector3.ZERO, "latao")
	_cyl(arandela, "Globo", 0.05, 0.035, 0.1, Vector3(0, 0.05, 0.08), "vidro_aceso", 8)
	var luz := _omni(arandela, "Luz", Vector3(0, 0.05, 0.2), Color(1.0, 0.8, 0.5), 0.9, 4.5)
	luz.shadow_enabled = true
	luz.omni_attenuation = 1.4

	# Ao sul, o vão da escada: por onde Wilmarth chegou e por onde volta.
	var esc := _group(c, "Escada", Vector3(0, 0, D_S))
	_quad(esc, "Escuro", Vector2(2 * W, H), Vector3(0, H / 2, -0.01), Vector3(0, 180, 0), "esmalte_preto")
	_box(esc, "Corrimao", Vector3(2 * W, 0.05, 0.05), Vector3(0, 0.95, -0.15), "madeira_escura")
	for x in [-0.5, -0.17, 0.17, 0.5]:
		_box(esc, "Balaustre%d" % int(x * 10), Vector3(0.03, 0.92, 0.03), Vector3(x, 0.46, -0.15), "madeira_escura")
	# A luz do andar de baixo, rente ao chão, junto ao vão (sessão de tester 2:
	# virado para a escada, era um retângulo todo preto, sem o corrimão).
	var debaixo := _omni(esc, "LuzDeBaixo", Vector3(0, 0.55, -0.35), Color(1.0, 0.78, 0.5), 0.3, 2.0)
	debaixo.omni_attenuation = 1.4
	var sair := _area(c, Interactable.new(), "Saida", Vector3(2 * W, 1.6, 0.4), Vector3(0, 0.8, D_S - 0.3)) as Interactable
	sair.unique_name_in_owner = true
	sair.prompt = "Voltar a Arkham"
	# Depois do essencial (o homem de Keene), pode-se ir (Fase 3e: a conversa tem opções).
	sair.condition = _flag(&"ligou_boston_homem")

	_colisao(c, "Colisao", [
		[Vector3(2 * W, 0.2, comp), Vector3(0, -0.1, meio_z)],
		[Vector3(2 * W, 0.2, comp), Vector3(0, H + 0.1, meio_z)],
		[Vector3(0.2, H, comp), Vector3(-W - 0.1, H / 2, meio_z)],
		# Leste em pedaços: o vão da porta fica livre (a soleira barra o corpo, não a mira).
		[Vector3(0.2, H, D_S - PORTA_Z.y), Vector3(W + 0.1, H / 2, (D_S + PORTA_Z.y) / 2)],
		[Vector3(0.2, H, PORTA_Z.x + D_N), Vector3(W + 0.1, H / 2, (-D_N + PORTA_Z.x) / 2)],
		[Vector3(0.2, H - PORTA_H, PORTA_Z.y - PORTA_Z.x), Vector3(W + 0.1, (H + PORTA_H) / 2, (PORTA_Z.x + PORTA_Z.y) / 2)],
		[Vector3(2 * W, H, 0.2), Vector3(0, H / 2, -D_N - 0.1)],
		[Vector3(2 * W, H, 0.2), Vector3(0, H / 2, D_S + 0.1)],
	])


## A porta do rapaz: dobradiça ao norte, abre para dentro do quarto. Fechada até
## Wilmarth bater; então abre uma fresta (Boston._abrir gira o `Folha`).
func _porta_do_quarto() -> void:
	var p := _group(cena, "PortaQuarto", Vector3(W, 0, PORTA_Z.x))
	var larg := PORTA_Z.y - PORTA_Z.x
	# Batentes.
	_box(p, "BatenteN", Vector3(0.06, PORTA_H + 0.04, 0.06), Vector3(0.0, (PORTA_H + 0.04) / 2, -0.03), "madeira_clara")
	_box(p, "BatenteS", Vector3(0.06, PORTA_H + 0.04, 0.06), Vector3(0.0, (PORTA_H + 0.04) / 2, larg + 0.03), "madeira_clara")
	_box(p, "BatenteAlto", Vector3(0.06, 0.06, larg + 0.12), Vector3(0.0, PORTA_H + 0.03, larg / 2), "madeira_clara")
	# A folha gira em torno da dobradiça (a origem do grupo): para dentro, +x.
	var folha := _group(p, "Folha")
	folha.unique_name_in_owner = true
	# O número é da folha (abre junto com ela).
	var numero := Label3D.new()
	numero.name = "Numero"
	numero.text = "7"
	numero.font_size = 64
	numero.pixel_size = 0.0012
	numero.modulate = Color(0.75, 0.6, 0.3)
	numero.position = Vector3(-0.004, 1.62, larg / 2)
	numero.rotation_degrees.y = -90
	_add(folha, numero)
	_box(folha, "Madeira", Vector3(0.045, PORTA_H, larg), Vector3(0.025, PORTA_H / 2, larg / 2), "madeira_escura")
	_quad(folha, "Frente", Vector2(larg, PORTA_H), Vector3(-0.0005, PORTA_H / 2, larg / 2), Vector3(0, -90, 0), "porta")
	_box(folha, "Macaneta", Vector3(0.06, 0.05, 0.05), Vector3(-0.03, 1.0, larg - 0.08), "latao")
	_colisao(folha, "Colisao", [[Vector3(0.05, PORTA_H, larg), Vector3(0.025, PORTA_H / 2, larg / 2)]])
	# A soleira: não se entra. Só até a cintura, para a mira passar por cima até o rosto.
	_colisao(p, "Soleira", [[Vector3(0.05, 1.1, larg), Vector3(0.0, 0.55, larg / 2)]])

	var bater := _area(p, StateInteractable.new(), "Bater", Vector3(0.3, 1.6, larg), Vector3(-0.15, 1.0, larg / 2)) as StateInteractable
	bater.unique_name_in_owner = true
	bater.prompt = "Bater à porta"
	bater.changes = {&"bateu_boston": 1.0}
	bater.additive = false
	bater.condition = _flag(&"bateu_boston", true)
	bater.som = load(SFX_DIR + "batidas_porta.wav")


## O quarto, atrás da porta: só se vê pela fresta — a parede do fundo, a cabeceira
## da cama de ferro, e a luz quente do abajur.
func _quarto() -> void:
	var q := _group(cena, "Quarto", Vector3(W, 0, 0))
	_quad(q, "Piso", Vector2(2.4, 3.0), Vector3(1.2, 0.002, -1.5), Vector3(-90, 0, 0), "piso")
	_quad(q, "Fundo", Vector2(3.0, H), Vector3(2.4, H / 2, -1.5), Vector3(0, -90, 0), "parede_pensao")
	_quad(q, "Norte", Vector2(2.4, H), Vector3(1.2, H / 2, -3.0), Vector3.ZERO, "parede_pensao")
	_quad(q, "Sul", Vector2(2.4, H), Vector3(1.2, H / 2, 0.0), Vector3(0, 180, 0), "parede_pensao")
	_quad(q, "Teto", Vector2(2.4, 3.0), Vector3(1.2, H, -1.5), Vector3(90, 0, 0), "teto")
	var cama := _group(q, "Cama", Vector3(1.6, 0, -0.45))
	_box(cama, "Colchao", Vector3(1.6, 0.18, 0.85), Vector3(0, 0.5, 0), "lencol")
	_box(cama, "Coberta", Vector3(1.0, 0.04, 0.9), Vector3(-0.25, 0.6, 0), "la_escura")
	for x in [-0.8, 0.8]:
		for z in [-0.42, 0.42]:
			_cyl(cama, "Pe%d%d" % [signf(x), signf(z)], 0.018, 0.018, 0.95, Vector3(x, 0.475, z), "ferro", 6)
	# O paletó e o boné do expresso num gancho, junto da porta.
	var gancho := _group(q, "Gancho", Vector3(0.08, 1.7, -2.6), -90)
	_box(gancho, "Tabua", Vector3(0.4, 0.06, 0.03), Vector3.ZERO, "madeira_escura")
	_box(gancho, "Paleto", Vector3(0.36, 0.7, 0.1), Vector3(0, -0.36, 0.06), "colete")
	_cyl(gancho, "Bone", 0.09, 0.1, 0.07, Vector3(0.12, 0.02, 0.07), "colete", 8)
	var luz := _omni(q, "Abajur", Vector3(1.9, 1.3, -2.3), Color(1.0, 0.72, 0.45), 2.2, 5.0)
	luz.shadow_enabled = true
	luz.omni_attenuation = 1.3


## O rapaz, em pé atrás da porta entreaberta, a mão na borda dela, o rosto na
## fresta (frente para -X, o corredor). Boneco provisório de primitivas: camisa,
## colete, cabelo curto (docs/ARTE.md).
func _funcionario() -> void:
	# Girado 90°: o -Z local (a frente) aponta para -X global (o corredor); o +X
	# local (a direita dele) para -Z global.
	var f := _group(cena, "Funcionario", Vector3(W + 0.3, 0, PORTA_Z.y - 0.17), 90)
	for x in [-0.1, 0.1]:
		var lado := "E" if x < 0 else "D"
		_box(f, "Perna" + lado, Vector3(0.13, 0.9, 0.14), Vector3(x, 0.45, 0), "colete")
	_box(f, "Camisa", Vector3(0.38, 0.62, 0.22), Vector3(0, 1.22, 0), "camisa")
	_box(f, "Colete", Vector3(0.395, 0.4, 0.235), Vector3(0, 1.14, 0), "colete")
	_cyl(f, "Pescoco", 0.05, 0.05, 0.09, Vector3(0, 1.57, 0), "pele", 6)
	_cyl(f, "Cabeca", 0.085, 0.092, 0.21, Vector3(0, 1.72, 0), "pele", 8)
	_cyl(f, "Cabelo", 0.06, 0.098, 0.08, Vector3(0, 1.85, 0.015), "cabelo", 8)
	for x in [-0.034, 0.034]:
		_box(f, "Olho%d" % signf(x), Vector3(0.022, 0.012, 0.01), Vector3(x, 1.74, -0.088), "esmalte_preto")
	_box(f, "Nariz", Vector3(0.022, 0.04, 0.03), Vector3(0, 1.71, -0.1), "pele")
	_box(f, "Boca", Vector3(0.04, 0.008, 0.01), Vector3(0, 1.665, -0.088), "esmalte_preto")
	# O braço direito caído; o esquerdo apoiado no batente, a mão na madeira.
	_box(f, "BracoD", Vector3(0.09, 0.6, 0.1), Vector3(0.24, 1.2, 0), "camisa")
	_box(f, "BracoE", Vector3(0.09, 0.26, 0.1), Vector3(-0.24, 1.38, 0), "camisa")
	_box(f, "AntebracoE", Vector3(0.08, 0.08, 0.2), Vector3(-0.22, 1.28, -0.12), "camisa")
	_box(f, "MaoE", Vector3(0.06, 0.1, 0.06), Vector3(-0.2, 1.3, -0.23), "pele")

	var fala := _area(f, Interlocutor.new(), "Conversa", Vector3(0.45, 0.6, 0.3), Vector3(0, 1.6, -0.05)) as Interlocutor
	fala.unique_name_in_owner = true
	fala.condition = _flag(&"porta_aberta_boston")
	var conversas: Array[Ligacao] = []
	for id in ["boston_apresentar", "boston_homem", "boston_voz", "boston_reconhecer"]:
		conversas.append(load("res://narrative/ligacoes/%s.tres" % id))
	fala.conversas = conversas
	fala.voz = load(SFX_DIR + "voz_sala.wav")
	fala.voz_db = -12.0
	# Em pessoa: as perguntas aparecem embaixo, para escolher (Fase 3e).
	fala.com_opcoes = true
	fala.despedida = "Agradecer e ir embora"
	fala.narracao_fim = load("res://narrative/narration/boston_nada.tres")
	fala.fim_depois_de = conversas[1]
