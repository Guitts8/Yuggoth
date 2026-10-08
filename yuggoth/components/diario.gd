class_name Diario
extends Node3D
## O diário de Wilmarth (docs/PLANO_ESCRITORIO.md, "A passagem para o sonho"):
## um caderno fechado na escrivaninha. Postada a resposta do dia, a área filha
## `Anotar` ("Anotar o dia", com condição) chama o Escritorio, que chama
## `anotar()`: Wilmarth senta, o caderno vem para diante dele e abre — à
## esquerda a entrada anterior, à direita a do dia, que se escreve sozinha com
## a pena da mesa, ao som dela. Com `falhar` (noite de sonho), a última linha
## cai, a pena tomba e a tinta escorre; quem segue (o sono) é o Escritorio.
##
## Fora disso, a área `Ler` ("Ler o diário", Fase 3d) abre o caderno do mesmo
## jeito para folheá-lo (`ler()`): a folha de rosto e as entradas já escritas,
## de duas em duas; [A] [D] (ou as setas) viram a folha, [E]/[Esc] fecham.
##
## A origem do nó é a lombada: fechado, o caderno fica do lado +X dela; aberto,
## as duas páginas, uma de cada lado. Peças montadas em código (nomes com "_",
## fora do .tscn); o gerador põe só o nó, as áreas e a pena.

const LARGURA := 0.15
const FUNDO := 0.215
const MIOLO := 0.017
const TABUA := 0.003
## O par de páginas abertas é uma textura só (SubViewport), ~1 pixel da textura
## por pixel do mundo com a vista apertada sobre a página.
const TEXTURA := Vector2i(640, 448)
const MARGEM := Vector2(26.0, 30.0)
const FONTE := 21
const ENTRELINHA := 3
const LETRAS_POR_SEGUNDO := 20.0
const TINTA := Color(0.1, 0.08, 0.13)
const PAPEL := Color(0.88, 0.84, 0.73)
## A vista apertada, debruçado sobre a página.
const FOV_ESCREVENDO := 38.0
## A primeira página, antes de qualquer entrada.
const ROSTO := "\n\n\n[center]A. N. Wilmarth\n\nMiskatonic University\nArkham, 1928[/center]"
const VIRAR_SEGUNDOS := 0.65

@export var som_pena: AudioStream
@export var som_papel: AudioStream
## A pena da mesa: vem para a página enquanto ele escreve.
@export var pena: Node3D
## A lombada com o caderno aberto, diante da cadeira (no espaço do pai).
@export var lugar_aberto := Transform3D.IDENTITY
## Quanto a cadeira fica recuada do caderno aberto (para +Z dele).
@export var recuo_cadeira := 0.62

var aberto := false
## Folheando (`ler()`), até o jogador fechar.
var lendo := false

var _casa: Transform3D
var _pena_casa: Transform3D
var _anotar: Interactable
var _ler: Interactable
## Do primeiro passo de anotar/ler até voltar ao lugar: as áreas somem.
var _ocupado := false
## Folheando: as páginas (rosto + entradas) e a da esquerda no par aberto.
var _paginas: PackedStringArray = []
var _par := 0
var _virando := false
var _pode_virar := false
var _dica: CanvasLayer
## As duas páginas abertas (cada uma, metade da textura) e a folha que vira:
## `_mat_vivo` mostra o par atual; `_mat_foto`, uma foto do par anterior.
var _pag_esq: MeshInstance3D
var _pag_dir: MeshInstance3D
var _virada: Node3D
var _frente: MeshInstance3D
var _verso: MeshInstance3D
var _mat_vivo: ShaderMaterial
var _mat_foto: ShaderMaterial
var _fechado: Node3D
var _capa: Node3D
var _aberto: Node3D
var _vp: SubViewport
var _esquerda: RichTextLabel
var _direita: RichTextLabel
var _mancha: Mancha
var _pautas: Pautas
var _escrevendo := false
var _queda_desde := -1
var _pena_som: AudioStreamPlayer
var _t := 0.0
var _player: Player


