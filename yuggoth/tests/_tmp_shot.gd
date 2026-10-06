extends Node
## Descartável: o correio pela fresta (Dia 1 tarde, Dia 2 fotos, Dia 3 pacote à
## noite) em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	for dia in [1, 2, 3]:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", dia)
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
		await _s(1.0)
		var esc: Escritorio = root.find_child("Escritorio", true, false)
		var player := esc.player
		Narrator.cancel()
		var correio: Correspondencia = esc.find_child("Dia%d" % dia, true, false).find_children("*", "Correspondencia", true, false)[0]
		# Da porta, olhando o chão onde o correio caiu.
		var chao := correio.get_visual().global_position
		player.global_position = Vector3(-1.0, 0, 2.6)
		player.look_at(Vector3(chao.x, 0, chao.z))
		await _s(0.2)
		var olho := player.camera.global_position
		player.head.rotation.x = atan2(chao.y - olho.y, Vector2(chao.x - olho.x, chao.z - olho.z).length())
		await _s(2.5)
		Narrator.cancel()
		await _s(0.3)
		_shot("%s_d%d_chao" % [tag, dia])
		# Na mão, a caminho da mesa.
		correio.interact(player)
		player.global_position = Vector3(-0.3, 0, -0.6)
		player.look_at(Vector3(0, 0, -2.3))
		player.head.rotation.x = deg_to_rad(-25)
		await _s(0.8)
		_shot("%s_d%d_mao" % [tag, dia])
		# Na mesa, fechado; depois aberto.
		(esc.get_node(^"%PorNaMesa") as MesaCorreio).interact(player)
		player.global_position = Vector3(0, 0, -1.35)
		player.rotation.y = 0
		player.head.rotation.x = deg_to_rad(-38)
		await _s(0.8)
		_shot("%s_d%d_mesa" % [tag, dia])
		correio.interact(player)
		for i in 3 if dia == 2 else 0:
			await _s(0.5)
			correio.interact(player)
		await _s(1.0)
		_shot("%s_d%d_aberto" % [tag, dia])
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
