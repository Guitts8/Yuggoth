class_name CartaSaida
extends Node3D
## A carta que Wilmarth acabou de selar, na mão, a caminho do correio — a porta
## do escritório (docs/PLANO_ESCRITORIO.md, Fase 3b). Ocupa a mão: enquanto ela
## existe, o correio do chão espera (Correspondencia).

## A carta na mão, ou null.
static var atual: CartaSaida

## Posição e rotação (graus) em relação à câmera, como o correio que chega.
const MAO_POSICAO := Vector3(0.17, -0.17, -0.42)
const MAO_ROTACAO := Vector3(80, -10, 5)

var reply: ReplyData
var _camera: Camera3D


## O envelope endereçado a Akeley, já na mão.
static func criar(parent: Node, carta: ReplyData) -> CartaSaida:
	var c := CartaSaida.new()
	c.name = "CartaSaida"
	c.reply = carta
	var env := Envelope.new()
	env.name = "Envelope"
	env.destinatario = carta.endereco
	env.remetente = "A. N. Wilmarth\nMiskatonic University\nArkham, Mass."
	env.selos = 3 if carta.registrada else 1
	# A folha dobrada dentro: o mesmo envelope da Selagem.
	env.volumoso = true
	# Ainda sem carimbo: o correio é que carimba.
	env.carimbo_data = ""
	c.add_child(env)
	parent.add_child(c)
	return c


func _ready() -> void:
	atual = self
	_camera = get_viewport().get_camera_3d()
	_seguir()


func _exit_tree() -> void:
	if atual == self:
		atual = null


func _process(_delta: float) -> void:
	_seguir()


## Posta a carta: some da mão.
func postar() -> void:
	if atual == self:
		atual = null
	queue_free()


func _seguir() -> void:
	if is_instance_valid(_camera):
		global_transform = _camera.global_transform * Transform3D(Basis.from_euler(MAO_ROTACAO * PI / 180.0), MAO_POSICAO)
