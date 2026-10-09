extends Node
## Descartável (playtest 6, Fase 3g): o Vazio nos sonhos 2, 4 e 5, a pedra nova,
## o mi-go subindo, o pacote aberto. Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)
	for n in [2, 4, 5]:
		var e := await _abrir(n)
		GameState.set_value(&"sonhando", n)
		GameState.set_value(&"sonho", 1.0)
		e.world_env.environment = e.ambientes_sonho.get(n, e.env_sonho)
		e.player.global_position = Vector3(0, 0, -1.3)
		e.player.olhar_para(Vector3(-2.5, 2.2, 1.0), 0.01)
		await _s(1.0)
		await _shot("%s_n%d_0_comeco" % [tag, n])
		await _s(7.0)
		await _shot("%s_n%d_1_oeste" % [tag, n])
		e.player.olhar_para(Vector3(2.5, 2.0, 1.5), 0.01)
		await _s(0.5)
		await _shot("%s_n%d_2_leste" % [tag, n])
		e.player.olhar_para(Vector3(0.3, 3.0, 0.5), 0.01)
		await _s(0.5)
		await _shot("%s_n%d_3_teto" % [tag, n])
		if n == 4:
			e.player.olhar_para(Vector3(-0.05, 1.05, -2.3), 0.01)
			e.player.fov_forcado = 40.0
			await _s(0.8)
			await _shot("%s_n4_4_pedra" % tag)
			e.player.fov_forcado = 0.0
	# O mi-go do Dia 5, subindo diante da janela.
	var e5 := await _abrir(5)
	GameState.set_flag(&"leu_bilhete_akeley_agosto")
	e5.player.global_position = Vector3(0, 0, -1.4)
	e5.player.olhar_para(Vector3(0.0, 1.6, -4.0), 0.01)
	await _s(0.75)
	await _shot("%s_migo_1" % tag)
	await _s(0.25)
	await _shot("%s_migo_2" % tag)
	await _s(0.25)
	await _shot("%s_migo_3" % tag)
	# O pacote do Dia 3, aberto na mesa.
	var e3 := await _abrir(3)
	GameState.set_value(&"correio_dia_3", Correspondencia.NA_MESA)
	await _s(0.3)
	var pac: Correspondencia = e3.find_child("Pacote", true, false).get_node("Correio")
	pac.interact(e3.player)
	e3.player.global_position = Vector3(0.45, 0, -1.55)
	e3.player.olhar_para(pac.get_visual().global_position, 0.01)
	e3.player.fov_forcado = 35.0
	await _s(0.35)
	await _shot("%s_pacote_1_abrindo" % tag)
	await _s(1.2)
	await _shot("%s_pacote_2_aberto" % tag)
	pac.interact(e3.player)
	await _s(0.25)
	await _shot("%s_pacote_3_tirando" % tag)
	get_tree().quit()


func _abrir(n: int) -> Escritorio:
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", n)
	GameState.set_flag(StringName("comecou_dia_%d" % n))
	await SceneDirector.change_level("res://levels/escritorio/escritorio.tscn")
	await _s(1.0)
	Narrator.cancel()
	var e: Escritorio = root.find_child("Escritorio", true, false)
	e.player.input_enabled = false
	return e


func _shot(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, nome])


func _s(t: float) -> void:
	await get_tree().create_timer(t).timeout
