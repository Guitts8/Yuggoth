extends "res://tools/gerador_base.gd"
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

const W := 2.5  # meia largura
const D := 3.0  # meia profundidade
const H := 3.0  # pé-direito
## Janela norte (abertura na parede).
const JANELA_X := 0.8
const JANELA_Y := Vector2(0.9, 2.4)
## Altura do lambri (até o peitoril da janela).
const LAMBRI := 0.9

## Arkham em 3D pela janela (Fase 3d): as malhas montadas uma vez, uma vista por hora.
var _cidade = preload("res://tools/cidade_arkham.gd").new()
## A folha da porta (feita em _estrutura; a calha a abre).
var _folha_porta: Node3D
## A gaveta da escrivaninha que guarda o frasco (feita em _escrivaninha; Bebida).
var _gaveta_mesa: Node3D
## Onde ele senta nas noites longe do diário (LugarSono): a cadeira de leitura e
## a poltrona.
var _assento_leitura: Marker3D
var _assento_poltrona: Marker3D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	_materiais()

	cena = Node3D.new()
	cena.name = "Escritorio"
	cena.set_script(load("res://levels/escritorio/escritorio.gd"))
	cena.set("env_1930", _env_1930())
	cena.set("env_dia", _env_dia())
	var ambientes: Array[Environment] = [null, cena.get("env_dia"), _env_entardecer(), _env_noite(), cena.get("env_dia"), _env_chuva(), _env_noite()]
	cena.set("ambientes_dia", ambientes)
	cena.set("som_chuva", load(SFX_DIR + "chuva.wav"))
	# Pássaros só no Dia 1 (tarde tranquila); à noite e nos dias tensos, não.
	cena.set("som_padrao", load(SFX_DIR + "dia_quieto.wav"))
	var sons: Array[AudioStream] = [null, load(SFX_DIR + "tarde.wav"), null,
		load(SFX_DIR + "noite.wav"), null, load(SFX_DIR + "chuva.wav"), load(SFX_DIR + "noite.wav")]
	cena.set("sons_dia", sons)
	# O Dia 4 vira noite sem acabar: a volta de Boston, para as cartas da madrugada.
	cena.set("env_noite", _env_noite())
	cena.set("som_noite", load(SFX_DIR + "noite.wav"))
	var volta: Dictionary[StringName, NarrationLine] = {&"voltou_de_boston": load("res://narrative/narration/depois_relato.tres")}
	cena.set("linhas_volta", volta)
	# Os sonhos (Escritorio._sonhar; o conteúdo vem de _sonhos).
	cena.set("env_sonho", _env_sonho())
	cena.set("som_sonho", load(SFX_DIR + "sonho.wav"))
	cena.set("som_pena", load(SFX_DIR + "pena.wav"))
	cena.set("som_papel", load(SFX_DIR + "papel_pegar.wav"))
	cena.set("som_selo", load(SFX_DIR + "selo_batido.wav"))
	cena.set("linha_abertura", load("res://narrative/narration/prologo_abertura.tres"))
	cena.set("linha_cartas", load("res://narrative/narration/prologo_cartas.tres"))
	var cartoes: Array[NarrationLine] = [null,
		load("res://narrative/narration/prologo_maio.tres"),
		load("res://narrative/narration/cartao_dia_2.tres"),
		load("res://narrative/narration/cartao_dia_3.tres"),
		load("res://narrative/narration/cartao_dia_4.tres"),
		load("res://narrative/narration/cartao_dia_5.tres"),
		load("res://narrative/narration/cartao_dia_6.tres")]
	cena.set("cartoes_dia", cartoes)
	var correio: Array[NarrationLine] = [null,
		load("res://narrative/narration/dia1_correio.tres"),
		load("res://narrative/narration/dia2_correio.tres"),
		load("res://narrative/narration/dia3_correio.tres"),
		load("res://narrative/narration/dia4_correio.tres"),
		load("res://narrative/narration/dia5_correio.tres"),
		load("res://narrative/narration/dia6_correio.tres")]
	cena.set("linhas_correio", correio)
	cena.set("linha_resposta_selada", load("res://narrative/narration/resposta_selada.tres"))
	cena.set("ultima_carta", load("res://narrative/documents/carta_akeley_quarta.tres"))
	cena.set("linha_fim_demo", load("res://narrative/narration/fim_da_demo.tres"))
	# O diário, ao fim de cada dia (Dias 1 a 5): as entradas e a fala ao postar.
	var entradas: Array[DocumentData] = [null]
	for n in range(1, 6):
		entradas.append(load("res://narrative/documents/diario_dia_%d.tres" % n))
	cena.set("diario_entradas", entradas)
	cena.set("linha_diario", load("res://narrative/narration/diario_lembrete.tres"))

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

	_salvar(OUT)


# --- Materiais -----------------------------------------------------------------

func _materiais() -> void:
	_mat("parede", "papel_parede", {world = 1.3})
	_mat("piso", "assoalho", {world = 0.8})
	_mat("teto", "reboco", {world = 1.0})
	_mat("madeira_escura", "madeira_escura", {world = 2.0})
	_mat("madeira_clara", "madeira_clara", {world = 2.0})
	_mat("porta", "porta", {})
	_mat("quadro", "quadro", {})
	_mat("diploma", "diploma", {})
	_mat("esmalte_verde", "aco", {world = 6.0, cor = Color(0.24, 0.36, 0.27)})
	_mat("porcelana", "papel", {world = 6.0, cor = Color(1.08, 1.06, 1.0)})
	_mat("cafe", "papel", {world = 6.0, cor = Color(0.14, 0.08, 0.04)})
	_mat("uisque", "papel", {world = 6.0, cor = Color(0.75, 0.42, 0.12)})
	_mat("piso_corredor", "assoalho", {world = 0.8, cor = Color(0.62, 0.52, 0.44)})
	_mat("parede_corredor", "reboco", {world = 1.0, cor = Color(0.8, 0.73, 0.6)})
	_mat("vidro_fosco", "papel", {unlit = true, world = 3.0, cor = Color(0.75, 0.62, 0.42)})
	_mat("tijolo", "tijolo", {world = 2.5})
	_mat("lambri", "lambri", {world = 1.0 / LAMBRI})
	_mat("aco", "aco", {world = 2.0})
	_mat("gaveta_arquivo", "gaveta_arquivo", {})
	_mat("esmalte_preto", "aco", {world = 6.0, cor = Color(0.2, 0.2, 0.2)})
	_mat("capa_livro", "capa_livro", {})
	_mat("la_escura", "la_escura", {world = 3.0})
	_mat("feltro", "feltro", {world = 4.0})
	_mat("cortina", "cortina", {world = 1.2})
	_mat("cortica", "cortica", {world = 2.0})
	_mat("tapete", "tapete", {})
	_mat("estofado", "estofado", {world = 3.0})
	_mat("lencol", "lencol", {world = 1.5})
	_mat("papel", "papel", {world = 4.0})
	_mat("latao", "latao", {world = 3.0})
	_mat("cinzas", "cinzas", {world = 2.0})
	_mat("papel_pardo", "papel_pardo", {world = 3.0})
	_mat("barbante", "barbante", {world = 40.0})
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
	_mat("vidro_verde", "papel", {world = 6.0, cor = Color(0.22, 0.6, 0.3)})
	# O vulto que passa pela janela no Dia 5 (iluminado só pelo abajur).
	_mat("sombra", "sombra", {})
	# A criatura cruzando o céu da cidade (Dias 3 e 6): silhueta sem luz.
	_mat("migo", "migo", {unlit = true})
	# A cidade em 3D (experimento): silhuetas de noite, sem luz.
	# Os sonhos entre os dias.
	_mat("pegada", "pegada_garra", {})
	_mat("vista_circulo", "vista_circulo", {unlit = true})
	_mat("vista_plataforma", "vista_plataforma", {unlit = true})
	_mat("homem_magro", "homem_magro", {unlit = true})
	_mat("pedra_negra", "pedra_negra", {world = 4.0})


func _env_1930() -> Environment:
	var e := _pos(Environment.new())
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.035, 0.037, 0.05)
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.02, 0.022, 0.03)
	e.fog_density = 1.0
	e.fog_depth_begin = 2.0
	e.fog_depth_end = 10.0
	return e


## Os sonhos: escuro, com uma névoa verde-acinzentada que come o fundo da sala.
func _env_sonho() -> Environment:
	var e := _env_1930()
	e.ambient_light_color = Color(0.05, 0.06, 0.055)
	e.fog_light_color = Color(0.05, 0.07, 0.06)
	e.fog_depth_begin = 1.5
	e.fog_depth_end = 7.0
	return e


## Dia 3: noite no escritório (só o abajur e a lua).
func _env_noite() -> Environment:
	var e := _env_1930()
	e.ambient_light_color = Color(0.045, 0.042, 0.05)
	return e


## Dia 5: noite de chuva, mais fria que a do Dia 3.
func _env_chuva() -> Environment:
	var e := _env_1930()
	e.ambient_light_color = Color(0.035, 0.04, 0.055)
	return e


## Dia 2: fim de tarde, mais escuro e alaranjado.
func _env_entardecer() -> Environment:
	var e := _env_dia()
	e.background_color = Color(0.5, 0.35, 0.3)
	e.ambient_light_color = Color(0.2, 0.15, 0.13)
	e.fog_light_color = Color(0.3, 0.2, 0.16)
	return e


func _env_dia() -> Environment:
	var e := _pos(Environment.new())
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.6, 0.66, 0.72)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.36, 0.32, 0.27)
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.5, 0.46, 0.4)
	e.fog_density = 0.6
	e.fog_depth_begin = 5.0
	e.fog_depth_end = 18.0
	return e


## Barbante em cruz em volta de uma caixa de tamanho `tam` (base em y 0, centrada
## em x/z), com o nó e um laço em cima. Devolve o grupo (para sumir ao desamarrar).
func _barbante(parent: Node, tam: Vector3, rot_laco := 0.0) -> Node3D:
	var b := _group(parent, "Barbante")
	var f := 0.004  # espessura do fio
	_box(b, "Comprido", Vector3(tam.x + f, tam.y + f, f), Vector3(0, tam.y / 2, 0), "barbante")
	_box(b, "Curto", Vector3(f, tam.y + f, tam.z + f), Vector3(0, tam.y / 2, 0), "barbante")
	var no := _group(b, "No", Vector3(0, tam.y + f, 0), rot_laco)
	_box(no, "Volta", Vector3(0.012, 0.008, 0.012), Vector3(0, 0.002, 0), "barbante")
	for s in [-1, 1]:
		var laco := _cyl(no, "Laco%d" % s, 0.016, 0.016, 0.004, Vector3(s * 0.02, 0.003, 0), "barbante", 6)
		laco.scale = Vector3(1.3, 1, 0.7)
		var ponta := _box(no, "Ponta%d" % s, Vector3(0.004, 0.003, 0.035), Vector3(s * 0.012, 0.001, 0.02), "barbante")
		ponta.rotation_degrees.y = s * 25
	return b


## Um maço de `n` cartas amarradas com barbante (base em y 0): envelopes de cores
## e alinhamentos um pouco diferentes, numa malha só.
func _maco(parent: Node, nome: String, n: int, seed: int) -> Node3D:
	var g := _group(parent, nome)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var esp := 0.0045
	var pecas := []
	for i in n:
		var cor := Color(1, 1, 1).lerp(Color(0.86, 0.8, 0.68), rng.randf())
		pecas.append([Vector3(Envelope.LARGURA, esp, Envelope.ALTURA), Vector3(rng.randf_range(-0.006, 0.006), esp * (i + 0.5), rng.randf_range(-0.004, 0.004)),
			Vector3(0, rng.randf_range(-4, 4), 0), cor])
	_lote(g, "Envelopes", pecas, "envelope")
	_barbante(g, Vector3(Envelope.LARGURA, esp * n, Envelope.ALTURA), 15)
	return g


# --- Estrutura (comum aos dois vestidos) ----------------------------------------

