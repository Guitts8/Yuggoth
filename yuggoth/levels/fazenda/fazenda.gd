class_name Fazenda
extends Node3D
## A fazenda de Henry Akeley, na encosta da Dark Mountain (docs/PLANO_FAZENDA.md).
## A mesma planta serve ao Interlúdio (habitada, setembro de 1928, jogando como
## Akeley) e ao Ato III (abandonada, Wilmarth).
##
## F2, o entardecer de 2 de setembro: o sol baixo a oeste vai para trás da
## montanha, o quintal escurece e o céu passa do laranja ao crepúsculo
## (`entardecer`, 0 → 1 em `duracao_entardecer`). Vinda do escritório (a flag
## `interludio`, posta quando a última carta é postada), a tinta da carta cai no
## quintal (TintaTransicao.revelar): Akeley está diante do canil com o balde de
## ração. F5: a rotina do entardecer (`Rotina`); feita, o sol se põe. F6: a
## preparação para a noite (`Preparacao`). F7: a noite do telhado (`NoiteTelhado`),
## e no escuro, com os cães calados, a demo acaba (`linha_fim`).
## Pelo Shift+F4 de teste, a fazenda é só para andar.
##
## Cena gerada por tools/gerar_fazenda.gd.

@export var som: AudioStream
## O entardecer com pássaros (o único momento calmo da fazenda: a regra dos
## pássaros); param de uma vez no fim da rotina (Rotina.som_sem_passaros).
@export var som_passaros: AudioStream
@export var linha_fim: NarrationLine
## A primeira fala de Akeley, quando o corpo se mexe (ou logo depois da descida).
@export var linha_inicio: NarrationLine
## Sem a noite do telhado na cena: segundos depois da preparação antes do fim.
@export var fim_provisorio := 30.0
## Segundos do sol baixo ao crepúsculo.
@export var duracao_entardecer := 180.0
## Até onde o sol desce enquanto a rotina não acaba (o crepúsculo espera por ela).
@export var teto_da_rotina := 0.72

@export_group("Akeley")
## O corpo é outro (GDD §5.1a): mais lento, ofegante.
@export var akeley_passo := 1.45
@export var akeley_respiracao := 1.0

@export_group("A descida do céu")
## A chegada do Interlúdio (playtest 10: "uma transição que vem do céu até dar na
## visão de Akeley"): a câmera começa alta sobre o vale, a leste, olhando o
## poente — o mesmo céu da tinta —, e desce num plano só até os olhos dele.
@export var duracao_descida := 17.0
@export var descida_inicio := Vector3(95.0, 120.0, 10.0)
## Os dois pontos de controle do caminho (Bézier até os olhos de Akeley).
@export var descida_c1 := Vector3(55.0, 50.0, 0.0)
@export var descida_c2 := Vector3(16.0, 6.0, -9.0)
## Para onde se olha no começo (o céu do poente, alto) e no meio (a fazenda ao pé
## da montanha).
@export var olhar_inicio := Vector3(-400.0, 540.0, -40.0)
@export var olhar_meio := Vector3(-24.0, 3.0, -18.0)

@export_group("Entardecer: começo e fim")
@export var sol_energia := Vector2(1.3, 0.0)
@export var sol_cor := Color(1.0, 0.62, 0.36)
@export var ceu_alto: Array[Color] = [Color(0.16, 0.18, 0.34), Color(0.035, 0.045, 0.1)]
@export var ceu_horizonte: Array[Color] = [Color(0.88, 0.5, 0.3), Color(0.36, 0.2, 0.19)]
@export var neblina: Array[Color] = [Color(0.62, 0.46, 0.38), Color(0.12, 0.12, 0.17)]
@export var ambiente := Vector2(0.5, 0.16)

## 0 = o sol baixo; 1 = o crepúsculo.
var entardecer := 0.0
## O entardecer não passa disto (a rotina o segura; depois, 1).
var teto := 1.0
## Depois do crepúsculo, a noite (0 → 1): o céu quase preto, a névoa escura, a luz
## só dos lampiões. A preparação a leva a `noite_da_preparacao`; a noite do
## telhado (F7), a 1.
var noite := 0.0
var _noite_alvo := 0.0
@export var noite_da_preparacao := 0.8
@export var duracao_noite := 120.0
## A descida do céu em curso (a câmera não é a de Akeley).
var descendo := false
var _env: Environment
## As luzes de rebatimento dos cômodos (gerar_fazenda._acabamento_interior) e a
## energia de cada uma de dia.
var _luzes_de_dentro: Dictionary[Light3D, float] = {}
var _ceu: ProceduralSkyMaterial
var _aplicado := -1.0
var _camera_ceu: Camera3D
## O desvio do mouse durante a descida (a cabeça nunca presa).
var _desvio := Vector2.ZERO

@onready var player: Player = $Player
@onready var sol: DirectionalLight3D = $Sol
@onready var balde: NaMao = $Balde
@onready var rotina: Rotina = get_node_or_null(^"Rotina") as Rotina
@onready var preparacao: Preparacao = get_node_or_null(^"Preparacao") as Preparacao
@onready var noite_telhado: NoiteTelhado = get_node_or_null(^"NoiteTelhado") as NoiteTelhado


