extends Node
## Descartável: o maço de cartas do Prólogo, o pacote do expresso (Dia 3) e o
## maço do Dia 5, em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	# Prólogo: o maço na mesa de 1930.
	GameState.reset()
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(6.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	_mirar(esc.player, Vector3(0.0, 0, -1.55), esc.caixa.global_position)
	await _s(1.0)
	_shot("%s_prologo" % tag)
	for dia in [3, 5]:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", dia)
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
		await _s(1.0)
		esc = root.find_child("Escritorio", true, false)
		Narrator.cancel()
		var no_chao: Correspondencia = esc.find_child("Dia%d" % dia, true, false).get_node("%s/Correio" % ("Pacote" if dia == 3 else "Maco"))
		var alvo := no_chao.get_visual().global_position
		_mirar(esc.player, alvo + Vector3(0.0, 0, -0.9), alvo)
		await _s(1.0)
		Narrator.cancel()
		_shot("%s_d%d_chao" % [tag, dia])
		no_chao.interact(esc.player)
		(esc.get_node(^"%PorNaMesa") as MesaCorreio).interact(esc.player)
		_mirar(esc.player, Vector3(0.1, 0, -1.4), Vector3(0.1, 0.78, -2.15))
		await _s(1.0)
		_shot("%s_d%d_mesa" % [tag, dia])
		no_chao.interact(esc.player)
		await _s(1.0)
		_shot("%s_d%d_aberto" % [tag, dia])
	SaveSystem.delete_save()
	get_tree().quit()


func _mirar(player: Player, de: Vector3, ponto: Vector3) -> void:
	player.global_position = de
	player.look_at(Vector3(ponto.x, de.y, ponto.z))
	var olho := de + Vector3(0, player.eye_height, 0)
	player.head.rotation.x = atan2(ponto.y - olho.y, Vector2(ponto.x - olho.x, ponto.z - olho.z).length())


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
