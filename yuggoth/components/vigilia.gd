class_name Vigilia
extends Node3D
## A noite em claro (playtest 8: "nos últimos dias, muitas cartas sem nada
## acontecer"). Lida a carta de terça (livro cap. IV: *"Não dormi nada naquela
## noite"*), em vez de um lapso, a noite passa jogável na sala. Nada se confirma
## (GDD §6, as estranhezas da Fase 6), nada salta: o telefone dá meio toque e
## cala — tirado do gancho, só um zumbido na linha —; a janela, que estava
## fechada, aparece entreaberta, com a cortina mexendo no vento frio; a criatura
## cruza o céu sem lua para quem olhar (já existe, Aparicao). Feito isso (ou com
## o tempo), "Reler as notas até o dia" na cadeira da escrivaninha (playtest 9:
## "sentar e esperar o dia" não fazia sentido): ele senta com o livro, lê a noite
## toda com a lâmpada acesa — nunca fecha, ao contrário dos lapsos —, e o dia raia
## pela janela devagar (Lapso.raiar); a carta de quarta cai pela fresta.
##
## A fase (Escritorio) chama `comecar()`; as áreas e os nós vêm do gerador.

## O que ele diz ao começar (a carta de terça fechada).
@export var linha_inicio: NarrationLine
## Dita ao raiar o dia: marca `narrou_<id>`, a condição da carta de quarta.
@export var linha_fim: NarrationLine
## Dia do ano de 1928 em que a noite acaba (a folhinha perde uma folha).
@export var data_fim := 0
@export var lapso: Lapso
@export_group("O telefone")
## Onde o meio toque soa (o aparelho).
@export var aparelho: Node3D
@export var campainha: AudioStream
## Marcada depois do meio toque: a Ligacao "tirar o fone do gancho" passa a valer.
@export var flag_toque := &"vigilia_toque"
@export_group("A janela")
## A folha de baixo da janela que sobe um palmo, e as cortinas que mexem.
@export var folha: Node3D
@export var cortinas: Array[Node3D] = []
@export var som_janela: AudioStream
@export var som_vento: AudioStream
@export var fechar: Interactable
@export var flag_janela := &"vigilia_janela"
@export var flag_fechou := &"vigilia_fechou_janela"
@export_group("O dia")
@export var esperar: Interactable
@export var flag_feita := &"vigilia_feita"
@export_group("")
## Segundos até o meio toque; até a janela, depois do toque (atendido ou não);
## até "Esperar o dia" valer, mesmo sem fechar a janela.
@export var ate_o_toque := 7.0
@export var ate_a_janela := 18.0
@export var ate_esperar := 30.0

const ABRE := 0.13

var correndo := false
var _esc: Escritorio
var _vento: AudioStreamPlayer3D
var _balanco: Tween
var _pivos: Array[Node3D] = []


func _ready() -> void:
	_ligar(fechar, false)
	_ligar(esperar, false)
	if fechar:
		fechar.interacted.connect(_on_fechar)
	if esperar:
		esperar.interacted.connect(_on_esperar)


## Desligada, a área sai da mira e da física (não tampa "Olhar" a janela).
static func _ligar(area: Interactable, on: bool) -> void:
	if area:
		area.enabled = on
		area.visible = on
		area.collision_layer = Interactable.LAYER_INTERACAO if on else 0


func comecar(esc: Escritorio) -> void:
	if correndo or GameState.has_flag(flag_feita):
		return
	correndo = true
	_esc = esc
	if linha_inicio:
		Narrator.say(linha_inicio)
	# O meio toque: a campainha começa e cala.
	if not await _esperar(ate_o_toque):
		return
	if campainha and aparelho:
		var toque := AudioStreamPlayer3D.new()
		toque.stream = campainha
		toque.bus = &"SFX"
		toque.unit_size = 4.0
		aparelho.add_child(toque)
		toque.play()
		await get_tree().create_timer(0.55).timeout
		if not is_inside_tree():
			return
		toque.stop()
		toque.queue_free()
	GameState.set_flag(flag_toque)
	# A janela: depois do fone (ou do tempo), quando ele não estiver olhando para ela.
	var t := 0.0
	while t < ate_a_janela and not GameState.has_flag(&"ligou_vigilia_linha"):
		if not await _esperar(0.25):
			return
		t += 0.25
	while _olhando(folha) or _esc.player.em_cena():
		if not await _esperar(0.25):
			return
	await _abrir_janela()
	if not is_inside_tree():
		return
	# "Esperar o dia": quando a janela fechar, ou com o tempo.
	t = 0.0
	while t < ate_esperar and not GameState.has_flag(flag_fechou):
		if not await _esperar(0.25):
			return
		t += 0.25
	_ligar(esperar, true)


