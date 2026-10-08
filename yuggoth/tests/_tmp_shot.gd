extends Node
## Descartável (playtest 4): o Dia 5 do save do usuário — a lareira pela mira.
## Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node
var p: Player


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	DirAccess.copy_absolute(OS.get_environment("SHOT_SAVE"), ProjectSettings.globalize_path(SaveSystem.save_path))
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = true
	add_child(root)
	await _s(0.5)
	root.continue_game()
	await _s(4.0)
	while SceneDirector.is_busy:
		await get_tree().process_frame
	var e: Escritorio = root.find_child("Escritorio", true, false)
	p = e.player
	await _s(2.0)
	Narrator.cancel()
	for pos in [Vector3(1.6, 0, -0.6), Vector3(1.4, 0, -0.9), Vector3(1.8, 0, -0.3)]:
		p.global_position = pos
		p.look_at(Vector3(2.4, 0, -0.6))
		var olho := p.global_position + Vector3(0, 1.62, 0)
		p.head.rotation.x = atan2(0.3 - olho.y, Vector2(2.3 - olho.x, -0.6 - olho.z).length())
		await _s(0.4)
		print("lareira de ", pos, ": alvo=", p._target, " (", p._target_prompt, ")")
	_tecla(&"interagir")
	await _s(1.0)
	print("acesa=", GameState.has_flag(&"lareira_dia_5"))
	_shot("%s_fogo" % tag)
	get_tree().quit()


func _tecla(acao: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = true
	Input.parse_input_event(ev)
	var solta := InputEventAction.new()
	solta.action = acao
	Input.parse_input_event.call_deferred(solta)


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
