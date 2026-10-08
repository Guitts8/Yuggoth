class_name CalhaCorreio
extends Node3D
## A calha de correio de latão no corredor, diante da porta do escritório
## (docs/PLANO_ESCRITORIO.md, Fases 3d e 3e): é por ela que a carta de Wilmarth
## sai. Como nos prédios dos anos 1920, a calha desce pela parede de andar em
## andar, com a frente de vidro, até a caixa do correio no saguão; o carteiro a
## esvazia de manhã ("vai amanhã cedo, com o primeiro correio").
##
## `await postar(carta, player)`: ele vai até a porta (ao lado da maçaneta, fora
## do arco da folha), abre, atravessa a soleira até a calha, põe a carta na boca
## (ela escorrega e se vê descer atrás do vidro), volta e fecha a porta. Quem
## chama solta a carta (`CartaSaida.postar`) depois. Durante tudo, a cena o
## conduz (`Player.conduzido`), e a cabeça continua dele.
##
## `abrir(player)` e `fechar(player)` servem também para sair do escritório no
## fim do dia (Escritorio, "Ir para casa").
##
## A origem do nó é a boca da calha, virada para a porta (-Z local aponta para
## dentro da calha). O gerador põe a calha, o corredor e a folha da porta.

## A folha da porta do escritório (gira na dobradiça; aberta = `aberta` graus).
@export var folha: Node3D
@export var aberta := 78.0
## O corredor atrás da porta: só aparece enquanto ela está aberta.
@export var corredor: Node3D
## Onde Wilmarth para para abrir a porta (global, no chão): ao lado da
## maçaneta, fora do arco da folha (playtest 4: a porta o atravessava).
@export var diante := Vector3.ZERO
## A soleira da porta (global, no chão) e o lugar diante da calha, no corredor.
@export var soleira := Vector3.ZERO
@export var na_calha := Vector3.ZERO
@export var som_abrir: AudioStream
@export var som_fechar: AudioStream
@export var som_calha: AudioStream
## A descida que se vê pelo vidro: de onde a carta cai até onde some (y local).
@export var queda := Vector2(0.0, -1.0)

var porta_aberta := false


func postar(carta: Node3D, player: Player) -> void:
	player.conduzido = true
	await abrir(player)
	if not is_inside_tree():
		return
	# Pela soleira até a calha, olhando a boca dela.
	await player.conduzir([soleira, na_calha], global_position + Vector3.DOWN * 0.1)
	if not is_inside_tree():
		return

	# A carta vai da mão à boca da calha, deitada, e escorrega para dentro.
	carta.set_process(false)
	var de := carta.global_transform
	# Deitada, a borda curta na fenda (o X do envelope aponta para dentro, -Z).
	var deitada := Basis(Vector3(0, 0, -1), Vector3.UP, Vector3(1, 0, 0))
	var na_boca := global_transform * Transform3D(deitada, Vector3(0, 0.0, Envelope.LARGURA * 0.5 + 0.03))
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(k: float) -> void: carta.global_transform = de.interpolate_with(na_boca, k), 0.0, 1.0, 0.8)
	await t.finished
	if not is_inside_tree():
		return
	var dentro := na_boca.translated(global_basis.z * -(Envelope.LARGURA + 0.05))
	t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(carta, ^"global_transform", dentro, 0.35)
	await t.finished
	carta.visible = false
	_tocar(som_calha)

	# Atrás do vidro, a carta desce e some andar abaixo; ele a acompanha.
	var desce := _envelope_caindo()
	player.olhar_para(global_position + Vector3.DOWN * 0.8, 1.0)
	t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(desce, ^"position:y", queda.y, 0.75)
	await t.finished
	desce.queue_free()
	await _pausa(0.6)
	if not is_inside_tree():
		return

	# De volta à sala, e fecha a porta.
	await player.conduzir([soleira, diante], _macaneta())
	if not is_inside_tree():
		return
	await fechar(player)
	player.conduzido = false
	if not is_inside_tree():
		return
	await player.olhar_para(diante + Vector3(0.4, 1.0, -3.0), 1.0).finished


## Vai até a porta, de frente para a maçaneta, e a abre para dentro; o corredor
## aparece.
func abrir(player: Player) -> void:
	var estava := player.conduzido
	player.conduzido = true
	await player.conduzir([diante], _macaneta())
	if not is_inside_tree():
		return
	if corredor:
		corredor.visible = true
	_tocar(som_abrir)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(folha, ^"rotation_degrees:y", aberta, 1.3)
	# Enquanto ela abre, os olhos vão para o corredor.
	player.olhar_para(soleira + Vector3(0, 1.4, 1.0), 1.3)
	await t.finished
	porta_aberta = true
	player.conduzido = estava


## Fecha a porta (ele está diante dela, do lado da sala); o corredor some.
func fechar(player: Player) -> void:
	await player.olhar_para(_macaneta(), 0.6).finished
	if not is_inside_tree():
		return
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(folha, ^"rotation_degrees:y", 0.0, 1.0)
	await t.finished
	_tocar(som_fechar)
	porta_aberta = false
	if corredor:
		corredor.visible = false


## Fechada de uma vez (no escuro da virada do dia).
func fechar_ja() -> void:
	if folha:
		folha.rotation_degrees.y = 0.0
	porta_aberta = false
	if corredor:
		corredor.visible = false


func _macaneta() -> Vector3:
	return folha.global_transform * Vector3(0.82, 1.0, 0.0) if folha else global_position


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
