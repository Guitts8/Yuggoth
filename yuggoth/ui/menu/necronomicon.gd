class_name Necronomicon
extends Control
## O livro dos menus (playtest 7: "o menu deve se assemelhar mais com o de
## Castlevania: Lords of Shadow 2 [...] é o Necronomicon afinal. Capa pesada,
## livro gigante, folhas velhas"; refeito na sessão do menu, com as imagens de
## referência): um tomo enorme encadernado em couro negro e ferro, aberto sobre a
## mesa no escuro, à luz de duas velas, em 3D — no grão do jogo (a tela do mundo
## em ~540 linhas, o pontilhado e as cores do PS1, `psx_post`). As páginas são a
## tinta dos menus (MainMenu, PauseMenu, OptionsMenu), que moram no SubViewport
## filho `Paginas` (as duas páginas lado a lado) e são impressas no papel velho
## (shaders/livro_pagina.gdshader).
##
## O mouse aponta para o livro: o raio da câmera acha o ponto na página e o
## evento vai para `Paginas` nesse ponto; teclado e controle vão direto. Com o
## livro escondido (no jogo), as teclas ainda passam por `Paginas`, depois de
## todo o resto (o Esc que abre a pausa).
##
## Aparece sozinho quando um dos menus está visível:
## - o jogo começando (`abertura_pedida`, MainMenu.open(true)): o escuro, as velas
##   que se acendem uma a uma, a câmera que se afasta da capa, a capa que se
##   levanta e cai do outro lado (o baque, a poeira), e a tinta que brota nas
##   páginas; qualquer tecla ou clique pula;
## - o menu principal de volta (sair do jogo): já aberto, a tinta brotando;
## - a pausa: o livro chega deslizando, já aberto.
## Passar de um menu ao outro vira a folha (com a sombra dela na página de
## baixo): quem sai tira a foto (`fotografar()`, antes de trocar a tinta) e quem
## chega chama `virar(para_tras)`. Começar ou continuar o jogo: `mergulhar()`, a
## tinta da entrada escolhida se derrama e toma a tela. A ponte com os menus é o
## `Livro` de cada um.

## A textura das duas páginas (cada uma 620 × 840, como no Livro).
const TINTA := Vector2i(1240, 840)
## Uma página, em metros: um livro gigante.
const LARGURA := 0.5
const ALTURA := LARGURA * 840.0 / 620.0
const CAPA := 0.036
const MIOLO := 0.072
const TOPO := CAPA + MIOLO
const ARCO := 0.04
## Quanto a capa passa do miolo (a faixa onde corre a moldura de ferro).
const ABA := 0.046
const VIRAR := 0.95
const ABRIR := 2.3
## As linhas da tela do mundo do livro: o grão do jogo (GameRoot.target_height).
const LINHAS := 540.0

const POSICAO_CAMERA := Vector3(0.0, 1.32, 0.57)
const ALVO_CAMERA := Vector3(0.0, 0.0, 0.045)
## A abertura começa perto da capa fechada (o livro fechado ocupa a metade da
## direita), mais baixo e de lado.
const POSICAO_INICIO := Vector3(0.5, 0.78, 0.62)
const ALVO_INICIO := Vector3(0.26, 0.1, 0.0)

static var atual: Necronomicon

## O próximo menu principal abre com a abertura inteira (o jogo começando).
var abertura_pedida := false

@onready var paginas: SubViewport = $Paginas

var _menus: Array[Control] = []
var _container: SubViewportContainer
var _mundo: SubViewport
var _camera: Camera3D
var _livro: Node3D
var _esquerda: Node3D
var _lombada: Node3D
var _mat_esq: ShaderMaterial
var _mat_dir: ShaderMaterial
var _mat_folha: ShaderMaterial
var _corte: ShaderMaterial
var _folha: MeshInstance3D
var _foto: Texture2D
var _escuro: ColorRect
var _tinta: ColorRect
var _dica: Label
var _velas: Array[OmniLight3D] = []
var _chamas: Array[Node3D] = []
var _acesas: Array[float] = []
var _poeira: GPUParticles3D
var _poeira_baque: GPUParticles3D
var _abrindo: Tween
var _pronto := false
var _t := 0.0
var _olhar := Vector2.ZERO
## A câmera entre a pose da abertura (0) e a do menu (1); o mergulho (0..1).
var _viagem := 1.0
var _mergulho := 0.0
var _alvo_mergulho := Vector3.ZERO
var _tremor := 0.0
var _som_folha: AudioStream
var _som_capa: AudioStream
var _som_fosforo: AudioStream
var _som_pena: AudioStream
var _som_baque: AudioStream


func _ready() -> void:
	atual = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	paginas.size = TINTA
	paginas.transparent_bg = true
	paginas.disable_3d = true
	paginas.handle_input_locally = true
	for c in paginas.get_children():
		if c is Control:
			_menus.append(c)
	_som_folha = load("res://audio/placeholder/papel_pegar.wav")
	_som_capa = load("res://audio/placeholder/porta_rangendo.wav")
	_som_baque = load("res://audio/placeholder/pacote_chao.wav")
	_som_fosforo = load("res://audio/placeholder/fosforo.wav")
	_som_pena = load("res://audio/placeholder/pena.wav")
	_montar_mundo()
	_tinta = ColorRect.new()
	_tinta.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tinta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat_tinta := ShaderMaterial.new()
	mat_tinta.shader = load("res://shaders/tinta_espalha.gdshader")
	mat_tinta.set_shader_parameter(&"ruido", _ruido(7, 0.03))
	_tinta.material = mat_tinta
	_tinta.visible = false
	add_child(_tinta)
	_dica = Label.new()
	_dica.add_theme_font_override(&"font", load(Livro.FONTE_ITALICO))
	_dica.add_theme_color_override(&"font_color", Color(0.78, 0.7, 0.56, 0.75))
	_dica.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	_dica.add_theme_constant_override(&"shadow_offset_x", 2)
	_dica.add_theme_constant_override(&"shadow_offset_y", 2)
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dica)
	_escuro = ColorRect.new()
	_escuro.color = Color.BLACK
	_escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escuro.modulate.a = 0.0
	add_child(_escuro)
	visible = false
	_ligar(false)
	resized.connect(_ajustar_tela)
	_ajustar_tela()