func _ready() -> void:
	_casa = transform
	if pena:
		_pena_casa = pena.transform
	_anotar = get_node_or_null(^"Anotar") as Interactable
	_ler = get_node_or_null(^"Ler") as Interactable
	_montar()


func _exit_tree() -> void:
	if _dica:
		_dica.queue_free()
		_dica = null


func _process(delta: float) -> void:
	_t += delta
	# Indisponível, a área some e sai da física (não tampa o que estiver atrás
	# dela). Na hora de anotar o dia, só "Anotar"; fora dela, "Ler".
	var anotar_pode := _anotar != null and not _ocupado and _anotar.can_interact(null)
	_ligar_area(_anotar, anotar_pode)
	_ligar_area(_ler, not _ocupado and not anotar_pode)
	if _escrevendo and pena:
		var ponta := global_transform * _na_pagina(_ponta_px())
		# A pena sobe e desce um pouco, de letra em letra.
		ponta += Vector3.UP * absf(sin(_t * 23.0)) * 0.004
		pena.global_transform = _pena_em(ponta, Vector3(0.35, 0.85, 0.4))
	if _escrevendo and _player and not _player.desviou_o_olhar():
		_seguir_a_pena(delta)


## Escrevendo, os olhos vão atrás da pena, com atraso (a linha corre, ele a
## acompanha e volta ao começo da seguinte), e a cabeça respira um pouco —
## até o jogador mexer a cabeça (a câmera é dele, playtest 4).
func _seguir_a_pena(delta: float) -> void:
	var alvo := global_transform * _na_pagina(_ponta_px() + Vector2(-30.0, 6.0))
	var olho := _player.camera.global_position
	var yaw := atan2(-(alvo.x - olho.x), -(alvo.z - olho.z))
	var pitch := atan2(alvo.y - olho.y, Vector2(alvo.x - olho.x, alvo.z - olho.z).length())
	pitch += sin(_t * 1.3) * 0.006
	yaw += sin(_t * 0.7) * 0.004
	var k := 1.0 - exp(-1.8 * delta)
	_player.rotation.y += angle_difference(_player.rotation.y, yaw) * k
	_player.head.rotation.x = lerp_angle(_player.head.rotation.x, pitch, k)


## Wilmarth senta, o caderno vem para diante dele e abre; a entrada se escreve.
## Com `falhar`, a última linha cai e a tinta escorre: termina aberto, a pena
## tombada na página.
func anotar(entrada: DocumentData, anterior: DocumentData, player: Player, falhar: bool) -> void:
	_esquerda.text = anterior.resolve_pages()[0] if anterior else ROSTO
	_direita.text = entrada.resolve_pages()[0] if entrada else ""
	_direita.visible_characters = 0
	_mancha.raio = 0.0
	_mancha.escorrido = 0.0
	await _abrir(player)
	if not is_inside_tree():
		return
	await player.olhar_para(global_transform * _na_pagina(_ponta_px()), 0.8).finished
	if not is_inside_tree():
		return

	# A pena vem do tinteiro para o começo da página.
	var de := pena.global_transform if pena else Transform3D.IDENTITY
	var t := _tween()
	t.tween_method(func(k: float) -> void:
		if pena:
			var ate := _pena_em(global_transform * _na_pagina(_ponta_px()), Vector3(0.35, 0.85, 0.4))
			pena.global_transform = de.interpolate_with(ate, k), 0.0, 1.0, 0.8)
	await t.finished
	await _escrever(falhar)


## Senta diante do lugar do caderno aberto e olha para ele (da cadeira); o
## caderno vem para diante dele e abre; debruça-se sobre a página.
func _abrir(player: Player) -> void:
	_ocupado = true
	_player = player
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_acertar_pautas.call_deferred()
	var lugar := get_parent_node_3d().global_transform * lugar_aberto
	var sentar := cadeira(player)
	var t := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"global_position", sentar, 1.2)
	player.seated = true
	await player.olhar_para(lugar.origin, 1.4, sentar).finished
	if not is_inside_tree():
		return

	_tocar(som_papel)
	t = _tween()
	t.tween_property(self, ^"transform", lugar_aberto, 1.0)
	await t.finished
	_tocar(som_papel)
	t = _tween()
	t.tween_property(_capa, ^"rotation:z", PI, 0.9)
	await t.finished
	_mostrar_aberto(true)

	# Debruça-se: a cabeça vai à frente sobre a página e a vista se aperta nela.
	player.fov_forcado = FOV_ESCREVENDO
	t = player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"debrucado", 1.0, 1.3)
	await t.finished


