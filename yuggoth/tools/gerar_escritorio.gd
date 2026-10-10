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
## As outras vistas em 3D (os sonhos) e o bosque do disco (Fase 3e).
var _vistas = preload("res://tools/vistas.gd").new()
## A folha da porta (feita em _estrutura; a calha a abre).
var _folha_porta: Node3D
## A gaveta da escrivaninha que guarda o frasco (feita em _escrivaninha; Bebida).
var _gaveta_mesa: Node3D
## Onde ele senta nas noites longe do diário (LugarSono): a poltrona.
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
	# A noite 3 sai da sala: o bosque onde o disco foi gravado.
	var fora: Array[int] = [3]
	cena.set("sonhos_fora", fora)
	var ambientes_sonho: Dictionary[int, Environment] = {3: _env_bosque()}
	cena.set("ambientes_sonho", ambientes_sonho)
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
	# Playtest 8: o Dia 5 acaba na renovação da oferta (a noite do AKELY logo
	# depois da farsa); a resposta de 28 de agosto passou para o Dia 6.
	var respostas: Dictionary[int, StringName] = {5: &"renovacao_dia_5"}
	cena.set("respostas_do_dia", respostas)
	# Cada lapso do seu jeito (Lapso.ESTILOS): os dias de chuva de agosto; os dias
	# do começo de setembro; a noite que traz a carta "na manhã seguinte".
	var estilos: Dictionary[StringName, String] = {
		&"cartao_telegrama_akely": "chuva", &"cartao_aprofundava": "chuva",
		&"cartao_31_agosto": "dias", &"cartao_5_setembro": "dias", &"cartao_6_setembro": "noite",
	}
	cena.set("estilos_lapso", estilos)
	cena.set("vigilia_depois_de", &"carta_akeley_terca")

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
	_ligar_vigilia()
	# Cada manhã (e a volta de Boston) começa no pé da escada, junto à porta da
	# rua, de frente para os degraus (playtest 6; na Fase 3f era no alto dela).
	_spawn("Porta", ESCADA_PE, 0)

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
	_mat("porcelana", "grao", {world = 6.0, cor = Color(1.02, 1.0, 0.95)})
	# Os líquidos sobre o grão neutro (playtest 6: no papel, em coordenadas de
	# mundo, o café parecia tábua do assoalho).
	_mat("cafe", "grao", {world = 2.0, cor = Color(0.13, 0.075, 0.04)})
	_mat("uisque", "grao", {world = 2.0, cor = Color(0.72, 0.4, 0.12)})
	_mat("piso_corredor", "assoalho", {world = 0.8, cor = Color(0.62, 0.52, 0.44)})
	_mat("parede_corredor", "reboco", {world = 1.0, cor = Color(0.8, 0.73, 0.6)})
	_mat("vidro_fosco", "grao", {unlit = true, world = 3.0, cor = Color(0.8, 0.66, 0.45)})
	# O corredor (playtest 6): a passadeira e o vidro fosco frio das janelas e da
	# porta da rua.
	_mat("passadeira", "feltro", {world = 2.0, cor = Color(0.5, 0.14, 0.11)})
	_mat("vidro_janela", "grao", {unlit = true, world = 3.0, cor = Color(0.44, 0.48, 0.52)})
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
	# A lareira (Fase 3e): azulejos verdes vidrados, o piso de pedra, a fuligem.
	_mat("azulejo", "aco", {world = 8.0, cor = Color(0.26, 0.4, 0.32)})
	_mat("pedra_lareira", "reboco", {world = 2.0, cor = Color(0.5, 0.48, 0.45)})
	_mat("fuligem", "cinzas", {world = 3.0, cor = Color(0.45, 0.42, 0.4)})
	_mat("papel_pardo", "papel_pardo", {world = 3.0})
	# A tampa e o fundo do estojo do cilindro (playtest 8): papelão envernizado, escuro.
	_mat("papelao_escuro", "papel_pardo", {world = 3.0, cor = Color(0.42, 0.3, 0.24)})
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
	_mat("pedra_negra", "pedra_negra", {world = 2.5})
	# O bosque do disco (noite 3): a cor vem do vértice, a textura só dá o grão.
	_mat("bosque", "grao", {world = 1.0})


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


## O bosque do disco (noite 3): a névoa do pântano, mais longe que a da sala
## (é um lugar aberto), verde-escura.
func _env_bosque() -> Environment:
	var e := _env_sonho()
	e.ambient_light_color = Color(0.05, 0.065, 0.06)
	# Funda o bastante para as ilhas do chão partido boiarem à vista, e um pouco
	# mais clara que a noite: as ilhas, escuras, se recortam nela (playtest 7).
	e.fog_light_color = Color(0.07, 0.1, 0.095)
	e.fog_depth_begin = 4.0
	e.fog_depth_end = 18.0
	return e


## Os sonhos: escuro, com uma névoa verde-acinzentada; funda o bastante para,
## pelas paredes estilhaçadas (Vazio), os destroços boiarem lá fora.
func _env_sonho() -> Environment:
	var e := _env_1930()
	e.ambient_light_color = Color(0.05, 0.06, 0.055)
	e.fog_light_color = Color(0.05, 0.07, 0.06)
	e.fog_depth_begin = 2.5
	e.fog_depth_end = 12.0
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

	_janela(e)

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
	# A folha fecha o vão (a parede tem o vão aberto, Fase 3e) e gira com ela.
	_colisao(folha, "Colisao", [[Vector3(PORTA_L, PORTA_H, 0.05), Vector3(PORTA_L / 2, PORTA_H / 2, -0.03)]])
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

	# O sul com o vão da porta (no fim do dia ele sai por ela, pelo corredor).
	var vo := PORTA_X - PORTA_L / 2 + W + 0.2
	var vl := W + 0.2 - (PORTA_X + PORTA_L / 2)
	_colisao(e, "Colisao", [
		[Vector3(2 * W, 0.2, 2 * D), Vector3(0, -0.1, 0)],
		[Vector3(2 * W, 0.2, 2 * D), Vector3(0, H + 0.1, 0)],
		[Vector3(0.2, H, 2 * D), Vector3(-W - 0.1, H / 2, 0)],
		[Vector3(0.2, H, 2 * D), Vector3(W + 0.1, H / 2, 0)],
		[Vector3(vo, H, PAREDE_SUL), Vector3(-W - 0.2 + vo / 2, H / 2, D + PAREDE_SUL / 2)],
		[Vector3(vl, H, PAREDE_SUL), Vector3(W + 0.2 - vl / 2, H / 2, D + PAREDE_SUL / 2)],
		[Vector3(PORTA_L, H - PORTA_H, PAREDE_SUL), Vector3(PORTA_X, (H + PORTA_H) / 2, D + PAREDE_SUL / 2)],
		[Vector3(2 * W, H, 0.2), Vector3(0, H / 2, -D - 0.1)],
	])


## A janela norte (Fase 3e: "a estrutura da janela"): duas janelas de guilhotina
## lado a lado, como nos prédios da Nova Inglaterra dos anos 1920, separadas por
## um montante. Cada uma com a folha de baixo na frente e a de cima atrás, em
## quatro vidros cada (pinázios), o trilho do meio com a tranca de latão e os
## puxadores; o vão forrado de madeira na espessura da parede; do lado da sala, o
## alizar com a cimalha em cima, e o peitoril com o avental embaixo. Um vidro
## quase invisível em cada folha.
func _janela(e: Node3D) -> void:
	var j := _group(e, "Janela", Vector3(0, 0, -D))
	var baixo := JANELA_Y.x
	var alto := JANELA_Y.y
	var meio := (baixo + alto) / 2
	var vao := alto - baixo
	var t := 0.2  # espessura da parede
	# O forro do vão: os lados e o alto, na espessura da parede.
	for s in [-1, 1]:
		_box(j, "Forro%s" % ("O" if s < 0 else "L"), Vector3(0.03, vao, t), Vector3(s * (JANELA_X - 0.015), meio, -t / 2), "madeira_clara")
	_box(j, "ForroAlto", Vector3(2 * JANELA_X, 0.03, t), Vector3(0, alto - 0.015, -t / 2), "madeira_clara")
	# O peitoril (de dentro, avançando na sala) e o avental embaixo dele.
	_box(j, "Peitoril", Vector3(2 * JANELA_X + 0.22, 0.04, 0.24), Vector3(0, baixo, 0.0), "madeira_clara")
	_box(j, "PeitorilFora", Vector3(2 * JANELA_X, 0.03, t), Vector3(0, baixo - 0.01, -t / 2 - 0.02), "madeira_clara")
	_box(j, "Avental", Vector3(2 * JANELA_X + 0.1, 0.1, 0.02), Vector3(0, baixo - 0.07, 0.01), "madeira_clara")
	# O alizar: os montantes, a verga e a cimalha.
	for s in [-1, 1]:
		_box(j, "Alizar%s" % ("O" if s < 0 else "L"), Vector3(0.1, vao + 0.02, 0.025), Vector3(s * (JANELA_X + 0.05), meio + 0.01, 0.0125), "madeira_clara")
	_box(j, "AlizarVerga", Vector3(2 * JANELA_X + 0.22, 0.14, 0.03), Vector3(0, alto + 0.07, 0.015), "madeira_clara")
	_box(j, "AlizarCimalha", Vector3(2 * JANELA_X + 0.3, 0.035, 0.07), Vector3(0, alto + 0.155, 0.03), "madeira_clara")
	# O montante entre as duas janelas.
	_box(j, "Montante", Vector3(0.1, vao, t - 0.02), Vector3(0, meio, -t / 2), "madeira_clara")
	# As duas janelas de guilhotina.
	var vidro := StandardMaterial3D.new()
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.albedo_color = Color(0.7, 0.78, 0.82, 0.07)
	vidro.roughness = 0.05
	vidro.metallic_specular = 0.9
	var larg := JANELA_X - 0.05 - 0.015  # cada janela, do montante ao forro
	for s in [-1, 1]:
		var cx: float = s * (0.05 + larg / 2)
		# A de baixo na frente (mais perto da sala), a de cima atrás.
		for f: Array in [["Baixo", baixo, meio + 0.02, -0.07], ["Cima", meio - 0.02, alto, -0.12]]:
			var y0: float = f[1]
			var y1: float = f[2]
			var z: float = f[3]
			var folha := _group(j, "Folha%s%s" % [f[0], "O" if s < 0 else "L"], Vector3(cx, (y0 + y1) / 2, z))
			var h := y1 - y0
			var tr := 0.045
			# Montantes e travessas da folha (a de baixo mais larga embaixo).
			for k in [-1, 1]:
				_box(folha, "Montante%d" % (k + 1), Vector3(tr, h, 0.035), Vector3(k * (larg / 2 - tr / 2), 0, 0), "madeira_clara")
			var pe := 0.07 if f[0] == "Baixo" else tr
			_box(folha, "TravessaPe", Vector3(larg, pe, 0.035), Vector3(0, -h / 2 + pe / 2, 0), "madeira_clara")
			_box(folha, "TravessaTopo", Vector3(larg, tr, 0.035), Vector3(0, h / 2 - tr / 2, 0), "madeira_clara")
			# Os pinázios: uma cruz, quatro vidros.
			_box(folha, "PinazioV", Vector3(0.018, h - tr, 0.025), Vector3(0, 0, 0), "madeira_clara")
			_box(folha, "PinazioH", Vector3(larg - tr, 0.018, 0.025), Vector3(0, (pe - tr) / 2, 0), "madeira_clara")
			var v := _quad(folha, "Vidro", Vector2(larg - tr, h - tr), Vector3(0, 0, -0.004), Vector3.ZERO, "papel")
			v.material_override = vidro
			v.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if f[0] == "Baixo":
				# A tranca no trilho do meio e os dois puxadores embaixo.
				_box(folha, "Tranca", Vector3(0.07, 0.018, 0.03), Vector3(0, h / 2 + 0.005, -0.02), "latao")
				for k in [-1, 1]:
					_box(folha, "Puxador%d" % (k + 1), Vector3(0.03, 0.025, 0.02), Vector3(k * larg * 0.3, -h / 2 + 0.05, 0.025), "latao")


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
	# Ao lado da lareira, virada para ela (as noites do disco e do fogo, LugarSono).
	var poltrona := _group(mob, "Poltrona", POLTRONA_POS, POLTRONA_ROT)
	_poltrona(poltrona, "estofado")
	_assento_poltrona = Marker3D.new()
	_assento_poltrona.name = "Assento"
	_add(poltrona, _assento_poltrona)
	_mesinha(mob)
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
		# Livros de série, às vezes: a mesma cor e altura, lado a lado.
		var serie := rng.randi_range(2, 5) if rng.randf() < 0.18 else 1
		for s in serie:
			if z + esp > z1:
				break
			var frente := fundo + prof
			pecas.append([Vector3(prof, alt, esp), Vector3(fundo + prof / 2, y + alt / 2, z + esp / 2), Vector3.ZERO, cor])
			# Na lombada, os frisos dourados perto do pé e da cabeça (Fase 3e).
			if rng.randf() < 0.7:
				var ouro := Color(0.78, 0.62, 0.3) * rng.randf_range(0.8, 1.1)
				ouro.a = 1.0
				for faixa in [0.035, alt - 0.045]:
					pecas.append([Vector3(0.004, 0.008, esp - 0.004), Vector3(frente + 0.001, y + faixa, z + esp / 2), Vector3.ZERO, ouro])
			# E a etiqueta clara do título, nos mais altos.
			if alt > 0.24 and rng.randf() < 0.4:
				pecas.append([Vector3(0.004, 0.03, esp - 0.008), Vector3(frente + 0.001, y + alt * 0.7, z + esp / 2), Vector3.ZERO, Color(0.82, 0.76, 0.6)])
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


## A estante da parede oeste, metade norte, cheia (Fase 3e: com acabamento): os
## lados, o fundo, o rodapé recuado, os montantes da frente, a cimalha em dois
## degraus no alto e a borda de cada prateleira; livros de lombada com frisos.
func _estante(parent: Node) -> void:
	var g := _group(parent, "Estante", Vector3(-W + 0.18, 0, -2.0))
	var alt := 2.3
	_box(g, "LadoN", Vector3(0.36, alt, 0.04), Vector3(0, alt / 2, -0.78), "madeira_escura")
	_box(g, "LadoS", Vector3(0.36, alt, 0.04), Vector3(0, alt / 2, 0.78), "madeira_escura")
	_box(g, "Fundo", Vector3(0.02, alt, 1.56), Vector3(-0.17, alt / 2, 0), "madeira_escura")
	var prateleiras := [0.1, 0.52, 0.95, 1.38, 1.82, alt - 0.02]
	for i in prateleiras.size():
		_box(g, "Prateleira%d" % i, Vector3(0.36, 0.04, 1.52), Vector3(0, prateleiras[i], 0), "madeira_escura")
		# A borda da frente, um pouco mais alta que a tábua.
		_box(g, "Borda%d" % i, Vector3(0.02, 0.05, 1.52), Vector3(0.175, prateleiras[i] - 0.005, 0), "madeira_escura")
	# Os montantes da frente, cobrindo os lados.
	for s in [-1, 1]:
		_box(g, "Montante%d" % (s + 1), Vector3(0.025, alt, 0.07), Vector3(0.19, alt / 2, s * 0.775), "madeira_escura")
	# O rodapé, recuado, e a cimalha no alto, em dois degraus.
	_box(g, "Rodape", Vector3(0.03, 0.08, 1.6), Vector3(0.165, 0.04, 0), "madeira_escura")
	_box(g, "CimalhaBaixo", Vector3(0.4, 0.05, 1.64), Vector3(0.02, alt + 0.025, 0), "madeira_escura")
	_box(g, "CimalhaAlto", Vector3(0.44, 0.04, 1.7), Vector3(0.03, alt + 0.07, 0), "madeira_escura")
	_box(g, "Friso", Vector3(0.02, 0.06, 1.56), Vector3(0.195, alt - 0.06, 0), "madeira_escura")
	# Em cima da estante, uma caixa de arquivo e um rolo de mapas.
	_box(g, "Caixa", Vector3(0.28, 0.16, 0.36), Vector3(0.0, alt + 0.17, -0.4), "papel_pardo")
	var rolo := _cyl(g, "Rolo", 0.04, 0.04, 0.6, Vector3(0.02, alt + 0.13, 0.3), "papel", 8)
	rolo.rotation_degrees.x = 90
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var livros := []
	for i in 5:
		_fileira(livros, rng, prateleiras[i] + 0.02, -0.16, -0.76, 0.76, prateleiras[i + 1] - prateleiras[i] - 0.06)
	_lote(g, "Livros", livros, "capa_livro")
	_colisao(g, "Colisao", [[Vector3(0.36, alt, 1.6), Vector3(0, alt / 2, 0)]])


