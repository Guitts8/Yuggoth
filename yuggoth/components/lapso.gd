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

## Um trecho do dia começou: a hora da cidade e a luz da sala (fração da de antes).
## O livro que ele lê fecha quando a sala apaga (LivroEstudo.reagir).
signal trecho(hora: String, luz: float)

## Playtest 8 ("sempre a mesma animação, e ela demora"): metade do tempo de
## antes (eram 18 s, 9 s por dia), e cada lapso no seu ESTILO.
const DURACAO_TOTAL := 9.0
const CICLO_MIN := 2.2
const COR_AURORA := Color(1.0, 0.62, 0.55)
const COR_DIA := Color(0.95, 0.95, 1.0)
const COR_TARDE := Color(1.0, 0.55, 0.25)

## O sol que entra pela janela durante o lapso (apagado no resto do tempo); ele
## cruza o céu, e a sombra do caixilho varre a sala.
@export var sol: Light3D
@export var sol_energia := 6.0
## Para onde o sol aponta de manhã e de tarde (no chão da sala, global).
## (Perto da janela: mais longe, o raio passa acima dela e a parede o barra.)
@export var sol_manha := Vector3(-1.6, 0, -1.2)
@export var sol_tarde := Vector3(1.0, 0, -1.4)
## A janela viva (Fase 3e): Arkham com materiais só dela, que o lapso anima de
## hora em hora — o céu, a luz, a névoa, as janelas da cidade acendendo e
## apagando, as nuvens correndo. Toma o lugar da vista do dia enquanto dura.
@export var cidade: Node3D
## As luzes da cidade por hora ("noite", "aurora", "dia", "entardecer", "chuva"),
## no formato de tools/cidade_arkham.gd (HORAS).
@export var horas: Dictionary = {}
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
@export var ciclo := 5.5

## Os jeitos de o tempo passar (Escritorio.estilos_lapso, por cartão):
## "dias" — o ciclo inteiro, de dia em dia (o de sempre, mais curto);
## "chuva" — dias cinzentos: a cidade na chuva o tempo todo, a luz da sala sobe e
##   desce sem sol, a chuva não para (Dia 5);
## "noite" — uma noite só: a cidade apaga janela por janela, um fio de aurora, e a
##   noite seguinte já (a carta que chega "na manhã seguinte").
const ESTILOS := ["dias", "chuva", "noite"]

var passando := false
## Algum lapso correndo agora: as aparições do céu esperam (playtest 8 — um mi-go
## cruzava a cidade em pleno sol, no meio de uma passada de dia).
static var em_curso := false
var _ambiente_base := -1.0
## A manhã de depois de um sonho (amanhecer): as luzes como estavam.
var _manha: Dictionary[Light3D, float] = {}
## As vistas do dia escondidas enquanto a cidade viva está na janela.
var _vistas_escondidas: Array[Node3D] = []
## As nuvens correndo (soma no céu, para não pular).
var _deriva := 0.0


