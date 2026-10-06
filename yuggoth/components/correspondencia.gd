class_name Correspondencia
extends Examinable
## O correio pela fresta da porta (docs/PLANO_ESCRITORIO.md, Fase 3). Fica numa
## área filha do visual (o pai: um Envelope, um pacote) e leva o visual de um
## lugar para outro, conforme o estado `correio_<id>` em GameState:
##
##   0 no chão, junto à porta  → `prompt_pegar`
##   1 na mão, preso à câmera  → "Pôr na mesa", mirando a escrivaninha (MesaCorreio)
##   2 na mesa, em `mesa`      → `prompt_abrir` (som de papel rasgando)
##   3 aberto                  → o conteúdo aparece (ConditionalNode com
##                               `correio_<id> >= 3`); com `retirar`, sai uma peça
##                               por vez (`correio_<id>_tiradas`); depois, é um
##                               Examinable como os outros.
##
## Pegar o correio junta tudo o que está no chão (uma pilha na mão); pôr na mesa
## pousa tudo, cada um no seu lugar. Com a carta selada na mão (CartaSaida), não
## se pega nada. Quando o nó começa a processar (o dia chega, ou a carta cruza o
## correio no escuro de um salto no tempo), toca `som_chegada` no lugar onde ele
## está: o envelope passando pela fresta, o pacote pousado no chão.

enum { NO_CHAO, NA_MAO, NA_MESA, ABERTO }

## A correspondência na mão do jogador (a pilha, na ordem em que foi pega).
static var na_mao: Array[Correspondencia] = []

@export var id: StringName
## Lugar do visual na escrivaninha (no espaço do pai dele).
@export var mesa: Transform3D
@export var prompt_pegar := "Pegar o correio"
@export var prompt_abrir := "Abrir com a espátula"
@export var prompt_examinar := "Examinar o envelope"
## Peças tiradas uma por vez depois de aberto, na ordem (as fotografias). Cada
## uma aparece pela própria condição (`correio_<id>_tiradas >= n`) e desliza do
## envelope para o seu lugar.
@export var retirar: Array[Node3D] = []
@export var prompt_retirar := "Tirar uma fotografia"
## Some ao abrir (o barbante do pacote).
@export var fechado: Node3D
## Um maço amarrado: ao desamarrar, estas cartas ficam soltas na mesa (cada uma
## no seu `mesa`, ainda fechadas), e o maço some (`some_ao_abrir`).
@export var soltar: Array[Correspondencia] = []
@export var some_ao_abrir := false
@export_group("Na mão")
## Posição e rotação (graus) do visual em relação à câmera.
@export var mao_posicao := Vector3(0.17, -0.17, -0.42)
@export var mao_rotacao := Vector3(80, -10, 5)
@export_group("Som")
@export var som_chegada: AudioStream
@export var som_mao: AudioStream
@export var som_abrir: AudioStream

var _chao: Transform3D
var _forma: CollisionShape3D
var _som: AudioStreamPlayer3D
var _camera: Camera3D
var _chegou := false


func _ready() -> void:
	super()
	add_to_group(&"correspondencia")
	_chao = get_visual().transform
	_forma = get_node(^"CollisionShape3D")
	_som = AudioStreamPlayer3D.new()
	_som.name = "Chegada"
	_som.bus = &"SFX"
	_som.unit_size = 2.5
	add_child(_som)
	# A mão não atravessa um load: volta para o chão.
	if estado() == NA_MAO:
		GameState.set_value(chave(), NO_CHAO)
	GameState.value_changed.connect(_on_value_changed)
	_atualizar()


func _exit_tree() -> void:
	na_mao.erase(self)


func _notification(what: int) -> void:
	# O dia acabou (ou a sala trocou de vestido) com isto na mão: fica na mesa.
	if what == NOTIFICATION_DISABLED and self in na_mao:
		na_mao.erase(self)
		GameState.set_value(chave(), NA_MESA)


func chave() -> StringName:
	return StringName("correio_%s" % id)


