extends Node
## Descartável (item 12): reproduz a conferência "carta longa paginada sem
## estourar o papel" do teste de fumaça, imprimindo as alturas.

var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await get_tree().create_timer(0.5).timeout
	var reader = root.get_node("UI/DocumentReader")
	var carta1: DocumentData = load("res://narrative/documents/carta_akeley_1.tres")
	for vez in 2:
		reader.open(carta1)
		for i in 3:
			await get_tree().process_frame
		print("vez %d: %d páginas (fonte %d), papel %.1f" % [vez, reader._pages.size(), carta1.pages.size(), reader.body.size.y])
		for i in reader._pages.size():
			reader._page = i
			reader._show_page()
			var h: float = reader.body.get_content_height()
			if h > reader.body.size.y + 1:
				print("  página %d transborda: %.1f > %.1f" % [i, h, reader.body.size.y])
		reader.close()
		await get_tree().process_frame
	get_tree().quit()