## Folhear o diário: abre no último par escrito e espera o jogador fechar
## ([E]/[Esc]); quem fecha o caderno depois é quem chamou (`fechar()`).
func ler(player: Player) -> void:
	_paginas = PackedStringArray([ROSTO])
	var entradas := GameState.dossier.filter(func(d: DocumentData) -> bool:
		return String(d.id).begins_with("diario_dia_"))
	entradas.sort_custom(func(a: DocumentData, b: DocumentData) -> bool:
		return String(a.id).naturalnocasecmp_to(String(b.id)) < 0)
	for d: DocumentData in entradas:
		_paginas.append(d.resolve_pages()[0])
	_par = maxi(0, _paginas.size() - 2)
	_mostrar_par()
	_direita.visible_characters = -1
	_mancha.raio = 0.0
	_mancha.escorrido = 0.0
	await _abrir(player)
	if not is_inside_tree():
		return
	# Os olhos no meio do par aberto, um pouco acima (onde o texto começa).
	await player.olhar_para(global_transform * Vector3(0, 0, -0.03), 0.8).finished
	if not is_inside_tree():
		return
	lendo = true
	_pode_virar = true
	Events.modal_changed.emit(true)
	# Modal para o resto do jogo (o Esc é daqui, não do menu de pausa), mas o
	# mouse continua preso: não há o que clicar.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mostrar_dica(true)
	while lendo or _virando:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	_mostrar_dica(false)
	Events.modal_changed.emit(false)
	player.input_enabled = false


func _unhandled_input(event: InputEvent) -> void:
	if not lendo or not _pode_virar:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"interagir"):
		lendo = false
	elif event.is_action_pressed(&"pagina_proxima") or event.is_action_pressed(&"mover_direita"):
		_virar(1)
	elif event.is_action_pressed(&"pagina_anterior") or event.is_action_pressed(&"mover_esquerda"):
		_virar(-1)
	else:
		return
	get_viewport().set_input_as_handled()


## Vira uma folha: para a frente, a da direita levanta e deita à esquerda; para
## trás, o contrário. A folha que vira leva o par antigo de um lado e o novo do
## outro (uma foto da textura antes da troca), e a página que ela ainda cobre
## continua mostrando o par antigo até a folha passar.
func _virar(direcao: int) -> void:
	var novo := _par + direcao
	if _virando or novo < 0 or novo > maxi(0, _paginas.size() - 2):
		return
	_virando = true
	_mat_foto.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(_vp.get_texture().get_image()))
	if direcao > 0:
		_pag_esq.material_override = _mat_foto
		_frente.material_override = _mat_foto
		_verso.material_override = _mat_vivo
		_virada.rotation.z = 0.0
	else:
		_pag_dir.material_override = _mat_foto
		_verso.material_override = _mat_foto
		_frente.material_override = _mat_vivo
		_virada.rotation.z = PI
	_par = novo
	_mostrar_par()
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	_virada.visible = true
	_tocar(som_papel)
	var t := _tween()
	t.tween_property(_virada, ^"rotation:z", PI if direcao > 0 else 0.0, VIRAR_SEGUNDOS)
	# A folha se arqueia um pouco no meio do caminho.
	t.parallel().tween_method(func(k: float) -> void:
		_virada.position.y = _altura_virada() + sin(k * PI) * 0.012, 0.0, 1.0, VIRAR_SEGUNDOS)
	await t.finished
	_pag_esq.material_override = _mat_vivo
	_pag_dir.material_override = _mat_vivo
	_virada.visible = false
	_virando = false


