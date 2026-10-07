extends Control
## Leitor de documentos. Vive na UI em resolução nativa, fora do SubViewport
## de baixa resolução, para o texto continuar legível (GDD §10.1).

var _doc: DocumentData
var _pages: PackedStringArray = []
var _page := 0
var _opened_frame := -1
var _tamanho_base := 0

@onready var title_label: Label = %Title
@onready var body: RichTextLabel = %Body
@onready var footer: Label = %Footer


func _ready() -> void:
	hide()
	_tamanho_base = body.get_theme_font_size(&"normal_font_size")
	body.install_effect(WhisperTextEffect.new())
	body.install_effect(IllegibleTextEffect.new())
	body.install_effect(TremorTextEffect.new())
	body.install_effect(QuedaTextEffect.new())
	Events.document_requested.connect(open)


func open(doc: DocumentData) -> void:
	_doc = doc
	_page = 0
	# O mesmo evento que abriu o leitor não pode fechá-lo.
	_opened_frame = Engine.get_process_frames()

	title_label.text = doc.title
	DocumentData.apply_fonts(body, doc.style, _tamanho_base)
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
	var variant := doc.resolve_variant()
	if variant and variant.id and not GameState.has_flag(variant.get_read_flag()):
		GameState.set_flag(variant.get_read_flag())
		GameState.add(&"exposicao", variant.exposure_on_read)


func _repaginate(doc: DocumentData) -> void:
	await get_tree().process_frame
	if _doc != doc or not visible:
		return
	_pages = _paginar_apertando(doc)
	_page = mini(_page, _pages.size() - 1)
	_show_page()


## Como quem escreve à mão aperta a letra no fim da folha: se cada página do
## documento quase cabe no papel (sobraria uma folha), a letra diminui (até APERTO_MAX) para caber
## inteira. Página que transborda de verdade continua indo para a folha seguinte.
const APERTO_MAX := 0.8


func _paginar_apertando(doc: DocumentData) -> PackedStringArray:
	var fonte := doc.resolve_pages()
	var base := _tamanho_base
	DocumentData.apply_fonts(body, doc.style, base)
	var paginas := _paginate(fonte)
	var tamanho := base
	# Só quando sobra uma folha: um texto longo não vira letra miúda.
	while paginas.size() == fonte.size() + 1 and tamanho > int(base * APERTO_MAX):
		tamanho -= 1
		DocumentData.apply_fonts(body, doc.style, tamanho)
		var apertadas := _paginate(fonte)
		if apertadas.size() == fonte.size():
			return apertadas
	DocumentData.apply_fonts(body, doc.style, base)
	return paginas


## Página que não cabe no papel é dividida por parágrafo (linha em branco) nas
## folhas seguintes: textos longos do livro entram sem quebra manual. Por isso
## uma tag BBCode não pode atravessar parágrafos. Uma assinatura (último
## parágrafo, curto) nunca fica sozinha numa folha: leva o parágrafo anterior junto.
func _paginate(source: PackedStringArray) -> PackedStringArray:
	var limit := body.size.y
	if limit <= 0.0:
		return source
	var out := PackedStringArray()
	for page in source:
		var paras := page.split("\n\n")
		var current := PackedStringArray()
		for i in paras.size():
			var para := paras[i]
			body.text = "\n\n".join(current + PackedStringArray([para]))
			if current.is_empty() or body.get_content_height() <= limit:
				current.append(para)
				continue
			var carry := PackedStringArray()
			if i == paras.size() - 1 and _curto(para) and current.size() > 1:
				carry.append(current[current.size() - 1])
				current.resize(current.size() - 1)
			out.append("\n\n".join(current))
			current = carry
			current.append(para)
		out.append("\n\n".join(current))
	return out


static var _tags := RegEx.create_from_string("\\[[^\\]]*\\]")


## Assinatura, P.S. de uma linha: menos de 40 letras fora das tags.
static func _curto(para: String) -> bool:
	return _tags.sub(para, "", true).strip_edges().length() < 40


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

