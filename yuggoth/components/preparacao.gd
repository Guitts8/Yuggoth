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
@export var rifle: Rifle
@export var rifle_armario: Node3D
@export var pegar_rifle: Interactable
@export var carregar_rifle: Interactable
@export var acender_lareira: AcenderLareira
@export var soltar_caes: Interactable
@export var porteira: Node3D
## A lingueta do trinco da porteira (gira para cima ao abrir).
@export var trinco: Node3D
@export var telefone: Interactable
## As peças do telefone que se mexem: o fone (vai à orelha), o gancho, a manivela.
@export var fone: Node3D
@export var gancho: Node3D
@export var manivela: Node3D
## De onde saem os cartuchos (o alto da caixa na bancada, do mundo).
@export var cartuchos_caixa := Vector3.ZERO
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
@export var som_manivela: AudioStream
@export var som_trinco: AudioStream
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
## Onde ele ficou carregando (afastou-se dali, o rifle volta à pose de levar).
var _onde_carrega := Vector3.INF


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
	# Afastou-se da bancada no meio da carga: o rifle volta a ser levado.
	if p and _onde_carrega != Vector3.INF and not _ocupado and p.global_position.distance_to(_onde_carrega) > 0.7:
		_onde_carrega = Vector3.INF
		if rifle:
			rifle.carga(false)
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
		await _pegar_o_rifle(p)
	elif a == carregar_rifle:
		await _carregar(p)
	elif a == soltar_caes:
		await _soltar(p)
	elif a == telefone:
		await _telefonar(p)
	if not is_inside_tree():
		return
	_ocupado = false
	p.input_enabled = true
	_depois_de(&"")


# --- O rifle ---------------------------------------------------------------------

## Do armário: o rifle sobe do cabide, sai do vão e vem para a mão; ele entreabre
## a alavanca (o depósito vazio) e a fecha.
func _pegar_o_rifle(p: Player) -> void:
	await p.olhar_para(rifle_armario.global_position + Vector3(0, 0.15, 0) if rifle_armario else pegar_rifle.global_position, 0.5).finished
	if not is_inside_tree():
		return
	_tocar(som_rifle, -3.0)
	rifle.visible = true
	rifle.process_mode = Node.PROCESS_MODE_INHERIT
	rifle.erguer = 1.0
	if rifle_armario:
		# A Corpo do rifle na mão fica 0,1 m atrás da origem (gerar_fazenda): no
		# cabide, a mesma peça no mesmo lugar.
		var no_cabide := rifle_armario.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.1))
		rifle.no_mundo = no_cabide
		rifle.peso_mao = 0.0
		rifle_armario.visible = false
		rifle.process_mode = Node.PROCESS_MODE_INHERIT
		# Sobe para fora do cabide, e vem.
		var sobe := create_tween().set_trans(Tween.TRANS_SINE)
		sobe.tween_property(rifle, ^"no_mundo:origin:y", no_cabide.origin.y + 0.14, 0.4)
		await sobe.finished
		rifle.arco = 0.1
		await rifle.pegar(0.75).finished
	if not is_inside_tree():
		return
	await rifle.ciclar(som_alavanca, true)
	if linha_rifle:
		Narrator.say(linha_rifle)


