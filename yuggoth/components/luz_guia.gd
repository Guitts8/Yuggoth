class_name LuzGuia
extends Node3D
## A luz-guia da fazenda (playtest 11: "precisamos de indicativos de luz — pode ser
## uma luz azul fraca — para onde devemos ir, uma coisa bem fraca que só indique em
## cima do para onde ir, quase nada"). Um brilho azul pálido paira sobre o lugar da
## próxima tarefa, pulsando devagar; some quando Akeley chega perto, e numa cena
## (sem controle) também. As `fontes` (a Rotina, a Preparacao) dizem o que vale
## agora (`guias()`); vale a mais perto de Akeley.

@export var fontes: Array[Node] = []
## Quanto acima da área o brilho paira.
@export var altura := 0.5
## A esta distância (m) ele some: já se chegou.
@export var perto := 2.4
@export var cor := Color(0.5, 0.68, 1.0)
@export var energia := 0.8

var _luz: OmniLight3D
var _brilho: Sprite3D
var _k := 0.0
var _t := 0.0
var _alvo := Vector3.INF


func _ready() -> void:
	top_level = true
	_luz = OmniLight3D.new()
	_luz.name = "Luz"
	_luz.light_color = cor
	_luz.omni_range = 2.4
	_luz.omni_attenuation = 1.6
	_luz.shadow_enabled = false
	add_child(_luz)
	_brilho = Sprite3D.new()
	_brilho.name = "Brilho"
	_brilho.texture = _textura()
	_brilho.pixel_size = 0.0065
	_brilho.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_brilho.shaded = false
	_brilho.transparent = true
	_brilho.double_sided = true
	_brilho.modulate = Color(cor.r, cor.g, cor.b, 0.0)
	_brilho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_brilho)
	visible = false


func _process(delta: float) -> void:
	_t += delta
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var alvo := Vector3.INF
	if player and player.input_enabled:
		var melhor := INF
		for f in fontes:
			if f == null or not f.has_method(&"guias"):
				continue
			for a: Interactable in f.guias():
				if a == null or a.collision_layer == 0 or not a.is_visible_in_tree():
					continue
				var d := a.global_position.distance_to(player.global_position)
				if d < melhor:
					melhor = d
					alvo = a.global_position
	var mostra := alvo != Vector3.INF and player.global_position.distance_to(alvo) > perto
	_k = move_toward(_k, 1.0 if mostra else 0.0, delta / 0.9)
	if alvo != Vector3.INF:
		var ponto := alvo + Vector3.UP * (altura + 0.06 * sin(_t * 1.3))
		# Vai até o novo alvo devagar (não salta de um lugar a outro).
		_alvo = ponto if _alvo == Vector3.INF or _k < 0.05 else _alvo.lerp(ponto, 1.0 - exp(-2.5 * delta))
		global_position = _alvo
	visible = _k > 0.01
	if not visible:
		return
	var pulso := 0.78 + 0.22 * sin(_t * 2.1)
	_luz.light_energy = energia * _k * pulso
	_brilho.modulate.a = 0.75 * _k * pulso


## Um borrão redondo, claro no meio e sumindo para a borda.
static func _textura() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.25, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 64
	t.height = 64
	return t
