class_name Necronomicon
extends Control
## O livro dos menus (playtest 7: "o menu deve se assemelhar mais com o de
## Castlevania: Lords of Shadow 2 [...] é o Necronomicon afinal. Capa pesada,
## livro gigante, folhas velhas"): um tomo enorme, aberto sobre a mesa, à luz de
## duas velas, em 3D. As páginas são a tinta dos menus (MainMenu, PauseMenu,
## OptionsMenu), que moram no SubViewport filho `Paginas` (as duas páginas lado a
## lado) e são impressas no papel velho (shaders/livro_pagina.gdshader).
##
## O mouse aponta para o livro: o raio da câmera acha o ponto na página e o
## evento vai para `Paginas` nesse ponto; teclado e controle vão direto. Com o
## livro escondido (no jogo), as teclas ainda passam por `Paginas`, depois de
## todo o resto (o Esc que abre a pausa).
##
## Aparece sozinho quando um dos menus está visível: o menu principal com a capa
## se abrindo; a pausa, já aberto. Passar de um menu ao outro vira a folha: quem
## sai tira a foto (`fotografar()`, antes de trocar a tinta) e quem chega chama
## `virar(para_tras)`. A ponte com os menus é o `Livro` de cada um.

## A textura das duas páginas (cada uma 620 × 840, como no Livro).
const TINTA := Vector2i(1240, 840)
## Uma página, em metros: um livro gigante.
const LARGURA := 0.5
const ALTURA := LARGURA * 840.0 / 620.0
const CAPA := 0.03
const MIOLO := 0.075
const TOPO := CAPA + MIOLO
const ARCO := 0.04
## Quanto a capa passa do miolo.
const ABA := 0.03
const VIRAR := 0.85
const ABRIR := 2.2

static var atual: Necronomicon

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
var _velas: Array[OmniLight3D] = []
var _chamas: Array[Node3D] = []
var _abrindo: Tween
var _t := 0.0
var _olhar := Vector2.ZERO
var _som_folha: AudioStream
var _som_capa: AudioStream


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
	_som_capa = load("res://audio/placeholder/gaveta.wav")
	_montar_mundo()
	_escuro = ColorRect.new()
	_escuro.color = Color.BLACK
	_escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escuro.modulate.a = 0.0
	add_child(_escuro)
	visible = false
	_ligar(false)


func _exit_tree() -> void:
	if atual == self:
		atual = null


func _process(delta: float) -> void:
	var deve := _menus.any(func(m: Control) -> bool: return m.visible)
	if deve != visible:
		_mostrar(deve)
	if not visible:
		return
	_t += delta
	# As velas tremem; a câmera respira e segue um pouco o mouse.
	for i in _velas.size():
		_velas[i].light_energy = 1.9 + 0.35 * sin(_t * (7.3 + i * 2.1)) * sin(_t * (3.1 + i)) + 0.12 * sin(_t * 23.0 + i)
		_chamas[i].scale = Vector3(1.0, 1.0 + 0.12 * sin(_t * (9.0 + i * 3.0)), 1.0)
	var mouse := get_local_mouse_position() / maxf(1.0, size.y) - Vector2(size.x / size.y * 0.5, 0.5)
	_olhar = _olhar.lerp(mouse.clamp(Vector2(-1, -1), Vector2(1, 1)), 1.0 - exp(-2.0 * delta))
	_camera.position = POSICAO_CAMERA + Vector3(sin(_t * 0.31) * 0.006, sin(_t * 0.43) * 0.005, 0.0)
	_camera.look_at(ALVO_CAMERA + Vector3(_olhar.x * 0.025, 0.0, _olhar.y * 0.02), Vector3.UP)


# --- Mostrar, abrir, virar ---------------------------------------------------------

func _ligar(sim: bool) -> void:
	var modo := SubViewport.UPDATE_ALWAYS if sim else SubViewport.UPDATE_DISABLED
	paginas.render_target_update_mode = modo
	_mundo.render_target_update_mode = modo