func _estrutura() -> void:
	var e := _group(cena, "Estrutura")
	# Cada plano passa um pouco (`sobra`) dos vizinhos, por fora da sala: o tremor de
	# vértice abria frestas nas quinas, e o fundo aparecia em pontinhos.
	var sobra := 0.2
	_quad(e, "Piso", Vector2(2 * W + sobra, 2 * D + sobra), Vector3(0, 0, 0), Vector3(-90, 0, 0), "piso")
	_quad(e, "Teto", Vector2(2 * W + sobra, 2 * D + sobra), Vector3(0, H, 0), Vector3(90, 0, 0), "teto")
	_quad(e, "ParedeOeste", Vector2(2 * D + sobra, H + sobra), Vector3(-W, H / 2, 0), Vector3(0, 90, 0), "parede")
	_quad(e, "ParedeLeste", Vector2(2 * D + sobra, H + sobra), Vector3(W, H / 2, 0), Vector3(0, -90, 0), "parede")
	# O sul em pedaços, em volta do vão da porta (ela abre para a calha, Fase 3d).
	var vao_o := PORTA_X - PORTA_L / 2
	var vao_l := PORTA_X + PORTA_L / 2
	var oeste := vao_o + W + sobra / 2
	var leste := W + sobra / 2 - vao_l
	_quad(e, "ParedeSulO", Vector2(oeste, H + sobra), Vector3(vao_o - oeste / 2, H / 2, D), Vector3(0, 180, 0), "parede")
	_quad(e, "ParedeSulL", Vector2(leste, H + sobra), Vector3(vao_l + leste / 2, H / 2, D), Vector3(0, 180, 0), "parede")
	_quad(e, "ParedeSulAlto", Vector2(PORTA_L, H + sobra / 2 - PORTA_H), Vector3(PORTA_X, (H + sobra / 2 + PORTA_H) / 2, D), Vector3(0, 180, 0), "parede")
	# Norte em pedaços, com espessura, em volta da janela.
	var t := 0.2
	var lado := W - JANELA_X
	_box(e, "ParedeNorteO", Vector3(lado + sobra / 2, H + sobra, t), Vector3(-JANELA_X - (lado + sobra / 2) / 2, H / 2, -D - t / 2), "parede")
	_box(e, "ParedeNorteL", Vector3(lado + sobra / 2, H + sobra, t), Vector3(JANELA_X + (lado + sobra / 2) / 2, H / 2, -D - t / 2), "parede")
	_box(e, "ParedeNorteBaixo", Vector3(2 * JANELA_X, JANELA_Y.x, t), Vector3(0, JANELA_Y.x / 2, -D - t / 2), "parede")
	_box(e, "ParedeNorteAlto", Vector3(2 * JANELA_X, H + sobra / 2 - JANELA_Y.y, t), Vector3(0, (H + sobra / 2 + JANELA_Y.y) / 2, -D - t / 2), "parede")

	# Lambri até o peitoril, com moldura em cima; no sul, interrompido pela porta.
	var l := 0.025
	var lambri := _group(e, "Lambri")
	var trechos := [
		["Oeste", Vector3(l, LAMBRI, 2 * D), Vector3(-W + l / 2, LAMBRI / 2, 0)],
		["Leste", Vector3(l, LAMBRI, 2 * D), Vector3(W - l / 2, LAMBRI / 2, 0)],
		["Norte", Vector3(2 * W, LAMBRI, l), Vector3(0, LAMBRI / 2, -D + l / 2)],
		["SulO", Vector3(0.95, LAMBRI, l), Vector3(-W + 0.475, LAMBRI / 2, D - l / 2)],
		["SulL", Vector3(2.95, LAMBRI, l), Vector3(W - 1.475, LAMBRI / 2, D - l / 2)],
	]
	for t2: Array in trechos:
		_box(lambri, t2[0], t2[1], t2[2], "lambri")
		var tam: Vector3 = t2[1]
		var moldura := Vector3(maxf(tam.x, 0.05), 0.04, maxf(tam.z, 0.05))
		_box(lambri, "Moldura" + t2[0], moldura, Vector3(t2[2].x, LAMBRI + 0.02, t2[2].z), "madeira_escura")

	# Rodapé, à frente do lambri.
	var r := 0.12
	var rp := 0.045
	_box(e, "RodapeOeste", Vector3(rp, r, 2 * D), Vector3(-W + rp / 2, r / 2, 0), "madeira_escura")
	_box(e, "RodapeLeste", Vector3(rp, r, 2 * D), Vector3(W - rp / 2, r / 2, 0), "madeira_escura")
	var ro := PORTA_X - PORTA_L / 2 - 0.05 + W
	var rl := W - (PORTA_X + PORTA_L / 2 + 0.05)
	_box(e, "RodapeSulO", Vector3(ro, r, rp), Vector3(-W + ro / 2, r / 2, D - rp / 2), "madeira_escura")
	_box(e, "RodapeSulL", Vector3(rl, r, rp), Vector3(W - rl / 2, r / 2, D - rp / 2), "madeira_escura")
	_box(e, "RodapeNorte", Vector3(2 * W, r, rp), Vector3(0, r / 2, -D + rp / 2), "madeira_escura")

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
	var p := _group(e, "Porta", Vector3(PORTA_X, 0, D))
	# A folha gira na dobradiça (oeste) e abre para dentro da sala (CalhaCorreio).
	var folha := _group(p, "Folha", Vector3(-PORTA_L / 2, 0, 0))
	_folha_porta = folha
	_box(folha, "Madeira", Vector3(PORTA_L, PORTA_H, 0.05), Vector3(PORTA_L / 2, PORTA_H / 2, -0.03), "madeira_escura")
	_quad(folha, "Frente", Vector2(PORTA_L, PORTA_H), Vector3(PORTA_L / 2, PORTA_H / 2, -0.06), Vector3(0, 180, 0), "porta")
	_quad(folha, "Costas", Vector2(PORTA_L, PORTA_H), Vector3(PORTA_L / 2, PORTA_H / 2, 0.0), Vector3.ZERO, "porta")
	_box(folha, "Macaneta", Vector3(0.05, 0.05, 0.06), Vector3(PORTA_L / 2 + 0.36, 1.0, -0.1), "latao")
	_box(folha, "MacanetaFora", Vector3(0.05, 0.05, 0.06), Vector3(PORTA_L / 2 + 0.36, 1.0, 0.04), "latao")
	_box(p, "BatenteO", Vector3(0.08, 2.2, 0.06), Vector3(-0.5, 1.1, -0.03), "madeira_clara")
	_box(p, "BatenteL", Vector3(0.08, 2.2, 0.06), Vector3(0.5, 1.1, -0.03), "madeira_clara")
	_box(p, "BatenteAlto", Vector3(1.08, 0.08, 0.06), Vector3(0, 2.18, -0.03), "madeira_clara")

	# O alizar da porta, do lado da sala: os montantes e a verga com a cimalha.
	for s in [-1, 1]:
		_box(p, "Alizar%d" % (s + 1), Vector3(0.1, PORTA_H + 0.12, 0.025), Vector3(s * (PORTA_L / 2 + 0.07), (PORTA_H + 0.12) / 2, -0.07), "madeira_escura")
	_box(p, "AlizarVerga", Vector3(PORTA_L + 0.3, 0.14, 0.03), Vector3(0, PORTA_H + 0.12, -0.07), "madeira_escura")
	_box(p, "AlizarCimalha", Vector3(PORTA_L + 0.38, 0.04, 0.06), Vector3(0, PORTA_H + 0.21, -0.08), "madeira_escura")

	_acabamento(e)

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

## O acabamento da sala (Fase 3d, "feito nas coxas"): a cornija em volta do teto,
## em dois degraus; o florão e o lustre de globo no meio do teto (apagado: as
## luzes são as da mesa, da janela e do fogo).
func _acabamento(e: Node3D) -> void:
	var c := _group(e, "Cornija")
	for t: Array in [["N", Vector3(2 * W, 0, 0), Vector3(0, 0, -D), Vector3(0, 0, 1)], ["S", Vector3(2 * W, 0, 0), Vector3(0, 0, D), Vector3(0, 0, -1)],
			["O", Vector3(0, 0, 2 * D), Vector3(-W, 0, 0), Vector3(1, 0, 0)], ["L", Vector3(0, 0, 2 * D), Vector3(W, 0, 0), Vector3(-1, 0, 0)]]:
		var ao_longo: Vector3 = t[1]
		var dentro: Vector3 = t[3]
		for degrau: Array in [[0.1, 0.035, 0.05], [0.045, 0.08, 0.1]]:
			var fundo: float = degrau[1]
			var tam: Vector3 = ao_longo + Vector3(absf(dentro.x), 0, absf(dentro.z)) * fundo + Vector3(0, degrau[0], 0)
			_box(c, "Cornija%s%d" % [t[0], int(degrau[0] * 1000)], tam, t[2] + dentro * fundo / 2 + Vector3(0, H - degrau[2], 0), "madeira_escura")
	var centro := Vector3(0, H, 0.2)
	_cyl(e, "Florao", 0.16, 0.12, 0.03, centro - Vector3(0, 0.015, 0), "teto", 10)
	_cyl(e, "LustreHaste", 0.008, 0.008, 0.5, centro - Vector3(0, 0.27, 0), "latao", 6)
	_cyl(e, "LustreCopa", 0.06, 0.04, 0.05, centro - Vector3(0, 0.54, 0), "latao", 8)
	_cyl(e, "LustreGlobo", 0.14, 0.09, 0.2, centro - Vector3(0, 0.66, 0), "porcelana", 10)


func _mobilia() -> void:
	var mob := _group(cena, "Mobilia")
	_escrivaninha(mob)
	_cadeira(mob)
	_estante(mob)
	_lareira(mob)
	# Virada para a lareira (a noite do Dia 5 é diante do fogo, LugarSono).
	var poltrona := _group(mob, "Poltrona", POLTRONA_POS, POLTRONA_ROT)
	_poltrona(poltrona, "estofado")
	_assento_poltrona = Marker3D.new()
	_assento_poltrona.name = "Assento"
	_add(poltrona, _assento_poltrona)
	_quad(mob, "Tapete", Vector2(2.4, 1.8), Vector3(0, 0.006, 0.3), Vector3(-90, 0, 0), "tapete")
	_cabideiro(mob)


## Canto sudeste: cabideiro com o chapéu no alto e o sobretudo virado para a sala.
func _cabideiro(parent: Node) -> void:
	var cab := _group(parent, "Cabideiro", Vector3(2.15, 0, 2.62), 45)
	_cyl(cab, "Haste", 0.02, 0.025, 1.8, Vector3(0, 0.9, 0), "madeira_escura", 6)
	_cyl(cab, "Pe", 0.03, 0.22, 0.08, Vector3(0, 0.04, 0), "madeira_escura", 6)
	for i in 3:
		var gancho := _box(cab, "Gancho%d" % i, Vector3(0.2, 0.02, 0.02), Vector3(0, 1.66, 0), "latao")
		gancho.rotation_degrees.y = i * 60
	# Chapéu de feltro coroando a haste.
	_cyl(cab, "Aba", 0.15, 0.16, 0.014, Vector3(0, 1.8, 0), "feltro", 10)
	_cyl(cab, "Copa", 0.085, 0.095, 0.1, Vector3(0, 1.86, 0), "feltro", 8)
	_cyl(cab, "Fita", 0.097, 0.097, 0.022, Vector3(0, 1.82, 0), "la_escura", 8)
	# Sobretudo pendurado num gancho, de frente para a sala (-Z).
	var casaco := _group(cab, "Sobretudo", Vector3(0, 0, -0.14))
	_box(casaco, "Ombros", Vector3(0.44, 0.07, 0.16), Vector3(0, 1.58, 0), "la_escura").rotation_degrees.x = 4
	var corpo := _cyl(casaco, "Corpo", 0.19, 0.25, 1.0, Vector3(0, 1.06, 0.01), "la_escura", 7)
	corpo.scale = Vector3(1, 1, 0.5)
	_box(casaco, "Gola", Vector3(0.16, 0.12, 0.05), Vector3(0, 1.52, -0.07), "la_escura").rotation_degrees.x = -20
	for s in [-1, 1]:
		var manga := _box(casaco, "Manga%d" % s, Vector3(0.09, 0.6, 0.1), Vector3(s * 0.21, 1.24, 0.0), "la_escura")
		manga.rotation_degrees.z = s * 4
	_colisao(cab, "Colisao", [[Vector3(0.45, 1.8, 0.45), Vector3(0, 0.9, -0.05)]])


## A escrivaninha de pedestal duplo (Fase 3d: com acabamento): o tampo com a
## borda moldurada, os dois gaveteiros sobre um rodapé, cada gaveta com a frente
## saliente e o puxador de latão, e a gaveta do meio sob o tampo.
func _escrivaninha(parent: Node) -> void:
	var g := _group(parent, "Escrivaninha", Vector3(0, 0, -2.2))
	_box(g, "Tampo", Vector3(1.6, 0.045, 0.8), Vector3(0, 0.7575, 0), "madeira_escura")
	_box(g, "Borda", Vector3(1.64, 0.025, 0.84), Vector3(0, 0.7225, 0), "madeira_escura")
	for s in [-1, 1]:
		var lado := "O" if s < 0 else "L"
		var x: float = s * 0.57
		_box(g, "Gaveteiro" + lado, Vector3(0.42, 0.62, 0.74), Vector3(x, 0.4, 0), "madeira_escura")
		_box(g, "Rodape" + lado, Vector3(0.44, 0.09, 0.76), Vector3(x, 0.045, 0), "madeira_escura")
		for k in 3:
			if s > 0 and k == 0:
				continue  # a gaveta de cima, à direita, abre (frente e puxador são dela)
			var y := 0.6 - k * 0.19
			_box(g, "Frente%s%d" % [lado, k], Vector3(0.38, 0.17, 0.02), Vector3(x, y, 0.38), "madeira_escura")
			_box(g, "Puxador%s%d" % [lado, k], Vector3(0.08, 0.02, 0.02), Vector3(x, y, 0.4), "latao")
	# A gaveta do meio (a do lápis), rasa, e o painel do fundo.
	_box(g, "FrenteMeio", Vector3(0.66, 0.07, 0.02), Vector3(0, 0.66, 0.38), "madeira_escura")
	_box(g, "PuxadorMeio", Vector3(0.1, 0.015, 0.02), Vector3(0, 0.66, 0.4), "latao")
	_box(g, "Fundo", Vector3(0.72, 0.55, 0.03), Vector3(0, 0.42, -0.3), "madeira_escura")
	# A gaveta de cima, à direita: guarda o frasco de uísque (Bebida, Fase 3d).
	var gaveta := _group(g, "Gaveta", Vector3(0.57, 0.6, 0.0))
	_gaveta_mesa = gaveta
	_box(gaveta, "Frente", Vector3(0.38, 0.17, 0.02), Vector3(0, 0, 0.38), "madeira_escura")
	_box(gaveta, "Puxador", Vector3(0.08, 0.02, 0.02), Vector3(0, 0, 0.4), "latao")
	_box(gaveta, "Chao", Vector3(0.34, 0.01, 0.55), Vector3(0, -0.07, 0.09), "madeira_clara")
	for lado in [-1, 1]:
		_box(gaveta, "Lado%d" % (lado + 1), Vector3(0.01, 0.12, 0.55), Vector3(lado * 0.165, -0.02, 0.09), "madeira_clara")
	_colisao(g, "Colisao", [[Vector3(1.6, 0.78, 0.8), Vector3(0, 0.39, 0)]])


## A cadeira de escritório de carvalho, de banqueiro (Fase 3d): o pé giratório de
## quatro garras, o assento arredondado, os braços curvos e o encosto de balaústres
## com o travessão de cima. Sem colisão: o jogador senta nela.
func _cadeira(parent: Node) -> void:
	var g := _group(parent, "Cadeira", Vector3(0, 0, -1.3))
	for i in 4:
		var pe := _box(g, "Pe%d" % i, Vector3(0.05, 0.04, 0.3), Vector3(0, 0.05, 0), "madeira_clara")
		pe.rotation_degrees = Vector3(-14, 45 + i * 90, 0)
		pe.position = Vector3(sin(deg_to_rad(45 + i * 90)), 0, cos(deg_to_rad(45 + i * 90))) * 0.13 + Vector3(0, 0.06, 0)
	_cyl(g, "Coluna", 0.03, 0.04, 0.32, Vector3(0, 0.25, 0), "ferro", 8)
	_cyl(g, "Assento", 0.25, 0.23, 0.045, Vector3(0, 0.44, 0), "madeira_clara", 12)
	for s in [-1, 1]:
		_box(g, "Braco%d" % (s + 1), Vector3(0.045, 0.025, 0.36), Vector3(s * 0.23, 0.64, -0.02), "madeira_clara")
		_box(g, "BracoApoio%d" % (s + 1), Vector3(0.03, 0.18, 0.03), Vector3(s * 0.23, 0.54, -0.16), "madeira_clara")
		_box(g, "Montante%d" % (s + 1), Vector3(0.035, 0.4, 0.035), Vector3(s * 0.21, 0.66, 0.2), "madeira_clara")
	for k in 5:
		_box(g, "Balaustre%d" % k, Vector3(0.018, 0.28, 0.018), Vector3(-0.12 + k * 0.06, 0.62, 0.21), "madeira_clara")
	var trav := _box(g, "Travessao", Vector3(0.48, 0.07, 0.03), Vector3(0, 0.82, 0.22), "madeira_clara")
	trav.rotation_degrees.x = 8


