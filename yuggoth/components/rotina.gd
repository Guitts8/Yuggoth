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
## Playtest 12 ("algumas animações estão fracas, como a de pôr ração para os
## cachorros... tirar água do poço e etc."): cada tarefa é um gesto inteiro — o balde
## erguido por cima da tela e inclinado, os grãos caindo onde ele passa, a sacudida
## do fim; o balde pendurado na bica, os golpes da alavanca, o jato; a água por cima
## da tela e o balde pousado no chão; as achas tiradas da pilha uma a uma e
## arrumadas na lareira; as folhas do portão corridas uma de cada vez e a tranca; a
## portinhola da caixa que cai e o olhar lá dentro.

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
## A tranca do portão (encostada; `tranca_fechada`: a pose atravessada, local).
@export var tranca: Node3D
@export var tranca_fechada := Transform3D.IDENTITY
## A portinhola da caixa de correio (presa embaixo; cai para a estrada).
@export var caixa_portinhola: Node3D
## A bomba: a alavanca (pivô), a haste, o jato da bica e os respingos no balde.
@export var bomba_alavanca: Node3D
@export var bomba_haste: Node3D
@export var jato: Node3D
@export var respingos: CPUParticles3D
## O balde pendurado na bica (o meio dele, no mundo).
@export var balde_na_bica := Vector3.ZERO
## Onde Akeley fica: na bomba, no bebedouro, na pilha de lenha, ajoelhado na lareira.
@export var diante_da_bomba := Vector3.ZERO
@export var diante_do_bebedouro := Vector3.ZERO
@export var diante_da_lenha := Vector3.ZERO
@export var ajoelhar_lareira := Vector3.ZERO
## O alto das pilhas de lenha (de onde saem as achas, uma por tora da braçada).
@export var lenha_pilha: PackedVector3Array = []
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
## Um clique de metal (o trinco da portinhola, o balde no gancho).
@export var som_trinco: AudioStream
## Um baque surdo (a folha do portão que bate no batente, a tranca).
@export var som_baque: AudioStream
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

## Quanto a ração e a água do balde cabem (a escala y do monte e o nível).
const NIVEL_CHEIO := 0.1
const NIVEL_VAZIO := -0.1

var etapa := Etapa.RACAO
var lenha_feita := false
var celeiro_feito := false
var caixa_feita := false
var _ocioso := 0.0
var _chamar: Interactable
var _ocupado := false
var _ativa := false
## A ração caindo na gamela: a ponta leste dela e o comprimento (do mundo).
var _gamela_leste := 0.0
var _gamela_compr := 1.0
var _despejando := false
var _alavanca_repouso := 0.0
var _haste_repouso := 0.0


func _ready() -> void:
	for a: Interactable in [por_racao, bombear, encher_bebedouro, pegar_lenha, por_lenha, fechar_celeiro, abrir_caixa]:
		if a:
			a.interacted.connect(_on_area.bind(a))
	if bracada:
		bracada.visible = false
		bracada.process_mode = Node.PROCESS_MODE_DISABLED
	if racao_gamela:
		_gamela_leste = racao_gamela.global_position.x
		var r := racao_gamela.get_child(0) as MeshInstance3D
		if r and r.mesh is BoxMesh:
			_gamela_compr = (r.mesh as BoxMesh).size.x
	if bomba_alavanca:
		_alavanca_repouso = bomba_alavanca.rotation.x
	if bomba_haste:
		_haste_repouso = bomba_haste.position.y
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
	# A ração cai onde a boca do balde passa (a gamela enche de leste a oeste).
	if _despejando and balde and racao_gamela:
		var boca := balde.global_transform * Vector3(0.16, 0.05, 0.0)
		var u := clampf((_gamela_leste - boca.x + 0.25) / _gamela_compr, 0.0, 1.0)
		racao_gamela.scale.x = maxf(racao_gamela.scale.x, u)
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
## O que a luz-guia pode apontar agora (LuzGuia): as tarefas da rotina (a caixa
## de correio, que é à toa, não).
func guias() -> Array[Interactable]:
	return [por_racao, bombear, encher_bebedouro, pegar_lenha, por_lenha, fechar_celeiro]


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
	# No meio de uma tarefa, nenhuma vale (a luz-guia e a mira não apontam nada).
	sim = sim and not _ocupado
	a.enabled = sim
	a.collision_layer = Interactable.LAYER_INTERACAO if sim else 0


