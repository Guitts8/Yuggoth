extends Node
## Troca de fases com fade e carregamento assíncrono (GDD §10.3).
## A fase vive dentro do SubViewport do GameRoot, que se registra aqui.
## Pontos de entrada: Marker3D no grupo "spawn"; o nome do nó é o id.

signal level_changed(path: String)

const FADE_TIME := 0.6

## Caminho e ponto de entrada da fase atual (lidos pelo SaveSystem).
var current_level := ""
var current_spawn: StringName = &""
var is_busy := false
## Uma fase pode segurar a tela preta ao abrir (ex.: cartão do Prólogo):
## enquanto true, fade_in() não faz nada. Solte com release_black().
var hold_black := false

var _root: Node
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


## Chamado pelo GameRoot. A raiz precisa de load_level(scene) -> Node e unload_level().
func register_root(root: Node) -> void:
	_root = root


## O mundo congela (pause) durante a troca; o jogador não anda no escuro.
func change_level(path: String, spawn: StringName = &"", fade := true) -> void:
	if is_busy:
		push_warning("SceneDirector ocupado; ignorando troca para %s." % path)
		return
	if _root == null:
		push_error("SceneDirector sem GameRoot registrado.")
		return
	is_busy = true
	# A fase nova decide de novo no _ready() se segura a tela preta.
	hold_black = false
	get_tree().paused = true
	ResourceLoader.load_threaded_request(path)
	if fade:
		await fade_out()

	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(path) as PackedScene
	if scene == null:
		push_error("Falha ao carregar fase %s." % path)
		get_tree().paused = false
		is_busy = false
		await fade_in()
		return

	# Na hora da troca (não antes): a fase velha ainda pode falar durante o fade.
	Narrator.cancel()
	var level: Node = _root.load_level(scene)
	_place_player(level, spawn)
	current_level = path
	current_spawn = spawn

	get_tree().paused = false
	is_busy = false
	level_changed.emit(path)
	if fade:
		await fade_in()


## Descarrega a fase sem carregar outra (voltar ao menu principal).
## Não emite level_changed: não há checkpoint de "fase nenhuma".
func clear_level() -> void:
	if _root == null or is_busy:
		return
	_root.unload_level()
	hold_black = false
	Narrator.cancel()
	current_level = ""
	current_spawn = &""


## Também usado por sequências que trocam o cenário no escuro (ex.: Prólogo).
func fade_out(time := FADE_TIME) -> void:
	await _tween_fade(1.0, time)


func fade_in(time := FADE_TIME) -> void:
	if hold_black:
		return
	await _tween_fade(0.0, time)


func release_black(time := FADE_TIME) -> void:
	hold_black = false
	await fade_in(time)


## Salto no tempo dentro da mesma fase: escurece, mostra o cartão e volta (ex.:
## depois de um telefonema ou de uma carta). O cartão é dito já no escuro, então
## a fase pode trocar o cenário pela flag `narrou_<id>` dele sem o jogador ver.
## Quem chama checa is_inside_tree() depois.
func time_skip(cartao: NarrationLine, saida := 1.0, volta := 1.2) -> void:
	await fade_out(saida)
	hold_black = true
	await Narrator.say(cartao, Narrator.Style.CARTAO)
	await release_black(volta)


func _tween_fade(alpha: float, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, time)
	await tween.finished


func _place_player(level: Node, spawn: StringName) -> void:
	if spawn.is_empty():
		return
	var marker: Node3D
	for node in get_tree().get_nodes_in_group(&"spawn"):
		if node.name == spawn and level.is_ancestor_of(node):
			marker = node
			break
	if marker == null:
		push_warning("Spawn '%s' não encontrado em %s." % [spawn, level.scene_file_path])
		return
	for node in get_tree().get_nodes_in_group(&"player"):
		if level.is_ancestor_of(node):
			(node as Node3D).global_transform = marker.global_transform
			return
