extends Node
## Um único slot de checkpoint + "continuar" (GDD §10.6).
## Salva fase, ponto de entrada e GameState; não salva a posição exata.
## Os tipos (int, float, StringName) são preservados via JSON.from_native.

signal saved

## Incrementar invalida saves antigos (ex.: os da demo no jogo completo).
const VERSION := 1

## Checkpoint automático a cada troca de fase.
var autosave := true
## Trocável em testes para não sobrescrever o save do jogador.
var save_path := "user://save.json"


func _ready() -> void:
	SceneDirector.level_changed.connect(func(_path: String) -> void:
		if autosave:
			checkpoint())


func has_save() -> bool:
	return not _read().is_empty()


func checkpoint() -> void:
	if SceneDirector.current_level.is_empty():
		push_warning("Checkpoint sem fase carregada.")
		return
	var data := {
		"version": VERSION,
		"level": SceneDirector.current_level,
		"spawn": SceneDirector.current_spawn,
		"state": GameState.to_dict(),
	}
	# Grava num temporário e renomeia: um crash no meio não corrompe o save.
	var tmp := save_path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível salvar: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(JSON.from_native(data), "\t"))
	file.close()
	var err := DirAccess.rename_absolute(tmp, save_path)
	if err != OK:
		push_error("Não foi possível salvar: %s" % error_string(err))
		return
	saved.emit()


## Restaura o estado e recarrega a fase do checkpoint.
func load_game() -> bool:
	var data := _read()
	if data.is_empty():
		return false
	GameState.from_dict(data["state"])
	await SceneDirector.change_level(data["level"], data["spawn"])
	return true


func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)


## Vazio se não houver save, se estiver corrompido ou se for de outra versão.
func _read() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed == null:
		push_warning("Save corrompido em %s." % save_path)
		return {}
	var data: Variant = JSON.to_native(parsed)
	if not data is Dictionary or data.get("version") != VERSION:
		return {}
	return data