func _mostrar_par() -> void:
	_esquerda.text = _paginas[_par] if _par < _paginas.size() else ""
	_direita.text = _paginas[_par + 1] if _par + 1 < _paginas.size() else ""
	_acertar_pautas.call_deferred()


## A dica embaixo da tela, em resolução nativa (na raiz, fora do mundo).
func _mostrar_dica(sim: bool) -> void:
	if not sim:
		if _dica:
			_dica.queue_free()
			_dica = null
		return
	if _dica:
		return
	_dica = CanvasLayer.new()
	_dica.layer = 40
	var l := Label.new()
	l.text = "[A] [D] folhear    [E] fechar"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -64.0
	l.offset_bottom = -28.0
	l.add_theme_font_size_override(&"font_size", 20)
	l.add_theme_color_override(&"font_color", Color(0.85, 0.8, 0.7, 0.85))
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override(&"outline_size", 6)
	_dica.add_child(l)
	get_tree().root.add_child(_dica)


static func _ligar_area(area: Interactable, sim: bool) -> void:
	if area == null or area.visible == sim:
		return
	area.visible = sim
	area.process_mode = Node.PROCESS_MODE_INHERIT if sim else Node.PROCESS_MODE_DISABLED


## Onde Wilmarth senta para escrever (global; a altura é a do jogador).
func cadeira(player: Player) -> Vector3:
	var lugar := get_parent_node_3d().global_transform * lugar_aberto
	var p := lugar * Vector3(LARGURA * 0.5, 0, recuo_cadeira)
	p.y = player.global_position.y
	return p


## O meio da página da direita (global, um pouco acima do meio, onde o texto
## começa), para onde ele olha debruçado.
func pagina() -> Vector3:
	return global_transform * Vector3(LARGURA * 0.5, 0, -0.02)


## Escrita a entrada sem falha (ou lido o diário): fecha o caderno, a pena
## volta, ele se ergue.
func fechar(player: Player) -> void:
	player.fov_forcado = 0.0
	var t := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"debrucado", 0.0, 1.0)
	_pena_para_casa(0.8)
	await t.finished
	_mostrar_aberto(false)
	_capa.rotation.z = PI
	_tocar(som_papel)
	t = _tween()
	t.tween_property(_capa, ^"rotation:z", 0.0, 0.9)
	await t.finished
	t = _tween()
	t.tween_property(self, ^"transform", _casa, 1.0)
	await t.finished
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_ocupado = false


## De volta ao lugar, fechado, sem tinta derramada (o dia seguinte).
func repor() -> void:
	_ocupado = false
	lendo = false
	_mostrar_dica(false)
	_escrevendo = false
	_parar_pena()
	transform = _casa
	_capa.rotation.z = 0.0
	_mostrar_aberto(false)
	if pena:
		pena.transform = _pena_casa
	_mancha.raio = 0.0
	_mancha.escorrido = 0.0
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _escrever(falhar: bool) -> void:
	var texto := _direita.get_parsed_text()
	var total := _direita.get_total_character_count()
	_queda_desde = -1
	if falhar:
		_queda_desde = texto.strip_edges(false, true).rfind("\n") + 1
	var normal := total if _queda_desde < 0 else _queda_desde
	_escrevendo = true
	_ligar_pena()
	var t := create_tween()
	t.tween_property(_direita, ^"visible_characters", normal, normal / LETRAS_POR_SEGUNDO)
	await t.finished
	if not is_inside_tree():
		return
	if falhar:
		# A última linha, cada vez mais devagar, até a mão parar.
		var resto := total - normal
		t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(_direita, ^"visible_characters", total, resto / LETRAS_POR_SEGUNDO * 2.6)
		await t.finished
		if not is_inside_tree():
			return
	_escrevendo = false
	_parar_pena()
	if not falhar:
		await get_tree().create_timer(1.2).timeout
		return

	# A pena para e tomba na página; a tinta se espalha e escorre.
	_mancha.centro = _ponta_px() + Vector2(3, 2)
	# Tomba para trás e para o lado, longe do fio que escorre para baixo.
	var ponta := global_transform * _na_pagina(_mancha.centro + Vector2(16, -10))
	var de := pena.global_transform if pena else Transform3D.IDENTITY
	var deitada := _pena_em(ponta, Vector3(0.85, 0.06, -0.5))
	t = create_tween().set_parallel()
	t.tween_method(func(k: float) -> void:
		if pena:
			pena.global_transform = de.interpolate_with(deitada, k), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_mancha, ^"raio", 9.0, 2.5).set_delay(0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_mancha, ^"escorrido", 46.0, 7.0).set_delay(1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.5).timeout


