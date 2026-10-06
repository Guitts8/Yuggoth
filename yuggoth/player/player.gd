class_name Player
extends CharacterBody3D
## Wilmarth em primeira pessoa: caminhada lenta, sem corrida (GDD §6.1).

signal footstep
## Saiu da cadeira (o jogador tentou andar sentado).
signal stood_up

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

@export_group("Interação")
@export var interact_distance := 2.0

@export_group("Som")
## Um é sorteado a cada passo, com variação de pitch.
@export var footstep_sounds: Array[AudioStream] = []
@export var footstep_volume_db := -8.0

var input_enabled := true
## Sentado só olha em volta; tentar andar levanta (Prólogo, GDD §5.0).
var seated := false

var _target: Interactable
var _target_prompt := ""
var _bob_t := 0.0
var _bob_weight := 0.0
var _last_bob_sin := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var lamp: Lamp = $Head/Camera3D/Lamp


func _ready() -> void:
	add_to_group(&"player")
	ray.target_position = Vector3(0, 0, -interact_distance)
	ray.add_exception(self)
	head.position.y = eye_height
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


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative * mouse_sensitivity)
	elif event.is_action_pressed("interagir") and _target:
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
			move = Vector2.ZERO
			crouching = false
		var look := Input.get_vector(&"olhar_esquerda", &"olhar_direita", &"olhar_cima", &"olhar_baixo")
		if look != Vector2.ZERO:
			_look(look * gamepad_look_speed * delta)

	var speed := crouch_speed if crouching else walk_speed
	var wish := (transform.basis * Vector3(move.x, 0.0, move.y)) * speed
	var k := 1.0 - exp(-acceleration * delta)
	velocity.x = lerpf(velocity.x, wish.x, k)
	velocity.z = lerpf(velocity.z, wish.z, k)
	move_and_slide()

	_update_head(delta, crouching)
	_update_target()


func _look(delta: Vector2) -> void:
	delta *= Settings.get_value(&"sensibilidade")
	if Settings.get_value(&"inverter_y"):
		delta.y = -delta.y
	rotate_y(-delta.x)
	head.rotation.x = clampf(head.rotation.x - delta.y, deg_to_rad(-85.0), deg_to_rad(85.0))


func _update_head(delta: float, crouching: bool) -> void:
	var target_height := crouch_eye_height if crouching else eye_height
	if seated:
		target_height = seated_eye_height
	head.position.y = lerpf(head.position.y, target_height, 1.0 - exp(-10.0 * delta))

	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var moving := is_on_floor() and ground_speed > 0.15
	_bob_weight = move_toward(_bob_weight, 1.0 if moving else 0.0, delta * 4.0)
	if moving:
		_bob_t += delta * bob_frequency * (ground_speed / walk_speed)
	var s := sin(_bob_t)
	camera.position = Vector3(cos(_bob_t * 0.5) * bob_amount * 0.6, s * bob_amount, 0.0) * _bob_weight
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
