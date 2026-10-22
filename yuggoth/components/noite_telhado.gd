class_name NoiteTelhado
extends Node
## A noite do telhado (docs/PLANO_FAZENDA.md, F7; "A tratativa", 3 e 4): a carta de
## segunda-feira, vivida. Cada frase da carta aparece na letra de Akeley quando a
## coisa acontece.
##
## A espera: "Sentar e esperar" na poltrona junto ao fogo, o rifle no colo; o fogo
## e o lampião baixam, o relógio bate, as pálpebras pesam — ele cochila. Os grilos
## param. O baque no telhado o acorda: a poeira do forro, o lampião que tine; os
## cães correm em volta da casa; um sobe pelo puxado baixo e corre por cima do
## forro; a luta lá em cima e o zumbido (o mesmo do disco), que sobe e some; o
## cheiro (a imagem turva, o fôlego). Só som e poeira: nada visto.
##
## As balas, anunciadas (não é um susto: os dois do jogo são do Ato III): os latidos
## viram para a frente da casa, um tiro de longe bate no tabuado, o seguinte
## estoura a vidraça do escritório e um estilhaço passa rente ao rosto, o terceiro
## — um clarão longe na mata, pela veneziana que a bala abriu — lasca a estante.
## Então o jogador age: "Apagar o lampião" (o do escritório; o da sala também, para
## atirar de lá) e, de janela em janela, "Atirar pela janela": a fresta da
## veneziana, o cano que sobe sozinho, alto (*"apontado alto o bastante para não
## acertar os cães"*), o clarão que mostra o quintal por um quadro, a alavanca, o
## cartucho no assoalho. No terceiro tiro, sempre, o ganido que corta. Depois do
## último, os latidos param um a um, e *"Isso pareceu encerrar a coisa"* —
## `terminou` (a fazenda escurece e acaba a demo).

signal terminou

enum Etapa { ANTES, SENTAR, ESPERA, TELHADO, BALAS, APAGAR, TIROS, FIM }

## Quantos tiros (as janelas de `seteiras`; o rifle tem quatro cartuchos).
const TIRO_DO_GANIDO := 2

@export var matilha: Matilha
@export var preparacao: Preparacao
@export var sentar: Interactable
## Onde o corpo fica sentado (a poltrona) e para onde olha (o fogo).
@export var assento := Vector3.ZERO
@export var diante := Vector3.ZERO
## O relógio do consolo (laço de tique-taque).
@export var relogio: AudioStreamPlayer3D
## O som que anda pelo telhado (o baque, as unhas, a luta) e o zumbido.
@export var som_telhado: AudioStreamPlayer3D
@export var som_zumbido: AudioStreamPlayer3D
## O caminho de quem sobe: da beira do puxado até o alto do escritório.
@export var caminho_telhado: PackedVector3Array = []
## A poeira que cai do forro do escritório.
@export var poeira: Array[CPUParticles3D] = []

@export_group("As balas")
## A janela do escritório que a bala estoura: a veneziana, a vidraça, os cacos.
@export var janela_bala: Venezianas
@export var vidraca: Node3D
@export var estilhacos: Node3D
## Os cacos caem aqui dentro (direção da janela para o cômodo).
@export var para_dentro := Vector3(0, 0, -1)
## O tabuado onde bate o primeiro tiro (de fora), a estante onde bate o terceiro.
@export var bate_tabuado := Vector3.ZERO
@export var bate_estante := Vector3.ZERO
@export var lascas: CPUParticles3D
## O clarão longe, na mata (a luz e o brilho).
@export var clarao: Node3D
## De onde vêm os tiros de lá (o som).
@export var mata_frente := Vector3(30.0, 2.0, 34.0)

@export_group("Os tiros de Akeley")
## As janelas que servem de seteira (as venezianas) e as áreas "Atirar pela
## janela", na mesma ordem; o lampião de cada cômodo tem de estar apagado.
@export var seteiras: Array[Venezianas] = []
@export var atirar: Array[Interactable] = []
@export var lampiao_de: Array[Lampiao] = []
## Os lampiões que se apagam (o do escritório primeiro).
@export var apagar: Array[Lampiao] = []