const CORES_LIVRO := [Color(0.5, 0.13, 0.1), Color(0.16, 0.3, 0.18), Color(0.14, 0.17, 0.36),
	Color(0.55, 0.4, 0.2), Color(0.32, 0.2, 0.12), Color(0.2, 0.18, 0.16), Color(0.4, 0.1, 0.16),
	Color(0.6, 0.55, 0.42)]


## Livros de uma fileira, de pé, encostados ao fundo (x = `fundo`, lombada para
## +X), de z0 a z1, sobre `y`. Às vezes uma pilha deitada; no fim, um inclinado.
func _fileira(pecas: Array, rng: RandomNumberGenerator, y: float, fundo: float, z0: float, z1: float, alt_max: float) -> void:
	var z := z0
	while z < z1 - 0.03:
		var cor: Color = CORES_LIVRO[rng.randi_range(0, CORES_LIVRO.size() - 1)] * rng.randf_range(0.8, 1.15)
		cor.a = 1.0
		var prof := rng.randf_range(0.15, 0.23)
		if rng.randf() < 0.07 and z1 - z > 0.3:
			# Pilha deitada.
			var larg := rng.randf_range(0.18, 0.26)
			var topo := y
			for k in rng.randi_range(2, 5):
				var esp := rng.randf_range(0.025, 0.05)
				var c: Color = CORES_LIVRO[rng.randi_range(0, CORES_LIVRO.size() - 1)]
				pecas.append([Vector3(prof, esp, larg - k * 0.01), Vector3(fundo + prof / 2, topo + esp / 2, z + larg / 2),
					Vector3(0, rng.randf_range(-6, 6), 0), c])
				topo += esp
			z += larg + 0.01
			continue
		if rng.randf() < 0.05:
			z += rng.randf_range(0.03, 0.08)  # um vão
			continue
		var esp := rng.randf_range(0.022, 0.06)
		var alt := minf(rng.randf_range(0.19, 0.33), alt_max)
		if z + esp > z1:
			break
		pecas.append([Vector3(prof, alt, esp), Vector3(fundo + prof / 2, y + alt / 2, z + esp / 2), Vector3.ZERO, cor])
		z += esp
	# O último, inclinado sobre os outros, se sobrou espaço.
	var resto := z1 - z
	if resto > 0.06:
		var alt := minf(0.26, alt_max)
		var ang := rad_to_deg(asin(clampf((resto - 0.035) / alt, 0.0, 0.6)))
		var cor: Color = CORES_LIVRO[rng.randi_range(0, CORES_LIVRO.size() - 1)]
		var a := deg_to_rad(ang)
		pecas.append([Vector3(0.2, alt, 0.035), Vector3(fundo + 0.1, y + (alt * cos(a) + 0.035 * sin(a)) / 2,
			z + (alt * sin(a) + 0.035 * cos(a)) / 2), Vector3(-ang, 0, 0), cor])


func _estante(parent: Node) -> void:
	# Parede oeste, metade norte, cheia.
	var g := _group(parent, "Estante", Vector3(-W + 0.18, 0, -2.0))
	var alt := 2.3
	_box(g, "LadoN", Vector3(0.36, alt, 0.04), Vector3(0, alt / 2, -0.78), "madeira_escura")
	_box(g, "LadoS", Vector3(0.36, alt, 0.04), Vector3(0, alt / 2, 0.78), "madeira_escura")
	_box(g, "Fundo", Vector3(0.02, alt, 1.56), Vector3(-0.17, alt / 2, 0), "madeira_escura")
	var prateleiras := [0.06, 0.5, 0.94, 1.38, 1.82, alt - 0.02]
	for i in prateleiras.size():
		_box(g, "Prateleira%d" % i, Vector3(0.36, 0.04, 1.52), Vector3(0, prateleiras[i], 0), "madeira_escura")
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var livros := []
	for i in 5:
		_fileira(livros, rng, prateleiras[i] + 0.02, -0.16, -0.76, 0.76, prateleiras[i + 1] - prateleiras[i] - 0.06)
	_lote(g, "Livros", livros, "capa_livro")
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


## Poltrona de clube olhando para -Z local (gire o grupo para orientar; Fase 3d:
## com acabamento): os pés torneados, a saia, a almofada solta do assento, os
## braços rolados, o encosto inclinado com as orelhas.
func _poltrona(g: Node3D, mat: String) -> void:
	for x in [-0.3, 0.3]:
		for z in [-0.28, 0.28]:
			_cyl(g, "Pe%d%d" % [signf(x), signf(z)], 0.025, 0.018, 0.1, Vector3(x, 0.05, z), "madeira_escura", 6)
	_box(g, "Base", Vector3(0.76, 0.26, 0.7), Vector3(0, 0.23, 0.01), mat)
	_box(g, "Almofada", Vector3(0.54, 0.11, 0.56), Vector3(0, 0.41, -0.04), mat)
	_box(g, "Frente", Vector3(0.56, 0.05, 0.05), Vector3(0, 0.38, -0.32), mat)
	for s in [-1, 1]:
		_box(g, "Braco%d" % s, Vector3(0.12, 0.3, 0.66), Vector3(s * 0.32, 0.5, 0.0), mat)
		# O rolo do braço, por cima e por fora.
		var rolo := _cyl(g, "Rolo%d" % s, 0.075, 0.075, 0.68, Vector3(s * 0.33, 0.65, -0.01), mat, 8)
		rolo.rotation_degrees.x = 90
		var orelha := _box(g, "Orelha%d" % s, Vector3(0.1, 0.42, 0.18), Vector3(s * 0.31, 0.92, 0.24), mat)
		orelha.rotation_degrees.y = -s * 10
	var encosto := _box(g, "Encosto", Vector3(0.56, 0.62, 0.14), Vector3(0, 0.8, 0.29), mat)
	encosto.rotation_degrees.x = -10
	var topo := _cyl(g, "TopoEncosto", 0.07, 0.07, 0.58, Vector3(0, 1.1, 0.33), mat, 8)
	topo.rotation_degrees.z = 90
	_box(g, "Costas", Vector3(0.76, 0.6, 0.06), Vector3(0, 0.62, 0.34), mat)
	_colisao(g, "Colisao", [[Vector3(0.9, 1.0, 0.8), Vector3(0, 0.5, 0.05)]])


# --- Vestido: gabinete de casa, 1930, noite --------------------------------------

func _gabinete_1930() -> void:
	var g := _group(cena, "Gabinete1930")
	_vista(g, "chuva", "vista_noite")
	_chuva(g)

	# Escrivaninha: as cartas de Akeley (um maço amarrado), a folha do relato,
	# tinteiro e lamparina.
	var caixa := _maco(g, "Caixa", 14, 7)
	caixa.position = Vector3(-0.45, MESA, -2.25)
	caixa.rotation_degrees.y = 12
	var exam := _area(caixa, Examinable.new(), "CaixaCartas", Vector3(0.26, 0.14, 0.18), Vector3(0, 0.05, 0)) as Examinable
	exam.unique_name_in_owner = true
	exam.prompt = "Examinar"
	exam.title = "As cartas de Henry Akeley"
	exam.description = "Amarradas com barbante. O papel ainda cheira a terra úmida."
	exam.initial_rotation = Vector3(25, 20, 0)
	# Primeiro o relato (a folha na mesa); só então as cartas que levam a maio.
	exam.condition = _flag(&"leu_relato_folha_1")

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
	var chama := _omni(lamp, "Luz", Vector3(0, 0.28, 0.1), Color(1.0, 0.72, 0.45), 2.6, 5.0)
	chama.shadow_enabled = true
	chama.omni_attenuation = 1.4
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

	# Escrivaninha (todos os dias): tinteiro, pena, mata-borrão com cantoneiras,
	# espátula de cartas e a lâmpada de banqueiro (acesa só nas noites, _abajur).
	_cyl(g, "Tinteiro", 0.03, 0.035, 0.05, Vector3(0.36, 0.805, -2.32), "ferro", 6)
	var pena := _box(g, "Pena", Vector3(0.01, 0.01, 0.2), Vector3(0.3, 0.79, -2.12), "lencol")
	pena.rotation_degrees.y = 25
	# Fino e rente ao tampo: os papéis por cima dele (a 2 mm ou mais) não se enterram.
	_box(g, "MataBorrao", Vector3(0.5, 0.003, 0.36), Vector3(0.05, MESA + 0.0015, -2.12), "estofado")
	for s in [-1, 1]:
		_box(g, "Cantoneira%d" % s, Vector3(0.05, 0.005, 0.37), Vector3(0.05 + s * 0.24, MESA + 0.0025, -2.12), "feltro")
	var espatula := _group(g, "Espatula", Vector3(-0.68, MESA, -1.9), 80)
	_box(espatula, "Lamina", Vector3(0.15, 0.003, 0.016), Vector3(-0.04, 0.0015, 0), "ferro")
	_box(espatula, "Cabo", Vector3(0.07, 0.01, 0.018), Vector3(0.07, 0.005, 0), "latao")
	_abajur_peca(g)
	_diario(g, pena)
	_bebida(g)
	_cadeira_leitura(g)

	_arquivo(g)
	_cesto(g)
	_quadros(g)
	_cortinas(g)

	# Os dias somem enquanto se sonha (Escritorio._sonhar).
	_dias(_grupo_se(g, "Dias", _cond_valor(&"sonhando", ValueCondition.Op.IGUAL, 0)))
	_sonhos(g)

	# A luz do corredor entra pela fresta embaixo da porta: uma linha acesa e um
	# brilho fraco no chão, onde o correio cai — nas noites, é o que o mostra.
	_quad(g, "Fresta", Vector2(0.88, 0.012), Vector3(-1.0, 0.006, D - 0.062), Vector3(0, 180, 0), "vidro_aceso")
	var corredor := _omni(g, "LuzCorredor", Vector3(-0.95, 0.12, D - 0.3), Color(1.0, 0.8, 0.55), 0.5, 2.2)
	corredor.omni_attenuation = 1.6

	_corredor(g)
	_lapso(g)

	# Com correspondência na mão, mirar o tampo a põe na mesa (some sem nada na mão).
	var por := _area(g, MesaCorreio.new(), "PorNaMesa", Vector3(1.6, 0.1, 0.8), Vector3(0, MESA + 0.05, -2.2)) as MesaCorreio
	por.unique_name_in_owner = true
	por.prompt = "Pôr na mesa"

	# A porta encerra o dia ("ir para casa"); só no escritório.
	var sair := _area(g, Interactable.new(), "SairPorta", Vector3(0.9, 2.0, 0.2), Vector3(-1.0, 1.05, D - 0.12)) as Interactable
	sair.unique_name_in_owner = true
	sair.prompt = "Ir para casa"

	# Canto sudoeste: o armário. A máquina emprestada chega no Dia 3 (_fonografo).
	var a := _group(g, "Armario", Vector3(-2.15, 0, 2.35), 90)
	_box(a, "Movel", Vector3(0.8, 0.9, 0.5), Vector3(0, 0.45, 0), "madeira_escura")
	_box(a, "Juncao", Vector3(0.01, 0.8, 0.01), Vector3(0, 0.45, -0.255), "ferro")
	_colisao(a, "Colisao", [[Vector3(0.8, 0.9, 0.5), Vector3(0, 0.45, 0)]])


## O que pende nas paredes do escritório (Fase 3d): uma paisagem a óleo sobre a
## lareira, em moldura dourada, e os dois diplomas de Wilmarth na parede leste,
## ao sul da lareira.
func _quadros(g: Node3D) -> void:
	var face := W - 0.4
	var q := _group(g, "QuadroLareira", Vector3(face, 1.95, -0.6))
	_box(q, "Moldura", Vector3(0.04, 0.6, 0.82), Vector3(-0.02, 0, 0), "latao")
	_quad(q, "Tela", Vector2(0.7, 0.48), Vector3(-0.042, 0, 0), Vector3(0, -90, 0), "quadro")
	for k in 2:
		var d := _group(g, "Diploma%d" % k, Vector3(W, 1.55 + k * 0.05, 1.05 + k * 0.5))
		_box(d, "Moldura", Vector3(0.025, 0.36, 0.3), Vector3(-0.0125, 0, 0), "madeira_escura")
		_quad(d, "Papel", Vector2(0.24, 0.3), Vector3(-0.026, 0, 0), Vector3(0, -90, 0), "diploma")


