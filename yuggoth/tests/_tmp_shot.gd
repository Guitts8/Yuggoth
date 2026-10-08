extends Node
## Descartável (playtest 3): a selagem vista de lado, o diário escrito e lido
## (virar a folha), o acordar com as pálpebras, e a porta de Boston abrindo.
## Em SHOT_DIR, com prefixo SHOT_TAG.

var dir := OS.get_environment("SHOT_DIR")
var tag := OS.get_environment("SHOT_TAG")
var root: Node


func _ready() -> void:
	SaveSystem.save_path = "user://_tmp_shot_save.json"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	add_child(root)
	await _s(0.5)

	if OS.get_environment("SHOT_SO") == "sala":
		await _sala()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_SO") == "sono":
		await _sono()
		get_tree().quit()
		return
	if OS.get_environment("SHOT_SO") == "postar":
		var e := await _escritorio(1)
		e.player.global_position = Vector3(0.2, 0, -1.2)
		e.player.look_at(Vector3(0.2, 0.0, -2.0))
		var r: ReplyData = load("res://narrative/replies/resposta_dia_1.tres")
		r.apply(r.options[0])
		CartaSaida.criar(e.miskatonic, r)
		await _s(0.5)
		e._on_porta(null)
		await _serie("postar", [3.6, 4.1, 4.5, 4.9])
		get_tree().quit()
		return
	if OS.get_environment("SHOT_SO") == "boston":
		await _boston()
		get_tree().quit()
		return
	# A selagem, começando de pé ao lado da mesa (a vista deve ir de frente para a carta).
	var esc := await _escritorio(1)
	esc.player.global_position = Vector3(0.9, 0, -1.3)
	esc.player.look_at(Vector3(1.5, 0.0, -1.0))
	var reply: ReplyData = load("res://narrative/replies/resposta_dia_1.tres")
	esc._on_reply_written(reply, reply.options[0])
	await _serie("selar", [1.5, 3.0, 5.0, 6.0, 6.8, 7.5, 8.2, 9.0, 9.8, 11.0, 12.5, 13.5, 14.5, 16.0])
	if OS.get_environment("SHOT_SO") == "selar":
		get_tree().quit()
		return

	# Escrevendo no diário (Dia 1).
	esc = await _escritorio(1)
	esc.player.global_position = Vector3(-0.2, 0, -1.2)
	GameState.set_value(&"diario", 1)
	await _s(0.5)
	esc._on_anotar(null)
	await _serie("escrever", [3.5, 7.0, 9.0, 12.0])

	# Folheando (Dia 3, duas entradas): abre no último par; vira para trás.
	GameState.reset()
	esc = await _escritorio(3)
	for n in [1, 2]:
		GameState.add_document(load("res://narrative/documents/diario_dia_%d.tres" % n))
	esc.player.global_position = Vector3(-0.6, 0, -1.3)
	await _s(0.5)
	esc._on_ler_diario(null)
	await _serie("ler", [6.5])
	esc.diario._virar(-1)
	await _serie("ler_virando", [0.2, 0.35, 0.5, 1.0])
	esc.diario._virar(-1)
	await _serie("ler_virando2", [0.3, 1.0])
	esc.diario._virar(1)
	await _serie("ler_frente", [0.3, 1.0])
	esc.diario.lendo = false
	await _serie("ler_fecha", [3.0])

	# O acordar: no escuro, debruçado; os olhos abrem como fecharam.
	esc = await _escritorio(2)
	await SceneDirector.fade_out(0.0)
	SceneDirector.hold_black = true
	esc._acordar(2)
	await _serie("acordar", [1.2, 2.6, 4.0, 5.6, 7.0, 9.5, 12.0])

	await _boston()
	SaveSystem.delete_save()
	get_tree().quit()


