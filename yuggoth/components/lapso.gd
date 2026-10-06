class_name Lapso
extends Node3D
## O tempo passando na própria sala (docs/PLANO_ESCRITORIO.md, Fase 3b), no
## lugar do corte em tela preta: para cada dia que passa, a sala escurece (a
## noite), uma folha da folhinha cai, e a luz fria da manhã entra pela janela e
## vai embora. O cartão aparece sobre a cena, no primeiro escuro — é ali que o
## que chega (a carta nova, pela fresta) aparece. A fase o chama de
## SceneDirector.time_skip (ver Escritorio.passar_tempo).
##
## A folhinha mostra `data` (dia do ano de 1928) o tempo todo, em inglês, como
## tudo o que é impresso na sala.

const MESES := ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
	"AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
## 1º de janeiro de 1928 foi um domingo.
const SEMANA := ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
## 1928 é bissexto.
const DIAS_NO_MES := [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

## O sol da manhã que entra pela janela durante o lapso (apagado no resto do tempo).
@export var sol: Light3D
@export var sol_energia := 6.0
## A paisagem de dia, posta na frente da do dia corrente enquanto o sol está alto.
@export var vista_dia: Node3D
@export var ambiente: WorldEnvironment
## As luzes que escurecem à noite: todas as Light3D visíveis sob este nó.
@export var sala: Node3D
@export_group("Folhinha")
## A folha de cima; os textos são filhos dela (a que cai leva a data velha).
@export var folha: Node3D
@export var texto_mes: Label3D
@export var texto_dia: Label3D
@export var texto_semana: Label3D
@export var som_folha: AudioStream
@export_group("")
## Segundos por dia que passa.
@export var ciclo := 1.4

var passando := false
var _ambiente_base := -1.0


## O Environment é um recurso da cena, compartilhado: saindo no meio, não pode
## ficar escuro para a próxima vez.
func _exit_tree() -> void:
	if passando and _ambiente_base >= 0.0:
		ambiente.environment.ambient_light_energy = _ambiente_base


## Dia do ano (1 = 1º de janeiro) de uma data de 1928.
static func dia_do_ano(mes: int, dia: int) -> int:
	var n := dia
	for m in mes - 1:
		n += DIAS_NO_MES[m]
	return n


func mostrar(data: int) -> void:
	var mes := 0
	var dia := data
	while mes < 11 and dia > DIAS_NO_MES[mes]:
		dia -= DIAS_NO_MES[mes]
		mes += 1
	texto_mes.text = MESES[mes]
	texto_dia.text = str(dia)
	texto_semana.text = SEMANA[(data - 1) % 7]


## Passa de `de` a `ate` (dias do ano). `no_escuro` é chamado no primeiro escuro.
func passar(de: int, ate: int, no_escuro: Callable) -> void:
	passando = true
	var luzes: Dictionary[Light3D, float] = {}
	for l: Light3D in sala.find_children("*", "Light3D", true, false):
		if l != sol and l.is_visible_in_tree():
			luzes[l] = l.light_energy
	var env := ambiente.environment
	var ambiente_base := env.ambient_light_energy
	_ambiente_base = ambiente_base
	for k in maxi(1, ate - de):
		# A noite: a sala quase apaga.
		var t := create_tween().set_parallel()
		for l in luzes:
			t.tween_property(l, ^"light_energy", luzes[l] * 0.08, ciclo * 0.3)
		t.tween_property(env, ^"ambient_light_energy", ambiente_base * 0.3, ciclo * 0.3)
		await t.finished
		if not is_inside_tree():
			return
		if k == 0:
			no_escuro.call()
		_arrancar_folha(de + k + 1)
		# A manhã: o sol frio entra pela janela e vai embora.
		vista_dia.visible = true
		t = create_tween().set_parallel()
		t.tween_property(sol, ^"light_energy", sol_energia, ciclo * 0.35).set_trans(Tween.TRANS_SINE)
		for l in luzes:
			t.tween_property(l, ^"light_energy", luzes[l], ciclo * 0.35)
		t.tween_property(env, ^"ambient_light_energy", ambiente_base * 1.5, ciclo * 0.35)
		await t.finished
		if not is_inside_tree():
			return
		t = create_tween().set_parallel()
		t.tween_property(sol, ^"light_energy", 0.0, ciclo * 0.35).set_trans(Tween.TRANS_SINE)
		t.tween_property(env, ^"ambient_light_energy", ambiente_base, ciclo * 0.35)
		await t.finished
		if not is_inside_tree():
			return
		vista_dia.visible = false
	for l in luzes:
		l.light_energy = luzes[l]
	env.ambient_light_energy = ambiente_base
	passando = false


## A folha de cima se solta e cai para a frente; a de baixo já mostra `data`.
func _arrancar_folha(data: int) -> void:
	var solta := folha.duplicate() as Node3D
	folha.get_parent().add_child(solta)
	solta.transform = folha.transform
	mostrar(data)
	AudioDirector.play_sfx(som_folha, -8.0)
	var t := create_tween().set_parallel()
	t.tween_property(solta, ^"position", solta.position + Vector3(0.0, 0.12, 0.12), ciclo * 0.4).set_ease(Tween.EASE_OUT)
	t.tween_property(solta, ^"rotation:x", solta.rotation.x + 1.4, ciclo * 0.4)
	t.tween_property(solta, ^"scale", Vector3.ONE * 0.01, ciclo * 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(solta.queue_free)
