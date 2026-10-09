extends Control
## Visualizador de objetos examinados. Mostra uma cópia do visual num mundo 3D
## próprio, em baixa resolução como o resto do jogo; textos em resolução nativa.
##
## Mouse: arrastar (qualquer botão) gira; mover sem botão olha em volta quando
## aproximado; roda aproxima. Controle: analógico dir. gira, esq. olha em volta,
## gatilhos aproximam.

const DWELL_TIME := 0.6
const ROTATE_MOUSE := 0.008
const ROTATE_STICK := 2.4
const PAN_STICK := 1.6
const ZOOM_STEP := 0.12
const ZOOM_STICK := 1.2
## Distância mínima da câmera, como fração da distância que enquadra o objeto todo.
const CLOSEST := 0.3
## Raio da zona central onde um detalhe conta como "olhado", em fração da altura.
const FOCUS_RADIUS := 0.18

@export var target_height := 480

var _target: Examinable
var _model: Node3D
var _hotspots: Array[ExamineHotspot] = []
var _dwell: Dictionary[ExamineHotspot, float] = {}
var _found: Dictionary[ExamineHotspot, bool] = {}
var _radius := 0.5
var _base_distance := 1.0
var _zoom := 0.0
## -1..1 em cada eixo; o alvo segue o mouse, o atual persegue o alvo.
var _pan_target := Vector2.ZERO
var _pan := Vector2.ZERO
var _opened_frame := -1

@onready var view: SubViewportContainer = %View
@onready var pivot: Node3D = %Pivot
@onready var camera: Camera3D = %Camera
@onready var title_label: Label = %Title
@onready var caption: Label = %Caption
@onready var _post: ShaderMaterial = view.material


func _ready() -> void:
	hide()
	Events.examine_requested.connect(open)
	get_viewport().size_changed.connect(_update_shrink)
	_update_shrink()


func open(target: Examinable) -> void:
	var source := target.get_visual()
	if source == null:
		push_warning("%s sem visual para examinar." % target.get_path())
		return
	_target = target
	_opened_frame = Engine.get_process_frames()

	_model = source.duplicate() as Node3D
	_strip(_model)
	_model.transform = Transform3D.IDENTITY
	pivot.transform = Transform3D(Basis.from_euler(target.initial_rotation * PI / 180.0))
	pivot.add_child(_model)
	_frame_model()

	_hotspots.assign(_model.find_children("*", "ExamineHotspot", true, false))
	_dwell.clear()
	_found.clear()
	for hs in _hotspots:
		if not hs.flag.is_empty() and GameState.has_flag(hs.flag):
			_found[hs] = true

	_zoom = 0.0
	_pan = Vector2.ZERO
	_pan_target = Vector2.ZERO
	title_label.text = target.title
	caption.text = target.description
	show()
	Events.modal(self, true)


func close() -> void:
	var target: Examinable = _target if is_instance_valid(_target) else null
	_target = null
	if _model:
		_model.queue_free()
		_model = null
	_hotspots.clear()
	hide()
	Events.modal(self, false)
	Events.examine_closed.emit(target)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask != 0:
			_rotate(event.relative * ROTATE_MOUSE)
		else:
			_pan_target = (event.position / size - Vector2(0.5, 0.5)) * 2.0
		accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom + ZOOM_STEP, 0.0, 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom - ZOOM_STEP, 0.0, 1.0)
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	# O clique esquerdo também é "interagir", mas aqui ele serve para girar.
	if event is InputEventMouseButton:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"interagir"):
		close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible or _model == null:
		return
	# O que se examinava sumiu (a fase trocou: a ligação de Keene leva a Boston).
	if not is_instance_valid(_target):
		close()
		return
	var turn := Input.get_vector(&"olhar_esquerda", &"olhar_direita", &"olhar_cima", &"olhar_baixo")
	if turn != Vector2.ZERO:
		_rotate(turn * ROTATE_STICK * delta)
	var stick := Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_frente", &"mover_tras")
	if stick != Vector2.ZERO:
		_pan_target = (_pan_target + stick * PAN_STICK * delta).clampf(-1.0, 1.0)
	_zoom = clampf(_zoom + Input.get_axis(&"zoom_menos", &"zoom_mais") * ZOOM_STICK * delta, 0.0, 1.0)

	_pan = _pan.lerp(_pan_target, 1.0 - exp(-8.0 * delta))
	# Só dá para olhar em volta quando aproximado; de longe o objeto fica centrado.
	var reach := _radius * _zoom
	camera.position = Vector3(_pan.x * reach, -_pan.y * reach, lerpf(_base_distance, _base_distance * CLOSEST, _zoom))
	_post.set_shader_parameter(&"exposure", GameState.get_number(&"exposicao"))
	_update_hotspots(delta)


func _rotate(amount: Vector2) -> void:
	pivot.rotate(Vector3.UP, amount.x)
	pivot.rotate(Vector3.RIGHT, amount.y)


func _update_hotspots(delta: float) -> void:
	var screen := Vector2(camera.get_viewport().size)
	var focused: ExamineHotspot
	for hs in _hotspots:
		if not hs.is_available():
			continue
		var in_focus := _is_in_focus(hs, screen)
		if _found.has(hs):
			if in_focus:
				focused = hs
			continue
		_dwell[hs] = _dwell.get(hs, 0.0) + delta if in_focus and _zoom >= hs.min_zoom else 0.0
		if _dwell[hs] >= DWELL_TIME:
			_discover(hs)
			focused = hs
	caption.text = focused.text if focused and not focused.text.is_empty() else _target.description


func _is_in_focus(hs: ExamineHotspot, screen: Vector2) -> bool:
	if camera.is_position_behind(hs.global_position):
		return false
	var to_camera := (camera.global_position - hs.global_position).normalized()
	if (-hs.global_basis.z).dot(to_camera) < 0.5:
		return false
	return camera.unproject_position(hs.global_position).distance_to(screen * 0.5) < screen.y * FOCUS_RADIUS


func _discover(hs: ExamineHotspot) -> void:
	_found[hs] = true
	if not hs.flag.is_empty():
		GameState.set_flag(hs.flag)
	if hs.exposure > 0.0:
		GameState.add(&"exposicao", hs.exposure)


## Enquadra o objeto inteiro com a câmera na distância base.
func _frame_model() -> void:
	var box := AABB()
	var first := true
	var to_pivot := pivot.global_transform.affine_inverse()
	# Só geometria: uma luz junto do objeto (a da pedra do sonho) inflava o raio.
	var visuals: Array[Node] = _model.find_children("*", "GeometryInstance3D", true, false)
	visuals.append(_model)
	for node in visuals:
		var vi := node as GeometryInstance3D
		if vi == null:
			continue
		var b: AABB = (to_pivot * vi.global_transform) * vi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	_model.position = -box.get_center()
	_radius = maxf(box.size.length() * 0.5, 0.01)
	_base_distance = _radius / tan(deg_to_rad(camera.fov * 0.5)) * 1.15
	camera.near = _base_distance * CLOSEST * 0.1


## Tira da cópia tudo que não é visual: áreas de interação, corpos, luzes e sons
## (o visualizador tem a sua luz; um som tocaria de novo).
func _strip(root: Node) -> void:
	var fora: Array[Node] = root.find_children("*", "CollisionObject3D", true, false)
	fora.append_array(root.find_children("*", "Light3D", true, false))
	fora.append_array(root.find_children("*", "AudioStreamPlayer3D", true, false))
	for node in fora:
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.free()


func _update_shrink() -> void:
	view.stretch_shrink = maxi(1, roundi(get_viewport().get_visible_rect().size.y / target_height))
