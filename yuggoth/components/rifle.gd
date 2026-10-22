class_name Rifle
extends NaMao
## O rifle de alavanca de Akeley na mão (docs/PLANO_FAZENDA.md, F6 e F7), sem mãos,
## como o balde. Playtest 12 ("recarregar a arma... fraca"): a alavanca e o cão são
## pivôs (gerar_fazenda._rifle), e o rifle tem a pose de carregar — deitado diante
## do peito, atravessado, o cano para a esquerda e a portinhola do lado direito
## virada para cima, por onde os cartuchos entram — misturada à de levar por
## `carga_peso`.

## A pose de carregar (no espaço da câmera): onde fica a culatra, e quanto o cano
## aponta para a frente (graus) e quanto o rifle rola para mostrar a portinhola.
@export var pos_carga := Vector3(0.05, -0.16, -0.38)
@export var carga_frente := 28.0
@export var carga_rolar := -38.0

## 0 = levado; 1 = na pose de carregar.
var carga_peso := 0.0
var na_carga := false
var _base_carga := Basis.IDENTITY
var _alavanca: Node3D
var _cao: Node3D
var _cao_repouso := 0.0


func _ready() -> void:
	# Atravessado: o cano (o -Z do rifle) para a esquerda da câmera, o lado direito
	# (+X) para cima, o alto (+Y) para a câmera; então rola um pouco e aponta um
	# pouco para a frente.
	var deitado := Basis(Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0))
	_base_carga = Basis(Vector3.UP, deg_to_rad(carga_frente)) * Basis(Vector3.RIGHT, deg_to_rad(carga_rolar)) * deitado
	super()
	_alavanca = find_child("Alavanca", true, false) as Node3D
	_cao = find_child("Cao", true, false) as Node3D
	if _cao:
		_cao_repouso = _cao.rotation.x


func _pose_mao() -> Transform3D:
	var mao := super()
	if carga_peso <= 0.0:
		return mao
	var u := clampf(carga_peso, 0.0, 1.0)
	return Transform3D(mao.basis.slerp(_base_carga, u), mao.origin.lerp(pos_carga, u) + Vector3(0, 0.06, 0.04) * sin(u * PI))


## A pose de carregar (`sim`) ou a de levar.
func carga(sim: bool, segundos := 0.6) -> Tween:
	na_carga = sim
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, ^"carga_peso", 1.0 if sim else 0.0, segundos)
	return t


## A pose de levar, de uma vez (pular, testes).
func a_mao_ja() -> void:
	na_carga = false
	carga_peso = 0.0


## A portinhola de carregar (com um desvio no espaço dela) e a boca do cano, no mundo.
func portinhola(desvio := Vector3.ZERO) -> Vector3:
	var p := find_child("Portinhola", true, false) as Node3D
	return (p.global_transform * desvio) if p else global_position


func boca() -> Vector3:
	var b := find_child("Boca", true, false) as Node3D
	return b.global_position if b else global_position


## A alavanca: abre (o estojo sai, o cão vai para trás) e fecha (o cartucho entra,
## o cão fica engatilhado), com o tranco do rifle. `meia`: só entreabre (conferir).
func ciclar(som: AudioStream, meia := false) -> void:
	if som:
		var s := AudioDirector.play_sfx(som, -2.0 if not meia else -9.0)
		if s and meia:
			s.pitch_scale *= 1.1
	var abre := deg_to_rad(28.0 if meia else 62.0)
	var d0 := deslocar
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _alavanca:
		t.tween_property(_alavanca, ^"rotation:x", abre, 0.13 if not meia else 0.25)
	if _cao:
		t.tween_property(_cao, ^"rotation:x", _cao_repouso + deg_to_rad(28.0), 0.13)
	t.tween_property(self, ^"deslocar", d0 + Vector3(0, -0.012, 0.01), 0.13)
	await t.finished
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.06 if not meia else 0.3, false).timeout
	var f := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _alavanca:
		f.tween_property(_alavanca, ^"rotation:x", 0.0, 0.16 if not meia else 0.25)
	if _cao:
		f.tween_property(_cao, ^"rotation:x", _cao_repouso + deg_to_rad(18.0), 0.16)
	f.tween_property(self, ^"deslocar", d0, 0.16)
	await f.finished