func _exit_tree() -> void:
	if atual == self:
		atual = null


## A entrada já responde (a abertura acabou, ou foi pulada).
func pronto() -> bool:
	return _pronto and visible


func _ajustar_tela() -> void:
	if _container:
		_container.stretch_shrink = maxi(1, roundi(size.y / LINHAS))
	if _dica:
		var escala := size.y / 1080.0
		_dica.add_theme_font_size_override(&"font_size", maxi(14, roundi(26 * escala)))
		_dica.position = Vector2(0, size.y - 70.0 * escala)
		_dica.size = Vector2(size.x - 60.0 * escala, 40.0 * escala)


func _process(delta: float) -> void:
	var deve := _menus.any(func(m: Control) -> bool: return m.visible)
	if deve != visible:
		_mostrar(deve)
	if not visible:
		return
	_t += delta
	# As velas tremem (cada uma no seu ritmo), na medida em que estão acesas.
	for i in _velas.size():
		var tremula := 1.0 + 0.18 * sin(_t * (7.3 + i * 2.1)) * sin(_t * (3.1 + i)) + 0.07 * sin(_t * 23.0 + i * 1.7)
		_velas[i].light_energy = 1.55 * tremula * _acesas[i]
		_chamas[i].scale = Vector3(1.0, 1.0 + 0.14 * sin(_t * (9.0 + i * 3.0)), 1.0) * maxf(_acesas[i], 0.001)
	# O canto da página da direita respira na corrente de ar.
	_mat_dir.set_shader_parameter(&"brisa", (0.003 + 0.004 * maxf(0.0, sin(_t * 0.6) * sin(_t * 0.23 + 1.0))) if _pronto else 0.0)
	# A câmera: da capa ao livro aberto (a abertura), respirando, seguindo um pouco
	# o mouse, tremendo no baque, e o mergulho na página.
	var mouse := get_local_mouse_position() / maxf(1.0, size.y) - Vector2(size.x / size.y * 0.5, 0.5)
	_olhar = _olhar.lerp(mouse.clamp(Vector2(-1, -1), Vector2(1, 1)), 1.0 - exp(-2.0 * delta))
	var v := _suave(_viagem)
	var pos := POSICAO_INICIO.lerp(POSICAO_CAMERA, v)
	var alvo := ALVO_INICIO.lerp(ALVO_CAMERA, v)
	pos += Vector3(sin(_t * 0.31) * 0.006, sin(_t * 0.43) * 0.005, 0.0)
	alvo += Vector3(_olhar.x * 0.03, 0.0, _olhar.y * 0.022) * v
	if _tremor > 0.0:
		pos += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.006 * _tremor
		_tremor = maxf(0.0, _tremor - delta * 2.5)
	if _mergulho > 0.0:
		var m := _mergulho * _mergulho
		pos = pos.lerp(_alvo_mergulho + Vector3(0, 0.12, 0.03), m * 0.85)
		alvo = alvo.lerp(_alvo_mergulho, m)
	_camera.position = pos
	_camera.look_at(alvo, Vector3.UP)
	_atualizar_dica()


