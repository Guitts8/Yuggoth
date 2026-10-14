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
##
## O caderno (playtest 5): capa de couro com cantos e a lombada de couro mais
## escuro, com nervuras; o corte das folhas; a fita marcadora vermelha.
##
## Playtest 11 ("essas aberturas e fechadas estão estranhas"): a capa sobe devagar,
## passa do prumo e cai na mesa com o próprio peso (um quique curto); por dentro, a
## guarda marmorizada. O miolo abre na fita como se abre um caderno de verdade:
## a metade de cima sobe inteira, um maço de folhas (`_maco`) que verga no caminho
## (a borda livre vem atrás do vinco, `DOBRA`) e deita à esquerda. A folha que vira
## escrevendo ou lendo também verga (`DOBRA_FOLHA`), como papel. Fecha ao
## contrário. `_pose(capa, folhas)`; a curva é `_curvar`.

const LARGURA := 0.15
const FUNDO := 0.215
## O miolo de cada lado, aberto; fechado, os dois juntos.
const MIOLO := 0.012
const TABUA := 0.003
## Quanto a borda livre fica para trás do vinco no meio do caminho (radianos): o
## maço, mais duro; a folha solta, mais mole.
const DOBRA := 0.75
const DOBRA_FOLHA := 1.5
## O par de páginas abertas é uma textura só (SubViewport), ~1 pixel da textura
## por pixel do mundo com a vista apertada sobre a página.
const TEXTURA := Vector2i(640, 448)
const MARGEM := Vector2(26.0, 30.0)
const FONTE := 25
const LETRAS_POR_SEGUNDO := 20.0
const TINTA := Color(0.1, 0.08, 0.13)
const PAPEL := Color(0.88, 0.84, 0.73)
## A vista apertada, debruçado sobre a página.
const FOV_ESCREVENDO := 30.0
## A primeira página, antes de qualquer entrada.
const ROSTO := "\n\n\n[center]A. N. Wilmarth\n\nMiskatonic University\nArkham, 1928[/center]"
const VIRAR_SEGUNDOS := 0.65
## Escrevendo, quanto os olhos vão do meio da linha para a pena (0 a 1).
const PUXAO_DA_PENA := 0.3

@export var som_pena: AudioStream
@export var som_papel: AudioStream
## A capa que bate fechando (playtest 10).
@export var som_fechar: AudioStream
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
## Folheando: as páginas (rosto + entradas, cada uma em quantas folhas der),
## como [texto, rolagem em px], e a da esquerda no par aberto.
var _paginas: Array = []
var _par := 0
var _virando := false
var _pode_virar := false
var _dica: CanvasLayer
## O caderno é uma tela aberta (Events.modal) enquanto se folheia.
var _tela := false
## As duas páginas abertas (cada uma, metade da textura) e a folha que vira:
## `_mat_vivo` mostra o par atual; `_mat_foto`, uma foto do par anterior.
var _pag_esq: MeshInstance3D
var _pag_dir: MeshInstance3D
var _virada: MeshInstance3D
var _virada_malha := ArrayMesh.new()
## [frente (para cima, deitada à direita), verso].
var _virada_mats: Array[Material] = []
var _mat_vivo: ShaderMaterial
var _mat_foto: ShaderMaterial
var _mat_branco: Material
## A fita no par do dia (aberto); a ponta que sai pelo pé do miolo é do `_Corpo`.
var _fita_aberta: Node3D
var _capa: Node3D
var _lombada: Node3D
var _bloco_dir: Node3D
var _alto_dir: Node3D
## A metade de cima do miolo, que abre na fita: [cima (a primeira página, em
## branco), baixo (a página da esquerda do par aberto), o corte].
var _maco: MeshInstance3D
var _maco_malha := ArrayMesh.new()
var _maco_mats: Array[Material] = []
## O sentido em que o maço anda agora (1 abrindo, -1 fechando): a borda vem atrás.
var _sentido := 1.0
var _aberto: Node3D
## A pose atual (`_pose`): a capa (0 fechada, 1 deitada à esquerda) e o miolo
## (0 todo à direita, 1 aberto na fita).
var _k_capa := 0.0
var _k_folhas := 0.0
var _vp: SubViewport
## Cada página é uma janela (recorta) com o rótulo dentro; o rótulo sobe para
## mostrar a folha seguinte do mesmo texto (playtest 4: a letra saía do caderno).
var _jan_esq: Control
var _jan_dir: Control
var _esquerda: RichTextLabel
var _direita: RichTextLabel
var _mancha: Mancha
var _pautas: Pautas
var _escrevendo := false
## Escrevendo: a página em que a pena está (a da direita ou, depois de virar a
## folha, a da esquerda) e a letra em que essa página começa.
var _pag: RichTextLabel
var _jan: Control
var _pag_desde := 0
## A página do caderno (0 = o rosto) onde a entrada do dia começa; as pares
## ficam à esquerda.
var _inicio := 1
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
	# A fase trocada com o caderno aberto (a ligação de Keene leva a Boston): a
	# tela fecha com ele (sessão de tester 2: ficava aberta, e o jogador sem controle).
	if _tela:
		_tela = false
		Events.modal(self, false)


