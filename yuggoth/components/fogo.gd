class_name Fogo
extends Node3D
## O fogo da lareira (docs/PLANO_ESCRITORIO.md, Fase 3b): uma luz quente que
## pisca e chamas que tremem. Fica dentro de um grupo com ConditionalNode (aceso
## ou não); escondido, para de processar — e o crepitar, um AudioStreamPlayer3D
## filho com autoplay, fica pausado junto.

@export var luz: Light3D
## Chamas (billboards) que esticam e encolhem, cada uma no seu ritmo.
@export var chamas: Array[Node3D] = []
@export var energia := 2.0
## 0 a 1: o fogo pegando (a lenha acesa agora, playtest 7: `AcenderLareira` o
## leva de quase nada até inteiro); aceso de antes, inteiro.
var intensidade := 1.0

var _t := 0.0
var _ruido := FastNoiseLite.new()
var _escala: Dictionary[Node3D, Vector3] = {}


var _crepitar: AudioStreamPlayer3D
var _volume := 0.0


func _ready() -> void:
	_ruido.frequency = 2.5
	for c in chamas:
		_escala[c] = c.scale
	_crepitar = get_node_or_null(^"Crepitar") as AudioStreamPlayer3D
	if _crepitar:
		_volume = _crepitar.volume_db


func _process(delta: float) -> void:
	_t += delta
	if luz:
		luz.light_energy = energia * intensidade * (0.8 + 0.25 * _ruido.get_noise_1d(_t * 6.0) + 0.06 * sin(_t * 31.0))
	if _crepitar:
		_crepitar.volume_db = _volume + linear_to_db(maxf(intensidade, 0.05))
	for i in chamas.size():
		var c := chamas[i]
		var s := _escala[c]
		var v := _ruido.get_noise_2d(_t * 4.0, i * 13.0)
		# Pegando, as chamas nascem no meio (onde o fósforo encostou) e se espalham.
		var k := clampf(intensidade * 1.6 - absf(i - (chamas.size() - 1) * 0.5) * 0.3, 0.0, 1.0)
		c.visible = k > 0.02
		c.scale = Vector3(s.x * (1.0 - 0.15 * v) * (0.4 + 0.6 * k), s.y * (0.85 + 0.35 * absf(v) + 0.1 * sin(_t * (9.0 + i))) * k, s.z)