func _on_area(_by: Node, a: Interactable) -> void:
	if _ocupado:
		return
	_ocupado = true
	_ocioso = 0.0
	_ligar_areas()
	var p := matilha.akeley()
	p.input_enabled = false
	if a == por_racao:
		await _racao(p)
	elif a == bombear:
		await _bombear(p)
	elif a == encher_bebedouro:
		await _bebedouro(p)
	elif a == pegar_lenha:
		await _pegar_lenha(p)
	elif a == por_lenha:
		await _por_lenha(p)
	elif a == fechar_celeiro:
		await _celeiro(p)
	elif a == abrir_caixa:
		await _caixa(p)
	if not is_inside_tree():
		return
	_ocupado = false
	p.input_enabled = true
	_ligar_areas()
	if etapa == Etapa.LIVRE and lenha_feita and celeiro_feito:
		_yautja()


# --- A ração ---------------------------------------------------------------------

## Ao longo da gamela, por fora da tela: o balde sobe por cima dela e inclina para
## a direita; os grãos caem onde a boca passa e a gamela enche atrás dele; os cães
## correm cada um para o seu lugar; no fim, a sacudida, e o balde vazio desce.
func _racao(p: Player) -> void:
	etapa = Etapa.AGUA
	var de := caminho_racao[0] if caminho_racao.size() >= 2 else p.global_position
	var ate := caminho_racao[1] if caminho_racao.size() >= 2 else p.global_position
	# Os olhos na gamela, uns passos à frente (por cima da tela, à direita).
	var olhar_gamela := Vector3(-2.6, 0.35, -0.97)
	await p.conduzir([de], de + olhar_gamela)
	if not is_inside_tree():
		return
	# Ergue por cima da tela e inclina: a boca para a gamela.
	await balde.gesto(Vector3(0.2, 0.36, -0.14), Vector3(-10.0, 0.0, -35.0), 0.5).finished
	await balde.gesto(Vector3(0.32, 0.42, -0.24), Vector3(-16.0, 0.0, -96.0), 0.4, Tween.TRANS_QUAD, Tween.EASE_IN).finished
	if not is_inside_tree():
		return
	_tocar(som_racao, -2.0)
	_jorro(true)
	_despejando = true
	matilha.modo = Matilha.Modo.COMENDO
	# O monte do balde baixa enquanto ele anda.
	var monte := create_tween().set_trans(Tween.TRANS_SINE)
	if racao_balde:
		monte.tween_property(racao_balde, ^"scale:y", 0.15, 6.0)
	# Anda devagar, despejando; o balde balança um pouco a cada passo.
	var balanca := create_tween().set_loops(8)
	balanca.tween_property(balde, ^"girar:z", -104.0, 0.35).set_trans(Tween.TRANS_SINE)
	balanca.tween_property(balde, ^"girar:z", -92.0, 0.35).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
		if _despejando:
			_tocar(som_racao, -5.0, 0.92))
	await p.conduzir([ate], ate + olhar_gamela, 0.85)
	if not is_inside_tree():
		return
	balanca.kill()
	# O resto: a gamela inteira, e a sacudida para os últimos grãos.
	var resto := create_tween()
	resto.tween_property(racao_gamela, ^"scale:x", 1.0, 0.5)
	var sacode := create_tween()
	for k in 3:
		sacode.tween_property(balde, ^"girar:z", -118.0, 0.09)
		sacode.tween_property(balde, ^"girar:z", -88.0, 0.11)
	await sacode.finished
	_jorro(false)
	_despejando = false
	if racao_balde:
		racao_balde.visible = false
	await balde.gesto(Vector3.ZERO, Vector3.ZERO, 0.6).finished
	# Comem uns vinte segundos; então, à toa no cercado.
	get_tree().create_timer(22.0, false).timeout.connect(_fim_de_comer)


func _fim_de_comer() -> void:
	if matilha.modo == Matilha.Modo.COMENDO:
		matilha.modo = Matilha.Modo.DEPOIS


