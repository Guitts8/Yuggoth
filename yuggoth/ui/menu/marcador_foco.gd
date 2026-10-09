class_name MarcadorFoco
extends Control
## As duas pontas de lança rubras que ladeiam a entrada escolhida do livro dos
## menus (como as de Castlevania: Lords of Shadow 2): seguem o foco de um botão a
## outro, deslizando, e respiram — chegam um pouco mais perto do texto e voltam.
## Só marca o que é deste Livro e está à vista; um controle deslizante tem a
## marca só à esquerda (à direita está o valor).

const DESLIZE := 0.2
## Quanto as pontas ficam longe do texto.
const FOLGA := 18.0
## O tamanho das pontas.
const ESCALA := 1.6

var livro: Control
var _alvo: Control
var _rect := Rect2()
var _mostrar := 0.0
var _t := 0.0
var _anda: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	top_level = false


func _process(delta: float) -> void:
	_t += delta
	var foco := get_viewport().gui_get_focus_owner() if is_visible_in_tree() else null
	var valido := foco != null and livro and livro.is_ancestor_of(foco) and foco.is_visible_in_tree() \
		and (foco is BaseButton or foco is Range)
	if valido and foco != _alvo:
		_ir_para(foco)
	elif not valido:
		_alvo = null
	_mostrar = move_toward(_mostrar, 1.0 if _alvo else 0.0, delta * 5.0)
	if _alvo and (_anda == null or not _anda.is_running()):
		_rect = _area(_alvo)
	queue_redraw()


func _area(c: Control) -> Rect2:
	var r := c.get_global_rect()
	# Um botão de texto: só a largura do texto (o botão pode ser mais largo).
	if c is Button:
		var b := c as Button
		var fonte := b.get_theme_font(&"font")
		var tam := b.get_theme_font_size(&"font_size")
		var w := fonte.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var meio := r.get_center()
		r = Rect2(Vector2(meio.x - w / 2.0, r.position.y), Vector2(w, r.size.y))
	var inv := get_global_transform().affine_inverse()
	return Rect2(inv * r.position, r.size)


func _ir_para(c: Control) -> void:
	var de := _rect
	var primeira := _alvo == null and _mostrar <= 0.01
	_alvo = c
	var para := _area(c)
	if _anda:
		_anda.kill()
	if primeira:
		_rect = para
		return
	_anda = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anda.tween_method(func(t: float) -> void:
		_rect = Rect2(de.position.lerp(para.position, t), de.size.lerp(para.size, t)), 0.0, 1.0, DESLIZE)


func _draw() -> void:
	if _mostrar <= 0.0 or _rect.size == Vector2.ZERO:
		return
	var cor := Color(Livro.RUBRO, _mostrar)
	var respira := 3.0 + 3.0 * sin(_t * 3.2)
	var y := _rect.get_center().y
	var so_esquerda := _alvo is Range
	_ponta(Vector2(_rect.position.x - FOLGA - respira, y), 1.0, cor)
	if not so_esquerda:
		_ponta(Vector2(_rect.end.x + FOLGA + respira, y), -1.0, cor)


## Uma ponta de lança apontando para o texto (`dir` = +1, para a direita), com a
## haste e a voluta atrás.
func _ponta(p: Vector2, dir: float, cor: Color) -> void:
	var d := Vector2(dir, 0) * ESCALA
	var n := Vector2(0, 1) * ESCALA
	draw_colored_polygon(PackedVector2Array([
		p, p - d * 13.0 + n * 7.0, p - d * 9.0, p - d * 13.0 - n * 7.0,
	]), cor)
	draw_line(p - d * 9.0, p - d * 26.0, cor, 2.0 * ESCALA, true)
	var pts := PackedVector2Array()
	for k in 14:
		var t := float(k) / 13.0
		var a := t * TAU * 0.85
		pts.append(p - d * 26.0 - d * 5.0 * sin(a) * (1.0 - t * 0.5) + n * (5.0 * (1.0 - cos(a))) * (1.0 - t * 0.5) * 0.9)
	draw_polyline(pts, cor, 1.6 * ESCALA, true)
