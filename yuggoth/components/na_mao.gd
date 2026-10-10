class_name NaMao
extends Node3D
## Um objeto seguro diante da câmera, sem mãos (docs/PLANO_FAZENDA.md: "sem
## corpo", como a carta no escritório): o balde de ração de Akeley, a lenha, o
## lampião. Segue a câmera com um pouco de atraso e balança com o passo.

## Posição e rotação (graus) em relação à câmera.
@export var posicao := Vector3(0.34, -0.5, -0.85)
@export var rotacao := Vector3(38, -12, 0)
## Quanto atrasa ao virar a cabeça (maior = mais preso à câmera).
@export var firmeza := 18.0
## O balanço do passo, em metros.
@export var balanco := 0.012

var _camera: Camera3D
var _t := 0.0


func _ready() -> void:
	top_level = true
	_camera = get_viewport().get_camera_3d()
	_seguir(1.0)


func _process(delta: float) -> void:
	if not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	_seguir(1.0 - exp(-firmeza * delta))


func _seguir(k: float) -> void:
	if not is_instance_valid(_camera):
		return
	var corpo := _camera.get_parent()
	while corpo and not corpo is CharacterBody3D:
		corpo = corpo.get_parent()
	var anda := 0.0
	if corpo:
		anda = clampf(Vector2((corpo as CharacterBody3D).velocity.x, (corpo as CharacterBody3D).velocity.z).length() / 1.5, 0.0, 1.0)
	_t += get_process_delta_time() * TAU * 1.8 * anda
	var passo := Vector3(sin(_t * 0.5) * balanco, -absf(cos(_t * 0.5)) * balanco, 0.0) * anda
	var alvo := _camera.global_transform * Transform3D(Basis.from_euler(rotacao * PI / 180.0), posicao + passo)
	global_transform = global_transform.interpolate_with(alvo, k) if k < 1.0 else alvo