## A lareira da parede leste (Fase 3e: "a lareira principalmente"): o peito de
## tijolo até o teto; embaixo, o consolo de madeira escura dos anos 1920 —
## pilastras com capitel, o friso e a prateleira com cimalha e mísulas —, um
## quadro de azulejos verdes em volta da boca, a verga de ferro; dentro, a
## fornalha com as faces de tijolo inclinadas, o fundo de fuligem e a grelha de
## ferro de barras; na frente, o piso de pedra com o guarda-fogo de latão; ao
## lado, o jogo de ferramentas e o cesto de lenha. Origem: o meio da parede; -X
## é a sala.
func _lareira(parent: Node) -> void:
	var g := _group(parent, "Lareira", Vector3(W, 0, -0.6))
	var prof := 0.4
	var boca := Vector2(0.36, 0.78)  # meia largura, altura
	var frente := -prof
	# O peito: dos lados da boca e acima dela, até o teto.
	for s in [-1, 1]:
		var largo := 0.8 - boca.x
		_box(g, "Peito%d" % (s + 1), Vector3(prof, boca.y, largo), Vector3(-prof / 2, boca.y / 2, s * (boca.x + largo / 2)), "tijolo")
	_box(g, "Chamine", Vector3(prof, H - boca.y, 1.6), Vector3(-prof / 2, (H + boca.y) / 2, 0), "tijolo")
	# A fornalha: o fundo de fuligem, as faces inclinadas, o teto escuro.
	_box(g, "FundoFogo", Vector3(0.03, boca.y, boca.x * 1.3), Vector3(-0.05, boca.y / 2, 0), "fuligem")
	for s in [-1, 1]:
		var face := _box(g, "Face%d" % (s + 1), Vector3(0.3, boca.y, 0.03), Vector3(-0.22, boca.y / 2, s * (boca.x * 0.84)), "tijolo")
		face.rotation_degrees.y = s * 14.0
	_box(g, "TetoFogo", Vector3(0.36, 0.03, boca.x * 2.0), Vector3(-0.2, boca.y - 0.015, 0), "fuligem")
	_box(g, "ChaoFogo", Vector3(0.36, 0.02, boca.x * 2.0), Vector3(-0.2, 0.01, 0), "cinzas")
	_box(g, "Cinzas", Vector3(0.26, 0.03, 0.46), Vector3(-0.2, 0.035, 0), "cinzas")
	# A verga de ferro sobre a boca.
	_box(g, "Verga", Vector3(0.02, 0.05, boca.x * 2.0 + 0.08), Vector3(frente - 0.005, boca.y + 0.02, 0), "ferro")
	_grelha(g, Vector3(-0.22, 0.0, 0))

	# O quadro de azulejos em volta da boca, em fiadas de 15 cm.
	var az := 0.15
	var faixa := 0.16
	for s in [-1, 1]:
		for k in int((boca.y + faixa) / az) + 1:
			var y := k * az + az / 2
			if y > boca.y + faixa:
				break
			_box(g, "Azulejo%d_%d" % [s + 1, k], Vector3(0.012, az - 0.006, faixa - 0.006), Vector3(frente - 0.006, y, s * (boca.x + faixa / 2)), "azulejo")
	for k in int((boca.x * 2.0 + faixa * 2.0) / az):
		var z := -boca.x - faixa + k * az + az / 2
		_box(g, "AzulejoAlto%d" % k, Vector3(0.012, faixa - 0.006, az - 0.006), Vector3(frente - 0.006, boca.y + faixa / 2, z), "azulejo")

	# O consolo de madeira: pilastras com base e capitel, o friso, a prateleira
	# com a cimalha por baixo e as mísulas nas pontas.
	var mad := frente - 0.03
	var pil := 0.11
	var zp := boca.x + faixa + pil / 2
	var alto := boca.y + faixa
	for s in [-1, 1]:
		_box(g, "Pilastra%d" % (s + 1), Vector3(0.06, alto, pil), Vector3(mad, alto / 2, s * zp), "madeira_escura")
		_box(g, "BasePilastra%d" % (s + 1), Vector3(0.08, 0.1, pil + 0.03), Vector3(mad - 0.01, 0.05, s * zp), "madeira_escura")
		_box(g, "Capitel%d" % (s + 1), Vector3(0.08, 0.05, pil + 0.03), Vector3(mad - 0.01, alto - 0.025, s * zp), "madeira_escura")
		var misula := _box(g, "Misula%d" % (s + 1), Vector3(0.1, 0.1, 0.05), Vector3(mad - 0.06, alto + 0.17, s * (zp + 0.02)), "madeira_escura")
		misula.rotation_degrees.z = 20.0
	var friso := zp + pil / 2
	_box(g, "Friso", Vector3(0.05, 0.16, friso * 2.0), Vector3(mad, alto + 0.08, 0), "madeira_escura")
	_box(g, "FrisoFilete", Vector3(0.065, 0.02, friso * 2.0), Vector3(mad - 0.005, alto + 0.01, 0), "madeira_escura")
	_box(g, "Cimalha", Vector3(0.12, 0.04, friso * 2.0 + 0.08), Vector3(mad - 0.04, alto + 0.18, 0), "madeira_escura")
	var prateleira := alto + 0.225
	_box(g, "Prateleira", Vector3(0.26, 0.05, friso * 2.0 + 0.18), Vector3(frente - 0.1, prateleira, 0), "madeira_escura")

	# Na prateleira: os castiçais, o relógio de mesa no meio e um pote de fumo.
	for s in [-1, 1]:
		_cyl(g, "Castical%d" % s, 0.025, 0.04, 0.2, Vector3(frente - 0.1, prateleira + 0.125, s * 0.62), "latao", 6)
		_cyl(g, "Vela%d" % s, 0.012, 0.012, 0.09, Vector3(frente - 0.1, prateleira + 0.27, s * 0.62), "porcelana", 6)
	var relogio := _group(g, "RelogioMesa", Vector3(frente - 0.1, prateleira + 0.025, 0.0), -90)
	_box(relogio, "Base", Vector3(0.26, 0.03, 0.1), Vector3(0, 0.015, 0), "madeira_escura")
	_box(relogio, "Caixa", Vector3(0.22, 0.16, 0.08), Vector3(0, 0.11, 0), "madeira_escura")
	var arco := _cyl(relogio, "Arco", 0.08, 0.08, 0.08, Vector3(0, 0.19, 0), "madeira_escura", 10)
	arco.rotation_degrees.x = 90
	_cyl(relogio, "Mostrador", 0.055, 0.055, 0.005, Vector3(0, 0.16, -0.042), "porcelana", 12).rotation_degrees.x = 90
	_cyl(g, "PoteFumo", 0.04, 0.045, 0.1, Vector3(frente - 0.1, prateleira + 0.075, -0.32), "porcelana", 8)

	# O piso de pedra na frente, um pouco alto, e o guarda-fogo de latão em volta.
	var funda := 0.5
	var larga := 0.8
	_box(g, "Lareiro", Vector3(funda, 0.04, larga * 2.0), Vector3(frente - funda / 2, 0.02, 0), "pedra_lareira")
	_box(g, "LareiroBorda", Vector3(0.03, 0.045, larga * 2.0), Vector3(frente - funda + 0.015, 0.0225, 0), "pedra_lareira")
	var gf := frente - funda + 0.08
	var gl := boca.x + faixa + 0.12
	_box(g, "GuardaFogo", Vector3(0.02, 0.1, gl * 2.0), Vector3(gf, 0.09, 0), "latao")
	_box(g, "GuardaFogoBarra", Vector3(0.035, 0.02, gl * 2.0 + 0.02), Vector3(gf, 0.15, 0), "latao")
	for s in [-1, 1]:
		_box(g, "GuardaFogoLado%d" % (s + 1), Vector3(frente - gf, 0.1, 0.02), Vector3((gf + frente) / 2, 0.09, s * gl), "latao")
		_cyl(g, "GuardaFogoPomo%d" % (s + 1), 0.018, 0.018, 0.03, Vector3(gf, 0.175, s * gl), "latao", 6)

	# O jogo de ferramentas, ao sul, e o cesto de lenha, ao norte.
	var jogo := _group(g, "Ferramentas", Vector3(frente - 0.18, 0.04, larga - 0.1))
	_cyl(jogo, "Base", 0.07, 0.08, 0.02, Vector3(0, 0.01, 0), "ferro", 8)
	_cyl(jogo, "Haste", 0.008, 0.008, 0.62, Vector3(0, 0.32, 0), "ferro", 6)
	_box(jogo, "Cabide", Vector3(0.14, 0.012, 0.012), Vector3(0, 0.62, 0), "latao")
	for k in 3:
		var x := -0.05 + k * 0.05
		_cyl(jogo, "Cabo%d" % k, 0.007, 0.007, 0.5, Vector3(x, 0.34, 0.012), "ferro", 5)
		_cyl(jogo, "Punho%d" % k, 0.012, 0.012, 0.05, Vector3(x, 0.6, 0.012), "latao", 6)
	_box(jogo, "Pa", Vector3(0.06, 0.08, 0.008), Vector3(-0.05, 0.08, 0.012), "ferro")
	_box(jogo, "Escova", Vector3(0.045, 0.07, 0.02), Vector3(0.05, 0.08, 0.012), "la_escura")
	var cesto := _group(g, "CestoLenha", Vector3(frente - 0.2, 0.04, -larga + 0.05))
	_cyl(cesto, "Cesto", 0.17, 0.15, 0.22, Vector3(0, 0.11, 0), "papel_pardo", 9)
	for k in 4:
		var tora := _cyl(cesto, "Tora%d" % k, 0.035, 0.04, 0.38, Vector3(-0.06 + (k % 2) * 0.1, 0.24 + (k / 2) * 0.06, 0), "madeira_escura", 7)
		tora.rotation_degrees = Vector3(90, 0, -8.0 + k * 6.0)

	# A boca fica livre (a mira alcança a lenha, "Acender a lareira"): o peito
	# dos lados e acima, o consolo, que avança mais; o piso de pedra é baixo.
	var lado := 0.8 - boca.x
	_colisao(g, "Colisao", [
		[Vector3(prof + 0.06, boca.y, lado), Vector3(-(prof + 0.06) / 2, boca.y / 2, -(boca.x + lado / 2))],
		[Vector3(prof + 0.06, boca.y, lado), Vector3(-(prof + 0.06) / 2, boca.y / 2, boca.x + lado / 2)],
		[Vector3(prof, H - boca.y, 1.6), Vector3(-prof / 2, (H + boca.y) / 2, 0)],
		[Vector3(prof + 0.24, 0.3, friso * 2.0 + 0.18), Vector3(-(prof + 0.24) / 2, prateleira - 0.12, 0)],
	])


## A grelha de ferro, um cesto de barras sobre quatro pés, onde a lenha das noites
## frias se apoia (ver _lareira_noite).
func _grelha(g: Node3D, c: Vector3) -> void:
	var gr := _group(g, "Grelha", c)
	var l := 0.25
	var f := 0.13
	for s in [-1, 1]:
		for t in [-1, 1]:
			_box(gr, "Pe%d%d" % [s + 1, t + 1], Vector3(0.02, 0.09, 0.02), Vector3(s * f, 0.045, t * l), "ferro")
	for k in 6:
		_box(gr, "Fundo%d" % k, Vector3(f * 2.0, 0.012, 0.012), Vector3(0, 0.09, -l + k * l * 2.0 / 5.0), "ferro")
	for t in [-1, 1]:
		_box(gr, "Trilho%d" % (t + 1), Vector3(f * 2.0 + 0.02, 0.015, 0.015), Vector3(0, 0.09, t * l), "ferro")
	# A frente: barras de pé; atrás, mais baixas.
	for k in 7:
		var z := -l + k * l * 2.0 / 6.0
		_box(gr, "Barra%d" % k, Vector3(0.012, 0.14, 0.012), Vector3(-f - 0.005, 0.155, z), "ferro")
		_box(gr, "Atras%d" % k, Vector3(0.012, 0.1, 0.012), Vector3(f - 0.01, 0.135, z), "ferro")
	_box(gr, "Aro", Vector3(0.016, 0.016, l * 2.0 + 0.02), Vector3(-f - 0.005, 0.225, 0), "ferro")
	for s in [-1, 1]:
		# As pinhas de latão na frente dos pés.
		_cyl(gr, "Pinha%d" % (s + 1), 0.018, 0.022, 0.06, Vector3(-f - 0.03, 0.03, s * (l + 0.02)), "latao", 6)


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
	corredor.light_cull_mask &= ~CAMADA_SEM_FRESTA

	_corredor(g)
	_lapso(g)

	# Com correspondência na mão, mirar o tampo a põe na mesa (some sem nada na mão).
	var por := _area(g, MesaCorreio.new(), "PorNaMesa", Vector3(1.6, 0.1, 0.8), Vector3(0, MESA + 0.05, -2.2)) as MesaCorreio
	por.unique_name_in_owner = true
	por.prompt = "Pôr na mesa"

	# A porta: com a carta, abre para a calha; no fim do dia, "ir para casa".
	var sair := _area(g, Interactable.new(), "SairPorta", Vector3(0.9, 2.0, 0.2), Vector3(-1.0, 1.05, D - 0.12)) as Interactable
	sair.unique_name_in_owner = true
	sair.prompt = "Ir para casa"
	# Do lado do corredor: de manhã, ele chega por ali (Fase 3f).
	var entrar := _area(g, Interactable.new(), "EntrarPorta", Vector3(0.9, 2.0, 0.15), Vector3(-1.0, 1.05, D + 0.1)) as Interactable
	entrar.unique_name_in_owner = true
	entrar.prompt = "Abrir a porta"

	# Canto sudoeste: o armário. A máquina emprestada chega no Dia 3 (_fonografo).
	# A frente (+Z local) para leste, para a sala (sessão de tester 2: era um bloco
	# liso, com a junção das portas virada para a parede).
	var a := _group(g, "Armario", Vector3(-2.15, 0, 2.35), 90)
	_box(a, "Rodape", Vector3(0.76, 0.07, 0.44), Vector3(0, 0.035, -0.02), "madeira_escura")
	_box(a, "Corpo", Vector3(0.8, 0.8, 0.46), Vector3(0, 0.47, -0.02), "madeira_escura")
	_box(a, "Tampo", Vector3(0.86, 0.035, 0.52), Vector3(0, 0.8875, 0), "madeira_escura")
	for s in [-1, 1]:
		var lado := "O" if s < 0 else "L"
		_box(a, "Porta" + lado, Vector3(0.37, 0.68, 0.02), Vector3(s * 0.19, 0.47, 0.22), "madeira_escura")
		_box(a, "Almofada" + lado, Vector3(0.27, 0.52, 0.012), Vector3(s * 0.19, 0.47, 0.236), "madeira_escura")
		_box(a, "Puxador" + lado, Vector3(0.02, 0.06, 0.02), Vector3(s * 0.035, 0.6, 0.24), "latao")
	# A luz do corredor, rente ao chão junto à porta, acendia a frente inteira do
	# armário à noite: ele fica fora dela (camada 2 de render, fora do cull da luz).
	for mi: MeshInstance3D in a.find_children("*", "MeshInstance3D", false, false):
		mi.layers = CAMADA_SEM_FRESTA
	_colisao(a, "Colisao", [[Vector3(0.8, 0.9, 0.5), Vector3(0, 0.45, 0)]])


## O que pende nas paredes do escritório (Fase 3d): uma paisagem a óleo sobre a
## lareira, em moldura dourada, e os dois diplomas de Wilmarth na parede leste,
## ao sul da lareira.
func _quadros(g: Node3D) -> void:
	var face := W - 0.4
	var q := _group(g, "QuadroLareira", Vector3(face, 1.95, -0.6))
	_box(q, "Moldura", Vector3(0.04, 0.6, 0.82), Vector3(-0.02, 0, 0), "latao")
	_quad(q, "Tela", Vector2(0.7, 0.48), Vector3(-0.042, 0, 0), Vector3(0, -90, 0), "quadro")
	# Playtest 8: "seria legal se os certificados na parede fossem legíveis". O
	# texto de verdade, em inglês como tudo o que é impresso; examináveis, com a
	# tradução embaixo. Os graus são nossos (o livro só diz "instrutor de
	# literatura"): bacharel e mestre pela própria Miskatonic.
	for k in 2:
		var d := _group(g, "Diploma%d" % k, Vector3(W, 1.55 + k * 0.05, 1.05 + k * 0.5), -90)
		_box(d, "Moldura", Vector3(0.3, 0.36, 0.025), Vector3(0, 0, 0.0125), "madeira_escura")
		_quad(d, "Papel", Vector2(0.24, 0.3), Vector3(0, 0, 0.026), Vector3.ZERO, "diploma")
		var grau: String = ["Bachelor of Arts", "Master of Arts"][k]
		var data: String = ["June 18, 1911", "June 17, 1914"][k]
		# Poucas palavras, grandes: a 540 linhas, o miúdo vira risco (de perto,
		# examinando, lê-se tudo).
		_impresso(d, 0.0265, 0.2, [
			["Miskatonic University", 0.105, 0.00022, FRAKTUR, Color(0.12, 0.08, 0.06)],
			["ARKHAM · MASSACHUSETTS", 0.082, 0.0001, VERSALETE, Color(0.3, 0.22, 0.16)],
			["The Trustees have conferred upon", 0.06, 0.00011, ITALICO, Color(0.2, 0.15, 0.12)],
			["Albert N. Wilmarth", 0.03, 0.0002, CALIGRAFIA, Color(0.1, 0.07, 0.1)],
			["the degree of", 0.002, 0.00011, ITALICO, Color(0.2, 0.15, 0.12)],
			[grau, -0.024, 0.0002, FRAKTUR, Color(0.12, 0.08, 0.06)],
			["with all its rights and honors.
Given at Arkham, " + data + ".", -0.062, 0.0001, ITALICO, Color(0.2, 0.15, 0.12)],
			["President            Secretary", -0.112, 0.00009, VERSALETE, Color(0.3, 0.22, 0.16)],
		])
		var ex := _area(d, Examinable.new(), "Examinar", Vector3(0.3, 0.36, 0.08), Vector3(0, 0, 0.04)) as Examinable
		ex.prompt = "Examinar"
		ex.title = ["O diploma de bacharel", "O diploma de mestre"][k]
		ex.description = ["Universidade Miskatonic, Arkham, Massachusetts. O Conselho da Universidade, por indicação do Corpo Docente, confere a Albert N. Wilmarth o grau de Bacharel em Letras — 18 de junho de 1911.",
			"Universidade Miskatonic. O grau de Mestre em Letras, conferido a Albert N. Wilmarth a 17 de junho de 1914. Quatorze anos depois, ainda instrutor de literatura."][k]
		ex.initial_rotation = Vector3.ZERO


## As letras do que está impresso nas paredes (diplomas, avisos).
const FRAKTUR := "res://art/fonts/UnifrakturMaguntia-Book.ttf"
const VERSALETE := "res://art/fonts/IMFellEnglish-SC.ttf"
const ITALICO := "res://art/fonts/IMFellEnglish-Italic.ttf"
const ROMANO := "res://art/fonts/IMFellEnglish-Regular.ttf"
const TIPO := "res://art/fonts/OldStandard-Bold.ttf"
const CALIGRAFIA := "res://art/fonts/PetitFormalScript-Regular.ttf"
const MAQUINA := "res://art/fonts/OldStandard-Regular.ttf"

## Os avisos do quadro do corredor: [linhas para _impresso, título, tradução].
const AVISOS := [
	[[["VERMONT", 0.085, 0.00016, TIPO, Color(0.1, 0.08, 0.08)],
		["FLOOD RELIEF", 0.062, 0.00011, TIPO, Color(0.1, 0.08, 0.08)],
		["Contributions for the sufferers\nof the November floods may be\nleft at the Bursar's Office,\nAdministration Building.\n\nClothing, blankets and\nfuel are most needed.", 0.0, 0.00012, ROMANO, Color(0.15, 0.12, 0.1)],
		["— The Faculty Committee", -0.088, 0.00008, ITALICO, Color(0.2, 0.15, 0.12)]],
		"Socorro às vítimas da enchente",
		"Socorro às vítimas da enchente de Vermont. Contribuições para os flagelados das enchentes de novembro podem ser deixadas na Tesouraria, no Prédio da Administração. Precisa-se sobretudo de roupas, cobertores e combustível. — A Comissão do Corpo Docente"],
	[[["DEPARTMENT OF ENGLISH", 0.05, 0.0001, VERSALETE, Color(0.15, 0.12, 0.1)],
		["Office Hours", 0.03, 0.00009, ITALICO, Color(0.15, 0.12, 0.1)],
		["Mr. A. N. Wilmarth, Room 310\nTuesdays and Thursdays, 2 to 4\nor by appointment.", -0.008, 0.00008, MAQUINA, Color(0.12, 0.1, 0.1)],
		["(Wed. 3 — the Folk-Lore Society, Library 4)", -0.05, 0.00006, CALIGRAFIA, Color(0.1, 0.08, 0.14)]],
		"O horário de atendimento",
		"Departamento de Inglês. Horário de atendimento: Sr. A. N. Wilmarth, sala 310, terças e quintas, das 2 às 4, ou com hora marcada. Embaixo, na minha letra: \u201cQuarta, 3h — a Sociedade de Folclore, Biblioteca 4.\u201d"],
	[[["LIBRARY", 0.074, 0.00012, TIPO, Color(0.1, 0.08, 0.08)],
		["NOTICE", 0.056, 0.00008, VERSALETE, Color(0.15, 0.12, 0.1)],
		["Volumes from the\nlocked cases may be\nconsulted only in the\npresence of the Librarian,\nand under no circumstances\nremoved from the\nbuilding.", -0.004, 0.00007, ROMANO, Color(0.15, 0.12, 0.1)],
		["Henry Armitage\nLibrarian", -0.07, 0.00006, ITALICO, Color(0.2, 0.15, 0.12)]],
		"Aviso da biblioteca",
		"Biblioteca. Os volumes dos armários trancados só podem ser consultados na presença do Bibliotecário, e em nenhuma hipótese retirados do prédio. — Henry Armitage, Bibliotecário"],
	[[["PUBLIC LECTURE", 0.04, 0.0001, TIPO, Color(0.1, 0.08, 0.08)],
		["Hill Legends of Northern New England", 0.02, 0.00008, ITALICO, Color(0.15, 0.12, 0.1)],
		["by Prof. Josiah Hartwell\nThursday evening at eight · Lecture Hall B", -0.012, 0.00006, ROMANO, Color(0.15, 0.12, 0.1)],
		["All are welcome", -0.042, 0.00006, VERSALETE, Color(0.2, 0.15, 0.12)]],
		"Uma palestra",
		"Palestra pública: \u201cLendas das colinas do norte da Nova Inglaterra\u201d, pelo Prof. Josiah Hartwell. Quinta-feira, às oito da noite, Anfiteatro B. Entrada franca."],
	[[["FOUND", 0.07, 0.00014, TIPO, Color(0.1, 0.08, 0.08)],
		["in the Reading Room:\na pair of tortoise-shell\nspectacles, and an\numbrella with an ivory\nhandle.\n\nApply to the Janitor,\nbasement of Hall C.", -0.01, 0.00008, ROMANO, Color(0.15, 0.12, 0.1)]],
		"Achados",
		"Achados na Sala de Leitura: um par de óculos de tartaruga e um guarda-chuva de cabo de marfim. Procurar o zelador, no porão do Prédio C."],
	[[["ROOM", 0.04, 0.0001, TIPO, Color(0.1, 0.08, 0.08)],
		["to let, quiet\nhouse, gentleman\npreferred.\nInquire Mrs. Dobbs,\n47 Garrison St.", -0.012, 0.00006, CALIGRAFIA, Color(0.1, 0.08, 0.14)]],
		"Um quarto",
		"Aluga-se quarto, casa sossegada, prefere-se cavalheiro. Tratar com a Sra. Dobbs, Garrison St., 47."],
]


## Linhas impressas num papel virado para +Z local, centradas: cada linha é
## [texto, y, pixel_size, fonte, cor]; `z` à frente do papel. Uma linha mais
## larga que `largura` encolhe até caber (medida pela própria fonte).
func _impresso(pai: Node3D, z: float, largura: float, linhas: Array) -> void:
	for i in linhas.size():
		var ln: Array = linhas[i]
		var l := Label3D.new()
		l.name = "Linha%d" % i
		l.text = ln[0]
		var fonte: Font = load(ln[3])
		l.font = fonte
		l.font_size = 64
		var px := fonte.get_multiline_string_size(ln[0], HORIZONTAL_ALIGNMENT_CENTER, -1, 64).x
		l.pixel_size = minf(ln[2], largura / maxf(px, 1.0))
		l.modulate = ln[4]
		l.outline_size = 0
		l.line_spacing = -6.0
		l.position = Vector3(0, ln[1], z)
		l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		l.double_sided = false
		l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_add(pai, l)


## O corredor da Miskatonic atrás da porta e, na parede da frente, a calha de
## correio de latão com frente de vidro (Fase 3d; CalhaCorreio): é por ela que a
## carta sai. No fim do corredor, a leste, a escada desce para a rua: é por ela
## que ele chega de manhã e vai para casa (Fase 3e; playtest 6). O corredor só aparece com a porta aberta; as
## colisões ficam sempre (atrás da porta fechada, ninguém chega a elas).
func _corredor(g: Node3D) -> void:
	var c := _group(g, "Corredor")
	c.unique_name_in_owner = true
	c.visible = false
	var fundo := D + CORREDOR
	var meio := D + CORREDOR / 2
	var perto := D + PAREDE_SUL
	var x0 := -4.0
	var x1 := ESCADA_X
	var largura := x1 - x0
	var cx := (x0 + x1) / 2
	_quad(c, "Piso", Vector2(largura, CORREDOR), Vector3(cx, 0, meio), Vector3(-90, 0, 0), "piso_corredor")
	_quad(c, "Teto", Vector2(largura, CORREDOR), Vector3(cx, H, meio), Vector3(90, 0, 0), "teto")
	_quad(c, "ParedeFrente", Vector2(largura, H), Vector3(cx, H / 2, fundo), Vector3(0, 180, 0), "parede_corredor")
	_quad(c, "PontaO", Vector2(CORREDOR, H), Vector3(x0, H / 2, meio), Vector3(0, 90, 0), "parede_corredor")
	# O lambri, a moldura e o rodapé param nas portas e na calha (playtest 7:
	# passavam por cima da porta 312, rentes à folha).
	var trechos_frente := _trechos(x0, x1, [Vector2(-2.9 - 0.54, -2.9 + 0.54), Vector2(CALHA_X - 0.1, CALHA_X + 0.1)])
	for i in trechos_frente.size():
		var a: float = trechos_frente[i].x
		var b: float = trechos_frente[i].y
		_box(c, "Lambri%d" % i, Vector3(b - a, 1.0, 0.02), Vector3((a + b) / 2, 0.5, fundo - 0.01), "lambri")
		_box(c, "LambriMoldura%d" % i, Vector3(b - a, 0.04, 0.04), Vector3((a + b) / 2, 1.02, fundo - 0.02), "madeira_escura")
		_box(c, "Rodape%d" % i, Vector3(b - a, 0.12, 0.045), Vector3((a + b) / 2, 0.06, fundo - 0.0225), "madeira_escura")
		_almofadas(c, "AlmofadasFrente%d" % i, a, b, fundo - 0.025, -1.0)
	_box(c, "LambriPonta", Vector3(0.02, 1.0, CORREDOR), Vector3(x0 + 0.01, 0.5, meio), "lambri")
	_box(c, "MolduraPonta", Vector3(0.04, 0.04, CORREDOR), Vector3(x0 + 0.02, 1.02, meio), "madeira_escura")

	# O lado do corredor da parede da sala, em volta do vão (de dentro do corredor,
	# a face da sala some — via-se a sala através dela), com lambri e rodapé, e os
	# montantes do vão, na espessura da parede.
	var vao_o := PORTA_X - PORTA_L / 2
	var vao_l := PORTA_X + PORTA_L / 2
	for t: Array in [["O", x0, vao_o], ["L", vao_l, x1]]:
		_quad(c, "ParedeSala" + t[0], Vector2(t[2] - t[1], H), Vector3((t[1] + t[2]) / 2, H / 2, perto), Vector3.ZERO, "parede_corredor")
		# Do lado oeste, a porta 308: o lambri para nela.
		var trechos := _trechos(t[1], t[2], [Vector2(-3.25 - 0.54, -3.25 + 0.54)])
		for i in trechos.size():
			var a: float = trechos[i].x
			var b: float = trechos[i].y
			_box(c, "LambriSala%s%d" % [t[0], i], Vector3(b - a, 1.0, 0.02), Vector3((a + b) / 2, 0.5, perto + 0.01), "lambri")
			_box(c, "MolduraSala%s%d" % [t[0], i], Vector3(b - a, 0.04, 0.04), Vector3((a + b) / 2, 1.02, perto + 0.02), "madeira_escura")
			_box(c, "RodapeSala%s%d" % [t[0], i], Vector3(b - a, 0.12, 0.045), Vector3((a + b) / 2, 0.06, perto + 0.0225), "madeira_escura")
			# As almofadas: do lado da porta dele, afastadas do alizar.
			var aa := a
			var bb := b
			if is_equal_approx(b, vao_o):
				bb -= 0.12
			if is_equal_approx(a, vao_l):
				aa += 0.12
			_almofadas(c, "AlmofadasSala%s%d" % [t[0], i], aa, bb, perto + 0.025, 1.0)
	_quad(c, "ParedeSalaAlto", Vector2(PORTA_L, H - PORTA_H), Vector3(PORTA_X, (H + PORTA_H) / 2, perto), Vector3.ZERO, "parede_corredor")
	for s in [-1, 1]:
		_box(c, "Montante%d" % (s + 1), Vector3(0.03, PORTA_H, PAREDE_SUL), Vector3(PORTA_X + s * (PORTA_L / 2 + 0.015), PORTA_H / 2, D + PAREDE_SUL / 2), "madeira_clara")
	_box(c, "VaoAlto", Vector3(PORTA_L + 0.06, 0.03, PAREDE_SUL), Vector3(PORTA_X, PORTA_H + 0.015, D + PAREDE_SUL / 2), "madeira_clara")
	# O alizar do lado do corredor.
	for s in [-1, 1]:
		_box(c, "Alizar%d" % (s + 1), Vector3(0.1, PORTA_H + 0.12, 0.025), Vector3(PORTA_X + s * (PORTA_L / 2 + 0.07), (PORTA_H + 0.12) / 2, perto + 0.0125), "madeira_escura")
	_box(c, "AlizarVerga", Vector3(PORTA_L + 0.3, 0.14, 0.03), Vector3(PORTA_X, PORTA_H + 0.12, perto + 0.015), "madeira_escura")
	# A plaqueta de latão com o nome, na parede junto à porta, do lado de fora.
	var placa := _group(c, "Plaqueta", Vector3(vao_l + 0.28, 1.5, perto + 0.012))
	_box(placa, "Latao", Vector3(0.24, 0.075, 0.006), Vector3.ZERO, "latao")
	_letreiro(placa, "Nome", "A. N. WILMARTH", Vector3(0, 0.009, 0.004), 0.00042, Color(0.18, 0.12, 0.05))
	_letreiro(placa, "Cargo", "LITERATURE", Vector3(0, -0.018, 0.004), 0.0003, Color(0.18, 0.12, 0.05))

	# Playtest 6 ("o corredor está muito simples"): as almofadas do lambri, a
	# cimalha no alto das duas paredes, a passadeira, a segunda luz, a janela com
	# o radiador no fim, o quadro de avisos, o banco, a outra porta do lado da sala
	# e o cinzeiro de pé no alto da escada.
	for t: Array in [["Fundo", fundo - 0.04, -1.0], ["Perto", perto + 0.04, 1.0]]:
		_box(c, "Cimalha" + t[0], Vector3(largura, 0.1, 0.08), Vector3(cx, H - 0.05, t[1]), "madeira_escura")
		_box(c, "CimalhaFilete" + t[0], Vector3(largura, 0.025, 0.11), Vector3(cx, H - 0.11, t[1] + t[2] * 0.015), "madeira_escura")
	_quad(c, "Passadeira", Vector2(largura - 0.2, 0.78), Vector3(cx + 0.1, 0.004, meio), Vector3(-90, 0, 0), "passadeira")
	for s in [-1, 1]:
		_box(c, "Galao%d" % (s + 1), Vector3(largura - 0.2, 0.004, 0.035), Vector3(cx + 0.1, 0.006, meio + s * 0.37), "latao")
	for k in 2:
		var gx: float = [PORTA_X, -3.0][k]
		var globo := Vector3(gx, H - 0.32, meio)
		_cyl(c, "Haste%d" % k, 0.008, 0.008, 0.24, globo + Vector3(0, 0.2, 0), "latao", 6)
		_cyl(c, "Roseta%d" % k, 0.05, 0.05, 0.02, Vector3(gx, H - 0.01, meio), "latao", 8)
		_cyl(c, "Globo%d" % k, 0.1, 0.07, 0.17, globo, "vidro_aceso", 8)
	var luz := _omni(c, "Luz", Vector3(PORTA_X, H - 0.47, meio), Color(1.0, 0.8, 0.55), 1.4, 4.5)
	luz.omni_attenuation = 1.3
	var luz2 := _omni(c, "Luz2", Vector3(-3.0, H - 0.47, meio), Color(1.0, 0.8, 0.55), 1.0, 3.8)
	luz2.omni_attenuation = 1.3

	# No fim, a oeste: a janela de guilhotina com o vidro fosco do poço de luz e,
	# embaixo dela, o radiador de ferro fundido.
	var jan := _group(c, "Janela", Vector3(x0, 0, meio), 90)
	_quad(jan, "Vidro", Vector2(0.8, 1.5), Vector3(0, 1.75, 0.015), Vector3.ZERO, "vidro_janela")
	for s in [-1, 1]:
		_box(jan, "Montante%d" % (s + 1), Vector3(0.07, 1.62, 0.07), Vector3(s * 0.435, 1.75, 0.03), "madeira_escura")
	_box(jan, "Verga", Vector3(1.0, 0.1, 0.08), Vector3(0, 2.55, 0.035), "madeira_escura")
	_box(jan, "Peitoril", Vector3(1.04, 0.04, 0.16), Vector3(0, 0.98, 0.07), "madeira_escura")
	_box(jan, "Trilho", Vector3(0.8, 0.05, 0.05), Vector3(0, 1.75, 0.04), "madeira_escura")
	for y: float in [1.38, 2.12]:
		_box(jan, "Pinazio%d" % int(y * 100), Vector3(0.025, 0.7, 0.03), Vector3(0, y, 0.035), "madeira_escura")
	_box(jan, "Tranca", Vector3(0.06, 0.015, 0.04), Vector3(0, 1.79, 0.07), "latao")
	var rad := _group(jan, "Radiador", Vector3(0, 0, 0.16))
	for k in 12:
		_box(rad, "Coluna%d" % k, Vector3(0.045, 0.62, 0.13), Vector3(-0.3 + k * 0.055, 0.39, 0), "ferro")
	_box(rad, "Base", Vector3(0.7, 0.04, 0.1), Vector3(0, 0.1, 0), "ferro")
	_box(rad, "Topo", Vector3(0.68, 0.03, 0.11), Vector3(0, 0.71, 0), "ferro")
	for s in [-1, 1]:
		_cyl(rad, "Pe%d" % (s + 1), 0.018, 0.018, 0.08, Vector3(s * 0.3, 0.04, 0), "ferro", 6)
	_cyl(rad, "Valvula", 0.02, 0.02, 0.06, Vector3(0.38, 0.2, 0), "latao", 6).rotation_degrees.z = 90

	# O quadro de avisos de cortiça entre a calha e a porta vizinha, com papéis
	# pregados, e o banco de madeira embaixo dele.
	var avisos := _group(c, "Avisos", Vector3(-1.95, 1.55, fundo - 0.02), 180)
	_box(avisos, "Moldura", Vector3(0.9, 0.62, 0.03), Vector3.ZERO, "madeira_escura")
	_quad(avisos, "Cortica", Vector2(0.82, 0.54), Vector3(0, 0, 0.016), Vector3.ZERO, "cortica")
	# Playtest 8: "os papéis no mural podem ter algo para ler". Avisos da
	# Miskatonic em 1928, em inglês (examináveis, com a tradução): o socorro às
	# vítimas das enchentes de Vermont (com que o livro começa), o horário de
	# Wilmarth, a biblioteca de Armitage, uma palestra, um achado, um quarto.
	var papeis := [[Vector2(0.16, 0.22), Vector2(-0.27, 0.08), 3], [Vector2(0.2, 0.14), Vector2(-0.04, 0.12), -2],
		[Vector2(0.13, 0.19), Vector2(0.2, 0.1), 5], [Vector2(0.18, 0.12), Vector2(0.24, -0.13), -4],
		[Vector2(0.15, 0.2), Vector2(-0.18, -0.13), 1], [Vector2(0.1, 0.13), Vector2(0.03, -0.14), -6]]
	for i in papeis.size():
		var pp: Array = papeis[i]
		var av := _group(avisos, "Aviso%d" % i, Vector3(pp[1].x, pp[1].y, 0.019 + i * 0.0005))
		av.rotation_degrees.z = pp[2]
		# Papel liso (o "papel" tem pauta).
		_quad(av, "Papel", pp[0], Vector3.ZERO, Vector3.ZERO, "envelope")
		_cyl(av, "Tacha", 0.006, 0.006, 0.006, Vector3(0, pp[0].y * 0.42, 0.005), "latao", 5).rotation_degrees.x = 90
		var aviso: Array = AVISOS[i]
		_impresso(av, 0.0006, pp[0].x * 0.86, aviso[0])
		var ex := _area(av, Examinable.new(), "Examinar", Vector3(pp[0].x, pp[0].y, 0.06), Vector3(0, 0, 0.02)) as Examinable
		ex.prompt = "Ler o aviso"
		ex.title = aviso[1]
		ex.description = aviso[2]
		ex.initial_rotation = Vector3.ZERO
	var banco := _group(c, "Banco", Vector3(-1.95, 0, fundo - 0.22), 180)
	_box(banco, "Assento", Vector3(1.2, 0.05, 0.34), Vector3(0, 0.45, 0), "madeira_escura")
	_box(banco, "Encosto", Vector3(1.2, 0.32, 0.03), Vector3(0, 0.74, -0.16), "madeira_escura")
	for s in [-1, 1]:
		_box(banco, "Lado%d" % (s + 1), Vector3(0.05, 0.62, 0.34), Vector3(s * 0.57, 0.33, 0), "madeira_escura")
	_box(banco, "Travessa", Vector3(1.1, 0.04, 0.03), Vector3(0, 0.14, 0.0), "madeira_escura")

	# A porta de outra sala, mais adiante, com o vidro fosco aceso e a bandeira;
	# e outra do lado da sala, a oeste (fechada, apagada).
	_porta_vizinha(c, "PortaVizinha", Vector3(-2.9, 0, fundo), 180, "312")
	_porta_vizinha(c, "PortaVizinhaSala", Vector3(-3.25, 0, perto), 0, "308", false)

	# O cinzeiro de pé, de latão, junto ao alto da escada.
	var cinz := _group(c, "CinzeiroPe", Vector3(x1 - 0.3, 0, fundo - 0.17))
	_cyl(cinz, "Base", 0.13, 0.15, 0.03, Vector3(0, 0.015, 0), "latao", 10)
	_cyl(cinz, "Haste", 0.018, 0.018, 0.62, Vector3(0, 0.34, 0), "latao", 6)
	_cyl(cinz, "Prato", 0.11, 0.07, 0.04, Vector3(0, 0.67, 0), "latao", 10)
	_cyl(cinz, "Fundo", 0.08, 0.08, 0.005, Vector3(0, 0.685, 0), "cinzas", 10)

	_escada(c, x1, perto, fundo)

	_colisao(c, "Colisao", [
		# O piso não passa da boca da escada (passava 20 cm: um degrau invisível no alto).
		[Vector3(largura + 0.2, 0.2, CORREDOR), Vector3(cx - 0.1, -0.1, meio)],
		[Vector3(largura + 0.4, H, 0.2), Vector3(cx, H / 2, fundo + 0.1)],
		[Vector3(0.2, H, CORREDOR), Vector3(x0 - 0.1, H / 2, meio)],
		[Vector3(vao_o - x0, H, PAREDE_SUL), Vector3((x0 + vao_o) / 2, H / 2, D + PAREDE_SUL / 2)],
		[Vector3(x1 - vao_l, H, PAREDE_SUL), Vector3((vao_l + x1) / 2, H / 2, D + PAREDE_SUL / 2)],
		# O radiador, o banco e o cinzeiro.
		[Vector3(0.2, 0.75, 0.75), Vector3(x0 + 0.16, 0.375, meio)],
		[Vector3(1.2, 0.8, 0.36), Vector3(-1.95, 0.4, fundo - 0.22)],
		[Vector3(0.22, 0.7, 0.22), Vector3(x1 - 0.3, 0.35, fundo - 0.17)],
	])

	# Quem anima: fora do grupo escondido (o envelope que desce é filho dela).
	_calha(g, c, fundo)


## Os trechos de a a b (x) fora dos `buracos` (as portas, a calha).
func _trechos(a: float, b: float, buracos: Array) -> Array[Vector2]:
	var r: Array[Vector2] = [Vector2(a, b)]
	for h: Vector2 in buracos:
		var novos: Array[Vector2] = []
		for t in r:
			if h.y <= t.x or h.x >= t.y:
				novos.append(t)
				continue
			if h.x - t.x > 0.05:
				novos.append(Vector2(t.x, h.x))
			if t.y - h.y > 0.05:
				novos.append(Vector2(h.y, t.y))
		r = novos
	return r


## Os montantes que dividem o lambri em almofadas, a cada ~0,6 m entre `a` e `b`
## (x), rentes à parede em `z`; `lado` é para onde a parede olha (+Z ou -Z).
func _almofadas(c: Node3D, nome: String, a: float, b: float, z: float, lado: float) -> void:
	var n := maxi(1, roundi((b - a) / 0.6))
	var passo := (b - a) / n
	var pecas := []
	for k in n + 1:
		pecas.append([Vector3(0.05, 0.8, 0.012), Vector3(a + k * passo, 0.53, z + lado * 0.004), Vector3.ZERO, Color(1, 1, 1)])
	# A travessa de baixo, sobre o rodapé.
	pecas.append([Vector3(b - a, 0.05, 0.012), Vector3((a + b) / 2, 0.15, z + lado * 0.004), Vector3.ZERO, Color(1, 1, 1)])
	_lote(c, nome, pecas, "madeira_escura")


## Um letreiro pequeno (Label3D) virado para +Z local.
func _letreiro(pai: Node3D, nome: String, texto: String, pos: Vector3, tamanho: float, cor: Color) -> Label3D:
	var l := Label3D.new()
	l.name = nome
	l.text = texto
	l.font_size = 48
	l.pixel_size = tamanho
	l.modulate = cor
	l.outline_size = 0
	l.position = pos
	_add(pai, l)
	return l


## A porta de outra sala no corredor (virada para +Z local): a folha com a
## almofada de vidro fosco e o número pintado, o batente, a bandeira em cima.
## Acesa, alguém trabalha lá dentro.
func _porta_vizinha(c: Node3D, nome: String, pos: Vector3, rot: float, numero: String, acesa := true) -> void:
	var v := _group(c, nome, pos, rot)
	var vidro := "vidro_fosco" if acesa else "vidro_janela"
	_box(v, "Folha", Vector3(0.9, 2.1, 0.05), Vector3(0, 1.05, 0.0), "madeira_escura")
	_box(v, "Vidro", Vector3(0.6, 0.62, 0.07), Vector3(0, 1.55, 0.0), vidro)
	_box(v, "Almofada", Vector3(0.6, 0.55, 0.06), Vector3(0, 0.55, 0.0), "madeira_clara")
	_box(v, "Batente", Vector3(1.04, 2.18, 0.04), Vector3(0, 1.09, -0.01), "madeira_clara")
	_box(v, "Macaneta", Vector3(0.05, 0.05, 0.06), Vector3(0.36, 1.0, 0.05), "latao")
	_box(v, "Bandeira", Vector3(0.86, 0.36, 0.04), Vector3(0, 2.42, 0.0), vidro)
	_box(v, "BandeiraMoldura", Vector3(1.04, 0.06, 0.06), Vector3(0, 2.62, 0.0), "madeira_clara")
	_box(v, "Travessa", Vector3(1.04, 0.06, 0.06), Vector3(0, 2.21, 0.0), "madeira_clara")
	_letreiro(v, "Numero", numero, Vector3(0, 1.66, 0.037), 0.0007, Color(0.12, 0.08, 0.05))


## A calha de latão na parede da frente do corredor (CalhaCorreio).
func _calha(g: Node3D, c: Node3D, fundo: float) -> void:
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
		var l := _letreiro(cal, "Plaqueta" + t[0].replace(".", "").replace(" ", ""), t[0], Vector3(0, CALHA_BOCA + t[1], -0.0975), 0.0006, Color(0.25, 0.17, 0.08))
		l.rotation_degrees.y = 180

	var calha := CalhaCorreio.new()
	calha.name = "Calha"
	calha.position = Vector3(CALHA_X, CALHA_BOCA, fundo - 0.1)
	calha.rotation_degrees.y = 180
	_add(g, calha)
	calha.unique_name_in_owner = true
	calha.folha = _folha_porta
	calha.corredor = c
	# A boca: com a carta na mão e a porta aberta, "Pôr a carta na calha".
	var boca := _area(calha, Interactable.new(), "PorNaCalha", Vector3(0.3, 0.4, 0.16), Vector3(0, 0, 0.04)) as Interactable
	boca.unique_name_in_owner = true
	boca.prompt = "Pôr a carta na calha"
	# Para abrir a porta, ao lado da maçaneta, fora do arco da folha; de fora,
	# diante da maçaneta (a folha abre para longe dele).
	calha.diante = Vector3(PORTA_X + 0.65, 0, D - 0.55)
	calha.diante_fora = Vector3(PORTA_X + 0.45, 0, D + PAREDE_SUL + 0.5)
	calha.soleira = Vector3(PORTA_X + 0.05, 0, D + PAREDE_SUL / 2)
	calha.na_calha = Vector3(CALHA_X, 0, fundo - 0.55)
	calha.queda = Vector2(-0.02, -CALHA_BOCA + 0.08)
	calha.som_abrir = load(SFX_DIR + "porta_rangendo.wav")
	calha.som_fechar = load(SFX_DIR + "porta_trinco.wav")
	calha.som_calha = load(SFX_DIR + "calha_correio.wav")


## A escada no fim do corredor (Fase 3e; Fase 3f; playtest 6, andável): o
## primeiro lanço desce para leste, entre as paredes, até um patamar; o segundo
## vira para o sul e desce ao andar de baixo, onde fica a porta da rua — é dali
## que ele sobe toda manhã (a marca `Porta`), e é no patamar que, descendo para
## casa, o dia acaba (%Escada). O corrimão de madeira com o pilar no alto, os
## balaústres, e a volta no pilar do patamar. Rampas invisíveis por baixo dos
## narizes dos degraus fazem a colisão.
func _escada(c: Node3D, x: float, perto: float, fundo: float) -> void:
	var e := _group(c, "Escada")
	var n := 9
	var largura := fundo - perto
	var meio := (perto + fundo) / 2
	var desce := n * DEGRAU.y
	for k in n:
		var topo := -(k + 1) * DEGRAU.y
		_box(e, "Degrau%d" % k, Vector3(DEGRAU.x, DEGRAU.y, largura), Vector3(x + (k + 0.5) * DEGRAU.x, topo - DEGRAU.y / 2, meio), "madeira_escura")
		# O nariz do degrau, na borda da frente (a de baixo), um pouco saliente.
		_box(e, "Nariz%d" % k, Vector3(0.03, 0.025, largura), Vector3(x + (k + 1) * DEGRAU.x + 0.005, topo - 0.0125, meio), "madeira_clara")
	# O espelho do primeiro degrau, do piso do corredor até ele (playtest 7: o
	# vão de 18 cm mostrava o vazio por baixo do piso).
	_box(e, "Espelho", Vector3(0.03, DEGRAU.y + 0.04, largura), Vector3(x + 0.015, -DEGRAU.y / 2 + 0.01, meio), "madeira_escura")
	var x2 := x + n * DEGRAU.x
	var xe := x2 + largura
	var xm := (x2 + xe) / 2
	var y1 := -desce
	var y2 := y1 - desce
	var zf := fundo + n * DEGRAU.x
	var zb := zf + 1.6
	var baixo := y2 - 0.3
	var alto := H - baixo
	var cy := (H + baixo) / 2
	# Grosso até o primeiro degrau do segundo lanço (com 12 cm, o vão de baixo
	# mostrava o vazio — playtest 7).
	_box(e, "Patamar", Vector3(largura, DEGRAU.y + 0.12, largura), Vector3(xm, y1 - (DEGRAU.y + 0.12) / 2, meio), "madeira_escura")
	_box(e, "PatamarNariz", Vector3(largura, 0.025, 0.03), Vector3(xm, y1 - 0.0125, fundo - 0.005), "madeira_clara")
	for k in n:
		var topo := y1 - (k + 1) * DEGRAU.y
		var zk := fundo + (k + 0.5) * DEGRAU.x
		_box(e, "Degrau2_%d" % k, Vector3(largura, DEGRAU.y, DEGRAU.x), Vector3(xm, topo - DEGRAU.y / 2, zk), "madeira_escura")
		_box(e, "Nariz2_%d" % k, Vector3(largura, 0.025, 0.03), Vector3(xm, topo - 0.0125, fundo + (k + 1) * DEGRAU.x + 0.005), "madeira_clara")
	_quad(e, "PisoBaixo", Vector2(largura, zb - zf), Vector3(xm, y2, (zf + zb) / 2), Vector3(-90, 0, 0), "piso_corredor")
	# As paredes do vão: a de perto corre os dois lanços; a de trás, só o primeiro.
	_quad(e, "ParedePerto", Vector2(xe - x, alto), Vector3((x + xe) / 2, cy, perto), Vector3.ZERO, "parede_corredor")
	_quad(e, "ParedeFundo", Vector2(x2 - x, alto), Vector3((x + x2) / 2, cy, fundo), Vector3(0, 180, 0), "parede_corredor")
	_quad(e, "ParedeFim", Vector2(zb - perto, alto), Vector3(xe, cy, (perto + zb) / 2), Vector3(0, -90, 0), "parede_corredor")
	_quad(e, "ParedeLanco2", Vector2(zb - fundo, alto), Vector3(x2, cy, (fundo + zb) / 2), Vector3(0, 90, 0), "parede_corredor")
	_quad(e, "ParedeSul", Vector2(largura, alto), Vector3(xm, cy, zb), Vector3(0, 180, 0), "parede_corredor")
	_quad(e, "Teto", Vector2(xe - x, largura), Vector3((x + xe) / 2, H, meio), Vector3(90, 0, 0), "teto")
	_quad(e, "Teto2", Vector2(largura, zb - fundo), Vector3(xm, H, (fundo + zb) / 2), Vector3(90, 0, 0), "teto")
	# O lambri do patamar e o de baixo, que se veem da escada.
	_box(e, "LambriPatamar", Vector3(largura, 1.0, 0.02), Vector3(xm, y1 + 0.5, perto + 0.01), "lambri")
	_box(e, "LambriPatamarFim", Vector3(0.02, 1.0, largura), Vector3(xe - 0.01, y1 + 0.5, meio), "lambri")
	for t: Array in [["Fim", xe - 0.01], ["O", x2 + 0.01]]:
		_box(e, "LambriBaixo" + t[0], Vector3(0.02, 1.0, zb - zf), Vector3(t[1], y2 + 0.5, (zf + zb) / 2), "lambri")
		_box(e, "RodapeBaixo" + t[0], Vector3(0.045, 0.12, zb - zf), Vector3(t[1], y2 + 0.06, (zf + zb) / 2), "madeira_escura")
	# Lá embaixo, a porta da rua: a folha dupla de carvalho com os vidros foscos,
	# claros da rua, e a bandeira; o capacho.
	var rua := _group(e, "PortaRua", Vector3(xm, y2, zb - 0.02), 180)
	for s in [-1, 1]:
		_box(rua, "Folha%d" % (s + 1), Vector3(0.52, 2.3, 0.06), Vector3(s * 0.265, 1.15, 0), "madeira_escura")
		_box(rua, "Vidro%d" % (s + 1), Vector3(0.34, 0.9, 0.075), Vector3(s * 0.265, 1.55, 0), "vidro_janela")
		_box(rua, "Puxador%d" % (s + 1), Vector3(0.03, 0.18, 0.05), Vector3(s * 0.05, 1.05, 0.05), "latao")
	_box(rua, "Bandeira", Vector3(1.04, 0.32, 0.05), Vector3(0, 2.5, 0), "vidro_janela")
	_box(rua, "Batente", Vector3(1.2, 2.82, 0.04), Vector3(0, 1.41, -0.02), "madeira_clara")
	_box(rua, "Capacho", Vector3(0.8, 0.015, 0.45), Vector3(0, 0.0075, 0.35), "papel_pardo")

	# O corrimão, do lado de dentro: o pilar no alto, a barra inclinada e os
	# balaústres; no patamar, o outro pilar, e a volta para o segundo lanço.
	var z := fundo - 0.07
	var a := atan2(desce, n * DEGRAU.x)
	var comp := Vector2(n * DEGRAU.x, desce).length()
	var pilar := _box(e, "Pilar", Vector3(0.08, 1.05, 0.08), Vector3(x + 0.04, 0.525, z), "madeira_escura")
	_cyl(e, "Pomo", 0.05, 0.045, 0.07, pilar.position + Vector3(0, 0.56, 0), "madeira_escura", 8)
	var barra := _box(e, "Corrimao", Vector3(comp, 0.05, 0.06), Vector3(x + 0.04 + n * DEGRAU.x / 2, 0.95 - desce / 2, z), "madeira_escura")
	barra.rotation.z = -a
	for k in n:
		var bx := x + (k + 0.5) * DEGRAU.x
		var chao := -(k + 1) * DEGRAU.y
		var topo := 0.95 - (bx - x - 0.04) * tan(a)
		_box(e, "Balaustre%d" % k, Vector3(0.025, topo - chao, 0.025), Vector3(bx, (topo + chao) / 2, z), "madeira_escura")
	var xr := x2 + 0.07
	var pilar2 := _box(e, "PilarPatamar", Vector3(0.08, 1.15, 0.08), Vector3(xr, y1 + 0.575, z), "madeira_escura")
	_cyl(e, "PomoPatamar", 0.05, 0.045, 0.07, pilar2.position + Vector3(0, 0.61, 0), "madeira_escura", 8)
	var barra2 := _box(e, "Corrimao2", Vector3(0.06, 0.05, comp), Vector3(xr, y1 + 0.95 - desce / 2, fundo + n * DEGRAU.x / 2), "madeira_escura")
	barra2.rotation.x = a
	for k in n:
		var bz := fundo + (k + 0.5) * DEGRAU.x
		var chao := y1 - (k + 1) * DEGRAU.y
		var topo := y1 + 0.95 - (bz - fundo) * tan(a)
		_box(e, "Balaustre2_%d" % k, Vector3(0.025, topo - chao, 0.025), Vector3(xr, (topo + chao) / 2, bz), "madeira_escura")
	var pilar3 := _box(e, "PilarBaixo", Vector3(0.09, 1.05, 0.09), Vector3(xr, y2 + 0.525, zf + 0.05), "madeira_escura")
	_cyl(e, "PomoBaixo", 0.055, 0.05, 0.08, pilar3.position + Vector3(0, 0.56, 0), "madeira_escura", 8)
	# No patamar, uma arandela na parede do fim (mostra a volta); lá embaixo, a
	# luz junto à porta da rua (é dali que ele sobe de manhã).
	var arandela := Vector3(xe - 0.06, y1 + 1.75, meio + 0.2)
	_box(e, "Arandela", Vector3(0.05, 0.12, 0.08), arandela, "latao")
	_cyl(e, "Cupula", 0.05, 0.035, 0.09, arandela + Vector3(-0.06, 0.04, 0), "vidro_aceso", 8)
	var luz_patamar := _omni(e, "LuzPatamar", arandela + Vector3(-0.25, -0.1, 0), Color(1.0, 0.74, 0.45), 1.1, 3.6)
	luz_patamar.omni_attenuation = 1.4
	var arandela2 := Vector3(xe - 0.06, y2 + 1.85, zf + 0.7)
	_box(e, "ArandelaBaixo", Vector3(0.05, 0.12, 0.08), arandela2, "latao")
	_cyl(e, "CupulaBaixo", 0.05, 0.035, 0.09, arandela2 + Vector3(-0.06, 0.04, 0), "vidro_aceso", 8)
	var luz := _omni(e, "LuzBaixo", arandela2 + Vector3(-0.3, -0.2, 0), Color(1.0, 0.76, 0.48), 1.5, 4.5)
	luz.omni_attenuation = 1.4

	# A colisão: as rampas rentes aos narizes, o patamar, o piso de baixo e as
	# paredes do vão.
	var ang := rad_to_deg(a)
	var n1 := Vector3(sin(a), cos(a), 0) * 0.1
	var n2 := Vector3(0, cos(a), sin(a)) * 0.1
	var piso := baixo - 1.0
	_colisao(e, "Colisao", [
		[Vector3(comp, 0.2, largura), Vector3(x + n * DEGRAU.x / 2, -desce / 2, meio) - n1, Vector3(0, 0, -ang)],
		[Vector3(largura + 0.2, 0.2, largura), Vector3(xm, y1 - 0.1, meio)],
		[Vector3(largura, 0.2, comp), Vector3(xm, y1 - desce / 2, fundo + n * DEGRAU.x / 2) - n2, Vector3(ang, 0, 0)],
		[Vector3(largura, 0.2, zb - zf + 0.2), Vector3(xm, y2 - 0.1, (zf + zb) / 2)],
		[Vector3(xe - x, H - piso, 0.2), Vector3((x + xe) / 2, (H + piso) / 2, perto - 0.1)],
		[Vector3(x2 - x, H - piso, 0.2), Vector3((x + x2) / 2, (H + piso) / 2, fundo + 0.1)],
		[Vector3(0.2, H - piso, zb - perto), Vector3(xe + 0.1, (H + piso) / 2, (perto + zb) / 2)],
		[Vector3(0.2, H - piso, zb - fundo), Vector3(x2 - 0.1, (H + piso) / 2, (fundo + zb) / 2)],
		[Vector3(largura, H - piso, 0.2), Vector3(xm, (H + piso) / 2, zb + 0.1)],
	])
	# No patamar, descendo com o dia acabado: ele foi para casa (Escritorio._on_escada).
	var area := Area3D.new()
	area.name = "Escada"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitorable = false
	area.position = Vector3(xm, y1 + 1.0, meio)
	_add(c.get_parent(), area)
	area.unique_name_in_owner = true
	var forma := CollisionShape3D.new()
	forma.name = "Forma"
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(largura * 0.8, 2.0, largura)
	forma.shape = caixa
	_add(area, forma)


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
	# A xícara é aberta (playtest 5: o café tem de se ver): a copa sem tampa, a
	# parede de dentro (a face virada para o centro) e a borda.
	var xicara := _group(b, "Xicara", Vector3(0.72, MESA + 0.008, -1.87))
	(_cyl(xicara, "Copa", 0.043, 0.03, 0.055, Vector3(0, 0.0275, 0), "porcelana", 14).mesh as CylinderMesh).cap_top = false
	var dentro := _cyl(xicara, "Dentro", 0.04, 0.026, 0.05, Vector3(0, 0.03, 0), "porcelana", 14).mesh as CylinderMesh
	dentro.cap_top = false
	dentro.flip_faces = true
	var borda := TorusMesh.new()
	borda.inner_radius = 0.039
	borda.outer_radius = 0.044
	borda.rings = 14
	borda.ring_segments = 4
	var aro := MeshInstance3D.new()
	aro.name = "Borda"
	aro.mesh = borda
	aro.material_override = m["porcelana"]
	aro.position = Vector3(0, 0.055, 0)
	aro.scale = Vector3(1, 0.5, 1)
	_add(xicara, aro)
	var asa := _box(xicara, "Asa", Vector3(0.025, 0.03, 0.008), Vector3(0.05, 0.03, 0), "porcelana")
	asa.rotation_degrees.z = 10
	# O café: o topo (o que se vê) fica rente à parede de dentro, abaixo da borda.
	_nivel(xicara, 0.037, 0.04, 0.006, "cafe", 0.026)
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
	# No espaço da escrivaninha (o pai da gaveta): em pé, junto ao copo, só
	# enquanto serve (depois volta para a gaveta).
	b.frasco_servindo = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(-25.0), 0)), Vector3(0.74, MESA, -0.1))
	b.som_servir = load(SFX_DIR + "servir.wav")
	b.som_gaveta = load(SFX_DIR + "gaveta.wav")
	var bebidas: Dictionary[int, int] = {1: 1, 2: 1, 3: 1, 4: 2}
	cena.set("bebidas", bebidas)


