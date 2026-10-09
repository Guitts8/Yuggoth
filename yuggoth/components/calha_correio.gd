class_name CalhaCorreio
extends Node3D
## A calha de correio de latão no corredor, diante da porta do escritório
## (docs/PLANO_ESCRITORIO.md, Fases 3d, 3e e 3f): é por ela que a carta de
## Wilmarth sai. Como nos prédios dos anos 1920, a calha desce pela parede de
## andar em andar, com a frente de vidro, até a caixa do correio no saguão; o
## carteiro a esvazia de manhã ("vai amanhã cedo, com o primeiro correio").
##
## Duas ações (playtest 5: "a tela deve ficar solta"): `abrir(player)` o leva à
## porta (ao lado da maçaneta, fora do arco da folha) e a abre; dali o corredor é
## dele. `por_na_calha(carta, player)` (a área `PorNaCalha`) põe a carta na boca:
## ela escorrega e se vê descer atrás do vidro. Quem chama solta a carta
## (`CartaSaida.postar`) depois. De volta à sala, a porta fecha sozinha
## (`fechar_sozinha`, quem decide é o Escritorio). De manhã, ele chega pelo
## corredor: `abrir_de_fora(player)`.
##
## A origem do nó é a boca da calha, virada para a porta (-Z local aponta para
## dentro da calha). O gerador põe a calha, o corredor e a folha da porta.

## A folha da porta do escritório (gira na dobradiça; aberta = `aberta` graus).
@export var folha: Node3D
@export var aberta := 78.0
## A largura da folha: o arco que ela varre ao fechar.
@export var largura_folha := 0.92
## O corredor atrás da porta: aparece com a porta aberta ou com ele lá fora.
@export var corredor: Node3D
## Onde Wilmarth para para abrir a porta (global, no chão): ao lado da
## maçaneta, fora do arco da folha (playtest 4: a porta o atravessava).
@export var diante := Vector3.ZERO
## O mesmo, do lado do corredor (de manhã, chegando).
@export var diante_fora := Vector3.ZERO
## A soleira da porta (global, no chão) e o lugar diante da calha, no corredor.
@export var soleira := Vector3.ZERO
@export var na_calha := Vector3.ZERO
@export var som_abrir: AudioStream
@export var som_fechar: AudioStream
@export var som_calha: AudioStream
## A descida que se vê pelo vidro: de onde a carta cai até onde some (y local).
@export var queda := Vector2(0.0, -1.0)

var porta_aberta := false
## A folha está girando (abrindo ou fechando).
var movendo := false


## Põe a carta na boca da calha (ele está no corredor): a carta escorrega para
## dentro e desce atrás do vidro; ele a acompanha com os olhos.
func por_na_calha(carta: Node3D, player: Player) -> void:
	var estava := player.conduzido
	await player.conduzir([na_calha], global_position + Vector3.DOWN * 0.1, 0.9)
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
	player.conduzido = estava


## Vai até a porta, de frente para a maçaneta, e a abre para dentro; o corredor
## aparece.
func abrir(player: Player) -> void:
	await _abrir(player, diante, _macaneta(), soleira + Vector3(0, 1.4, 1.0))


## De manhã, chegando pelo corredor: a maçaneta de fora; a folha abre para longe
## dele, para dentro da sala.
func abrir_de_fora(player: Player) -> void:
	await _abrir(player, diante_fora, _macaneta(0.05), soleira + Vector3(0, 1.3, -1.5))


func _abrir(player: Player, onde: Vector3, macaneta: Vector3, depois: Vector3) -> void:
	movendo = true
	var estava := player.conduzido
	player.conduzido = true
	await player.conduzir([onde], macaneta)
	if not is_inside_tree():
		return
	if corredor:
		corredor.visible = true
	_tocar(som_abrir)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(folha, ^"rotation_degrees:y", aberta, 1.3)
	# Enquanto ela abre, os olhos vão para o outro lado.
	player.olhar_para(depois, 1.3)
	await t.finished
	porta_aberta = true
	movendo = false
	player.conduzido = estava


## A porta fecha sozinha atrás dele (a mola do fecho), sem levá-lo a ela.
func fechar_sozinha() -> void:
	movendo = true
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(folha, ^"rotation_degrees:y", 0.0, 1.4)
	await t.finished
	_tocar(som_fechar)
	porta_aberta = false
	movendo = false


## Fechada de uma vez (no escuro da virada do dia).
func fechar_ja() -> void:
	if folha:
		folha.rotation_degrees.y = 0.0
	porta_aberta = false
	movendo = false


## Longe o bastante da dobradiça para a folha fechar sem passar por `ponto`.
func fora_do_arco(ponto: Vector3) -> bool:
	var dobradica := folha.global_position
	return Vector2(ponto.x - dobradica.x, ponto.z - dobradica.z).length() > largura_folha + 0.25


## Do lado do corredor (passou da soleira).
func do_lado_de_fora(ponto: Vector3) -> bool:
	return ponto.z > folha.global_position.z + 0.05 if folha else false


## A maçaneta, do lado da sala (`lado` < 0) ou do corredor (> 0).
func _macaneta(lado := -0.1) -> Vector3:
	return folha.global_transform * Vector3(0.82, 1.0, lado) if folha else global_position


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