func _ready() -> void:
	player.lamp.available = false
	# O Environment é recurso da cena (compartilhado com a próxima instância):
	# o entardecer mexe numa cópia.
	var we := $WorldEnvironment as WorldEnvironment
	_env = we.environment.duplicate(true)
	we.environment = _env
	_ceu = _env.sky.sky_material as ProceduralSkyMaterial
	_capim()
	var dentro := get_node_or_null(^"LuzesDeDentro")
	if dentro:
		for l: Light3D in dentro.get_children():
			_luzes_de_dentro[l] = l.light_energy
	_aplicar(0.0)
	var akeley := GameState.has_flag(&"interludio")
	var ambiente_som := som_passaros if akeley and som_passaros else som
	if ambiente_som:
		AudioDirector.play_ambience(ambiente_som)
	balde.visible = akeley
	balde.process_mode = Node.PROCESS_MODE_INHERIT if akeley else Node.PROCESS_MODE_DISABLED
	balde.camera = player.camera
	var caes := get_node_or_null(^"Caes") as Matilha
	if caes:
		caes.balde = balde
	if akeley:
		_ser_akeley()
		_interludio()


func _exit_tree() -> void:
	Narrator.voz = Narrator.Voz.WILMARTH
	# Saindo no meio do cheiro da noite do telhado, a imagem não fica turva.
	GameState.set_value(&"sonho", 0.0)


## O corpo é outro (GDD §5.1a): mais lento, ofegante; sem dossiê; quem narra é ele.
func _ser_akeley() -> void:
	player.walk_speed = akeley_passo
	player.bob_frequency = 4.6
	player.bob_amount = 0.034
	player.respiracao = akeley_respiracao
	Narrator.voz = Narrator.Voz.AKELEY
	add_to_group(&"sem_dossie")


func _process(delta: float) -> void:
	# Passado o teto (a rotina acabou), o crepúsculo vem mais depressa.
	var passo := delta / duracao_entardecer * (1.0 if teto < 1.0 or entardecer < teto_da_rotina else 4.0)
	entardecer = minf(teto, entardecer + passo)
	if entardecer >= 1.0:
		noite = move_toward(noite, _noite_alvo, delta / duracao_noite)
	# O céu refaz a radiância quando muda: só a cada passo visível.
	if absf(entardecer + noite - _aplicado) > 0.004:
		_aplicar(entardecer)


func _aplicar(p: float) -> void:
	_aplicado = p + noite
	var some := smoothstep(0.0, 0.6, p)
	sol.light_energy = lerpf(sol_energia.x, sol_energia.y, some)
	sol.light_color = sol_cor.lerp(Color(0.9, 0.42, 0.3), some)
	sol.visible = sol.light_energy > 0.01
	var n := smoothstep(0.0, 1.0, noite)
	_ceu.sky_top_color = ceu_alto[0].lerp(ceu_alto[1], p).lerp(Color(0.008, 0.01, 0.02), n)
	_ceu.sky_horizon_color = ceu_horizonte[0].lerp(ceu_horizonte[1], smoothstep(0.2, 1.0, p)).lerp(Color(0.03, 0.03, 0.045), n)
	_ceu.ground_horizon_color = _ceu.sky_horizon_color.darkened(0.5)
	_env.fog_light_color = neblina[0].lerp(neblina[1], p).lerp(Color(0.02, 0.022, 0.03), n)
	_env.ambient_light_energy = lerpf(ambiente.x, ambiente.y, p) * lerpf(1.0, 0.25, n)
	# O rebatimento dentro de casa acompanha o dia que entra pelas janelas (de
	# noite, só os lampiões).
	for l: Light3D in _luzes_de_dentro:
		l.light_energy = _luzes_de_dentro[l] * lerpf(1.0, 0.35, some) * lerpf(1.0, 0.04, n)


## O Interlúdio na demo, por enquanto: a descida do céu, um tempo no quintal ao
## entardecer, e o fim.
func _interludio() -> void:
	# A troca de fase pausa a árvore; a descida começa já no primeiro quadro (a
	# tinta se desfaz por cima dela).
	await _descida()
	if not is_inside_tree():
		return
	_primeira_fala()
	# A rotina do entardecer (F5); o sol espera por ela.
	if rotina:
		teto = teto_da_rotina
		rotina.comecar()
		await rotina.terminou
		if not is_inside_tree():
			return
		teto = 1.0
	# A preparação para a noite (F6), no crepúsculo; a noite cai enquanto isso.
	if preparacao:
		_noite_alvo = noite_da_preparacao
		preparacao.comecar(self)
		await preparacao.terminou
		if not is_inside_tree():
			return
	# A noite do telhado (F7): a espera, o telhado, as balas, os tiros; acaba no
	# escuro, com os cães calados.
	if noite_telhado:
		noite_telhado.comecar(self)
		await noite_telhado.terminou
		if not is_inside_tree():
			return
	else:
		# Parado na pausa (o timer não corre com a árvore pausada).
		await get_tree().create_timer(fim_provisorio, false).timeout
		if not is_inside_tree():
			return
	await SceneDirector.fade_out(3.0)
	if not is_inside_tree():
		return
	SceneDirector.hold_black = true
	await Narrator.say(linha_fim, Narrator.Style.CARTAO)
	if not is_inside_tree():
		return
	Events.quit_to_menu_requested.emit()