## Onde está a ponta da pena (pixels da textura): logo depois da última letra visível.
func _ponta_px() -> Vector2:
	var c := _direita.visible_characters
	var fonte := _direita.get_theme_font(&"normal_font")
	var subida := fonte.get_ascent(FONTE) * 0.8
	if c <= 0:
		return _direita.position + Vector2(0, subida)
	var texto := _direita.get_parsed_text()
	var linha := _direita.get_character_line(c - 1)
	var faixa := _direita.get_line_range(linha)
	var trecho := texto.substr(faixa.x, c - faixa.x).replace("\n", "")
	var largura := fonte.get_string_size(trecho, HORIZONTAL_ALIGNMENT_LEFT, -1, FONTE).x
	var p := _direita.position + Vector2(largura, _direita.get_line_offset(linha) + subida)
	if _queda_desde >= 0 and c > _queda_desde:
		p += QuedaTextEffect.deslocamento(c - 1 - _queda_desde)
	return p


## Pixel da textura → ponto sobre a folha (local, aberto).
func _na_pagina(px: Vector2) -> Vector3:
	var w := 2.0 * (LARGURA - 0.004)
	var d := FUNDO - 0.008
	return Vector3(-w * 0.5 + px.x / TEXTURA.x * w, TABUA + MIOLO + 0.002, -d * 0.5 + px.y / TEXTURA.y * d)


## A pena com a ponta em `ponta` (global) e o cabo para `cauda` (no espaço do caderno).
func _pena_em(ponta: Vector3, cauda: Vector3) -> Transform3D:
	var dir := (global_basis * cauda).normalized()
	var b := Basis.looking_at(-dir)
	# A caixa da pena tem 0,2 m ao longo de Z; a ponta é o -Z.
	return Transform3D(b, ponta + dir * 0.1)


func _pena_para_casa(segundos: float) -> void:
	if pena == null:
		return
	var de := pena.transform
	var t := _tween()
	t.tween_method(func(k: float) -> void: pena.transform = de.interpolate_with(_pena_casa, k), 0.0, 1.0, segundos)


func _ligar_pena() -> void:
	if som_pena == null:
		return
	_pena_som = AudioStreamPlayer.new()
	_pena_som.stream = som_pena
	_pena_som.bus = &"SFX"
	_pena_som.volume_db = -8.0
	_pena_som.finished.connect(func() -> void:
		if _escrevendo:
			_pena_som.play())
	add_child(_pena_som)
	_pena_som.play()


func _parar_pena() -> void:
	if _pena_som:
		_pena_som.queue_free()
		_pena_som = null


func _mostrar_aberto(sim: bool) -> void:
	aberto = sim
	_aberto.visible = sim
	_fechado.visible = not sim


func _tween() -> Tween:
	return create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _tocar(som: AudioStream) -> void:
	if som:
		AudioDirector.play_sfx(som, -6.0)


# --- Montagem -------------------------------------------------------------------