## O Environment é um recurso da cena, compartilhado: saindo no meio, não pode
## ficar escuro para a próxima vez.
func _exit_tree() -> void:
	if passando:
		em_curso = false
	if passando and _ambiente_base >= 0.0:
		ambiente.environment.ambient_light_energy = _ambiente_base
	desfazer_manha()


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
func passar(de: int, ate: int, no_escuro: Callable, estilo := "dias") -> void:
	passando = true
	em_curso = true
	var luzes: Dictionary[Light3D, float] = {}
	for l: Light3D in sala.find_children("*", "Light3D", true, false):
		if l != sol and l.is_visible_in_tree():
			luzes[l] = l.light_energy
	var env := ambiente.environment
	var ambiente_base := env.ambient_light_energy
	_ambiente_base = ambiente_base
	var dias := maxi(1, ate - de)
	var dur := clampf(DURACAO_TOTAL / dias, CICLO_MIN, ciclo)
	# A janela viva: a cidade do lapso no lugar da vista do dia, na mesma hora.
	var hora_do_dia := _cidade_viva(true, estilo == "chuva")
	# [fração do dia, energia do sol, cor do sol, hora da cidade, luz da sala,
	# ambiente, onde o sol está (0 manhã .. 1 tarde)]
	var segmentos := _segmentos(estilo, hora_do_dia)
	if estilo == "noite":
		dur = clampf(DURACAO_TOTAL * 0.6, CICLO_MIN, ciclo)
	var hora_atual := hora_do_dia
	var onde_sol := 0.0
	for k in dias:
		for h in segmentos.size():
			var seg: Array = segmentos[h]
			var segundos: float = dur * seg[0]
			# O último anoitecer volta à hora do dia corrente (a noite de chuva...).
			var para: String = hora_do_dia if k == dias - 1 and h == segmentos.size() - 1 else seg[3]
			if not horas.has(para):
				para = hora_atual
			trecho.emit(para, seg[4])
			var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
			t.tween_property(sol, ^"light_energy", seg[1], segundos)
			t.tween_property(sol, ^"light_color", seg[2], segundos)
			for l in luzes:
				t.tween_property(l, ^"light_energy", luzes[l] * seg[4], segundos)
			t.tween_property(env, ^"ambient_light_energy", ambiente_base * seg[5], segundos)
			t.tween_method(_cidade_entre.bind(hora_atual, para), 0.0, 1.0, segundos)
			t.tween_method(_sol_em, onde_sol, seg[6], segundos)
			# As nuvens correm o dia todo.
			t.tween_method(_nuvens, _deriva, _deriva + segundos * 0.035, segundos).set_trans(Tween.TRANS_LINEAR)
			await t.finished
			if not is_inside_tree():
				return
			hora_atual = para
			onde_sol = 0.0 if h == segmentos.size() - 1 else seg[6]
			if h == 0:
				if k == 0:
					no_escuro.call()
				_arrancar_folha(de + k + 1)
	_cidade_viva(false)
	for l in luzes:
		l.light_energy = luzes[l]
	env.ambient_light_energy = ambiente_base
	passando = false
	em_curso = false


## [fração do lapso, energia do sol, cor do sol, hora da cidade, luz da sala,
## ambiente, onde o sol está (0 manhã .. 1 tarde)] de cada trecho do dia, por estilo.
func _segmentos(estilo: String, hora_do_dia: String) -> Array:
	match estilo:
		"chuva":
			return [
				[0.22, 0.0, COR_DIA, "chuva", 0.08, 0.3, 0.0],
				[0.3, 0.0, COR_DIA, "chuva", 0.35, 1.25, 0.5],
				[0.26, 0.0, COR_DIA, "chuva", 0.2, 0.9, 1.0],
				[0.22, 0.0, COR_DIA, hora_do_dia, 1.0, 1.0, 1.0],
			]
		"noite":
			return [
				[0.4, 0.0, COR_AURORA, "noite", 0.04, 0.2, 0.0],
				[0.25, sol_energia * 0.25, COR_AURORA, "aurora", 0.06, 0.5, 0.1],
				[0.35, 0.0, COR_TARDE, "noite", 1.0, 1.0, 1.0],
			]
	return [
		[0.16, 0.0, COR_AURORA, "noite", 0.06, 0.25, 0.0],
		[0.2, sol_energia * 0.45, COR_AURORA, "aurora", 0.1, 0.8, 0.15],
		[0.24, sol_energia, COR_DIA, "dia", 0.08, 1.6, 0.55],
		[0.24, sol_energia * 0.6, COR_TARDE, "entardecer", 0.1, 1.0, 1.0],
		[0.16, 0.0, COR_TARDE, "noite", 1.0, 1.0, 1.0],
	]


## O dia raiando devagar, de onde a noite estiver (a noite em claro, Vigilia): a
## lâmpada que ardeu a noite toda empalidece, a aurora entra pela janela e a
## cidade clareia. `na_metade` é chamado no meio (a folhinha). Fica como manhã
## até `desfazer_manha()`.
func raiar(segundos: float, na_metade := Callable()) -> void:
	desfazer_manha()
	passando = true
	em_curso = true
	var hora := _cidade_viva(true)
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	for l: Light3D in sala.find_children("*", "Light3D", true, false):
		if l != sol and l.is_visible_in_tree():
			_manha[l] = l.light_energy
			t.tween_property(l, ^"light_energy", l.light_energy * 0.15, segundos)
	sol.light_color = COR_AURORA
	sol.light_energy = 0.0
	_sol_em(0.15)
	t.tween_property(sol, ^"light_energy", sol_energia * 0.5, segundos)
	t.tween_method(_cidade_entre.bind(hora, "aurora"), 0.0, 1.0, segundos)
	t.tween_method(_nuvens, _deriva, _deriva + segundos * 0.02, segundos).set_trans(Tween.TRANS_LINEAR)
	await get_tree().create_timer(segundos * 0.5, false).timeout
	if not is_inside_tree():
		return
	if na_metade.is_valid():
		na_metade.call()
	if t.is_running():
		await t.finished
	passando = false
	em_curso = false