## A descida do céu: uma câmera própria, de `descida_inicio` (alta, a leste,
## olhando o poente) até os olhos de Akeley, por uma curva de Bézier; o olhar vai
## do céu à fazenda ao pé da montanha e, no fim, ao que ele olha (o canil, o
## balde). O mouse desvia o olhar (nunca preso), e o desvio se desfaz na chegada.
## No fim, o balde sobe à vista e a câmera passa a ser a dele, no mesmo quadro.
func _descida() -> void:
	descendo = true
	player.input_enabled = false
	balde.visible = false
	balde.erguer = 0.0
	_camera_ceu = Camera3D.new()
	_camera_ceu.name = "_CameraCeu"
	_camera_ceu.fov = player.camera.fov
	_camera_ceu.near = player.camera.near
	_camera_ceu.far = maxf(player.camera.far, 2000.0)
	add_child(_camera_ceu)
	_camera_ceu.current = true
	_camera_ceu.global_transform = Transform3D.IDENTITY.looking_at(olhar_inicio - descida_inicio, Vector3.UP).translated(descida_inicio)
	# A troca de fase põe o jogador na entrada depois do _ready.
	while SceneDirector.is_busy:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	# A câmera dele, no fim: olhando para onde a entrada aponta, um pouco abaixo.
	player.head.rotation.x = deg_to_rad(-12.0)
	player.head.position.y = player.eye_height
	var olho := player.camera.global_transform
	var fim_olhar := olho.origin - olho.basis.z * 8.0
	var t := 0.0
	while t < duracao_descida:
		_pose_descida(t / duracao_descida, olho, fim_olhar)
		await get_tree().process_frame
		if not is_inside_tree():
			return
		t += get_process_delta_time()
		# O balde sobe à vista no último trecho, quando a câmera chega a ele.
		var k := clampf((t / duracao_descida - 0.86) / 0.14, 0.0, 1.0)
		if k > 0.0 and not balde.visible:
			balde.visible = true
		balde.erguer = smoothstep(0.0, 1.0, k)
	_pose_descida(1.0, olho, fim_olhar)
	balde.erguer = 1.0
	balde.visible = true
	player.camera.current = true
	_camera_ceu.queue_free()
	_camera_ceu = null
	descendo = false
	player.input_enabled = true


func _pose_descida(u: float, olho: Transform3D, fim_olhar: Vector3) -> void:
	# O caminho: devagar no alto, mais rápido no meio, assentando no fim.
	var s := smoothstep(0.0, 1.0, u)
	s = lerpf(s, 1.0 - pow(1.0 - u, 2.2), 0.5)
	var p := descida_inicio.bezier_interpolate(descida_c1, descida_c2, olho.origin, s)
	# O olhar: do céu à fazenda (até a metade), da fazenda ao que ele vê (no fim).
	var a := smoothstep(0.05, 0.5, u)
	var b := smoothstep(0.45, 0.97, u)
	var alvo := olhar_inicio.lerp(olhar_meio, a).lerp(fim_olhar, b)
	var x := Transform3D.IDENTITY.looking_at(alvo - p, Vector3.UP)
	x.origin = p
	# O desvio do mouse, que volta a zero na chegada.
	var peso := 1.0 - smoothstep(0.8, 0.98, u)
	x.basis = x.basis * Basis(Vector3.UP, _desvio.x * peso) * Basis(Vector3.RIGHT, _desvio.y * peso)
	if u >= 1.0:
		x = olho
	_camera_ceu.global_transform = x


func _unhandled_input(event: InputEvent) -> void:
	if descendo and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var d := (event as InputEventMouseMotion).relative * player.mouse_sensitivity * float(Settings.get_value(&"sensibilidade"))
		_desvio.x = clampf(_desvio.x - d.x, deg_to_rad(-50.0), deg_to_rad(50.0))
		_desvio.y = clampf(_desvio.y - d.y, deg_to_rad(-35.0), deg_to_rad(35.0))


## A primeira fala de Akeley: quando ele se mexe, ou uns segundos depois.
func _primeira_fala() -> void:
	if linha_inicio == null:
		return
	var de := player.global_position
	var t := 0.0
	while t < 5.0 and player.global_position.distance_to(de) < 0.3:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		t += get_process_delta_time()
	Narrator.say(linha_inicio)


## O capim do quintal (gerar_fazenda._arbustos_e_capim): as posições vêm na meta.
func _capim() -> void:
	var mi := get_node_or_null(^"Capim") as MultiMeshInstance3D
	if mi == null or not mi.has_meta(&"instancias"):
		return
	var dados: PackedFloat32Array = mi.get_meta(&"instancias")
	var multi := mi.multimesh.duplicate() as MultiMesh
	multi.instance_count = dados.size() / 12
	multi.buffer = dados
	mi.multimesh = multi
