class_name MapaInvestigacao
extends Examinable
## O mapa de Vermont na parede oeste, o quadro da investigação (docs/PLANO_ESCRITORIO.md,
## Fase 4). Lida uma carta que cita um lugar novo (a `condicao` dele vale), o mapa
## oferece "Marcar no mapa": um alfinete por lugar, o fio vermelho ligando ao
## anterior e, nos lugares que o mapa impresso não tem, o nome na letra de
## Wilmarth. Não trava nada (nem a porta); sem nada a marcar, examina-se o mapa
## (Examinable). Marcado, fica `mapa_<id>`; ao carregar, o que já foi marcado
## está lá.
##
## O papel é o nó `papel` (virado para +Z local, centrado, do tamanho `tamanho`);
## os lugares vêm do gerador (tools/gerar_escritorio.gd, _mapa), com o `uv` já
## calculado de tools/vermont.gd.

@export var papel: Node3D
@export var tamanho := Vector2(0.8, 1.24)
@export var ids: PackedStringArray = []
## O nome escrito à mão junto ao alfinete ("" = o mapa já o imprime).
@export var nomes: PackedStringArray = []
@export var uvs: PackedVector2Array = []
## Onde começa o nome, em metros a partir do alfinete (x negativo: à esquerda).
@export var rotulos: PackedVector2Array = []
@export var condicoes: Array[Condition] = []
## 1 = no fio vermelho (a trilha de Akeley); 0 = alfinete preto, sem fio (as enchentes).
@export var trilha: PackedByteArray = []
@export var mat_alfinete: Material
@export var mat_alfinete_preto: Material
@export var mat_fio: Material
@export var fonte_mao: Font
@export var som_alfinete: AudioStream

const ALTURA_CABECA := 0.014
const ALTURA_FIO := 0.009

var _marcando := false
var _ultimo := -1


func _ready() -> void:
	super()
	# O papel (o pai) ainda está montando os filhos: os alfinetes vêm no quadro seguinte.
	_repor.call_deferred()


## O que já foi marcado (ao carregar): os alfinetes, os fios e os nomes, sem animar.
func _repor() -> void:
	for i in ids.size():
		if GameState.has_flag(_flag(i)):
			_alfinete(i, false)


func _flag(i: int) -> StringName:
	return StringName("mapa_%s" % ids[i])


func pendentes() -> Array[int]:
	var r: Array[int] = []
	for i in ids.size():
		if not GameState.has_flag(_flag(i)) and condicoes[i] != null and condicoes[i].is_met():
			r.append(i)
	return r


func _process(_delta: float) -> void:
	prompt = "Marcar no mapa" if not pendentes().is_empty() and not _marcando else "Examinar o mapa"


func _on_interact(by: Node) -> void:
	if _marcando:
		return
	var p := pendentes()
	if p.is_empty():
		super(by)
		return
	_marcar(p)


## Os lugares novos, um depois do outro: o alfinete entra, o fio corre do anterior.
func _marcar(lista: Array[int]) -> void:
	_marcando = true
	for i in lista:
		GameState.set_flag(_flag(i))
	for i in lista:
		_alfinete(i, true)
		if som_alfinete:
			AudioDirector.play_sfx(som_alfinete, -10.0)
		await get_tree().create_timer(0.55).timeout
		if not is_inside_tree():
			return
	_marcando = false


func _ponto(i: int) -> Vector3:
	return Vector3((uvs[i].x - 0.5) * tamanho.x, (0.5 - uvs[i].y) * tamanho.y, 0.0)


## O alfinete do lugar `i`, o fio desde o anterior marcado e o nome.
func _alfinete(i: int, animar: bool) -> void:
	var p := _ponto(i)
	var alfinete := Node3D.new()
	alfinete.name = "_Alfinete%d" % i
	alfinete.position = p
	papel.add_child(alfinete)
	var cabeca := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.0065
	esfera.height = 0.013
	esfera.radial_segments = 8
	esfera.rings = 4
	cabeca.mesh = esfera
	var no_fio := i >= trilha.size() or trilha[i] == 1
	cabeca.material_override = mat_alfinete if no_fio or mat_alfinete_preto == null else mat_alfinete_preto
	cabeca.position.z = ALTURA_CABECA
	alfinete.add_child(cabeca)
	var haste := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.0012
	cil.bottom_radius = 0.0012
	cil.height = ALTURA_CABECA
	cil.radial_segments = 4
	haste.mesh = cil
	haste.material_override = mat_alfinete
	haste.rotation_degrees.x = 90.0
	haste.position.z = ALTURA_CABECA / 2.0
	alfinete.add_child(haste)
	var fio: Node3D = null
	if no_fio and _ultimo >= 0:
		var de := _ponto(_ultimo)
		var d := p - de
		fio = Node3D.new()
		fio.name = "_Fio%d" % i
		fio.position = de + Vector3(0, 0, ALTURA_FIO)
		fio.rotation.z = atan2(d.y, d.x)
		papel.add_child(fio)
		var linha := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(d.length(), 0.0022, 0.0022)
		linha.mesh = caixa
		linha.material_override = mat_fio
		linha.position.x = d.length() / 2.0
		fio.add_child(linha)
	if no_fio:
		_ultimo = i
	var nome: Label3D = null
	if i < nomes.size() and not nomes[i].is_empty():
		nome = Label3D.new()
		nome.name = "_Nome%d" % i
		nome.text = nomes[i]
		nome.font = fonte_mao
		nome.font_size = 64
		nome.pixel_size = 0.0002
		nome.modulate = Color(0.12, 0.08, 0.16)
		nome.outline_size = 0
		nome.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		nome.double_sided = false
		# O Label3D centra o texto no nó: meia largura para o lado do rótulo.
		var off := rotulos[i] if i < rotulos.size() else Vector2(0.012, 0.0)
		var meia := fonte_mao.get_string_size(nomes[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x * nome.pixel_size / 2.0
		nome.position = p + Vector3(off.x + signf(off.x) * meia, off.y, 0.002)
		papel.add_child(nome)
	if not animar:
		return
	alfinete.scale = Vector3.ONE * 0.01
	var t := create_tween().set_parallel()
	t.tween_property(alfinete, ^"scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if fio:
		fio.scale = Vector3(0.001, 1, 1)
		t.tween_property(fio, ^"scale:x", 1.0, 0.5).set_delay(0.1).set_trans(Tween.TRANS_SINE)
	if nome:
		nome.modulate.a = 0.0
		t.tween_property(nome, ^"modulate:a", 1.0, 0.6).set_delay(0.3)