## Na bancada, um cartucho por vez (E de novo para o seguinte): o rifle vem para a
## frente e deita (a portinhola para cima); o cartucho sai da caixa, gira, encosta
## na portinhola e é empurrado para dentro com o estalo; o rifle dá um tranco. O
## último, a alavanca: o cartucho na câmara, o cão engatilhado; e o rifle volta.
func _carregar(p: Player) -> void:
	# Os olhos um pouco acima da caixa: o rifle deitado diante do peito, por cima dela.
	await p.olhar_para((cartuchos_caixa if cartuchos_caixa != Vector3.ZERO else carregar_rifle.global_position) + Vector3(0, 0.22, 0), 0.4).finished
	if not is_inside_tree():
		return
	_onde_carrega = p.global_position
	if not rifle.na_carga:
		await rifle.carga(true).finished
	var c := _cartucho_novo()
	add_child(c)
	var de := cartuchos_caixa if cartuchos_caixa != Vector3.ZERO else carregar_rifle.global_position
	c.global_position = de
	# Do alto da caixa até a portinhola, deitando no rumo do depósito.
	var deitar := Basis(Vector3.RIGHT, -PI / 2.0)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(u: float) -> void:
		if not is_instance_valid(c):
			return
		var perto := rifle.portinhola(Vector3(0.03, 0.0, 0.07))
		var pos := de.lerp(perto, u) + Vector3.UP * sin(u * PI) * 0.08
		var b := Basis.IDENTITY.slerp(rifle.global_basis * deitar, u)
		c.global_transform = Transform3D(b, pos), 0.0, 1.0, 0.6)
	await t.finished
	if not is_inside_tree():
		return
	# Empurrado para dentro: encosta, entra, some.
	var e := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	e.tween_method(func(u: float) -> void:
		if not is_instance_valid(c):
			return
		var pos := rifle.portinhola(Vector3(0.03, 0.0, 0.07).lerp(Vector3(0.0, 0.0, -0.035), u))
		c.global_transform = Transform3D(rifle.global_basis * deitar, pos), 0.0, 1.0, 0.28)
	await e.finished
	c.queue_free()
	cartuchos += 1
	_tocar(som_cartucho, -3.0)
	var tranco := rifle.gesto(Vector3(0, -0.008, 0.012), Vector3(-2.0, 0, 0), 0.06)
	await tranco.finished
	await rifle.gesto(Vector3.ZERO, Vector3.ZERO, 0.2).finished
	if cartuchos >= CARTUCHOS:
		await get_tree().create_timer(0.25, false).timeout
		_onde_carrega = Vector3.INF
		await rifle.carga(false, 0.5).finished
		await rifle.ciclar(som_alavanca)
	carregar_rifle.prompt = "Pôr mais um cartucho (%d de %d)" % [cartuchos, CARTUCHOS] if cartuchos < CARTUCHOS else "Carregar o rifle"


## Um cartucho .45-90: o estojo de latão, a bala de chumbo.
func _cartucho_novo() -> Node3D:
	var n := Node3D.new()
	n.name = "_Cartucho"
	n.top_level = true
	var estojo := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.0065
	cil.bottom_radius = 0.007
	cil.height = 0.06
	cil.radial_segments = 8
	cil.rings = 1
	estojo.mesh = cil
	var latao := StandardMaterial3D.new()
	latao.albedo_color = Color(0.78, 0.6, 0.28)
	latao.metallic = 0.7
	latao.roughness = 0.35
	estojo.material_override = latao
	estojo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(estojo)
	var bala := MeshInstance3D.new()
	var b := CylinderMesh.new()
	b.top_radius = 0.003
	b.bottom_radius = 0.0062
	b.height = 0.018
	b.radial_segments = 8
	b.rings = 1
	bala.mesh = b
	var chumbo := StandardMaterial3D.new()
	chumbo.albedo_color = Color(0.42, 0.42, 0.44)
	chumbo.roughness = 0.6
	bala.material_override = chumbo
	bala.position = Vector3(0, 0.039, 0)
	bala.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(bala)
	return n


# --- O telefone e a porteira -----------------------------------------------------

## O fone vai à orelha; ele dá manivela para a telefonista; nada: aperta o gancho
## duas vezes; nada. O fone volta para o gancho.
func _telefonar(p: Player) -> void:
	# Até o aparelho (na parede sul do vestíbulo, de frente para o norte).
	var diante := telefone.global_position + Vector3(0, 0, -0.62)
	diante.y = p.global_position.y
	if Vector2(diante.x - p.global_position.x, diante.z - p.global_position.z).length() > 0.3:
		await p.conduzir([diante], telefone.global_position)
		if not is_inside_tree():
			return
	await p.olhar_para(telefone.global_position + Vector3(0, 0.02, 0), 0.45).finished
	if not is_inside_tree():
		return
	_tocar(som_gancho, -4.0)
	var no_gancho := fone.transform if fone else Transform3D.IDENTITY
	if fone:
		var orelha := func() -> Transform3D:
			var cam := p.camera.global_transform
			# Na mão esquerda, junto ao rosto, à vista no canto (sem mãos).
			return Transform3D(cam.basis * Basis(Vector3.FORWARD, deg_to_rad(-20.0)) * Basis(Vector3.RIGHT, deg_to_rad(-10.0)), cam * Vector3(-0.17, -0.05, -0.22))
		var ini := fone.global_transform
		var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_method(func(u: float) -> void:
			if is_instance_valid(fone):
				fone.global_transform = ini.interpolate_with(orelha.call(), u), 0.0, 1.0, 0.6)
		if gancho:
			t.parallel().tween_property(gancho, ^"rotation:z", deg_to_rad(-14.0), 0.15)
		await t.finished
		# Na orelha, enquanto ele escuta (segue a cabeça).
		set_meta(&"_orelha", orelha)
	# A manivela do magneto: duas voltas.
	if manivela:
		_tocar(som_manivela, -8.0)
		var gira := create_tween()
		gira.tween_property(manivela, ^"rotation:x", manivela.rotation.x + TAU * 2.0, 1.1)
		await _seguir_fone(gira, p)
	await _esperar_fone(1.3, p)
	# O gancho, duas vezes: a telefonista? Nada.
	if gancho:
		for k in 2:
			_tocar(som_gancho, -9.0)
			var g := create_tween()
			g.tween_property(gancho, ^"rotation:z", 0.0, 0.08)
			g.tween_property(gancho, ^"rotation:z", deg_to_rad(-14.0), 0.12)
			await _seguir_fone(g, p)
	if linha_telefone:
		Narrator.say(linha_telefone)
	await _esperar_fone(1.2, p)
	if fone:
		var ini := fone.global_transform
		var pai := fone.get_parent_node_3d()
		var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_method(func(u: float) -> void:
			if is_instance_valid(fone):
				fone.global_transform = ini.interpolate_with(pai.global_transform * no_gancho, u), 0.0, 1.0, 0.55)
		await t.finished
		fone.transform = no_gancho
		remove_meta(&"_orelha")
	if gancho:
		var g := create_tween()
		g.tween_property(gancho, ^"rotation:z", 0.0, 0.1)
	_tocar(som_gancho, -6.0)