## A noite do Dia 5: anotado o dia, com o fogo aceso, "Sentar diante do fogo" na
## poltrona, com o copo de uísque servido na mesinha ao lado (LugarSono).
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
	# O copo servido, na mesinha ao lado da poltrona (ele o trouxe da mesa).
	var copo := _grupo_se(g, "CopoFogo", _flag(&"anotou_dia_5"))
	copo.position = _mesinha_pos() + Vector3(-0.07, MESINHA_ALTURA, -0.09)
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


## O líquido: um pivô no fundo que cresce para cima (Bebida escala o y). Num
## recipiente que afunila (a xícara), `raio_fundo` dá o fundo, e o nível guarda
## a razão (meta `afunila`): enchendo, ele alarga junto, rente à parede.
func _nivel(recipiente: Node3D, raio: float, altura: float, fundo: float, mat: String, raio_fundo := -1.0) -> void:
	var nivel := _group(recipiente, "Nivel", Vector3(0, fundo, 0))
	nivel.visible = false
	var baixo := raio * 0.92 if raio_fundo < 0.0 else raio_fundo
	if raio_fundo >= 0.0:
		nivel.set_meta(&"afunila", raio_fundo / raio)
	_cyl(nivel, "Liquido", raio, baixo, altura, Vector3(0, altura / 2, 0), mat, 14)