@export_group("Sons")
@export var som_noite: AudioStream
@export var som_sem_grilos: AudioStream
@export var som_baque: AudioStream
@export var som_unhas: AudioStream
@export var som_luta: AudioStream
@export var som_poeira: AudioStream
@export var som_tiro: AudioStream
@export var som_tiro_longe: AudioStream
@export var som_vidro: AudioStream
@export var som_lascas: AudioStream
@export var som_alavanca: AudioStream
@export var som_cartucho: AudioStream

@export_group("Falas")
## A carta de segunda, frase por frase (ids: nuvens, pousou, correram, subiu,
## luta, cheiro, balas, apaguei, seteiras, encerrar).
@export var frases: Dictionary[StringName, NarrationLine] = {}
## Parado, o que falta (sentar, apagar, atirar).
@export var lembretes: Dictionary[StringName, NarrationLine] = {}

var etapa := Etapa.ANTES
var tiros := 0
var feita := false
var _ocupado := false
var _ocioso := 0.0
var _fazenda: Node
var _palpebras: Palpebras
var _tremor := 0.0
var _tremor_t := 0.0
## Os tiros de lá, de tempos em tempos, enquanto Akeley atira.
var _tiros_de_la := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1928
	set_process(false)
	if sentar:
		sentar.interacted.connect(func(_by: Node) -> void: _sentar())
	for i in atirar.size():
		atirar[i].interacted.connect(func(_by: Node) -> void: _atirar(i))
	for l in apagar:
		l.mudou.connect(func(aceso: bool) -> void:
			if not aceso:
				_apagou(l))
	if estilhacos:
		estilhacos.visible = false
	if clarao:
		clarao.visible = false
	_ligar_areas.call_deferred()


## Começa (a fazenda chama, feita a preparação): a noite fechada, os grilos, a
## poltrona à espera.
func comecar(fazenda: Node) -> void:
	_fazenda = fazenda
	etapa = Etapa.SENTAR
	if preparacao:
		preparacao.encerrar()
	if som_noite:
		AudioDirector.play_ambience(som_noite, 4.0)
	set_process(true)
	_ligar_areas()


## Apagadas as luzes, a luz-guia quase não clareia (LuzGuia).
func escuro() -> bool:
	return etapa >= Etapa.APAGAR and not apagar.is_empty() and not apagar[0].aceso


## O que a luz-guia pode apontar agora (LuzGuia).
func guias() -> Array[Interactable]:
	var todas: Array[Interactable] = []
	if sentar:
		todas.append(sentar)
	todas.append_array(apagar)
	todas.append_array(atirar)
	return todas


func _process(delta: float) -> void:
	# O tremor da câmera (o baque, a luta, o recuo): no deslocamento da lente, que
	# ninguém mais usa.
	var p := matilha.akeley()
	if p:
		_tremor = move_toward(_tremor, 0.0, delta * 1.6)
		_tremor_t += delta * 38.0
		p.camera.h_offset = sin(_tremor_t * 1.3) * 0.02 * _tremor
		p.camera.v_offset = sin(_tremor_t + 0.7) * 0.025 * _tremor
	if p == null or not p.input_enabled or _ocupado or feita:
		_ocioso = 0.0
		return
	_ocioso += delta
	if _ocioso > 35.0:
		_ocioso = 0.0
		var falta: StringName = {Etapa.SENTAR: &"sentar", Etapa.APAGAR: &"apagar", Etapa.TIROS: &"atirar"}.get(etapa, &"")
		if falta == &"atirar" and _apagar_falta():
			falta = &"apagar"
		var linha := lembretes.get(falta, null) as NarrationLine
		if linha and not Narrator.is_speaking():
			Narrator.say(linha)


func _apagar_falta() -> bool:
	for i in atirar.size():
		if not _ja_atirou(i) and lampiao_de[i] and lampiao_de[i].aceso:
			return true
	return false


func _ja_atirou(i: int) -> bool:
	return atirar[i].get_meta(&"atirou", false)


func _ligar_areas() -> void:
	_ligar(sentar, etapa == Etapa.SENTAR)
	for i in apagar.size():
		var l := apagar[i]
		# O do escritório primeiro; o da sala, depois dele.
		var vale := (etapa == Etapa.APAGAR and i == 0) or (etapa == Etapa.TIROS and l.aceso)
		l.apagavel = vale
		_ligar(l, vale and l.aceso)
	for i in atirar.size():
		var vale := etapa == Etapa.TIROS and not _ja_atirou(i) and (lampiao_de[i] == null or not lampiao_de[i].aceso)
		_ligar(atirar[i], vale and not _ocupado)


func _ligar(a: Interactable, sim: bool) -> void:
	if a:
		a.collision_layer = Interactable.LAYER_INTERACAO if sim else 0


# --- A espera e o telhado -------------------------------------------------------

func _sentar() -> void:
	if etapa != Etapa.SENTAR:
		return
	etapa = Etapa.ESPERA
	_ocupado = true
	_ligar_areas()
	var p := matilha.akeley()
	p.input_enabled = false
	# Até a poltrona e sentado nela, olhando o fogo; o rifle no colo.
	var frente := (diante - assento)
	frente.y = 0.0
	frente = frente.normalized()
	await p.conduzir([assento + frente * 0.6], diante)
	if not is_inside_tree():
		return
	# Sentado antes de entrar na poltrona: a física o empurraria para fora dela.
	p.seated = true
	var s := p.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	s.tween_property(p, ^"global_position", Vector3(assento.x, p.global_position.y, assento.z), 0.9)
	await p.olhar_para(diante, 1.0, assento).finished
	if not is_inside_tree():
		return
	var rifle := preparacao.rifle if preparacao else null
	if rifle:
		create_tween().tween_property(rifle, ^"erguer", 0.45, 1.2)
	await _frase(&"nuvens")
	await _espera(p)
	if not is_inside_tree():
		return
	await _telhado(p)
	if not is_inside_tree():
		return
	await _balas(p)


## A espera: o fogo e o lampião baixam, o relógio, as pálpebras pesam; passa da
## meia-noite; os grilos param.
func _espera(p: Player) -> void:
	# A noite fecha de todo enquanto ele espera.
	if _fazenda:
		_fazenda.set(&"_noite_alvo", 1.0)
		create_tween().tween_property(_fazenda, ^"noite", 1.0, 24.0)
	if relogio:
		relogio.play()
	var fogo := preparacao.acender_lareira.fogo if preparacao and preparacao.acender_lareira else null
	var lampiao := apagar[0] if not apagar.is_empty() else null
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	if fogo:
		t.tween_property(fogo, ^"intensidade", 0.35, 28.0)
	if lampiao:
		# Ele baixa o pavio: a chama menor, a luz mais curta.
		t.tween_property(lampiao, ^"energia", lampiao.energia * 0.55, 20.0)
	_palpebras = Palpebras.new()
	add_child(_palpebras)
	await _esperar(6.0)
	for passo: Vector2 in [Vector2(0.55, 5.0), Vector2(0.3, 2.0), Vector2(0.78, 5.0), Vector2(0.5, 1.6), Vector2(0.93, 5.0)]:
		await _palpebras.fechar(passo.x, passo.y)
		if not is_inside_tree():
			return
	# Os grilos param; lá fora, um rosnado.
	if som_sem_grilos:
		AudioDirector.play_ambience(som_sem_grilos, 1.2)
	await _esperar(2.5)
	var hercules := matilha.cao("Hércules")
	if hercules:
		hercules._som(matilha.rosnado, -6.0)
	await _esperar(3.0)


## O telhado: o baque, a poeira, os cães em volta, um sobe pelo puxado, a luta e o
## zumbido, o cheiro.
func _telhado(p: Player) -> void:
	etapa = Etapa.TELHADO
	# O baque: os olhos abrem de uma vez.
	_tocar_em(som_telhado, som_baque, caminho_telhado[caminho_telhado.size() - 1], 6.0)
	_tremer(1.0)
	_palpebras.fechar(0.0, 0.25)
	await _esperar(0.25)
	_poeira(1.0)
	_tinir_lampiao()
	await _frase(&"pousou")
	await _esperar(1.5)
	await _frase(&"correram")
	matilha.modo = Matilha.Modo.TELHADO
	await _esperar(3.0)
	# Um sobe pelo puxado baixo e corre por cima do forro.
	await _frase(&"subiu")
	if not is_inside_tree():
		return
	var kull := matilha.cao("Kull")
	if kull:
		kull.sumir()
	if som_telhado and som_unhas and caminho_telhado.size() >= 2:
		som_telhado.stream = som_unhas
		som_telhado.volume_db = 2.0
		som_telhado.global_position = caminho_telhado[0]
		som_telhado.play()
		var t := create_tween()
		for k in range(1, caminho_telhado.size()):
			t.tween_property(som_telhado, ^"global_position", caminho_telhado[k], 1.1)
		await t.finished
		if not is_inside_tree():
			return
	_poeira(0.4)
	await _esperar(1.0)
	# A luta lá em cima, e o zumbido.
	await _frase(&"luta")
	if not is_inside_tree():
		return
	if som_telhado:
		som_telhado.stop()
	var alto := caminho_telhado[caminho_telhado.size() - 1]
	_tocar_em(som_telhado, som_luta, alto, 6.0)
	_tremer(0.6)
	if som_zumbido:
		som_zumbido.global_position = alto + Vector3(-1.0, 0.5, 0.0)
		som_zumbido.volume_db = -30.0
		som_zumbido.play()
		create_tween().tween_property(som_zumbido, ^"volume_db", 4.0, 2.5).set_trans(Tween.TRANS_SINE)
	for k in 4:
		await _esperar(1.6)
		if not is_inside_tree():
			return
		_poeira(0.35)
		_tremer(0.5)
		_tinir_lampiao()
	# O ganido lá em cima, as unhas escorregando, o corpo que cai lá fora; o
	# zumbido sobe e se vai.
	_tocar_em(som_telhado, matilha.ganido, alto, 2.0)
	if som_zumbido:
		var z := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		z.tween_property(som_zumbido, ^"global_position", alto + Vector3(-30.0, 60.0, -20.0), 4.0)
		z.tween_property(som_zumbido, ^"volume_db", -40.0, 4.0)
		z.chain().tween_callback(som_zumbido.stop)
	await _esperar(0.7)
	_tocar_em(som_telhado, som_baque, alto + Vector3(0.0, -6.0, 4.0), -4.0)
	await _esperar(2.0)
	# O cheiro: a imagem lacrimeja e turva, o fôlego curto; os cães ganem.
	await _frase(&"cheiro")
	if not is_inside_tree():
		return
	var sonho := create_tween().set_trans(Tween.TRANS_SINE)
	sonho.tween_method(func(v: float) -> void: GameState.set_value(&"sonho", v), 0.0, 0.55, 2.5)
	sonho.tween_interval(2.0)
	sonho.tween_method(func(v: float) -> void: GameState.set_value(&"sonho", v), 0.55, 0.0, 4.0)
	var folego := p.respiracao
	var f := create_tween().set_trans(Tween.TRANS_SINE)
	f.tween_property(p, ^"respiracao", folego * 3.0, 1.5)
	f.tween_interval(4.0)
	f.tween_property(p, ^"respiracao", folego * 1.6, 3.0)
	# Ele cobre o rosto: a cabeça baixa.
	p.olhar_para(diante + Vector3(0.0, -0.9, 0.0), 1.2)
	for nome in ["Brutus", "Conan"]:
		var c := matilha.cao(nome)
		if c:
			c._som(matilha.choramingo, -6.0)
			await _esperar(0.8)
	await _esperar(4.5)


## As balas: os latidos viram para a frente; um tiro bate no tabuado; outro
## estoura a vidraça (um caco rente ao rosto); o terceiro, com o clarão na mata,
## lasca a estante. Ele se levanta e se abaixa; e o jogo é dele.
func _balas(p: Player) -> void:
	etapa = Etapa.BALAS
	await _calar(8.0)
	if not is_inside_tree():
		return
	matilha.modo = Matilha.Modo.FRENTE
	p.olhar_para(diante + Vector3.UP * 0.4, 1.0)
	await _esperar(3.5)
	_tiro_de_la()
	await _esperar(0.18)
	_tocar_em(som_telhado, som_lascas, bate_tabuado, -6.0)
	await _esperar(1.8)
	_tiro_de_la()
	await _esperar(0.14)
	_estourar()
	Narrator.say(frases.get(&"balas"))
	# De pé, e abaixado, fora da poltrona.
	p.stand()
	p._desencaixar()
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(p, ^"abaixar", 0.45, 0.35)
	await _esperar(1.4)
	if clarao:
		clarao.visible = true
	_tiro_de_la()
	await _esperar(0.08)
	if clarao:
		clarao.visible = false
	await _esperar(0.06)
	_tocar_em(som_telhado, som_lascas, bate_estante, 2.0)
	if lascas:
		lascas.restart()
		lascas.emitting = true
	_tremer(0.4)
	await _esperar(1.2)
	create_tween().tween_property(p, ^"abaixar", 0.0, 0.8)
	# A vez dele: apagar a luz.
	etapa = Etapa.APAGAR
	_ocupado = false
	_ligar_areas()
	p.input_enabled = true
	_tiros_de_la = true
	_tiros_soltos()


## Um lampião apagado (o do escritório primeiro: "Apaguei a luz,").
func _apagou(l: Lampiao) -> void:
	if etapa == Etapa.APAGAR and l == apagar[0]:
		Narrator.say(frases.get(&"apaguei"))
		etapa = Etapa.TIROS
	_ligar_areas()


# --- Os tiros -------------------------------------------------------------------

## "Atirar pela janela": até a janela, a fresta, o rifle ao ombro, o cano que sobe
## sozinho, o tiro e o clarão no quintal, a alavanca, o cartucho no chão.
func _atirar(i: int) -> void:
	if _ocupado or _ja_atirou(i):
		return
	_ocupado = true
	_ocioso = 0.0
	atirar[i].set_meta(&"atirou", true)
	_ligar_areas()
	var p := matilha.akeley()
	p.input_enabled = false
	var v := seteiras[i]
	var fora := atirar[i].get_meta(&"fora", Vector3.FORWARD) as Vector3
	var longe := v.global_position + fora * 14.0
	# Onde o corpo cabe e se chega em linha reta (a cena passa por cima da física:
	# playtest 12, depois, o preso entre os móveis).
	var junto := v.junto(p, [0.55, 0.4, 0.7, 0.3])
	if junto != Vector3.INF:
		await p.conduzir([junto], longe)
	else:
		await p.olhar_para(longe, 0.5).finished
	if not is_inside_tree():
		return
	await v.fresta(true, 65.0)
	var rifle := preparacao.rifle if preparacao else null
	var pos0 := Vector3.ZERO
	var rot0 := Vector3.ZERO
	if rifle:
		pos0 = rifle.posicao
		rot0 = rifle.rotacao
		var r := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		r.tween_property(rifle, ^"posicao", Vector3(0.05, -0.12, -0.2), 0.6)
		r.tween_property(rifle, ^"rotacao", Vector3(1.0, 0.0, 0.0), 0.6)
		r.tween_property(rifle, ^"erguer", 1.0, 0.4)
	# O cano sobe sozinho, alto: por cima dos cães.
	await p.olhar_para(longe + Vector3.UP * 3.2, 0.9).finished
	if not is_inside_tree():
		return
	await _esperar(0.3)
	_disparar(p, v, fora)
	if rifle:
		var k := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		k.tween_property(rifle, ^"posicao:z", -0.12, 0.05)
		k.tween_property(rifle, ^"posicao:z", -0.2, 0.3)
	var cabeca := p.head.rotation.x
	var coice := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	coice.tween_property(p.head, ^"rotation:x", cabeca + 0.07, 0.06)
	coice.tween_property(p.head, ^"rotation:x", cabeca, 0.45)
	tiros += 1
	if preparacao:
		preparacao.cartuchos = maxi(preparacao.cartuchos - 1, 0)
	if tiros == 1:
		Narrator.say(frases.get(&"seteiras"))
	# Num dos tiros, sempre, o ganido que corta.
	if tiros == TIRO_DO_GANIDO + 1:
		await _esperar(0.3)
		var ferido := _cao_ferido(v.global_position + fora * 6.0)
		if ferido:
			ferido.ferir()
	await _esperar(0.5)
	# A alavanca (playtest 12: abre e fecha de verdade): o estojo vazio salta da
	# culatra e cai no assoalho.
	if rifle:
		rifle.ciclar(som_alavanca)
		await _esperar(0.09)
	else:
		_tocar(som_alavanca, -2.0)
	_cartucho(p, rifle)
	await _esperar(0.9)
	await v.fresta(false)
	if rifle:
		var b := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		b.tween_property(rifle, ^"posicao", pos0, 0.6)
		b.tween_property(rifle, ^"rotacao", rot0, 0.6)
	if not is_inside_tree():
		return
	_ocupado = false
	_ligar_areas()
	p.input_enabled = true
	if tiros >= atirar.size():
		_encerrar(p)


## O estampido, o clarão do cano e o do quintal (um quadro: as árvores, a cerca,
## os cães correndo, nada mais).
func _disparar(p: Player, v: Venezianas, fora: Vector3) -> void:
	_tocar(som_tiro, 0.0)
	_tremer(0.8)
	# O clarão do cano já do lado de fora (dentro, estourava a moldura), e o
	# quintal clareado de perto da casa até a cerca.
	var cano := OmniLight3D.new()
	cano.light_color = Color(1.0, 0.75, 0.45)
	cano.light_energy = 2.0
	cano.omni_range = 3.5
	add_child(cano)
	cano.global_position = v.global_position + fora * 0.6
	var quintal := OmniLight3D.new()
	quintal.light_color = Color(1.0, 0.85, 0.65)
	quintal.light_energy = 7.0
	quintal.omni_range = 30.0
	quintal.omni_attenuation = 0.8
	quintal.shadow_enabled = true
	add_child(quintal)
	quintal.global_position = v.global_position + fora * 5.0 + Vector3.UP * 1.5
	# O clarão na boca do cano e a fumaça que fica na fresta (playtest 12).
	var rifle := preparacao.rifle if preparacao else null
	var flash := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.32, 0.32)
	var mf := StandardMaterial3D.new()
	mf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mf.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mf.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mf.albedo_color = Color(1.0, 0.75, 0.4)
	mf.albedo_texture = LuzGuia._textura()
	q.material = mf
	flash.mesh = q
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flash)
	flash.global_position = rifle.boca() if rifle else v.global_position + fora * 0.4
	_fumaca(flash.global_position, fora)
	await _esperar(0.07)
	cano.queue_free()
	quintal.queue_free()
	flash.queue_free()


## A fumaça da pólvora negra, branca e espessa, que sai pela fresta e se desfaz.
func _fumaca(onde: Vector3, fora: Vector3) -> void:
	var e := CPUParticles3D.new()
	e.one_shot = true
	e.explosiveness = 0.85
	e.amount = 26
	e.lifetime = 2.6
	e.direction = fora + Vector3.UP * 0.2
	e.spread = 22.0
	e.initial_velocity_min = 0.6
	e.initial_velocity_max = 1.6
	e.damping_min = 1.2
	e.damping_max = 2.0
	e.gravity = Vector3(0, 0.12, 0)
	e.scale_amount_min = 1.0
	e.scale_amount_max = 2.6
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.7, 0.68, 0.22)
	m.albedo_texture = LuzGuia._textura()
	q.material = m
	e.mesh = q
	add_child(e)
	e.global_position = onde
	e.emitting = true
	get_tree().create_timer(3.0, false).timeout.connect(e.queue_free)


## O cão do ganido: o mais perto de onde o tiro foi, dos que estão lá fora.
func _cao_ferido(onde: Vector3) -> CaoIA:
	var melhor: CaoIA = null
	var d := INF
	for c in matilha.caes():
		if c.fugiu or c.caido or c.papel == CaoIA.Papel.SEGUIR or c.papel == CaoIA.Papel.FOGO:
			continue
		var e := c.global_position.distance_to(onde)
		if e < d:
			d = e
			melhor = c
	return melhor


## O cartucho vazio: sai da culatra, cai no assoalho, quica e fica.
func _cartucho(p: Player, rifle: Rifle = null) -> void:
	var c := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.006
	cil.bottom_radius = 0.0065
	cil.height = 0.05
	cil.radial_segments = 6
	cil.rings = 1
	c.mesh = cil
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.55, 0.25)
	mat.metallic = 0.7
	mat.roughness = 0.35
	c.material_override = mat
	add_child(c)
	var de := p.camera.global_position - p.camera.global_basis.z * 0.3 + p.camera.global_basis.x * 0.08 - Vector3.UP * 0.12
	if rifle:
		de = rifle.global_transform * Vector3(0.0, 0.05, 0.07)
	var chao := Vector3(de.x, p.global_position.y + 0.007, de.z) + p.global_basis.x * _rng.randf_range(0.25, 0.55)
	c.global_position = de
	# Salta para cima e para a direita, gira, e cai.
	var t := create_tween()
	t.tween_method(func(u: float) -> void:
		if is_instance_valid(c):
			var alto := sin(u * PI) * 0.22 + (1.0 - u) * 0.05
			c.global_position = de.lerp(chao, u) + Vector3.UP * alto
			c.rotation = Vector3(u * 14.0, u * 6.0, 0.0), 0.0, 1.0, 0.55)
	t.tween_callback(func() -> void:
		if is_instance_valid(c):
			c.rotation = Vector3(0.0, _rng.randf() * TAU, PI / 2.0)
		_tocar(som_cartucho, -6.0))


## Os tiros de lá, de tempos em tempos, longe, enquanto ele atira.
func _tiros_soltos() -> void:
	while _tiros_de_la and is_inside_tree():
		await _esperar(_rng.randf_range(7.0, 14.0))
		if _tiros_de_la and not _ocupado:
			_tiro_de_la()


func _tiro_de_la() -> void:
	if som_tiro_longe:
		var s := AudioStreamPlayer3D.new()
		s.stream = som_tiro_longe
		s.bus = &"SFX"
		s.unit_size = 30.0
		s.max_distance = 400.0
		s.volume_db = 4.0
		s.pitch_scale = _rng.randf_range(0.92, 1.06)
		add_child(s)
		s.global_position = mata_frente + Vector3(_rng.randf_range(-12.0, 12.0), 0.0, _rng.randf_range(-6.0, 6.0))
		s.finished.connect(s.queue_free)
		s.play()


## A vidraça estoura: o vidro some, os cacos voam para dentro e ficam no
## assoalho, um passa rente ao rosto; a bala abre a veneziana.
func _estourar() -> void:
	_tocar(som_vidro, 0.0)
	_tremer(0.7)
	if vidraca:
		vidraca.visible = false
	if janela_bala:
		janela_bala.fresta(true)
	if estilhacos == null:
		return
	estilhacos.visible = true
	var p := matilha.akeley()
	var cacos := estilhacos.get_children()
	for k in cacos.size():
		var c := cacos[k] as Node3D
		var de := c.global_position
		var lado := para_dentro.cross(Vector3.UP).normalized()
		var chao := de + para_dentro * _rng.randf_range(0.3, 1.9) + lado * _rng.randf_range(-0.7, 0.7)
		chao.y = c.get_meta(&"chao", de.y - 1.0)
		var meio := Vector3.INF
		# O primeiro passa rente ao rosto.
		if k == 0 and p:
			meio = p.camera.global_position + p.camera.global_basis.x * 0.28 + Vector3.UP * 0.05
			chao = meio + para_dentro * 0.9
			chao.y = c.get_meta(&"chao", de.y - 1.0)
		var giro := Vector3(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-8.0, 8.0), _rng.randf_range(-8.0, 8.0))
		var yaw := _rng.randf() * TAU
		var dur := _rng.randf_range(0.45, 0.8)
		var t := create_tween()
		t.tween_method(func(u: float) -> void:
			if not is_instance_valid(c):
				return
			if meio != Vector3.INF:
				c.global_position = de.lerp(meio, u * 2.0) if u < 0.5 else meio.lerp(chao, (u - 0.5) * 2.0)
			else:
				c.global_position = de.lerp(chao, u) + Vector3.UP * sin(u * PI) * 0.25
			c.rotation = giro * u * (1.0 - u) + Vector3(0.0, yaw, 0.0) * u, 0.0, 1.0, dur)
		t.tween_callback(func() -> void:
			if is_instance_valid(c):
				c.rotation = Vector3(0.0, yaw, 0.0))