func _jorro(sim: bool, nome := "Jorro") -> void:
	var j := balde.get_node_or_null(NodePath(nome)) as CPUParticles3D
	if j:
		j.emitting = sim


# --- A bomba do poço -------------------------------------------------------------

## Do lado da bomba: o balde vai para o gancho da bica; a alavanca, golpe a golpe
## (a cabeça desce com cada um); no segundo golpe a água vem, um jato que pulsa e
## enche o balde; parado o braço, o jato míngua em pingos; o balde cheio volta à mão,
## pesado.
func _bombear(p: Player) -> void:
	etapa = Etapa.BEBEDOURO
	await p.conduzir([diante_da_bomba], balde_na_bica + Vector3(0.0, 0.1, -0.25))
	if not is_inside_tree():
		return
	# O balde no gancho da bica.
	var t := balde.pousar(Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), balde_na_bica), 0.75)
	await t.finished
	_tocar(som_trinco, -12.0, 1.3)
	if agua_balde:
		agua_balde.visible = true
		agua_balde.position.y = NIVEL_VAZIO
	# Os olhos entre a bica e o balde (a alavanca sobe e desce à direita).
	p.olhar_para(balde_na_bica + Vector3(0.0, 0.18, -0.12), 0.5)
	await _esperar(0.35)
	var golpes := 6
	for k in golpes:
		await _golpe(p, k)
		if not is_inside_tree():
			return
		# A água vem no segundo golpe; cada golpe enche um pouco.
		if k >= 1 and agua_balde:
			var sobe := create_tween()
			sobe.tween_property(agua_balde, ^"position:y", lerpf(NIVEL_VAZIO, NIVEL_CHEIO, float(k) / (golpes - 1)), 0.5)
	_jato(0.0, 0.7)
	await _esperar(0.8)
	# De volta à mão, cheio.
	balde.peso = 1.0
	await balde.pegar(0.7).finished
	_tocar(som_trinco, -14.0, 0.9)
	await _esperar(0.2)


## Um golpe da alavanca: o braço desce (a cabeça vai junto) e volta; a haste sobe e
## desce; da segunda vez em diante, o jato.
func _golpe(p: Player, k: int) -> void:
	if k % 2 == 0:
		_tocar(som_bomba, -3.0, 0.95 + 0.04 * k)
	var desce := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	desce.tween_property(bomba_alavanca, ^"rotation:x", _alavanca_repouso - deg_to_rad(44.0), 0.36)
	desce.tween_property(bomba_haste, ^"position:y", _haste_repouso + 0.07, 0.36)
	desce.tween_property(p, ^"abaixar", 0.1, 0.36)
	await desce.finished
	if k >= 1:
		_jato(1.0, 0.12)
	var sobe := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sobe.tween_property(bomba_alavanca, ^"rotation:x", _alavanca_repouso + deg_to_rad(6.0), 0.42)
	sobe.tween_property(bomba_haste, ^"position:y", _haste_repouso - 0.01, 0.42)
	sobe.tween_property(p, ^"abaixar", 0.0, 0.42)
	await sobe.finished
	if k >= 1:
		# Entre um golpe e outro o jato afina.
		_jato(0.45, 0.2)


## O jato da bica até a água do balde: `forca` 0 (parado) a 1 (cheio).
func _jato(forca: float, segundos: float) -> void:
	if jato == null:
		return
	jato.visible = true
	var alto := clampf(jato.global_position.y - (balde.global_position.y + (agua_balde.position.y if agua_balde else 0.0)), 0.05, 1.0)
	var t := create_tween().set_parallel()
	t.tween_property(jato, ^"scale", Vector3(lerpf(0.35, 1.0, forca), alto if forca > 0.0 else 0.001, lerpf(0.35, 1.0, forca)), segundos)
	if respingos:
		respingos.emitting = forca > 0.3
	if forca <= 0.0:
		t.chain().tween_callback(func() -> void: jato.visible = false)


# --- O bebedouro -----------------------------------------------------------------