static func _suave(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func _atualizar_dica() -> void:
	var texto := ""
	if _pronto and _mergulho <= 0.0:
		for m in _menus:
			if m.visible:
				if m is OptionsMenu:
					texto = "Ajustar  ◂ ▸        Voltar  [Esc]"
				elif m is PauseMenu:
					texto = "Selecionar  [Enter]        Voltar ao jogo  [Esc]"
				else:
					texto = "Selecionar  [Enter]"
		# As Opções cobrem quem as abriu (o livro dele fica escondido, o menu não).
		for m in _menus:
			if m is OptionsMenu and m.visible:
				texto = "Ajustar  ◂ ▸        Voltar  [Esc]"
	_dica.text = texto


# --- Mostrar, abrir, virar ---------------------------------------------------------

func _ligar(sim: bool) -> void:
	var modo := SubViewport.UPDATE_ALWAYS if sim else SubViewport.UPDATE_DISABLED
	paginas.render_target_update_mode = modo
	_mundo.render_target_update_mode = modo
	if _poeira:
		_poeira.emitting = sim


func _mostrar(sim: bool) -> void:
	visible = sim
	_ligar(sim)
	_cursor(sim)
	if _abrindo:
		_abrindo.kill()
	if not sim:
		_pronto = false
		_mergulho = 0.0
		_tinta.visible = false
		_livro.position = Vector3.ZERO
		_livro.rotation = Vector3.ZERO
		return
	var principal := _menus.any(func(m: Control) -> bool: return m is MainMenu and m.visible)
	if principal and abertura_pedida:
		abertura_pedida = false
		_abertura()
	elif principal:
		_abrir_ja_aberto()
	else:
		_entrar_deslizando()


func _pose_aberto() -> void:
	_esquerda.rotation.z = 0.0
	_lombada.visible = false
	_arco(ARCO)
	_revelar(1.0)
	_viagem = 1.0
	_mergulho = 0.0
	for i in _acesas.size():
		_acesas[i] = 1.0


## O jogo começando: o escuro; as velas, uma e outra; a câmera se afasta da capa
## fechada; a capa se levanta, passa e cai do outro lado (o baque, a poeira); as
## páginas se assentam e a tinta brota nelas.
func _abertura() -> void:
	_pronto = false
	_esquerda.rotation.z = -PI
	_lombada.visible = true
	_arco(0.0)
	_revelar(0.0)
	_viagem = 0.0
	for i in _acesas.size():
		_acesas[i] = 0.0
	_escuro.modulate.a = 1.0
	var capa := 2.3
	var assenta := capa + ABRIR
	_abrindo = create_tween().set_parallel(true)
	_abrindo.tween_property(_escuro, ^"modulate:a", 0.0, 1.6).set_delay(0.25).set_trans(Tween.TRANS_SINE)
	for i in _velas.size():
		_abrindo.tween_callback(_acender.bind(i)).set_delay(0.3 + 0.55 * i)
	_abrindo.tween_property(self, ^"_viagem", 1.0, 3.6).set_delay(0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_abrindo.tween_callback(func() -> void: AudioDirector.play_sfx(_som_capa, -14.0)).set_delay(capa)
	_abrindo.tween_property(_esquerda, ^"rotation:z", 0.0, ABRIR).set_delay(capa).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_abrindo.tween_callback(func() -> void: _lombada.visible = false).set_delay(capa + ABRIR * 0.35)
	_abrindo.tween_callback(_baque).set_delay(assenta)
	_abrindo.tween_method(_arco, 0.0, ARCO, 0.6).set_delay(assenta).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_abrindo.tween_callback(func() -> void: AudioDirector.play_sfx(_som_pena, -12.0)).set_delay(assenta + 0.35)
	_abrindo.tween_method(_revelar, 0.0, 1.0, 1.6).set_delay(assenta + 0.35).set_trans(Tween.TRANS_SINE)
	_abrindo.tween_callback(func() -> void: _pronto = true).set_delay(assenta + 1.2)


## Qualquer tecla ou clique durante a abertura: tudo no lugar, de uma vez.
func _pular_abertura() -> void:
	if _abrindo:
		_abrindo.kill()
	_pose_aberto()
	_escuro.modulate.a = 0.0
	_pronto = true


## De volta ao menu principal (saindo do jogo): o livro já aberto, a tinta brota.
func _abrir_ja_aberto() -> void:
	_pose_aberto()
	_pronto = true
	_revelar(0.0)
	_escuro.modulate.a = 1.0
	_abrindo = create_tween().set_parallel(true)
	_abrindo.tween_property(_escuro, ^"modulate:a", 0.0, 0.5)
	_abrindo.tween_method(_revelar, 0.0, 1.0, 0.9).set_delay(0.15).set_trans(Tween.TRANS_SINE)


## A pausa: o livro aberto chega deslizando de perto dos olhos e assenta na mesa.
func _entrar_deslizando() -> void:
	_pose_aberto()
	_pronto = true
	_livro.position = Vector3(0.0, 0.05, 0.42)
	_livro.rotation = Vector3(0.12, 0.0, 0.0)
	_escuro.modulate.a = 0.7
	_abrindo = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_abrindo.tween_property(_livro, ^"position", Vector3.ZERO, 0.42)
	_abrindo.tween_property(_livro, ^"rotation", Vector3.ZERO, 0.42)
	_abrindo.tween_property(_escuro, ^"modulate:a", 0.0, 0.3)


## Uma vela se acende: o fósforo, a chama que cresce, a luz que sobe.
func _acender(i: int) -> void:
	AudioDirector.play_sfx(_som_fosforo, -10.0)
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_method(func(v: float) -> void: _acesas[i] = v, 0.0, 1.0, 0.7)


## A capa cai do outro lado: o baque, a câmera estremece, a poeira sobe das páginas.
func _baque() -> void:
	AudioDirector.play_sfx(_som_baque, -6.0)
	_tremor = 1.0
	if _poeira_baque:
		_poeira_baque.restart()
		_poeira_baque.emitting = true


func _arco(v: float) -> void:
	for m: ShaderMaterial in [_mat_esq, _mat_dir, _mat_folha, _corte]:
		m.set_shader_parameter(&"arco", v)


func _revelar(v: float) -> void:
	for m: ShaderMaterial in [_mat_esq, _mat_dir]:
		m.set_shader_parameter(&"revelar", v)


## A foto das duas páginas como estão agora (antes de quem sai trocar a tinta).
func fotografar() -> Texture2D:
	if not visible or DisplayServer.get_name() == "headless":
		_foto = null
		return null
	var img := paginas.get_texture().get_image()
	_foto = ImageTexture.create_from_image(img) if img and not img.is_empty() else null
	return _foto


## Vira uma folha (a foto tirada antes da troca). Para a frente, a da direita se
## levanta e deita na esquerda; para trás, o contrário. A folha faz sombra: na
## página que ela descobre enquanto sobe, na que ela vai cobrir enquanto desce.
func virar(para_tras := false) -> void:
	if _foto == null or not visible:
		return
	var lado := -1.0 if para_tras else 1.0
	# A página que a folha vai cobrir ainda mostra o par de antes até ela chegar.
	var coberta := _mat_dir if para_tras else _mat_esq
	var descoberta := _mat_esq if para_tras else _mat_dir
	coberta.set_shader_parameter(&"foto", _foto)
	coberta.set_shader_parameter(&"usar_foto", 1.0)
	_mat_folha.set_shader_parameter(&"foto", _foto)
	_mat_folha.set_shader_parameter(&"lado", lado)
	_mat_folha.set_shader_parameter(&"progresso", 0.0)
	_folha.visible = true
	AudioDirector.play_sfx(_som_folha, -6.0)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(p: float) -> void:
		_mat_folha.set_shader_parameter(&"progresso", p)
		var ate := absf(cos(PI * p))
		var forca := sin(PI * p)
		descoberta.set_shader_parameter(&"sombra", forca if p < 0.5 else 0.0)
		descoberta.set_shader_parameter(&"sombra_ate", ate)
		coberta.set_shader_parameter(&"sombra", forca if p >= 0.5 else 0.0)
		coberta.set_shader_parameter(&"sombra_ate", ate), 0.0, 1.0, VIRAR)
	await t.finished
	for m: ShaderMaterial in [coberta, descoberta]:
		m.set_shader_parameter(&"sombra", 0.0)
	coberta.set_shader_parameter(&"usar_foto", 0.0)
	_folha.visible = false
	_foto = null


## Começar ou continuar: a tinta da entrada escolhida se derrama pela página e
## toma a tela, e a câmera desce para dentro dela. Quem chama segue no escuro.
func mergulhar(de: Control = null) -> void:
	if not visible or DisplayServer.get_name() == "headless":
		return
	_pronto = false
	var uv := Vector2(0.75, 0.55)
	if de:
		var r := de.get_global_rect()
		uv = r.get_center() / Vector2(TINTA)
	var ponto := _livro.global_transform * _ponto_da_pagina(uv)
	_alvo_mergulho = ponto
	var tela := _camera.unproject_position(ponto) / Vector2(_mundo.size)
	var mat := _tinta.material as ShaderMaterial
	mat.set_shader_parameter(&"centro", tela)
	mat.set_shader_parameter(&"proporcao", size.x / maxf(1.0, size.y))
	mat.set_shader_parameter(&"progresso", 0.0)
	_tinta.visible = true
	AudioDirector.play_sfx(_som_pena, -8.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, ^"_mergulho", 1.0, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_method(func(p: float) -> void: mat.set_shader_parameter(&"progresso", p), 0.0, 1.0, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished


## O ponto da página (local ao livro) da tinta em `uv` (0..1 nas duas páginas).
func _ponto_da_pagina(uv: Vector2) -> Vector3:
	var x := (uv.x * 2.0 - 1.0) * LARGURA
	return Vector3(x, TOPO + ARCO * _perfil(absf(x) / LARGURA), -ALTURA / 2.0 + uv.y * ALTURA)


## Com o livro à vista, o mouse é uma pena de escrever (a ponta é o clique).
func _cursor(sim: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if sim:
		var escala := clampf(size.y / 1080.0, 0.75, 2.0)
		Input.set_custom_mouse_cursor(_pena(roundi(44 * escala)), Input.CURSOR_ARROW, Vector2(1, 1))
	else:
		Input.set_custom_mouse_cursor(null)


## A pena: a haste da ponta (cima, à esquerda) ao fim, as barbas que se abrem e
## afinam, a ponta de metal molhada de tinta.
static func _pena(n: int) -> ImageTexture:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var ponta := Vector2(1, 1)
	var fim := Vector2(n - 2, n - 2)
	var eixo := (fim - ponta).normalized()
	var lado := Vector2(-eixo.y, eixo.x)
	var comprimento := ponta.distance_to(fim)
	for y in n:
		for x in n:
			var p := Vector2(x, y) - ponta
			var t := p.dot(eixo) / comprimento
			var d := p.dot(lado)
			if t < 0.0 or t > 1.0:
				continue
			var cor := Color(0, 0, 0, 0)
			if t < 0.18:
				# A ponta de metal, escura, com a tinta.
				var meia := t / 0.18 * n * 0.045
				if absf(d) <= meia + 0.6:
					cor = Color(0.08, 0.05, 0.04) if t < 0.08 else Color(0.32, 0.27, 0.2)
			else:
				# A pena: as barbas, mais largas de um lado, em riscas.
				var u := (t - 0.18) / 0.82
				var meia := sin(clampf(u * 1.15, 0.0, 1.0) * PI) * n * (0.13 if d > 0.0 else 0.07)
				if absf(d) <= 0.8:
					cor = Color(0.25, 0.18, 0.12)
				elif absf(d) <= meia:
					var risca := 0.82 + 0.18 * sin((t * comprimento - absf(d) * 1.4) * 1.6)
					cor = Color(0.9, 0.84, 0.72) * risca
					cor.a = 1.0
					if absf(d) > meia - 1.2:
						cor = Color(0.3, 0.22, 0.15)
			img.set_pixel(x, y, cor)
	# O contorno, para a pena se ver no escuro e no papel.
	var saida := img.duplicate() as Image
	for y in n:
		for x in n:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + o
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and img.get_pixelv(q).a > 0.0:
					saida.set_pixel(x, y, Color(0.04, 0.02, 0.02, 0.85))
					break
	return ImageTexture.create_from_image(saida)


# --- A entrada: o mouse aponta para a página --------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not _pronto:
		# A abertura: uma tecla ou um clique pula; o resto espera.
		var aperto: bool = (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed) 			or (event is InputEventAction and event.pressed)
		if aperto and _mergulho <= 0.0:
			_pular_abertura()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouse:
		var ev := event.duplicate() as InputEventMouse
		var uv: Variant = _na_pagina(event.position)
		ev.position = (uv as Vector2) * Vector2(TINTA) if uv != null else Vector2(-9999, -9999)
		ev.global_position = ev.position
		paginas.push_input(ev, true)
	else:
		paginas.push_input(event)
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# No jogo, o livro escondido: as teclas (o Esc da pausa) ainda chegam aos
	# menus, depois de todo o resto.
	if visible or event is InputEventMouse:
		return
	paginas.push_input(event)
	if paginas.is_input_handled():
		get_viewport().set_input_as_handled()


## O ponto da tinta (0..1 nas duas páginas) sob `tela` (posição na tela), ou null.
func _na_pagina(tela: Vector2) -> Variant:
	var local := (tela - _container.global_position) * Vector2(_mundo.size) / _container.size
	var origem := _camera.project_ray_origin(local)
	var direcao := _camera.project_ray_normal(local)
	var inv := _livro.global_transform.affine_inverse()
	var o := inv * origem
	var d := (inv.basis * direcao).normalized()
	if absf(d.y) < 0.0001:
		return null
	# A página é arqueada: acha a altura do arco no ponto, e de novo, até assentar.
	var y := TOPO
	var p := Vector3.ZERO
	for i in 5:
		p = o + d * ((y - o.y) / d.y)
		y = TOPO + ARCO * _perfil(absf(p.x) / LARGURA)
	if absf(p.x) > LARGURA or absf(p.z) > ALTURA / 2.0:
		return null
	return Vector2((p.x + LARGURA) / (2.0 * LARGURA), (p.z + ALTURA / 2.0) / ALTURA)


static func _perfil(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return (1.0 - exp(-12.0 * u)) * (1.0 - 0.85 * u)


# --- Montagem: a cena ---------------------------------------------------------------

func _montar_mundo() -> void:
	_container = SubViewportContainer.new()
	_container.name = "_Tela"
	_container.stretch = true
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# O grão do jogo: o mesmo pontilhado e as mesmas cores do mundo (sem a
	# distorção, que é da exposição).
	var post := ShaderMaterial.new()
	post.shader = load("res://shaders/psx_post.gdshader")
	post.set_shader_parameter(&"color_levels", 40.0)
	post.set_shader_parameter(&"dither_strength", 0.85)
	post.set_shader_parameter(&"vignette", 1.35)
	_container.material = post
	add_child(_container)
	_mundo = SubViewport.new()
	_mundo.name = "_Mundo"
	_mundo.own_world_3d = true
	_mundo.process_mode = Node.PROCESS_MODE_ALWAYS
	_container.add_child(_mundo)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.004, 0.004)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.1, 0.07)
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.015, 0.01, 0.008)
	env.fog_density = 0.35
	var we := WorldEnvironment.new()
	we.environment = env
	_mundo.add_child(we)

	_camera = Camera3D.new()
	_camera.fov = 34.0
	_camera.near = 0.03
	_camera.position = POSICAO_CAMERA
	_mundo.add_child(_camera)
	_camera.look_at(ALVO_CAMERA, Vector3.UP)

	_livro = Node3D.new()
	_livro.name = "Livro"
	_mundo.add_child(_livro)
	_mesa()
	_montar_livro()
	for s in [-1.0, 1.0]:
		# Fora do quadro, dos lados: só a luz delas chega ao livro.
		_vela(Vector3(s * 1.3, 0.0, -0.35 + (0.07 if s > 0 else 0.0)), 0.3 if s < 0 else 0.22)
	# Uma luz fria, fraca, de cima e de trás: o contorno do livro no escuro.
	var lua := DirectionalLight3D.new()
	lua.light_color = Color(0.45, 0.55, 0.75)
	lua.light_energy = 0.06
	lua.rotation_degrees = Vector3(-50, 165, 0)
	_mundo.add_child(lua)
	# A luz sobre as páginas, quente, de onde estão os olhos, que morre nas bordas.
	var leitura := SpotLight3D.new()
	leitura.light_color = Color(1.0, 0.8, 0.58)
	leitura.light_energy = 0.75
	leitura.spot_range = 3.0
	leitura.spot_angle = 30.0
	leitura.spot_angle_attenuation = 1.6
	leitura.position = Vector3(0.0, 1.55, 0.6)
	_mundo.add_child(leitura)
	leitura.look_at(Vector3(0, 0, 0.02), Vector3.UP)
	_poeira = _particulas(45, 9.0, Vector3(0.75, 0.3, 0.5), Vector3(0, 0.35, 0.05), false)
	_poeira_baque = _particulas(60, 2.6, Vector3(0.5, 0.02, 0.36), Vector3(0, TOPO + 0.02, 0), true)


## A poeira na luz: grãos que boiam devagar (ou, no baque, que sobem de uma vez).
func _particulas(n: int, vida: float, caixa: Vector3, onde: Vector3, baque: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = n
	p.lifetime = vida
	p.one_shot = baque
	p.explosiveness = 0.9 if baque else 0.0
	p.preprocess = 0.0 if baque else vida
	p.position = onde
	p.visibility_aabb = AABB(-caixa * 2.0 - Vector3.ONE * 0.3, caixa * 4.0 + Vector3.ONE * 0.6)
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = caixa
	m.gravity = Vector3(0, -0.004, 0) if not baque else Vector3(0, -0.05, 0)
	m.direction = Vector3(0, 1, 0)
	m.spread = 180.0 if not baque else 60.0
	m.initial_velocity_min = 0.002 if not baque else 0.05
	m.initial_velocity_max = 0.012 if not baque else 0.18
	m.damping_min = 0.0 if not baque else 0.3
	m.damping_max = 0.0 if not baque else 0.5
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.4
	m.turbulence_noise_scale = 3.0
	m.turbulence_influence_min = 0.02
	m.turbulence_influence_max = 0.06
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.0))
	curva.add_point(Vector2(0.2, 1.0))
	curva.add_point(Vector2(0.75, 1.0))
	curva.add_point(Vector2(1.0, 0.0))
	var rampa := CurveTexture.new()
	rampa.curve = curva
	m.alpha_curve = rampa
	m.scale_min = 0.6
	m.scale_max = 1.4
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.0022, 0.0022)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.0, 0.82, 0.58, 0.3 if not baque else 0.35)
	q.material = mat
	p.draw_pass_1 = q
	p.emitting = not baque
	_mundo.add_child(p)
	return p


