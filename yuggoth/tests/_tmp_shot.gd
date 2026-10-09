extends Node
## Descartável (playtest 5, Fase 3f, item 19): a loucura do sonho do disco — os
## vultos que viram o rosto, a lanterna que anda, os pedaços do escritório, a
## visão dupla na voz zumbida. Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 3)
	GameState.set_flag(&"comecou_dia_3")
	GameState.set_flag(&"tocou_disco")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	var e: Escritorio = root.find_child("Escritorio", true, false)
	GameState.set_value(&"sonhando", 3)
	GameState.set_value(&"sonho", 1.0)
	e._esconder_sala(true)
	e.world_env.environment = e.ambientes_sonho.get(3, e.env_sonho)
	var noite: Node3D = e.find_child("Noite3", true, false)
	var p := e._lugar_sono(3).assento.global_position
	e.player.global_position = Vector3(p.x, 0, p.z)
	e.player.input_enabled = false
	var boca: Vector3 = (noite.get_node("Vulto1") as Node3D).global_position
	e.player.olhar_para(boca + Vector3(0, 1.2, 0), 0.01)
	await _s(0.8)
	_shot("%s_1_vultos_de_costas" % tag)
	# Vira as costas por um tempo; os vultos viram, a lanterna anda, os pedaços aparecem.
	e.player.olhar_para(e.player.global_position + Vector3(0, 1.4, 6), 0.01)
	await _s(18.0)
	e.player.olhar_para(boca + Vector3(0, 1.2, 0), 0.01)
	await _s(0.5)
	_shot("%s_2_vultos_virados" % tag)
	for a in 4:
		var ang := a * PI / 2.0 + 0.6
		e.player.olhar_para(e.player.global_position + Vector3(sin(ang) * 5, 1.0, cos(ang) * 5), 0.01)
		await _s(0.4)
		_shot("%s_3_volta_%d" % [tag, a])
	# A visão dupla: o disco na voz zumbida.
	var disco: Fonografo = noite.get_node("Fonografo/Disco")
	var zumbida := 0.0
	for i in disco.gravacao.tipos.size():
		if disco.gravacao.tipos[i] == Gravacao.Tipo.ZUMBIDA:
			zumbida = disco.gravacao.inicios[i] + 0.5
			break
	disco.tocar(zumbida)
	e.player.olhar_para(disco.global_position + Vector3(0, 0.2, 0), 0.01)
	await _s(2.0)
	_shot("%s_4_visao_dupla" % tag)
	disco.parar()
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
