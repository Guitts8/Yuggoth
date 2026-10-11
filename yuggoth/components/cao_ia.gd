class_name CaoIA
extends CharacterBody3D
## Um cão de Akeley com corpo e vontade (docs/PLANO_FAZENDA.md, F4; GDD §5.1a):
## quatro têm o seu jeito — Brutus segue Akeley, Conan deita junto ao fogo,
## Hércules late para a mata, Rambo rosna para a janela (e não come) —; os outros
## são a matilha. Decide de tempos em tempos a partir do `modo` da `Matilha` (o
## pai); anda até um ponto (sem navegação: o cercado e o quintal são abertos), vira
## para onde vai, e o `Cao` filho (`Visual`) faz a pose e o passo.
##
## Camada própria (CAMADA): esbarra no mundo, mas não tampa a mira nem empurra o
## jogador; e um cão não esbarra no outro (lado a lado na gamela, eles se
## empurravam num monte).

enum Papel { MATILHA, SEGUIR, FOGO, MATA, JANELA }

const CAMADA := 1 << 3
const PASSO := 1.1
const TROTE := 2.6
const CORRIDA := 5.0
## Distância do alvo em que se dá por chegado.
const PERTO := 0.35

@export var papel := Papel.MATILHA
## Correu para a mata e não voltou (Yautja, F5): fora da matilha.
var fugiu := false
## Correndo para a mata agora (fugir()).
var fugindo := false

var visual: Cao
var matilha: Matilha
var _alvo := Vector3.INF
var _velocidade := PASSO
## Para onde olhar parado (INF = para onde estava indo).
var _olhar_para := Vector3.INF
var _decidir := 0.0
var _latir := 0.0
var _empacado := 0.0
var _voz: AudioStreamPlayer3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = CAMADA
	collision_mask = 1
	visual = get_node_or_null(^"Visual") as Cao
	matilha = get_parent() as Matilha
	_rng.seed = hash(name) + 7
	_decidir = _rng.randf_range(0.2, 1.5)
	_latir = _rng.randf_range(2.0, 8.0)
	_voz = AudioStreamPlayer3D.new()
	_voz.name = "_Voz"
	_voz.bus = &"SFX"
	_voz.unit_size = 6.0
	_voz.max_distance = 90.0
	_voz.position = Vector3(0, 0.6, -0.5)
	add_child(_voz)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	_decidir -= delta
	if _decidir <= 0.0 and matilha:
		_decidir = _rng.randf_range(0.6, 2.2)
		_pensar()
	var plano := Vector3.ZERO
	if _alvo != Vector3.INF:
		var para := Vector3(_alvo.x - global_position.x, 0, _alvo.z - global_position.z)
		if para.length() < PERTO:
			_alvo = Vector3.INF
		else:
			plano = para.normalized() * _velocidade
	var k := 1.0 - exp(-6.0 * delta)
	velocity.x = lerpf(velocity.x, plano.x, k)
	velocity.z = lerpf(velocity.z, plano.z, k)
	move_and_slide()
	# Empacado (uma parede, outro cão): desiste do alvo e pensa de novo.
	var anda := Vector2(velocity.x, velocity.z).length()
	if plano != Vector3.ZERO and anda < 0.15:
		_empacado += delta
		if _empacado > 1.2:
			_empacado = 0.0
			_alvo = Vector3.INF
			_decidir = 0.0
	else:
		_empacado = 0.0
	_virar(delta, anda)
	if visual:
		visual.andar = anda / PASSO if anda < TROTE * 0.8 else 1.2 + anda / CORRIDA
	_latir -= delta


## Vira o corpo para onde anda ou para onde quer olhar; a cabeça vai um pouco além.
func _virar(delta: float, anda: float) -> void:
	var rumo := Vector3.ZERO
	if anda > 0.2:
		rumo = Vector3(velocity.x, 0, velocity.z)
	elif _olhar_para != Vector3.INF:
		rumo = Vector3(_olhar_para.x - global_position.x, 0, _olhar_para.z - global_position.z)
	if rumo.length() < 0.01:
		if visual:
			visual.olhar = move_toward(visual.olhar, 0.0, delta * 40.0)
		return
	# A frente do cão é o -Z: yaw = atan2(-x, -z).
	var yaw := atan2(-rumo.x, -rumo.z)
	var falta := angle_difference(rotation.y, yaw)
	rotation.y += clampf(falta, -delta * 3.5, delta * 3.5)
	if visual:
		visual.olhar = lerpf(visual.olhar, clampf(rad_to_deg(falta), -60.0, 60.0), 1.0 - exp(-4.0 * delta))


