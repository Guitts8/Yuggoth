extends Node
## Descartável: o diário (Dia 1, sem sonho; Dia 2, a linha que falha, o sono,
## o sonho e a manhã), em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	for n in [1, 2]:
		GameState.reset()
		GameState.set_flag(&"prologo_concluido")
		GameState.set_value(&"dia", n)
		GameState.set_flag(StringName("escreveu_resposta_dia_%d" % n))
		GameState.set_flag(StringName("comecou_dia_%d" % n))
		if n == 2:
			GameState.add_document(load("res://narrative/documents/diario_dia_1.tres"))
		await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
		await _s(1.0)
		var esc: Escritorio = root.find_child("Escritorio", true, false)
		Narrator.cancel()
		esc.player.global_position = Vector3(-0.2, 0, -1.2)
		esc.player.look_at(Vector3(-0.45, 0.0, -2.0))
		esc.player.head.rotation.x = deg_to_rad(-30)
		GameState.set_value(&"diario", n)
		await _s(0.8)
		_shot("%s_d%d_0mesa" % [tag, n])
		esc._on_anotar(null)
		var tempos := [3.0, 9.0, 14.0] if n == 1 else [9.0, 15.0, 19.0, 22.5, 26.0, 31.0, 34.5, 38.0, 43.0]
		var t0 := Time.get_ticks_msec()
		for i in tempos.size():
			while (Time.get_ticks_msec() - t0) / 1000.0 < tempos[i]:
				await get_tree().process_frame
			_shot("%s_d%d_%d" % [tag, n, i + 1])
		if n == 2:
			GameState.set_flag(&"narrou_sonho_garra")
			t0 = Time.get_ticks_msec()
			for t in [6.5, 9.0, 12.5]:
				while (Time.get_ticks_msec() - t0) / 1000.0 < t:
					await get_tree().process_frame
				_shot("%s_d2_manha_%d" % [tag, int(t * 10)])
		await _s(4.0)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