## Por cima da tela: o balde sobe e inclina para a frente, a água cai no bebedouro
## (o nível do balde desce, o do bebedouro sobe); então ele se abaixa e pousa o
## balde vazio no chão, ao lado.
func _bebedouro(p: Player) -> void:
	etapa = Etapa.LIVRE
	var beb := agua_bebedouro.global_position
	await p.conduzir([diante_do_bebedouro], beb + Vector3(0.2, 0.55, 0))
	if not is_inside_tree():
		return
	# Por cima da tela, sobre o bebedouro: a boca virada para ele.
	var de_frente := Basis(Vector3.UP, atan2(-(beb.x - diante_do_bebedouro.x), -(beb.z - diante_do_bebedouro.z)))
	var eixo := de_frente * Vector3.RIGHT
	var sobre := beb + Vector3(0, 0.82, 0) + (diante_do_bebedouro - beb).normalized() * 0.32
	sobre.y = beb.y + 0.82
	balde.arco = 0.25
	await balde.pousar(Transform3D(de_frente, sobre), 0.7).finished
	if not is_inside_tree():
		return
	# Inclina: devagar até a água chegar à borda, e então ela cai.
	var inclinar := func(graus: float) -> void:
		balde.no_mundo = Transform3D(Basis(eixo, deg_to_rad(-graus)) * de_frente, sobre)
	var t0 := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t0.tween_method(inclinar, 0.0, 85.0, 0.55)
	await t0.finished
	_tocar(som_bebedouro, -2.0)
	_jorro(true, "JorroAgua")
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_property(agua_bebedouro, ^"scale:y", 1.0, 1.8)
	if agua_balde:
		t.tween_property(agua_balde, ^"position:y", NIVEL_VAZIO, 1.6)
	t.tween_method(inclinar, 85.0, 140.0, 1.8)
	await t.finished
	_jorro(false, "JorroAgua")
	if agua_balde:
		agua_balde.visible = false
	balde.peso = 0.0
	var t1 := create_tween().set_trans(Tween.TRANS_SINE)
	t1.tween_method(inclinar, 140.0, 0.0, 0.5)
	await t1.finished
	# Abaixa-se e pousa o balde no chão, à frente e à esquerda.
	var chao := balde_no_chao.global_position + Vector3(0, 0.13, 0)
	var abaixa := create_tween().set_trans(Tween.TRANS_SINE)
	abaixa.tween_property(p, ^"abaixar", 0.45, 0.6)
	p.olhar_para(chao, 0.7)
	await balde.mover(Transform3D(Basis(Vector3.UP, deg_to_rad(20.0)), chao), 0.9, 0.2).finished
	balde.arco = 0.18
	_tocar(som_trinco, -10.0, 0.7)
	balde.visible = false
	balde.process_mode = Node.PROCESS_MODE_DISABLED
	balde.peso_mao = 1.0
	if balde_no_chao:
		balde_no_chao.visible = true
	var levanta := create_tween().set_trans(Tween.TRANS_SINE)
	levanta.tween_property(p, ^"abaixar", 0.0, 0.6)
	await levanta.finished


# --- A lenha ---------------------------------------------------------------------

## Na pilha do galpão: ele se abaixa, e as achas vêm da pilha para os braços uma a
## uma, encaixando-se na braçada; ele se ergue com o peso.
func _pegar_lenha(p: Player) -> void:
	var olhar := pegar_lenha.global_position + Vector3(0, 0.1, 0)
	if diante_da_lenha != Vector3.ZERO:
		await p.conduzir([diante_da_lenha], olhar)
		if not is_inside_tree():
			return
	var abaixa := create_tween().set_trans(Tween.TRANS_SINE)
	abaixa.tween_property(p, ^"abaixar", 0.4, 0.5)
	await abaixa.finished
	bracada.visible = true
	bracada.process_mode = Node.PROCESS_MODE_INHERIT
	bracada.erguer = 0.75
	bracada.peso = 0.0
	var toras := _toras(bracada)
	for tora in toras:
		tora.visible = false
	for k in toras.size():
		var tora := toras[k]
		var de := lenha_pilha[k % lenha_pilha.size()] if not lenha_pilha.is_empty() else olhar
		var local := tora.transform
		tora.visible = true
		_tocar(som_lenha_pegar, -8.0, 0.9 + 0.06 * k)
		var giro := Basis(Vector3.UP, deg_to_rad(90.0 + k * 13.0))
		var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_method(func(u: float) -> void:
			if not is_instance_valid(tora):
				return
			var alvo := bracada.global_transform * local
			var x := Transform3D(giro, de).interpolate_with(alvo, u)
			x.origin += Vector3.UP * sin(u * PI) * 0.12
			tora.global_transform = x, 0.0, 1.0, 0.42)
		await t.finished
		if not is_inside_tree():
			return
		tora.transform = local
		bracada.peso = float(k + 1) / toras.size()
	var ergue := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	ergue.tween_property(p, ^"abaixar", 0.0, 0.7)
	ergue.tween_property(bracada, ^"erguer", 1.0, 0.7)
	await ergue.finished