# --- Montagem: o livro --------------------------------------------------------------

func _montar_livro() -> void:
	var papel := _papel_velho()
	var tinta := paginas.get_texture()
	var shader_pagina: Shader = load("res://shaders/livro_pagina.gdshader")
	var ruido := _ruido(3, 0.02)
	var nova_pagina := func() -> ShaderMaterial:
		var m := ShaderMaterial.new()
		m.shader = shader_pagina
		m.set_shader_parameter(&"tinta", tinta)
		m.set_shader_parameter(&"papel", papel)
		m.set_shader_parameter(&"ruido", ruido)
		m.set_shader_parameter(&"largura", LARGURA)
		m.set_shader_parameter(&"altura", ALTURA)
		m.set_shader_parameter(&"arco", ARCO)
		return m
	_mat_esq = nova_pagina.call()
	_mat_dir = nova_pagina.call()
	_mat_folha = nova_pagina.call()
	_mat_folha.set_shader_parameter(&"virando", true)
	_corte = ShaderMaterial.new()
	_corte.shader = load("res://shaders/livro_corte.gdshader")
	_corte.set_shader_parameter(&"largura", LARGURA)
	var couro := _couro()
	var ferro := _ferro()
	var latao := StandardMaterial3D.new()
	latao.albedo_color = Color(0.42, 0.3, 0.14)
	latao.metallic = 0.85
	latao.roughness = 0.38
	# A metade da direita fica; a da esquerda gira na lombada (no alto do miolo).
	var direita := Node3D.new()
	direita.name = "Direita"
	_livro.add_child(direita)
	_esquerda = Node3D.new()
	_esquerda.name = "Esquerda"
	_esquerda.position = Vector3(0, TOPO, 0)
	_livro.add_child(_esquerda)
	for s in [1.0, -1.0]:
		var pai: Node3D = direita if s > 0 else _esquerda
		var base := 0.0 if s > 0 else -TOPO
		# A capa: a tábua de couro.
		var capa := _caixa(pai, Vector3(LARGURA + ABA, CAPA, ALTURA + ABA * 2.0), Vector3(s * (LARGURA + ABA) / 2.0, base + CAPA / 2.0, 0), couro)
		capa.name = "Capa"
		# A moldura de ferro por dentro (na faixa em volta das folhas) e por fora.
		_moldura_de_ferro(pai, s, base + CAPA, 1.0, ferro, latao)
		_moldura_de_ferro(pai, s, base, -1.0, ferro, latao)
		# Os fechos, nas duas tábuas: a dobradiça na borda e a chapa pendurada.
		for z in [-0.2, 0.2]:
			_fecho(pai, s, base, z, ferro, latao)
		# O miolo: o corte das folhas (os lados), a página por cima.
		var corte := MeshInstance3D.new()
		corte.mesh = _miolo(s, base)
		corte.material_override = _corte
		pai.add_child(corte)
		var pagina := MeshInstance3D.new()
		pagina.name = "Pagina"
		pagina.mesh = _grade(s, 32, 16)
		pagina.position.y = base + TOPO + 0.0004
		pagina.material_override = _mat_dir if s > 0 else _mat_esq
		pai.add_child(pagina)
	# A capa da frente (a da esquerda, por fora): moldura em relevo, os cravos e,
	# no meio, o medalhão de metal com o sinal.
	_ornamentos(couro, ferro, latao)
	# A fita marcadora: sai do vinco, passa pela borda de baixo e cai na mesa.
	_fita()
	# A lombada (só com o livro fechado, do lado de fora).
	_lombada = Node3D.new()
	_livro.add_child(_lombada)
	var lomb := _caixa(_lombada, Vector3(0.034, TOPO * 2.0, ALTURA + ABA * 2.0), Vector3(-0.014, TOPO, 0), couro)
	lomb.name = "Lombada"
	for k in 5:
		_caixa(_lombada, Vector3(0.012, TOPO * 2.0 + 0.004, 0.026), Vector3(-0.032, TOPO, lerpf(-ALTURA * 0.4, ALTURA * 0.4, k / 4.0)), ferro)
	# A folha que vira (deitada na direita; o shader a gira).
	_folha = MeshInstance3D.new()
	_folha.name = "Folha"
	_folha.mesh = _grade(1.0, 32, 16)
	_folha.position.y = TOPO + 0.0008
	_folha.material_override = _mat_folha
	_folha.visible = false
	_folha.extra_cull_margin = 1.0
	_livro.add_child(_folha)


