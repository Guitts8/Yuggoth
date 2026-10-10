extends Node
## Camadas de ambiente com crossfade, o zumbido e sons 2D avulsos (GDD §9, §10.3).
## Sons posicionais ficam nas fases (AudioStreamPlayer3D); aqui só o que é global.
##
## O zumbido é o leitmotiv: toca no bus Whisper e `exposicao` controla volume,
## filtro, distorção e pitch. Fica mudo até alguém chamar set_hum() — no
## escritório, isso acontece depois do disco (Dia 3).
##
## Com uma UI modal aberta (ler uma carta, escrever, examinar), o ambiente
## abaixa: os pássaros da tarde não disputam com a leitura.

const AMBIENCE_FADE := 2.0
## Velocidade com que o zumbido persegue `exposicao` (igual ao pós do GameRoot).
const EXPOSURE_FOLLOW := 1.5

## Faixas do zumbido de exposicao 0 a 1.
const HUM_DB := Vector2(-30.0, -6.0)
const HUM_CUTOFF_HZ := Vector2(400.0, 5000.0)
const HUM_DRIVE := Vector2(0.0, 0.45)
const HUM_PITCH := Vector2(1.0, 0.94)
## Ganho do bus Ambience com um modal aberto, e quão rápido (dB/s) chega lá.
const DUCK_DB := -16.0
const DUCK_SPEED := 30.0

var _ambience: Array[AudioStreamPlayer] = []
var _ambience_active := 0
var _ambience_tweens: Array[Tween] = [null, null]
var _hum: AudioStreamPlayer
var _hum_level := 0.0
var _hum_tween: Tween
var _shown_exposure := 0.0

var _whisper_bus := -1
var _lowpass: AudioEffectLowPassFilter
var _distortion: AudioEffectDistortion
var _pitch: AudioEffectPitchShift
var _duck: AudioEffectAmplify


func _ready() -> void:
	# Ambiente e zumbido continuam no menu de pausa; o silêncio seria uma quebra.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		_ambience.append(_make_player(&"Ambience"))
	_hum = _make_player(&"Whisper")
	_hum.volume_db = -80.0

	# Separado do volume do bus (que é a preferência do jogador, em Settings).
	var ambience_bus := AudioServer.get_bus_index(&"Ambience")
	if ambience_bus >= 0:
		_duck = AudioEffectAmplify.new()
		AudioServer.add_bus_effect(ambience_bus, _duck)

	_whisper_bus = AudioServer.get_bus_index(&"Whisper")
	if _whisper_bus < 0:
		push_error("Bus Whisper ausente; confira default_bus_layout.tres.")
		return
	for i in AudioServer.get_bus_effect_count(_whisper_bus):
		var fx := AudioServer.get_bus_effect(_whisper_bus, i)
		if fx is AudioEffectLowPassFilter:
			_lowpass = fx
		elif fx is AudioEffectDistortion:
			_distortion = fx
		elif fx is AudioEffectPitchShift:
			_pitch = fx


func _process(delta: float) -> void:
	var target := GameState.get_number(&"exposicao")
	_shown_exposure = move_toward(_shown_exposure, target, delta * EXPOSURE_FOLLOW)
	_update_whisper(_shown_exposure)
	if _duck:
		var duck := DUCK_DB if Events.is_modal_open else 0.0
		_duck.volume_db = move_toward(_duck.volume_db, duck, delta * DUCK_SPEED)


## Troca o ambiente com crossfade. `null` silencia.
func play_ambience(stream: AudioStream, fade := AMBIENCE_FADE) -> void:
	var current := _ambience[_ambience_active]
	if stream != null and current.stream == stream and current.playing:
		return
	_fade_ambience(_ambience_active, false, fade)
	if stream == null:
		return
	_ambience_active = 1 - _ambience_active
	var next := _ambience[_ambience_active]
	next.stream = stream
	next.volume_db = -80.0
	next.play()
	_fade_ambience(_ambience_active, true, fade)


func stop_ambience(fade := AMBIENCE_FADE) -> void:
	play_ambience(null, fade)


func get_ambience() -> AudioStream:
	var current := _ambience[_ambience_active]
	return current.stream if current.playing else null


## Liga (ou troca) o zumbido. `null` desliga. O volume depende de `exposicao`.
func set_hum(stream: AudioStream, fade := AMBIENCE_FADE) -> void:
	if _hum_tween:
		_hum_tween.kill()
	_hum_tween = create_tween()
	if stream == null:
		_hum_tween.tween_property(self, "_hum_level", 0.0, fade)
		_hum_tween.tween_callback(_hum.stop)
		return
	if _hum.stream != stream:
		_hum.stream = stream
		_hum.play()
	elif not _hum.playing:
		_hum.play()
	_hum_tween.tween_property(self, "_hum_level", 1.0, fade)


func is_hum_on() -> bool:
	return _hum.playing and _hum_level > 0.0


## Som 2D avulso (interface, sons sem posição). Libera o player ao terminar.
func play_sfx(stream: AudioStream, volume_db := 0.0, bus: StringName = &"SFX") -> AudioStreamPlayer:
	if stream == null:
		return null
	var player := _make_player(bus)
	player.stream = stream
	player.volume_db = volume_db
	# Cada toque um pouco diferente (playtest 8: "genéricos"): a altura varia um fio.
	player.pitch_scale = randf_range(0.96, 1.04)
	player.finished.connect(player.queue_free)
	player.play()
	return player


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _fade_ambience(index: int, fade_in: bool, time: float) -> void:
	var player := _ambience[index]
	if _ambience_tweens[index]:
		_ambience_tweens[index].kill()
	var tween := create_tween()
	_ambience_tweens[index] = tween
	if fade_in:
		tween.tween_property(player, "volume_db", 0.0, time)
	else:
		tween.tween_property(player, "volume_db", -80.0, time)
		tween.tween_callback(player.stop)


func _update_whisper(e: float) -> void:
	if _hum.playing:
		var db := lerpf(HUM_DB.x, HUM_DB.y, e)
		_hum.volume_db = linear_to_db(db_to_linear(db) * _hum_level)
	if _lowpass:
		_lowpass.cutoff_hz = lerpf(HUM_CUTOFF_HZ.x, HUM_CUTOFF_HZ.y, e * e)
	if _distortion:
		_distortion.drive = lerpf(HUM_DRIVE.x, HUM_DRIVE.y, e * e)
	if _pitch:
		_pitch.pitch_scale = lerpf(HUM_PITCH.x, HUM_PITCH.y, e)