## Espera `segundos` de jogo; false se a fase saiu.
func _esperar(segundos: float) -> bool:
	await get_tree().create_timer(segundos, false).timeout
	return is_inside_tree()


func _olhando(alvo: Node3D) -> bool:
	if alvo == null:
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var para := alvo.global_position - cam.global_position
	return rad_to_deg(para.angle_to(-cam.global_basis.z)) < 40.0


## Sem ninguém ver: a folha de baixo sobe um palmo, o vento entra, as cortinas
## mexem. Uma vez.
func _abrir_janela() -> void:
	GameState.set_flag(flag_janela)
	if folha:
		folha.position.y += ABRE
	if som_janela:
		AudioDirector.play_sfx(som_janela, -14.0)
	if som_vento and folha:
		_vento = AudioStreamPlayer3D.new()
		_vento.stream = som_vento
		_vento.bus = &"Ambience"
		_vento.unit_size = 2.5
		_vento.volume_db = -6.0
		folha.add_child(_vento)
		_vento.position = Vector3(0, -0.4, -0.1)
		_vento.play()
	_balancar(true)
	_ligar(fechar, true)


## As cortinas balançam presas no alto (um pivô no varão para cada uma).
func _balancar(sim: bool) -> void:
	if _balanco:
		_balanco.kill()
		_balanco = null
	if _pivos.is_empty():
		for c in cortinas:
			var aabb := (c as VisualInstance3D).get_aabb() if c is VisualInstance3D else AABB()
			var pivo := Node3D.new()
			c.get_parent().add_child(pivo)
			var topo := c.global_transform * Vector3(aabb.get_center().x, aabb.end.y, aabb.get_center().z)
			pivo.global_position = topo
			c.reparent(pivo, true)
			_pivos.append(pivo)
	if not sim:
		_balanco = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		for p in _pivos:
			_balanco.tween_property(p, ^"rotation", Vector3.ZERO, 2.5)
		return
	_balanco = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for k in 3:
		var a := deg_to_rad([5.0, 2.5, 6.5][k])
		_balanco.tween_method(_vento_nas_cortinas.bind(a), 0.0, 1.0, [1.6, 1.1, 1.9][k])
		_balanco.tween_method(_vento_nas_cortinas.bind(a), 1.0, 0.0, [1.4, 1.3, 1.7][k])


func _vento_nas_cortinas(k: float, a: float) -> void:
	for i in _pivos.size():
		# A borda solta vai para dentro da sala (+Z), cada uma no seu tempo.
		_pivos[i].rotation.x = a * k * (1.0 if i % 2 == 0 else 0.8)
		_pivos[i].rotation.z = a * 0.3 * k * (1.0 if i % 2 == 0 else -1.0)


func _on_fechar(_by: Node) -> void:
	if GameState.has_flag(flag_fechou):
		return
	GameState.set_flag(flag_fechou)
	_ligar(fechar, false)
	if som_janela:
		AudioDirector.play_sfx(som_janela, -10.0)
	if folha:
		var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(folha, ^"position:y", folha.position.y - ABRE, 0.7)
	if _vento:
		var v := create_tween()
		v.tween_property(_vento, ^"volume_db", -60.0, 0.8)
		v.tween_callback(_vento.queue_free)
		_vento = null
	_balancar(false)


## Ele senta à escrivaninha e o dia raia pela janela; a carta de quarta cai pela
## fresta; a folhinha perde a folha da noite.
func _on_esperar(_by: Node) -> void:
	if GameState.has_flag(flag_feita) or _esc == null:
		return
	_ligar(esperar, false)
	_ligar(fechar, false)
	_esc.em_lapso = true
	var p := _esc.player
	p.input_enabled = false
	await _esc.abrir_livro()
	if not is_inside_tree():
		return
	if lapso:
		await lapso.raiar(12.0, func() -> void:
			if data_fim > 0:
				lapso._arrancar_folha(data_fim)
				GameState.set_value(&"data", data_fim))
	if not is_inside_tree():
		return
	GameState.set_flag(flag_feita)
	if linha_fim:
		await Narrator.say(linha_fim)
	if not is_inside_tree():
		return
	await _esc.fechar_livro()
	if not is_inside_tree():
		return
	p.input_enabled = true
	_esc.em_lapso = false
	correndo = false