## A moldura de ferro de uma tábua, na face de dentro (`face` = +1, em volta das
## folhas) ou na de fora (−1): as barras ao longo da borda, com os rebites, e as
## cantoneiras com o cravo em ponta de diamante.
func _moldura_de_ferro(pai: Node3D, s: float, y_face: float, face: float, ferro: Material, latao: Material) -> void:
	var h := 0.008
	var y := y_face + face * h / 2.0
	var meia_z := ALTURA / 2.0 + ABA
	var largura_barra := ABA - 0.01
	# A barra da borda de fora e as de cima e de baixo.
	var x_fora := s * (LARGURA + ABA - largura_barra / 2.0 - 0.003)
	_caixa(pai, Vector3(largura_barra, h, meia_z * 2.0 - 0.006), Vector3(x_fora, y, 0), ferro)
	for z in [-1.0, 1.0]:
		_caixa(pai, Vector3(LARGURA + ABA - 0.006, h, largura_barra), Vector3(s * (LARGURA + ABA) / 2.0, y, z * (meia_z - largura_barra / 2.0 - 0.003)), ferro)
	# Os rebites, de latão, em fila nas barras.
	var topo_barra := y + face * h / 2.0
	for k in 11:
		var z := lerpf(-meia_z + 0.06, meia_z - 0.06, k / 10.0)
		_rebite(pai, Vector3(x_fora, topo_barra, z), latao)
	for z in [-1.0, 1.0]:
		for k in 7:
			var x := s * lerpf(0.05, LARGURA + ABA - 0.07, k / 6.0)
			_rebite(pai, Vector3(x, topo_barra, z * (meia_z - largura_barra / 2.0 - 0.003)), latao)
	# As cantoneiras: a chapa em L, mais alta, e o cravo de diamante.
	for z in [-1.0, 1.0]:
		var canto := Vector3(s * (LARGURA + ABA - 0.04), topo_barra, z * (meia_z - 0.04))
		var chapa := 0.075
		_caixa(pai, Vector3(chapa, 0.006, 0.026), canto + Vector3(-s * (chapa - 0.08) / 2.0 - s * 0.0, face * 0.003, z * 0.027), ferro)
		_caixa(pai, Vector3(0.026, 0.006, chapa), canto + Vector3(s * 0.027, face * 0.003, -z * (chapa - 0.08) / 2.0), ferro)
		_caixa(pai, Vector3(0.05, 0.008, 0.05), canto + Vector3(0, face * 0.004, 0), ferro)
		_piramide(pai, canto + Vector3(0, face * 0.008, 0), 0.03, 0.02 * face, latao)


