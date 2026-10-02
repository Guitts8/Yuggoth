@tool
class_name Fotografia
extends Node3D
## Fotografia de câmera Kodak, deitada (imagem para +Y, topo da imagem para -Z),
## com borda branca. Detalhes escondidos são ExamineHotspot filhos, posicionados
## com pos_na_imagem() — o ExamineViewer os acha de perto, "com a lupa".
##
## Para trocar pelo modelo final: filho "Modelo" substitui o cartão provisório;
## a imagem continua sendo esta textura.

const CARTAO := Vector2(0.13, 0.1)
const IMAGEM := Vector2(0.116, 0.087)
const ESPESSURA := 0.0025

@export var imagem: Texture2D:
	set(v):
		imagem = v
		_reconstruir()


func _ready() -> void:
	_reconstruir()


## Ponto da imagem (uv 0..1, origem no canto superior esquerdo) em coordenadas
## locais, logo acima da superfície.
static func pos_na_imagem(uv: Vector2) -> Vector3:
	return Vector3((uv.x - 0.5) * IMAGEM.x, ESPESSURA * 0.5 + 0.0006, (uv.y - 0.5) * IMAGEM.y)


func _reconstruir() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if child.name.begins_with("_"):
			remove_child(child)
			child.queue_free()
	if not has_node(^"Modelo"):
		var cartao := BoxMesh.new()
		cartao.size = Vector3(CARTAO.x, ESPESSURA, CARTAO.y)
		var mi := MeshInstance3D.new()
		mi.name = "_Cartao"
		mi.mesh = cartao
		mi.material_override = load("res://art/materials/cartao_foto.tres")
		add_child(mi)
	if imagem:
		var quad := QuadMesh.new()
		quad.size = IMAGEM
		var mat := (load("res://art/materials/foto.tres") as ShaderMaterial).duplicate() as ShaderMaterial
		mat.set_shader_parameter(&"albedo_tex", imagem)
		var mi := MeshInstance3D.new()
		mi.name = "_Imagem"
		mi.mesh = quad
		mi.material_override = mat
		mi.position.y = ESPESSURA * 0.5 + 0.0003
		mi.rotation_degrees.x = -90.0
		add_child(mi)
