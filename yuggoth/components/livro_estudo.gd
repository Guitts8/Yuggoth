class_name LivroEstudo
extends Node3D
## O livro da biblioteca que Wilmarth lê enquanto o tempo passa (playtest 9: "e se
## a passagem de tempo tivesse algo a ver com os livros lidos? para justificar?").
## Nos lapsos, ele senta à escrivaninha e o livro abre diante dele; pela janela os
## dias passam. À noite (as luzes da sala quase apagadas) o livro fecha — ele foi
## para casa; de dia abre de novo e as folhas viram. Na noite em claro (Vigilia) o
## livro fica aberto a noite toda, com a lâmpada acesa: não dormiu.
##
## Playtest 11: (1) as folhas são impressas (uma textura de página com o texto em
## linhas, `_pagina_impressa`), e a folha que vira leva texto nas duas faces e verga
## como papel (`Diario._curvar`) — antes era uma folha em branco que tapava as
## linhas e parecia escrever a página na frente dele; (2) de um dia para o outro o
## livro troca: fechado à noite, no escuro, ele o devolve e de manhã abre outro
## volume (`VOLUMES`, a cor da capa, a largura, a grossura).
##
## A lombada é o eixo Z local; a metade da direita (`_direita`) gira sobre ela para
## fechar sobre a da esquerda. Peças feitas aqui, com os materiais do gerador.

@export var mat_capa: Material
## As capas que se revezam (o primeiro volume usa `mat_capa`).
@export var mats_capa: Array[Material] = []
@export var mat_papel: Material
## (Antes, as linhas do texto eram caixas pretas; ficou para compatibilidade.)
@export var mat_tinta: Material

const COMPRIDO := 0.215
const CAPA := 0.006
const ABRIR := 0.7
const VIRAR := 0.6
## Os volumes, um por dia: [largura, grossura do miolo de cada lado, giro da cor].
const VOLUMES := [[0.15, 0.016, 0.0], [0.138, 0.011, 0.08], [0.158, 0.02, -0.06], [0.142, 0.013, 0.14]]

var aberto := false
## Qual dos VOLUMES está na mesa.
var volume := 0
var _direita: Node3D
var _pecas: Array[Node] = []
var _tween: Tween
var _virando: Tween
var _folha: MeshInstance3D
var _folha_malha := ArrayMesh.new()
var _folha_mats: Array[Material] = []
var _devolver := false
var _largo := 0.15
var _miolo := 0.016

static var _paginas: Array[Material] = []


func _ready() -> void:
	visible = false
	_direita = Node3D.new()
	_direita.name = "_Direita"
	add_child(_direita)
	_folha = MeshInstance3D.new()
	_folha.name = "_Folha"
	_folha.mesh = _folha_malha
	_folha.visible = false
	add_child(_folha)
	_montar()
	_direita.rotation.z = PI


## As duas metades do volume atual: a capa, o miolo (o corte) e a página impressa
## por cima; a dobra na altura do alto do miolo (fechado, a metade da direita deita
## por cima da da esquerda).
func _montar() -> void:
	for p in _pecas:
		p.queue_free()
	_pecas.clear()
	var v: Array = VOLUMES[volume % VOLUMES.size()]
	_largo = v[0]
	_miolo = v[1]
	var capa := _capa(volume)
	var paginas := _materiais_de_pagina()
	var dobra := CAPA + _miolo
	_direita.position.y = dobra
	for lado: float in [-1.0, 1.0]:
		var pai: Node3D = self if lado < 0 else _direita
		var base := 0.0 if lado < 0 else dobra
		_pecas.append(_caixa(pai, Vector3(_largo + 0.01, CAPA, COMPRIDO + 0.01), Vector3(lado * (_largo + 0.01) / 2.0, CAPA / 2.0 - base, 0), capa))
		_pecas.append(_caixa(pai, Vector3(_largo, _miolo, COMPRIDO - 0.004), Vector3(lado * _largo / 2.0, CAPA + _miolo / 2.0 - base, 0), mat_papel))
		var pagina := MeshInstance3D.new()
		var plano := PlaneMesh.new()
		plano.size = Vector2(_largo - 0.004, COMPRIDO - 0.008)
		plano.subdivide_width = 2
		plano.subdivide_depth = 3
		pagina.mesh = plano
		pagina.material_override = paginas[0 if lado < 0 else 1]
		pagina.position = Vector3(lado * _largo / 2.0, dobra + 0.0004 - base, 0)
		pai.add_child(pagina)
		_pecas.append(pagina)
	_folha.position.y = dobra + 0.0008
	_folha_mats = [paginas[1], paginas[0]]


## A capa do volume `n`: as do gerador, em rodízio, com a cor girada de leve.
func _capa(n: int) -> Material:
	var todas: Array[Material] = [mat_capa]
	todas.append_array(mats_capa)
	var base: Material = todas[n % todas.size()]
	var giro: float = VOLUMES[n % VOLUMES.size()][2]
	if base == null or giro == 0.0 or not (base is ShaderMaterial):
		return base
	var m := (base as ShaderMaterial).duplicate() as ShaderMaterial
	var c: Color = m.get_shader_parameter(&"albedo_color") if m.get_shader_parameter(&"albedo_color") != null else Color.WHITE
	c.h = fposmod(c.h + giro, 1.0)
	m.set_shader_parameter(&"albedo_color", c)
	return m