func _montar() -> void:
	var capa := Selagem._material("res://art/materials/capa_livro.tres")
	capa.set_shader_parameter(&"albedo_color", Color(0.4, 0.16, 0.12))
	var papel := Selagem._material("res://art/materials/papel.tres")

	_fechado = _no(self, "_Fechado")
	_caixa(_fechado, Vector3(LARGURA, TABUA, FUNDO), Vector3(LARGURA * 0.5, TABUA * 0.5, 0), capa)
	_caixa(_fechado, Vector3(LARGURA - 0.006, MIOLO, FUNDO - 0.008), Vector3(LARGURA * 0.5 - 0.001, TABUA + MIOLO * 0.5, 0), papel)
	_caixa(_fechado, Vector3(0.005, MIOLO + TABUA * 2.0, FUNDO), Vector3(0.0025, (MIOLO + TABUA * 2.0) * 0.5, 0), capa)
	# A capa de cima gira na lombada (Z) e vai deitar do lado esquerdo.
	_capa = _no(_fechado, "_Capa")
	_capa.position = Vector3(0, TABUA * 1.5 + MIOLO, 0)
	_caixa(_capa, Vector3(LARGURA, TABUA, FUNDO), Vector3(LARGURA * 0.5, 0, 0), capa)

	_aberto = _no(self, "_Aberto")
	_aberto.visible = false
	for s in [-1.0, 1.0]:
		_caixa(_aberto, Vector3(LARGURA, TABUA, FUNDO), Vector3(s * LARGURA * 0.5, TABUA * 0.5, 0), capa)
		_caixa(_aberto, Vector3(LARGURA - 0.004, MIOLO, FUNDO - 0.008), Vector3(s * (LARGURA * 0.5 - 0.001), TABUA + MIOLO * 0.5, 0), papel)

	_vp = SubViewport.new()
	_vp.name = "_Folhas"
	_vp.size = TEXTURA
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_vp)
	var fundo := ColorRect.new()
	fundo.color = PAPEL
	fundo.size = Vector2(TEXTURA)
	_vp.add_child(fundo)
	_pautas = Pautas.new()
	_pautas.size = Vector2(TEXTURA)
	_vp.add_child(_pautas)
	var meia := TEXTURA.x * 0.5
	_esquerda = _rotulo(Rect2(MARGEM.x, MARGEM.y, meia - MARGEM.x * 2.0, TEXTURA.y - MARGEM.y * 2.0))
	_direita = _rotulo(Rect2(meia + MARGEM.x, MARGEM.y, meia - MARGEM.x * 2.0, TEXTURA.y - MARGEM.y * 2.0))
	_mancha = Mancha.new()
	_mancha.size = Vector2(TEXTURA)
	_mancha.cor = TINTA
	_vp.add_child(_mancha)

	# As páginas: cada uma, metade da textura; a folha que vira gira na lombada,
	# com a frente (para cima, deitada à direita) e o verso.
	var wp := LARGURA - 0.004
	_mat_vivo = Selagem._material("res://art/materials/papel.tres")
	_mat_vivo.set_shader_parameter(&"albedo_tex", _vp.get_texture())
	_mat_foto = Selagem._material("res://art/materials/papel.tres")
	var y := TABUA + MIOLO + 0.0005
	_pag_esq = _folha(_aberto, "_PaginaEsq", -wp, 0.0, 0.0, 0.5, Vector3.UP)
	_pag_dir = _folha(_aberto, "_PaginaDir", 0.0, wp, 0.5, 1.0, Vector3.UP)
	_pag_esq.position.y = y
	_pag_dir.position.y = y
	_virada = _no(_aberto, "_Virada")
	_virada.position.y = _altura_virada()
	_virada.visible = false
	_frente = _folha(_virada, "_Frente", 0.0, wp, 0.5, 1.0, Vector3.UP)
	# O verso: deitado à esquerda (girado meia volta), mostra a página da esquerda.
	_verso = _folha(_virada, "_Verso", 0.0, wp, 0.5, 0.0, Vector3.DOWN)
	for mi in [_pag_esq, _pag_dir, _frente, _verso]:
		mi.material_override = _mat_vivo


func _altura_virada() -> float:
	return TABUA + MIOLO + 0.0017


