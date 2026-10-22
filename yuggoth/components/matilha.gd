class_name Matilha
extends Node3D
## Os cães de Akeley juntos (docs/PLANO_FAZENDA.md, F4): o que vale para todos — o
## momento da noite (`modo`, que a fazenda muda a cada beat), onde fica o cercado,
## para onde fica a mata, a janela do escritório, o fogo — e os sons. Cada cão é um
## `CaoIA` filho, que decide por si a partir disto.

enum Modo {
	## O entardecer, antes da ração: no cercado; com Akeley perto e o balde na
	## mão, juntam-se na tela do lado dele, olham, latem pedindo.
	ESPERANDO,
	## A ração na gamela (F5): cada um no seu lugar ao longo dela, comendo; Rambo
	## não come (fica com a mata).
	COMENDO,
	## Depois de comer: andam à toa pelo cercado, deitam, sentam (o balde vazio).
	DEPOIS,
	## Soltos no quintal, de guarda (a noite: rodada 2 da tratativa).
	SOLTOS,
	## A noite do telhado (F7): algo pousou lá em cima; os de fora correm em volta
	## da casa latindo para o telhado; dentro, Brutus arranha a porta e Conan
	## rosna para o forro.
	TELHADO,
	## Os latidos viram para a frente da casa (F7, antes das balas): os de fora
	## correm pelo quintal da frente, latindo para a mata do outro lado.
	FRENTE,
	## "Isso pareceu encerrar a coisa" (F7): os latidos param um a um.
	CALADOS,
}

## Onde Conan deita diante do fogo aceso (INF = o fogo apagado). A Preparacao o põe.
var fogo := Vector3.INF
## Por onde Conan entra no escritório (a casa não tem navegação: ele aparece ali,
## fora da vista, e anda até o fogo).
@export var porta_do_fogo := Vector3.INF
## Por onde Conan passa da porta ao fogo, contornando a mesa grande (INF: direto).
@export var passagem_do_fogo := Vector3.INF
## O lado de cá da porta do escritório (o vestíbulo), e o escritório (o cômodo do
## fogo): de dentro de casa, Conan passa pela porta (playtest 12).
@export var porta_do_fogo_fora := Vector3.INF
@export var comodo_do_fogo := AABB()
## A casa (a planta, com o puxado), para correrem em volta dela na noite do
## telhado.
@export var casa := AABB(Vector3(-9.0, 0, -6.0), Vector3(15.0, 1, 12.0))
## O quintal da frente (de onde vêm as balas) e para onde latem lá.
@export var frente := AABB(Vector3(7.5, 0, -6.0), Vector3(12.0, 1, 18.0))
@export var frente_alvo := Vector3(40.0, 1.0, 14.0)
## Onde Rambo fica, de fora, rosnando para a janela do escritório (à noite).
@export var diante_da_janela := Vector3(4.6, 0, 7.6)

## Os lugares ao longo da gamela (do mundo), um por cão, na ordem dos filhos.
@export var gamela: PackedVector3Array = []
## Para onde se olha comendo (a gamela fica deste lado).
@export var gamela_frente := Vector3(0, 0, 1)

@export var modo := Modo.ESPERANDO
## O chão do cercado (onde andam esperando), em coordenadas do mundo.
@export var cercado := AABB(Vector3(-7.6, 0, -9.9), Vector3(10.0, 1, 2.4))
## A porteira do cercado: um ponto logo dentro e um logo fora do vão. Aberta
## (`porteira_aberta`, a Preparacao abre), quem cruza a cerca passa por ela
## (playtest 12: soltos, eles saíam em linha reta e empacavam na tela).
@export var porteira_dentro := Vector3.INF
@export var porteira_fora := Vector3.INF
## Além da ponta da porteira aberta, dentro do cercado: aberta para dentro, ela é
## uma parede, e quem estava do lado da dobradiça empacava nela (playtest 12,
## depois). Quem sai passa por aqui antes do vão; quem entra, depois.
@export var porteira_volta := Vector3.INF
var porteira_aberta := false
## Até onde a ração já caiu na gamela (x do mundo; ela enche de leste para oeste):
## a Rotina o move enquanto despeja. -INF: a gamela inteira.
var racao_ate := -INF
## Todos calados de uma vez (a noite do telhado: o instante antes de um tiro, o
## zumbido). Só o ganido passa.
var mudos := false:
	set(v):
		mudos = v
		if v:
			for c in caes():
				c.calar_ja()