func _mostrar(sim: bool) -> void:
	visible = sim
	_ligar(sim)
	if not sim:
		if _abrindo:
			_abrindo.kill()
		return
	var principal := _menus.any(func(m: Control) -> bool: return m is MainMenu and m.visible)
	if principal:
		_abrir_a_capa()
	else:
		_pose_aberto()
		_escuro.modulate.a = 1.0
		var t := create_tween()
		t.tween_property(_escuro, ^"modulate:a", 0.0, 0.35)


func _pose_aberto() -> void:
	_esquerda.rotation.z = 0.0
	_lombada.visible = false
	_arco(ARCO)


## O livro chega fechado, a capa pesada para cima; ela se levanta na lombada e
## deita do outro lado, e as páginas se assentam.
func _abrir_a_capa() -> void:
	if _abrindo:
		_abrindo.kill()
	_esquerda.rotation.z = -PI
	_lombada.visible = true
	_arco(0.0)
	_escuro.modulate.a = 1.0
	_abrindo = create_tween()
	_abrindo.tween_property(_escuro, ^"modulate:a", 0.0, 0.8)
	_abrindo.tween_interval(0.5)
	_abrindo.tween_callback(func() -> void: AudioDirector.play_sfx(_som_capa, -8.0))
	_abrindo.tween_property(_esquerda, ^"rotation:z", 0.0, ABRIR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_abrindo.parallel().tween_callback(func() -> void: _lombada.visible = false).set_delay(ABRIR * 0.3)
	_abrindo.tween_method(_arco, 0.0, ARCO, 0.5).set_trans(Tween.TRANS_SINE)


func _arco(v: float) -> void:
	for m: ShaderMaterial in [_mat_esq, _mat_dir, _mat_folha, _corte]:
		m.set_shader_parameter(&"arco", v)


## A foto das duas páginas como estão agora (antes de quem sai trocar a tinta).
func fotografar() -> Texture2D:
	if not visible or DisplayServer.get_name() == "headless":
		_foto = null
		return null
	var img := paginas.get_texture().get_image()
	_foto = ImageTexture.create_from_image(img) if img and not img.is_empty() else null
	return _foto


## Vira uma folha (a foto tirada antes da troca). Para a frente, a da direita se
## levanta e deita na esquerda; para trás, o contrário.
func virar(para_tras := false) -> void:
	if _foto == null or not visible:
		return
	var lado := -1.0 if para_tras else 1.0
	# A página que a folha vai cobrir ainda mostra o par de antes até ela chegar.
	var coberta := _mat_dir if para_tras else _mat_esq
	coberta.set_shader_parameter(&"foto", _foto)
	coberta.set_shader_parameter(&"usar_foto", 1.0)
	_mat_folha.set_shader_parameter(&"foto", _foto)
	_mat_folha.set_shader_parameter(&"lado", lado)
	_mat_folha.set_shader_parameter(&"progresso", 0.0)
	_folha.visible = true
	AudioDirector.play_sfx(_som_folha, -6.0)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(p: float) -> void: _mat_folha.set_shader_parameter(&"progresso", p), 0.0, 1.0, VIRAR)
	await t.finished
	coberta.set_shader_parameter(&"usar_foto", 0.0)
	_folha.visible = false
	_foto = null


# --- A entrada: o mouse aponta para a página --------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
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


# --- Montagem ------------------------------------------------------------------------

const POSICAO_CAMERA := Vector3(0.0, 1.3, 0.84)
const ALVO_CAMERA := Vector3(0.0, 0.0, 0.02)