## A mesinha de apoio ao lado da poltrona (Fase 3e: "uma mesa de apoio para
## bebidas"): tampo redondo sobre um pé torneado de três garras; em cima, o
## cinzeiro de latão e um livro deixado aberto de borco.
static func _mesinha_pos() -> Vector3:
	return POLTRONA_POS + Vector3(0.62, 0, 0.1).rotated(Vector3.UP, deg_to_rad(POLTRONA_ROT))


func _mesinha(parent: Node) -> void:
	var g := _group(parent, "Mesinha", _mesinha_pos(), 15)
	var alt := MESINHA_ALTURA
	_cyl(g, "Tampo", 0.2, 0.2, 0.025, Vector3(0, alt - 0.0125, 0), "madeira_escura", 12)
	_cyl(g, "Saia", 0.18, 0.18, 0.04, Vector3(0, alt - 0.045, 0), "madeira_escura", 12)
	_cyl(g, "Pe", 0.025, 0.035, alt - 0.17, Vector3(0, 0.12 + (alt - 0.17) / 2, 0), "madeira_escura", 8)
	_cyl(g, "Anel", 0.045, 0.045, 0.04, Vector3(0, 0.36, 0), "madeira_escura", 8)
	_cyl(g, "Base", 0.05, 0.06, 0.06, Vector3(0, 0.12, 0), "madeira_escura", 8)
	for k in 3:
		var garra := _box(g, "Garra%d" % k, Vector3(0.04, 0.03, 0.2), Vector3(0, 0, 0), "madeira_escura")
		var a := TAU * k / 3.0
		garra.position = Vector3(sin(a), 0, cos(a)) * 0.1 + Vector3(0, 0.06, 0)
		garra.rotation = Vector3(deg_to_rad(18.0), a, 0)
	_cyl(g, "Cinzeiro", 0.05, 0.045, 0.015, Vector3(-0.08, alt + 0.0075, 0.07), "latao", 10)
	var livro := _box(g, "Livro", Vector3(0.13, 0.02, 0.19), Vector3(0.06, alt + 0.01, -0.04), "capa_livro")
	livro.rotation_degrees.y = 25
	_colisao(g, "Colisao", [[Vector3(0.36, alt, 0.36), Vector3(0, alt / 2, 0)]])


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
	# O lapso começa e termina nesta hora (Lapso._cidade_viva).
	v.set_meta(&"hora", hora)
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


## Uma vista em 3D (tools/vistas.gd) atrás da janela, nas coordenadas da sala.
func _vista_3d(parent: Node, vista: Node3D) -> Node3D:
	_add(parent, vista)
	for filho in vista.get_children():
		filho.owner = cena
	return vista


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
	# A janela viva (Fase 3e): a cidade com materiais só dela, animados pelo lapso.
	var viva: Node3D = _cidade.vista_viva("dia")
	viva.visible = false
	_add(lapso, viva)
	for filho in viva.get_children():
		filho.owner = cena
	lapso.cidade = viva
	lapso.horas = _cidade.horas_do_lapso()

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
	var datas: Array[int] = [0, Lapso.dia_do_ano(5, 8), Lapso.dia_do_ano(5, 24), Lapso.dia_do_ano(7, 2), Lapso.dia_do_ano(7, 18), Lapso.dia_do_ano(8, 15), Lapso.dia_do_ano(8, 28)]
	cena.set("datas_dia", datas)
	var depois: Dictionary[StringName, int] = {
		&"cartao_sexta": Lapso.dia_do_ano(7, 20),
		&"cartao_telegrama_akely": Lapso.dia_do_ano(8, 17), &"cartao_aprofundava": Lapso.dia_do_ano(8, 23),
		&"cartao_31_agosto": Lapso.dia_do_ano(8, 31), &"cartao_5_setembro": Lapso.dia_do_ano(9, 5),
		&"cartao_6_setembro": Lapso.dia_do_ano(9, 6),
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
	# Só a faixa: com as tampas, o aro fechava a boca do cesto.
	var aro := _cyl(c, "Aro", 0.155, 0.155, 0.02, Vector3(0, 0.335, 0), "madeira_escura", 9).mesh as CylinderMesh
	aro.cap_top = false
	aro.cap_bottom = false
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
## Camada de render do que a luz da fresta (LuzCorredor) não alcança: o armário.
const CAMADA_SEM_FRESTA := 2
## A porta do escritório (sul): o meio do vão, a largura e a altura da folha.
const PORTA_X := -1.0
const PORTA_L := 0.92
const PORTA_H := 2.1
## O corredor atrás dela (largura) e a calha de correio na parede da frente.
const CORREDOR := 1.4
const CALHA_X := -0.92
const CALHA_BOCA := 1.15
## A espessura da parede sul (entre a sala e o corredor).
const PAREDE_SUL := 0.14
## Onde o corredor acaba, a leste, e a escada começa a descer.
const ESCADA_X := 2.0
const DEGRAU := Vector2(0.28, 0.18)
## O pé da escada, no andar de baixo (9 + 9 degraus abaixo), junto à porta da rua.
const ESCADA_PE := Vector3(ESCADA_X + 9 * DEGRAU.x + CORREDOR / 2, -18 * DEGRAU.y, D + CORREDOR + 9 * DEGRAU.x + 0.9)
## A poltrona, ao lado da lareira e virada para ela (Fase 3e: estava no meio da
## sala), com a mesinha de apoio à direita: onde ele adormece nas noites 3 e 5.
## Afastada das paredes e da lareira (playtest 6), ainda virada para o fogo.
const POLTRONA_POS := Vector3(1.15, 0, 0.95)
const POLTRONA_ROT := -32.0
const MESINHA_ALTURA := 0.6


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


func _escrever(parent: Node, resposta: String, carta_lida: StringName) -> WriteReply:
	var escrever := _area(parent, WriteReply.new(), "Escrever", Vector3(0.36, 0.2, 0.36), Vector3(0.33, 0.85, -2.22)) as WriteReply
	escrever.prompt = "Escrever a Akeley"
	escrever.reply = load("res://narrative/replies/%s.tres" % resposta)
	escrever.condition = _cond_valor(carta_lida, ValueCondition.Op.MAIOR_OU_IGUAL, 1)
	return escrever


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


## Dia 6 (cap. IV): de 28 de agosto às três últimas cartas manuscritas. Abre com
## a carta da "saída digna" (playtest 8: era o fim do Dia 5) e a resposta
## animadora; depois, a resposta mais calma de Akeley; o ânimo de Wilmarth cruza
## no correio com a carta de segunda, que traz a de terça no dia seguinte
## (DocumentData.cartao_depois); lida a de terça, a noite em claro (Vigilia), e a
## de quarta cai pela fresta ao raiar o dia. Selada a carta registrada, a letra da
## última enche a tela e a tinta vira o céu de Vermont
## (Escritorio._para_o_interludio). Noite sem lua.
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

	# 28 de agosto, de manhã: "uma saída digna". A resposta animadora cruza o
	# correio até a carta calma de 31 de agosto (ReplyData.cartao_depois).
	var c28 := _group(g, "Carta28")
	var folha28 := _folha(c28, "Folha", Vector3(0.45, MESA + 0.003, -2.12), 8, "carta_akeley_28_agosto", "Ler a carta de 28 de agosto", false)
	_dentro(folha28.get_parent(), &"28_agosto")
	_correio(c28, "Envelope", &"28_agosto", CHAO_C, Vector3(-0.05, -1.86, 4), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "AUG 27\n1928",
	}, "Envelope de Brattleboro",
		"A letra continua trêmula, mas o envelope veio fechado com cuidado. Carimbo de Brattleboro, 27 de agosto.")
	_escrever(c28, "resposta_dia_5", &"leu_carta_akeley_28_agosto")

	# 31 de agosto: menos terrores. Wilmarth o anima de novo.
	var calma := _grupo_se(g, "Setembro", _flag(&"narrou_cartao_31_agosto"))
	var setembro := _folha(calma, "CartaSetembro", Vector3(-0.1, MESA + 0.003, -2.1), -6, "carta_akeley_setembro", "Ler a carta", false)
	_dentro(setembro.get_parent(), &"setembro")
	_correio(calma, "Envelope", &"setembro", CHAO_A, Vector3(-0.15, -2.47, -4), {
		remetente = REMETENTE_BRATTLEBORO,
		carimbo_cidade = "BRATTLEBORO",
		carimbo_data = "AUG 31\n1928",
	}, "Envelope de Brattleboro",
		"A letra ainda treme, mas está mais firme do que em agosto. Carimbo de Brattleboro, 31 de agosto.")
	var animo := _grupo_se(g, "Animo", _composta(CompositeCondition.Mode.TODAS,
		[_flag(&"narrou_cartao_31_agosto"), _flag(&"narrou_cartao_5_setembro", true)]))
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
	_vigilia(g)