func _process(delta: float) -> void:
	_t += delta
	# Indisponível, a área some e sai da física (não tampa o que estiver atrás
	# dela). Na hora de anotar o dia, só "Anotar"; fora dela, "Ler".
	var anotar_pode := _anotar != null and not _ocupado and _anotar.can_interact(null)
	_ligar_area(_anotar, anotar_pode)
	# Num sonho (a poltrona da noite 5), o caderno fechado na mesa não se folheia.
	_ligar_area(_ler, not _ocupado and not anotar_pode and int(GameState.get_value(&"sonhando", 0)) == 0)
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
##
## Playtest 7: colada na pena, a vista ficava presa a ela. Agora os olhos ficam
## na linha (o meio da página, na altura dela) e só puxam um pouco para a pena;
## e vão devagar.
func _seguir_a_pena(delta: float) -> void:
	var ponta := _ponta_px()
	var linha := Vector2(_meio_da_pagina(), ponta.y + 6.0)
	var alvo := global_transform * _na_pagina(linha.lerp(ponta + Vector2(-30.0, 6.0), PUXAO_DA_PENA))
	var olho := _player.camera.global_position
	var yaw := atan2(-(alvo.x - olho.x), -(alvo.z - olho.z))
	var pitch := atan2(alvo.y - olho.y, Vector2(alvo.x - olho.x, alvo.z - olho.z).length())
	pitch += sin(_t * 1.3) * 0.006
	yaw += sin(_t * 0.7) * 0.004
	var k := 1.0 - exp(-0.9 * delta)
	_player.rotation.y += angle_difference(_player.rotation.y, yaw) * k
	_player.head.rotation.x = lerp_angle(_player.head.rotation.x, pitch, k)


## Wilmarth senta, o caderno vem para diante dele e abre; a entrada se escreve.
## Com `falhar`, a última linha cai e a tinta escorre: termina aberto, a pena
## tombada na página.
##
## Playtest 11: as páginas são as do caderno, em sequência (o rosto, depois cada
## entrada a partir da página seguinte à da anterior). Se a do dia começa numa
## página da direita, à esquerda fica o fim da anterior; se começa na da esquerda,
## o par é novo. Cheia a da direita, a folha vira e leva o que foi escrito; a
## escrita continua na esquerda do par seguinte, depois na direita.
func anotar(entrada: DocumentData, _anterior: DocumentData, player: Player, falhar: bool) -> void:
	var antes := _sequencia(entrada.id if entrada else &"")
	_inicio = antes.size()
	var texto: String = entrada.resolve_pages()[0] if entrada else ""
	_direita.text = texto
	_direita.visible_characters = 0
	var folhas := _folhas(_direita)
	if _inicio % 2 == 1:
		# Começa à direita: à esquerda, a última página escrita.
		_mostrar(_esquerda, antes[_inicio - 1])
		_direita.position.y = 0.0
		_usar_pagina(_direita, _jan_dir, 0)
	else:
		# Começa num par novo, à esquerda; a da direita, em branco.
		_esquerda.text = texto
		_esquerda.visible_characters = 0
		_esquerda.position.y = 0.0
		_direita.position.y = -folhas[1] if folhas.size() > 1 else 0.0
		_usar_pagina(_esquerda, _jan_esq, 0)
	_mancha.raio = 0.0
	_mancha.escorrido = 0.0
	await _abrir(player)
	if not is_inside_tree():
		return
	var ponta := _ponta_px()
	var linha := Vector2(_meio_da_pagina(), ponta.y + 6.0)
	await player.olhar_para(global_transform * _na_pagina(linha.lerp(ponta, PUXAO_DA_PENA)), 0.8).finished
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
	# Longe, vai até a cadeira a pé antes de sentar (playtest 10).
	if Vector2(player.global_position.x - sentar.x, player.global_position.z - sentar.z).length() > 0.6:
		if player.seated:
			player.stand()
		await player.conduzir([sentar + lugar.basis.z * 0.4], lugar.origin)
		if not is_inside_tree():
			return
	var t := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"global_position", sentar, 0.9)
	player.seated = true
	await player.olhar_para(lugar.origin, 1.1, sentar).finished
	if not is_inside_tree():
		return

	_tocar(som_papel)
	t = _tween()
	t.tween_property(self, ^"transform", lugar_aberto, 1.0)
	await t.finished
	# Debruça-se enquanto abre (playtest 11: de longe, a abertura passava sem ser
	# vista): a cabeça vai à frente e a vista se aperta sobre o caderno.
	player.fov_forcado = FOV_ESCREVENDO
	var deb := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	deb.tween_property(player, ^"debrucado", 1.0, 2.4)
	await _abrir_capa()
	if not is_inside_tree():
		return
	# O miolo abre na fita.
	await _animar_pose(1.0, 1.0, 1.05)
	_tocar(som_papel, -12.0)
	_mostrar_aberto(true)
	if deb.is_running():
		await deb.finished


