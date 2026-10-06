extends Node
## Descartável: cada resposta a Akeley no leitor (como no dossiê), página por
## página, em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	var root: Node = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	var reader = root.get_node("UI/DocumentReader")
	for arquivo in DirAccess.get_files_at("res://narrative/documents"):
		if not arquivo.begins_with("resposta_"):
			continue
		var doc := load("res://narrative/documents/" + arquivo.trim_suffix(".remap")) as DocumentData
		reader.open(doc)
		await _s(0.3)
		for p in reader._pages.size():
			reader._page = p
			reader._show_page()
			await _s(0.1)
			_shot("%s_%s_p%d" % [tag, doc.id, p + 1])
		reader.close()
		await _s(0.1)
	SaveSystem.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
