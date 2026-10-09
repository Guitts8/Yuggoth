class_name Player
extends CharacterBody3D
## Wilmarth em primeira pessoa: caminhada lenta, sem corrida (GDD §6.1).

signal footstep
## Saiu da cadeira (o jogador tentou andar sentado).
signal stood_up

## Debruçado de todo (`debrucado` = 1), quanto a cabeça desce e vai à frente.
const DEBRUCAR_DESCE := 0.08
const DEBRUCAR_AVANCA := 0.28

@export_group("Movimento")
@export var walk_speed := 1.9
@export var crouch_speed := 0.9
@export var acceleration := 9.0

@export_group("Câmera")
@export var mouse_sensitivity := 0.0022
@export var gamepad_look_speed := 2.6
@export var eye_height := 1.62
@export var crouch_eye_height := 1.05
@export var seated_eye_height := 1.15
@export var bob_amount := 0.03
@export var bob_frequency := 5.5

## Segurando "zoom_visao" (botão direito, Z): o campo de visão aperta para ler de
## longe (a folhinha, um papel na mesa), e a mira fica mais lenta.
@export var zoom_fov := 32.0

@export_group("Interação")
@export var interact_distance := 2.0

@export_group("Som")
## Um é sorteado a cada passo, com variação de pitch.
@export var footstep_sounds: Array[AudioStream] = []
@export var footstep_volume_db := -8.0

## Andar e interagir. Desligado por uma cena (selar, o diário, a calha, o lapso),
## a cabeça continua livre (playtest 4: "a cabeça deve dar liberdade para o
## jogador, pois é quase a única que ele tem"): o mouse soma um desvio à direção
## que a cena dá; devolvido o controle, o desvio vira a direção do corpo e da cabeça.
var input_enabled := true:
	set(v):
		if v and not input_enabled:
			_assumir_olhar()
		input_enabled = v
## Sentado só olha em volta; tentar andar levanta (Prólogo, GDD §5.0).
var seated := false
## Levado por uma cena (a calha, a porta): a cena move o corpo, sem a física
## (passa pela porta aberta e pelos móveis); os passos e o balanço continuam.
var conduzido := false
## Debruçado sobre a mesa (0 a 1; o diário, o sono): sentado, a cabeça vai à
## frente e desce.
var debrucado := 0.0
## Campo de visão imposto por uma cena (a página do diário); 0 = o de sempre.
var fov_forcado := 0.0

var _target: Interactable
var _target_prompt := ""
var _bob_t := 0.0
var _bob_weight := 0.0
var _last_bob_sin := 0.0
var _fov_base := 75.0
## O desvio do olhar durante uma cena: (yaw, pitch), em radianos.
var _olhar_extra := Vector2.ZERO
var _pos_antes := Vector3.ZERO
## O giro em curso de olhar_para (um novo o substitui).
var _giro: Tween

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var lamp: Lamp = $Head/Camera3D/Lamp


func _ready() -> void:
	add_to_group(&"player")
	ray.target_position = Vector3(0, 0, -interact_distance)
	ray.add_exception(self)
	head.position.y = eye_height
	_fov_base = camera.fov
	Events.modal_changed.connect(_on_modal_changed)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not footstep_sounds.is_empty():
		var steps := AudioStreamPlayer.new()
		steps.bus = &"SFX"
		steps.volume_db = footstep_volume_db
		add_child(steps)
		footstep.connect(func() -> void:
			steps.stream = footstep_sounds.pick_random()
			steps.pitch_scale = randf_range(0.9, 1.1)
			steps.play())


func _exit_tree() -> void:
	# Fase trocada com algo na mira: o HUD não pode ficar com o aviso velho.
	if _target:
		_target = null
		Events.interaction_target_changed.emit(null)


## Põe na cadeira onde o player está; a câmera desce para a altura sentada.
func sit() -> void:
	seated = true
	head.position.y = seated_eye_height


func stand() -> void:
	if seated:
		seated = false
		stood_up.emit()


## Levantou-se andando (o jogador) de um assento cuja colisão o envolve (a
## poltrona no sonho da noite 5; playtest 6: "acordo travado no mesmo lugar"): dá
## o passo até o lugar livre mais perto, à frente de preferência.
func _desencaixar() -> void:
	if livre(global_position):
		return
	var frente := -global_basis.z
	frente.y = 0.0
	frente = frente.normalized()
	for raio: float in [0.45, 0.65, 0.85, 1.1, 1.4]:
		for k in 12:
			# 0, +30°, -30°, +60°... a partir da frente.
			var a := deg_to_rad(30.0 * ceilf(k / 2.0) * (1.0 if k % 2 == 1 else -1.0))
			var p := global_position + frente.rotated(Vector3.UP, a) * raio
			if livre(p):
				var estava := conduzido
				conduzido = true
				var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				t.tween_property(self, ^"global_position", p, 0.25 + raio * 0.4)
				await t.finished
				conduzido = estava
				return


