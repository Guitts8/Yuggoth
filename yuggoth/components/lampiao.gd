class_name Lampiao
extends Interactable
## Um lampião de querosene da casa de Akeley (docs/PLANO_FAZENDA.md, F6): não há
## luz elétrica (a carta de terça: *"mandaria pôr luz elétrica na casa, e um
## holofote, se não soubesse que eles cortariam os cabos"*). "Acender o lampião":
## ele ergue a chaminé de vidro, risca o fósforo e o leva ao pavio, a chama pega
## pequena, a chaminé desce e ele gira a rodinha até a chama crescer e a luz encher
## o cômodo (playtest 12: era só o som e a luz). Com `apagavel`, "Apagar o lampião"
## (a noite do telhado, F7): a rodinha baixa o pavio, ele sopra, e sobe um fio de
## fumaça. A área é o próprio lampião; o vidro, a chama e a luz vêm do gerador.

signal mudou(aceso: bool)

@export var aceso := false
## Pode-se apagar (F7: "Apaguei a luz").
@export var apagavel := false
@export var luz: OmniLight3D
@export var chama: Node3D
@export var vidro: MeshInstance3D
@export var vidro_aceso: Material
@export var vidro_apagado: Material
@export var energia := 1.4
@export var som_fosforo: AudioStream
@export var som_vidro: AudioStream
## A chama do fósforo (a mesma das lareiras).
@export var textura_chama: Texture2D

var _t := 0.0
var _k := 0.0
var _rodinha: Node3D
var _fumaca: CPUParticles3D


func _ready() -> void:
	super()
	_rodinha = get_node_or_null(^"Rodinha") as Node3D
	_k = 1.0 if aceso else 0.0
	_mostrar()


func can_interact(by: Node) -> bool:
	return super(by) and (not aceso or apagavel)


func _process(delta: float) -> void:
	_t += delta
	if luz and luz.visible:
		var tremor := 0.06 * sin(_t * 9.0) + 0.04 * sin(_t * 23.0 + 1.3)
		luz.light_energy = energia * _k * (1.0 + tremor)
	if chama and chama.visible:
		chama.scale = Vector3.ONE * maxf(_k, 0.05) * (1.0 + 0.08 * sin(_t * 17.0))
	prompt = "Apagar o lampião" if aceso else "Acender o lampião"


func _on_interact(by: Node) -> void:
	var p := by as Player
	if aceso:
		apagar(p)
	else:
		acender(p)


func acender(p: Player = null) -> void:
	if aceso:
		return
	aceso = true
	enabled = false
	# Sem quem acenda (o resto da casa de uma vez, nos testes), só a chama.
	if p == null or not is_inside_tree():
		_k = 0.05
		_mostrar()
		var r := create_tween().set_trans(Tween.TRANS_SINE)
		r.tween_property(self, ^"_k", 1.0, 1.4)
		await r.finished
		enabled = true
		mudou.emit(true)
		return
	p.input_enabled = false
	var pavio := global_position + Vector3(0, -0.03, 0)
	await p.olhar_para(global_position + Vector3.UP * 0.06, 0.5).finished
	# A chaminé sobe (o vidro tine) e fica erguida, um pouco inclinada.
	var v0 := vidro.position if vidro else Vector3.ZERO
	if vidro:
		if som_vidro:
			AudioDirector.play_sfx(som_vidro, -12.0)
		var sobe := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		sobe.tween_property(vidro, ^"position", v0 + Vector3(0, 0.11, 0), 0.35)
		sobe.tween_property(vidro, ^"rotation:z", deg_to_rad(5.0), 0.35)
		await sobe.finished
	# O fósforo: riscado, levado ao pavio.
	var f := Fosforo.novo(get_parent(), p.camera, textura_chama) if textura_chama else null
	if f:
		await _esperar(0.25)
		await f.riscar(som_fosforo)
		await _esperar(0.45)
		await f.levar(pavio + Vector3(0.012, 0.0, 0.0), 0.55)
	elif som_fosforo:
		AudioDirector.play_sfx(som_fosforo, -4.0)
	await _esperar(0.3)
	if not is_inside_tree():
		return
	# Pega pequena, azulada no começo.
	_k = 0.05
	_mostrar()
	var pega := create_tween().set_trans(Tween.TRANS_SINE)
	pega.tween_property(self, ^"_k", 0.3, 0.6)
	if f:
		await f.trazer(0.4)
		f.apagar_e_sumir()
	await pega.finished
	# A chaminé desce no lugar.
	if vidro:
		var desce := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		desce.tween_property(vidro, ^"position", v0, 0.3)
		desce.tween_property(vidro, ^"rotation:z", 0.0, 0.3)
		await desce.finished
		if som_vidro:
			AudioDirector.play_sfx(som_vidro, -9.0)
	# A rodinha sobe o pavio: a chama cresce e a luz toma o cômodo.
	var cresce := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	cresce.tween_property(self, ^"_k", 1.0, 1.1)
	if _rodinha:
		cresce.tween_property(_rodinha, ^"rotation:x", _rodinha.rotation.x + 3.2, 0.9)
	await cresce.finished
	enabled = true
	if is_instance_valid(p):
		p.input_enabled = true
	mudou.emit(true)


