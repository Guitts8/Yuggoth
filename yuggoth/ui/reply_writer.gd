extends Control
## Wilmarth escreve a Akeley (GDD §5.1). Primeiro o jogador escolhe como a
## carta começa (o tom); depois ela se escreve sozinha, ao som da pena. Antes
## de escolher dá para desistir (Esc) e voltar depois; escolhida, dá para
## amassar a folha (Esc) e começar outra quantas vezes quiser. Só selar decide.

const CHARS_PER_SECOND := 70.0
## O envelope desenhado na animação de selar (px, na resolução da UI).
const ENVELOPE := Vector2(840, 400)
const PAPEL_ENVELOPE := Color(0.82, 0.76, 0.62)
const TINTA := Color(0.12, 0.09, 0.14)

@export var pen_sound: AudioStream
## Dobrar a folha, enfiar no envelope.
@export var paper_sound: AudioStream
## O selo batido com a palma da mão.
@export var stamp_sound: AudioStream

var _reply: ReplyData
var _chosen: ReplyOption
var _tween: Tween
## Pena arranhando em loop enquanto a carta se escreve.
var _pen: AudioStreamPlayer
var _opened_frame := -1
var _selando := false
var _paper_topo := 0.0

# Peças da animação de selar (montadas em _montar_envelope).
var _env: Control
var _verso: Array[CanvasItem] = []
var _aba: Polygon2D
var _frente: Control
var _endereco: RichTextLabel
var _selos: HBoxContainer

@onready var title_label: Label = %Title
@onready var choices: VBoxContainer = %Choices
@onready var body: RichTextLabel = %Body
@onready var footer: Label = %Footer
@onready var paper: Control = $Paper
@onready var dim: ColorRect = $Dim


func _ready() -> void:
	hide()
	_paper_topo = paper.offset_top
	# Na frente do fundo e da aba aberta (z 0), atrás do bolso (z 2). Nada abaixo de
	# 0: o que fica atrás do Dim escurece.
	paper.z_index = 1
	_montar_envelope()
	_repor()
	_pen = AudioStreamPlayer.new()
	_pen.stream = pen_sound
	_pen.bus = &"SFX"
	_pen.volume_db = -6.0
	_pen.finished.connect(func() -> void:
		if _tween:
			_pen.play())
	add_child(_pen)
	DocumentData.apply_fonts(body, DocumentData.Style.MANUSCRITO)
	Events.reply_requested.connect(open)


func open(reply: ReplyData) -> void:
	if reply == null or reply.is_done():
		return
	_reply = reply
	_chosen = null
	_opened_frame = Engine.get_process_frames()
	_repor()
	title_label.text = reply.destinatario
	body.text = ""
	body.hide()
	for child in choices.get_children():
		child.queue_free()
	_mostrar_aberturas()
	show()
	Events.modal_changed.emit(true)
	_focar_primeira()


func _mostrar_aberturas() -> void:
	for option in _reply.options:
		var button := Button.new()
		button.text = "“%s”" % option.resumo
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose.bind(option))
		# Tinta sobre papel claro (o tema dos menus é claro sobre escuro).
		button.add_theme_color_override(&"font_color", Color(0.3, 0.24, 0.18))
		for state: StringName in [&"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
			button.add_theme_color_override(state, Color(0.06, 0.04, 0.03))
		button.add_theme_font_size_override(&"font_size", 24)
		choices.add_child(button)
	choices.show()
	footer.text = "Como começar a carta?    [Esc] mais tarde"


func _focar_primeira() -> void:
	for child in choices.get_children():
		if not child.is_queued_for_deletion():
			(child as Button).grab_focus()
			return


## Amassa a folha: de volta às aberturas, nada decidido.
func _recomecar() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_pen.stop()
	_chosen = null
	body.text = ""
	body.hide()
	choices.show()
	footer.text = "Como começar a carta?    [Esc] mais tarde"
	_focar_primeira()


func _choose(option: ReplyOption) -> void:
	_chosen = option
	choices.hide()
	body.text = option.document.resolve_pages()[0] if option.document else option.resumo
	body.visible_ratio = 0.0
	body.show()
	footer.text = "[E] escrever de uma vez    [Esc] recomeçar"
	var length := body.get_parsed_text().length()
	_tween = create_tween()
	_tween.tween_property(body, "visible_ratio", 1.0, length / CHARS_PER_SECOND)
	_tween.tween_callback(_finish_writing)
	_pen.play()


func _finish_writing() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	body.visible_ratio = 1.0
	_pen.stop()
	footer.text = "[E] selar o envelope    [Esc] recomeçar"


func _unhandled_input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	if _selando:
		get_viewport().set_input_as_handled()
		return
	if _chosen == null:
		if event.is_action_pressed(&"ui_cancel"):
			_close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"interagir"):
			# [E] escolhe a opção em foco, como no resto do jogo.
			var focused := get_viewport().gui_get_focus_owner() as Button
			if focused and choices.is_ancestor_of(focused):
				focused.pressed.emit()
				get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel"):
		_recomecar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interagir") or event.is_action_pressed(&"ui_accept"):
		if _tween:
			_finish_writing()  # pressa: mostra o resto de uma vez
		else:
			_seal()
		get_viewport().set_input_as_handled()