## Põe (ou tira) a cidade viva na janela, escondendo as vistas do dia que estão
## nela; devolve a hora da vista escondida (por onde o lapso começa e termina).
## Com `chuva`, a chuva da janela continua (os dias cinzentos do Dia 5).
func _cidade_viva(sim: bool, chuva := false) -> String:
	if not sim:
		if cidade:
			cidade.visible = false
		for v in _vistas_escondidas:
			if is_instance_valid(v):
				v.visible = true
		_vistas_escondidas.clear()
		return ""
	var hora := "dia"
	for v: Node3D in sala.find_children("Vista", "Node3D", true, false):
		if v.is_visible_in_tree() and not is_ancestor_of(v):
			hora = String(v.get_meta(&"hora", hora))
			v.visible = false
			_vistas_escondidas.append(v)
	# A chuva da noite não atravessa os dias que passam (menos nos dias de chuva).
	for c: Node3D in sala.find_children("Chuva", "GPUParticles3D", true, false):
		if c.is_visible_in_tree() and not chuva:
			c.visible = false
			_vistas_escondidas.append(c)
	if not horas.has(hora):
		hora = "dia"
	if cidade:
		cidade.visible = true
		_cidade_entre(1.0, hora, hora)
	return hora


## A luz da cidade viva entre duas horas (k de 0 a 1).
func _cidade_entre(k: float, de: String, para: String) -> void:
	if cidade == null or not horas.has(de) or not horas.has(para):
		return
	var a: Dictionary = horas[de]
	var b: Dictionary = horas[para]
	for parte in [&"Solido", &"Janelas", &"Ceu"]:
		var mi := cidade.get_node_or_null(NodePath(parte)) as MeshInstance3D
		if mi == null:
			continue
		# Cada material só usa as chaves dele (as outras ficam guardadas, sem efeito).
		var mat := mi.material_override as ShaderMaterial
		for chave: String in a:
			mat.set_shader_parameter(StringName(chave), _misturar(a[chave], b[chave], k))


static func _misturar(a: Variant, b: Variant, k: float) -> Variant:
	if a is float or a is int:
		return lerpf(a, b, k)
	return a.lerp(b, k)


## O sol na posição do dia (0 manhã, 1 tarde): a luz entra torta e a sombra do
## caixilho anda pelo assoalho.
func _sol_em(k: float) -> void:
	var alvo := sol_manha.lerp(sol_tarde, k)
	sol.look_at(alvo)


func _nuvens(v: float) -> void:
	_deriva = v
	if cidade:
		var ceu := cidade.get_node_or_null(^"Ceu") as MeshInstance3D
		if ceu:
			(ceu.material_override as ShaderMaterial).set_shader_parameter(&"deriva", v)


## Manhã cedo, de uma vez (acordar debruçado na mesa depois de um sonho, no
## escuro): a sala quase apagada, a lâmpada que ardeu a noite toda fraca, e a
## aurora entrando pela janela. `desfazer_manha()` devolve a sala como estava.
func amanhecer() -> void:
	desfazer_manha()
	for l: Light3D in sala.find_children("*", "Light3D", true, false):
		if l != sol and l.is_visible_in_tree():
			_manha[l] = l.light_energy
			l.light_energy *= 0.12
	sol.light_color = COR_AURORA
	sol.light_energy = sol_energia * 0.5
	_sol_em(0.15)
	_cidade_viva(true)
	_cidade_entre(1.0, "aurora", "aurora")


func desfazer_manha() -> void:
	if _manha.is_empty():
		return
	for l in _manha:
		if is_instance_valid(l):
			l.light_energy = _manha[l]
	_manha.clear()
	sol.light_energy = 0.0
	_cidade_viva(false)


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
