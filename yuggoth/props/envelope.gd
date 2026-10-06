@tool
class_name Envelope
extends Node3D
## Envelope de carta, deitado (frente para +Y, topo do texto para -Z): papel,
## selo(s), carimbo do correio e os endereços escritos à mão.
##
## Para trocar pelo modelo final: ponha o .glb como filho chamado "Modelo"
## (mesmo tamanho, frente para +Y). O papel provisório some; selos, carimbo e
## textos continuam por cima, configurados aqui.

const LARGURA := 0.19
const ALTURA := 0.11
const TINTA := Color(0.1, 0.09, 0.16)

@export_multiline var destinatario := "Albert N. Wilmarth, Esq.\n118 Saltonstall St.\nArkham, Mass.":
	set(v):
		destinatario = v
		_reconstruir()
@export_multiline var remetente := "":
	set(v):
		remetente = v
		_reconstruir()
@export var carimbo_cidade := "TOWNSHEND":
	set(v):
		carimbo_cidade = v
		_reconstruir()
@export var carimbo_data := "MAY 5\n1928":
	set(v):
		carimbo_data = v
		_reconstruir()
## Zero selos e `carimbo_data` vazio: envelope de telegrama, entregue em mãos.
@export_range(0, 4) var selos := 1:
	set(v):
		selos = v
		_reconstruir()
## Carta grossa (fotografias dentro): envelope mais estufado.
@export var volumoso := false:
	set(v):
		volumoso = v
		_reconstruir()
## Aberto com a espátula: a fenda escura ao longo da borda de cima.
@export var aberto := false:
	set(v):
		aberto = v
		_reconstruir()


func _ready() -> void:
	_reconstruir()


func espessura() -> float:
	return 0.012 if volumoso else 0.004


## Peças geradas têm nome começando com "_": são refeitas a cada mudança e não
## vão para o .tscn. Uma cópia (ex.: no ExamineViewer) as refaz no _ready.
func _reconstruir() -> void:
	# Antes do _ready (cópia, ou um filho mexendo nele no próprio _ready), o
	# _ready reconstrói de qualquer jeito.
	if not is_node_ready():
		return
	for child in get_children():
		if child.name.begins_with("_"):
			remove_child(child)
			child.queue_free()
	var topo := espessura() * 0.5
	if not has_node(^"Modelo"):
		var papel := BoxMesh.new()
		papel.size = Vector3(LARGURA, espessura(), ALTURA)
		_mesh("_Papel", papel, Vector3.ZERO, _mat("envelope"))

	var direita := LARGURA * 0.5 - 0.004
	var selo_w := 0.022
	for i in selos:
		var quad := QuadMesh.new()
		quad.size = Vector2(selo_w, selo_w * 1.25)
		var x := direita - selo_w * 0.5 - i * (selo_w + 0.002)
		_mesh("_Selo%d" % i, quad, Vector3(x, topo + 0.0004, -ALTURA * 0.5 + 0.02), _mat("selo"), true)

	if not carimbo_data.is_empty():
		var carimbo := QuadMesh.new()
		carimbo.size = Vector2(0.07, 0.035)
		var cx := direita - selos * (selo_w + 0.002) - 0.006
		var pos := Vector3(cx, topo + 0.0008, -ALTURA * 0.5 + 0.02)
		_mesh("_Carimbo", carimbo, pos, _mat("carimbo"), true)
		# Texto dentro do círculo do carimbo (o círculo fica à esquerda da textura).
		var circulo := pos + Vector3(-0.07 * (0.5 - 15.5 / 64.0), 0.0004, 0.0)
		# Fonte grande com pixel pequeno: o texto sai nítido de perto (no exame).
		_texto("_CarimboTexto", "%s\n%s" % [carimbo_cidade, carimbo_data], circulo, 48, 0.000055,
			["Courier New", "Courier", "monospace"], HORIZONTAL_ALIGNMENT_CENTER, Color(TINTA, 0.85))

	if aberto:
		var fenda := QuadMesh.new()
		fenda.size = Vector2(LARGURA - 0.012, 0.0035)
		_mesh("_Fenda", fenda, Vector3(0, topo + 0.0004, -ALTURA * 0.5 + 0.003), _mat("esmalte_preto"), true)

	var letra := ["Segoe Script", "Brush Script MT", "cursive"]
	if not remetente.is_empty():
		_texto("_Remetente", remetente, Vector3(-LARGURA * 0.5 + 0.008, topo + 0.0004, -ALTURA * 0.5 + 0.016),
			48, 0.00009, letra, HORIZONTAL_ALIGNMENT_LEFT, TINTA)
	_texto("_Destinatario", destinatario, Vector3(-0.025, topo + 0.0004, 0.016),
		64, 0.000115, letra, HORIZONTAL_ALIGNMENT_LEFT, TINTA)


func _mesh(nome: String, mesh: Mesh, pos: Vector3, mat: Material, deitado := false) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	if deitado:
		mi.rotation_degrees.x = -90.0
	add_child(mi)


func _texto(nome: String, texto: String, pos: Vector3, tamanho: int, pixel: float,
		fontes: Array, alinhamento: HorizontalAlignment, cor: Color) -> void:
	var label := Label3D.new()
	label.name = nome
	label.text = texto
	label.position = pos
	label.rotation_degrees.x = -90.0
	label.font_size = tamanho
	label.pixel_size = pixel
	label.modulate = cor
	label.outline_size = 0
	label.horizontal_alignment = alinhamento
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var font := SystemFont.new()
	font.font_names = PackedStringArray(fontes)
	label.font = font
	add_child(label)


static func _mat(nome: String) -> Material:
	return load("res://art/materials/%s.tres" % nome)