## A capa: sobe devagar até o prumo, cai do outro lado com o próprio peso e quica
## de leve na mesa.
func _abrir_capa() -> void:
	_tocar(som_papel, -10.0)
	var t := create_tween()
	t.tween_method(func(k: float) -> void: _pose(k, 0.0), 0.0, 0.5, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(k: float) -> void: _pose(k, 0.0), 0.5, 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		if som_fechar:
			var baque := AudioDirector.play_sfx(som_fechar, -22.0)
			baque.pitch_scale = 1.6)
	t.tween_method(func(k: float) -> void: _pose(k, 0.0), 1.0, 0.975, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_method(func(k: float) -> void: _pose(k, 0.0), 0.975, 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished


## As páginas do caderno, em ordem: o rosto e as folhas de cada entrada do
## dossiê (menos `menos`), como [texto, rolagem, até que letra].
func _sequencia(menos: StringName) -> Array:
	var paginas: Array = [[ROSTO, 0.0]]
	var entradas := GameState.dossier.filter(func(d: DocumentData) -> bool:
		return String(d.id).begins_with("diario_dia_") and d.id != menos)
	entradas.sort_custom(func(a: DocumentData, b: DocumentData) -> bool:
		return String(a.id).naturalnocasecmp_to(String(b.id)) < 0)
	for d: DocumentData in entradas:
		var texto: String = d.resolve_pages()[0]
		_esquerda.text = texto
		var folhas := _folhas(_esquerda)
		for k in folhas.size():
			paginas.append([texto, folhas[k], _fim_da_folha(_esquerda, k)])
	return paginas


## Folhear o diário: abre no último par escrito e espera o jogador fechar
## ([E]/[Esc]); quem fecha o caderno depois é quem chamou (`fechar()`).
func ler(player: Player) -> void:
	_paginas = _sequencia(&"")
	# Abre no par da última página escrita (os pares começam nas páginas pares).
	_par = (_paginas.size() - 1) & ~1
	_mostrar_par()
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
	_tela = true
	Events.modal(self, true)
	# Modal para o resto do jogo (o Esc é daqui, não do menu de pausa), mas o
	# mouse continua preso: não há o que clicar.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mostrar_dica(true)
	while lendo or _virando:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	_mostrar_dica(false)
	_tela = false
	Events.modal(self, false)
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


## Vira uma folha (o par anda duas páginas): para a frente, a da direita levanta
## e deita à esquerda; para trás, o contrário. A folha que vira leva o par antigo de um lado e o novo do
## outro (uma foto da textura antes da troca), e a página que ela ainda cobre
## continua mostrando o par antigo até a folha passar.
func _virar(direcao: int) -> void:
	var novo := _par + direcao * 2
	if _virando or novo < 0 or novo > _paginas.size() - 1:
		return
	await _animar_virada(direcao, func() -> void:
		_par = novo
		_mostrar_par())


## A folha virando (as duas direções), com `trocar` mudando o conteúdo no meio:
## ao ler (o par seguinte) e ao escrever (a folha cheia passa para a esquerda).
func _animar_virada(direcao: int, trocar: Callable) -> void:
	_virando = true
	var foto: Image = null if DisplayServer.get_name() == "headless" else _vp.get_texture().get_image()
	if foto == null:
		# Sem renderização (os testes, headless): não há foto da folha, nem quadro
		# desenhado para esperar — troca e pronto.
		trocar.call()
		await get_tree().process_frame
		_virando = false
		return
	_mat_foto.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(foto))
	if direcao > 0:
		_pag_esq.material_override = _mat_foto
		_virada_mats = [_mat_foto, _mat_vivo]
	else:
		_pag_dir.material_override = _mat_foto
		_virada_mats = [_mat_vivo, _mat_foto]
	var sentido := 1.0 if direcao > 0 else -1.0
	_curvar_folha(0.0 if direcao > 0 else 1.0, sentido)
	trocar.call()
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	_virada.visible = true
	_tocar(som_papel)
	# A folha verga: o vinco vai na frente e a borda vem atrás.
	var t := _tween()
	t.tween_method(func(k: float) -> void:
		_curvar_folha(k if direcao > 0 else 1.0 - k, sentido), 0.0, 1.0, VIRAR_SEGUNDOS)
	await t.finished
	_pag_esq.material_override = _mat_vivo
	_pag_dir.material_override = _mat_vivo
	_virada.visible = false
	_virando = false


func _mostrar_par() -> void:
	_mostrar(_esquerda, _paginas[_par] if _par < _paginas.size() else ["", 0.0])
	_mostrar(_direita, _paginas[_par + 1] if _par + 1 < _paginas.size() else ["", 0.0])
	_acertar_pautas.call_deferred()


## Uma página: [texto, rolagem, até que letra] (a folha do texto que cabe nela).
func _mostrar(r: RichTextLabel, pagina: Array) -> void:
	r.text = pagina[0]
	r.visible_characters = pagina[2] if pagina.size() > 2 else -1
	r.position.y = -float(pagina[1])


## Quantas linhas cabem numa folha (a última com folga para a letra que cai).
func _linhas_por_folha(r: RichTextLabel) -> int:
	if r.get_line_count() < 2:
		return 999
	var passo := r.get_line_offset(1) - r.get_line_offset(0)
	var fonte := r.get_theme_font(&"normal_font")
	var alto := _jan_dir.size.y - 14.0
	return maxi(1, int((alto - fonte.get_height(FONTE)) / passo) + 1)


## As folhas do texto que está em `r`: a rolagem (px) de cada uma.
func _folhas(r: RichTextLabel) -> PackedFloat32Array:
	var f := PackedFloat32Array([0.0])
	var linhas := r.get_line_count()
	var por := _linhas_por_folha(r)
	var k := por
	while k < linhas:
		f.append(r.get_line_offset(k) - r.get_line_offset(0))
		k += por
	return f


## Até que letra vai a folha `k` do texto em `r` (-1: até o fim): a linha
## seguinte, já da outra folha, não aparece cortada no pé desta.
func _fim_da_folha(r: RichTextLabel, k: int) -> int:
	var primeira := (k + 1) * _linhas_por_folha(r)
	return r.get_line_range(primeira).x if primeira < r.get_line_count() else -1


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
	_pena_para_casa(0.8)
	await get_tree().create_timer(0.5).timeout
	# Ao contrário, ainda debruçado (playtest 11: erguia-se antes e o caderno
	# fechava longe): o maço volta para a direita; ele se ergue enquanto a capa
	# fecha por cima.
	_mostrar_aberto(false)
	await _animar_pose(1.0, 0.0, 1.05)
	player.fov_forcado = 0.0
	var t := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"debrucado", 0.0, 1.6)
	# A capa: erguida devagar até em pé, e dali cai sobre o miolo (acelera no fim,
	# como cai uma capa de verdade), com um baque surdo de couro.
	await _animar_pose(0.5, 0.0, 0.6)
	var cai := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	cai.tween_method(func(k: float) -> void: _pose(k, 0.0), 0.5, 0.0, 0.32)
	await cai.finished
	if som_fechar:
		var baque := AudioDirector.play_sfx(som_fechar, -15.0)
		baque.pitch_scale = 1.4
	await get_tree().create_timer(0.25).timeout
	if t.is_running():
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
	_pose(0.0, 0.0)
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
	# As páginas que a entrada ocupa (playtest 4: "ao finalizar a folha, ele deve
	# passar para a próxima"): da direita para a esquerda do par seguinte, virando
	# a folha; da esquerda para a direita do mesmo par, só a pena muda de página.
	var folhas := _folhas(_direita)
	var por := _linhas_por_folha(_direita)
	_escrevendo = true
	_ligar_pena()
	var t: Tween
	for k in folhas.size():
		var desde := 0 if k == 0 else _direita.get_line_range(k * por).x
		var fim := total if k == folhas.size() - 1 else _direita.get_line_range((k + 1) * por).x
		if k > 0:
			if (_inicio + k) % 2 == 0:
				await _virar_escrevendo(folhas, k, desde)
			else:
				await _pena_para(_direita, _jan_dir, desde)
			if not is_inside_tree():
				return
		var alvo := mini(fim, normal)
		if alvo > desde:
			t = create_tween()
			t.tween_property(_pag, ^"visible_characters", alvo, (alvo - desde) / LETRAS_POR_SEGUNDO)
			await t.finished
			if not is_inside_tree():
				return
	if falhar:
		# A última linha, cada vez mais devagar, até a mão parar.
		var resto := total - maxi(normal, _pag.visible_characters)
		t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(_pag, ^"visible_characters", total, resto / LETRAS_POR_SEGUNDO * 2.6)
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