func _caixa(pai: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)
	return mi


## Aparece fechado em `onde` (global) e abre.
func aparecer(onde: Transform3D) -> void:
	global_transform = onde
	_direita.rotation.z = PI
	aberto = false
	visible = true
	abrir()


func abrir() -> void:
	if aberto:
		return
	aberto = true
	# Fechado à noite (a sala às escuras): de manhã é outro volume. No lapso a
	# noite dura menos que a capa leva para fechar; troca-se aqui, ainda no escuro.
	if _devolver:
		_devolver = false
		volume += 1
		_montar()
		_direita.rotation.z = PI
	_girar(0.0, ABRIR)


## Fecha; com `devolver` (a noite: ele foi para casa e levou o livro de volta), a
## próxima abertura é de outro volume.
func fechar(devolver := false) -> void:
	if devolver:
		_devolver = true
	if not aberto:
		return
	aberto = false
	_parar_folha()
	_girar(PI, ABRIR)


## Uma folha vira, da direita para a esquerda, vergando; impressa dos dois lados.
func virar() -> void:
	if not aberto or (_virando and _virando.is_running()):
		return
	_folha.visible = true
	_virando = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_virando.tween_method(_curvar_folha, 0.0, 1.0, VIRAR)
	_virando.tween_callback(func() -> void: _folha.visible = false)


func _curvar_folha(t: float) -> void:
	Diario._curvar(_folha_malha, t, 1.0, 1.4, 0.0005, _largo - 0.006, Vector2(0.0, 1.0), Vector2(1.0, 0.0), false)
	Diario._aplicar_mats(_folha_malha, _folha_mats)


func _parar_folha() -> void:
	if _virando:
		_virando.kill()
	_folha.visible = false


## Fecha e some (devolvido à pilha).
func guardar() -> void:
	fechar()
	await get_tree().create_timer(ABRIR + 0.1).timeout
	if is_inside_tree():
		visible = false


## Um trecho do lapso começou (Lapso.trecho): de noite com a sala apagada (a
## lâmpada quase sem luz), o livro fecha — foi para casa, e o devolve; de dia (a
## luz é a da janela), ou de noite com a lâmpada acesa, abre, ou vira uma folha.
func reagir(hora: String, luz: float) -> void:
	var noite := (hora == "noite" and luz < 0.5) or (hora == "chuva" and luz < 0.15)
	if noite:
		fechar(true)
	elif not aberto:
		abrir()
	else:
		virar()


func _girar(para: float, segundos: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_direita, ^"rotation:z", para, segundos)


## As duas páginas impressas (a da esquerda e a da direita), uma vez só.
static func _materiais_de_pagina() -> Array[Material]:
	if _paginas.is_empty():
		for semente in [3, 8]:
			var mat := Selagem._material("res://art/materials/papel.tres")
			mat.set_shader_parameter(&"albedo_tex", _pagina_impressa(semente))
			mat.set_shader_parameter(&"albedo_color", Color.WHITE)
			_paginas.append(mat)
	return _paginas


## Uma página de livro impressa, vista de perto à mesa: o título corrido no alto,
## o bloco de texto em linhas de palavras (parágrafos com recuo, a última linha
## mais curta) e o número da página.
static func _pagina_impressa(semente: int) -> Texture2D:
	var w := 150
	var h := 216
	var papel := Color(0.87, 0.83, 0.72)
	var tinta := Color(0.24, 0.21, 0.19)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for y in h:
		for x in w:
			var f := 1.0 + rng.randf_range(-0.012, 0.012)
			var borda := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if borda < 4:
				f *= 0.93 + borda * 0.017
			img.set_pixel(x, y, Color(papel.r * f, papel.g * f, papel.b * f))
	var palavra := func(x0: int, y0: int, largura: int, cor: Color, alto: int) -> void:
		for yy in range(y0, y0 + alto):
			for xx in range(x0, mini(x0 + largura, w)):
				img.set_pixel(xx, yy, img.get_pixel(xx, yy).lerp(cor, 0.8 if yy == y0 + alto - 1 else 0.55))
	# O título corrido, em versaletes (palavras curtas e espaçadas), no meio.
	var x := w / 2 - 26
	for k in 4:
		var l := rng.randi_range(6, 12)
		palavra.call(x, 10, l, tinta, 2)
		x += l + 4
	# O texto.
	var esq := 13
	var dir := w - 13
	var y := 24
	var recuo := true
	while y < h - 22:
		x = esq + (8 if recuo else 0)
		var fim := dir if rng.randf() > 0.12 else rng.randi_range(esq + 30, dir - 20)
		while x < fim - 4:
			var l := mini(rng.randi_range(3, 14), fim - x)
			palavra.call(x, y, l, tinta, 2)
			x += l + rng.randi_range(2, 3)
		recuo = fim < dir
		y += 7
	# O número da página.
	palavra.call(w / 2 - 4, h - 12, 8, tinta, 2)
	return ImageTexture.create_from_image(img)
