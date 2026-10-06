class_name Lapso
extends Node3D
## O tempo passando na própria sala (docs/PLANO_ESCRITORIO.md, Fase 3b), no
## lugar do corte em tela preta: para cada dia que passa, a sala escurece (a
## noite), uma folha da folhinha cai, e o dia nasce, entardece e anoitece pela
## janela. O cartão aparece sobre a cena, no primeiro escuro — é ali que o
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

const DURACAO_TOTAL := 15.0
const CICLO_MIN := 3.5
const COR_AURORA := Color(1.0, 0.62, 0.55)
const COR_DIA := Color(0.95, 0.95, 1.0)
const COR_TARDE := Color(1.0, 0.55, 0.25)

## O sol da manhã que entra pela janela durante o lapso (apagado no resto do tempo).
@export var sol: Light3D
@export var sol_energia := 6.0
## As paisagens postas na frente da do dia corrente: o dia claro, e a aurora e o
## fim de tarde (o céu alaranjado).
@export var vista_dia: Node3D
@export var vista_tarde: Node3D
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
## Segundos de um dia que passa sozinho; vários dias dividem DURACAO_TOTAL, sem
## ficar mais curtos que CICLO_MIN cada.
@export var ciclo := 7.0

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
## Cada dia que passa: a noite (a sala apaga, cai uma folha), a aurora rosada, o
## dia claro, a tarde alaranjada e o anoitecer — o sol entrando pela janela com
## a cor da hora. Vários dias de uma vez passam mais depressa, cada um inteiro.
func passar(de: int, ate: int, no_escuro: Callable) -> void:
	passando = true
	var luzes: Dictionary[Light3D, float] = {}
	for l: Light3D in sala.find_children("*", "Light3D", true, false):
		if l != sol and l.is_visible_in_tree():
			luzes[l] = l.light_energy
	var env := ambiente.environment
	var ambiente_base := env.ambient_light_energy
	_ambiente_base = ambiente_base
	var dias := maxi(1, ate - de)
	var dur := clampf(DURACAO_TOTAL / dias, CICLO_MIN, ciclo)
	# [fração do dia, energia do sol, cor do sol, vista, luz da sala, ambiente]
	var horas := [
		[0.16, 0.0, COR_AURORA, null, 0.06, 0.25],
		[0.2, sol_energia * 0.45, COR_AURORA, vista_tarde, 0.1, 0.8],
		[0.24, sol_energia, COR_DIA, vista_dia, 0.08, 1.6],
		[0.24, sol_energia * 0.6, COR_TARDE, vista_tarde, 0.1, 1.0],
		[0.16, 0.0, COR_TARDE, null, 1.0, 1.0],
	]
	for k in dias:
		for h in horas.size():
			var hora: Array = horas[h]
			var segundos: float = dur * hora[0]
			if h == 1 or h == 3:
				_vista(hora[3])
			elif h == 2:
				_vista(vista_dia)
			var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
			t.tween_property(sol, ^"light_energy", hora[1], segundos)
			t.tween_property(sol, ^"light_color", hora[2], segundos)
			for l in luzes:
				t.tween_property(l, ^"light_energy", luzes[l] * hora[4], segundos)
			t.tween_property(env, ^"ambient_light_energy", ambiente_base * hora[5], segundos)
			await t.finished
			if not is_inside_tree():
				return
			if h == 0:
				if k == 0:
					no_escuro.call()
				_arrancar_folha(de + k + 1)
			elif h == 4:
				_vista(null)
	for l in luzes:
		l.light_energy = luzes[l]
	env.ambient_light_energy = ambiente_base
	passando = false


## Uma das paisagens do lapso na frente da do dia corrente (null: nenhuma).
func _vista(qual: Node3D) -> void:
	vista_dia.visible = qual == vista_dia
	if vista_tarde:
		vista_tarde.visible = qual == vista_tarde

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
