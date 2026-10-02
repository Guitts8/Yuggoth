class_name Lamp
extends OmniLight3D
## Lamparina a querosene: chama ajustável com oscilação por ruído.
## No Ato III, aumentar a chama é uma escolha com consequência (GDD §5.5).

@export_range(0.0, 1.0, 0.05) var intensity := 0.5:
	set(value):
		value = clampf(value, 0.0, 1.0)
		if is_equal_approx(value, intensity):
			return
		intensity = value
		if is_node_ready():
			Events.lamp_changed.emit(intensity)
## Desligada e sem resposta ao input quando a cena não dá a lamparina ao
## jogador (escritório de dia, gabinete com a luz da mesa).
@export var available := true:
	set(value):
		available = value
		if not available:
			intensity = 0.0
@export var max_energy := 2.4
@export var min_range := 1.5
@export var max_range := 8.0
@export var step := 0.1
@export_range(0.0, 0.5) var flicker := 0.12

var _noise := FastNoiseLite.new()
var _t := 0.0


func _ready() -> void:
	_noise.frequency = 0.9
	_noise.seed = randi()


func adjust(direction: int) -> void:
	if available:
		intensity += step * direction


func _process(delta: float) -> void:
	_t += delta
	var n := _noise.get_noise_1d(_t * 40.0)
	light_energy = max_energy * intensity * (1.0 + n * flicker)
	omni_range = lerpf(min_range, max_range, intensity) * (1.0 + n * flicker * 0.3)
	visible = intensity > 0.0
