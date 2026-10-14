class_name Rotina
extends Node
## O entardecer na fazenda (docs/PLANO_FAZENDA.md, F5; "A tratativa", 1): a rotina
## de Akeley antes da noite, na ordem do balde — a ração na gamela comprida (os
## doze vêm comer lado a lado), a água do poço no bebedouro (e o balde fica no
## chão) —, e então, em qualquer ordem, a lenha do galpão até a lareira do
## escritório, o portão do celeiro, a caixa de correio junto à estrada (vazia: é
## domingo). Os cães e as falas curtas de Akeley guiam (quando uma tarefa falta e
## ele fica parado). Feitas a lenha e o celeiro, os pássaros param de uma vez e
## Yautja dispara para a mata; "Chamar Yautja" só traz o silêncio. Então o sol se
## põe (`terminou`).
##
## As áreas (Interactable) e as peças vêm do gerador; aqui, só a ordem e o movimento.

signal terminou

enum Etapa { RACAO, AGUA, BEBEDOURO, LIVRE, YAUTJA, CHAMAR, FIM }

@export var matilha: Matilha
@export var balde: NaMao
@export var bracada: NaMao
@export_group("Áreas")
@export var por_racao: Interactable
@export var bombear: Interactable
@export var encher_bebedouro: Interactable
@export var pegar_lenha: Interactable
@export var por_lenha: Interactable
@export var fechar_celeiro: Interactable
@export var abrir_caixa: Interactable
@export_group("Peças")
## A ração na gamela (escala x de 0 a 1, de leste a oeste).
@export var racao_gamela: Node3D
## A ração no balde e a água no balde.
@export var racao_balde: Node3D
@export var agua_balde: Node3D
## A água no bebedouro (sobe em y).
@export var agua_bebedouro: Node3D
## O balde deixado no chão junto ao bebedouro.
@export var balde_no_chao: Node3D
## A lenha arrumada na lareira do escritório.
@export var lenha_lareira: Node3D
## As folhas do portão de correr: [folha, posição fechada (local)].
@export var portao: Array[Node3D] = []
@export var portao_fechado: PackedVector3Array = []
## O caminho de Akeley ao longo da gamela, despejando (do mundo).
@export var caminho_racao: PackedVector3Array = []
@export var mata := Vector3(-58.0, 0, -6.0)
@export_group("Sons")
@export var som_racao: AudioStream
@export var som_bomba: AudioStream
@export var som_bebedouro: AudioStream
@export var som_lenha_pegar: AudioStream
@export var som_lenha_largar: AudioStream
@export var som_portao: AudioStream
@export var som_caixa: AudioStream
## O ambiente sem pássaros (quando eles param de uma vez).
@export var som_sem_passaros: AudioStream
@export_group("Falas")
## O que falta, dito por Akeley quando ele fica parado (por etapa/tarefa).
@export var lembretes: Dictionary[StringName, NarrationLine] = {}
## A caixa de correio vazia.
@export var linha_caixa: NarrationLine
## Yautja dispara; Akeley chama; não volta.
@export var linha_yautja: NarrationLine
@export var linha_chamar: NarrationLine
@export var linha_nao_voltou: NarrationLine

var etapa := Etapa.RACAO
var lenha_feita := false
var celeiro_feito := false
var caixa_feita := false
var _ocioso := 0.0
var _chamar: Interactable
var _ocupado := false
var _ativa := false


func _ready() -> void:
	for a: Interactable in [por_racao, bombear, encher_bebedouro, pegar_lenha, por_lenha, fechar_celeiro, abrir_caixa]:
		if a:
			a.interacted.connect(_on_area.bind(a))
	if bracada:
		bracada.visible = false
		bracada.process_mode = Node.PROCESS_MODE_DISABLED
	set_process(false)
	# Depois do _ready das áreas (que poriam a camada de volta).
	_ligar_areas.call_deferred()


## Começa a rotina (a fazenda chama, no Interlúdio, depois da descida). Antes
## disso (e fora do Interlúdio), nenhuma área vale.
func comecar() -> void:
	_ativa = true
	set_process(true)
	_ligar_areas()


func _process(delta: float) -> void:
	var p := matilha.akeley() if matilha else null
	if p == null or not p.input_enabled or _ocupado:
		_ocioso = 0.0
		return
	# Parado (ou à toa) por um tempo, Akeley lembra do que falta.
	_ocioso += delta
	if _ocioso > 35.0:
		_ocioso = 0.0
		var linha := lembretes.get(_falta(), null) as NarrationLine
		if linha and not Narrator.is_speaking():
			Narrator.say(linha)