## A folha da direita encheu: a pena se ergue, a folha vira e leva o que foi
## escrito (o verso dela, agora à esquerda, está em branco), e a escrita continua
## no alto da página da esquerda do par novo (a folha `k` do texto).
func _virar_escrevendo(folhas: PackedFloat32Array, k: int, desde: int) -> void:
	_escrevendo = false
	_parar_pena()
	if pena:
		var de := pena.global_transform
		var t := _tween()
		t.tween_property(pena, ^"global_transform", de.translated(Vector3.UP * 0.05), 0.3)
		await t.finished
	await _animar_virada(1, func() -> void:
		# As duas páginas do par novo, em branco: o texto até `desde` fica acima
		# da janela de cada uma.
		_esquerda.text = _direita.text
		_esquerda.visible_characters = desde
		_esquerda.position.y = -folhas[k]
		_direita.visible_characters = desde
		_direita.position.y = -folhas[k + 1] if k + 1 < folhas.size() else -folhas[k])
	if not is_inside_tree():
		return
	await _pena_para(_esquerda, _jan_esq, desde)


## A escrita passa para a página `r` (a letra `desde` é a primeira dela): a pena
## se ergue, vai ao alto da página e continua.
func _pena_para(r: RichTextLabel, janela: Control, desde: int) -> void:
	_escrevendo = false
	_parar_pena()
	r.visible_characters = desde
	_usar_pagina(r, janela, desde)
	if pena:
		var de := pena.global_transform
		var ate := _pena_em(global_transform * _na_pagina(_ponta_px()), Vector3(0.35, 0.85, 0.4))
		var t := _tween()
		t.tween_method(func(k: float) -> void:
			var m := de.interpolate_with(ate, k)
			pena.global_transform = m.translated(Vector3.UP * sin(k * PI) * 0.03), 0.0, 1.0, 0.55)
		await t.finished
		if not is_inside_tree():
			return
	_escrevendo = true
	_ligar_pena()


