class_name Bebida
extends Node3D
## O café e o uísque de Wilmarth (docs/PLANO_ESCRITORIO.md, Fase 3d) 💭: antes de
## anotar o dia, sentado à mesa, ele se serve — café da garrafa térmica nos
## primeiros dias (para render mais), uísque do frasco escondido na gaveta nos
## últimos (é 1928, a Lei Seca: para os nervos). A xícara e o copo ficam na mesa.
##
## `await cafe(player)` / `await uisque(player)`: serve e bebe um gole; `await
## gole(player, recipiente)` só bebe (o copo já servido, junto à lareira). Quem
## chama já sentou Wilmarth. Peças feitas pelo gerador; aqui, só o movimento.
## Recipientes têm um filho "Nivel" (o líquido), escondido enquanto vazios.

@export var garrafa: Node3D
@export var xicara: Node3D
## O frasco começa dentro da gaveta (filho dela); servido o uísque, vai para a
## mesa (`frasco_na_mesa`, no espaço do pai da gaveta) e não volta mais.
@export var frasco: Node3D
@export var copo: Node3D
@export var gaveta: Node3D
@export var frasco_na_mesa := Transform3D.IDENTITY
@export var som_servir: AudioStream
@export var som_gaveta: AudioStream


func _ready() -> void:
	# Depois que a gaveta e o frasco estiverem prontos (reparent no _ready falha).
	_repor.call_deferred()


func _repor() -> void:
	if GameState.has_flag(&"frasco_na_mesa"):
		_frasco_para_a_mesa()
		frasco.transform = frasco_na_mesa
	if copo:
		copo.visible = GameState.has_flag(&"frasco_na_mesa")


## Café da garrafa térmica na xícara, e um gole.
func cafe(player: Player) -> void:
	await _servir(player, garrafa, xicara, 1.0)
	await gole(player, xicara)


## A gaveta abre, o frasco sai para a mesa, o uísque no copo; um gole.
func uisque(player: Player) -> void:
	copo.visible = true
	if not GameState.has_flag(&"frasco_na_mesa"):
		var fechada := gaveta.position
		await player.olhar_para(gaveta.global_position + Vector3.UP * 0.25, 0.9).finished
		_tocar(som_gaveta)
		var t := _tween()
		t.tween_property(gaveta, ^"position", fechada + Vector3(0, 0, 0.24), 0.7)
		await t.finished
		_frasco_para_a_mesa()
		var de := frasco.transform
		t = _tween()
		t.tween_method(func(k: float) -> void:
			var x := de.interpolate_with(frasco_na_mesa, k)
			x.origin.y += sin(k * PI) * 0.2
			frasco.transform = x, 0.0, 1.0, 1.1)
		await t.finished
		_tocar(som_gaveta)
		t = _tween()
		t.tween_property(gaveta, ^"position", fechada, 0.6)
		await t.finished
		GameState.set_flag(&"frasco_na_mesa")
	await _servir(player, frasco, copo, 0.45)
	await gole(player, copo)


## O recipiente vem à boca (embaixo do centro da vista), inclina, e volta.
func gole(player: Player, recipiente: Node3D) -> void:
	var casa := recipiente.global_transform
	var cam := player.camera
	var boca := func(inclina: float) -> Transform3D:
		return cam.global_transform * Transform3D(Basis.from_euler(Vector3(deg_to_rad(inclina), 0, 0)), Vector3(0.0, -0.17, -0.33))
	var t := _tween()
	t.tween_method(func(k: float) -> void: recipiente.global_transform = casa.interpolate_with(boca.call(10.0), k), 0.0, 1.0, 1.1)
	await t.finished
	t = _tween()
	t.tween_method(func(k: float) -> void: recipiente.global_transform = boca.call(10.0 + 45.0 * sin(k * PI)), 0.0, 1.0, 1.6)
	await t.finished
	var de := recipiente.global_transform
	t = _tween()
	t.tween_method(func(k: float) -> void: recipiente.global_transform = de.interpolate_with(casa, k), 0.0, 1.0, 1.1)
	await t.finished


## O que serve vai sobre o recipiente, inclina, o líquido sobe até `cheio`, e
## o que serve volta ao lugar.
func _servir(player: Player, de: Node3D, para: Node3D, cheio: float) -> void:
	await player.olhar_para(para.global_position, 0.8).finished
	var casa := de.global_transform
	# Inclina de lado para quem olha, com a boca (o filho "Boca") sobre o
	# recipiente; antes, chega em pé um pouco acima de onde vai inclinar.
	var boca := de.get_node_or_null(^"Boca") as Node3D
	var boca_local := boca.position if boca else Vector3(0, 0.25, 0)
	var eixo := -player.camera.global_basis.z
	eixo.y = 0.0
	eixo = eixo.normalized() if eixo.length() > 0.01 else Vector3.FORWARD
	var base := casa.basis.rotated(eixo, deg_to_rad(-78.0))
	var inclinado := Transform3D(base, para.global_position + Vector3(0, 0.09, 0) - base * boca_local)
	var sobre := Transform3D(casa.basis, inclinado.origin + Vector3(0, 0.06, 0))
	var t := _tween()
	t.tween_property(de, ^"global_transform", sobre, 0.8)
	t.tween_property(de, ^"global_transform", inclinado, 0.5)
	await t.finished
	_tocar(som_servir)
	var nivel := para.get_node_or_null(^"Nivel") as Node3D
	if nivel:
		nivel.visible = true
		nivel.scale.y = 0.05
		t = _tween()
		t.tween_property(nivel, ^"scale:y", cheio, 1.3)
		await t.finished
	else:
		await get_tree().create_timer(1.3).timeout
	t = _tween()
	t.tween_property(de, ^"global_transform", sobre, 0.4)
	t.tween_property(de, ^"global_transform", casa, 0.7)
	await t.finished


func _frasco_para_a_mesa() -> void:
	if frasco.get_parent() == gaveta:
		frasco.reparent(gaveta.get_parent(), true)


func _tween() -> Tween:
	return create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _tocar(som: AudioStream) -> void:
	if som:
		AudioDirector.play_sfx(som, -6.0)