## O corredor da Miskatonic atrás da porta e, na parede da frente, a calha de
## correio de latão com frente de vidro (Fase 3d; CalhaCorreio): é por ela que a
## carta sai. O corredor só aparece com a porta aberta.
func _corredor(g: Node3D) -> void:
	var c := _group(g, "Corredor")
	c.unique_name_in_owner = true
	c.visible = false
	var fundo := D + CORREDOR
	var meio := D + CORREDOR / 2
	var x0 := -4.0
	var x1 := 2.0
	var largura := x1 - x0
	var cx := (x0 + x1) / 2
	_quad(c, "Piso", Vector2(largura, CORREDOR), Vector3(cx, 0, meio), Vector3(-90, 0, 0), "piso_corredor")
	_quad(c, "Teto", Vector2(largura, CORREDOR), Vector3(cx, H, meio), Vector3(90, 0, 0), "teto")
	_quad(c, "ParedeFrente", Vector2(largura, H), Vector3(cx, H / 2, fundo), Vector3(0, 180, 0), "parede_corredor")
	_quad(c, "PontaO", Vector2(CORREDOR, H), Vector3(x0, H / 2, meio), Vector3(0, 90, 0), "parede_corredor")
	_quad(c, "PontaL", Vector2(CORREDOR, H), Vector3(x1, H / 2, meio), Vector3(0, -90, 0), "parede_corredor")
	_box(c, "Lambri", Vector3(largura, 1.0, 0.02), Vector3(cx, 0.5, fundo - 0.01), "lambri")
	_box(c, "LambriMoldura", Vector3(largura, 0.04, 0.04), Vector3(cx, 1.02, fundo - 0.02), "madeira_escura")
	_box(c, "Rodape", Vector3(largura, 0.12, 0.045), Vector3(cx, 0.06, fundo - 0.0225), "madeira_escura")
	# A porta de outra sala, mais adiante, com o vidro fosco aceso.
	var vizinha := _group(c, "PortaVizinha", Vector3(-2.9, 0, fundo), 180)
	_box(vizinha, "Folha", Vector3(0.9, 2.1, 0.05), Vector3(0, 1.05, 0.0), "madeira_escura")
	_box(vizinha, "Vidro", Vector3(0.6, 0.55, 0.052), Vector3(0, 1.6, 0.0), "vidro_fosco")
	_box(vizinha, "Batente", Vector3(1.04, 2.18, 0.04), Vector3(0, 1.09, 0.01), "madeira_clara")
	_box(vizinha, "Macaneta", Vector3(0.05, 0.05, 0.06), Vector3(0.36, 1.0, -0.05), "latao")
	# A luz do teto: um globo de vidro.
	var globo := Vector3(PORTA_X, H - 0.32, meio)
	_cyl(c, "Haste", 0.008, 0.008, 0.24, globo + Vector3(0, 0.2, 0), "latao", 6)
	_cyl(c, "Globo", 0.1, 0.07, 0.17, globo, "vidro_aceso", 8)
	var luz := _omni(c, "Luz", globo + Vector3(0, -0.15, 0), Color(1.0, 0.8, 0.55), 1.4, 4.5)
	luz.omni_attenuation = 1.3

	# A calha: o fundo e as laterais de latão, a frente de vidro com faixas, de
	# piso a teto (vem do andar de cima e desce ao saguão); a boca com a plaqueta.
	var cal := _group(c, "CalhaTubo", Vector3(CALHA_X, 0, fundo - 0.002))
	_box(cal, "Fundo", Vector3(0.18, H, 0.01), Vector3(0, H / 2, -0.005), "latao")
	for s in [-1, 1]:
		_box(cal, "Lado%d" % (s + 1), Vector3(0.014, H, 0.08), Vector3(s * 0.083, H / 2, -0.04), "latao")
	var vidro := _quad(cal, "Vidro", Vector2(0.152, H), Vector3(0, H / 2, -0.079), Vector3(0, 180, 0), "papel")
	var mv := StandardMaterial3D.new()
	mv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mv.albedo_color = Color(0.55, 0.62, 0.6, 0.2)
	mv.roughness = 0.15
	vidro.material_override = mv
	for y in [0.35, 0.95, 1.55, 2.15, 2.75]:
		_box(cal, "Faixa%d" % int(y * 100), Vector3(0.18, 0.025, 0.086), Vector3(0, y, -0.043), "latao")
	_box(cal, "Placa", Vector3(0.21, 0.17, 0.014), Vector3(0, CALHA_BOCA, -0.09), "latao")
	_quad(cal, "Fenda", Vector2(0.135, 0.014), Vector3(0, CALHA_BOCA, -0.0975), Vector3(0, 180, 0), "esmalte_preto")
	for t: Array in [["LETTERS", 0.05], ["U.S. MAIL", -0.05]]:
		var l := Label3D.new()
		l.name = "Plaqueta" + t[0].replace(".", "").replace(" ", "")
		l.text = t[0]
		l.font_size = 48
		l.pixel_size = 0.0006
		l.modulate = Color(0.25, 0.17, 0.08)
		l.outline_size = 0
		l.position = Vector3(0, CALHA_BOCA + t[1], -0.0975)
		l.rotation_degrees.y = 180
		_add(cal, l)

	# Quem anima: fora do grupo escondido (o envelope que desce é filho dela).
	var calha := CalhaCorreio.new()
	calha.name = "Calha"
	calha.position = Vector3(CALHA_X, CALHA_BOCA, fundo - 0.1)
	calha.rotation_degrees.y = 180
	_add(g, calha)
	calha.unique_name_in_owner = true
	calha.folha = _folha_porta
	calha.corredor = c
	calha.diante = Vector3(PORTA_X + 0.1, 0, D - 0.62)
	calha.queda = Vector2(-0.02, -CALHA_BOCA + 0.08)
	calha.som_abrir = load(SFX_DIR + "porta_rangendo.wav")
	calha.som_fechar = load(SFX_DIR + "porta_trinco.wav")
	calha.som_calha = load(SFX_DIR + "calha_correio.wav")


## O café e o uísque (Bebida, Fase 3d): a garrafa térmica e a xícara no pires,
## à direita na mesa; o copo (só depois do primeiro uísque) e o frasco, que mora
## na gaveta de cima à direita até o Dia 4. Antes de anotar o dia, `bebidas`.
func _bebida(g: Node3D) -> void:
	var b := Bebida.new()
	b.name = "Bebida"
	_add(g, b)
	b.unique_name_in_owner = true
	var garrafa := _group(b, "Garrafa", Vector3(0.75, MESA, -2.56))
	_cyl(garrafa, "Corpo", 0.042, 0.045, 0.22, Vector3(0, 0.11, 0), "esmalte_verde", 10)
	_cyl(garrafa, "Ombro", 0.03, 0.042, 0.03, Vector3(0, 0.235, 0), "aco", 10)
	_cyl(garrafa, "Tampa", 0.044, 0.044, 0.065, Vector3(0, 0.282, 0), "aco", 10)
	_marca(garrafa, "Boca", Vector3(0, 0.31, 0))
	_cyl(b, "Pires", 0.062, 0.055, 0.008, Vector3(0.72, MESA + 0.004, -1.87), "porcelana", 12)
	var xicara := _group(b, "Xicara", Vector3(0.72, MESA + 0.008, -1.87))
	_cyl(xicara, "Copa", 0.043, 0.03, 0.055, Vector3(0, 0.0275, 0), "porcelana", 12)
	var asa := _box(xicara, "Asa", Vector3(0.025, 0.03, 0.008), Vector3(0.05, 0.03, 0), "porcelana")
	asa.rotation_degrees.z = 10
	_nivel(xicara, 0.039, 0.042, 0.006, "cafe")
	var copo := _group(b, "Copo", Vector3(0.6, MESA, -2.03))
	_copo(copo)
	# O frasco, deitado dentro da gaveta.
	var frasco := _group(_gaveta_mesa, "Frasco", Vector3(0.0, -0.05, 0.16))
	frasco.rotation_degrees.x = -90
	_box(frasco, "Corpo", Vector3(0.09, 0.13, 0.024), Vector3(0, 0.065, 0), "aco")
	_cyl(frasco, "Gargalo", 0.009, 0.009, 0.02, Vector3(0.02, 0.14, 0), "aco", 6)
	_cyl(frasco, "Tampa", 0.012, 0.012, 0.014, Vector3(0.02, 0.155, 0), "latao", 6)
	_marca(frasco, "Boca", Vector3(0.02, 0.16, 0))
	b.garrafa = garrafa
	b.xicara = xicara
	b.copo = copo
	b.frasco = frasco
	b.gaveta = _gaveta_mesa
	# No espaço da escrivaninha (o pai da gaveta): em pé, junto ao copo.
	b.frasco_na_mesa = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(-25.0), 0)), Vector3(0.74, MESA, -0.1))
	b.som_servir = load(SFX_DIR + "servir.wav")
	b.som_gaveta = load(SFX_DIR + "gaveta.wav")
	var bebidas: Dictionary[int, int] = {1: 1, 2: 1, 3: 1, 4: 2}
	cena.set("bebidas", bebidas)


## A noite do Dia 5: anotado o dia, com o fogo aceso, "Sentar diante do fogo" na
## poltrona, com o copo de uísque no braço dela (LugarSono).
func _sono_fogo(g: Node3D) -> void:
	var fogo := _area(g, LugarSono.new(), "SentarFogo", Vector3(0.95, 1.05, 0.9), POLTRONA_POS + Vector3(0, 0.5, 0)) as LugarSono
	fogo.rotation_degrees.y = POLTRONA_ROT
	fogo.noite = 5
	fogo.prompt = "Sentar diante do fogo"
	fogo.condition = _composta(CompositeCondition.Mode.TODAS, [_cond_valor(&"sono", ValueCondition.Op.IGUAL, 5), _flag(&"lareira_dia_5")])
	fogo.assento = _assento_poltrona
	var olhar := Marker3D.new()
	olhar.name = "OlharFogo"
	olhar.position = Vector3(W - 0.25, 0.35, -0.6)
	_add(g, olhar)
	fogo.olhar = olhar
	fogo.linha = load("res://narrative/narration/sono_fogo.tres")
	# O copo servido, no braço da poltrona (ele o trouxe da mesa).
	var braco := POLTRONA_POS + Vector3(0.38, 0.62, 0.05).rotated(Vector3.UP, deg_to_rad(POLTRONA_ROT))
	var copo := _grupo_se(g, "CopoFogo", _flag(&"anotou_dia_5"))
	copo.position = braco
	_copo(copo)
	var nivel := copo.get_node("Nivel") as Node3D
	nivel.visible = true
	nivel.scale.y = 0.45
	fogo.copo = copo


## Um copo baixo de vidro, de uísque, com o nível (escondido enquanto vazio).
func _copo(copo: Node3D) -> void:
	var vidro := _cyl(copo, "Vidro", 0.033, 0.03, 0.075, Vector3(0, 0.0375, 0), "porcelana", 10)
	var mv := StandardMaterial3D.new()
	mv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mv.albedo_color = Color(0.75, 0.82, 0.8, 0.3)
	mv.roughness = 0.1
	vidro.material_override = mv
	_cyl(copo, "FundoGrosso", 0.029, 0.029, 0.01, Vector3(0, 0.005, 0), "porcelana", 10).material_override = mv
	_nivel(copo, 0.028, 0.06, 0.01, "uisque")