## Um fecho: a dobradiça presa na borda da tábua e a chapa que pende para fora,
## com a argola.
func _fecho(pai: Node3D, s: float, base: float, z: float, ferro: Material, latao: Material) -> void:
	var borda := s * (LARGURA + ABA)
	_caixa(pai, Vector3(0.026, CAPA + 0.012, 0.08), Vector3(borda + s * 0.008, base + CAPA / 2.0, z), ferro)
	for k in 3:
		_caixa(pai, Vector3(0.022, 0.022, 0.02), Vector3(borda + s * 0.028, base + CAPA * 0.5, z - 0.028 + k * 0.028), ferro if k != 1 else latao)
	var chapa := _caixa(pai, Vector3(0.11, 0.008, 0.06), Vector3(borda + s * 0.09, base + 0.006, z), ferro)
	chapa.rotation.z = s * -0.08
	_rebite(pai, Vector3(borda + s * 0.07, base + 0.012, z), latao)
	var argola := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.018
	toro.outer_radius = 0.025
	toro.rings = 12
	toro.ring_segments = 6
	argola.mesh = toro
	argola.material_override = latao
	argola.position = Vector3(borda + s * 0.155, base + 0.004, z)
	pai.add_child(argola)


## A capa da frente por fora (embaixo da metade esquerda aberta; fechado, para
## cima): a moldura em relevo, os cravos, o medalhão com o sinal.
func _ornamentos(couro: Material, ferro: Material, latao: Material) -> void:
	var y := -TOPO - 0.004
	var cx := -(LARGURA + ABA) / 2.0
	var w := LARGURA + ABA - 0.16
	var h := ALTURA + ABA * 2.0 - 0.16
	for t: Array in [[Vector3(w, 0.008, 0.02), Vector3(cx, y, -h / 2.0)], [Vector3(w, 0.008, 0.02), Vector3(cx, y, h / 2.0)],
			[Vector3(0.02, 0.008, h), Vector3(cx - w / 2.0, y, 0)], [Vector3(0.02, 0.008, h), Vector3(cx + w / 2.0, y, 0)]]:
		_caixa(_esquerda, t[0], t[1], couro)
	for k in 16:
		var a := TAU * k / 16.0
		_rebite(_esquerda, Vector3(cx, y - 0.004, 0) + Vector3(cos(a) * 0.15, 0, sin(a) * 0.15), latao)
	var disco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.115
	cil.bottom_radius = 0.12
	cil.height = 0.012
	cil.radial_segments = 24
	disco.mesh = cil
	disco.material_override = ferro
	disco.position = Vector3(cx, y - 0.002, 0)
	_esquerda.add_child(disco)
	# O sinal: uma estrela de cinco pontas, riscada no metal, com o olho no meio.
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color(0.06, 0.04, 0.03)
	for k in 5:
		var a := TAU * k / 5.0
		var b := TAU * (k + 2) / 5.0
		var p := Vector3(cos(a), 0, sin(a)) * 0.095
		var q := Vector3(cos(b), 0, sin(b)) * 0.095
		var risco := _caixa(_esquerda, Vector3(p.distance_to(q), 0.004, 0.009), Vector3(cx, y - 0.009, 0) + (p + q) / 2.0, latao)
		risco.rotation.y = -atan2(q.z - p.z, q.x - p.x)
	var olho := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.024
	esfera.height = 0.03
	olho.mesh = esfera
	olho.material_override = escuro
	olho.position = Vector3(cx, y - 0.011, 0)
	_esquerda.add_child(olho)


