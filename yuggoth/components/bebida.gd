class_name Bebida
extends Node3D
## O café e o uísque de Wilmarth (docs/PLANO_ESCRITORIO.md, Fase 3d) 💭: antes de
## anotar o dia, sentado à mesa, ele se serve — café da garrafa térmica nos
## primeiros dias (para render mais), uísque do frasco escondido na gaveta nos
## últimos (é 1928, a Lei Seca: para os nervos). O frasco volta para a gaveta
## assim que serve (playtest 4: "o uísque é escondido"); a xícara e o copo ficam
## na mesa.
##
## `await cafe(player)` / `await uisque(player)`: serve e bebe um gole; `await
## gole(player, recipiente)` só bebe (o copo já servido, junto à lareira). Quem
## chama já sentou Wilmarth. Peças feitas pelo gerador; aqui, só o movimento.
## Recipientes têm um filho "Nivel" (o líquido), escondido enquanto vazios.

@export var garrafa: Node3D
@export var xicara: Node3D
## O frasco mora dentro da gaveta (filho dela); sai só para servir, em pé sobre
## a mesa em `frasco_servindo` (no espaço do pai da gaveta), e volta.
@export var frasco: Node3D
@export var copo: Node3D
@export var gaveta: Node3D
@export var frasco_servindo := Transform3D.IDENTITY
@export var som_servir: AudioStream
@export var som_gaveta: AudioStream


func _ready() -> void:
	_repor()


## O copo fica na mesa depois do primeiro uísque (`frasco_na_mesa` é o nome
## antigo da flag, de saves da 3d).
func _repor() -> void:
	if copo:
		copo.visible = GameState.has_flag(&"serviu_uisque") or GameState.has_flag(&"frasco_na_mesa")


## Café da garrafa térmica na xícara, e um gole.
func cafe(player: Player) -> void:
	await _servir(player, garrafa, xicara, 1.0)
	await gole(player, xicara)


## A gaveta abre, o frasco sai, o uísque no copo, e o frasco volta escondido
## para a gaveta, que fecha; um gole.
func uisque(player: Player) -> void:
	copo.visible = true
	var fechada := gaveta.position
	await player.olhar_para(gaveta.global_position + Vector3.UP * 0.25, 0.9).finished
	_tocar(som_gaveta)
	var t := _tween()
	t.tween_property(gaveta, ^"position", fechada + Vector3(0, 0, 0.24), 0.7)
	await t.finished
	# Da gaveta (aberta) para a mesa, num arco; e de volta pelo mesmo caminho.
	var na_gaveta := frasco.transform
	frasco.reparent(gaveta.get_parent(), true)
	var de := frasco.transform
	await _arco(de, frasco_servindo, 1.1)
	await _servir(player, frasco, copo, 0.45)
	await player.olhar_para(gaveta.global_position + Vector3.UP * 0.25, 0.7).finished
	await _arco(frasco_servindo, de, 0.9)
	frasco.reparent(gaveta, true)
	frasco.transform = na_gaveta
	_tocar(som_gaveta)
	t = _tween()
	t.tween_property(gaveta, ^"position", fechada, 0.6)
	await t.finished
	GameState.set_flag(&"serviu_uisque")
	await gole(player, copo)


## O frasco de `de` a `ate` (no espaço do pai da gaveta), subindo no meio.
func _arco(de: Transform3D, ate: Transform3D, segundos: float) -> void:
	var t := _tween()
	t.tween_method(func(k: float) -> void:
		var x := de.interpolate_with(ate, k)
		x.origin.y += sin(k * PI) * 0.2
		frasco.transform = x, 0.0, 1.0, segundos)
	await t.finished


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
		# Na xícara, que afunila, o café alarga ao subir (rente à parede de dentro).
		var afunila: float = nivel.get_meta(&"afunila", 1.0)
		var encher := func(s: float) -> void:
			var largo := lerpf(afunila, 1.0, s)
			nivel.scale = Vector3(largo, s, largo)
		t = _tween()
		t.tween_method(encher, 0.05, cheio, 1.3)
		await t.finished
	else:
		await get_tree().create_timer(1.3).timeout
	t = _tween()
	t.tween_property(de, ^"global_transform", sobre, 0.4)
	t.tween_property(de, ^"global_transform", casa, 0.7)
	await t.finished


func _tween() -> Tween:
	return create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _tocar(som: AudioStream) -> void:
	if som:
		AudioDirector.play_sfx(som, -6.0)