## Selar decide na hora; depois a animação (a folha dobrada em três, o envelope,
## o selo) e só então a carta sai da tela — para a mão de Wilmarth (a fase ouve
## reply_written). Dá para esperar: `await _seal()`.
func _seal() -> void:
	if _selando or _reply == null:
		return
	var reply := _reply
	var option := _chosen
	reply.apply(option)
	_selando = true
	footer.text = ""
	await _animar_selagem(reply)
	_selando = false
	_close()
	Events.reply_written.emit(reply, option)


func _close() -> void:
	_reply = null
	_chosen = null
	hide()
	_repor()
	Events.modal_changed.emit(false)


# --- Selar ------------------------------------------------------------------

func _animar_selagem(reply: ReplyData) -> void:
	# A tinta some do papel e a folha se dobra em três, de baixo para cima.
	var t := create_tween()
	t.tween_property(paper.get_node(^"VBox"), ^"modulate:a", 0.0, 0.25)
	await t.finished
	paper.pivot_offset = Vector2(paper.size.x * 0.5, 0.0)
	for dobra in [0.67, 0.34]:
		_som(paper_sound)
		t = create_tween()
		t.tween_property(paper, ^"scale:y", dobra, 0.2).set_trans(Tween.TRANS_SINE)
		await t.finished
		await get_tree().create_timer(0.08).timeout

	# O verso do envelope, aberto; a folha desce para dentro do bolso.
	_endereco.text = reply.endereco
	for i in _selos.get_child_count():
		_selos.get_child(i).visible = i < (3 if reply.registrada else 1)
	_env.show()
	_env.modulate.a = 0.0
	t = create_tween()
	t.tween_property(_env, ^"modulate:a", 1.0, 0.2)
	await t.finished
	_som(paper_sound)
	# O centro da folha dobrada (um terço da altura) no centro do envelope.
	var dentro := _env.position.y + ENVELOPE.y * 0.5 - paper.size.y * 0.17
	t = create_tween()
	t.tween_property(paper, ^"position:y", dentro, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished

	# A aba fecha por cima.
	t = create_tween()
	t.tween_property(_aba, ^"scale:y", 0.0, 0.14)
	await t.finished
	_aba.z_index = 3
	t = create_tween()
	t.tween_property(_aba, ^"scale:y", 1.0, 0.14)
	await t.finished
	await get_tree().create_timer(0.15).timeout

	# Vira o envelope: o endereço de Akeley; o selo batido com a palma da mão.
	_env.pivot_offset = _env.size * 0.5
	t = create_tween()
	t.tween_property(_env, ^"scale:x", 0.0, 0.14)
	await t.finished
	paper.hide()
	for peca in _verso:
		peca.hide()
	_frente.show()
	t = create_tween()
	t.tween_property(_env, ^"scale:x", 1.0, 0.14)
	await t.finished
	_selos.show()
	_selos.modulate.a = 0.0
	_selos.scale = Vector2.ONE * 1.4
	t = create_tween().set_parallel()
	t.tween_property(_selos, ^"modulate:a", 1.0, 0.1)
	t.tween_property(_selos, ^"scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	_som(stamp_sound)
	await get_tree().create_timer(0.7).timeout

	# Para a mão: desce para o canto e a sala volta.
	t = create_tween().set_parallel()
	t.tween_property(_env, ^"position", _env.position + Vector2(size.x * 0.25, size.y * 0.55), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(_env, ^"scale", Vector2.ONE * 0.5, 0.4)
	t.tween_property(dim, ^"modulate:a", 0.0, 0.4)
	await t.finished


## Desfaz a animação: folha aberta, envelope escondido.
func _repor() -> void:
	paper.show()
	paper.scale = Vector2.ONE
	paper.offset_top = _paper_topo
	paper.offset_bottom = _paper_topo + paper.size.y
	paper.get_node(^"VBox").modulate.a = 1.0
	dim.modulate.a = 1.0
	_env.hide()
	_env.scale = Vector2.ONE
	_env.position = size * 0.5 - ENVELOPE * 0.5
	for peca in _verso:
		peca.show()
	_aba.scale.y = -1.0
	_aba.z_index = 0
	_frente.hide()
	_selos.hide()


func _som(stream: AudioStream) -> void:
	AudioDirector.play_sfx(stream, -4.0)


## O envelope em peças: o verso (o fundo, por trás da folha; a aba aberta, para
## cima; o bolso, na frente da folha) e a frente (endereço, remetente, selos).
func _montar_envelope() -> void:
	_env = Control.new()
	_env.name = "_Envelope"
	_env.size = ENVELOPE
	_env.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_env)
	var w := ENVELOPE.x
	var h := ENVELOPE.y

	var fundo := ColorRect.new()
	fundo.color = PAPEL_ENVELOPE.darkened(0.35)
	fundo.size = ENVELOPE
	fundo.z_index = 0
	_env.add_child(fundo)
	_aba = Polygon2D.new()
	_aba.polygon = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, h * 0.58)])
	_aba.color = PAPEL_ENVELOPE.darkened(0.08)
	_env.add_child(_aba)
	var bolso := Polygon2D.new()
	bolso.polygon = PackedVector2Array([Vector2(0, 0), Vector2(w * 0.5, h * 0.55), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
	bolso.color = PAPEL_ENVELOPE
	bolso.z_index = 2
	_env.add_child(bolso)
	var dobras := Line2D.new()
	dobras.points = PackedVector2Array([Vector2(0, h), Vector2(w * 0.5, h * 0.5), Vector2(w, h)])
	dobras.width = 2.0
	dobras.default_color = PAPEL_ENVELOPE.darkened(0.25)
	dobras.z_index = 2
	_env.add_child(dobras)
	_verso.assign([fundo, _aba, bolso, dobras])

	_frente = Control.new()
	_frente.size = ENVELOPE
	_frente.z_index = 4
	_env.add_child(_frente)
	var cara := ColorRect.new()
	cara.color = PAPEL_ENVELOPE
	cara.size = ENVELOPE
	_frente.add_child(cara)
	var remetente := _texto("A. N. Wilmarth\nMiskatonic University\nArkham, Mass.", 18)
	remetente.position = Vector2(28, 22)
	remetente.size = Vector2(320, 90)
	_frente.add_child(remetente)
	_endereco = _texto("", 30)
	_endereco.position = Vector2(w * 0.36, h * 0.42)
	_endereco.size = Vector2(w * 0.6, h * 0.5)
	_frente.add_child(_endereco)

	_selos = HBoxContainer.new()
	_selos.alignment = BoxContainer.ALIGNMENT_END
	_selos.add_theme_constant_override(&"separation", 8)
	_selos.size = Vector2(240, 92)
	_selos.position = Vector2(w - 240 - 24, 22)
	_selos.pivot_offset = _selos.size * 0.5
	_selos.z_index = 5
	_env.add_child(_selos)
	for i in 3:
		var selo := Panel.new()
		selo.custom_minimum_size = Vector2(70, 88)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.62, 0.13, 0.11)
		estilo.border_color = Color(0.93, 0.9, 0.82)
		estilo.set_border_width_all(6)
		selo.add_theme_stylebox_override(&"panel", estilo)
		_selos.add_child(selo)


func _texto(texto: String, tamanho: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DocumentData.apply_fonts(r, DocumentData.Style.MANUSCRITO)
	r.add_theme_color_override(&"default_color", TINTA)
	r.add_theme_font_size_override(&"normal_font_size", tamanho)
	r.text = texto
	return r
