class_name Lampiao
extends Interactable
## Um lampião de querosene da casa de Akeley (docs/PLANO_FAZENDA.md, F6): não há
## luz elétrica (a carta de terça: *"mandaria pôr luz elétrica na casa, e um
## holofote, se não soubesse que eles cortariam os cabos"*). "Acender o lampião":
## ele risca o fósforo, ergue a chaminé, a chama pega no pavio e cresce, a luz
## enche o cômodo; com `apagavel`, "Apagar o lampião" (a noite do telhado, F7).
## A área é o próprio lampião; o vidro, a chama e a luz vêm do gerador.

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

var _t := 0.0
var _k := 0.0


func _ready() -> void:
	super()
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
	if p:
		p.input_enabled = false
		await p.olhar_para(global_position + Vector3.UP * 0.15, 0.5).finished
	if som_vidro:
		AudioDirector.play_sfx(som_vidro, -8.0)
	await get_tree().create_timer(0.35, false).timeout
	if som_fosforo:
		AudioDirector.play_sfx(som_fosforo, -4.0)
	await get_tree().create_timer(0.5, false).timeout
	_k = 0.05
	_mostrar()
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(self, ^"_k", 1.0, 1.4)
	await t.finished
	if som_vidro:
		AudioDirector.play_sfx(som_vidro, -10.0)
	enabled = true
	if p and is_instance_valid(p):
		p.input_enabled = true
	mudou.emit(true)


func apagar(p: Player = null) -> void:
	if not aceso:
		return
	aceso = false
	enabled = false
	if p:
		p.input_enabled = false
	var t := create_tween()
	t.tween_property(self, ^"_k", 0.0, 0.5)
	await t.finished
	_mostrar()
	enabled = true
	if p and is_instance_valid(p):
		p.input_enabled = true
	mudou.emit(false)


func _mostrar() -> void:
	var ligado := aceso or _k > 0.01
	if luz:
		luz.visible = ligado
		luz.light_energy = energia * _k
	if chama:
		chama.visible = ligado
	if vidro:
		vidro.material_override = vidro_aceso if ligado and vidro_aceso else vidro_apagado