## A noite em claro do Dia 6 (Vigilia; playtest 8), depois da carta de terça: as
## áreas aqui; os nós de fora (a janela, as cortinas, o telefone, o lapso), em
## _ligar_vigilia, com a cena montada.
func _vigilia(g: Node3D) -> void:
	var v := Vigilia.new()
	v.name = "Vigilia"
	_add(g, v)
	v.linha_inicio = load("res://narrative/narration/vigilia_inicio.tres")
	v.linha_fim = load("res://narrative/narration/cartao_7_setembro.tres")
	v.data_fim = Lapso.dia_do_ano(9, 7)
	v.campainha = load(SFX_DIR + "campainha.wav")
	v.som_janela = load(SFX_DIR + "gaveta.wav")
	v.som_vento = load(SFX_DIR + "noite.wav")
	var fechar := _area(v, Interactable.new(), "FecharJanela", Vector3(1.5, 1.1, 0.2), Vector3(0, 1.35, -D + 0.3)) as Interactable
	fechar.prompt = "Fechar a janela"
	v.fechar = fechar
	var esperar := _area(v, Interactable.new(), "Esperar", Vector3(0.6, 0.6, 0.6), Vector3(0, 0.6, -1.3)) as Interactable
	esperar.prompt = "Sentar e esperar o dia"
	v.esperar = esperar


## Os nós que a vigília mexe e que nascem fora do Dia 6.
func _ligar_vigilia() -> void:
	var v := cena.find_child("Vigilia", true, false) as Vigilia
	v.lapso = cena.get("lapso")
	v.folha = cena.get_node("Estrutura/Janela/FolhaBaixoL") as Node3D
	v.cortinas.assign([cena.find_child("CortinaO", true, false), cena.find_child("CortinaL", true, false)])
	v.aparelho = cena.find_child("TelefoneParede", true, false) as Node3D
	cena.set("vigilia", v)


## Dia 5 (cap. IV): agosto. A carta frenética, a oferta de ajuda, o telegrama
## "AKELY", o bilhete que o desmente e a renovação da oferta; a noite (o fogo, o
## sonho do AKELY) vem logo depois da farsa (playtest 8). As cartas
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
	# A renovação da oferta fecha o dia (playtest 8): depois dela, o diário, o fogo
	# e o sonho do AKELY, na mesma noite em que ele percebeu a farsa.
	var renovacao := _grupo_se(g, "Renovacao", _flag(&"narrou_cartao_aprofundava"))
	_escrever(renovacao, "renovacao_dia_5", &"comparou_assinatura")

	# Depois do bilhete, quem olhar para a janela vê algo passar lá fora, na
	# chuva, rente ao vidro: uma delas, em 3D (Fase 3e). Uma vez. Playtest 5 ("o
	# mi-go mais visível"): a uns dois metros da janela (mais perto, a asa entrava
	# na parede) e maior. Playtest 6 ("passou devagar, ficou claro demais"): sobe
	# na vertical, de baixo do peitoril até sumir no alto, num segundo.
	var sombra := Aparicao.new()
	sombra.name = "Sombra"
	sombra.position = Vector3(-0.2, -1.6, -D - 2.0)
	sombra.deslocamento = Vector3(0.5, 6.2, -0.3)
	sombra.duracao = 1.1
	sombra.atraso = 0.3
	sombra.distancia = 9.0
	sombra.condition = _flag(&"leu_bilhete_akeley_agosto")
	sombra.flag = &"viu_sombra_janela"
	sombra.exposure = 0.03
	_add(g, sombra)
	var vulto := Migo.new()
	vulto.name = "Vulto"
	# Subindo: o corpo de pé, as asas abertas para os lados.
	vulto.rotation_degrees = Vector3(-72, -95, 8)
	vulto.scale = Vector3.ONE * 1.4
	vulto.batida = 0.26
	_add(sombra, vulto)
	# Um clarão frio e curto que viaja com ela (a luz da rua na chuva): sem ele,
	# o corpo some no escuro. Fica do lado de fora, quase sem alcançar a sala.
	var clarao := _omni(sombra, "Clarao", Vector3(0.2, 1.3, -0.4), Color(0.7, 0.75, 0.9), 0.7, 1.7)
	clarao.omni_attenuation = 1.6


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
	# As cartas da noite, de volta de Boston (a ligação de Keene marca a flag uns
	# segundos antes da troca de fase: dava para começar a escrever e ir a Boston
	# com a carta aberta — o macaco, sessão de tester).
	_escrever(g, "resposta_dia_4", &"voltou_de_boston")

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
func _telefone(parent: Node, ids: Array = ["agencia_arkham", "boston", "telegrama_noturno", "relato_keene", "resposta_telegrama", "vigilia_linha"], nome := "Telefone") -> Telefone:
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
	# Saem do pacote uma a uma (playtest 5: "abrir o pacote e tirar as coisas").
	_retirada(bilhete.get_parent(), &"dia_3", 1, 99)
	_retirada(transcricao.get_parent(), &"dia_3", 2, 99)

	# O pacote do expresso não passa na fresta: fica no chão junto à porta. Na
	# mesa, cortado o barbante, tiram-se o bilhete, a transcrição e o estojo do
	# cilindro, um de cada vez.
	var pacote := _group(g, "Pacote", Vector3(-0.45, 0, 2.45), 10)
	var tam := Vector3(0.24, 0.1, 0.16)
	# Uma caixa de papelão aberta em cima, com as duas abas da tampa (playtest 6:
	# "abra o pacote antes de tirar as coisas"): cortado o barbante, as abas se
	# abrem, e o que veio se vê lá dentro até sair.
	var e := 0.006
	_box(pacote, "Fundo", Vector3(tam.x, e, tam.z), Vector3(0, e / 2, 0), "papel_pardo")
	for sx in [-1, 1]:
		_box(pacote, "Lado%d" % (sx + 1), Vector3(e, tam.y, tam.z), Vector3(sx * (tam.x - e) / 2, tam.y / 2, 0), "papel_pardo")
		_box(pacote, "Frente%d" % (sx + 1), Vector3(tam.x, tam.y, e), Vector3(0, tam.y / 2, sx * (tam.z - e) / 2), "papel_pardo")
	var abas: Array[Node3D] = []
	for sz in [1, -1]:
		var aba := _group(pacote, "Aba%d" % (sz + 1), Vector3(0, tam.y, sz * tam.z / 2))
		_box(aba, "Papelao", Vector3(tam.x, e, tam.z / 2), Vector3(0, e / 2, -sz * tam.z / 4), "papel_pardo")
		aba.set_meta(&"aberta", Vector3(sz * 112.0, 0, 0))
		abas.append(aba)
	# Lá dentro: as duas folhas dobradas e o estojo, cada um até ser tirado.
	var dentro := [["DentroBilhete", 1, Vector3(-0.055, 0.032, 0.0)], ["DentroTranscricao", 2, Vector3(-0.055, 0.024, 0.0)]]
	for d: Array in dentro:
		var folha := _box(pacote, d[0], Vector3(0.11, 0.006, 0.14), d[2], "papel")
		var cn := ConditionalNode.new()
		cn.name = "AteTirar"
		cn.condition = _composta(CompositeCondition.Mode.TODAS, [_aberto(&"dia_3"),
			_cond_valor(&"correio_dia_3_tiradas", ValueCondition.Op.MENOR, d[1])])
		_add(folha, cn)
	var tubo_dentro := _estojo_cilindro(pacote, "DentroEstojo")
	tubo_dentro.position = Vector3(0.06, 0.036, 0.0)
	tubo_dentro.rotation_degrees.x = 90
	var cn_tubo := ConditionalNode.new()
	cn_tubo.name = "AteTirar"
	cn_tubo.condition = _composta(CompositeCondition.Mode.TODAS, [_aberto(&"dia_3"),
		_cond_valor(&"correio_dia_3_tiradas", ValueCondition.Op.MENOR, 3)])
	_add(tubo_dentro, cn_tubo)
	var barbante := _barbante(pacote, tam + Vector3(0, e, 0), -20)
	# A etiqueta do expresso colada numa aba, fora do caminho do barbante.
	_quad(abas[0], "Etiqueta", Vector2(0.1, 0.06), Vector3(-0.065, e + 0.001, -0.04), Vector3(-90, 0, 0), "envelope")
	var pac := _area(pacote, Correspondencia.new(), "Correio", Vector3(0.28, 0.14, 0.2), Vector3(0, 0.05, 0)) as Correspondencia
	pac.id = &"dia_3"
	# Na ponta leste da mesa: no lugar antigo (oeste) tampava as fotografias.
	pac.mesa = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(-8), 0)), Vector3(0.64, MESA, -2.12))
	pac.prompt_pegar = "Pegar o pacote"
	pac.prompt_abrir = "Abrir o pacote"
	pac.prompt_examinar = "Examinar o pacote"
	pac.title = "O pacote do expresso"
	pac.description = "American Railway Express, despachado de Brattleboro: Akeley não confiava no ramal ao norte de lá."
	pac.initial_rotation = Vector3(25, 20, 0)
	pac.fechado = barbante
	pac.abas = abas
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
	etiqueta.position = Vector3(-0.065, e + 0.0015, -0.04)
	etiqueta.rotation_degrees.x = -90
	etiqueta.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_add(abas[0], etiqueta)
	# A última peça a sair do pacote; vai para a máquina com o cilindro.
	var estojo := _grupo_se(g, "Estojo", _composta(CompositeCondition.Mode.TODAS,
		[_cond_valor(&"correio_dia_3_tiradas", ValueCondition.Op.MAIOR_OU_IGUAL, 3), _flag(&"fono_cilindro", true)]))
	estojo.position = Vector3(-0.15, MESA + 0.03, -2.34)
	var tubo := _estojo_cilindro(estojo, "Tubo", "May 1, 1915")
	tubo.rotation_degrees.z = 90
	var ex_estojo := _examinavel(tubo, Vector3(0.07, 0.13, 0.07), "Examinar o estojo", "O cilindro de cera",
		"Um cilindro de cera escura, gravado com ditafone, no estojo de papelão. Na tampa, a letra apertada de Akeley: “1º de maio de 1915.”")
	ex_estojo.initial_rotation = Vector3(0, 0, -60)
	pac.retirar = [bilhete.get_parent() as Node3D, transcricao.get_parent() as Node3D, estojo]
	pac.prompts_retirar = PackedStringArray(["Tirar o bilhete", "Tirar a transcrição", "Tirar o estojo do cilindro"])
	pac.saida_altura = tam.y + 0.02

	_escrever(g, "resposta_dia_3", &"tocou_disco")
	return g


## O estojo de um cilindro de ditafone (playtest 8: "melhorar o modelo 3D do
## estojo" — era um cilindro liso de papel): o tubo de papelão pardo, a tampa de
## papelão envernizado com a borda, o fundo, duas cintas escuras e a etiqueta
## impressa que dá a volta (DICTAPHONE / WAX CYLINDER RECORD, em inglês como tudo
## o que é impresso). Com `mao`, um disco de papel na tampa com a letra de Akeley.
## Ao longo do Y local, centrado na origem (11,5 cm).
func _estojo_cilindro(pai: Node3D, nome: String, mao := "") -> Node3D:
	var e := _group(pai, nome)
	var r := 0.031
	_cyl(e, "Corpo", r, r, 0.09, Vector3(0, -0.006, 0), "papel_pardo", 16)
	_cyl(e, "Tampa", r + 0.0025, r + 0.0025, 0.03, Vector3(0, 0.0425, 0), "papelao_escuro", 16)
	_cyl(e, "BordaTampa", r + 0.0035, r + 0.0035, 0.004, Vector3(0, 0.028, 0), "papelao_escuro", 16)
	_cyl(e, "Fundo", r + 0.0012, r + 0.0012, 0.008, Vector3(0, -0.0535, 0), "papelao_escuro", 16)
	_cyl(e, "Etiqueta", r + 0.0006, r + 0.0006, 0.042, Vector3(0, -0.012, 0), "envelope", 16)
	for y in [-0.034, 0.01]:
		_cyl(e, "Cinta%d" % int(y * 1000), r + 0.0009, r + 0.0009, 0.003, Vector3(0, y, 0), "papelao_escuro", 16)
	# O impresso da etiqueta corre ao longo do tubo, virado para fora (+Z).
	var marca := _letreiro(e, "Marca", "DICTAPHONE", Vector3(0, -0.012, r + 0.0012), 0.00011, Color(0.38, 0.08, 0.06))
	marca.rotation_degrees.z = 90
	var linha := _letreiro(e, "Linha", "WAX CYLINDER RECORD\nTHE DICTAPHONE CORP. · N. Y.", Vector3(0, -0.012, r + 0.0012), 0.000045, Color(0.16, 0.12, 0.1))
	linha.rotation_degrees.z = 90
	linha.position.x = -0.011
	marca.position.x = 0.006
	for l: Label3D in [marca, linha]:
		l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		l.double_sided = false
	if mao:
		_cyl(e, "Disco", r - 0.004, r - 0.004, 0.0012, Vector3(0, 0.058, 0), "papel", 16)
		var letra := _letreiro(e, "Letra", mao, Vector3(0, 0.0592, 0), 0.00009, Color(0.12, 0.09, 0.14))
		letra.rotation_degrees.x = -90
		letra.font = load("res://art/fonts/Tangerine-Regular.ttf")
		letra.font_size = 64
		letra.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	return e


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
	# O jornal amassado sob as toras, onde o fósforo encosta (playtest 7).
	for k in 4:
		var bola := _box(lenha, "Jornal%d" % k, Vector3(0.07, 0.035, 0.06), Vector3(-0.07 + (k % 2) * 0.05, 0.005, -0.12 + k * 0.08), "papel")
		bola.rotation_degrees = Vector3(17.0 * k, 33.0 * k + 10.0, -12.0 * k)
	var chave := StringName("lareira_dia_%d" % n)
	var acender := _area(parent, AcenderLareira.new(), "AcenderLareira", Vector3(0.5, 0.8, 0.9), Vector3(W - 0.3, 0.45, -0.6)) as AcenderLareira
	acender.prompt = "Acender a lareira"
	acender.ajoelhar = Vector3(W - 1.0, 0, -0.6)
	acender.lenha = fogo_pos
	acender.chama = load(TEX_DIR + "chama.png")
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
	acender.fogo = fogo
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
	var n2: Node3D = noite.call(2)
	var n4: Node3D = noite.call(4)
	var n5: Node3D = noite.call(5)
	_sonho_garras(n2)
	_sonho_disco(noite.call(3))
	_sonho_pedra(n4)
	_sonho_telefone(n5)
	# Playtest 6: a sala do sonho se estilhaça, como o Vazio de Dishonored — mais a
	# cada noite (Vazio).
	_vazio(n2, 0.55, [Vector3(-W, 2.4, 1.6), Vector3(0.6, H, 0.9)], 1.5, 7, 3, 2)
	_vazio(n4, 0.8, [Vector3(W, 2.2, 1.9), Vector3(-0.4, H, -0.4), Vector3(-W, 2.6, -1.4)], 1.6, 11, 5, 4)
	_vazio(n5, 1.0, [Vector3(W, 2.0, 1.6), Vector3(-W, 2.3, 0.4), Vector3(0.3, H, 1.2), Vector3(W, 2.6, -2.2)], 1.8, 14, 7, 5)
	var acordar: Dictionary[int, StringName] = {
		2: &"narrou_sonho_garra", 3: &"acordou_noite_3", 4: &"viu_pedra_sonho", 5: &"ligou_sonho_telefone",
	}
	cena.set("sonhos", acordar)