func apagar(p: Player = null) -> void:
	if not aceso:
		return
	aceso = false
	enabled = false
	if p == null or not is_inside_tree():
		var r := create_tween()
		r.tween_property(self, ^"_k", 0.0, 0.5)
		await r.finished
		_mostrar()
		enabled = true
		mudou.emit(false)
		return
	p.input_enabled = false
	await p.olhar_para(global_position + Vector3.UP * 0.06, 0.35).finished
	# A rodinha baixa o pavio: a chama encolhe, a sala escurece.
	var baixa := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	baixa.tween_property(self, ^"_k", 0.22, 0.55)
	if _rodinha:
		baixa.tween_property(_rodinha, ^"rotation:x", _rodinha.rotation.x - 2.4, 0.55)
	await baixa.finished
	# Ele se inclina e sopra por cima da chaminé: a chama treme e morre.
	var inclina := create_tween().set_trans(Tween.TRANS_SINE)
	inclina.tween_property(p, ^"inclinar", 0.14, 0.25)
	await inclina.finished
	var sopro := create_tween()
	sopro.tween_property(self, ^"_k", 0.35, 0.06)
	sopro.tween_property(self, ^"_k", 0.08, 0.1)
	sopro.tween_property(self, ^"_k", 0.0, 0.12)
	await sopro.finished
	_mostrar()
	_fumacinha()
	var volta := create_tween().set_trans(Tween.TRANS_SINE)
	volta.tween_property(p, ^"inclinar", 0.0, 0.4)
	await volta.finished
	enabled = true
	if is_instance_valid(p):
		p.input_enabled = true
	mudou.emit(false)


## O fio de fumaça do pavio que acabou de apagar, subindo pela chaminé.
func _fumacinha() -> void:
	if _fumaca == null:
		_fumaca = CPUParticles3D.new()
		_fumaca.name = "_Fumaca"
		_fumaca.emitting = false
		_fumaca.one_shot = true
		_fumaca.amount = 24
		_fumaca.lifetime = 2.2
		_fumaca.explosiveness = 0.1
		_fumaca.direction = Vector3.UP
		_fumaca.spread = 6.0
		_fumaca.initial_velocity_min = 0.08
		_fumaca.initial_velocity_max = 0.16
		_fumaca.gravity = Vector3(0, 0.04, 0)
		_fumaca.scale_amount_min = 0.6
		_fumaca.scale_amount_max = 1.8
		var q := QuadMesh.new()
		q.size = Vector2(0.025, 0.025)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.55, 0.55, 0.55, 0.35)
		q.material = m
		_fumaca.mesh = q
		_fumaca.position = Vector3(0, -0.02, 0)
		add_child(_fumaca)
	_fumaca.restart()
	_fumaca.emitting = true


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout


func _mostrar() -> void:
	var ligado := aceso or _k > 0.01
	if luz:
		luz.visible = ligado
		luz.light_energy = energia * _k
	if chama:
		chama.visible = ligado
	if vidro:
		vidro.material_override = vidro_aceso if ligado and vidro_aceso else vidro_apagado
