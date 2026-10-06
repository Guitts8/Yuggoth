extends Node
## Descartável: o lapso (um dia), a pedra do sonho no exame e a criatura no céu,
## em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	# O lapso: de pé no meio da sala, olhando para a lareira; ele vira para a janela.
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 6)
	GameState.set_flag(&"tocou_disco")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	var esc: Escritorio = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	esc.player.global_position = Vector3(0.2, 0, -0.8)
	esc.player.rotation.y = -PI / 2
	esc.player.head.rotation.x = 0.0
	await _s(0.5)
	esc.passar_tempo(load("res://narrative/narration/cartao_6_setembro.tres"))
	var t := 0.0
	for marca in [1.8, 2.6, 3.6, 5.3, 6.5, 7.6]:
		await _s(marca - t)
		t = marca
		_shot("%s_lapso_%.1f" % [tag, marca])
	while esc.em_lapso:
		await _s(0.2)
	# A criatura (Dia 3, depois do disco).
	GameState.set_value(&"dia", 3)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	esc = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	esc.player.global_position = Vector3(0, 0, -1.4)
	esc.player.rotation = Vector3.ZERO
	esc.player.head.rotation.x = deg_to_rad(8)
	await _s(2.1)
	_shot("%s_migo" % tag)
	# A pedra do sonho, no exame.
	GameState.set_value(&"dia", 4)
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(0.5)
	esc = root.find_child("Escritorio", true, false)
	Narrator.cancel()
	await SceneDirector.fade_out(0.1)
	esc._sonhar(4)
	await _s(3.0)
	esc.find_child("Noite4", true, false).get_node("Pedra/Examinar").interact(esc.player)
	await _s(1.0)
	_shot("%s_pedra" % tag)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