## Um marcador vazio (a boca de uma garrafa: por onde se serve).
func _marca(pai: Node3D, nome: String, pos: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = nome
	m.position = pos
	_add(pai, m)
	return m


## O líquido: um pivô no fundo que cresce para cima (Bebida escala o y).
func _nivel(recipiente: Node3D, raio: float, altura: float, fundo: float, mat: String) -> void:
	var nivel := _group(recipiente, "Nivel", Vector3(0, fundo, 0))
	nivel.visible = false
	_cyl(nivel, "Liquido", raio, raio * 0.92, altura, Vector3(0, altura / 2, 0), mat, 10)


## A cadeira de leitura no canto sudoeste, virada para o armário onde fica o
## fonógrafo: a noite do Dia 3 (LugarSono "Ouvir o disco outra vez") é aqui.
func _cadeira_leitura(g: Node3D) -> void:
	var c := _group(g, "CadeiraLeitura", LEITURA_POS, LEITURA_ROT)
	_box(c, "Assento", Vector3(0.5, 0.06, 0.48), Vector3(0, 0.44, 0), "estofado")
	_box(c, "Moldura", Vector3(0.52, 0.04, 0.5), Vector3(0, 0.4, 0), "madeira_escura")
	for x in [-0.23, 0.23]:
		for z in [-0.21, 0.21]:
			_box(c, "Perna%d%d" % [signf(x), signf(z)], Vector3(0.045, 0.4, 0.045), Vector3(x, 0.2, z), "madeira_escura")
		_box(c, "Braco%d" % signf(x), Vector3(0.05, 0.03, 0.46), Vector3(x, 0.66, 0.0), "madeira_escura")
		_box(c, "Apoio%d" % signf(x), Vector3(0.035, 0.22, 0.035), Vector3(x, 0.54, -0.2), "madeira_escura")
	_box(c, "Encosto", Vector3(0.5, 0.5, 0.05), Vector3(0, 0.74, 0.24), "estofado")
	_box(c, "EncostoMoldura", Vector3(0.54, 0.04, 0.07), Vector3(0, 1.0, 0.24), "madeira_escura")
	var assento := Marker3D.new()
	assento.name = "Assento"
	_add(c, assento)
	_assento_leitura = assento
	_colisao(c, "Colisao", [[Vector3(0.55, 0.9, 0.55), Vector3(0, 0.45, 0)]])


## O diário de Wilmarth (Diario): um caderno fechado à esquerda do mata-borrão.
## "Anotar o dia" só depois de postada a resposta do dia (`diario` = o dia); aberto,
## fica diante da cadeira, sobre o mata-borrão, e a pena da mesa escreve nele.
func _diario(g: Node3D, pena: Node3D) -> void:
	var d := Diario.new()
	d.name = "Diario"
	d.position = Vector3(-0.5, MESA, -1.99)
	d.rotation_degrees.y = 8
	_add(g, d)
	d.unique_name_in_owner = true
	d.pena = pena
	d.som_pena = load(SFX_DIR + "pena.wav")
	d.som_papel = load(SFX_DIR + "papel_pegar.wav")
	d.lugar_aberto = Transform3D(Basis.IDENTITY, Vector3(-0.02, MESA + 0.003, -2.02))
	var anotar := _area(d, Interactable.new(), "Anotar", Vector3(Diario.LARGURA + 0.02, 0.06, Diario.FUNDO + 0.02), Vector3(Diario.LARGURA * 0.5, 0.03, 0)) as Interactable
	anotar.prompt = "Anotar o dia"
	anotar.condition = _cond_valor(&"diario", ValueCondition.Op.MAIOR_OU_IGUAL, 1)
	# Fora da hora de anotar, o diário se lê e se folheia (o Diario alterna as duas).
	var ler := _area(d, Interactable.new(), "Ler", Vector3(Diario.LARGURA + 0.02, 0.06, Diario.FUNDO + 0.02), Vector3(Diario.LARGURA * 0.5, 0.03, 0)) as Interactable
	ler.prompt = "Ler o diário"


## A vista da janela (Fase 3d): Arkham em 3D na hora pedida ("dia", "entardecer",
## "noite", "chuva"; tools/cidade_arkham.gd). O painel antigo continua por baixo,
## só com a flag `painel` (tecla C em depuração), para comparar.
func _vista(parent: Node, hora: String, painel: String, nome := "Vista", z := -D - 1.2) -> Node3D:
	var v := _group(parent, nome)
	var quad := _quad(v, "Painel", Vector2(5.0, 3.0), Vector3(0, 1.6, z), Vector3.ZERO, painel)
	var so_painel := ConditionalNode.new()
	so_painel.name = "SoComPainel"
	so_painel.condition = _flag(&"painel")
	_add(quad, so_painel)
	var cidade: Node3D = _cidade.vista(hora)
	_add(v, cidade)
	for filho in cidade.get_children():
		filho.owner = cena
	var sem_painel := ConditionalNode.new()
	sem_painel.name = "SemPainel"
	sem_painel.condition = _flag(&"painel", true)
	_add(cidade, sem_painel)
	return v


## O tempo passando na sala (Lapso): a folhinha no peitoril da janela, de frente
## para a escrivaninha, o sol frio da manhã e a vista de dia que entram nos saltos.
func _lapso(g: Node3D) -> void:
	var lapso := Lapso.new()
	lapso.name = "Lapso"
	_add(g, lapso)
	lapso.sala = g
	lapso.ambiente = cena.get_node("WorldEnvironment")
	lapso.som_folha = load(SFX_DIR + "papel_pegar.wav")

	var sol := SpotLight3D.new()
	sol.name = "Sol"
	var sol_pos := Vector3(0.6, 3.4, -D - 1.5)
	sol.transform = Transform3D(Basis.looking_at(Vector3(-0.3, 0, 0.4) - sol_pos), sol_pos)
	sol.light_color = Color(0.85, 0.92, 1.0)
	sol.light_energy = 0.0
	sol.spot_range = 11.0
	sol.spot_angle = 30.0
	sol.shadow_enabled = true
	_add(lapso, sol)
	lapso.sol = sol
	var vista := _vista(lapso, "dia", "vista_dia", "VistaDia", -D - 1.18)
	vista.visible = false
	lapso.vista_dia = vista
	var tarde := _vista(lapso, "entardecer", "vista_entardecer", "VistaTarde", -D - 1.17)
	tarde.visible = false
	lapso.vista_tarde = tarde

	# A folhinha: base de madeira, o bloco inclinado para trás, a folha do dia.
	var f := _group(lapso, "Folhinha", Vector3(0.5, JANELA_Y.x + 0.03, -D + 0.1), -12)
	# Grande o bastante para a data se ler da cadeira, a 1,6 m.
	f.scale = Vector3.ONE * 1.6
	_box(f, "Base", Vector3(0.12, 0.025, 0.07), Vector3(0, 0.0125, 0), "madeira_escura")
	var bloco := _group(f, "Bloco", Vector3(0, 0.025, 0))
	bloco.rotation_degrees.x = -15
	_box(bloco, "Papel", Vector3(0.11, 0.14, 0.015), Vector3(0, 0.07, 0), "envelope")
	var folha := _quad(bloco, "Folha", Vector2(0.105, 0.135), Vector3(0, 0.07, 0.0081), Vector3.ZERO, "envelope")
	lapso.folha = folha
	var textos := []
	for t: Array in [["Mes", 0.046, 40, Color(0.6, 0.1, 0.08)], ["Dia", 0.002, 130, Color(0.1, 0.08, 0.08)], ["Semana", -0.048, 30, Color(0.1, 0.08, 0.08)]]:
		var label := Label3D.new()
		label.name = t[0]
		label.position = Vector3(0, t[1], 0.0006)
		label.font_size = t[2]
		label.pixel_size = 0.0004
		label.modulate = t[3]
		label.outline_size = 0
		label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		var fonte := SystemFont.new()
		fonte.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
		label.font = fonte
		_add(folha, label)
		textos.append(label)
	lapso.texto_mes = textos[0]
	lapso.texto_dia = textos[1]
	lapso.texto_semana = textos[2]

	cena.set("lapso", lapso)
	# Datas (1928): a chegada do correio de cada dia; o dia depois de cada salto.
	var datas: Array[int] = [0, Lapso.dia_do_ano(5, 8), Lapso.dia_do_ano(5, 24), Lapso.dia_do_ano(7, 2), Lapso.dia_do_ano(7, 18), Lapso.dia_do_ano(8, 15), Lapso.dia_do_ano(8, 31)]
	cena.set("datas_dia", datas)
	var depois: Dictionary[StringName, int] = {
		&"cartao_sexta": Lapso.dia_do_ano(7, 20),
		&"cartao_telegrama_akely": Lapso.dia_do_ano(8, 17), &"cartao_aprofundava": Lapso.dia_do_ano(8, 23),
		&"cartao_28_agosto": Lapso.dia_do_ano(8, 28), &"cartao_5_setembro": Lapso.dia_do_ano(9, 5),
		&"cartao_6_setembro": Lapso.dia_do_ano(9, 6), &"cartao_7_setembro": Lapso.dia_do_ano(9, 7),
	}
	cena.set("datas_cartao", depois)


## Canto nordeste, abaixo do telefone: arquivo de aço de quatro gavetas, com a
## máquina de escrever guardada em cima (só decoração).
func _arquivo(parent: Node) -> void:
	var a := _group(parent, "Arquivo", Vector3(W - 0.31, 0, -D + 0.26), 90)
	var alt := 1.32
	_box(a, "Corpo", Vector3(0.45, alt, 0.6), Vector3(0, alt / 2, 0), "aco")
	for i in 4:
		_quad(a, "Gaveta%d" % i, Vector2(0.41, 0.29), Vector3(0, 0.2 + i * 0.31, -0.302), Vector3(0, 180, 0), "gaveta_arquivo")
	_colisao(a, "Colisao", [[Vector3(0.45, alt, 0.6), Vector3(0, alt / 2, 0)]])

	# Máquina de escrever: base, corpo inclinado com as fileiras de teclas, rolo.
	var maquina := _group(a, "MaquinaEscrever", Vector3(0, alt, 0.02))
	_lote(maquina, "Corpo", [
		[Vector3(0.3, 0.05, 0.26), Vector3(0, 0.025, 0), Vector3.ZERO, Color.WHITE],
		[Vector3(0.28, 0.08, 0.14), Vector3(0, 0.09, 0.04), Vector3(-12, 0, 0), Color.WHITE],
		[Vector3(0.34, 0.035, 0.035), Vector3(0, 0.15, 0.1), Vector3.ZERO, Color.WHITE],
		[Vector3(0.04, 0.02, 0.02), Vector3(-0.19, 0.16, 0.1), Vector3(0, 0, 20), Color.WHITE],
	], "esmalte_preto")
	var teclas := []
	for fila in 4:
		for k in 10 - fila:
			teclas.append([Vector3(0.016, 0.01, 0.016), Vector3(-0.1 + k * 0.022 + fila * 0.011, 0.065 + fila * 0.012, -0.09 + fila * 0.028),
				Vector3(-12, 0, 0), Color.WHITE])
	_lote(maquina, "Teclas", teclas, "lencol")


## Cesto de papéis de vime, aberto, à direita da escrivaninha.
func _cesto(parent: Node) -> void:
	var c := _group(parent, "Cesto", Vector3(1.0, 0, -1.95))
	var fora := _cyl(c, "Fora", 0.15, 0.11, 0.34, Vector3(0, 0.17, 0), "madeira_clara", 9)
	(fora.mesh as CylinderMesh).cap_top = false
	var dentro := _cyl(c, "Dentro", 0.14, 0.1, 0.33, Vector3(0, 0.175, 0), "madeira_clara", 9)
	(dentro.mesh as CylinderMesh).cap_top = false
	(dentro.mesh as CylinderMesh).flip_faces = true
	_cyl(c, "Aro", 0.155, 0.155, 0.02, Vector3(0, 0.335, 0), "madeira_escura", 9)
	_colisao(c, "Colisao", [[Vector3(0.3, 0.34, 0.3), Vector3(0, 0.17, 0)]])


## Cortinas de veludo, abertas, uma de cada lado da janela; pregas de verdade
## (faixas em zigue-zague), para a luz facetada mostrar o caimento.
func _cortinas(parent: Node) -> void:
	var g := _group(parent, "Cortinas", Vector3(0, 0, -D + 0.1))
	var varao := _cyl(g, "Varao", 0.012, 0.012, 2.8, Vector3(0, 2.58, -0.02), "latao", 6)
	varao.rotation_degrees.z = 90
	for s in [-1, 1]:
		var pecas := []
		var alt := 2.52
		for k in 6:
			var ang := 28.0 if k % 2 else -28.0
			pecas.append([Vector3(0.085, alt, 0.012), Vector3(s * (1.06 + k * 0.075), 0.04 + alt / 2, 0), Vector3(0, ang, 0), Color.WHITE])
		_lote(g, "Cortina%s" % ("O" if s < 0 else "L"), pecas, "cortina")


# --- Os dias --------------------------------------------------------------------

const MESA := 0.78  # altura do tampo da escrivaninha
## A porta do escritório (sul): o meio do vão, a largura e a altura da folha.
const PORTA_X := -1.0
const PORTA_L := 0.92
const PORTA_H := 2.1
## O corredor atrás dela (largura) e a calha de correio na parede da frente.
const CORREDOR := 1.4
const CALHA_X := -0.92
const CALHA_BOCA := 1.15
## A poltrona (virada para a lareira) e a cadeira de leitura (virada para o
## fonógrafo, no canto sudoeste): onde ele adormece nas noites 5 e 3.
const POLTRONA_POS := Vector3(1.35, 0, 0.45)
const POLTRONA_ROT := -50.0
const LEITURA_POS := Vector3(-1.45, 0, 1.0)
const LEITURA_ROT := 153.0


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


## Onde o correio cai, junto à porta: x, z e a rotação em y (graus). A marca
## "Porta" (onde o jogador entra) fica em z 2,3; o envelope desliza para dentro.
const CHAO_A := Vector3(-0.85, 1.75, 25)
const CHAO_B := Vector3(-1.15, 1.6, -15)
const CHAO_C := Vector3(-0.55, 1.95, 50)

const REMETENTE_BRATTLEBORO := "H. W. Akeley\nGeneral Delivery, Brattleboro, Vt."
const TELEGRAMA := {
	remetente = "WESTERN UNION",
	destinatario = "Prof. A. N. Wilmarth\nMiskatonic University\nArkham, Mass.",
	selos = 0,
	carimbo_data = "",
}


## Correspondência que chega pela fresta (Correspondencia): o envelope cai em
## `chao` e, posto na mesa, fica em `mesa` (x, z e rotação em y, como CHAO_*).
## Aberto, é examinável com `titulo` e `descricao`.
func _correio(parent: Node, nome: String, id: StringName, chao: Vector3, mesa: Vector3, props: Dictionary, titulo: String, descricao: String) -> Correspondencia:
	var env := _envelope(parent, nome, Vector3(chao.x, 0.001, chao.y), chao.z, props)
	var c := _area(env, Correspondencia.new(), "Correio", Vector3(0.22, 0.05, 0.14)) as Correspondencia
	c.id = id
	c.mesa = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(mesa.z), 0)), Vector3(mesa.x, MESA + env.espessura() * 0.5, mesa.y))
	c.title = titulo
	c.description = descricao
	c.initial_rotation = Vector3(90, 0, 0)
	if props.get("selos", 1) == 0:
		c.prompt_abrir = "Abrir o telegrama"
		c.prompt_examinar = "Examinar o envelope do telegrama"
	c.som_chegada = load(SFX_DIR + "correio_fresta.wav")
	c.som_mao = load(SFX_DIR + "papel_pegar.wav")
	c.som_abrir = load(SFX_DIR + "papel_rasgando.wav")
	return c


## A correspondência `id` foi aberta.
func _aberto(id: StringName) -> ValueCondition:
	return _cond_valor(StringName("correio_%s" % id), ValueCondition.Op.MAIOR_OU_IGUAL, Correspondencia.ABERTO)


## Cartas que chegaram juntas: um maço amarrado cai em `chao`; posto na mesa
## (`mesa`) e desamarrado, some, e as `cartas` (ocultas até ali) ficam soltas na
## mesa, cada uma no seu lugar, para abrir uma a uma.
func _amarradas(parent: Node, id: StringName, chao: Vector3, mesa: Vector3, cartas: Array[Correspondencia]) -> Correspondencia:
	var maco := _maco(parent, "Maco", cartas.size(), 5)
	maco.position = Vector3(chao.x, 0.001, chao.y)
	maco.rotation_degrees.y = chao.z
	var c := _area(maco, Correspondencia.new(), "Correio", Vector3(0.24, 0.06, 0.16), Vector3(0, 0.02, 0)) as Correspondencia
	c.id = id
	c.mesa = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(mesa.z), 0)), Vector3(mesa.x, MESA, mesa.y))
	c.prompt_abrir = "Desamarrar o maço"
	c.some_ao_abrir = true
	c.soltar = cartas
	c.som_chegada = load(SFX_DIR + "correio_fresta.wav")
	c.som_mao = load(SFX_DIR + "papel_pegar.wav")
	c.som_abrir = load(SFX_DIR + "papel_pegar.wav")
	for carta in cartas:
		_dentro(carta.get_parent(), id)
	return c


## O nó só aparece depois de aberta a correspondência `id`. Um ConditionalNode
## por nó: se o nó já tem condição, combine com _aberto() nela.
func _dentro(node: Node, id: StringName) -> void:
	var cn := ConditionalNode.new()
	cn.name = "NoCorreio"
	cn.condition = _aberto(id)
	_add(node, cn)


## Peça tirada de um envelope (Correspondencia.retirar): aparece quando tirada,
## ou de qualquer jeito a partir de `dia_fixo` (Wilmarth as tirou fora de cena).
func _retirada(node: Node, id: StringName, n: int, dia_fixo: int) -> void:
	var cn := ConditionalNode.new()
	cn.name = "Retirada"
	cn.condition = _composta(CompositeCondition.Mode.QUALQUER, [
		_cond_valor(StringName("correio_%s_tiradas" % id), ValueCondition.Op.MAIOR_OU_IGUAL, n),
		_cond_valor(&"dia", ValueCondition.Op.MAIOR_OU_IGUAL, dia_fixo)])
	_add(node, cn)


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
	_vista(parent, {"vista_dia": "dia", "vista_entardecer": "entardecer"}.get(vista, "noite"), vista)
	var sol := SpotLight3D.new()
	sol.name = "Sol"
	sol.transform = Transform3D(Basis.looking_at(sol_alvo - sol_pos), sol_pos)
	sol.light_color = sol_cor
	sol.light_energy = sol_energia
	sol.spot_range = 11.0
	sol.spot_angle = 30.0
	sol.shadow_enabled = true
	_add(parent, sol)
	_omni(parent, "Preenchimento", Vector3(0, 2.6, 0.6), Color(1.0, 0.92, 0.8).lerp(sol_cor, 0.4), preench, 7.0)


func _dias(parent: Node) -> void:
	_debate(parent)
	var fotos := _fotografias(parent)
	_dia_1(parent)
	_dia_2(parent, fotos)
	var dia3 := _dia_3(parent)
	_fonografo(parent, dia3)
	_dia_4(parent)
	_telefone(parent)
	_dia_5(parent)
	_dia_6(parent)


