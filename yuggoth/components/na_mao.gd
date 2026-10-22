class_name NaMao
extends Node3D
## Um objeto seguro diante da câmera, sem mãos (docs/PLANO_FAZENDA.md: "sem
## corpo", como a carta no escritório): o balde de ração de Akeley, a lenha, o
## lampião. Segue a câmera com um pouco de atraso e balança com o passo.
##
## Os gestos (playtest 12: "algumas animações estão fracas"): `deslocar` e `girar`
## somam um deslocamento e um giro ao jeito de segurar (inclinar o balde, levar o
## rifle ao ombro); com `peso_mao` < 1 o objeto vai para `no_mundo` (pendurado na
## bica da bomba, pousado no chão, no cabide do armário) e volta num arco; `peso`
## pesa na mão (o balde cheio desce e balança mais).

## Posição e rotação (graus) em relação à câmera.
@export var posicao := Vector3(0.34, -0.5, -0.85)
@export var rotacao := Vector3(38, -12, 0)
## Quanto atrasa ao virar a cabeça (maior = mais preso à câmera).
@export var firmeza := 18.0
## O balanço do passo, em metros.
@export var balanco := 0.012
## A câmera de quem segura (vazio = a câmera atual). A fazenda põe a de Akeley:
## na descida do céu, a atual é outra.
@export var camera: Camera3D
## 0 = abaixado, fora da vista; 1 = diante dos olhos (a descida do céu o ergue
## quando a câmera chega a Akeley).
var erguer := 1.0
## O gesto de agora, por cima do jeito de segurar (no espaço da câmera; graus).
var deslocar := Vector3.ZERO
var girar := Vector3.ZERO
## 1 = na mão; 0 = em `no_mundo`; no meio, a caminho, num arco de `arco` metros.
var peso_mao := 1.0
var no_mundo := Transform3D.IDENTITY
var arco := 0.18
## 0 = leve; 1 = cheio (desce um pouco e balança mais com o passo).
var peso := 0.0

var _camera: Camera3D
var _t := 0.0
var _anda := 0.0
## A luz de preencher (o truque dos objetos em primeira pessoa): longe dos olhos
## (pousado, erguido por cima da tela) ela clareava o chão em volta; esmaece.
var _luz: Light3D
var _luz_energia := 0.0


func _ready() -> void:
	top_level = true
	_camera = camera if camera else get_viewport().get_camera_3d()
	_luz = get_node_or_null(^"Luz") as Light3D
	if _luz:
		_luz_energia = _luz.light_energy
	_seguir(1.0)


func _process(delta: float) -> void:
	if camera:
		_camera = camera
	elif not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	_anda = 0.0
	if is_instance_valid(_camera):
		var corpo := _camera.get_parent()
		while corpo and not corpo is CharacterBody3D:
			corpo = corpo.get_parent()
		if corpo:
			var v := (corpo as CharacterBody3D).velocity
			_anda = clampf(Vector2(v.x, v.z).length() / 1.5, 0.0, 1.0)
	_t += delta * TAU * 1.8 * _anda
	# Fora da mão, sem o atraso (está no mundo, não segue a câmera).
	_seguir(1.0 if peso_mao <= 0.0 else 1.0 - exp(-firmeza * delta))
	if _luz:
		_luz.light_energy = _luz_energia * clampf(peso_mao, 0.0, 1.0) * clampf(1.0 - (deslocar.length() - 0.3) * 2.0, 0.0, 1.0)


## Onde ficaria na mão agora (sem o atraso).
func na_mao() -> Transform3D:
	if not is_instance_valid(_camera):
		return global_transform
	var anda := _anda
	var bal := balanco * (1.0 + 1.6 * peso)
	var passo := Vector3(sin(_t * 0.5) * bal, -absf(cos(_t * 0.5)) * bal, 0.0) * anda
	var baixo := Vector3(0.0, -0.55, 0.2) * (1.0 - erguer) + Vector3(0.0, -0.06, 0.0) * peso
	var base := _pose_mao()
	var giro := base.basis * Basis.from_euler(girar * PI / 180.0)
	# Cheio, o balde gira um pouco com o passo (a alça).
	if peso > 0.0:
		giro = Basis(Vector3.FORWARD, sin(_t * 0.5) * 0.06 * peso * anda) * giro
	return _camera.global_transform * Transform3D(giro, base.origin + deslocar + passo + baixo)


## O jeito de segurar (no espaço da câmera), antes do gesto: `posicao` e `rotacao`.
## O rifle o mistura com a pose de carregar.
func _pose_mao() -> Transform3D:
	return Transform3D(Basis.from_euler(rotacao * PI / 180.0), posicao)


func _seguir(k: float) -> void:
	if not is_instance_valid(_camera):
		return
	var alvo := na_mao()
	if peso_mao < 1.0:
		var u := clampf(peso_mao, 0.0, 1.0)
		var t := no_mundo.interpolate_with(alvo, u)
		t.origin += Vector3.UP * sin(u * PI) * arco
		alvo = t
	global_transform = global_transform.interpolate_with(alvo, k) if k < 1.0 else alvo


## Leva da mão até `onde` (no mundo) em `segundos`, num arco; ou de lá à mão.
func pousar(onde: Transform3D, segundos: float, trans := Tween.TRANS_SINE) -> Tween:
	no_mundo = onde
	var t := create_tween().set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, ^"peso_mao", 0.0, segundos)
	return t


## Já fora da mão: leva de onde está no mundo até `onde`, num arco de `altura`.
func mover(onde: Transform3D, segundos: float, altura := 0.15) -> Tween:
	var ini := no_mundo
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(u: float) -> void:
		var x := ini.interpolate_with(onde, u)
		x.origin += Vector3.UP * sin(u * PI) * altura
		no_mundo = x, 0.0, 1.0, segundos)
	return t


func pegar(segundos: float) -> Tween:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, ^"peso_mao", 1.0, segundos)
	return t


## Um gesto: `deslocar`/`girar` até os valores dados em `segundos`.
func gesto(desl: Vector3, gir: Vector3, segundos: float, trans := Tween.TRANS_SINE, ease := Tween.EASE_IN_OUT) -> Tween:
	var t := create_tween().set_parallel().set_trans(trans).set_ease(ease)
	t.tween_property(self, ^"deslocar", desl, segundos)
	t.tween_property(self, ^"girar", gir, segundos)
	return t