# --- O fim ----------------------------------------------------------------------

## Os latidos param um a um; ele no escuro, respirando; "Isso pareceu encerrar a
## coisa".
func _encerrar(p: Player) -> void:
	etapa = Etapa.FIM
	_tiros_de_la = false
	_ligar_areas()
	p.input_enabled = false
	matilha.modo = Matilha.Modo.CALADOS
	await _esperar(8.5)
	if not is_inside_tree():
		return
	await Narrator.say(frases.get(&"encerrar"))
	if not is_inside_tree():
		return
	await _esperar(2.5)
	_fim()


func _fim() -> void:
	if feita:
		return
	feita = true
	set_process(false)
	terminou.emit()


## Tudo de uma vez (testes; F2 na fazenda): os tiros dados, os cães calados.
func pular() -> void:
	if preparacao:
		preparacao.encerrar()
	etapa = Etapa.FIM
	tiros = atirar.size()
	for a in atirar:
		a.set_meta(&"atirou", true)
	for l in apagar:
		if l.aceso:
			l.aceso = false
			l._k = 0.0
			l._mostrar()
	if vidraca:
		vidraca.visible = false
	_tiros_de_la = false
	matilha.modo = Matilha.Modo.CALADOS
	_ligar_areas()
	_fim()


# --- Ajudantes ------------------------------------------------------------------

func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout


## Espera a frase na tela acabar (no máximo `teto` segundos).
func _calar(teto: float) -> void:
	var t := 0.0
	while Narrator.is_speaking() and t < teto and is_inside_tree():
		await get_tree().process_frame
		t += get_process_delta_time()


## A frase seguinte da carta, quando a anterior acabar: a coisa acontece com ela.
func _frase(id: StringName) -> void:
	await _calar(9.0)
	if is_inside_tree():
		Narrator.say(frases.get(id))


func _tremer(forca: float) -> void:
	_tremor = maxf(_tremor, forca)


## A poeira do forro (o quanto cai).
func _poeira(quanto: float) -> void:
	for e in poeira:
		var base: int = e.get_meta(&"base", e.amount)
		e.set_meta(&"base", base)
		e.amount = maxi(4, roundi(base * clampf(quanto, 0.1, 1.0)))
		e.restart()
		e.emitting = true
	_tocar(som_poeira, linear_to_db(clampf(quanto, 0.2, 1.0)) - 4.0)


## O lampião do escritório tine e a chama pula.
func _tinir_lampiao() -> void:
	if apagar.is_empty():
		return
	var l := apagar[0]
	if not l.aceso:
		return
	if l.som_vidro:
		AudioDirector.play_sfx(l.som_vidro, -8.0)
	var t := create_tween()
	t.tween_property(l, ^"_k", 0.55, 0.08)
	t.tween_property(l, ^"_k", 1.0, 0.5)


## Um som avulso de `player` (posicional) em `onde`.
func _tocar_em(player: AudioStreamPlayer3D, s: AudioStream, onde: Vector3, db: float) -> void:
	if s == null or player == null:
		return
	var a := AudioStreamPlayer3D.new()
	a.stream = s
	a.bus = &"SFX"
	a.unit_size = player.unit_size
	a.max_distance = player.max_distance
	a.volume_db = db
	add_child(a)
	a.global_position = onde
	a.finished.connect(a.queue_free)
	a.play()


func _tocar(s: AudioStream, db: float) -> void:
	if s:
		AudioDirector.play_sfx(s, db)