func _montar_mundo() -> void:
	_container = SubViewportContainer.new()
	_container.name = "_Tela"
	_container.stretch = true
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	_mundo = SubViewport.new()
	_mundo.name = "_Mundo"
	_mundo.own_world_3d = true
	_mundo.msaa_3d = Viewport.MSAA_4X
	_mundo.process_mode = Node.PROCESS_MODE_ALWAYS
	_container.add_child(_mundo)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.009, 0.008)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.11, 0.08)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.015, 0.012)
	env.fog_density = 0.18
	var we := WorldEnvironment.new()
	we.environment = env
	_mundo.add_child(we)

	_camera = Camera3D.new()
	_camera.fov = 36.0
	_camera.near = 0.05
	_camera.position = POSICAO_CAMERA
	_mundo.add_child(_camera)
	_camera.look_at(ALVO_CAMERA, Vector3.UP)

	_livro = Node3D.new()
	_livro.name = "Livro"
	_mundo.add_child(_livro)
	_mesa()
	_montar_livro()
	for s in [-1.0, 1.0]:
		_vela(Vector3(s * 0.86, 0.0, -0.5 + (0.06 if s > 0 else 0.0)), 0.3 if s < 0 else 0.24)
	# Uma luz fria, fraca, de cima e de trás: o contorno do livro no escuro.
	var lua := DirectionalLight3D.new()
	lua.light_color = Color(0.5, 0.58, 0.75)
	lua.light_energy = 0.05
	lua.rotation_degrees = Vector3(-55, 160, 0)
	_mundo.add_child(lua)
	# A luz sobre as páginas, quente e baixa, de onde estão os olhos.
	var leitura := SpotLight3D.new()
	leitura.light_color = Color(1.0, 0.82, 0.6)
	leitura.light_energy = 1.2
	leitura.spot_range = 3.0
	leitura.spot_angle = 38.0
	leitura.spot_attenuation = 0.6
	leitura.position = Vector3(0.0, 1.5, 0.55)
	_mundo.add_child(leitura)
	leitura.look_at(Vector3(0, 0, 0), Vector3.UP)