## A fita marcadora de veludo rubro: sai do vinco no pé da página, dobra na borda
## do miolo, desce pela frente e corre na mesa até a ponta em V.
func _fita() -> void:
	var pts: Array[Vector3] = [
		Vector3(0.006, TOPO + 0.003, ALTURA / 2.0 - 0.07),
		Vector3(0.012, TOPO + 0.003, ALTURA / 2.0 - 0.005),
		Vector3(0.02, TOPO - 0.012, ALTURA / 2.0 + 0.006),
		Vector3(0.03, CAPA + 0.004, ALTURA / 2.0 + 0.012),
		Vector3(0.045, CAPA + 0.004, ALTURA / 2.0 + ABA - 0.004),
		Vector3(0.06, 0.012, ALTURA / 2.0 + ABA + 0.03),
		Vector3(0.085, 0.003, ALTURA / 2.0 + ABA + 0.1),
		Vector3(0.11, 0.003, ALTURA / 2.0 + ABA + 0.17),
	]
	var meia := 0.013
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var lado := (b - a).cross(Vector3.UP).normalized() * meia
		if lado.length() < 0.001:
			lado = Vector3(meia, 0, 0)
		var ponta := i == pts.size() - 2
		# A ponta em V: o meio recua.
		var b_meio := b - (b - a).normalized() * 0.022 if ponta else b
		for v: Vector3 in [a - lado, b - lado, b_meio, a - lado, b_meio, a, a, b_meio, a + lado, b_meio, b + lado, a + lado]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.03, 0.025)
	mat.roughness = 0.65
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var fita := MeshInstance3D.new()
	fita.mesh = mesh
	fita.material_override = mat
	_livro.add_child(fita)


## Uma página (ou a folha que vira): uma grade deitada de x = 0 à borda (lado
## `s`: +1 à direita, −1 à esquerda), com a UV do par aberto.
static func _grade(s: float, nx: int, nz: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in nx:
		for j in nz:
			var cantos := [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]
			# Espelhada (à esquerda), a ordem inverte para a frente continuar para cima
			# (com a de trás para cima, a luz a tomava pelo avesso: a página cinzenta).
			if s < 0.0:
				cantos = [cantos[0], cantos[2], cantos[1], cantos[3], cantos[5], cantos[4]]
			for c: Vector2i in cantos:
				var a := float(c.x) / nx
				var b := float(c.y) / nz
				var x := s * a * LARGURA
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2((x + LARGURA) / (2.0 * LARGURA), b))
				st.add_vertex(Vector3(x, 0.0, -ALTURA / 2.0 + b * ALTURA))
	return st.commit()


