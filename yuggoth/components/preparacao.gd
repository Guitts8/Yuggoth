class_name Preparacao
extends Node
## A preparação para a noite (docs/PLANO_FAZENDA.md, F6; "A tratativa", 2), no
## crepúsculo, em qualquer ordem: os quatro lampiões do térreo (o escritório, o
## vestíbulo, a sala de estar, a cozinha), as venezianas do escritório e da sala,
## o rifle (tirado do armário da sala dos fundos e carregado na bancada, cartucho
## por cartucho), a lareira do escritório (com a lenha da rotina: Conan vem deitar
## diante dela) e a porteira do cercado (os cães ficam soltos no quintal, de
## guarda). O telefone, se ele tentar: mudo. Enquanto isso a noite cai, e a lua
## cheia que nasce sobre os morros do leste é engolida pelas nuvens.

signal terminou

const CARTUCHOS := 4
const FLAG_LAREIRA := &"lareira_akeley"

@export var matilha: Matilha
@export var lampioes: Array[Lampiao] = []
@export var venezianas: Array[Venezianas] = []
@export var rifle: NaMao
@export var rifle_armario: Node3D
@export var pegar_rifle: Interactable
@export var carregar_rifle: Interactable
@export var acender_lareira: AcenderLareira
@export var soltar_caes: Interactable
@export var porteira: Node3D
@export var telefone: Interactable
## Onde Conan deita diante do fogo (do mundo).
@export var diante_do_fogo := Vector3.ZERO
@export_group("O céu")
@export var lua: Node3D
@export var nuvens: Node3D
## A lua nasce de `lua_de` a `lua_ate`; as nuvens vão de `nuvens_de` a `nuvens_ate`.
@export var lua_de := Vector3.ZERO
@export var lua_ate := Vector3.ZERO
@export var nuvens_de := Vector3.ZERO
@export var nuvens_ate := Vector3.ZERO
@export_group("Sons")
@export var som_rifle: AudioStream
@export var som_cartucho: AudioStream
@export var som_alavanca: AudioStream
@export var som_porteira: AudioStream
@export var som_gancho: AudioStream
@export_group("Falas")
@export var lembretes: Dictionary[StringName, NarrationLine] = {}
## O primeiro lampião (a carta de terça: a luz elétrica que eles cortariam).
@export var linha_lampiao: NarrationLine
@export var linha_rifle: NarrationLine
@export var linha_telefone: NarrationLine
@export var linha_lua: NarrationLine

var cartuchos := 0
var caes_soltos := false
var lareira_acesa := false
var feita := false
var _ativa := false
var _ocupado := false
var _ocioso := 0.0
var _fazenda: Node


func _ready() -> void:
	set_process(false)
	for l in lampioes:
		l.mudou.connect(func(_a: bool) -> void: _depois_de(&"lampiao"))
	for v in venezianas:
		v.fechou.connect(func() -> void: _depois_de(&"veneziana"))
	for a: Interactable in [pegar_rifle, carregar_rifle, soltar_caes, telefone]:
		if a:
			a.interacted.connect(_on_area.bind(a))
	# A lareira conta quando o fogo pega (a flag da AcenderLareira).
	GameState.value_changed.connect(_on_value_changed)
	if rifle:
		rifle.visible = false
		rifle.process_mode = Node.PROCESS_MODE_DISABLED
	if lua:
		lua.visible = false
	if nuvens:
		nuvens.visible = false
	_ligar_areas.call_deferred()


## Começa (a fazenda chama, terminada a rotina): o céu da noite, as áreas.
func comecar(fazenda: Node) -> void:
	_fazenda = fazenda
	_ativa = true
	set_process(true)
	_ligar_areas()
	_ceu()


func _process(delta: float) -> void:
	var p := matilha.akeley()
	if p == null or not p.input_enabled or _ocupado or feita:
		_ocioso = 0.0
		return
	_ocioso += delta
	if _ocioso > 35.0:
		_ocioso = 0.0
		var linha := lembretes.get(_falta(), null) as NarrationLine
		if linha and not Narrator.is_speaking():
			Narrator.say(linha)


func _falta() -> StringName:
	if lampioes.any(func(l: Lampiao) -> bool: return not l.aceso):
		return &"lampioes"
	if venezianas.any(func(v: Venezianas) -> bool: return not v.fechada):
		return &"venezianas"
	if cartuchos < CARTUCHOS:
		return &"rifle"
	if not lareira_acesa:
		return &"lareira"
	if not caes_soltos:
		return &"caes"
	return &""


## O que a luz-guia pode apontar agora (LuzGuia): o que falta da preparação (o
## telefone, que é à toa, não).
func guias() -> Array[Interactable]:
	var todas: Array[Interactable] = []
	todas.append_array(lampioes)
	todas.append_array(venezianas)
	todas.append_array([pegar_rifle, carregar_rifle, acender_lareira, soltar_caes])
	return todas