func _montar_livro() -> void:
	var papel := _papel_velho()
	var tinta := paginas.get_texture()
	var shader_pagina: Shader = load("res://shaders/livro_pagina.gdshader")
	var nova_pagina := func() -> ShaderMaterial:
		var m := ShaderMaterial.new()
		m.shader = shader_pagina
		m.set_shader_parameter(&"tinta", tinta)
		m.set_shader_parameter(&"papel", papel)
		m.set_shader_parameter(&"largura", LARGURA)
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
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.3, 0.23, 0.14)
	metal.metallic = 0.75
	metal.roughness = 0.55

	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.1, 0.09, 0.08)
	ferro.metallic = 0.6
	ferro.roughness = 0.7
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
		# A capa: a tábua de couro, os cantos de metal.
		var capa := _caixa(pai, Vector3(LARGURA + ABA, CAPA, ALTURA + ABA * 2.0), Vector3(s * (LARGURA + ABA) / 2.0, base + CAPA / 2.0, 0), couro)
		capa.name = "Capa"
		for z in [-1.0, 1.0]:
			# As cantoneiras: um L de metal em cada canto de fora da capa, por dentro
			# (na aba que passa do miolo) e por fora (que se vê com o livro fechado).
			var cx: float = s * (LARGURA + ABA - 0.035)
			var cz: float = z * (ALTURA / 2.0 + ABA - 0.035)
			for y: float in [base + CAPA + 0.0035, base - 0.0035]:
				_caixa(pai, Vector3(0.07, 0.007, 0.02), Vector3(cx, y, z * (ALTURA / 2.0 + ABA - 0.01)), metal)
				_caixa(pai, Vector3(0.02, 0.007, 0.07), Vector3(s * (LARGURA + ABA - 0.01), y, cz), metal)
		# O miolo: o corte das folhas (os lados), a página por cima.
		var corte := MeshInstance3D.new()
		corte.mesh = _miolo(s, base)
		corte.material_override = _corte
		pai.add_child(corte)
		var pagina := MeshInstance3D.new()
		pagina.name = "Pagina"
		pagina.mesh = _grade(s, 28, 12)
		pagina.position.y = base + TOPO + 0.0004
		pagina.material_override = _mat_dir if s > 0 else _mat_esq
		pai.add_child(pagina)
	# A capa da frente (a da esquerda, por fora): moldura em relevo, os cravos e,
	# no meio, o medalhão de metal com o sinal.
	_ornamentos(couro, metal)
	# Os fechos: as correias de couro que pendem da capa da direita, com as
	# fivelas; na da esquerda, as chapas onde elas prendem.
	for z in [-0.18, 0.18]:
		var correia := _caixa(direita, Vector3(0.2, 0.008, 0.05), Vector3(LARGURA + ABA + 0.09, 0.004, z), couro)
		correia.rotation.z = -0.05
		_caixa(direita, Vector3(0.05, 0.012, 0.07), Vector3(LARGURA + ABA + 0.19, 0.007, z), ferro)
		_caixa(_esquerda, Vector3(0.05, 0.01, 0.07), Vector3(-(LARGURA + ABA) + 0.02, -TOPO - 0.004, z), metal)
	# As fitas marcadoras, saindo do pé do vinco.
	for k in 2:
		var fita := StandardMaterial3D.new()
		fita.albedo_color = [Color(0.45, 0.04, 0.03), Color(0.08, 0.06, 0.06)][k]
		fita.roughness = 0.8
		var f := _caixa(direita, Vector3(0.018, 0.002, 0.2), Vector3(0.012 + k * 0.03, 0.002, ALTURA / 2.0 + ABA + 0.08), fita)
		f.rotation.y = 0.12 - k * 0.2
	# A lombada (só com o livro fechado, do lado de fora).
	_lombada = Node3D.new()
	_livro.add_child(_lombada)
	var lomb := _caixa(_lombada, Vector3(0.03, TOPO * 2.0, ALTURA + ABA * 2.0), Vector3(-0.012, TOPO, 0), couro)
	lomb.name = "Lombada"
	for k in 5:
		_caixa(_lombada, Vector3(0.012, TOPO * 2.0, 0.025), Vector3(-0.03, TOPO, lerpf(-ALTURA * 0.4, ALTURA * 0.4, k / 4.0)), couro)
	# A folha que vira (deitada na direita; o shader a gira).
	_folha = MeshInstance3D.new()
	_folha.name = "Folha"
	_folha.mesh = _grade(1.0, 28, 12)
	_folha.position.y = TOPO + 0.0008
	_folha.material_override = _mat_folha
	_folha.visible = false
	_folha.extra_cull_margin = 1.0
	_livro.add_child(_folha)


## A capa da frente por fora (embaixo da metade esquerda aberta; fechado, para
## cima): a moldura em relevo, os cravos, o medalhão com o sinal.
func _ornamentos(couro: Material, metal: Material) -> void:
	var y := -TOPO - 0.004
	var cx := -(LARGURA + ABA) / 2.0
	var w := LARGURA + ABA - 0.1
	var h := ALTURA + ABA * 2.0 - 0.1
	for t: Array in [[Vector3(w, 0.008, 0.02), Vector3(cx, y, -h / 2.0)], [Vector3(w, 0.008, 0.02), Vector3(cx, y, h / 2.0)],
			[Vector3(0.02, 0.008, h), Vector3(cx - w / 2.0, y, 0)], [Vector3(0.02, 0.008, h), Vector3(cx + w / 2.0, y, 0)]]:
		_caixa(_esquerda, t[0], t[1], couro)
	for k in 12:
		var a := TAU * k / 12.0
		_caixa(_esquerda, Vector3(0.016, 0.012, 0.016), Vector3(cx, y - 0.002, 0) + Vector3(cos(a) * 0.13, 0, sin(a) * 0.13), metal)
	var disco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.1
	cil.bottom_radius = 0.1
	cil.height = 0.01
	cil.radial_segments = 24
	disco.mesh = cil
	disco.material_override = metal
	disco.position = Vector3(cx, y - 0.002, 0)
	_esquerda.add_child(disco)
	# O sinal: uma estrela de cinco pontas, riscada no metal, com o olho no meio.
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color(0.08, 0.05, 0.03)
	for k in 5:
		var a := TAU * k / 5.0
		var b := TAU * (k + 2) / 5.0
		var p := Vector3(cos(a), 0, sin(a)) * 0.085
		var q := Vector3(cos(b), 0, sin(b)) * 0.085
		var risco := _caixa(_esquerda, Vector3(p.distance_to(q), 0.004, 0.008), Vector3(cx, y - 0.008, 0) + (p + q) / 2.0, escuro)
		risco.rotation.y = -atan2(q.z - p.z, q.x - p.x)
	var olho := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.022
	esfera.height = 0.03
	olho.mesh = esfera
	olho.material_override = escuro
	olho.position = Vector3(cx, y - 0.01, 0)
	_esquerda.add_child(olho)


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
	g.set_color(0, Color(0.07, 0.04, 0.025))
	g.set_color(1, Color(0.2, 0.12, 0.07))
	tex.color_ramp = g
	madeira.albedo_texture = tex
	madeira.uv1_scale = Vector3(3, 0.6, 1)
	madeira.roughness = 0.7
	_caixa(_livro, Vector3(3.0, 0.08, 2.0), Vector3(0, -0.04, 0.1), madeira)