## As paredes leste e oeste e o teto do sonho se estilhaçam em volta das
## `brechas` (Vazio); livros e papéis boiam na sala.
func _vazio(g: Node3D, intensidade: float, brechas: Array, raio: float, livros: int, papeis: int, semente: int) -> void:
	var v := Vazio.new()
	v.name = "Vazio"
	v.paredes = PackedStringArray(["Estrutura/ParedeLeste", "Estrutura/ParedeOeste", "Estrutura/Teto"])
	v.brechas = PackedVector3Array(brechas)
	v.raio_brecha = raio
	v.intensidade = intensidade
	v.livros = livros
	v.papeis = papeis
	v.destrocos = 6 + roundi(intensidade * 8)
	v.semente = semente
	_add(g, v)


## Noite do Dia 2 (as fotografias): marcas de garra, de lama, da porta
## até a mesa onde ele dorme, subindo por ela até a janela, que dá para o
## círculo de pedras. Acorda ao seguir as marcas de volta até a porta, onde
## começam ("Chamei-a de pegada...").
func _sonho_garras(g: Node3D) -> void:
	_vista_3d(g, _vistas.circulo())
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
	# O caminho (playtest 5: mais marcas, frescas, úmidas): da porta ao pé da
	# mesa, em duas fileiras, como de muitas patas; depois o tampo e o peitoril.
	var de := Vector2(-1.0, 2.75)
	var ate := Vector2(-0.05, -1.75)
	var rumo := rad_to_deg(atan2(-(ate - de).x, -(ate - de).y))
	for k in 20:
		var lado := 1.0 if k % 2 else -1.0
		var p := de.lerp(ate, k / 19.0) + Vector2(lado * rng.randf_range(0.1, 0.17), rng.randf_range(-0.05, 0.05))
		_quad(g, "Pegada%d" % k, Vector2(0.36, 0.36), Vector3(p.x, 0.014 + k * 0.0002, p.y), Vector3(-90, rumo + rng.randf_range(-14, 14), 0), "pegada")
	for k in 4:
		var p := Vector3(-0.1 + (0.1 if k % 2 else -0.1), MESA + 0.004, -1.9 - k * 0.18)
		_quad(g, "PegadaMesa%d" % k, Vector2(0.22, 0.22), p, Vector3(-90, rng.randf_range(-20, 20), 0), "pegada")
	_quad(g, "PegadaPeitoril", Vector2(0.2, 0.2), Vector3(0.0, JANELA_Y.x + 0.035, -D + 0.02), Vector3(-90, 0, 0), "pegada")
	# E as que se formam enquanto ele sonha (Rastro): em volta da cadeira, uma
	# volta larga e outra mais fechada, chegando perto dele.
	var rastro := Rastro.new()
	rastro.name = "Rastro"
	rastro.som = load(SFX_DIR + "lama.wav")
	_add(g, rastro)
	var centro := Vector2(0.05, -1.4)
	var voltas: Array[Vector3] = []
	for k in 7:
		voltas.append(Vector3(lerpf(-115.0, 115.0, k / 6.0), 1.25, 1.0))
	for k in 6:
		voltas.append(Vector3(lerpf(100.0, -70.0, k / 5.0), lerpf(0.85, 0.5, k / 5.0), -1.0))
	for k in voltas.size():
		var v := voltas[k]
		var a := deg_to_rad(v.x)
		var p := centro + Vector2(sin(a), cos(a)) * v.y
		# De lado, seguindo a volta.
		var giro := v.x + (90.0 if v.z > 0.0 else -90.0)
		_quad(rastro, "Fresca%d" % k, Vector2(0.36, 0.36), Vector3(p.x, 0.016 + k * 0.0002, p.y), Vector3(-90, giro, 0), "pegada")
	var gatilho := NarrationTrigger.new()
	gatilho.line = load("res://narrative/narration/sonho_garra.tres")
	_area(g, gatilho, "NaPorta", Vector3(1.4, 2.0, 0.9), Vector3(-1.0, 1.0, 2.4))


## Noite do Dia 3 (Fase 3e: "que ele revivesse o que acontece dentro do disco,
## em sonho, de relance"): a sala some, e ele está onde o disco foi gravado — a 1
## da manhã de 1º de maio de 1915, junto à boca fechada de uma caverna, onde a
## encosta oeste da Dark Mountain sobe do pântano de Lee (cap. III). O
## fonógrafo de Akeley no toco, a lanterna dele no chão, e o disco tocando de onde
## parou na sala, com as legendas; vultos parados na névoa, junto da caverna, e
## uma das criaturas passando entre as árvores, para quem olhar. Acorda ao
## levantar a agulha (ou quando o disco acaba).
## Até onde o chão do bosque do disco fica inteiro (o resto se parte em ilhas).
const RAIO_BOSQUE := 6.0


func _sonho_disco(g: Node3D) -> void:
	var clareira := POLTRONA_POS + Vector3(-0.1, 0, -1.9)
	var boca := POLTRONA_POS + Vector3(0.9, 0, -7.2)
	var mat := load(MAT_DIR + "bosque.tres") as Material
	# O chão além de 9 m da clareira se parte em ilhas que boiam (playtest 7: o
	# Vazio também no sonho do disco).
	var bosque: Node3D = _vistas.bosque(mat, clareira, boca, RAIO_BOSQUE)
	_add(g, bosque)
	for filho in bosque.find_children("*", "", true, false):
		filho.owner = cena
	var v := Vazio.new()
	v.name = "Vazio"
	v.position = clareira
	v.soltos = cena.get_path_to(bosque.get_node(^"Ilhas"))
	v.centro_soltos = clareira
	v.raio_firme = RAIO_BOSQUE
	v.intensidade = 0.9
	v.abertura = 12.0
	v.livros = 5
	v.papeis = 9
	v.destrocos = 16
	v.materiais_destroco = PackedStringArray(["pedra_negra", "madeira_escura", "pedra_lareira", "tijolo"])
	v.distancia_destroco = Vector2(12.0, 20.0)
	v.semente = 3
	_add(g, v)
	# Lá embaixo, no vazio, uma claridade fria que bate por baixo das ilhas.
	var fundo := _omni(g, "LuzDoVazio", clareira + Vector3(0, -7.0, 0), Color(0.4, 0.6, 0.55), 1.6, 26.0)
	fundo.omni_attenuation = 0.8
	# O chão (o que ficou: uma faixa por fileira de ladrilhos), os troncos, a
	# encosta; e, na borda do chão, paredes invisíveis (o escuro em volta não se
	# pisa).
	var chao: PackedVector2Array = bosque.get_meta(&"chao")
	var tem := {}
	for c in chao:
		tem[Vector2i(roundi(c.x), roundi(c.y))] = true
	var formas := []
	var fileiras := {}
	for c: Vector2i in tem:
		fileiras.get_or_add(c.y, []).append(c.x)
	for z: int in fileiras:
		var xs: Array = fileiras[z]
		xs.sort()
		var ini: int = xs[0]
		for i in xs.size():
			var fim: bool = i == xs.size() - 1 or xs[i + 1] != xs[i] + 1
			if fim:
				var w: int = xs[i] + 1 - ini
				formas.append([Vector3(w, 0.2, 1.0), Vector3(ini + w * 0.5, -0.1, z + 0.5)])
				if i < xs.size() - 1:
					ini = xs[i + 1]
	for c: Vector2i in tem:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if tem.has(c + d):
				continue
			var meio := Vector3(c.x + 0.5 + d.x * 0.5, 2.0, c.y + 0.5 + d.y * 0.5)
			formas.append([Vector3(0.2 if d.x != 0 else 1.2, 4.0, 1.2 if d.x != 0 else 0.2), meio])
	for p: Vector3 in bosque.get_meta(&"troncos"):
		formas.append([Vector3(0.3, 3.0, 0.3), p + Vector3(0, 1.5, 0)])
	formas.append([Vector3(12, 6, 1.0), boca + Vector3(0, 3, -0.6)])
	_colisao(g, "Colisao", formas)

	# O toco com o fonógrafo de Akeley (o ditafone que gravou), virado para ele.
	var toco_pos := clareira + Vector3(0.5, 0, -0.6)
	_cyl(g, "Toco", 0.28, 0.33, 0.55, toco_pos + Vector3(0, 0.275, 0), "madeira_escura", 9)
	var f := _group(g, "Fonografo", toco_pos + Vector3(0, 0.55, 0), 200)
	_box(f, "Caixa", Vector3(0.34, 0.14, 0.24), Vector3(0, 0.07, 0), "madeira_clara")
	var cera := _cyl(f, "Cera", 0.032, 0.032, 0.11, Vector3(0, 0.19, 0.02), "cinzas", 10)
	cera.rotation_degrees.z = 90
	var cone := _cyl(f, "Corneta", 0.2, 0.015, 0.5, Vector3(0.0, 0.42, -0.18), "latao", 10)
	cone.rotation_degrees = Vector3(-60, 0, 0)
	var fono := _area(f, Fonografo.new(), "Disco", Vector3(0.5, 0.6, 0.5), Vector3(0, 0.2, 0)) as Fonografo
	fono.gravacao = load("res://narrative/gravacoes/disco_1915.tres")
	fono.gravacao_longa = load("res://narrative/gravacoes/disco_1915_longo.tres")
	fono.exposicao_repeticao = 0.0
	fono.flag_ao_parar = &"acordou_noite_3"
	# Na voz zumbida, a voz vem de trás dele, e a vista se desdobra (Fase 3f).
	fono.voz_por_tras = true
	fono.visao_dupla = 0.8

	# A lanterna de Akeley no chão, junto do toco: a única luz quente. Anda
	# sozinha (Espreita): cada vez que ele não olha, está noutro lugar — em volta
	# dele, e depois rumo à caverna, até os vultos.
	var lanterna := Espreita.new()
	lanterna.name = "Lanterna"
	lanterna.position = toco_pos + Vector3(-0.45, 0, 0.25)
	lanterna.pontos = PackedVector3Array([
		clareira + Vector3(1.6, 0, 1.2), clareira + Vector3(-0.4, 0, 2.0), clareira + Vector3(-1.8, 0, 0.5),
		clareira + Vector3(-1.5, 0, -1.5), clareira.lerp(boca, 0.55) + Vector3(-0.6, 0, 0), boca + Vector3(0.3, 0, 2.1)])
	lanterna.intervalo = 4.0
	lanterna.espera = 10.0
	lanterna.altura = 0.2
	lanterna.angulo_visto = 50.0
	_add(g, lanterna)
	_cyl(lanterna, "Base", 0.06, 0.065, 0.04, Vector3(0, 0.02, 0), "ferro", 8)
	_cyl(lanterna, "Vidro", 0.045, 0.045, 0.12, Vector3(0, 0.1, 0), "vidro_aceso", 8)
	_cyl(lanterna, "Tampa", 0.03, 0.06, 0.04, Vector3(0, 0.18, 0), "ferro", 8)
	var chama := _omni(lanterna, "Luz", Vector3(0, 0.25, 0), Color(1.0, 0.7, 0.4), 1.6, 6.0)
	chama.shadow_enabled = true
	chama.omni_attenuation = 1.3
	# A lua, fria e alta, por entre as copas.
	_omni(g, "Lua", clareira + Vector3(-2.0, 7.0, -3.0), Color(0.45, 0.52, 0.75), 0.9, 14.0)

	# De relance: uma delas, atravessando entre as árvores, acima da caverna.
	# Playtest 8 ("não sei se o mi-go no sonho não está muito expositivo"): no
	# livro, Wilmarth nunca vê uma delas viva — só a sugestão. Agora longe, no
	# alto da encosta, atrás da boca da caverna e na névoa, só a silhueta escura
	# com as asas batendo, e depressa; a vista clara fica para a janela, no Dia 5.
	var passa := Aparicao.new()
	passa.name = "Criatura"
	passa.position = boca + Vector3(-5.5, 4.2, -3.5)
	passa.deslocamento = Vector3(11.0, 1.6, -1.0)
	passa.duracao = 1.7
	passa.atraso = 1.0
	passa.angulo = 24.0
	passa.distancia = 18.0
	passa.flag = &"viu_criatura_disco"
	passa.exposure = 0.03
	_add(g, passa)
	var migo := Migo.new()
	migo.name = "Migo"
	migo.silhueta = true
	migo.batida = 0.4
	migo.rotation_degrees = Vector3(0, -90, -8)
	_add(passa, migo)

	_loucura_do_disco(g, mat, bosque, clareira)


## O sonho do disco enlouquece (Fase 3f, item 19): os vultos diante da caverna,
## de costas para ele, viram o rosto pálido para ele quando ninguém olha; e
## pedaços do escritório aparecem entre as árvores, um de cada vez, sempre fora
## da vista — a porta com a luz do corredor por baixo, o abajur verde aceso no
## chão, a cadeira dele virada para a caverna, um pedaço da estante encostado
## numa árvore. (As árvores perto da clareira respiram: Respira, nas vistas.)
func _loucura_do_disco(g: Node3D, mat: Material, bosque: Node3D, clareira: Vector3) -> void:
	var vultos: PackedVector3Array = bosque.get_meta(&"vultos")
	for k in vultos.size():
		var v := Espreita.new()
		v.name = "Vulto%d" % k
		v.position = vultos[k]
		# De costas para ele, olhando a caverna.
		v.rotation.y = PI
		v.virar = true
		v.intervalo = 2.4 + k * 1.1
		v.espera = 6.0 + k * 2.0
		v.altura = 1.55
		_add(g, v)
		_add(v, _vistas.vulto(mat))

	# A porta do escritório, de pé sozinha entre as árvores, fechada, com a luz
	# do corredor por baixo.
	var porta := _pedaco(g, "PedacoPorta", clareira + Vector3(-5.0, 0, 0.9), 90, 14.0)
	_box(porta, "Folha", Vector3(PORTA_L, PORTA_H, 0.05), Vector3(0, PORTA_H / 2, 0), "madeira_escura")
	_quad(porta, "Frente", Vector2(PORTA_L, PORTA_H), Vector3(0, PORTA_H / 2, -0.026), Vector3(0, 180, 0), "porta")
	_quad(porta, "Costas", Vector2(PORTA_L, PORTA_H), Vector3(0, PORTA_H / 2, 0.026), Vector3.ZERO, "porta")
	for s in [-1, 1]:
		_box(porta, "Batente%d" % (s + 1), Vector3(0.08, PORTA_H + 0.08, 0.1), Vector3(s * (PORTA_L / 2 + 0.04), (PORTA_H + 0.08) / 2, 0), "madeira_clara")
	_box(porta, "Verga", Vector3(PORTA_L + 0.16, 0.08, 0.1), Vector3(0, PORTA_H + 0.04, 0), "madeira_clara")
	_box(porta, "Macaneta", Vector3(0.05, 0.05, 0.06), Vector3(0.36, 1.0, -0.06), "latao")
	_quad(porta, "Fresta", Vector2(PORTA_L - 0.04, 0.012), Vector3(0, 0.006, -0.03), Vector3(0, 180, 0), "vidro_aceso")
	var corredor := _omni(porta, "LuzCorredor", Vector3(0, 0.08, -0.25), Color(1.0, 0.8, 0.55), 0.6, 1.6)
	corredor.omni_attenuation = 1.6

	# O abajur verde da escrivaninha, aceso, no chão do bosque.
	var abajur := _pedaco(g, "PedacoAbajur", clareira + Vector3(3.6, 0, 2.4), -35, 22.0)
	_cyl(abajur, "Base", 0.08, 0.09, 0.03, Vector3(0, 0.015, 0), "latao", 10)
	_cyl(abajur, "Haste", 0.01, 0.01, 0.34, Vector3(0, 0.2, 0), "latao", 6)
	var cupula := _box(abajur, "Cupula", Vector3(0.36, 0.06, 0.16), Vector3(0, 0.38, -0.04), "esmalte_verde")
	cupula.rotation_degrees.x = -8
	var luz := _omni(abajur, "Luz", Vector3(0, 0.3, -0.06), Color(1.0, 0.82, 0.55), 0.9, 2.6)
	luz.omni_attenuation = 1.4

	# A cadeira dele, virada para a caverna, no caminho.
	var cadeira := _pedaco(g, "PedacoCadeira", clareira + Vector3(1.4, 0, -4.4), 180, 30.0)
	_box(cadeira, "Assento", Vector3(0.44, 0.04, 0.42), Vector3(0, 0.46, 0), "madeira_clara")
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_box(cadeira, "Perna%d%d" % [sx + 1, sz + 1], Vector3(0.035, 0.46, 0.035), Vector3(sx * 0.19, 0.23, sz * 0.18), "madeira_clara")
	for k in 4:
		_box(cadeira, "Ripa%d" % k, Vector3(0.03, 0.42, 0.02), Vector3(-0.13 + k * 0.087, 0.7, 0.2), "madeira_clara")
	_box(cadeira, "Encosto", Vector3(0.44, 0.06, 0.03), Vector3(0, 0.93, 0.2), "madeira_clara")

	# Um pedaço da estante, com livros, encostado numa árvore.
	var estante := _pedaco(g, "PedacoEstante", clareira + Vector3(-3.4, 0, -3.2), 30, 38.0)
	estante.rotation_degrees.x = -9
	for s in [-1, 1]:
		_box(estante, "Lado%d" % (s + 1), Vector3(0.03, 1.3, 0.3), Vector3(s * 0.45, 0.65, 0), "madeira_escura")
	var livros := []
	for p in 3:
		_box(estante, "Prateleira%d" % p, Vector3(0.9, 0.025, 0.3), Vector3(0, 0.05 + p * 0.42, 0), "madeira_escura")
		if p == 2:
			break
		var x := -0.42
		var rng := RandomNumberGenerator.new()
		rng.seed = 300 + p
		while x < 0.38:
			var larg := rng.randf_range(0.03, 0.06)
			var alto := rng.randf_range(0.24, 0.33)
			livros.append([Vector3(larg, alto, 0.22), Vector3(x + larg / 2, 0.0625 + p * 0.42 + alto / 2, 0.02), Vector3.ZERO, CORES_LIVRO[rng.randi() % CORES_LIVRO.size()]])
			x += larg + 0.004
	_lote(estante, "Livros", livros, "capa_livro")


