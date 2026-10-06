class_name Aparicao
extends Node3D
## Algo visto de relance, uma vez só, e só por quem estiver olhando para o lugar
## certo (GDD §5.1 Dia 5: a sombra na janela; §5.3 Cena C: o vulto entre as
## árvores). Fica escondido até `condition` valer e a câmera mirar o meio do
## percurso; então aparece, atravessa `deslocamento` em `duracao` segundos e some.
## Nada confirma o que foi visto: sem som, sem aviso, sem fala do narrador.

@export var condition: Condition
## Marcada quando acontece; com ela marcada, não acontece mais.
@export var flag: StringName
@export_range(0.0, 1.0, 0.01) var exposure := 0.0
## Percurso, a partir da posição inicial (espaço do pai).
@export var deslocamento := Vector3(3.0, 0.0, 0.0)
@export var duracao := 1.4
## Espera entre o olhar chegar e a coisa passar.
@export var atraso := 0.5
## Ângulo máximo (graus) entre o centro da tela e o meio do percurso.
@export var angulo := 22.0
@export var distancia := 6.0
## Asas batendo: a escala vertical oscila tanto assim (0 = parado), `batidas` por segundo.
@export var batida := 0.0
@export var batidas := 5.0


func _ready() -> void:
	visible = false
	if flag and GameState.has_flag(flag):
		set_process(false)


func _process(_delta: float) -> void:
	if Events.is_modal_open or (condition and not condition.is_met()):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var meio := global_position + get_parent_node_3d().global_basis * deslocamento * 0.5
	var para := meio - cam.global_position
	if para.length() > distancia:
		return
	if rad_to_deg(para.angle_to(-cam.global_basis.z)) > angulo:
		return
	set_process(false)
	_passar()


func _passar() -> void:
	if flag:
		GameState.set_flag(flag)
	GameState.add(&"exposicao", exposure)
	await get_tree().create_timer(atraso).timeout
	if not is_inside_tree():
		return
	visible = true
	var asas: Tween
	if batida > 0.0:
		var base := scale
		asas = create_tween().set_loops()
		asas.tween_property(self, "scale:y", base.y * (1.0 - batida), 0.5 / batidas)
		asas.tween_property(self, "scale:y", base.y * (1.0 + batida), 0.5 / batidas)
	var tween := create_tween()
	tween.tween_property(self, "position", position + deslocamento, duracao)
	await tween.finished
	if asas:
		asas.kill()
	visible = false