## Late para a mata, dispara para lá, e some quando chega longe (Yautja, no fim da
## rotina: "Pássaros ainda cantam (e param)" — 💭 nosso, GDD §5.1a).
func fugir(para: Vector3) -> void:
	fugindo = true
	_olhar_para = para
	_pose(Cao.Pose.LATINDO)
	await _latidos(3)
	if not is_inside_tree():
		return
	_pose(Cao.Pose.PARADO)
	_ir(para, CORRIDA)
	collision_mask = 1
	var t := 0.0
	while t < 25.0 and _alvo != Vector3.INF:
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		t += get_physics_process_delta_time()
		_alvo = para
		_velocidade = CORRIDA
	fugindo = false
	fugiu = true
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


## A decisão do momento, pelo modo da matilha e pelo papel.
func _pensar() -> void:
	if fugindo or fugiu:
		return
	var akeley := matilha.akeley()
	match matilha.modo:
		Matilha.Modo.COMENDO:
			var lugar := matilha.lugar_na_gamela(self)
			if lugar == Vector3.INF:
				_vigiar_a_mata(false)
			elif global_position.distance_to(lugar) > PERTO * 1.5:
				_olhar_para = lugar + matilha.gamela_frente
				_ir(lugar, TROTE)
				_pose(Cao.Pose.PARADO)
			else:
				_alvo = Vector3.INF
				_olhar_para = lugar + matilha.gamela_frente
				_pose(Cao.Pose.COMENDO)
		Matilha.Modo.DEPOIS:
			if papel == Papel.SEGUIR and akeley:
				_seguir(akeley)
			elif papel == Papel.JANELA:
				_vigiar_a_mata(false)
			elif papel == Papel.MATA and _rng.randf() < 0.25:
				_vigiar_a_mata(true)
			else:
				_vagar(matilha.cercado)
		Matilha.Modo.ESPERANDO:
			if papel == Papel.SEGUIR and akeley:
				_seguir(akeley)
			elif papel == Papel.JANELA:
				_vigiar_a_mata(false)
			elif papel == Papel.MATA and _rng.randf() < 0.3:
				_vigiar_a_mata(true)
			elif akeley and matilha.com_balde() and _perto_do_cercado(akeley.global_position):
				_pedir_racao(akeley)
			else:
				_vagar(matilha.cercado)
		Matilha.Modo.SOLTOS:
			if papel == Papel.SEGUIR and akeley:
				_seguir(akeley)
			elif papel == Papel.MATA and _rng.randf() < 0.5:
				_vigiar_a_mata(true)
			else:
				_vagar(matilha.quintal)


## Brutus: a dois passos de Akeley, do lado; quando ele para, senta junto.
func _seguir(akeley: Player) -> void:
	var de := akeley.global_position
	var atras := de + akeley.global_basis.z * 1.3 + akeley.global_basis.x * 0.7
	var longe := global_position.distance_to(de)
	_olhar_para = de
	# Preso para trás (uma parede, a escada): longe e fora da vista, ele chega.
	if longe > 14.0:
		var cam := akeley.camera
		var visto := (global_position - cam.global_position).normalized().dot(-cam.global_basis.z) > 0.3
		if not visto:
			global_position = atras + Vector3(0, 0.1, 0)
			velocity = Vector3.ZERO
			return
	if longe > 2.2:
		_ir(atras, TROTE if longe > 5.0 else PASSO)
		_pose(Cao.Pose.PARADO)
	else:
		_alvo = Vector3.INF
		var parado := Vector2(akeley.velocity.x, akeley.velocity.z).length() < 0.1
		_pose(Cao.Pose.SENTADO if parado and _rng.randf() < 0.6 else Cao.Pose.PARADO)


