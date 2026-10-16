extends Node
## Preferências do jogador (volume, mouse, tela, acessibilidade), separadas do estado
## narrativo e do save: sobrevivem a "Novo jogo" e a saves inválidos.

signal changed(key: StringName)

## `volume_<bus>` é linear (0–1). Não há volume_Whisper de propósito:
## o zumbido é narrativa (GDD §9), só o volume geral o afeta.
const DEFAULTS: Dictionary[StringName, Variant] = {
	&"volume_Master": 0.8,
	&"volume_Music": 1.0,
	&"volume_Ambience": 1.0,
	&"volume_SFX": 1.0,
	&"volume_Voice": 1.0,
	## Multiplicador sobre a sensibilidade base do Player.
	&"sensibilidade": 1.0,
	&"inverter_y": false,
	&"tela_cheia": false,
	## Acessibilidade (GDD §12): o campo de visão da câmera (graus) e quanto do
	## visual do PS1 se quer — o tremor das formas (psx_jitter) e a ondulação das
	## texturas (psx_affine), de 0 (desligado) a 1 (como o jogo foi feito).
	&"campo_visao": 70.0,
	&"tremor": 1.0,
	&"distorcao": 1.0,
	## A qualidade da imagem (QUALIDADES): 0 baixa, 1 média, 2 alta. Sem escolha
	## gravada, sai da placa de vídeo (`padrao`): numa integrada, a baixa.
	&"qualidade": 2,
}

const QUALIDADES := ["Baixa", "Média", "Alta"]
## Por qualidade: o atlas da sombra do sol e o das luzes (px), quanto do alcance da
## sombra do sol fica (fração do que a fase pediu), em quantas faixas ela se parte,
## o filtro das sombras e se a sombra das luzes pontuais é cubo (6 passadas) ou
## duplo paraboloide (2). O custo da fazenda está quase todo na sombra do sol
## (sessão de 2026-10-16: 1,2 milhão de triângulos por quadro só nela).
const NIVEIS := [
	{atlas_sol = 1024, atlas_luzes = 1024, alcance = 0.3, faixas = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		filtro = RenderingServer.SHADOW_QUALITY_HARD, cubo = false, ssao = RenderingServer.ENV_SSAO_QUALITY_VERY_LOW},
	{atlas_sol = 2048, atlas_luzes = 2048, alcance = 0.55, faixas = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		filtro = RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW, cubo = false, ssao = RenderingServer.ENV_SSAO_QUALITY_LOW},
	{atlas_sol = 4096, atlas_luzes = 4096, alcance = 1.0, faixas = -1,
		filtro = RenderingServer.SHADOW_QUALITY_SOFT_LOW, cubo = true, ssao = RenderingServer.ENV_SSAO_QUALITY_MEDIUM},
]

## Trocável em testes para não sobrescrever as preferências do jogador.
var settings_path := "user://settings.cfg"

var _values: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	load_settings()
	# As luzes e as janelas 3D seguem a qualidade quando entram na árvore.
	get_tree().node_added.connect(_no_novo)


func get_value(key: StringName) -> Variant:
	return _values.get(key, padrao(key))


## O valor de fábrica; a qualidade depende da placa de vídeo.
func padrao(key: StringName) -> Variant:
	if key == &"qualidade":
		match RenderingServer.get_video_adapter_type():
			RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, RenderingDevice.DEVICE_TYPE_CPU:
				return 0
		return DEFAULTS[key]
	return DEFAULTS.get(key)


func set_value(key: StringName, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_warning("Preferência desconhecida: %s" % key)
		return
	value = type_convert(value, typeof(DEFAULTS[key]))
	if _values.get(key) == value:
		return
	_values[key] = value
	_apply(key)
	changed.emit(key)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in _values:
		cfg.set_value("geral", key, _values[key])
	var err := cfg.save(settings_path)
	if err != OK:
		push_error("Não foi possível salvar preferências: %s" % error_string(err))


func load_settings() -> void:
	_values.clear()
	for key in DEFAULTS:
		_values[key] = padrao(key)
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) == OK:
		for key in DEFAULTS:
			var v: Variant = cfg.get_value("geral", key, _values[key])
			_values[key] = type_convert(v, typeof(DEFAULTS[key]))
	for key in _values:
		_apply(key)


func reset_to_defaults() -> void:
	for key in DEFAULTS:
		set_value(key, padrao(key))


func _apply(key: StringName) -> void:
	var value: Variant = _values[key]
	if String(key).begins_with("volume_"):
		var bus := AudioServer.get_bus_index(String(key).trim_prefix("volume_"))
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	elif key == &"tela_cheia" and DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	elif key == &"qualidade":
		_aplicar_qualidade()


func nivel() -> Dictionary:
	return NIVEIS[clampi(get_value(&"qualidade"), 0, NIVEIS.size() - 1)]


func _aplicar_qualidade() -> void:
	var n := nivel()
	RenderingServer.directional_shadow_atlas_set_size(n.atlas_sol, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(n.filtro)
	RenderingServer.positional_soft_shadow_filter_set_quality(n.filtro)
	RenderingServer.environment_set_ssao_quality(n.ssao, n.ssao != RenderingServer.ENV_SSAO_QUALITY_MEDIUM, 0.5, 2, 50.0, 300.0)
	if is_inside_tree():
		var pilha: Array[Node] = [get_tree().root]
		while not pilha.is_empty():
			var no: Node = pilha.pop_back()
			pilha.append_array(no.get_children(true))
			_ajustar(no)


func _no_novo(no: Node) -> void:
	if no is Light3D or no is Viewport:
		# Adiado: quem cria a luz em código liga a sombra depois do add_child.
		_ajustar.call_deferred(no)


## Guarda na meta o que a fase pediu e aplica a fração do nível por cima.
func _ajustar(no: Node) -> void:
	if not is_instance_valid(no):
		return
	var n := nivel()
	if no is DirectionalLight3D:
		var sol := no as DirectionalLight3D
		if not sol.has_meta(&"_q_alcance"):
			sol.set_meta(&"_q_alcance", sol.directional_shadow_max_distance)
			sol.set_meta(&"_q_faixas", sol.directional_shadow_mode)
		sol.directional_shadow_max_distance = sol.get_meta(&"_q_alcance") * n.alcance
		sol.directional_shadow_mode = sol.get_meta(&"_q_faixas") if n.faixas < 0 else mini(n.faixas, sol.get_meta(&"_q_faixas"))
	elif no is OmniLight3D:
		var luz := no as OmniLight3D
		if not luz.has_meta(&"_q_modo"):
			luz.set_meta(&"_q_modo", luz.omni_shadow_mode)
		luz.omni_shadow_mode = luz.get_meta(&"_q_modo") if n.cubo else OmniLight3D.SHADOW_DUAL_PARABOLOID
	elif no is Viewport:
		var vp := no as Viewport
		if not vp.has_meta(&"_q_atlas"):
			vp.set_meta(&"_q_atlas", vp.positional_shadow_atlas_size)
		if vp.get_meta(&"_q_atlas") > 0:
			vp.positional_shadow_atlas_size = mini(n.atlas_luzes, vp.get_meta(&"_q_atlas"))
