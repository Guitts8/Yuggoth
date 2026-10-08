extends Node
## Descartável (playtest 4): a poltrona e a mesinha; o sonho do disco no bosque;
## as janelas dos sonhos em 3D; os mi-gos. Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var so := OS.get_environment("SHOT_SO")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)

	if so == "" or so == "sala":
		var e := await _escritorio(5, [&"lareira_dia_5", &"anotou_dia_5", &"serviu_uisque"])
		for v: Array in [["porta", Vector3(-0.9, 0, 2.4), Vector3(1.8, 0.7, -0.2)], ["centro", Vector3(-0.6, 0, 0.6), Vector3(2.3, 0.6, 0.0)],
				["mesa", Vector3(0.6, 0, -1.4), Vector3(0.7, 0.78, -2.2)]]:
			_olhar(e, v[1], v[2])
			await _s(0.6)
			_shot("%s_sala_%s" % [tag, v[0]])

	if so == "" or so == "janelas":
		for n in [2, 4]:
			var e := await _escritorio(n + 1, [])
			GameState.set_value(&"sonhando", n)
			e.world_env.environment = e.env_sonho
			GameState.set_value(&"sonho", 1.0)
			_olhar(e, Vector3(0, 0, -1.5), Vector3(0, 1.4, -6.0))
			await _s(0.8)
			_shot("%s_janela_noite%d" % [tag, n])
			GameState.set_value(&"sonho", 0.0)

	if so == "" or so == "migos":
		var e := await _escritorio(5, [&"leu_bilhete_akeley_agosto"])
		_olhar(e, Vector3(0, 0, -1.6), Vector3(0, 1.65, -6.0))
		var sombra: Node3D = e.find_child("Sombra", true, false)
		for k in 12:
			await _s(0.2)
			print("sombra visivel=", sombra.visible, " pos=", sombra.global_position, " flag=", GameState.has_flag(&"viu_sombra_janela"))
			if sombra.visible:
				_shot("%s_sombra_%d" % [tag, k])
		e = await _escritorio(3, [&"tocou_disco"])
		_olhar(e, Vector3(0, 0, -1.4), Vector3(0, 4.0, -20.0))
		await _serie("ceu", [0.8, 1.4, 2.0, 2.6])

	if so == "" or so == "bosque":
		var e := await _escritorio(3, [&"fono_corneta", &"fono_manivela", &"fono_agulha", &"fono_cilindro", &"tocou_disco", &"anotou_dia_3"])
		GameState.set_value(&"sono", 3)
		await _s(0.3)
		var lugar := e._lugar_sono(3)
		e.player.global_position = Vector3(0.3, 0, -1.0)
		e._on_lugar_sono(null, lugar)
		await _serie("disco", [2.0, 4.0, 7.0, 12.0])
		while GameState.get_value(&"sonhando") != 3:
			await get_tree().process_frame
		await _serie("bosque", [1.0, 4.0, 6.0])
		var mouse := InputEventMouseMotion.new()
		for k in 5:
			mouse.relative = Vector2(-220, 0)
			Input.parse_input_event(mouse)
			await _s(0.5)
			_shot("%s_bosque_giro%d" % [tag, k])
		print("fono no sonho tocando: ", e.find_child("Noite3", true, false).get_node("Fonografo/Disco").tocando())
	SaveSystem.delete_save()
	get_tree().quit()


func _olhar(e: Escritorio, de: Vector3, para: Vector3) -> void:
	e.player.global_position = de
	e.player.look_at(Vector3(para.x, de.y, para.z))
	var olho := de + Vector3(0, 1.62, 0)
	e.player.head.rotation.x = atan2(para.y - olho.y, Vector2(para.x - olho.x, para.z - olho.z).length())


func _escritorio(dia: int, flags: Array) -> Escritorio:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", dia)
	for k in range(1, dia + 1):
		GameState.set_flag(StringName("comecou_dia_%d" % k))
	for f: StringName in flags:
		GameState.set_flag(f)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	return root.find_child("Escritorio", true, false)


func _serie(nome: String, tempos: Array) -> void:
	var t0 := Time.get_ticks_msec()
	for i in tempos.size():
		while (Time.get_ticks_msec() - t0) / 1000.0 < tempos[i]:
			await get_tree().process_frame
		_shot("%s_%s_%d" % [tag, nome, i])


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