func _falta() -> StringName:
	match etapa:
		Etapa.RACAO: return &"racao"
		Etapa.AGUA, Etapa.BEBEDOURO: return &"agua"
		Etapa.LIVRE:
			if not lenha_feita:
				return &"lenha_bracada" if bracada and bracada.visible else &"lenha"
			if not celeiro_feito:
				return &"celeiro"
	return &""


## Cada área vale na sua hora; as outras saem da física (não tampam a mira).
func _ligar_areas() -> void:
	var levando := bracada != null and bracada.visible
	_ligar(por_racao, _ativa and etapa == Etapa.RACAO)
	_ligar(bombear, _ativa and etapa == Etapa.AGUA)
	_ligar(encher_bebedouro, _ativa and etapa == Etapa.BEBEDOURO)
	_ligar(pegar_lenha, _ativa and etapa == Etapa.LIVRE and not lenha_feita and not levando)
	_ligar(por_lenha, _ativa and etapa == Etapa.LIVRE and levando)
	_ligar(fechar_celeiro, _ativa and etapa == Etapa.LIVRE and not celeiro_feito and not levando)
	_ligar(abrir_caixa, _ativa and etapa in [Etapa.LIVRE, Etapa.YAUTJA, Etapa.CHAMAR, Etapa.FIM] and not caixa_feita)


func _ligar(a: Interactable, sim: bool) -> void:
	if a == null:
		return
	a.enabled = sim
	a.collision_layer = Interactable.LAYER_INTERACAO if sim else 0


func _on_area(_by: Node, a: Interactable) -> void:
	if _ocupado:
		return
	_ocupado = true
	_ocioso = 0.0
	var p := matilha.akeley()
	p.input_enabled = false
	if a == por_racao:
		await _racao(p)
	elif a == bombear:
		await _bombear(p)
	elif a == encher_bebedouro:
		await _bebedouro(p)
	elif a == pegar_lenha:
		await _pegar_lenha()
	elif a == por_lenha:
		await _por_lenha(p)
	elif a == fechar_celeiro:
		await _celeiro(p)
	elif a == abrir_caixa:
		await _caixa()
	if not is_inside_tree():
		return
	_ocupado = false
	p.input_enabled = true
	_ligar_areas()
	if etapa == Etapa.LIVRE and lenha_feita and celeiro_feito:
		_yautja()


## Ao longo da gamela, despejando: o balde inclina, a ração cai, os cães vêm.
func _racao(p: Player) -> void:
	etapa = Etapa.AGUA
	if caminho_racao.size() >= 2:
		await p.conduzir([caminho_racao[0]], caminho_racao[0] + Vector3(-1, -0.6, -0.4))
	var de := balde.rotacao
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(balde, ^"rotacao", Vector3(78, -20, -35), 0.6)
	await t.finished
	_tocar(som_racao, -2.0)
	matilha.modo = Matilha.Modo.COMENDO
	var anda := create_tween()
	anda.tween_property(racao_gamela, ^"scale:x", 1.0, 3.2)
	if caminho_racao.size() >= 2:
		await p.conduzir([caminho_racao[1]], caminho_racao[1] + Vector3(-1, -0.6, -0.4), 1.0)
	else:
		await anda.finished
	if racao_balde:
		racao_balde.visible = false
	t = create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(balde, ^"rotacao", de, 0.6)
	await t.finished
	# Comem uns vinte segundos; então, à toa no cercado.
	get_tree().create_timer(22.0, false).timeout.connect(_fim_de_comer)


func _fim_de_comer() -> void:
	if matilha.modo == Matilha.Modo.COMENDO:
		matilha.modo = Matilha.Modo.DEPOIS


## A bomba do poço: a alavanca, a água no balde.
func _bombear(p: Player) -> void:
	etapa = Etapa.BEBEDOURO
	await p.olhar_para(bombear.global_position, 0.6).finished
	_tocar(som_bomba, -2.0)
	await get_tree().create_timer(1.8, false).timeout
	if agua_balde:
		agua_balde.visible = true
	await get_tree().create_timer(0.9, false).timeout


## A água no bebedouro, e o balde fica no chão.
func _bebedouro(p: Player) -> void:
	etapa = Etapa.LIVRE
	await p.olhar_para(encher_bebedouro.global_position, 0.6).finished
	var de := balde.rotacao
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(balde, ^"rotacao", Vector3(80, -15, -30), 0.5)
	await t.finished
	_tocar(som_bebedouro, -2.0)
	if agua_balde:
		agua_balde.visible = false
	var sobe := create_tween()
	sobe.tween_property(agua_bebedouro, ^"scale:y", 1.0, 1.0)
	await sobe.finished
	balde.rotacao = de
	balde.visible = false
	balde.process_mode = Node.PROCESS_MODE_DISABLED
	if balde_no_chao:
		balde_no_chao.visible = true


