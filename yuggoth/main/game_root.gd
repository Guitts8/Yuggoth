extends Node
## Raiz do jogo: mundo 3D num SubViewport de baixa resolução (visual PSX)
## e UI por cima em resolução nativa (GDD §10.1).

## Primeira fase de um jogo novo.
@export var start_level: PackedScene
## Desligado (testes, ou para testar uma fase direto): pula o menu e começa um jogo novo.
@export var boot_to_menu := true
## Altura alvo do mundo em pixels; o shrink é inteiro e arredondado, então com
## base 1080p dá shrink 2 = 960x540.
@export var target_height := 480
## Velocidade com que a distorção de tela persegue `exposicao`.
@export var exposure_follow := 1.5

@export_group("Visual PSX")
## Valores com o mundo firme (x) e em sonho (y). "Sonho" é o maior entre
## exposicao² e o valor `sonho` do GameState: a realidade quebrando devolve a
## estética crua do PS1, e sequências oníricas a ligam direto.
@export var jitter_range := Vector2(0.25, 1.0)
## Texturas "escorrendo" (mapeamento afim). Acima de 1 amplifica o erro: com a
## geometria subdividida, é o que devolve o redemoinho dos polígonos gigantes.
@export var affine_range := Vector2(0.15, 5.0)
## Grossura da grade de tremor (1 = meio pixel do viewport).
@export var snap_range := Vector2(1.0, 2.5)
@export var vignette_range := Vector2(0.35, 0.7)

## Quanto o visual está em "sonho" agora (0–1), já combinando exposição e `sonho`.
var dream_level := 0.0

var _level: Node
var _shown_exposure := 0.0
## Impede clique duplo nos menus durante o fade.
var _transitioning := false

@onready var world_container: SubViewportContainer = $WorldContainer
@onready var world: SubViewport = $WorldContainer/World
@onready var main_menu: MainMenu = $Menus/MainMenu
@onready var pause_menu: PauseMenu = $Menus/PauseMenu
@onready var _post: ShaderMaterial = world_container.material


func _ready() -> void:
	get_viewport().size_changed.connect(_update_shrink)
	_update_shrink()
	SceneDirector.register_root(self)
	main_menu.new_game_requested.connect(new_game)
	main_menu.continue_requested.connect(continue_game)
	pause_menu.quit_to_menu_requested.connect(quit_to_menu)
	Events.quit_to_menu_requested.connect(quit_to_menu)
	if boot_to_menu:
		main_menu.open()
	else:
		new_game(false)


func new_game(fade := true) -> void:
	if _transitioning:
		return
	_transitioning = true
	if fade:
		await SceneDirector.fade_out()
	main_menu.close()
	GameState.reset()
	_shown_exposure = 0.0
	await SceneDirector.change_level(start_level.resource_path, &"", false)
	_transitioning = false
	if fade:
		await SceneDirector.fade_in()


func continue_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	await SceneDirector.fade_out()
	main_menu.close()
	# load_game faz o próprio fade_in (o fade_out dele já encontra a tela preta).
	var ok := await SaveSystem.load_game()
	_shown_exposure = GameState.get_number(&"exposicao")
	_transitioning = false
	if not ok:
		main_menu.open()
		await SceneDirector.fade_in()


func quit_to_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	await SceneDirector.fade_out()
	pause_menu.close()
	SceneDirector.clear_level()
	AudioDirector.stop_ambience(0.0)
	AudioDirector.set_hum(null, 0.0)
	main_menu.open()
	_transitioning = false
	await SceneDirector.fade_in()


## Troca crua da fase. Use SceneDirector.change_level(), não isto.
func load_level(scene: PackedScene) -> Node:
	unload_level()
	_level = scene.instantiate()
	world.add_child(_level)
	return _level


func unload_level() -> void:
	if _level:
		# Sai da árvore já: a fase nova pode ter o mesmo nome e os mesmos grupos.
		world.remove_child(_level)
		_level.queue_free()
		_level = null


func _process(delta: float) -> void:
	var target := GameState.get_number(&"exposicao")
	_shown_exposure = move_toward(_shown_exposure, target, delta * exposure_follow)
	_post.set_shader_parameter(&"exposure", _shown_exposure)
	WhisperTextEffect.intensity = _shown_exposure
	# Exposição quadrática: os primeiros dias ficam firmes, a quebra vem no fim.
	dream_level = maxf(_shown_exposure * _shown_exposure, GameState.get_number(&"sonho"))
	RenderingServer.global_shader_parameter_set(&"psx_dream", dream_level)
	RenderingServer.global_shader_parameter_set(&"psx_jitter", lerpf(jitter_range.x, jitter_range.y, dream_level))
	RenderingServer.global_shader_parameter_set(&"psx_affine", lerpf(affine_range.x, affine_range.y, dream_level))
	RenderingServer.global_shader_parameter_set(&"psx_snap", lerpf(snap_range.x, snap_range.y, dream_level))
	_post.set_shader_parameter(&"vignette", lerpf(vignette_range.x, vignette_range.y, dream_level))


func _update_shrink() -> void:
	var height := get_viewport().get_visible_rect().size.y
	world_container.stretch_shrink = maxi(1, roundi(height / target_height))