## Uma vela grossa num prato de latão, a chama e a luz dela.
func _vela(onde: Vector3, alto: float) -> void:
	var cera := StandardMaterial3D.new()
	cera.albedo_color = Color(0.82, 0.76, 0.62)
	cera.roughness = 0.5
	cera.subsurf_scatter_enabled = false
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
	mat.albedo_color = Color(1.4, 1.1, 0.8)
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
	luz.light_color = Color(1.0, 0.66, 0.36)
	luz.light_energy = 2.0
	luz.omni_range = 3.2
	luz.omni_attenuation = 1.1
	luz.shadow_enabled = true
	luz.position = topo + Vector3(0, 0.06, 0)
	_livro.add_child(luz)
	_velas.append(luz)


func _caixa(pai: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)
	return mi


## O couro da capa: escuro, quase negro, gasto em manchas.
static func _couro() -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.seed = 13
	ruido.frequency = 0.03
	ruido.fractal_octaves = 5
	var tex := NoiseTexture2D.new()
	tex.noise = ruido
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.025, 0.02))
	g.set_color(1, Color(0.22, 0.1, 0.07))
	tex.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(3, 3, 3)
	m.roughness = 0.62
	return m


## O papel velho: amarelado, manchado de umidade, com pintas de mofo.
static func _papel_velho() -> Texture2D:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var manchas := FastNoiseLite.new()
	manchas.seed = 11
	manchas.frequency = 0.012
	manchas.fractal_octaves = 4
	var grao := FastNoiseLite.new()
	grao.seed = 12
	grao.frequency = 0.35
	var base := Color(0.86, 0.78, 0.6)
	var mancha := Color(0.55, 0.4, 0.22)
	for y in n:
		for x in n:
			var m := manchas.get_noise_2d(x, y)
			var c := base * (0.93 + 0.1 * m + 0.05 * grao.get_noise_2d(x, y))
			if m > 0.3:
				c = c.lerp(mancha, minf((m - 0.3) * 1.2, 0.45))
			img.set_pixel(x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 40:
		var c := Vector2(rng.randf() * n, rng.randf() * n)
		var r := rng.randf_range(1.0, 4.0)
		for y in range(int(c.y - r), int(c.y + r) + 1):
			for x in range(int(c.x - r), int(c.x + r) + 1):
				var d := Vector2(x, y).distance_to(c) / r
				if d < 1.0:
					var px := Vector2i(posmod(x, n), posmod(y, n))
					img.set_pixelv(px, img.get_pixelv(px).lerp(Color(0.45, 0.3, 0.15), (1.0 - d) * 0.55))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