## O quintal, onde andam soltos à noite.
@export var quintal := AABB(Vector3(-14, 0, -16), Vector3(36, 1, 30))
## Para onde fica a mata (o pântano e a Dark Mountain, a oeste).
@export var mata := Vector3(-40.0, 1.0, -6.0)
## A janela do escritório de Akeley, para onde Rambo rosna à noite.
@export var janela := Vector3(4.6, 1.4, 6.0)

@export_group("Sons")
@export var latidos: Array[AudioStream] = []
@export var rosnado: AudioStream
@export var arreganho: AudioStream
@export var choramingo: AudioStream
@export var ganido: AudioStream
## A matilha latindo ao longe (laço), para quando muitos latem juntos.
@export var latidos_longe: AudioStream


func caes() -> Array[CaoIA]:
	var lista: Array[CaoIA] = []
	for c in get_children():
		if c is CaoIA:
			lista.append(c)
	return lista


func cao(nome: String) -> CaoIA:
	return get_node_or_null(NodePath(nome)) as CaoIA


## Onde um cão espera, um passo atrás, em vez de comer no `lugar` da gamela: a
## ração ainda não chegou ali (`racao_ate`), ou Akeley está ali, dentro do cercado,
## despejando (playtest 12, depois). INF: pode comer.
func esperar_na_gamela(lugar: Vector3) -> Vector3:
	var a := akeley()
	var dentro := a != null and no_cercado(a.global_position)
	var perto := dentro and Vector2(a.global_position.x - lugar.x, a.global_position.z - lugar.z).length() < 1.3
	if lugar.x >= racao_ate and not perto:
		return Vector3.INF
	var p := lugar - gamela_frente * 1.15
	if dentro and absf(a.global_position.z - p.z) < 0.9 and absf(a.global_position.x - p.x) < 1.0:
		p.x = a.global_position.x + (1.0 if p.x >= a.global_position.x else -1.0)
	return p


## O lugar na gamela de `c` (os que comem, na ordem), ou INF.
func lugar_na_gamela(c: CaoIA) -> Vector3:
	var i := 0
	for o in caes():
		if o.papel == CaoIA.Papel.JANELA or o.fugiu:
			continue
		if o == c:
			return gamela[i] if i < gamela.size() else Vector3.INF
		i += 1
	return Vector3.INF


## Akeley (o jogador) e se ele traz o balde.
func akeley() -> Player:
	if not is_instance_valid(_akeley):
		_akeley = get_tree().get_first_node_in_group(&"player") as Player
	return _akeley


## O balde de ração na mão de Akeley (a fazenda o põe aqui).
var balde: Node3D
var _akeley: Player
## Segundos desde que o modo virou CALADOS (cada cão se cala na sua vez).
var calados_ha := 0.0


func _process(delta: float) -> void:
	calados_ha = calados_ha + delta if modo == Modo.CALADOS else 0.0


## `p` (do mundo) fica dentro do cercado (a tela em volta).
func no_cercado(p: Vector3) -> bool:
	# Até a tela (a borda do `cercado` fica um pouco para dentro) e as baias do canil.
	return p.x > cercado.position.x - 0.45 and p.x < cercado.end.x + 0.45 \
		and p.z > cercado.position.z - 1.6 and p.z < cercado.end.z + 0.45


func com_balde() -> bool:
	return balde != null and balde.visible
