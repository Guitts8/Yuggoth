extends Control
## Leitor de documentos. Vive na UI em resolução nativa, fora do SubViewport
## de baixa resolução, para o texto continuar legível (GDD §10.1).

var _doc: DocumentData
var _pages: PackedStringArray = []
var _page := 0
var _opened_frame := -1

@onready var title_label: Label = %Title
@onready var body: RichTextLabel = %Body
@onready var footer: Label = %Footer


func _ready() -> void:
	hide()
	body.install_effect(WhisperTextEffect.new())
	body.install_effect(IllegibleTextEffect.new())
	Events.document_requested.connect(open)


func open(doc: DocumentData) -> void:
	_doc = doc
	_page = 0
	# O mesmo evento que abriu o leitor não pode fechá-lo.
	_opened_frame = Engine.get_process_frames()

	title_label.text = doc.title
	DocumentData.apply_fonts(body, doc.style)
	WhisperTextEffect.intensity = GameState.get_number(&"exposicao")
	show()
	_pages = doc.resolve_pages()
	_show_page()
	# Na primeira abertura o papel ainda não tem tamanho; pagina no quadro seguinte.
	_repaginate.call_deferred(doc)
	Events.modal_changed.emit(true)

	var read_flag := doc.get_read_flag()
	if not GameState.has_flag(read_flag):
		GameState.set_flag(read_flag)
		GameState.add(&"exposicao", doc.exposure_on_read)


func _repaginate(doc: DocumentData) -> void:
	await get_tree().process_frame
	if _doc != doc or not visible:
		return
	_pages = _paginate(doc.resolve_pages())
	_page = mini(_page, _pages.size() - 1)
	_show_page()


## Página que não cabe no papel é dividida por parágrafo (linha em branco) nas
## folhas seguintes: textos longos do livro entram sem quebra manual. Por isso
## uma tag BBCode não pode atravessar parágrafos.
func _paginate(source: PackedStringArray) -> PackedStringArray:
	var limit := body.size.y
	if limit <= 0.0:
		return source
	var out := PackedStringArray()
	for page in source:
		var current := ""
		for para in page.split("\n\n"):
			var candidate := para if current.is_empty() else current + "\n\n" + para
			body.text = candidate
			if not current.is_empty() and body.get_content_height() > limit:
				out.append(current)
				current = para
			else:
				current = candidate
		out.append(current)
	return out


func close() -> void:
	var doc := _doc
	_doc = null
	hide()
	Events.modal_changed.emit(false)
	Events.document_closed.emit(doc)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"interagir"):
		close()
	elif event.is_action_pressed(&"pagina_proxima"):
		_turn(1)
	elif event.is_action_pressed(&"pagina_anterior"):
		_turn(-1)
	else:
		return
	get_viewport().set_input_as_handled()


func _turn(direction: int) -> void:
	var next := clampi(_page + direction, 0, _pages.size() - 1)
	if next != _page:
		_page = next
		_show_page()


func _show_page() -> void:
	body.text = _pages[_page] if not _pages.is_empty() else ""
	var hints := "[E] fechar"
	if _pages.size() > 1:
		hints = "%d / %d    [←] [→] página    %s" % [_page + 1, _pages.size(), hints]
	footer.text = hints