func _usar_pagina(r: RichTextLabel, janela: Control, desde: int) -> void:
	_pag = r
	_jan = janela
	_pag_desde = desde


## O meio da página em que se escreve (x, pixels da textura).
func _meio_da_pagina() -> float:
	return _jan.position.x + _jan.size.x * 0.5


## Onde está a ponta da pena (pixels da textura): logo depois da última letra visível.
func _ponta_px() -> Vector2:
	var r := _pag
	var c := r.visible_characters
	var fonte := r.get_theme_font(&"normal_font")
	var subida := fonte.get_ascent(FONTE) * 0.8
	var origem := _jan.position + r.position
	if c <= _pag_desde:
		# Nada escrito nesta página ainda: o começo da primeira linha dela.
		return _jan.position + Vector2(0, subida)
	var texto := r.get_parsed_text()
	var linha := r.get_character_line(c - 1)
	var faixa := r.get_line_range(linha)
	var trecho := texto.substr(faixa.x, c - faixa.x).replace("\n", "")
	var largura := fonte.get_string_size(trecho, HORIZONTAL_ALIGNMENT_LEFT, -1, FONTE).x
	var p := origem + Vector2(largura, r.get_line_offset(linha) + subida)
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
	_pose(_k_capa, _k_folhas)


## Anima a pose de onde está até (`capa`, `folhas`); `correndo`, com o som das
## folhas passando (umas atrás das outras).
func _animar_pose(capa: float, folhas: float, segundos: float, correndo := false) -> void:
	var de := Vector2(_k_capa, _k_folhas)
	var ate := Vector2(capa, folhas)
	if ate.y != de.y:
		_sentido = signf(ate.y - de.y)
	var t := _tween()
	t.tween_method(func(k: float) -> void:
		var p := de.lerp(ate, k)
		_pose(p.x, p.y), 0.0, 1.0, segundos)
	_tocar(som_papel)
	if correndo:
		for i in 3:
			get_tree().create_timer(segundos * (0.25 + i * 0.25)).timeout.connect(_tocar.bind(som_papel))
	await t.finished


## O caderno entre fechado e aberto na fita. `capa` 0..1: a capa gira na lombada
## e deita à esquerda (a dobradiça desce à mesa na segunda metade, sem a capa
## entrar nela). `folhas` 0..1: o maço (a metade de cima do miolo) gira no vinco,
## vergando, da direita para a esquerda, onde deita sobre a guarda.
func _pose(capa: float, folhas: float) -> void:
	_k_capa = capa
	_k_folhas = folhas
	var angulo := PI * capa
	var alto := TABUA + MIOLO * 2.0 + TABUA * 0.5
	var queda := clampf(capa * 2.0 - 1.0, 0.0, 1.0)
	_capa.rotation.z = angulo
	_capa.position.y = lerpf(alto, TABUA * 0.5, queda)
	# A lombada cobre o miolo inteiro; aberto, fica sob o vinco.
	_lombada.scale.y = TABUA * (2.0 - capa) + MIOLO * (2.0 - folhas) - 0.0005 * capa
	# O maço gira na linha do meio dele, junto ao vinco: em cima da metade da
	# direita, fechado; sobre a guarda da capa, aberto.
	var k := smoothstep(0.0, 1.0, folhas)
	_maco.position = Vector3(lerpf(0.002, -0.002, k), lerpf(TABUA + MIOLO * 1.5, TABUA + MIOLO * 0.5, k) + 0.0003, 0)
	_curvar(_maco_malha, folhas, _sentido, DOBRA, MIOLO, LARGURA - 0.006, Vector2(0.0, 1.0), Vector2(0.5, 0.0), true)
	_aplicar_mats(_maco_malha, _maco_mats)


## A folha que vira (`t` 0 deitada à direita, 1 à esquerda), vergando.
func _curvar_folha(t: float, sentido: float) -> void:
	_virada.position.y = _altura_virada() + sin(t * PI) * 0.003
	_curvar(_virada_malha, t, sentido, DOBRA_FOLHA, 0.0004, LARGURA - 0.004, Vector2(0.5, 1.0), Vector2(0.5, 0.0), false)
	_aplicar_mats(_virada_malha, _virada_mats)


static func _aplicar_mats(malha: ArrayMesh, mats: Array[Material]) -> void:
	for i in mini(malha.get_surface_count(), mats.size()):
		malha.surface_set_material(i, mats[i])