func _boston() -> void:
	# Boston: a porta abre com o 7.
	GameState.reset()
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", 4)
	await SceneDirector.change_level("res://levels/boston/boston.tscn")
	await _s(1.0)
	var b: Boston = root.find_child("Boston", true, false)
	Narrator.cancel()
	var porta := b.folha.global_position
	b.player.global_position = porta + Vector3(-1.15, 0, 1.3)
	b.player.look_at(porta + Vector3(0, 0, 0.45))
	b.player.head.rotation.x = deg_to_rad(8)
	GameState.set_flag(&"bateu_boston")
	await _serie("boston", [0.5, 4.5])


func _sono() -> void:
	# O café (Dia 1) e o uísque (Dia 4), antes do diário.
	for n in [1, 4]:
		GameState.reset()
		var e := await _escritorio(n)
		e.player.global_position = Vector3(0.3, 0, -1.2)
		GameState.set_value(&"diario", n)
		await _s(0.5)
		e._on_anotar(null)
		var tempos := [3.0, 3.6, 4.2, 4.8, 6.0, 7.0, 7.8] if n == 1 else [6.5, 7.2, 7.8, 8.4, 10.0, 11.0]
		await _serie("beber_d%d" % n, tempos)
	if OS.get_environment("SHOT_BEBER") == "1":
		return
	# As noites longe da mesa: o disco (3) e o fogo (5); e o acordar ali.
	for n in [3, 5]:
		GameState.reset()
		for fl in [&"fono_corneta", &"fono_manivela", &"fono_agulha", &"fono_cilindro", &"tocou_disco", &"lareira_dia_5"]:
			GameState.set_flag(fl)
		var e := await _escritorio(n)
		e.player.global_position = Vector3(0.3, 0, -1.2)
		GameState.set_value(&"diario", n)
		await _s(0.5)
		e._on_anotar(null)
		var t0 := Time.get_ticks_msec()
		while GameState.get_value(&"sono", 0) != n and Time.get_ticks_msec() - t0 < 60000:
			await get_tree().process_frame
		await _s(1.0)
		var lugar := e._lugar_sono(n)
		e.player.look_at(lugar.global_position)
		await _s(0.3)
		_shot("%s_noite%d_area" % [tag, n])
		e._on_lugar_sono(null, lugar)
		await _serie("noite%d" % n, [1.0, 2.5, 4.5, 8.0, 14.0, 20.0])
		GameState.set_flag(e.sonhos[n])
		await _serie("acordar%d" % n, [6.0, 9.0, 12.0, 15.0, 18.0])


## A sala de vários pontos, de dia (Dia 1) e de noite (Dia 5, fogo aceso).
func _sala() -> void:
	var vistas := [
		["porta", Vector3(-0.9, 0, 2.4), Vector3(0.0, 1.0, -2.2)],
		["cadeira", Vector3(0.05, 0, -1.35), Vector3(0.05, 0.9, -2.6)],
		["leste", Vector3(-1.2, 0, 0.2), Vector3(2.5, 1.0, -0.6)],
		["oeste", Vector3(1.2, 0, 0.0), Vector3(-2.5, 1.2, -1.2)],
		["janela", Vector3(0.0, 0, -1.6), Vector3(0.0, 1.7, -3.5)],
		["mesa", Vector3(0.6, 0, -1.4), Vector3(-0.1, 0.78, -2.2)],
		["sul", Vector3(0.5, 0, -1.8), Vector3(-0.5, 1.2, 3.0)],
	]
	for d in [1, 5]:
		GameState.reset()
		GameState.set_flag(&"lareira_dia_5")
		var e := await _escritorio(d)
		Narrator.cancel()
		for v: Array in vistas:
			e.player.global_position = v[1]
			e.player.look_at(Vector3(v[2].x, v[1].y, v[2].z))
			var olho := e.player.global_position + Vector3(0, 1.62, 0)
			e.player.head.rotation.x = atan2(v[2].y - olho.y, Vector2(v[2].x - olho.x, v[2].z - olho.z).length())
			await _s(0.6)
			_shot("%s_d%d_%s" % [tag, d, v[0]])


func _escritorio(dia: int) -> Escritorio:
	GameState.set_flag(&"prologo_concluido")
	GameState.set_value(&"dia", dia)
	for n in range(1, dia + 1):
		GameState.set_flag(StringName("comecou_dia_%d" % n))
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