## Na lareira do escritório: ajoelhado, as achas saem dos braços uma a uma — três na
## boca, uma sobre as outras, e duas de reserva na pedra.
func _por_lenha(p: Player) -> void:
	lenha_feita = true
	var boca := por_lenha.global_position
	if ajoelhar_lareira != Vector3.ZERO:
		await p.conduzir([ajoelhar_lareira], boca)
		if not is_inside_tree():
			return
	var ajoelha := create_tween().set_trans(Tween.TRANS_SINE)
	ajoelha.tween_property(p, ^"abaixar", 0.8, 0.7)
	p.olhar_para(boca + Vector3(0, -0.2, 0), 0.7)
	await ajoelha.finished
	var de_braco := _toras(bracada)
	var na_boca := _toras(lenha_lareira)
	if lenha_lareira:
		lenha_lareira.visible = true
		for t in na_boca:
			t.visible = false
	for k in mini(de_braco.size(), na_boca.size()):
		var tora := de_braco[k]
		var alvo := na_boca[k]
		var ini := tora.global_transform
		var fim := alvo.global_transform
		var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_method(func(u: float) -> void:
			if not is_instance_valid(tora):
				return
			var x := ini.interpolate_with(fim, u)
			x.origin += Vector3.UP * sin(u * PI) * 0.1
			tora.global_transform = x, 0.0, 1.0, 0.45)
		await t.finished
		if not is_inside_tree():
			return
		tora.visible = false
		alvo.visible = true
		bracada.peso = 1.0 - float(k + 1) / de_braco.size()
		_tocar(som_lenha_largar, -9.0, 0.9 + 0.07 * k)
		await _esperar(0.12)
	bracada.visible = false
	bracada.process_mode = Node.PROCESS_MODE_DISABLED
	for tora in de_braco:
		tora.visible = true
	var levanta := create_tween().set_trans(Tween.TRANS_SINE)
	levanta.tween_property(p, ^"abaixar", 0.0, 0.7)
	await levanta.finished


## As toras de um grupo (Tora0, Tora1...), na ordem.
func _toras(g: Node) -> Array[Node3D]:
	var lista: Array[Node3D] = []
	if g == null:
		return lista
	for c in g.get_children():
		if String(c.name).begins_with("Tora"):
			lista.append(c as Node3D)
	return lista


# --- O portão do celeiro ---------------------------------------------------------

