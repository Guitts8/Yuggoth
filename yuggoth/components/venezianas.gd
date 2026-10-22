class_name Venezianas
extends Interactable
## As venezianas de uma janela da casa de Akeley (docs/PLANO_FAZENDA.md, F6): de
## dentro, ele chega à janela, se debruça para fora, puxa uma folha e depois a
## outra (cada uma bate no batente), e passa a tramela de ferro por cima da junta
## (playtest 12: as duas giravam juntas, sem ele sair do lugar). As folhas são os
## nós `VenezianaA`/`VenezianaB` do gerador (`_janela`), com a meta `aberta` (o
## giro, em graus, contra a parede); a tramela, `Tranca`, filha da folha B. Na
## noite do telhado (F7), `fresta()` as abre um palmo para a janela servir de
## seteira.

signal fechou

@export var folhas: Array[Node3D] = []
@export var som: AudioStream
## O clique da tramela.
@export var som_tranca: AudioStream
## Para fora da janela (do cômodo para o quintal).
@export var fora := Vector3.ZERO
## Quanto abre a fresta (graus).
@export var fresta_graus := 20.0

var fechada := false
var _base: Array[Basis] = []
var _aberta: Array[float] = []
var _tranca: Node3D


func _ready() -> void:
	super()
	prompt = "Fechar as venezianas"
	for f in folhas:
		var a: float = f.get_meta(&"aberta", 170.0)
		_aberta.append(a)
		_base.append(f.basis * Basis(Vector3.UP, deg_to_rad(-a)))
	if folhas.size() > 1:
		_tranca = folhas[1].get_node_or_null(^"Tranca") as Node3D


func can_interact(by: Node) -> bool:
	return super(by) and not fechada


func _on_interact(by: Node) -> void:
	var p := by as Player
	fechada = true
	if p == null or not is_inside_tree():
		await _girar(0.0, 0.9)
		_trancar(true, 0.0)
		fechou.emit()
		return
	p.input_enabled = false
	# Até a janela, de frente para ela.
	var lugar := junto(p)
	if lugar != Vector3.INF and Vector2(lugar.x - p.global_position.x, lugar.z - p.global_position.z).length() > 0.25:
		await p.conduzir([lugar], global_position + fora * 3.0)
		if not is_inside_tree():
			return
	elif lugar != Vector3.INF:
		await p.olhar_para(global_position + fora * 3.0, 0.5).finished
	# Debruçado para fora, de olho em cada folha enquanto a puxa.
	var debruca := create_tween().set_trans(Tween.TRANS_SINE)
	debruca.tween_property(p, ^"inclinar", 0.16, 0.45)
	await debruca.finished
	for i in folhas.size():
		var f := folhas[i]
		# Os olhos no vão da janela, do lado da folha que ele puxa.
		var centro := global_position + fora * 0.45
		var lado := f.global_position - centro
		lado.y = 0.0
		p.olhar_para(centro + fora * 0.6 + lado.normalized() * 0.3, 0.35)
		await _esperar(0.2)
		# Puxada: devagar no começo (a dobradiça dura), rápida no fim, e bate.
		await _girar_uma(i, 0.0, 0.55, Tween.TRANS_QUAD, Tween.EASE_IN)
		if som:
			var s := AudioDirector.play_sfx(som, -4.0 if i == 1 else -7.0)
			if s:
				s.pitch_scale *= 1.0 if i == 1 else 1.12
		# O repique no batente.
		await _girar_uma(i, 5.0 * signf(_aberta[i]), 0.08, Tween.TRANS_SINE, Tween.EASE_OUT)
		await _girar_uma(i, 0.0, 0.12, Tween.TRANS_SINE, Tween.EASE_IN)
	# A tramela por cima da junta.
	if _tranca:
		p.olhar_para(_tranca.global_position, 0.3)
		await _esperar(0.25)
		await _trancar(true, 0.25)
		if som_tranca:
			AudioDirector.play_sfx(som_tranca, -10.0)
	var volta := create_tween().set_trans(Tween.TRANS_SINE)
	volta.tween_property(p, ^"inclinar", 0.0, 0.45)
	await volta.finished
	if is_instance_valid(p):
		p.input_enabled = true
	fechou.emit()


## Onde ele fica para fechar: diante da janela, no meio dela, `recuo` metros para
## dentro da área (playtest 12, depois: "tire os móveis da frente dos locais... não
## contorne o ficar trancado simplesmente fechando as persianas de longe"). O lugar
## diante de cada janela fica livre de móveis no gerador, e o `alcance_test` confere
## que o corpo cabe ali e sai dali andando.
func junto(p: Player, recuo := 0.3) -> Vector3:
	if fora == Vector3.ZERO:
		return Vector3.INF
	var q := global_position - fora * recuo
	q.y = p.global_position.y
	return q


## Fecha de uma vez, sem animar (pular, testes).
func fechar_ja() -> void:
	fechada = true
	for i in folhas.size():
		_pose(i, 0.0)
	_trancar(true, 0.0)


## Entreabre (a seteira da noite do telhado; `graus` < 0 = `fresta_graus`) ou
## volta a fechar; a tramela sai antes e volta depois.
func fresta(abrir: bool, graus := -1.0) -> void:
	if abrir:
		await _trancar(false, 0.15)
		if som:
			AudioDirector.play_sfx(som, -10.0)
	await _girar((fresta_graus if graus < 0.0 else graus) if abrir else 0.0, 0.4)
	if not abrir:
		await _trancar(true, 0.15)


## A tramela: atravessada (`sim`) ou pendurada.
func _trancar(sim: bool, segundos: float) -> void:
	if _tranca == null:
		return
	var alvo := PI / 2.0 if sim else 0.0
	if segundos <= 0.0:
		_tranca.rotation.z = alvo
		return
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_tranca, ^"rotation:z", alvo, segundos)
	await t.finished


func _girar(alvo: float, segundos: float) -> void:
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	for i in folhas.size():
		var de := _angulo(i)
		var ate := alvo * signf(_aberta[i])
		t.tween_method(func(a: float) -> void: _pose_graus(i, a), de, ate, segundos)
	await t.finished


func _girar_uma(i: int, graus: float, segundos: float, trans: Tween.TransitionType, ease: Tween.EaseType) -> void:
	var t := create_tween().set_trans(trans).set_ease(ease)
	t.tween_method(func(a: float) -> void: _pose_graus(i, a), _angulo(i), graus, segundos)
	await t.finished


func _angulo(i: int) -> float:
	var rel := _base[i].inverse() * folhas[i].basis
	return rad_to_deg(rel.get_euler().y)


func _pose(i: int, fracao: float) -> void:
	_pose_graus(i, _aberta[i] * fracao)


func _pose_graus(i: int, graus: float) -> void:
	folhas[i].basis = _base[i] * Basis(Vector3.UP, deg_to_rad(graus))


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout
