extends Node
## Descartável (playtest 4): a folha entrando no envelope, vista de lado e de
## cima, quadro a quadro. Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	var esc := await _escritorio(1)
	esc.player.global_position = Vector3(0.05, 0, -1.48)
	var reply: ReplyData = load("res://narrative/replies/resposta_dia_1.tres")
	esc._on_reply_written(reply, reply.options[0])
	var cam := Camera3D.new()
	esc.add_child(cam)
	var alvo := Escritorio.SELAGEM_POS + Vector3(0, 0.006, 0.2)
	var lados := [Vector3(0.32, 0.06, 0.12), Vector3(0.0, 0.32, 0.36)]
	cam.fov = 40
	var t0 := Time.get_ticks_msec()
	var i := 0
	while (Time.get_ticks_msec() - t0) < 7500:
		await get_tree().process_frame
		var t := (Time.get_ticks_msec() - t0) / 1000.0
		if t > 4.2 + i * 0.25:
			for k in lados.size():
				cam.global_position = alvo + lados[k]
				cam.look_at(alvo)
				cam.make_current()
				await RenderingServer.frame_post_draw
				_shot("%s_lado%d_%02d" % [tag, k, i])
			esc.player.camera.make_current()
			i += 1
	SaveSystem.delete_save()
	get_tree().quit()


func _escritorio(dia: int) -> Escritorio:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", dia)
	for n in range(1, dia + 1):
		GameState.set_flag(StringName("comecou_dia_%d" % n))
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	return root.find_child("Escritorio", true, false)


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