## As duas folhas de correr, uma de cada vez: ele pega a borda da folha e anda com
## ela (devagar no começo, o peso), a folha bate no meio e repica; então a outra; e
## a tranca, de onde estava encostada, cai atravessada nos suportes.
func _celeiro(p: Player) -> void:
	celeiro_feito = true
	var g := portao[0].get_parent_node_3d() if not portao.is_empty() else null
	if g == null:
		return
	for i in mini(portao.size(), portao_fechado.size()):
		var folha := portao[i]
		var s := signf(folha.position.x)
		# A borda de dentro da folha (de onde ele a puxa), no mundo, agora e fechada.
		var borda := g.global_transform * (folha.position + Vector3(-s * 0.925, 0, 0))
		var borda_fim := g.global_transform * (portao_fechado[i] + Vector3(-s * 0.925, 0, 0))
		var fora := g.global_basis.z
		var junto := borda + fora * 0.75 - (borda_fim - borda).normalized() * 0.45
		junto.y = p.global_position.y
		await p.conduzir([junto], borda + Vector3.UP * 1.1)
		if not is_inside_tree():
			return
		_tocar(som_portao, -2.0, 1.0 + 0.05 * i)
		var anda := borda_fim - borda
		var leva := create_tween()
		leva.tween_property(folha, ^"position", portao_fechado[i] + Vector3(s * 0.04, 0, 0), 1.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await p.conduzir([junto + Vector3(anda.x, 0, anda.z)], borda_fim + Vector3.UP * 1.1, anda.length() / 1.9)
		if leva.is_running():
			await leva.finished
		if not is_inside_tree():
			return
		# Bate no meio e repica.
		_tocar(som_baque, -8.0, 0.7)
		var repica := create_tween().set_trans(Tween.TRANS_SINE)
		repica.tween_property(folha, ^"position", portao_fechado[i] + Vector3(s * 0.08, 0, 0), 0.12)
		repica.tween_property(folha, ^"position", portao_fechado[i], 0.25)
		await repica.finished
		await _esperar(0.2)
	if tranca:
		var t0 := tranca.transform
		var t1 := tranca_fechada
		var olhar := g.global_transform * t1.origin
		p.olhar_para(olhar, 0.5)
		await _esperar(0.3)
		var cai := create_tween()
		cai.tween_method(func(u: float) -> void:
			var x := t0.interpolate_with(t1, u)
			x.origin += Vector3.UP * sin(u * PI) * 0.35
			tranca.transform = x, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await cai.finished
		_tocar(som_lenha_largar, -4.0, 0.75)
		_tocar(som_baque, -10.0, 0.9)


# --- A caixa de correio ----------------------------------------------------------

## Do lado da estrada: a portinhola cai, ele olha lá dentro (vazia: é domingo), e a
## fecha com o estalo do trinco.
func _caixa(p: Player) -> void:
	caixa_feita = true
	if caixa_portinhola:
		var porta := caixa_portinhola.global_position
		var diante := porta + caixa_portinhola.global_basis.x * 0.85
		diante.y = p.global_position.y
		await p.conduzir([diante], porta + Vector3(0, 0.08, 0))
		if not is_inside_tree():
			return
		_tocar(som_trinco, -8.0)
		await _esperar(0.15)
		_tocar(som_caixa, -4.0)
		var abre := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		abre.tween_property(caixa_portinhola, ^"rotation_degrees:z", -100.0, 0.55)
		await abre.finished
		# Olha lá dentro, inclinado.
		var inclina := create_tween().set_trans(Tween.TRANS_SINE)
		inclina.tween_property(p, ^"inclinar", 0.18, 0.5)
		p.olhar_para(porta + Vector3(0, 0.1, 0) - caixa_portinhola.global_basis.x * 0.3, 0.5)
		await _esperar(1.3)
	else:
		_tocar(som_caixa, -4.0)
	if linha_caixa:
		Narrator.say(linha_caixa)
	if caixa_portinhola:
		var volta := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		volta.tween_property(p, ^"inclinar", 0.0, 0.5)
		volta.tween_property(caixa_portinhola, ^"rotation_degrees:z", 0.0, 0.45).set_ease(Tween.EASE_IN)
		await volta.finished
		_tocar(som_trinco, -6.0, 0.85)
	await _calar(8.0)


# --- Yautja ----------------------------------------------------------------------

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
	_despejando = false
	racao_gamela.scale.x = 1.0
	racao_balde.visible = false
	agua_balde.visible = false
	agua_bebedouro.scale.y = 1.0
	balde.visible = false
	balde.process_mode = Node.PROCESS_MODE_DISABLED
	balde_no_chao.visible = true
	bracada.visible = false
	lenha_lareira.visible = true
	for t in _toras(lenha_lareira):
		t.visible = true
	for i in mini(portao.size(), portao_fechado.size()):
		portao[i].position = portao_fechado[i]
	if tranca:
		tranca.transform = tranca_fechada
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


func _tocar(s: AudioStream, db: float, tom := 1.0) -> void:
	var a := AudioDirector.play_sfx(s, db)
	if a:
		a.pitch_scale *= tom


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout


## Espera a fala na tela acabar (no máximo `teto` segundos).
func _calar(teto: float) -> void:
	var t := 0.0
	while Narrator.is_speaking() and t < teto and is_inside_tree():
		await get_tree().process_frame
		t += get_process_delta_time()