## Dia 6 (cap. IV): as três últimas cartas manuscritas. Abre com a resposta
## mais calma de Akeley; o ânimo de Wilmarth cruza no correio com a carta de
## segunda, e cada carta lida traz a seguinte no dia seguinte
## (DocumentData.cartao_depois). Selada a carta registrada, a letra da última
## enche a tela e a tinta vira o céu de Vermont (Escritorio._para_o_interludio).
## Noite sem lua.
func _dia_6(parent: Node) -> void:
	var g := _grupo_do_dia(parent, 6)
	_vista(g, "noite", "vista_noite")
	_abajur(g)
	_lareira_noite(g, 6)
	# Depois de "falaram comigo", de novo — no céu sem lua.
	_criatura_no_ceu(g, _flag(&"leu_carta_akeley_terca"), &"viu_criatura_ceu_6")
	var janela := _area(g, StateInteractable.new(), "OlharJanela", Vector3(1.6, 1.5, 0.2), Vector3(0, 1.65, -D)) as StateInteractable
	janela.prompt = "Olhar"
	janela.notice = "Nenhuma lua. Só as nuvens, baixas e espessas."

	# Fim de agosto: menos terrores. Wilmarth o anima de novo.
	var setembro := _folha(g, "CartaSetembro", Vector3(-0.1, MESA + 0.003, -2.1), -6, "carta_akeley_setembro", "Ler a carta", false)
	_dentro(setembro.get_parent(), &"setembro")
	_correio(g, "Envelope", &"setembro", CHAO_A, Vector3(-0.15, -2.47, -4), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "AUG 31\n1928",
	}, "Envelope de Brattleboro",
		"A letra ainda treme, mas está mais firme do que em agosto. Carimbo de Brattleboro, 31 de agosto.")
	var animo := _grupo_se(g, "Animo", _flag(&"narrou_cartao_5_setembro", true))
	_escrever(animo, "animo_dia_6", &"leu_carta_akeley_setembro")

	# Segunda, terça e quarta: uma por dia, cada uma caindo pela fresta no escuro
	# do salto. As três escritas em Brattleboro (cap. IV).
	var cartas := [
		["Segunda", &"narrou_cartao_5_setembro", "carta_akeley_segunda", "Ler a carta de segunda-feira",
			Vector3(0.2, MESA + 0.005, -2.0), 7, &"segunda", CHAO_B, Vector3(0.62, -2.2, 8), "SEP 3",
			"A letra treme mais do que nunca. Carimbo de Brattleboro, 3 de setembro."],
		["Terca", &"narrou_cartao_6_setembro", "carta_akeley_terca", "Ler a carta de terça-feira",
			Vector3(-0.42, MESA + 0.007, -1.98), -9, &"terca", CHAO_C, Vector3(0.42, -2.0, -5), "SEP 4",
			"O endereço é um rabisco que quase sai do envelope. Carimbo de Brattleboro, 4 de setembro."],
		["Quarta", &"narrou_cartao_7_setembro", "carta_akeley_quarta", "Ler a carta de quarta-feira",
			Vector3(0.02, MESA + 0.009, -1.9), 3, &"quarta", CHAO_A, Vector3(0.06, -2.48, 3), "SEP 5",
			"Mal se lê o meu nome. Carimbo de Brattleboro, 5 de setembro."],
	]
	var quarta: Node3D
	for c: Array in cartas:
		var grupo := _grupo_se(g, c[0], _flag(c[1]))
		var folha := _folha(grupo, "Folha", c[4], c[5], c[2], c[3], false)
		_dentro(folha.get_parent(), c[6])
		_correio(grupo, "Envelope", c[6], c[7], c[8], {
			remetente = REMETENTE_BRATTLEBORO,
			carimbo_cidade = "BRATTLEBORO",
			carimbo_data = "%s\n1928" % c[9],
		}, "Envelope de Brattleboro", c[10])
		quarta = grupo
	_escrever(quarta, "resposta_dia_6", &"leu_carta_akeley_quarta")


## Dia 5 (cap. IV): agosto. A carta frenética, a oferta de ajuda, o telegrama
## "AKELY", o bilhete que o desmente e a carta da "saída digna". As cartas
## cruzam o correio: cada carta selada salta no tempo (ReplyData.cartao_depois,
## Ligacao.cartao_depois), e o que chega depois aparece no escuro, pela flag
## `narrou_<cartão>`. Noite de chuva; um vulto passa pela janela (não confirmado).
func _dia_5(parent: Node) -> void:
	var g := _grupo_do_dia(parent, 5)
	_vista(g, "chuva", "vista_noite")
	_chuva(g)
	_abajur(g)
	_lareira_noite(g, 5)
	_sono_fogo(g)
	var janela := _area(g, StateInteractable.new(), "OlharJanela", Vector3(1.6, 1.5, 0.2), Vector3(0, 1.65, -D)) as StateInteractable
	janela.prompt = "Olhar"
	janela.notice = "Só a chuva, escorrendo no vidro."

	# 15 de agosto: as cartas trêmulas e a oferta de ir a Vermont. As duas
	# chegaram juntas, amarradas num maço; desamarrado na mesa, ficam soltas.
	var agosto := _folha(g, "CartaAgosto", Vector3(-0.26, MESA + 0.003, -2.08), 9, "carta_akeley_agosto", "Ler a carta", false)
	_dentro(agosto.get_parent(), &"agosto")
	var c_agosto := _correio(g, "EnvelopeAgosto", &"agosto", CHAO_B, Vector3(0.1, -2.48, -3), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "AUG 7\n1928",
	}, "Envelope de Brattleboro",
		"A letra treme tanto que o endereço desce em degraus. Carimbo de Brattleboro, 7 de agosto.")
	var c15 := _folha(g, "Carta15", Vector3(0.0, MESA + 0.005, -2.12), -5, "carta_akeley_15_agosto", "Ler a carta de 15 de agosto", false)
	_dentro(c15.get_parent(), &"15_agosto")
	var c_15 := _correio(g, "Envelope", &"15_agosto", CHAO_A, Vector3(-0.12, -2.47, 5), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "AUG 14\n1928",
	}, "Envelope de Brattleboro",
		"Escrita no próprio correio de Brattleboro e posta ali mesmo: chegou sem demora. A letra mal se sustenta na linha.")
	_amarradas(g, &"agosto_maco", CHAO_A, Vector3(-0.05, -1.86, 4), [c_agosto, c_15])
	var oferta := _grupo_se(g, "Oferta", _flag(&"narrou_cartao_telegrama_akely", true))
	_escrever(oferta, "oferta_dia_5", &"leu_carta_akeley_15_agosto")

	# A resposta: um telegrama de Bellows Falls, assinado AKELY.
	var tel := _grupo_se(g, "TelegramaAkely", _flag(&"narrou_cartao_telegrama_akely"))
	_correio(tel, "EnvelopeTelegrama", &"telegrama_akely", CHAO_C, Vector3(0.62, -2.2, 12), TELEGRAMA,
		"Telegrama de Bellows Falls", "O envelope amarelo da Western Union. Em resposta a uma carta inteira, só isto.")
	var papel := _box(tel, "Papel", Vector3(0.2, 0.003, 0.14), Vector3(0.45, MESA + 0.0045, -1.94), "envelope")
	papel.rotation_degrees.y = -10
	_dentro(papel, &"telegrama_akely")
	# Depois do bilhete, o mesmo papel serve para comparar (uma área por vez).
	var comparando := _composta(CompositeCondition.Mode.TODAS, [_flag(&"leu_bilhete_akeley_agosto"), _flag(&"comparou_assinatura", true)])
	var lendo := comparando.duplicate() as CompositeCondition
	lendo.negate = true
	var ler := _area(_grupo_se(papel, "Leitura", lendo), DocumentPickup.new(), "Ler", Vector3(0.24, 0.06, 0.18)) as DocumentPickup
	ler.prompt = "Ler o telegrama"
	ler.remove_visual = false
	ler.document = load("res://narrative/documents/telegrama_akely.tres")
	var comparar := _area(_grupo_se(papel, "Comparacao", comparando), StateInteractable.new(), "Comparar", Vector3(0.24, 0.06, 0.18)) as StateInteractable
	comparar.prompt = "Comparar a assinatura com as cartas"
	comparar.changes = {&"comparou_assinatura": 1.0, &"exposicao": 0.03}
	comparar.narration = load("res://narrative/narration/comparar_assinatura.tres")

	# O bilhete: ele nunca mandou o telegrama. Depois, a carta que renova a oferta.
	var bilhete := _grupo_se(g, "Bilhete", _flag(&"narrou_cartao_aprofundava"))
	var folha_bilhete := _folha(bilhete, "Folha", Vector3(-0.52, MESA + 0.005, -1.98), -7, "bilhete_akeley_agosto", "Ler o bilhete", false)
	_dentro(folha_bilhete.get_parent(), &"bilhete")
	_correio(bilhete, "Envelope", &"bilhete", CHAO_A, Vector3(0.65, -1.93, -6), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "AUG 22\n1928",
	}, "Envelope de Brattleboro",
		"Um envelope fino, endereçado às pressas. Carimbo de Brattleboro, 22 de agosto.")
	var renovacao := _grupo_se(g, "Renovacao", _composta(CompositeCondition.Mode.TODAS,
		[_flag(&"narrou_cartao_aprofundava"), _flag(&"narrou_cartao_28_agosto", true)]))
	_escrever(renovacao, "renovacao_dia_5", &"comparou_assinatura")

	# 28 de agosto: "uma saída digna". A resposta do dia (a que leva para casa).
	var c28 := _grupo_se(g, "Carta28", _flag(&"narrou_cartao_28_agosto"))
	var folha28 := _folha(c28, "Folha", Vector3(0.22, MESA + 0.007, -1.96), 6, "carta_akeley_28_agosto", "Ler a carta de 28 de agosto", false)
	_dentro(folha28.get_parent(), &"28_agosto")
	_correio(c28, "Envelope", &"28_agosto", CHAO_C, Vector3(-0.05, -1.86, 4), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "AUG 27\n1928",
	}, "Envelope de Brattleboro",
		"A letra continua trêmula, mas o envelope veio fechado com cuidado. Carimbo de Brattleboro, 27 de agosto.")
	_escrever(c28, "resposta_dia_5", &"leu_carta_akeley_28_agosto")

	# Depois do bilhete, quem olhar para a janela vê algo passar lá fora. Uma vez.
	var sombra := Aparicao.new()
	sombra.name = "Sombra"
	sombra.position = Vector3(-1.7, 1.6, -D - 0.35)
	sombra.deslocamento = Vector3(3.4, 0.15, 0)
	sombra.duracao = 1.6
	sombra.condition = _flag(&"leu_bilhete_akeley_agosto")
	sombra.flag = &"viu_sombra_janela"
	sombra.exposure = 0.03
	_add(g, sombra)
	_quad(sombra, "Vulto", Vector2(0.9, 1.3), Vector3.ZERO, Vector3.ZERO, "sombra")


## Dia 4 (cap. III): a pedra que não chega. O telegrama de quarta-feira, a carta
## ansiosa de julho com a foto do "exército" de pegadas, e o telefone.
func _dia_4(parent: Node) -> void:
	var g := _grupo_do_dia(parent, 4)
	# A tarde de julho; de volta de Boston (`anoiteceu_dia_4`), a noite e o abajur.
	var tarde := _grupo_se(g, "Tarde", _flag(&"anoiteceu_dia_4", true))
	_luz(tarde, "vista_dia", Color(1.0, 0.9, 0.7), 7.5, Vector3(-0.3, 0, 0.4), Vector3(0.6, 3.6, -D - 1.5), 1.1)
	var noite := _grupo_se(g, "Noite", _flag(&"anoiteceu_dia_4"))
	_vista(noite, "noite", "vista_noite")
	_omni(noite, "Lua", Vector3(0, 2.2, -2.6), Color(0.5, 0.6, 0.9), 0.4, 5.0)
	_abajur(noite)
	var telegrama := _box(g, "Telegrama", Vector3(0.2, 0.003, 0.14), Vector3(0.02, MESA + 0.0045, -2.12), "envelope")
	telegrama.rotation_degrees.y = -4
	var ler := _area(telegrama, DocumentPickup.new(), "Ler", Vector3(0.24, 0.06, 0.18)) as DocumentPickup
	ler.prompt = "Ler o telegrama"
	ler.remove_visual = false
	ler.document = load("res://narrative/documents/telegrama_pedra.tres")
	_dentro(telegrama, &"telegrama_pedra")
	_correio(g, "EnvelopeTelegrama", &"telegrama_pedra", CHAO_A, Vector3(0.08, -2.47, -6), TELEGRAMA,
		"Telegrama de Bellows Falls", "O envelope amarelo da Western Union, trazido por um mensageiro de manhã cedo.")
	var julho_carta := _folha(g, "CartaJulho", Vector3(0.36, MESA + 0.003, -2.02), 10, "carta_akeley_julho", "Ler a carta", false)
	_dentro(julho_carta.get_parent(), &"julho")
	var c := _correio(g, "Envelope", &"julho", CHAO_B, Vector3(-0.2, -2.47, 7), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "JUL 12\n1928",
	}, "Envelope de Brattleboro",
		"A letra de Akeley, mais trêmula. Carimbo de Brattleboro, 12 de julho — ele já não confia no correio de Townshend.")
	_escrever(g, "resposta_dia_4", &"ligou_relato_keene")

	# A foto de julho vem no envelope e fica junto das outras, dali em diante.
	var julho := _grupo_se(parent, "FotografiaJulho", _cond_valor(&"dia", ValueCondition.Op.MAIOR_OU_IGUAL, 4))
	var foto := Fotografia.new()
	foto.name = "Foto10"
	foto.imagem = load(TEX_DIR + "foto_exercito.png")
	# A ponta passa por cima do mata-borrão.
	foto.position = Vector3(-0.25, MESA + 0.0035 + Fotografia.ESPESSURA * 0.5, -2.33)
	foto.rotation_degrees.y = 6
	_add(julho, foto)
	_retirada(foto, &"julho", 1, 5)
	c.retirar = [foto]
	var ex := _examinavel(foto, Vector3(0.13, 0.03, 0.1), "Examinar a fotografia", "Fotografia — o exército de pegadas",
		"Repulsivamente perturbadora: um verdadeiro exército de pegadas em fila, de frente para uma linha igualmente cerrada e resoluta de pegadas de cães. Tirada depois de uma noite em que os cães se superaram em latidos e uivos.")
	ex.flag = &"viu_foto_exercito"
	ex.exposure = 0.04


