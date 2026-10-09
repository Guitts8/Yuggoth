class_name Espreita
extends Node3D
## O que muda quando ninguém está olhando (docs/PLANO_ESCRITORIO.md, Fase 3f: o
## sonho do disco, "um efeito de loucura"). Fora da vista por `intervalo`
## segundos, dá um passo:
## - `aparecer`: começa escondido e aparece (os pedaços do escritório no bosque);
## - `virar`: vira o rosto (+Z) para quem olha (os vultos que viram a cabeça);
## - `pontos`: vai para o próximo lugar (global) da lista (a lanterna que anda).
## Nunca muda à vista: quem olha só encontra a coisa já mudada. Sem som.

@export var aparecer := false
@export var virar := false
@export var pontos: PackedVector3Array = []
## Segundos fora da vista entre um passo e outro (e antes do primeiro).
@export var intervalo := 3.0
## Antes disso, nada muda (segundos desde que apareceu à vista do jogo).
@export var espera := 0.0
## Ângulo (graus) a partir do centro da tela dentro do qual conta como visto.
@export var angulo_visto := 55.0
## Altura do ponto que se olha (o rosto, a chama).
@export var altura := 1.2

var _fora := 0.0
var _vivo := 0.0
var _passo := 0


func _ready() -> void:
	if aparecer:
		visible = false


func _process(delta: float) -> void:
	var pai := get_parent_node_3d()
	if pai and not pai.is_visible_in_tree():
		_vivo = 0.0
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_vivo += delta
	if _visto(cam):
		_fora = 0.0
		return
	_fora += delta
	if _vivo < espera or _fora < intervalo:
		return
	_fora = 0.0
	if aparecer and not visible:
		visible = true
		if not virar and pontos.is_empty():
			set_process(false)
		return
	if not pontos.is_empty() and _passo < pontos.size():
		global_position = pontos[_passo]
		_passo += 1
	if virar:
		var alvo := cam.global_position
		alvo.y = global_position.y
		if alvo.distance_to(global_position) > 0.1:
			look_at(alvo, Vector3.UP, true)


func _visto(cam: Camera3D) -> bool:
	var para := global_position + Vector3.UP * altura - cam.global_position
	return rad_to_deg(para.angle_to(-cam.global_basis.z)) < angulo_visto