## Do galpão: uma braçada de lenha diante dos olhos.
func _pegar_lenha() -> void:
	_tocar(som_lenha_pegar, -3.0)
	bracada.visible = true
	bracada.process_mode = Node.PROCESS_MODE_INHERIT
	bracada.erguer = 0.0
	var t := create_tween()
	t.tween_property(bracada, ^"erguer", 1.0, 0.5)
	await t.finished


## Na lareira do escritório: a lenha arrumada para a noite.
func _por_lenha(p: Player) -> void:
	lenha_feita = true
	await p.olhar_para(por_lenha.global_position, 0.6).finished
	var t := create_tween()
	t.tween_property(bracada, ^"erguer", 0.0, 0.5)
	await t.finished
	bracada.visible = false
	bracada.process_mode = Node.PROCESS_MODE_DISABLED
	_tocar(som_lenha_largar, -3.0)
	if lenha_lareira:
		lenha_lareira.visible = true


## O portão de correr do celeiro, as duas folhas ao meio.
func _celeiro(p: Player) -> void:
	celeiro_feito = true
	await p.olhar_para(fechar_celeiro.global_position, 0.6).finished
	_tocar(som_portao, -2.0)
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	for i in mini(portao.size(), portao_fechado.size()):
		t.tween_property(portao[i], ^"position", portao_fechado[i], 1.5)
	await t.finished


## A caixa de correio: vazia, é domingo.
func _caixa() -> void:
	caixa_feita = true
	_tocar(som_caixa, -4.0)
	if linha_caixa:
		await Narrator.say(linha_caixa)


## Os pássaros param de uma vez; Yautja late para a mata e dispara.
func _yautja() -> void:
	etapa = Etapa.YAUTJA
	_ligar_areas()
	if som_sem_passaros:
		AudioDirector.play_ambience(som_sem_passaros)
	await get_tree().create_timer(2.5, false).timeout
	if not is_inside_tree():
		return
	var yautja := matilha.cao("Yautja")
	if yautja:
		yautja.fugir(mata)
	if linha_yautja:
		await Narrator.say(linha_yautja)
	if not is_inside_tree():
		return
	etapa = Etapa.CHAMAR
	_chamar_yautja()


## "Chamar Yautja": uma área diante dos olhos (qualquer mira a pega) até ele chamar.
func _chamar_yautja() -> void:
	var p := matilha.akeley()
	_chamar = Interactable.new()
	_chamar.name = "_ChamarYautja"
	_chamar.prompt = "Chamar Yautja"
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.6, 1.2, 0.2)
	forma.shape = caixa
	_chamar.add_child(forma)
	p.camera.add_child(_chamar)
	_chamar.position = Vector3(0, 0, -1.2)
	_chamar.interacted.connect(func(_by: Node) -> void: _chamado())
	# Sem chamar, em meio minuto acaba do mesmo jeito.
	get_tree().create_timer(30.0, false).timeout.connect(_chamado)


func _chamado() -> void:
	if etapa != Etapa.CHAMAR:
		return
	etapa = Etapa.FIM
	if is_instance_valid(_chamar):
		_chamar.queue_free()
	if linha_chamar:
		await Narrator.say(linha_chamar)
	if not is_inside_tree():
		return
	await get_tree().create_timer(3.0, false).timeout
	if linha_nao_voltou and is_inside_tree():
		await Narrator.say(linha_nao_voltou)
	if is_inside_tree():
		terminou.emit()


## Dá a rotina por feita, de uma vez (testes; F2 de depuração na fazenda): a ração
## na gamela, a água, a lenha na lareira, o celeiro fechado; Yautja some.
func pular() -> void:
	if etapa == Etapa.FIM:
		return
	etapa = Etapa.FIM
	lenha_feita = true
	celeiro_feito = true
	racao_gamela.scale.x = 1.0
	racao_balde.visible = false
	agua_balde.visible = false
	agua_bebedouro.scale.y = 1.0
	balde.visible = false
	balde.process_mode = Node.PROCESS_MODE_DISABLED
	balde_no_chao.visible = true
	bracada.visible = false
	lenha_lareira.visible = true
	for i in mini(portao.size(), portao_fechado.size()):
		portao[i].position = portao_fechado[i]
	var yautja := matilha.cao("Yautja")
	if yautja:
		yautja.fugiu = true
		yautja.visible = false
		yautja.process_mode = Node.PROCESS_MODE_DISABLED
	matilha.modo = Matilha.Modo.DEPOIS
	if is_instance_valid(_chamar):
		_chamar.queue_free()
	if som_sem_passaros:
		AudioDirector.play_ambience(som_sem_passaros)
	_ligar_areas()
	terminou.emit()


func _tocar(s: AudioStream, db: float) -> void:
	if s:
		AudioDirector.play_sfx(s, db)