## Uma página plana, de x0 a x1 (no espaço do pai), com u indo de u0 a u1
## (metade da textura do par), subdividida (o afim não torce), virada para `normal`.
func _folha(pai: Node3D, nome: String, x0: float, x1: float, u0: float, u1: float, normal: Vector3) -> MeshInstance3D:
	var d := FUNDO - 0.008
	var nx := 3
	var nz := 4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ponto := func(i: int, j: int) -> Array:
		var a := float(i) / nx
		var b := float(j) / nz
		return [Vector3(lerpf(x0, x1, a), 0.0, -d * 0.5 + b * d), Vector2(lerpf(u0, u1, a), b)]
	for i in nx:
		for j in nz:
			for tri: Array in [[[i, j], [i + 1, j], [i + 1, j + 1]], [[i, j], [i + 1, j + 1], [i, j + 1]]]:
				var vs: Array = tri.map(func(c: Array) -> Array: return ponto.call(c[0], c[1]))
				# A face da frente do Godot é a de giro horário visto de fora:
				# o produto vetorial aponta para longe de quem vê.
				var n: Vector3 = (vs[1][0] - vs[0][0]).cross(vs[2][0] - vs[0][0])
				if n.dot(normal) > 0.0:
					vs = [vs[0], vs[2], vs[1]]
				for v: Array in vs:
					st.set_normal(normal)
					st.set_uv(v[1])
					st.add_vertex(v[0])
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = st.commit()
	pai.add_child(mi)
	return mi


## As pautas sob as linhas de texto, medidas no próprio rótulo (a altura da
## linha da letra de mão não é a da fonte).
func _acertar_pautas() -> void:
	var r := _direita if _direita.get_line_count() > 1 else _esquerda
	if r.get_line_count() < 2:
		return
	var fonte := r.get_theme_font(&"normal_font")
	_pautas.passo = r.get_line_offset(1) - r.get_line_offset(0)
	_pautas.topo = r.position.y + r.get_line_offset(0) + fonte.get_ascent(FONTE) + 3.0
	_pautas.queue_redraw()


func _rotulo(onde: Rect2) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.clip_contents = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = onde.position
	r.size = onde.size
	r.add_theme_color_override(&"default_color", TINTA)
	r.add_theme_constant_override(&"line_separation", ENTRELINHA)
	DocumentData.apply_fonts(r, DocumentData.Style.MANUSCRITO, FONTE)
	r.install_effect(TremorTextEffect.new())
	r.install_effect(QuedaTextEffect.new())
	r.install_effect(IllegibleTextEffect.new())
	_vp.add_child(r)
	return r


func _no(pai: Node3D, nome: String) -> Node3D:
	var n := Node3D.new()
	n.name = nome
	pai.add_child(n)
	return n


func _caixa(pai: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)
	return mi


## As pautas azuis, apagadas, e a sombra da dobra no meio.
class Pautas extends Control:
	var topo := 40.0
	var passo := 30.0

	func _draw() -> void:
		var cor := Color(0.42, 0.52, 0.68, 0.32)
		var y := topo
		while y < size.y - 16.0:
			draw_line(Vector2(14, y), Vector2(size.x * 0.5 - 12, y), cor, 1.0)
			draw_line(Vector2(size.x * 0.5 + 12, y), Vector2(size.x - 14, y), cor, 1.0)
			y += passo
		for i in 6:
			var a := 0.16 * (1.0 - i / 6.0)
			draw_rect(Rect2(size.x * 0.5 - i * 2 - 2, 0, 4 + i * 4, size.y), Color(0.25, 0.18, 0.1, a * 0.4))


## A tinta derramada no fim da linha que o sono interrompeu: a mancha e o fio
## que escorre página abaixo.
class Mancha extends Control:
	var cor := Color.BLACK
	var centro := Vector2.ZERO
	var raio := 0.0:
		set(v):
			raio = v
			queue_redraw()
	var escorrido := 0.0:
		set(v):
			escorrido = v
			queue_redraw()

	func _draw() -> void:
		if raio <= 0.0:
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		if escorrido > 0.0:
			var fim := centro + Vector2(2.0, escorrido)
			draw_line(centro, fim, cor, maxf(2.0, raio * 0.3))
			draw_circle(fim, maxf(1.5, raio * 0.32), cor)
		draw_circle(centro, raio, cor)
		for i in 8:
			var r := raio * rng.randf_range(0.6, 1.25)
			draw_circle(centro + Vector2.from_angle(rng.randf() * TAU) * r, raio * rng.randf_range(0.18, 0.42), cor)
