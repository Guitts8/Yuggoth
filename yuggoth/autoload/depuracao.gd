extends Node
## Só para testes — não existe no jogo exportado (some fora de build de
## depuração): segurar F acelera tudo VELOCIDADE vezes (falas do narrador,
## telefonemas, cartões, lapsos, sonhos, animações), com um aviso no canto.

const VELOCIDADE := 8.0
const TECLA := KEY_F

var _acelerando := false
var _aviso: Label


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	var camada := CanvasLayer.new()
	camada.layer = 128
	add_child(camada)
	_aviso = Label.new()
	_aviso.text = "▶▶ %d×  (teste)" % VELOCIDADE
	_aviso.position = Vector2(24, 20)
	_aviso.add_theme_font_size_override(&"font_size", 22)
	_aviso.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.3))
	_aviso.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override(&"outline_size", 6)
	_aviso.hide()
	camada.add_child(_aviso)


func _process(_delta: float) -> void:
	var segurando := Input.is_physical_key_pressed(TECLA) and get_window().has_focus()
	# Só mexe no time_scale que ele mesmo mudou (o teste de fumaça usa o seu).
	if segurando and not _acelerando:
		_acelerando = true
		Engine.time_scale = VELOCIDADE
	elif not segurando and _acelerando:
		_acelerando = false
		Engine.time_scale = 1.0
	_aviso.visible = _acelerando