## Refaz `malha`: uma folha (ou um maço, com `espessura`) presa no vinco (a origem,
## ao longo de Z), de largura `w`, com `t` 0 deitada para +X e 1 para -X. No meio
## do caminho a borda livre fica para trás do vinco (`dobra` radianos, no sentido
## contrário ao movimento, `sentido`), e o comprimento não muda: a curva é a soma
## de pedaços iguais. Superfícies: a de cima (u de `u_cima` pela largura), a de
## baixo (`u_baixo`) e, com `bordas`, o corte (a borda livre e as duas pontas).
static func _curvar(malha: ArrayMesh, t: float, sentido: float, dobra: float, espessura: float, w: float,
		u_cima: Vector2, u_baixo: Vector2, bordas: bool) -> void:
	const N := 12
	const NZ := 4
	var d := FUNDO - 0.008
	var a := PI * t
	var curva := dobra * sin(PI * t) * sentido
	var angulos := PackedFloat32Array()
	for i in N + 1:
		angulos.append(clampf(a - curva * float(i) / N, 0.0, PI))
	var meio := PackedVector2Array([Vector2.ZERO])
	var p := Vector2.ZERO
	for i in N:
		var phi := (angulos[i] + angulos[i + 1]) * 0.5
		p += Vector2(cos(phi), sin(phi)) * w / N
		meio.append(p)
	var cima := PackedVector3Array()
	var baixo := PackedVector3Array()
	var normais := PackedVector3Array()
	for i in N + 1:
		var n := Vector2(-sin(angulos[i]), cos(angulos[i]))
		normais.append(Vector3(n.x, n.y, 0))
		cima.append(Vector3(meio[i].x + n.x * espessura * 0.5, meio[i].y + n.y * espessura * 0.5, 0))
		baixo.append(Vector3(meio[i].x - n.x * espessura * 0.5, meio[i].y - n.y * espessura * 0.5, 0))
	malha.clear_surfaces()
	for lado: float in [1.0, -1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var linha := cima if lado > 0 else baixo
		var u := u_cima if lado > 0 else u_baixo
		for i in N:
			for j in NZ:
				var quad := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
				var vs: Array = []
				for c: Array in quad:
					var z := -d * 0.5 + d * float(c[1]) / NZ
					vs.append([linha[c[0]] + Vector3(0, 0, z), Vector2(lerpf(u.x, u.y, float(c[0]) / N), float(c[1]) / NZ),
						normais[c[0]] * lado])
				_quad(st, vs)
		st.commit(malha)
	if not bordas:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ponta := Vector3(cos(angulos[N]), sin(angulos[N]), 0)
	for j in NZ:
		var z0 := -d * 0.5 + d * float(j) / NZ
		var z1 := -d * 0.5 + d * float(j + 1) / NZ
		_quad(st, [[cima[N] + Vector3(0, 0, z0), Vector2(0, 0), ponta], [cima[N] + Vector3(0, 0, z1), Vector2(1, 0), ponta],
			[baixo[N] + Vector3(0, 0, z1), Vector2(1, 1), ponta], [baixo[N] + Vector3(0, 0, z0), Vector2(0, 1), ponta]])
	for lado: float in [-1.0, 1.0]:
		var z := d * 0.5 * lado
		var n := Vector3(0, 0, lado)
		for i in N:
			_quad(st, [[cima[i] + Vector3(0, 0, z), Vector2(float(i) / N, 0), n], [cima[i + 1] + Vector3(0, 0, z), Vector2(float(i + 1) / N, 0), n],
				[baixo[i + 1] + Vector3(0, 0, z), Vector2(float(i + 1) / N, 1), n], [baixo[i] + Vector3(0, 0, z), Vector2(float(i) / N, 1), n]])
	st.commit(malha)


## Um quadrilátero ([ponto, uv, normal] × 4) com a frente para o lado da normal.
static func _quad(st: SurfaceTool, vs: Array) -> void:
	for tri: Array in [[vs[0], vs[1], vs[2]], [vs[0], vs[2], vs[3]]]:
		var n: Vector3 = (tri[1][0] - tri[0][0]).cross(tri[2][0] - tri[0][0])
		# A face da frente do Godot é a de giro horário visto de fora: o produto
		# vetorial aponta para longe de quem vê.
		if n.dot(tri[0][2]) > 0.0:
			tri = [tri[0], tri[2], tri[1]]
		for v: Array in tri:
			st.set_normal(v[2])
			st.set_uv(v[1])
			st.add_vertex(v[0])


func _tween() -> Tween:
	return create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _tocar(som: AudioStream, db := -6.0) -> void:
	if som:
		AudioDirector.play_sfx(som, db)


# --- Montagem -------------------------------------------------------------------

func _montar() -> void:
	var capa := _cor("res://art/materials/capa_livro.tres", Color(0.4, 0.16, 0.12))
	var couro := _cor("res://art/materials/capa_livro.tres", Color(0.19, 0.08, 0.06))
	var corte := _cor("res://art/materials/papel.tres", Color(0.86, 0.8, 0.66))
	var guarda := Selagem._material("res://art/materials/papel.tres")
	guarda.set_shader_parameter(&"albedo_tex", _guarda_marmorizada())
	guarda.set_shader_parameter(&"albedo_color", Color.WHITE)
	var fita := _cor("res://art/materials/papel.tres", Color(0.62, 0.09, 0.08))
	var miolo := Vector3(LARGURA - 0.006, 1.0, FUNDO - 0.008)
	# A página em branco (pautada, como as do par aberto): o alto do miolo e as
	# folhas que correm (playtest 7: o corte riscado no lugar da página, ao
	# fechar, era um salto).
	var branco := Selagem._material("res://art/materials/papel.tres")
	branco.set_shader_parameter(&"albedo_tex", _pagina_em_branco())
	branco.set_shader_parameter(&"albedo_color", Color.WHITE)
	_mat_branco = branco
	_mat_vivo = Selagem._material("res://art/materials/papel.tres")

	var corpo := _no(self, "_Corpo")
	# A contracapa (embaixo) e a metade de baixo do miolo, à direita (pivô no pé: a
	# escala em y é a altura); o alto dela é a página da direita do par aberto (a
	# textura viva). A metade de cima é o maço, que abre na fita.
	_caixa(corpo, Vector3(LARGURA, TABUA, FUNDO), Vector3(LARGURA * 0.5, TABUA * 0.5, 0), capa)
	_bloco_dir = _no(corpo, "_BlocoDir")
	_bloco_dir.position = Vector3(LARGURA * 0.5 - 0.001, TABUA, 0)
	_bloco_dir.scale.y = MIOLO
	_sem_tampa(_caixa(_bloco_dir, miolo, Vector3(0, 0.5, 0), corte))
	_alto_dir = _folha(corpo, "_AltoDir", -miolo.x * 0.5, miolo.x * 0.5, 0.5, 1.0, Vector3.UP)
	_alto_dir.position = Vector3(_bloco_dir.position.x, TABUA + MIOLO, 0)
	_alto_dir.material_override = _mat_vivo
	_maco = MeshInstance3D.new()
	_maco.name = "_Maco"
	_maco.mesh = _maco_malha
	corpo.add_child(_maco)
	_maco_mats = [branco, _mat_vivo, corte]
	# A capa gira na lombada (Z) e vai deitar do lado esquerdo: o couro com os
	# cantos e a faixa da lombada por fora, a folha de guarda por dentro.
	_capa = _no(corpo, "_Capa")
	var tabua := _caixa(_capa, Vector3(LARGURA, TABUA, FUNDO), Vector3(LARGURA * 0.5, 0, 0), capa)
	_cantos(tabua, TABUA * 0.5 + 0.0004, couro)
	_caixa(tabua, Vector3(0.024, 0.0008, FUNDO + 0.001), Vector3(-LARGURA * 0.5 + 0.012, TABUA * 0.5 + 0.0004, 0), couro)
	# Por dentro, a guarda marmorizada (uma folha só, virada para dentro).
	var gd := _folha(tabua, "_Guarda", -LARGURA * 0.5 + 0.004, LARGURA * 0.5 - 0.004, 0.0, 1.0, Vector3.DOWN)
	gd.position.y = -TABUA * 0.5 - 0.0002
	gd.material_override = guarda
	# A lombada de couro escuro com as nervuras (pivô no pé).
	_lombada = _no(corpo, "_Lombada")
	_caixa(_lombada, Vector3(0.006, 1.0, FUNDO + 0.001), Vector3(-0.003, 0.5, 0), couro)
	for k in 4:
		var z := lerpf(-FUNDO * 0.36, FUNDO * 0.36, k / 3.0)
		_caixa(_lombada, Vector3(0.003, 0.9, 0.007), Vector3(-0.0065, 0.5, z), couro)
	# A fita: desce pelo pé do miolo e deita na mesa; aberto, corre no par do dia.
	var pe := FUNDO * 0.5 + 0.0008
	_caixa(corpo, Vector3(0.006, TABUA + MIOLO, 0.0005), Vector3(0.0075, (TABUA + MIOLO) * 0.5, pe), fita)
	var ponta := _caixa(corpo, Vector3(0.006, 0.0005, 0.036), Vector3(0.0095, 0.0003, pe + 0.018), fita)
	ponta.rotation.y = deg_to_rad(-9.0)

	_aberto = _no(self, "_Aberto")
	_aberto.visible = false
	_fita_aberta = _caixa(_aberto, Vector3(0.006, 0.0005, FUNDO - 0.012), Vector3(0.0075, TABUA + MIOLO + 0.0012, 0.002), fita)

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
	_jan_esq = _janela(Rect2(MARGEM.x, MARGEM.y, meia - MARGEM.x * 2.0, TEXTURA.y - MARGEM.y * 2.0))
	_jan_dir = _janela(Rect2(meia + MARGEM.x, MARGEM.y, meia - MARGEM.x * 2.0, TEXTURA.y - MARGEM.y * 2.0))
	_esquerda = _rotulo(_jan_esq)
	_direita = _rotulo(_jan_dir)
	_usar_pagina(_direita, _jan_dir, 0)
	_mancha = Mancha.new()
	_mancha.size = Vector2(TEXTURA)
	_mancha.cor = TINTA
	_vp.add_child(_mancha)

	# As páginas: cada uma, metade da textura; a folha que vira gira na lombada,
	# com a frente (para cima, deitada à direita) e o verso.
	var wp := LARGURA - 0.004
	_mat_vivo.set_shader_parameter(&"albedo_tex", _vp.get_texture())
	_mat_foto = Selagem._material("res://art/materials/papel.tres")
	var y := TABUA + MIOLO + 0.0005
	_pag_esq = _folha(_aberto, "_PaginaEsq", -wp, 0.0, 0.0, 0.5, Vector3.UP)
	_pag_dir = _folha(_aberto, "_PaginaDir", 0.0, wp, 0.5, 1.0, Vector3.UP)
	_pag_esq.position.y = y
	_pag_dir.position.y = y
	# A folha que vira: a frente (para cima, deitada à direita) e o verso, que
	# deitado à esquerda mostra a página da esquerda (`_curvar_folha`).
	_virada = MeshInstance3D.new()
	_virada.name = "_Virada"
	_virada.mesh = _virada_malha
	_virada.visible = false
	_aberto.add_child(_virada)
	_virada_mats = [_mat_vivo, _mat_vivo]
	_curvar_folha(0.0, 1.0)
	for mi in [_pag_esq, _pag_dir]:
		mi.material_override = _mat_vivo
	_pose(0.0, 0.0)


## A textura da página em branco: o papel e as pautas, na escala do par aberto.
static func _pagina_em_branco() -> Texture2D:
	# Uma página só (metade do par), a meia resolução.
	var img := Image.create(TEXTURA.x / 4, TEXTURA.y / 2, false, Image.FORMAT_RGB8)
	img.fill(PAPEL)
	var pauta := PAPEL.lerp(Color(0.42, 0.52, 0.68), 0.32)
	var y := 20.0
	while y < img.get_height() - 8:
		for x in range(7, img.get_width() - 4):
			img.set_pixel(x, int(y), pauta)
		y += 15.0
	return ImageTexture.create_from_image(img)


## A guarda marmorizada (o papel de dentro da capa): veios torcidos de vermelho,
## creme, azul e ocre.
static func _guarda_marmorizada() -> Texture2D:
	var ruido := FastNoiseLite.new()
	ruido.seed = 11
	ruido.frequency = 0.06
	ruido.domain_warp_enabled = true
	ruido.domain_warp_amplitude = 18.0
	ruido.domain_warp_frequency = 0.04
	# Tons apagados, próximos uns dos outros (playtest 11: berrante, parecia camuflagem).
	var cores := [Color(0.36, 0.17, 0.13), Color(0.5, 0.36, 0.26), Color(0.27, 0.22, 0.22), Color(0.44, 0.27, 0.17)]
	var img := Image.create(96, 136, false, Image.FORMAT_RGB8)
	for y in img.get_height():
		for x in img.get_width():
			var n := (ruido.get_noise_2d(x * 1.0, y * 0.45) * 0.5 + 0.5) * 6.0
			var i := int(n) % cores.size()
			var c: Color = cores[i].lerp(cores[(i + 1) % cores.size()], smoothstep(0.75, 1.0, fposmod(n, 1.0)))
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Uma cópia do material com outra cor (o couro, o corte das folhas, a fita).
static func _cor(caminho: String, cor: Color) -> Material:
	var mat := Selagem._material(caminho)
	mat.set_shader_parameter(&"albedo_color", cor)
	return mat


## Os cantos de couro nas pontas de fora da capa (`tabua`, centrada na origem).
func _cantos(tabua: Node3D, y: float, mat: Material) -> void:
	for s in [-1.0, 1.0]:
		_caixa(tabua, Vector3(0.024, 0.0008, 0.024), Vector3(LARGURA * 0.5 - 0.0115, y, s * (FUNDO * 0.5 - 0.0115)), mat)


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
	# As folhas rolam de linha inteira em linha inteira: as pautas não mudam.
	_pautas.topo = _jan_dir.position.y + r.get_line_offset(0) + fonte.get_ascent(FONTE) + 3.0
	_pautas.queue_redraw()


## A janela de uma página: recorta o que passa da folha.
func _janela(onde: Rect2) -> Control:
	var c := Control.new()
	c.position = onde.position
	c.size = onde.size
	c.clip_contents = true
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp.add_child(c)
	return c


## O rótulo de uma página: da largura dela e bem mais alto (o texto todo, que
## sobe uma folha por vez).
func _rotulo(janela: Control) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.clip_contents = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = Vector2.ZERO
	r.size = Vector2(janela.size.x, janela.size.y * 24.0)
	r.add_theme_color_override(&"default_color", TINTA)
	DocumentData.apply_fonts(r, DocumentData.Style.WILMARTH, FONTE)
	r.install_effect(TremorTextEffect.new())
	r.install_effect(QuedaTextEffect.new())
	r.install_effect(IllegibleTextEffect.new())
	janela.add_child(r)
	return r


## Tira a face de cima de uma caixa (o alto do miolo é outra malha, a página).
static func _sem_tampa(mi: MeshInstance3D) -> void:
	var arrays := (mi.mesh as BoxMesh).get_mesh_arrays()
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0, idx.size(), 3):
		if ns[idx[t]].y > 0.9:
			continue
		for k in 3:
			st.set_normal(ns[idx[t + k]])
			st.set_uv(uvs[idx[t + k]])
			st.add_vertex(vs[idx[t + k]])
	mi.mesh = st.commit()


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