## O corpo cabe em `ponto` (global, no chão) sem tocar no mundo.
func livre(ponto: Vector3) -> bool:
	var forma := get_node(^"CollisionShape3D") as CollisionShape3D
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = forma.shape
	consulta.collision_mask = 1
	consulta.exclude = [get_rid()]
	# Um tico acima do chão: encostar no piso não é estar preso.
	consulta.transform = Transform3D(Basis.IDENTITY, ponto + Vector3.UP * 0.03) * forma.transform
	return get_world_3d().direct_space_state.intersect_shape(consulta, 1).is_empty()


## Onde ficam os olhos com o corpo em `de` (global), sentado ou de pé e
## debruçado o quanto `debrucado` diz, virado para `yaw`.
func olhos_em(de: Vector3, yaw: float) -> Vector3:
	var altura := (seated_eye_height - DEBRUCAR_DESCE * debrucado) if seated else eye_height
	var frente := Vector3(-sin(yaw), 0.0, -cos(yaw)) * (DEBRUCAR_AVANCA * debrucado if seated else 0.0)
	return de + Vector3(0.0, altura, 0.0) + frente


## Vira o corpo e a cabeça, devagar, para `ponto` (global), como se visto de `de`
## (onde o corpo vai estar quando o tween acabar; por padrão, onde está).
func olhar_para(ponto: Vector3, segundos: float, de := global_position) -> Tween:
	# A cena leva o olhar a algo novo: o desvio do mouse vira a direção de agora,
	# e o giro sai de onde os olhos estão, pelo lado mais curto (playtest 5: com o
	# desvio desfeito à parte, o corpo e o desvio somados davam a volta longa — um
	# "girinho" ao clicar na porta).
	# Um giro anterior ainda correndo brigaria com este pela rotação (playtest 6:
	# perto da maçaneta, o giro do caminho não tinha acabado quando vinha o de
	# olhar para fora, e o corpo dava uma volta inteira).
	if _giro and _giro.is_valid() and _giro.is_running():
		var velho := _giro
		velho.kill()
		# Quem esperava por ele (await ...finished) segue em frente.
		(func() -> void: velho.finished.emit()).call_deferred()
	_assumir_olhar()
	rotation.y = wrapf(rotation.y, -PI, PI)
	var yaw := atan2(-(ponto.x - de.x), -(ponto.z - de.z))
	var olho := olhos_em(de, yaw)
	var pitch := atan2(ponto.y - olho.y, Vector2(ponto.x - olho.x, ponto.z - olho.z).length())
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, ^"rotation:y", rotation.y + angle_difference(rotation.y, yaw), segundos)
	t.tween_property(head, ^"rotation:x", clampf(pitch, deg_to_rad(-85.0), deg_to_rad(85.0)), segundos)
	_giro = t
	return t