## Enquanto `t` corre, o fone fica na orelha (seguindo a cabeça que o mouse vira).
func _seguir_fone(t: Tween, p: Player) -> void:
	while t.is_running():
		_fone_na_orelha()
		await get_tree().process_frame
		if not is_inside_tree():
			return
	if p:
		_fone_na_orelha()


func _esperar_fone(segundos: float, _p: Player) -> void:
	var t := 0.0
	while t < segundos and is_inside_tree():
		_fone_na_orelha()
		await get_tree().process_frame
		t += get_process_delta_time()


func _fone_na_orelha() -> void:
	if fone and has_meta(&"_orelha"):
		fone.global_transform = (get_meta(&"_orelha") as Callable).call()


## A porteira: ele chega ao trinco, ergue a lingueta (o estalo), empurra a porteira
## para dentro do cercado — ela vai pesada, repica no fim — e recua um passo; os
## cães saem pelo vão, um atrás do outro.
func _soltar(p: Player) -> void:
	caes_soltos = true
	if trinco:
		var t_pos := trinco.global_position
		var diante := t_pos + Vector3(0.25, 0.0, 0.75)
		diante.y = p.global_position.y
		await p.conduzir([diante], t_pos)
		if not is_inside_tree():
			return
		_tocar(som_trinco, -6.0)
		var ergue := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ergue.tween_property(trinco, ^"rotation:z", deg_to_rad(65.0), 0.25)
		await ergue.finished
	_tocar(som_porteira, -3.0)
	p.olhar_para(porteira.global_position + Vector3(0.7, 0.6, -0.6), 0.9)
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(porteira, ^"rotation_degrees:y", 100.0, 1.5)
	if trinco:
		t.parallel().tween_property(trinco, ^"rotation:z", 0.0, 0.3).set_delay(0.6)
	await get_tree().create_timer(0.45, false).timeout
	matilha.porteira_aberta = true
	matilha.modo = Matilha.Modo.SOLTOS
	if t.is_running():
		await t.finished
	# Um passo para trás, abrindo caminho.
	var atras := p.global_position + Vector3(0.6, 0, 0.7)
	await p.conduzir([atras], matilha.porteira_fora + Vector3(0, 0.4, 0))


func _on_value_changed(k: StringName, _v: Variant) -> void:
	if k == FLAG_LAREIRA and not lareira_acesa:
		_lareira()


func _lareira() -> void:
	lareira_acesa = true
	matilha.fogo = diante_do_fogo
	_depois_de(&"lareira")


## Acabou a preparação e começou a noite (NoiteTelhado): nada mais vale aqui (os
## lampiões que se apagam são da noite).
func encerrar() -> void:
	_ativa = false
	set_process(false)
	_ligar_areas()


func _depois_de(o_que: StringName) -> void:
	if not _ativa:
		return
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
		rifle.peso_mao = 1.0
		rifle.a_mao_ja()
	_onde_carrega = Vector3.INF
	if acender_lareira and not lareira_acesa:
		acender_lareira._acender()
		if acender_lareira.fogo:
			acender_lareira.fogo.intensidade = 1.0
		_lareira()
	caes_soltos = true
	if porteira:
		porteira.rotation_degrees.y = 100.0
	matilha.porteira_aberta = true
	matilha.modo = Matilha.Modo.SOLTOS
	_ativa = true
	_depois_de(&"")


func _tocar(s: AudioStream, db: float) -> void:
	if s:
		AudioDirector.play_sfx(s, db)