func estado() -> int:
	return int(GameState.get_value(chave(), NO_CHAO))


func tiradas() -> int:
	return int(GameState.get_value(StringName("%s_tiradas" % chave()), 0))


func can_interact(by: Node) -> bool:
	match estado():
		NO_CHAO:
			return super(by) and na_mao.is_empty() and CartaSaida.atual == null
		NA_MAO:
			return false
	return super(by)


func _on_interact(by: Node) -> void:
	match estado():
		NO_CHAO:
			# Tudo o que caiu pela fresta vem junto, este por cima.
			var camera := get_viewport().get_camera_3d()
			for c: Correspondencia in get_tree().get_nodes_in_group(&"correspondencia"):
				if c != self and c.estado() == NO_CHAO and c.is_visible_in_tree() and c.can_process():
					c._pegar(camera)
			_pegar(camera)
			_tocar(som_mao)
		NA_MESA:
			GameState.set_value(chave(), ABERTO)
			_tocar(som_abrir)
			for carta in soltar:
				GameState.set_value(carta.chave(), NA_MESA)
		ABERTO:
			if tiradas() < retirar.size():
				_retirar()
			else:
				super(by)


func _pegar(camera: Camera3D) -> void:
	_camera = camera
	na_mao.append(self)
	GameState.set_value(chave(), NA_MAO)


## Chamado pela MesaCorreio: da mão para a escrivaninha, cada um no seu lugar.
static func pousar_tudo() -> void:
	var pilha := na_mao.duplicate()
	na_mao.clear()
	for c in pilha:
		GameState.set_value(c.chave(), NA_MESA)
	if not pilha.is_empty():
		pilha[0]._tocar(pilha[0].som_mao)


func _retirar() -> void:
	var n := tiradas()
	GameState.add(StringName("%s_tiradas" % chave()), 1)
	_tocar(som_mao)
	# A condição da peça já a mostrou (value_changed é síncrono): sai do envelope.
	var peca := retirar[n]
	if peca and peca.is_inside_tree():
		var lugar := peca.position
		peca.global_position = get_visual().global_position + Vector3(0, 0.02, 0)
		create_tween().tween_property(peca, ^"position", lugar, 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	if not _chegou:
		_chegou = true
		if estado() == NO_CHAO and som_chegada:
			_som.stream = som_chegada
			_som.play()
	if estado() == NA_MAO and is_instance_valid(_camera):
		# Na pilha, os de baixo um pouco atrás e deslocados (0 = o de cima).
		var i := na_mao.size() - 1 - na_mao.find(self)
		var rot := Basis.from_euler((mao_rotacao + Vector3(0, i * 4.0, -i * 3.0)) * PI / 180.0)
		var pos := mao_posicao + Vector3(-0.018, 0.012, -0.008) * i
		get_visual().global_transform = _camera.global_transform * Transform3D(rot, pos)


func _on_value_changed(key: StringName, _value: Variant) -> void:
	if key == chave() or key == StringName("%s_tiradas" % chave()):
		_atualizar()


func _atualizar() -> void:
	var e := estado()
	var visual := get_visual()
	if e == NO_CHAO:
		visual.transform = _chao
	elif e != NA_MAO:
		visual.transform = mesa
	if "aberto" in visual:
		visual.set(&"aberto", e == ABERTO)
	if fechado:
		fechado.visible = e != ABERTO
	var sumiu := some_ao_abrir and e == ABERTO
	if some_ao_abrir:
		visual.visible = not sumiu
	# Na mão não se mira a si mesma (nem tampa a mira da mesa).
	visible = e != NA_MAO and not sumiu
	_forma.set_deferred(&"disabled", e == NA_MAO or sumiu)
	match e:
		NO_CHAO:
			prompt = prompt_pegar
		NA_MESA:
			prompt = prompt_abrir
		ABERTO:
			prompt = prompt_retirar if tiradas() < retirar.size() else prompt_examinar


func _tocar(stream: AudioStream) -> void:
	if stream:
		AudioDirector.play_sfx(stream, -4.0)