## Os lados do miolo (a borda de fora e as de cima e de baixo), da capa ao alto
## da página; o alto sobe com o arco (COLOR.r = 1 nos vértices de cima).
static func _miolo(s: float, base: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y0 := base + CAPA
	var y1 := base + TOPO
	var nx := 24
	var parede := func(a: Vector3, b: Vector3, ua: float, ub: float) -> void:
		var vs := [[a, ua, 0.0], [b, ub, 0.0], [b, ub, 1.0], [a, ua, 0.0], [b, ub, 1.0], [a, ua, 1.0]]
		for v: Array in vs:
			var p: Vector3 = v[0]
			var alto: float = v[2]
			st.set_color(Color(alto, 0, 0))
			st.set_uv(Vector2(v[1], alto))
			st.add_vertex(Vector3(p.x, lerpf(y0, y1, alto), p.z))
	for z in [-ALTURA / 2.0, ALTURA / 2.0]:
		for i in nx:
			var a := s * LARGURA * i / nx
			var b := s * LARGURA * (i + 1) / nx
			parede.call(Vector3(a, 0, z), Vector3(b, 0, z), float(i) / nx, float(i + 1) / nx)
	for j in 12:
		var a := -ALTURA / 2.0 + ALTURA * j / 12.0
		var b := -ALTURA / 2.0 + ALTURA * (j + 1) / 12.0
		parede.call(Vector3(s * LARGURA, 0, a), Vector3(s * LARGURA, 0, b), float(j) / 12.0, float(j + 1) / 12.0)
	st.generate_normals()
	return st.commit()


func _mesa() -> void:
	var madeira := StandardMaterial3D.new()
	var ruido := FastNoiseLite.new()
	ruido.seed = 5
	ruido.frequency = 0.02
	var tex := NoiseTexture2D.new()
	tex.noise = ruido
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var g := Gradient.new()
	g.set_color(0, Color(0.035, 0.02, 0.014))
	g.set_color(1, Color(0.11, 0.065, 0.04))
	tex.color_ramp = g
	madeira.albedo_texture = tex
	madeira.uv1_scale = Vector3(3, 0.6, 1)
	madeira.roughness = 0.75
	_caixa(_livro, Vector3(3.0, 0.08, 2.0), Vector3(0, -0.04, 0.1), madeira)


## Uma vela grossa num prato de latão, a chama e a luz dela.
func _vela(onde: Vector3, alto: float) -> void:
	var cera := StandardMaterial3D.new()
	cera.albedo_color = Color(0.8, 0.73, 0.58)
	cera.roughness = 0.5
	var latao := StandardMaterial3D.new()
	latao.albedo_color = Color(0.45, 0.33, 0.16)
	latao.metallic = 0.8
	latao.roughness = 0.35
	var prato := MeshInstance3D.new()
	var cp := CylinderMesh.new()
	cp.top_radius = 0.09
	cp.bottom_radius = 0.1
	cp.height = 0.015
	prato.mesh = cp
	prato.material_override = latao
	prato.position = onde + Vector3(0, 0.0075, 0)
	_livro.add_child(prato)
	var corpo := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.035
	cc.bottom_radius = 0.038
	cc.height = alto
	cc.radial_segments = 12
	corpo.mesh = cc
	corpo.material_override = cera
	corpo.position = onde + Vector3(0, 0.015 + alto / 2.0, 0)
	_livro.add_child(corpo)
	# A cera escorrida.
	for k in 4:
		var a := TAU * k / 4.0 + 0.6
		_caixa(_livro, Vector3(0.012, alto * (0.3 + 0.15 * k), 0.012), onde + Vector3(cos(a) * 0.034, 0.015 + alto * (1.0 - (0.3 + 0.15 * k) / 2.0), sin(a) * 0.034), cera)
	var topo := onde + Vector3(0, 0.015 + alto, 0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.albedo_texture = load("res://art/textures/chama.png")
	mat.albedo_color = Color(1.6, 1.2, 0.8)
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.07)
	q.center_offset = Vector3(0, 0.03, 0)
	q.material = mat
	var chama := MeshInstance3D.new()
	chama.mesh = q
	chama.position = topo
	chama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_livro.add_child(chama)
	_chamas.append(chama)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.62, 0.32)
	luz.light_energy = 1.55
	luz.omni_range = 3.8
	luz.omni_attenuation = 1.2
	luz.shadow_enabled = true
	luz.position = topo + Vector3(0, 0.06, 0)
	_livro.add_child(luz)
	_velas.append(luz)
	_acesas.append(1.0)


func _caixa(pai: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)
	return mi


func _rebite(pai: Node3D, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.0055
	esfera.height = 0.007
	esfera.radial_segments = 8
	esfera.rings = 3
	mi.mesh = esfera
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)


## Uma ponta de diamante (pirâmide de quatro faces); `alto` negativo aponta para baixo.
func _piramide(pai: Node3D, pos: Vector3, base: float, alto: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.0
	cil.bottom_radius = base * 0.7071
	cil.height = absf(alto)
	cil.radial_segments = 4
	cil.rings = 1
	mi.mesh = cil
	mi.material_override = mat
	mi.position = pos + Vector3(0, alto / 2.0, 0)
	mi.rotation = Vector3(PI if alto < 0.0 else 0.0, PI / 4.0, 0)
	pai.add_child(mi)


## O couro da capa: escuro, quase negro, gasto em manchas, com o grão.
static func _couro() -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.seed = 13
	ruido.frequency = 0.035
	ruido.fractal_octaves = 5
	var tex := NoiseTexture2D.new()
	tex.noise = ruido
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var g := Gradient.new()
	g.set_color(0, Color(0.03, 0.016, 0.014))
	g.set_color(1, Color(0.16, 0.07, 0.05))
	tex.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(3, 3, 3)
	m.roughness = 0.58
	return m


## O ferro da moldura: escuro, com o brilho gasto nas arestas.
static func _ferro() -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.seed = 21
	ruido.frequency = 0.08
	ruido.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.noise = ruido
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	var g := Gradient.new()
	g.set_color(0, Color(0.06, 0.055, 0.05))
	g.set_color(1, Color(0.26, 0.23, 0.2))
	tex.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(8, 8, 8)
	m.metallic = 0.8
	m.roughness = 0.48
	return m


static func _ruido(semente: int, frequencia: float) -> Texture2D:
	var r := FastNoiseLite.new()
	r.seed = semente
	r.frequency = frequencia
	r.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.noise = r
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.normalize = true
	tex.generate_mipmaps = true
	return tex


## O papel velho: amarelado, manchado de umidade, com pintas de mofo (as fibras
## são do shader da página).
static func _papel_velho() -> Texture2D:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var manchas := FastNoiseLite.new()
	manchas.seed = 11
	manchas.frequency = 0.012
	manchas.fractal_octaves = 5
	var grao := FastNoiseLite.new()
	grao.seed = 12
	grao.frequency = 0.35
	var base := Color(0.84, 0.74, 0.55)
	var mancha := Color(0.55, 0.38, 0.2)
	for y in n:
		for x in n:
			var m := manchas.get_noise_2d(x, y)
			var c := base * (0.92 + 0.11 * m + 0.05 * grao.get_noise_2d(x, y))
			if m > 0.25:
				c = c.lerp(mancha, minf((m - 0.25) * 1.1, 0.42))
			img.set_pixel(x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 45:
		var c := Vector2(rng.randf() * n, rng.randf() * n)
		var r := rng.randf_range(1.0, 4.0)
		var forca := rng.randf_range(0.25, 0.6)
		for y in range(int(c.y - r), int(c.y + r) + 1):
			for x in range(int(c.x - r), int(c.x + r) + 1):
				var d := Vector2(x, y).distance_to(c) / r
				if d < 1.0:
					var px := Vector2i(posmod(x, n), posmod(y, n))
					img.set_pixelv(px, img.get_pixelv(px).lerp(Color(0.42, 0.27, 0.13), (1.0 - d) * forca))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
