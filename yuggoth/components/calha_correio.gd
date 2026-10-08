class_name CalhaCorreio
extends Node3D
## A calha de correio de latão no corredor, diante da porta do escritório
## (docs/PLANO_ESCRITORIO.md, Fase 3d): é por ela que a carta de Wilmarth sai.
## Como nos prédios dos anos 1920, a calha desce pela parede de andar em andar,
## com a frente de vidro, até a caixa do correio no saguão; o carteiro a esvazia
## de manhã ("vai amanhã cedo, com o primeiro correio").
##
## `await postar(carta, player)`: ele vai até a porta, abre, põe a carta na boca
## da calha (a carta escorrega e se vê descer atrás do vidro), fecha a porta e
## volta a olhar a sala. Quem chama solta a carta (`CartaSaida.postar`) depois.
##
## A origem do nó é a boca da calha, virada para a porta (-Z local aponta para
## dentro da calha). O gerador põe a calha, o corredor e a folha da porta.

## A folha da porta do escritório (gira na dobradiça; aberta = `aberta` graus).
@export var folha: Node3D
@export var aberta := 78.0
## O corredor atrás da porta: só aparece enquanto ela está aberta.
@export var corredor: Node3D
## Onde Wilmarth para, diante da porta (global, no chão).
@export var diante := Vector3.ZERO
@export var som_abrir: AudioStream
@export var som_fechar: AudioStream
@export var som_calha: AudioStream
## A descida que se vê pelo vidro: de onde a carta cai até onde some (y local).
@export var queda := Vector2(0.0, -1.0)

## A vista, apertada na calha enquanto a porta está aberta.
const FOV := 55.0


func postar(carta: Node3D, player: Player) -> void:
	# Até a porta, de frente para ela.
	var macaneta := folha.global_transform * Vector3(0.82, 1.0, 0.0) if folha else global_position
	var t := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"global_position", Vector3(diante.x, player.global_position.y, diante.z), 1.1)
	await player.olhar_para(macaneta, 1.1, Vector3(diante.x, player.global_position.y, diante.z)).finished
	if not is_inside_tree():
		return

	# A porta abre para dentro; ele olha a calha do outro lado do corredor.
	if corredor:
		corredor.visible = true
	player.fov_forcado = FOV
	_tocar(som_abrir)
	t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(folha, ^"rotation_degrees:y", aberta, 1.3)
	await _pausa(0.5)
	await player.olhar_para(global_position + Vector3.DOWN * 0.08, 1.0).finished
	if t.is_running():
		await t.finished
	if not is_inside_tree():
		return

	# A carta vai da mão à boca da calha, em pé, e escorrega para dentro.
	carta.set_process(false)
	var de := carta.global_transform
	# Deitada, a borda curta na fenda (o X do envelope aponta para dentro, -Z).
	var deitada := Basis(Vector3(0, 0, -1), Vector3.UP, Vector3(1, 0, 0))
	var na_boca := global_transform * Transform3D(deitada, Vector3(0, 0.0, Envelope.LARGURA * 0.5 + 0.03))
	t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(k: float) -> void: carta.global_transform = de.interpolate_with(na_boca, k), 0.0, 1.0, 0.9)
	await t.finished
	if not is_inside_tree():
		return
	var dentro := na_boca.translated(global_basis.z * -(Envelope.LARGURA + 0.05))
	t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(carta, ^"global_transform", dentro, 0.35)
	await t.finished
	carta.visible = false
	_tocar(som_calha)

	# Atrás do vidro, a carta desce e some andar abaixo.
	var desce := _envelope_caindo()
	t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(desce, ^"position:y", queda.y, 0.75)
	await t.finished
	desce.queue_free()
	await _pausa(0.7)
	if not is_inside_tree():
		return

	# Fecha a porta e volta a olhar a sala.
	await player.olhar_para(macaneta, 0.8).finished
	t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(folha, ^"rotation_degrees:y", 0.0, 1.0)
	await t.finished
	_tocar(som_fechar)
	if corredor:
		corredor.visible = false
	player.fov_forcado = 0.0
	if not is_inside_tree():
		return
	await player.olhar_para(diante + Vector3(0.6, 1.0, -3.0), 1.2).finished


## Um envelope de pé dentro da calha, atrás do vidro, na altura da boca.
func _envelope_caindo() -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.1, 0.17, 0.004)
	var mi := MeshInstance3D.new()
	mi.name = "_Caindo"
	mi.mesh = mesh
	mi.material_override = Selagem._material("res://art/materials/envelope.tres")
	mi.position = Vector3(0, queda.x, -0.03)
	add_child(mi)
	return mi


func _pausa(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


func _tocar(som: AudioStream) -> void:
	if som:
		AudioDirector.play_sfx(som, -4.0)