## Telefone de parede (caixa de madeira, manivela, fone no gancho), na parede
## leste, ao lado da escrivaninha. Só se usa quando há ligação disponível.
## O do sonho da noite do Dia 5 é outro, com a sua ligação (`ids`).
func _telefone(parent: Node, ids: Array = ["agencia_arkham", "boston", "telegrama_noturno", "relato_keene", "resposta_telegrama"], nome := "Telefone") -> Telefone:
	var g := _group(parent, "TelefoneParede", Vector3(W - 0.07, 1.45, -2.25), 90)
	_box(g, "Caixa", Vector3(0.24, 0.38, 0.12), Vector3.ZERO, "madeira_clara")
	for s in [-1, 1]:
		var sineta := _cyl(g, "Sineta%d" % s, 0.035, 0.035, 0.03, Vector3(s * 0.05, 0.14, -0.075), "latao", 8)
		sineta.rotation_degrees.x = 90
	var bocal := _cyl(g, "Bocal", 0.03, 0.015, 0.08, Vector3(0, 0.0, -0.1), "ferro", 8)
	bocal.rotation_degrees.x = 90
	_cyl(g, "Fone", 0.018, 0.022, 0.12, Vector3(-0.15, -0.02, -0.02), "ferro", 8)
	_box(g, "Manivela", Vector3(0.012, 0.08, 0.012), Vector3(0.14, 0.02, -0.03), "ferro")
	var tel := _area(g, Telefone.new(), nome, Vector3(0.36, 0.45, 0.3), Vector3(0, 0, -0.08)) as Telefone
	tel.unique_name_in_owner = nome == "Telefone"
	tel.campainha = load(SFX_DIR + "campainha.wav")
	tel.gancho = load(SFX_DIR + "telefone_gancho.wav")
	tel.manivela = load(SFX_DIR + "telefone_manivela.wav")
	tel.linha = load(SFX_DIR + "telefone_linha.wav")
	tel.voz = load(SFX_DIR + "telefone_voz.wav")
	var ligs: Array[Ligacao] = []
	for id in ids:
		ligs.append(load("res://narrative/ligacoes/%s.tres" % id))
	tel.conversas = ligs
	return tel


## Dia 3 (cap. III): o disco chega de Brattleboro. Noite; abajur na mesa.
func _dia_3(parent: Node) -> Node3D:
	var g := _grupo_do_dia(parent, 3)
	_vista(g, "noite", "vista_noite")
	_omni(g, "Lua", Vector3(0, 2.2, -2.6), Color(0.5, 0.6, 0.9), 0.4, 5.0)
	_abajur(g)
	# Depois do disco, algo cruza o céu da cidade.
	_criatura_no_ceu(g, _flag(&"tocou_disco"), &"viu_criatura_ceu_3")

	var bilhete := _folha(g, "Bilhete", Vector3(-0.05, MESA + 0.003, -2.16), 8, "bilhete_disco", "Ler o bilhete", false)
	var transcricao := _folha(g, "Transcricao", Vector3(0.25, MESA + 0.003, -2.05), -12, "transcricao_disco", "Ler a transcrição", false)
	transcricao.get_parent().set_meta(&"treme", true)
	bilhete.get_parent().set_meta(&"treme", true)
	_dentro(bilhete.get_parent(), &"dia_3")
	_dentro(transcricao.get_parent(), &"dia_3")

	# O pacote do expresso não passa na fresta: fica no chão junto à porta. Na
	# mesa, cortado o barbante, saem o bilhete, a transcrição e o estojo do cilindro.
	var pacote := _group(g, "Pacote", Vector3(-0.45, 0, 2.45), 10)
	var tam := Vector3(0.24, 0.1, 0.16)
	_box(pacote, "Caixa", tam, Vector3(0, tam.y / 2, 0), "papel_pardo")
	var barbante := _barbante(pacote, tam, -20)
	# A etiqueta do expresso colada na tampa, fora do caminho do barbante.
	_quad(pacote, "Etiqueta", Vector2(0.1, 0.06), Vector3(-0.065, tam.y + 0.001, 0.04), Vector3(-90, 0, 0), "envelope")
	var pac := _area(pacote, Correspondencia.new(), "Correio", Vector3(0.28, 0.14, 0.2), Vector3(0, 0.05, 0)) as Correspondencia
	pac.id = &"dia_3"
	# Na ponta leste da mesa: no lugar antigo (oeste) tampava as fotografias.
	pac.mesa = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(-8), 0)), Vector3(0.64, MESA, -2.12))
	pac.prompt_pegar = "Pegar o pacote"
	pac.prompt_abrir = "Cortar o barbante"
	pac.prompt_examinar = "Examinar o pacote"
	pac.title = "O pacote do expresso"
	pac.description = "American Railway Express, despachado de Brattleboro: Akeley não confiava no ramal ao norte de lá."
	pac.initial_rotation = Vector3(25, 20, 0)
	pac.fechado = barbante
	pac.mao_posicao = Vector3(0.19, -0.26, -0.56)
	pac.mao_rotacao = Vector3(22, -24, 0)
	pac.som_chegada = load(SFX_DIR + "pacote_chao.wav")
	pac.som_mao = load(SFX_DIR + "papel_pegar.wav")
	pac.som_abrir = load(SFX_DIR + "papel_rasgando.wav")
	var etiqueta := Label3D.new()
	etiqueta.name = "EtiquetaTexto"
	etiqueta.text = "AMERICAN RAILWAY EXPRESS\nFrom H. W. Akeley, Brattleboro, Vt.\nTo A. N. Wilmarth, Arkham, Mass."
	etiqueta.font_size = 40
	etiqueta.pixel_size = 0.00006
	etiqueta.modulate = Color(0.12, 0.1, 0.12)
	etiqueta.outline_size = 0
	etiqueta.position = Vector3(-0.065, tam.y + 0.0015, 0.04)
	etiqueta.rotation_degrees.x = -90
	etiqueta.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_add(pacote, etiqueta)
	# Sai do pacote aberto; vai para a máquina com o cilindro.
	var estojo := _grupo_se(g, "Estojo", _composta(CompositeCondition.Mode.TODAS,
		[_aberto(&"dia_3"), _flag(&"fono_cilindro", true)]))
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
	# Aberto em cima: só paredes e fundo colidem. Uma caixa maciça bloqueava o
	# raio de interação e as peças lá dentro nunca podiam ser miradas.
	_colisao(caixote, "Colisao", [
		[Vector3(0.5, 0.02, 0.38), Vector3(0, 0.01, 0)],
		[Vector3(0.02, 0.3, 0.38), Vector3(-0.24, 0.15, 0)],
		[Vector3(0.02, 0.3, 0.38), Vector3(0.24, 0.15, 0)],
		[Vector3(0.5, 0.3, 0.02), Vector3(0, 0.15, -0.18)],
		[Vector3(0.5, 0.3, 0.02), Vector3(0, 0.15, 0.18)],
	])
	# [flag, ação, posição, tamanho da área]
	var pecas := [
		[&"fono_corneta", "Montar a corneta", Vector3(-0.08, 0.12, 0), Vector3(0.3, 0.16, 0.2)],
		[&"fono_manivela", "Montar a manivela", Vector3(0.12, 0.08, 0.06), Vector3(0.16, 0.1, 0.1)],
		[&"fono_agulha", "Pôr uma agulha", Vector3(0.14, 0.06, -0.08), Vector3(0.12, 0.1, 0.1)],
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
		var montar := _area(peca, StateInteractable.new(), "Montar", p[3]) as StateInteractable
		montar.prompt = p[1]
		montar.changes = {p[0]: 1.0}
		montar.additive = false

	_escrever(g, "resposta_dia_3", &"tocou_disco")
	return g


## Noite fria do dia `n` (Dias 5 e 6): a lenha na grelha e "Acender a lareira".
## Acesa (`lareira_dia_<n>`), uma luz quente e trêmula clareia a metade leste da
## sala, com o crepitar — é o que deixa as últimas noites legíveis sem acender a sala.
func _lareira_noite(parent: Node, n: int) -> void:
	var fogo_pos := Vector3(W - 0.22, 0.19, -0.6)
	var lenha := _group(parent, "Lenha", fogo_pos)
	# Duas toras lado a lado ao longo da grelha e uma atravessada por cima.
	for k in 3:
		var tora := _cyl(lenha, "Tora%d" % k, 0.035, 0.04, 0.42, Vector3([-0.05, 0.05, 0.0][k], [0.035, 0.035, 0.09][k], 0), "madeira_escura", 7)
		tora.rotation_degrees = Vector3(90, [4.0, -6.0, 25.0][k], 0)
	var chave := StringName("lareira_dia_%d" % n)
	var acender := _area(parent, StateInteractable.new(), "AcenderLareira", Vector3(0.5, 0.8, 0.9), Vector3(W - 0.3, 0.45, -0.6)) as StateInteractable
	acender.prompt = "Acender a lareira"
	acender.changes = {chave: 1.0}
	acender.additive = false
	acender.condition = _flag(chave, true)

	var aceso := _grupo_se(parent, "Fogo", _flag(chave))
	var fogo := Fogo.new()
	fogo.name = "Chamas"
	fogo.position = fogo_pos
	_add(aceso, fogo)
	# Brasas embaixo da lenha.
	_box(fogo, "Brasas", Vector3(0.24, 0.02, 0.4), Vector3(0, -0.005, 0), "vidro_aceso")
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.albedo_texture = load(TEX_DIR + "chama.png")
	var chamas: Array[Node3D] = []
	for k in 5:
		var q := QuadMesh.new()
		q.size = Vector2(0.14, 0.28)
		q.center_offset = Vector3(0, 0.14, 0)
		q.material = mat
		var mi := MeshInstance3D.new()
		mi.name = "Chama%d" % k
		mi.mesh = q
		mi.position = Vector3(0, 0.02, -0.16 + k * 0.08)
		mi.scale = Vector3.ONE * (0.75 + 0.4 * sin(k * 1.9 + 0.4) ** 2)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(fogo, mi)
		chamas.append(mi)
	fogo.chamas = chamas
	var luz := _omni(fogo, "Luz", Vector3(-0.3, 0.3, 0), Color(1.0, 0.58, 0.28), 2.0, 5.5)
	luz.shadow_enabled = true
	luz.omni_attenuation = 1.2
	fogo.luz = luz
	fogo.energia = 2.0
	var crepitar := AudioStreamPlayer3D.new()
	crepitar.name = "Crepitar"
	crepitar.stream = load(SFX_DIR + "lareira.wav")
	crepitar.autoplay = true
	crepitar.bus = &"Ambience"
	crepitar.volume_db = -6.0
	crepitar.unit_size = 2.5
	_add(fogo, crepitar)
	acender.som = load(SFX_DIR + "fosforo.wav")


## Os sonhos da noite depois de cada dia (Escritorio._sonhar): cada um num grupo
## `Sonhos/NoiteN` que só existe com `sonhando == N`, enquanto o conteúdo dos dias
## some. Sem susto; acordam numa ação (a flag de `sonhos`).
func _sonhos(parent: Node) -> void:
	var s := _group(parent, "Sonhos")
	var noite := func(n: int) -> Node3D:
		return _grupo_se(s, "Noite%d" % n, _cond_valor(&"sonhando", ValueCondition.Op.IGUAL, n))
	_sonho_garras(noite.call(2))
	_sonho_disco(noite.call(3))
	_sonho_pedra(noite.call(4))
	_sonho_telefone(noite.call(5))
	var acordar: Dictionary[int, StringName] = {
		2: &"narrou_sonho_garra", 3: &"acordou_noite_3", 4: &"viu_pedra_sonho", 5: &"ligou_sonho_telefone",
	}
	cena.set("sonhos", acordar)


## Noite do Dia 2 (as fotografias): marcas de garra, de lama, da porta
## até a mesa onde ele dorme, subindo por ela até a janela, que dá para o
## círculo de pedras. Acorda ao seguir as marcas de volta até a porta, onde
## começam ("Chamei-a de pegada...").
func _sonho_garras(g: Node3D) -> void:
	_quad(g, "Vista", Vector2(5.0, 3.0), Vector3(0, 1.6, -D - 1.15), Vector3.ZERO, "vista_circulo")
	_omni(g, "Lua", Vector3(0.2, 2.2, -2.4), Color(0.5, 0.6, 0.9), 1.4, 7.0)
	# A luz fria que deita no chão e mostra o caminho das marcas (acima do tapete).
	var caminho := SpotLight3D.new()
	caminho.name = "Caminho"
	caminho.transform = Transform3D(Basis.looking_at(Vector3(0.1, -1, -0.25)), Vector3(-0.6, 2.8, 1.2))
	caminho.light_color = Color(0.6, 0.68, 0.85)
	caminho.light_energy = 2.2
	caminho.spot_angle = 50.0
	caminho.spot_range = 5.0
	_add(g, caminho)
	var rng := RandomNumberGenerator.new()
	rng.seed = 22
	# O caminho: da porta ao pé da mesa; depois o tampo e o peitoril.
	var de := Vector2(-1.0, 2.75)
	var ate := Vector2(-0.05, -1.75)
	var rumo := rad_to_deg(atan2(-(ate - de).x, -(ate - de).y))
	for k in 12:
		var p := de.lerp(ate, k / 11.0) + Vector2(0.12 if k % 2 else -0.12, 0)
		_quad(g, "Pegada%d" % k, Vector2(0.32, 0.32), Vector3(p.x, 0.014, p.y), Vector3(-90, rumo, 0), "pegada")
	for k in 3:
		var p := Vector3(-0.1 + (0.1 if k % 2 else -0.1), MESA + 0.004, -1.95 - k * 0.22)
		_quad(g, "PegadaMesa%d" % k, Vector2(0.2, 0.2), p, Vector3(-90, 0, 0), "pegada")
	_quad(g, "PegadaPeitoril", Vector2(0.18, 0.18), Vector3(0.0, JANELA_Y.x + 0.035, -D + 0.02), Vector3(-90, 0, 0), "pegada")
	var gatilho := NarrationTrigger.new()
	gatilho.line = load("res://narrative/narration/sonho_garra.tres")
	_area(g, gatilho, "NaPorta", Vector3(1.4, 2.0, 0.9), Vector3(-1.0, 1.0, 2.4))


## Noite do Dia 3 (o disco): tudo escuro; só o fonógrafo, na mesa, sob uma luz,
## tocando sozinho. Acorda ao levantar a agulha.
func _sonho_disco(g: Node3D) -> void:
	# De lado para quem chega: a corneta se vê de perfil, virada para a sala.
	var f := _group(g, "Fonografo", Vector3(0.05, MESA, -2.36), 120)
	_box(f, "Caixa", Vector3(0.34, 0.14, 0.24), Vector3(0, 0.07, 0), "madeira_clara")
	var cera := _cyl(f, "Cera", 0.032, 0.032, 0.11, Vector3(0, 0.19, 0.02), "cinzas", 10)
	cera.rotation_degrees.z = 90
	var cone := _cyl(f, "Corneta", 0.2, 0.015, 0.5, Vector3(0.0, 0.42, -0.18), "latao", 10)
	cone.rotation_degrees = Vector3(-60, 0, 0)
	var luz := SpotLight3D.new()
	luz.name = "Luz"
	luz.transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(0, 1.6, 0))
	luz.light_color = Color(0.9, 0.85, 0.6)
	luz.light_energy = 4.5
	luz.spot_angle = 26.0
	luz.spot_range = 3.0
	luz.shadow_enabled = true
	_add(f, luz)
	var disco := AudioStreamPlayer3D.new()
	disco.name = "Disco"
	disco.stream = load(SFX_DIR + "disco_longo.wav")
	disco.autoplay = true
	disco.bus = &"Voice"
	disco.unit_size = 3.0
	_add(f, disco)
	var agulha := _area(f, StateInteractable.new(), "Agulha", Vector3(0.45, 0.5, 0.4), Vector3(0, 0.2, 0)) as StateInteractable
	agulha.prompt = "Levantar a agulha"
	agulha.changes = {&"acordou_noite_3": 1.0}
	agulha.additive = false