## Na tela do cercado, do lado de Akeley: olham o balde, latem pedindo, sentam.
func _pedir_racao(akeley: Player) -> void:
	var c := matilha.cercado
	var de := akeley.global_position
	var junto := Vector3(clampf(de.x, c.position.x + 0.3, c.end.x - 0.3), 0, clampf(de.z, c.position.z + 0.3, c.end.z - 0.3))
	junto += Vector3(_rng.randf_range(-1.6, 1.6), 0, _rng.randf_range(-1.2, 1.2))
	junto.x = clampf(junto.x, c.position.x + 0.3, c.end.x - 0.3)
	junto.z = clampf(junto.z, c.position.z + 0.3, c.end.z - 0.3)
	_olhar_para = de
	if global_position.distance_to(junto) > 1.0:
		_ir(junto, TROTE if global_position.distance_to(junto) > 3.0 else PASSO)
		_pose(Cao.Pose.PARADO)
		return
	var r := _rng.randf()
	if r < 0.35 and _latir <= 0.0:
		_latir = _rng.randf_range(2.5, 6.0)
		_pose(Cao.Pose.LATINDO)
		_latidos(_rng.randi_range(1, 3))
	else:
		_pose(Cao.Pose.SENTADO if r < 0.7 else Cao.Pose.PARADO)


## Hércules (latindo) e Rambo (calado, rosnando baixo): de frente para a mata.
func _vigiar_a_mata(latindo: bool) -> void:
	_alvo = Vector3.INF
	_olhar_para = matilha.mata
	if latindo and _latir <= 0.0:
		_latir = _rng.randf_range(4.0, 9.0)
		_pose(Cao.Pose.LATINDO)
		_latidos(_rng.randi_range(2, 4))
	elif not latindo and _rng.randf() < 0.25:
		_pose(Cao.Pose.ROSNANDO)
		_som(matilha.rosnado if _rng.randf() < 0.6 else matilha.arreganho, -10.0)
	else:
		_pose(Cao.Pose.PARADO)


## Anda à toa dentro de `area`; às vezes senta ou deita, às vezes cheira o chão.
func _vagar(area: AABB) -> void:
	_olhar_para = Vector3.INF
	var r := _rng.randf()
	if r < 0.35:
		var p := Vector3(_rng.randf_range(area.position.x, area.end.x), 0, _rng.randf_range(area.position.z, area.end.z))
		_ir(p, PASSO)
		_pose(Cao.Pose.PARADO)
	elif r < 0.55:
		_pose(Cao.Pose.SENTADO)
	elif r < 0.7:
		_pose(Cao.Pose.DEITADO)
	elif r < 0.8:
		_pose(Cao.Pose.COMENDO)  # o focinho no chão: cheirando
	else:
		_pose(Cao.Pose.PARADO)
	# Um deitado fica mais tempo.
	if visual and visual.pose == Cao.Pose.DEITADO:
		_decidir += _rng.randf_range(3.0, 8.0)


func _perto_do_cercado(p: Vector3) -> bool:
	return matilha.cercado.grow(9.0).has_point(Vector3(p.x, 0.5, p.z))


func _ir(p: Vector3, velocidade: float) -> void:
	_alvo = p
	_velocidade = velocidade


func _pose(p: Cao.Pose) -> void:
	if visual:
		visual.pose = p


## `n` latidos em rajada (a mandíbula de cada um no seu som).
func _latidos(n: int) -> void:
	for i in n:
		if not is_inside_tree() or matilha.latidos.is_empty():
			return
		if visual:
			visual.latir()
		_som(matilha.latidos[_rng.randi() % matilha.latidos.size()], -2.0)
		await get_tree().create_timer(_rng.randf_range(0.32, 0.6), false).timeout


func _som(s: AudioStream, db: float) -> void:
	if s == null:
		return
	_voz.stream = s
	_voz.volume_db = db
	_voz.pitch_scale = _rng.randf_range(0.92, 1.06) * (1.0 / clampf(visual.porte if visual else 1.0, 0.85, 1.15))
	_voz.play()