func _ligar_areas() -> void:
	for l in lampioes:
		_ligar(l, _ativa and not l.aceso)
	for v in venezianas:
		_ligar(v, _ativa and not v.fechada)
	var com_rifle := rifle != null and rifle.visible
	_ligar(pegar_rifle, _ativa and not com_rifle and cartuchos < CARTUCHOS)
	_ligar(carregar_rifle, _ativa and com_rifle and cartuchos < CARTUCHOS)
	_ligar(acender_lareira, _ativa and not lareira_acesa)
	_ligar(soltar_caes, _ativa and not caes_soltos)
	_ligar(telefone, _ativa)


func _ligar(a: Interactable, sim: bool) -> void:
	if a == null:
		return
	a.collision_layer = Interactable.LAYER_INTERACAO if sim else 0


func _on_area(_by: Node, a: Interactable) -> void:
	if _ocupado:
		return
	_ocupado = true
	_ocioso = 0.0
	var p := matilha.akeley()
	p.input_enabled = false
	if a == pegar_rifle:
		await p.olhar_para(pegar_rifle.global_position, 0.5).finished
		_tocar(som_rifle, -3.0)
		if rifle_armario:
			rifle_armario.visible = false
		rifle.visible = true
		rifle.process_mode = Node.PROCESS_MODE_INHERIT
		rifle.erguer = 0.0
		var t := create_tween()
		t.tween_property(rifle, ^"erguer", 1.0, 0.6)
		await t.finished
		if linha_rifle:
			Narrator.say(linha_rifle)
	elif a == carregar_rifle:
		# Um cartucho por vez (E de novo para o seguinte); o último fecha a alavanca.
		await p.olhar_para(carregar_rifle.global_position, 0.4).finished
		cartuchos += 1
		_tocar(som_cartucho, -3.0)
		await get_tree().create_timer(0.5, false).timeout
		if cartuchos >= CARTUCHOS:
			_tocar(som_alavanca, -2.0)
			await get_tree().create_timer(0.6, false).timeout
		carregar_rifle.prompt = "Pôr mais um cartucho (%d de %d)" % [cartuchos, CARTUCHOS] if cartuchos < CARTUCHOS else "Carregar o rifle"
	elif a == soltar_caes:
		caes_soltos = true
		_tocar(som_porteira, -3.0)
		var t := create_tween().set_trans(Tween.TRANS_SINE)
		t.tween_property(porteira, ^"rotation_degrees:y", -100.0, 1.4)
		await t.finished
		matilha.modo = Matilha.Modo.SOLTOS
	elif a == telefone:
		_tocar(som_gancho, -4.0)
		await get_tree().create_timer(1.6, false).timeout
		_tocar(som_gancho, -6.0)
		if linha_telefone:
			Narrator.say(linha_telefone)
	if not is_inside_tree():
		return
	_ocupado = false
	p.input_enabled = true
	_depois_de(&"")


func _on_value_changed(k: StringName, _v: Variant) -> void:
	if k == FLAG_LAREIRA and not lareira_acesa:
		_lareira()


func _lareira() -> void:
	lareira_acesa = true
	matilha.fogo = diante_do_fogo
	_depois_de(&"lareira")


func _depois_de(o_que: StringName) -> void:
	if o_que == &"lampiao" and linha_lampiao and lampioes.filter(func(l: Lampiao) -> bool: return l.aceso).size() == 1:
		Narrator.say(linha_lampiao)
	_ligar_areas()
	if not feita and _falta() == &"":
		feita = true
		terminou.emit()


## O céu da noite: a lua cheia nasce sobre os morros do leste, as nuvens a engolem.
func _ceu() -> void:
	if lua == null:
		return
	await get_tree().create_timer(12.0, false).timeout
	if not is_inside_tree():
		return
	lua.visible = true
	lua.position = lua_de
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(lua, ^"position", lua_ate, 40.0)
	await get_tree().create_timer(26.0, false).timeout
	if not is_inside_tree():
		return
	if linha_lua:
		Narrator.say(linha_lua)
	if nuvens:
		nuvens.visible = true
		nuvens.position = nuvens_de
		var n := create_tween().set_trans(Tween.TRANS_SINE)
		n.tween_property(nuvens, ^"position", nuvens_ate, 30.0)
		await n.finished
		if is_inside_tree():
			lua.visible = false


## Tudo feito de uma vez (testes; F2 na fazenda).
func pular() -> void:
	for l in lampioes:
		if not l.aceso:
			l.aceso = true
			l._k = 1.0
			l._mostrar()
	for v in venezianas:
		v.fechar_ja()
	cartuchos = CARTUCHOS
	if rifle_armario:
		rifle_armario.visible = false
	if rifle:
		rifle.visible = true
		rifle.process_mode = Node.PROCESS_MODE_INHERIT
		rifle.erguer = 1.0
	if acender_lareira and not lareira_acesa:
		acender_lareira._acender()
		if acender_lareira.fogo:
			acender_lareira.fogo.intensidade = 1.0
		_lareira()
	caes_soltos = true
	if porteira:
		porteira.rotation_degrees.y = -100.0
	matilha.modo = Matilha.Modo.SOLTOS
	_depois_de(&"")


func _tocar(s: AudioStream, db: float) -> void:
	if s:
		AudioDirector.play_sfx(s, db)