## Um pedaço do escritório que aparece no sonho do disco fora da vista (Espreita).
func _pedaco(g: Node3D, nome: String, pos: Vector3, rot_y: float, espera: float) -> Espreita:
	var e := Espreita.new()
	e.name = nome
	e.position = pos
	e.rotation_degrees.y = rot_y
	e.aparecer = true
	e.espera = espera
	e.intervalo = 1.5
	e.altura = 0.8
	_add(g, e)
	return e


## Noite do Dia 4 (a pedra que não chega): a pedra negra está na mesa; pela
## janela, a plataforma de Keene à noite e um homem magro de costas, e a voz
## zumbida. Acorda depois de examinar a pedra (o sono pesa).
func _sonho_pedra(g: Node3D) -> void:
	_vista_3d(g, _vistas.plataforma())
	_omni(g, "Janela", Vector3(0.3, 1.8, -2.6), Color(0.85, 0.75, 0.55), 0.6, 4.0)
	var pedra := _group(g, "Pedra", Vector3(-0.05, MESA, -2.3), 8)
	_monolito(pedra, "Bloco", Vector3(0.34, 0.56, 0.22), 7)
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


## A pedra negra de Round Hill (playtest 6: eram duas caixas; playtest 8: "o
## modelo está quebrado" — os anéis torcidos dobravam as faces umas sobre as
## outras, e as normais suaves espalhavam a textura como pano). Agora uma estela
## como a da gravura do menu: uma laje de faces planas, mais larga embaixo, os
## lados um pouco tortos, o alto **partido** em dentes, e as arestas chanfradas
## (a face da frente e a de trás recuadas `chanfro`), cada face com a própria
## normal. `tam` = largura, altura, espessura; a base no chão (y 0).
func _monolito(pai: Node3D, nome: String, tam: Vector3, semente: int) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var w := tam.x
	var h := tam.y
	# O contorno visto de frente, no sentido anti-horário: a base, o lado
	# direito, o alto partido (da direita para a esquerda), o lado esquerdo.
	var contorno := PackedVector2Array([
		Vector2(-0.5, 0.0), Vector2(0.5, 0.0),
		Vector2(0.49, 0.3), Vector2(0.46, 0.58), Vector2(0.44, 0.7),
		Vector2(0.3, 0.76), Vector2(0.2, 0.71), Vector2(0.08, 0.86),
		Vector2(-0.06, 0.82), Vector2(-0.2, 0.97), Vector2(-0.33, 0.93),
		Vector2(-0.43, 0.88), Vector2(-0.46, 0.6), Vector2(-0.48, 0.3),
	])
	for i in contorno.size():
		var q := contorno[i]
		var j := Vector2(rng.randf_range(-0.012, 0.012), rng.randf_range(-0.012, 0.012) if q.y > 0.0 else 0.0)
		contorno[i] = Vector2((q.x + j.x) * w, (q.y + j.y) * h)
	# A face recuada: o contorno encolhido para o meio (o chanfro); o alto
	# partido não tem chanfro (a quebra é viva).
	var chanfro := minf(w, tam.z) * 0.12
	var centro := Vector2(0.0, h * 0.45)
	var dentro := PackedVector2Array()
	for q in contorno:
		var d := centro - q
		var k := 0.4 if q.y > h * 0.69 else 1.0
		dentro.append(q + d.normalized() * chanfro * k if q.y > 0.0 else Vector2(q.x * (1.0 - chanfro / w), 0.0))
	var meia := tam.z * 0.5
	var raso := meia - chanfro * 0.6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var tri := func(a: Vector3, b: Vector3, c: Vector3) -> void:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	var quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		tri.call(a, b, c)
		tri.call(a, c, d)
	# A frente e as costas (a face recuada, triangulada).
	var ind := Geometry2D.triangulate_polygon(dentro)
	for t in range(0, ind.size(), 3):
		var a := dentro[ind[t]]
		var b := dentro[ind[t + 1]]
		var c := dentro[ind[t + 2]]
		tri.call(Vector3(a.x, a.y, meia), Vector3(c.x, c.y, meia), Vector3(b.x, b.y, meia))
		tri.call(Vector3(a.x, a.y, -meia), Vector3(b.x, b.y, -meia), Vector3(c.x, c.y, -meia))
	var n := contorno.size()
	for i in n:
		var j := (i + 1) % n
		var o0 := contorno[i]
		var o1 := contorno[j]
		var d0 := dentro[i]
		var d1 := dentro[j]
		# O chanfro da frente e o de trás.
		quad.call(Vector3(d0.x, d0.y, meia), Vector3(d1.x, d1.y, meia), Vector3(o1.x, o1.y, raso), Vector3(o0.x, o0.y, raso))
		quad.call(Vector3(o0.x, o0.y, -raso), Vector3(o1.x, o1.y, -raso), Vector3(d1.x, d1.y, -meia), Vector3(d0.x, d0.y, -meia))
		# O lado (a borda), de um chanfro ao outro.
		quad.call(Vector3(o0.x, o0.y, raso), Vector3(o1.x, o1.y, raso), Vector3(o1.x, o1.y, -raso), Vector3(o0.x, o0.y, -raso))
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = mesh
	mi.material_override = m["pedra_negra"]
	_add(pai, mi)
	return mi


## Noite do Dia 5 (o telegrama AKELY): chove dentro da sala; o telefone toca.
## Atendido, só um zumbido na linha, soletrando. Acorda ao desligar.
func _sonho_telefone(g: Node3D) -> void:
	_vista(g, "chuva", "vista_noite")
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


## Uma das criaturas cruzando o céu da cidade, à noite: em 3D (Fase 3e), uma
## silhueta escura de asas batendo, por cima dos olmos do campus, uma vez, sem som
## — só para quem estiver olhando (Aparicao). Nada confirma o que foi visto.
func _criatura_no_ceu(parent: Node, cond: Condition, flag: StringName) -> void:
	var passa := Aparicao.new()
	passa.name = "Criatura"
	passa.position = Vector3(-9.0, 4.0, -18.0)
	passa.deslocamento = Vector3(18.0, 2.5, -4.0)
	passa.duracao = 3.0
	passa.atraso = 0.6
	passa.angulo = 20.0
	passa.distancia = 30.0
	passa.condition = cond
	passa.flag = flag
	passa.exposure = 0.03
	_add(parent, passa)
	var migo := Migo.new()
	migo.name = "Silhueta"
	migo.silhueta = true
	migo.batida = 0.4
	migo.rotation_degrees = Vector3(0, -100, -6)
	_add(passa, migo)


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


## A máquina comercial emprestada da administração (cap. III: "a commercial
## machine"), que chega montada no Dia 3 — só falta o cilindro de Akeley. Um
## fonógrafo de cilindro (o disco é um cilindro de cera) na sua própria mesinha,
## junto à parede oeste, entre a estante e o quadro, onde chega a luz da janela
## (playtest 5: "um lugar digno"): a caixa de carvalho com a placa preta, o
## mecanismo à vista (o mandril, a rosca do carro, o diafragma de latão), a
## manivela do lado, e a corneta grande de latão presa ao guindaste, a boca
## virada para a sala. Na prateleira de baixo, estojos de cilindros.
func _fonografo(parent: Node, dia3: Node3D) -> void:
	var g := _grupo_se(parent, "MaquinaFonografo", _cond_valor(&"dia", ValueCondition.Op.MAIOR_OU_IGUAL, 3))
	g.position = Vector3(-W + 0.33, 0, -0.75)
	# A frente (-Z local) para leste, para a sala; +X local é o sul.
	g.rotation_degrees.y = -90
	# A mesinha: tampo, saia, pernas torneadas e a prateleira de baixo.
	var alto := 0.7
	_box(g, "Tampo", Vector3(0.52, 0.03, 0.42), Vector3(0, alto - 0.015, 0), "madeira_escura")
	_box(g, "Saia", Vector3(0.46, 0.07, 0.36), Vector3(0, alto - 0.065, 0), "madeira_escura")
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_cyl(g, "Perna%d%d" % [sx + 1, sz + 1], 0.02, 0.016, alto - 0.03, Vector3(sx * 0.22, (alto - 0.03) / 2, sz * 0.17), "madeira_escura", 6)
	_box(g, "Prateleira", Vector3(0.46, 0.02, 0.36), Vector3(0, 0.18, 0), "madeira_escura")
	for k in 4:
		var est := _estojo_cilindro(g, "Estojo%d" % k)
		est.position = Vector3(-0.15 + k * 0.075, 0.248, 0.04 - (k % 2) * 0.05)
		est.rotation_degrees.y = -150.0 + k * 47.0
	# A caixa de carvalho, com o rodapé, e a placa preta em cima.
	var caixa_h := 0.15
	var topo := alto + caixa_h
	_box(g, "Caixa", Vector3(0.36, caixa_h, 0.24), Vector3(0, alto + caixa_h / 2, 0), "madeira_clara")
	_box(g, "Rodape", Vector3(0.38, 0.02, 0.26), Vector3(0, alto + 0.01, 0), "madeira_clara")
	_box(g, "Placa", Vector3(0.34, 0.008, 0.22), Vector3(0, topo + 0.004, 0), "esmalte_preto")
	# O mecanismo: os mancais, o mandril, a rosca do carro e o diafragma.
	var eixo_y := topo + 0.06
	for s in [-1, 1]:
		_box(g, "Mancal%d" % (s + 1), Vector3(0.016, 0.07, 0.03), Vector3(s * 0.12, topo + 0.035, -0.04), "ferro")
	var mandril := _cyl(g, "Mandril", 0.026, 0.026, 0.2, Vector3(0, eixo_y, -0.04), "ferro", 12)
	mandril.rotation_degrees.z = 90
	var rosca := _cyl(g, "Rosca", 0.006, 0.006, 0.26, Vector3(0, topo + 0.085, 0.035), "aco", 6)
	rosca.rotation_degrees.z = 90
	_box(g, "Carro", Vector3(0.03, 0.025, 0.08), Vector3(-0.05, topo + 0.09, 0.0), "ferro")
	var boca := Vector3(-0.05, eixo_y + 0.06, -0.04)
	_cyl(g, "Diafragma", 0.03, 0.03, 0.014, boca + Vector3(0, -0.012, 0), "latao", 12)
	var cilindro := _grupo_se(g, "Cilindro", _flag(&"fono_cilindro"))
	var cera := _cyl(cilindro, "Cera", 0.031, 0.031, 0.11, Vector3(-0.02, eixo_y, -0.04), "cinzas", 12)
	cera.rotation_degrees.z = 90
	# A manivela, do lado direito da caixa.
	var manivela := _group(g, "Manivela", Vector3(-0.185, alto + 0.08, 0.0))
	_cyl(manivela, "Eixo", 0.008, 0.008, 0.03, Vector3(-0.015, 0, 0), "ferro", 6).rotation_degrees.z = 90
	_box(manivela, "Braco", Vector3(0.01, 0.1, 0.014), Vector3(-0.032, -0.04, 0), "ferro")
	_cyl(manivela, "Punho", 0.011, 0.011, 0.045, Vector3(-0.055, -0.085, 0), "madeira_escura", 6).rotation_degrees.z = 90
	# A corneta, do diafragma para cima e para a sala, em três trechos que se
	# abrem; a boca com o aro. Oca: a parede de dentro é a face virada para o eixo.
	var rumo := Vector3(0.55, 0.62, -0.42).normalized()
	var corneta := _group(g, "Corneta", boca)
	corneta.basis = Basis(Quaternion(Vector3.UP, rumo))
	var trechos := [[0.012, 0.03, 0.26], [0.03, 0.075, 0.22], [0.075, 0.2, 0.16]]
	var y := 0.0
	for k in trechos.size():
		var t: Array = trechos[k]
		for dentro in [false, true]:
			var mi := _cyl(corneta, "Trecho%d%s" % [k, "Dentro" if dentro else ""], t[1] - (0.003 if dentro else 0.0),
				t[0] - (0.002 if dentro else 0.0), t[2], Vector3(0, y + t[2] / 2, 0), "latao", 14)
			var malha := mi.mesh as CylinderMesh
			malha.cap_top = false
			malha.cap_bottom = false
			malha.flip_faces = dentro
		y += t[2]
	var aro := MeshInstance3D.new()
	aro.name = "Aro"
	var toro := TorusMesh.new()
	toro.inner_radius = 0.195
	toro.outer_radius = 0.212
	toro.rings = 16
	toro.ring_segments = 4
	aro.mesh = toro
	aro.material_override = m["latao"]
	aro.position = Vector3(0, y, 0)
	_add(corneta, aro)
	# O guindaste: a haste atrás da caixa, o braço e a corrente até a corneta.
	var meio_corneta := boca + rumo * 0.36
	var haste := Vector3(0.15, 0, 0.1)
	var haste_alto := meio_corneta.y + 0.24
	_cyl(g, "Haste", 0.007, 0.007, haste_alto - topo, Vector3(haste.x, (topo + haste_alto) / 2, haste.z), "ferro", 6)
	var braco := Vector3(meio_corneta.x, haste_alto, meio_corneta.z) - Vector3(haste.x, haste_alto, haste.z)
	var bg := _box(g, "BracoGuindaste", Vector3(0.012, 0.012, braco.length()), Vector3(haste.x, haste_alto, haste.z) + braco / 2, "ferro")
	bg.rotation.y = atan2(braco.x, braco.z)
	_box(g, "Corrente", Vector3(0.004, 0.17, 0.004), Vector3(meio_corneta.x, haste_alto - 0.085, meio_corneta.z), "ferro")
	_colisao(g, "Colisao", [[Vector3(0.52, topo, 0.42), Vector3(0, topo / 2, 0)]])

	var f := _area(g, Fonografo.new(), "Fonografo", Vector3(0.42, 0.3, 0.32), Vector3(0, topo + 0.05, 0)) as Fonografo
	f.unique_name_in_owner = true
	f.gravacao = load("res://narrative/gravacoes/disco_1915.tres")
	f.gravacao_longa = load("res://narrative/gravacoes/disco_1915_longo.tres")
	f.zumbido = load(SFX_DIR + "zumbido.wav")
	f.narracao_depois = load("res://narrative/narration/depois_do_disco.tres")
	f.luz = dia3.get_node("Abajur/Luz")
	# O cilindro está à mão quando o estojo sai do pacote (a última peça).
	f.cilindro_chegou = _cond_valor(&"correio_dia_3_tiradas", ValueCondition.Op.MAIOR_OU_IGUAL, 3)
	var tremem: Array[Node3D] = []
	for n in dia3.get_children():
		if n.has_meta(&"treme"):
			tremem.append(n)
	f.tremer = tremem

	# A noite do Dia 3: anotado o dia, ouvir o disco outra vez — ele baixa a
	# agulha e vai ouvi-lo da poltrona, olhando a lareira fria; o sono vem com o
	# disco (LugarSono). A área é maior que a do fonógrafo (ganha a mira) e só
	# existe nessa noite.
	var ouvir := _area(g, LugarSono.new(), "OuvirDeNovo", Vector3(0.56, 0.42, 0.46), Vector3(0, topo + 0.05, 0)) as LugarSono
	ouvir.noite = 3
	ouvir.prompt = "Ouvir o disco outra vez"
	ouvir.condition = _cond_valor(&"sono", ValueCondition.Op.IGUAL, 3)
	ouvir.assento = _assento_poltrona
	ouvir.diante = _marca(parent as Node3D, "DianteDisco", g.position + Vector3(0.62, 0, 0))
	ouvir.olhar = _marca(parent as Node3D, "OlharLareiraFria", Vector3(W - 0.25, 0.35, -0.6))
	ouvir.escutar = 14.0
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
	# Só depois de tirar as fotografias do envelope (playtest 5: dava para responder
	# com elas ainda dentro).
	var escrever := _escrever(g, "resposta_dia_2", &"leu_carta_akeley_2")
	escrever.condition = _composta(CompositeCondition.Mode.TODAS, [escrever.condition,
		_cond_valor(&"correio_dia_2_tiradas", ValueCondition.Op.MAIOR_OU_IGUAL, fotos.size())])


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
	# Sessão de tester 2: a carta e os envelopes passavam por baixo da base da
	# lâmpada. A carta fica por cima do rascunho; os envelopes, no fundo dela.
	_folha(op, "CartaLeitor", Vector3(0.4, MESA + 0.004, -2.43), 6, "carta_opositor", "Ler a carta do leitor", false)
	for i in 3:
		_envelope(op, "Opositor%d" % i, Vector3(0.38, MESA + 0.0105 + i * 0.0045, -2.52), -4 + i * 7, {
			remetente = "",
			destinatario = "Prof. A. N. Wilmarth\nMiskatonic University\nArkham, Mass.",
			carimbo_cidade = "ARKHAM",
			carimbo_data = "MAY %d\n1928" % (17 + i),
		})
	var deixar := _area(op, StateInteractable.new(), "DeixarSemResposta", Vector3(0.22, 0.06, 0.13), Vector3(0.38, MESA + 0.05, -2.525)) as StateInteractable
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