## Uma cena o leva a pé pelos `pontos` (global, no chão), no passo dele, olhando
## `olhar`; sem a física (passa pela porta aberta e pelos móveis).
func conduzir(pontos: Array, olhar: Vector3, passo := 1.1) -> void:
	var estava := conduzido
	conduzido = true
	var de := global_position
	var total := 0.0
	var anterior := de
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	for i in pontos.size():
		var p: Vector3 = pontos[i]
		p.y = de.y
		var s := maxf(0.15, p.distance_to(anterior)) / passo
		total += s
		var facil := Tween.EASE_IN_OUT
		if pontos.size() > 1:
			facil = Tween.EASE_IN if i == 0 else (Tween.EASE_OUT if i == pontos.size() - 1 else Tween.EASE_IN_OUT)
		t.tween_property(self, ^"global_position", p, s).set_ease(facil)
		anterior = p
	var giro := olhar_para(olhar, maxf(total, 0.5), anterior)
	await t.finished
	# O olhar dura no mínimo meio segundo: chega junto com ele.
	if giro.is_valid() and giro.is_running():
		await giro.finished
	conduzido = estava


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and pode_olhar():
		_look(event.relative * mouse_sensitivity)
		return
	if not input_enabled:
		return
	if event.is_action_pressed("interagir") and _target:
		_target.interact(self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("lamparina_mais"):
		lamp.adjust(1)
	elif event.is_action_pressed("lamparina_menos"):
		lamp.adjust(-1)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var move := Vector2.ZERO
	var crouching := false
	if input_enabled:
		move = Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_frente", &"mover_tras")
		crouching = Input.is_action_pressed(&"agachar")
		if seated:
			if move != Vector2.ZERO:
				stand()
				_desencaixar()
			move = Vector2.ZERO
			crouching = false
	if pode_olhar():
		var look := Input.get_vector(&"olhar_esquerda", &"olhar_direita", &"olhar_cima", &"olhar_baixo")
		if look != Vector2.ZERO:
			_look(look * gamepad_look_speed * delta)

	var speed := crouch_speed if crouching else walk_speed
	var wish := (transform.basis * Vector3(move.x, 0.0, move.y)) * speed
	var k := 1.0 - exp(-acceleration * delta)
	velocity.x = lerpf(velocity.x, wish.x, k)
	velocity.z = lerpf(velocity.z, wish.z, k)
	# Sentado (a cadeira, a poltrona), fica onde a cena o pôs: a física o
	# empurraria para fora da colisão do móvel. Conduzido, quem anda é a cena; a
	# velocidade (do passo e do balanço) vem do quanto ele andou.
	if conduzido:
		velocity = (global_position - _pos_antes) / maxf(delta, 0.0001)
		velocity.y = 0.0
	elif seated:
		velocity = Vector3.ZERO
	else:
		move_and_slide()
	_pos_antes = global_position

	_update_head(delta, crouching)
	_update_target()


func _look(delta: Vector2) -> void:
	delta *= Settings.get_value(&"sensibilidade") * camera.fov / _fov_base
	if Settings.get_value(&"inverter_y"):
		delta.y = -delta.y
	if input_enabled:
		rotate_y(-delta.x)
		head.rotation.x = clampf(head.rotation.x - delta.y, deg_to_rad(-85.0), deg_to_rad(85.0))
		return
	# Numa cena: o desvio, por cima da direção que ela dá.
	_olhar_extra.x = wrapf(_olhar_extra.x - delta.x, -PI, PI)
	_olhar_extra.y = clampf(_olhar_extra.y - delta.y, deg_to_rad(-85.0) - head.rotation.x, deg_to_rad(85.0) - head.rotation.x)


## O mouse mexe a cabeça sempre que está preso — também numa cena (e folheando
## o diário, que é modal mas não solta o mouse). As telas o soltam.
func pode_olhar() -> bool:
	return input_enabled or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Numa cena, o jogador mexeu a cabeça por conta própria (a cena para de
## conduzir o olhar: o diário deixa de seguir a pena).
func desviou_o_olhar() -> bool:
	return _olhar_extra != Vector2.ZERO


## O controle voltou: o desvio da cena vira a direção do corpo e da cabeça.
func _assumir_olhar() -> void:
	if _olhar_extra == Vector2.ZERO:
		return
	rotation.y += _olhar_extra.x
	head.rotation.x = clampf(head.rotation.x + _olhar_extra.y, deg_to_rad(-85.0), deg_to_rad(85.0))
	_olhar_extra = Vector2.ZERO
	camera.basis = Basis.IDENTITY


func _update_head(delta: float, crouching: bool) -> void:
	var target_height := crouch_eye_height if crouching else eye_height
	if seated:
		target_height = seated_eye_height - DEBRUCAR_DESCE * debrucado
	head.position.y = lerpf(head.position.y, target_height, 1.0 - exp(-10.0 * delta))
	head.position.z = -DEBRUCAR_AVANCA * debrucado if seated else 0.0
	var zoom := input_enabled and Input.is_action_pressed(&"zoom_visao")
	var fov := fov_forcado if fov_forcado > 0.0 else (zoom_fov if zoom else _fov_base)
	camera.fov = lerpf(camera.fov, fov, 1.0 - exp(-8.0 * delta))

	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var moving := is_on_floor() and ground_speed > 0.15
	_bob_weight = move_toward(_bob_weight, 1.0 if moving else 0.0, delta * 4.0)
	if moving:
		_bob_t += delta * bob_frequency * (ground_speed / walk_speed)
	var s := sin(_bob_t)
	camera.position = Vector3(cos(_bob_t * 0.5) * bob_amount * 0.6, s * bob_amount, 0.0) * _bob_weight
	# O desvio de uma cena: a câmera desfaz o pitch da cabeça, gira o yaw extra
	# em torno da vertical e refaz o pitch somado (sem rolar o horizonte).
	if _olhar_extra != Vector2.ZERO:
		var p := head.rotation.x
		var q := clampf(_olhar_extra.y, deg_to_rad(-85.0) - p, deg_to_rad(85.0) - p)
		camera.basis = Basis(Vector3.RIGHT, -p) * Basis(Vector3.UP, _olhar_extra.x) * Basis(Vector3.RIGHT, p + q)
	elif camera.basis != Basis.IDENTITY:
		camera.basis = Basis.IDENTITY
	# Passo no ponto mais baixo do balanço.
	if moving and _last_bob_sin > -0.95 and s <= -0.95:
		footstep.emit()
	_last_bob_sin = s


func _update_target() -> void:
	var hit: Interactable = null
	# Parado (um lapso no tempo, uma tela aberta), nada na mira.
	if input_enabled and ray.is_colliding():
		hit = ray.get_collider() as Interactable
	if hit and not hit.can_interact(self):
		hit = null
	# O mesmo alvo pode mudar de aviso (ex.: o fonógrafo, de "pôr o cilindro"
	# para "baixar a agulha"): reavisa o HUD.
	var prompt := hit.prompt if hit else ""
	if hit != _target or prompt != _target_prompt:
		_target = hit
		_target_prompt = prompt
		Events.interaction_target_changed.emit(hit)


func _on_modal_changed(is_open: bool) -> void:
	input_enabled = not is_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED
