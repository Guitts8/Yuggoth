class_name LivroEstudo
extends Node3D
## O livro da biblioteca que Wilmarth lê enquanto o tempo passa (playtest 9: "e se
## a passagem de tempo tivesse algo a ver com os livros lidos? para justificar?").
## Nos lapsos, ele senta à escrivaninha e o livro abre diante dele; pela janela os
## dias passam. À noite (as luzes da sala quase apagadas) o livro fecha — ele foi
## para casa; de dia abre de novo e as folhas viram. Na noite em claro (Vigilia) o
## livro fica aberto a noite toda, com a lâmpada acesa: não dormiu.
##
## A lombada é o eixo Z local; a metade da direita (`_direita`) gira sobre ela para
## fechar sobre a da esquerda. Peças feitas aqui, com os materiais do gerador.

@export var mat_capa: Material
@export var mat_papel: Material
@export var mat_tinta: Material

const LARGO := 0.15
const COMPRIDO := 0.22
const ABRIR := 0.7
const DOBRA := 0.0145

var aberto := false
var _direita: Node3D
var _tween: Tween


func _ready() -> void:
	visible = false
	_metade(self, -1.0, 0.0)
	# O eixo da dobra na altura do meio do miolo: fechada, a metade da direita deita
	# por cima da da esquerda (e não por baixo da mesa).
	_direita = Node3D.new()
	_direita.name = "_Direita"
	_direita.position.y = DOBRA
	add_child(_direita)
	_metade(_direita, 1.0, DOBRA)
	_direita.rotation.z = PI


func _metade(pai: Node3D, lado: float, base: float) -> void:
	var capa := _caixa(pai, Vector3(LARGO + 0.01, 0.006, COMPRIDO + 0.01), Vector3(lado * (LARGO + 0.01) / 2.0, 0.003 - base, 0), mat_capa)
	capa.name = "_Capa"
	var folhas := _caixa(pai, Vector3(LARGO, 0.016, COMPRIDO), Vector3(lado * LARGO / 2.0, 0.014 - base, 0), mat_papel)
	folhas.name = "_Folhas"
	for k in 10:
		var linha := _caixa(pai, Vector3(LARGO * 0.75 - (k % 3) * 0.01, 0.0006, 0.004), Vector3(lado * LARGO * 0.5, 0.0225 - base, -0.08 + k * 0.017), mat_tinta)
		linha.name = "_Linha%d" % k


func _caixa(pai: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)
	return mi


## Aparece fechado em `onde` (global) e abre.
func aparecer(onde: Transform3D) -> void:
	global_transform = onde
	_direita.rotation.z = PI
	aberto = false
	visible = true
	abrir()


func abrir() -> void:
	if aberto:
		return
	aberto = true
	_girar(0.0, ABRIR)


func fechar() -> void:
	if not aberto:
		return
	aberto = false
	_girar(PI, ABRIR)


## Uma folha vira, da direita para a esquerda.
func virar() -> void:
	if not aberto:
		return
	var eixo := Node3D.new()
	eixo.name = "_Virando"
	eixo.position.y = 0.023
	add_child(eixo)
	var folha := _caixa(eixo, Vector3(LARGO * 0.98, 0.002, COMPRIDO * 0.98), Vector3(LARGO / 2.0, 0.0, 0), mat_papel)
	folha.name = "_Folha"
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(eixo, ^"rotation:z", PI, 0.55)
	t.tween_callback(eixo.queue_free)


## Fecha e some (devolvido à pilha).
func guardar() -> void:
	fechar()
	await get_tree().create_timer(ABRIR + 0.1).timeout
	if is_inside_tree():
		visible = false


## Um trecho do lapso começou (Lapso.trecho): de noite com a sala apagada (a
## lâmpada quase sem luz), o livro fecha — foi para casa; de dia (a luz é a da
## janela), ou de noite com a lâmpada acesa, abre, ou vira uma folha.
func reagir(hora: String, luz: float) -> void:
	var noite := (hora == "noite" and luz < 0.5) or (hora == "chuva" and luz < 0.15)
	if noite:
		fechar()
	elif not aberto:
		abrir()
	else:
		virar()


func _girar(para: float, segundos: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_direita, ^"rotation:z", para, segundos)
