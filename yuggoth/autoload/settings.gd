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
}

## Trocável em testes para não sobrescrever as preferências do jogador.
var settings_path := "user://settings.cfg"

var _values: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	load_settings()


func get_value(key: StringName) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


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
	_values.merge(DEFAULTS)
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) == OK:
		for key in DEFAULTS:
			var v: Variant = cfg.get_value("geral", key, DEFAULTS[key])
			_values[key] = type_convert(v, typeof(DEFAULTS[key]))
	for key in _values:
		_apply(key)


func reset_to_defaults() -> void:
	for key in DEFAULTS:
		set_value(key, DEFAULTS[key])


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