## Noite do Dia 4 (a pedra que não chega): a pedra negra está na mesa; pela
## janela, a plataforma de Keene à noite e um homem magro de costas, e a voz
## zumbida. Acorda depois de examinar a pedra (o sono pesa).
func _sonho_pedra(g: Node3D) -> void:
	_quad(g, "Vista", Vector2(5.0, 3.0), Vector3(0, 1.6, -D - 1.15), Vector3.ZERO, "vista_plataforma")
	_quad(g, "Homem", Vector2(0.26, 0.65), Vector3(0.45, 1.2, -D - 0.85), Vector3.ZERO, "homem_magro")
	_omni(g, "Janela", Vector3(0.3, 1.8, -2.6), Color(0.85, 0.75, 0.55), 0.6, 4.0)
	var pedra := _group(g, "Pedra", Vector3(-0.05, MESA, -2.3), 8)
	_box(pedra, "Bloco", Vector3(0.3, 0.55, 0.14), Vector3(0, 0.275, 0), "pedra_negra")
	var lasca := _box(pedra, "Lasca", Vector3(0.22, 0.2, 0.13), Vector3(0.06, 0.5, 0.005), "pedra_negra")
	lasca.rotation_degrees.z = 32
	var ex := _area(pedra, Examinable.new(), "Examinar", Vector3(0.4, 0.65, 0.3), Vector3(0, 0.3, 0)) as Examinable
	ex.prompt = "Examinar a pedra"
	ex.title = "A pedra negra"
	ex.description = "A grande pedra negra de Round Hill — a que nunca chegou. Que princípios geométricos guiaram o corte dela, eu não saberia dizer. Distingo poucos hieróglifos, mas um ou dois me dão um choque."
	ex.flag = &"viu_pedra_sonho"
	var luz := _omni(pedra, "Luz", Vector3(0.3, 0.9, 0.4), Color(0.7, 0.75, 0.9), 1.2, 2.5)
	luz.shadow_enabled = true
	var voz := AudioStreamPlayer3D.new()
	voz.name = "Voz"
	voz.stream = load(SFX_DIR + "zumbido.wav")
	voz.autoplay = true
	voz.bus = &"Whisper"
	voz.volume_db = -4.0
	voz.position = Vector3(0.45, 1.3, -D - 0.6)
	voz.unit_size = 3.0
	_add(g, voz)


## Noite do Dia 5 (o telegrama AKELY): chove dentro da sala; o telefone toca.
## Atendido, só um zumbido na linha, soletrando. Acorda ao desligar.
func _sonho_telefone(g: Node3D) -> void:
	_omni(g, "Penumbra", Vector3(0.5, 2.4, -1.0), Color(0.45, 0.5, 0.65), 0.7, 7.0)
	var chuva := _chuva_dentro(g)
	chuva.name = "ChuvaDentro"
	var som := AudioStreamPlayer3D.new()
	som.name = "Chuva"
	som.stream = load(SFX_DIR + "chuva.wav")
	som.autoplay = true
	som.bus = &"Ambience"
	som.position = Vector3(0, 2.0, 0)
	som.unit_size = 6.0
	_add(g, som)
	var tel := _telefone(g, ["sonho_telefone"], "TelefoneSonho")
	tel.voz = load(SFX_DIR + "zumbido.wav")
	tel.voz_db = -6.0


## Chuva caindo dentro da sala, do teto ao chão, em toda a planta.
func _chuva_dentro(parent: Node) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = Vector3(0, H - 0.1, 0)
	p.amount = 500
	p.lifetime = 0.6
	p.visibility_aabb = AABB(Vector3(-W, -H, -D), Vector3(2 * W, H + 0.5, 2 * D))
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = Vector3(W - 0.1, 0.05, D - 0.1)
	proc.direction = Vector3(0.03, -1, 0)
	proc.spread = 2.0
	proc.initial_velocity_min = 5.0
	proc.initial_velocity_max = 6.5
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
	mat.albedo_color = Color(0.55, 0.6, 0.75, 0.6)
	quad.material = mat
	p.draw_pass_1 = quad
	_add(parent, p)
	return p


## Uma das criaturas cruzando o céu da cidade, à noite: uma silhueta 2D sobre o
## painel da janela, passando na frente do mostrador aceso da torre, uma vez, sem
## som — só para quem estiver olhando (Aparicao). Nada confirma o que foi visto.
func _criatura_no_ceu(parent: Node, cond: Condition, flag: StringName) -> void:
	var migo := Aparicao.new()
	migo.name = "Criatura"
	migo.position = Vector3(-1.5, 1.72, -D - 1.12)
	migo.deslocamento = Vector3(3.8, 0.32, 0)
	migo.duracao = 2.4
	migo.atraso = 0.6
	migo.angulo = 20.0
	migo.batida = 0.35
	migo.batidas = 4.0
	migo.condition = cond
	migo.flag = flag
	migo.exposure = 0.03
	_add(parent, migo)
	_quad(migo, "Silhueta", Vector2(0.48, 0.29), Vector3.ZERO, Vector3.ZERO, "migo")


## Lugar da lâmpada de banqueiro na mesa.
const ABAJUR_POS := Vector3(0.62, MESA, -2.45)
const ABAJUR_ROT := -20.0


## A lâmpada de banqueiro (cúpula de vidro verde), na mesa todos os dias.
func _abajur_peca(parent: Node) -> void:
	var abajur := _group(parent, "LampadaBanqueiro", ABAJUR_POS, ABAJUR_ROT)
	_box(abajur, "Base", Vector3(0.16, 0.025, 0.1), Vector3(0, 0.0125, 0), "latao")
	_cyl(abajur, "Haste", 0.01, 0.01, 0.3, Vector3(0, 0.17, 0), "latao", 6)
	# Cilindro deitado e achatado: a cúpula verde.
	var cupula := _cyl(abajur, "Cupula", 0.055, 0.055, 0.3, Vector3(0, 0.33, 0.04), "vidro_verde", 7)
	cupula.rotation_degrees.z = 90
	cupula.scale = Vector3(1, 1, 0.75)
	_cyl(abajur, "Corrente", 0.003, 0.003, 0.08, Vector3(0.1, 0.25, 0.09), "latao", 4)


## A lâmpada acesa, a luz-chave das noites: o tubo aceso sob a cúpula, um spot
## com sombra que faz o círculo na mesa e um omni fraco sem sombra (o que a mesa
## rebate na sala). A luz-chave fica em "Abajur/Luz" (o fonógrafo pulsa a do Dia 3).
func _abajur(parent: Node) -> SpotLight3D:
	var abajur := _group(parent, "Abajur", ABAJUR_POS, ABAJUR_ROT)
	_box(abajur, "Lampada", Vector3(0.22, 0.012, 0.04), Vector3(0, 0.29, 0.04), "vidro_aceso")
	var luz := SpotLight3D.new()
	luz.name = "Luz"
	luz.transform = Transform3D(Basis.looking_at(Vector3(0, -1, 0.45)), Vector3(0, 0.27, 0.06))
	luz.light_color = Color(1.0, 0.78, 0.5)
	luz.light_energy = 4.0
	luz.spot_range = 3.0
	luz.spot_angle = 62.0
	luz.spot_angle_attenuation = 0.6
	luz.shadow_enabled = true
	_add(abajur, luz)
	_omni(abajur, "Rebatida", Vector3(0, 0.45, 0.35), Color(1.0, 0.8, 0.6), 0.35, 4.5)
	return luz


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
	f.cilindro_chegou = _aberto(&"dia_3")
	var tremem: Array[Node3D] = []
	for n in dia3.get_children():
		if n.has_meta(&"treme"):
			tremem.append(n)
	f.tremer = tremem

	# A noite do Dia 3: anotado o dia, ouvir o disco outra vez, da cadeira de
	# leitura — e o sono vem com ele (LugarSono). A área é maior que a do
	# fonógrafo (ganha a mira) e só existe nessa noite.
	var ouvir := _area(g, LugarSono.new(), "OuvirDeNovo", Vector3(0.52, 0.48, 0.48), Vector3(0, 0.18, 0)) as LugarSono
	ouvir.noite = 3
	ouvir.prompt = "Ouvir o disco outra vez"
	ouvir.condition = _cond_valor(&"sono", ValueCondition.Op.IGUAL, 3)
	ouvir.assento = _assento_leitura
	var olhar := Marker3D.new()
	olhar.name = "OlharDisco"
	olhar.position = Vector3(0.0, 0.3, -0.05)
	_add(g, olhar)
	ouvir.olhar = olhar
	ouvir.linha = load("res://narrative/narration/sono_disco.tres")
	ouvir.fonografo = f


func _dia_1(parent: Node) -> void:
	var g := _grupo_do_dia(parent, 1)
	_luz(g, "vista_dia", Color(1.0, 0.86, 0.62), 7.0, Vector3(-0.4, 0, 0.6), Vector3(0.8, 3.4, -D - 1.5), 1.0)
	var carta := _folha(g, "Carta", Vector3(-0.22, MESA + 0.004, -2.12), 12, "carta_akeley_1", "Ler a carta")
	_dentro(carta.get_parent(), &"dia_1")
	_correio(g, "Envelope", &"dia_1", CHAO_A, Vector3(-0.5, -2.32, 10), {
		remetente = "H. W. Akeley\nR.F.D. #2, Townshend, Vt.",
		carimbo_data = "MAY 5\n1928",
	}, "Envelope de Townshend",
		"Uma letra apertada, de aparência arcaica — de quem obviamente não se misturou muito com o mundo. Selo de dois centavos; carimbo de Townshend, 5 de maio.")
	_escrever(g, "resposta_dia_1", &"leu_carta_akeley_1")


## A carta e as fotografias vêm no mesmo envelope gordo; aberto, as fotos saem
## uma por vez, cada uma para o seu lugar na mesa (`fotos`, de _fotografias).
func _dia_2(parent: Node, fotos: Array[Node3D]) -> void:
	var g := _grupo_do_dia(parent, 2)
	# Fim de tarde: sol baixo e alaranjado, entrando quase na horizontal.
	_luz(g, "vista_entardecer", Color(1.0, 0.58, 0.32), 5.5, Vector3(-0.6, 0.5, 1.8), Vector3(1.2, 2.2, -D - 1.5), 0.55)
	var carta := _folha(g, "Carta", Vector3(0.0, MESA + 0.004, -2.1), -6, "carta_akeley_2", "Ler a carta", true, 0.014)
	_dentro(carta.get_parent(), &"dia_2")
	var c := _correio(g, "Envelope", &"dia_2", CHAO_A, Vector3(-0.2, -2.47, 6), {
		remetente = "H. W. Akeley\nR.F.D. #2, Townshend, Vt.",
		carimbo_data = "MAY 22\n1928",
		selos = 2,
		volumoso = true,
	}, "Envelope gordo de Townshend",
		"A mesma letra apertada. Dois selos — a carta pesa. Carimbo de Townshend, 22 de maio.")
	c.retirar = fotos
	_escrever(g, "resposta_dia_2", &"leu_carta_akeley_2")


## O debate nos jornais: o rascunho (Dias 1 e 2) e, no Dia 2, as cartas dos
## opositores que ficam sem resposta depois da 2ª carta de Akeley (cap. II).
func _debate(parent: Node) -> void:
	var todas := CompositeCondition.new()
	var encerrado := _cond_valor(&"debate_encerrado", ValueCondition.Op.MAIOR_OU_IGUAL, 1, true)
	var partes: Array[Condition] = [_cond_valor(&"dia", ValueCondition.Op.MENOR_OU_IGUAL, 2), encerrado]
	todas.conditions = partes
	var g := _grupo_se(parent, "Debate", todas)
	_folha(g, "Rascunho", Vector3(0.52, MESA + 0.002, -2.12), -20, "rascunho_editor", "Ler o rascunho", false)

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


## Devolve as fotos na ordem em que saem do envelope do Dia 2.
func _fotografias(parent: Node) -> Array[Node3D]:
	var g := _grupo_se(parent, "Fotografias", _cond_valor(&"dia", ValueCondition.Op.MAIOR_OU_IGUAL, 2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var fotos: Array[Node3D] = []
	for i in FOTOS.size():
		var info: Array = FOTOS[i]
		var foto := Fotografia.new()
		foto.name = "Foto%d" % (i + 1)
		foto.imagem = load(TEX_DIR + info[0] + ".png")
		foto.position = Vector3(-0.7 + (i % 3) * 0.15, MESA + Fotografia.ESPESSURA * 0.5 + (i % 2) * 0.0005, -2.47 + (i / 3) * 0.14)
		foto.rotation_degrees.y = rng.randf_range(-9, 9)
		_add(g, foto)
		_retirada(foto, &"dia_2", i + 1, 3)
		fotos.append(foto)
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
	return fotos
