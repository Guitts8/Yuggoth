extends Node
## Estado narrativo: flags, variáveis ocultas (GDD §6.3) e dossiê.
## Variantes de documentos, diálogos, narrador e finais leem daqui.

signal value_changed(key: StringName, value: Variant)
signal dossier_changed

const DEFAULTS: Dictionary[StringName, Variant] = {
	&"dia": 1,
	&"crenca": 0,
	&"exposicao": 0.0,
	&"suspeita": 0,
	&"drogado": false,
	&"discrepancias": 0,
	## Visual de sonho (0–1), para sequências oníricas; não é variável oculta do GDD.
	## O GameRoot usa o maior entre isto e a exposição.
	&"sonho": 0.0,
}

## Valores fora da faixa são grampeados.
const RANGES: Dictionary[StringName, Vector2] = {
	&"crenca": Vector2(-4, 4),
	&"exposicao": Vector2(0, 1),
	&"suspeita": Vector2(0, 3),
	&"sonho": Vector2(0, 1),
}

var dossier: Array[DocumentData] = []

var _values: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	reset()


func reset() -> void:
	_values.clear()
	_values.merge(DEFAULTS)
	dossier.clear()
	dossier_changed.emit()


func get_value(key: StringName, default: Variant = null) -> Variant:
	return _values.get(key, default)


## Valor numérico; flags booleanas viram 1.0 / 0.0.
func get_number(key: StringName) -> float:
	return float(_values.get(key, 0))


func has_flag(key: StringName) -> bool:
	return bool(_values.get(key, false))


func set_flag(key: StringName, on := true) -> void:
	set_value(key, on)


func set_value(key: StringName, value: Variant) -> void:
	if RANGES.has(key):
		var r := RANGES[key]
		if value is float:
			value = clampf(value, r.x, r.y)
		else:
			value = clampi(int(value), int(r.x), int(r.y))
	if _values.has(key) and typeof(_values[key]) == typeof(value) and _values[key] == value:
		return
	_values[key] = value
	value_changed.emit(key, value)


## Soma preservando o tipo atual (int continua int).
func add(key: StringName, amount: float) -> void:
	var current: Variant = _values.get(key, 0)
	if current is float:
		set_value(key, current + amount)
	else:
		set_value(key, int(current) + roundi(amount))


func add_document(doc: DocumentData) -> void:
	if doc and doc not in dossier:
		dossier.append(doc)
		dossier_changed.emit()


func to_dict() -> Dictionary:
	return {
		"values": _values.duplicate(),
		"dossier": dossier.map(func(d: DocumentData) -> String: return d.resource_path),
	}


func from_dict(data: Dictionary) -> void:
	reset()
	var values: Dictionary = data.get("values", {})
	for k: String in values:
		var key := StringName(k)
		var v: Variant = values[k]
		# JSON não distingue int de float; o tipo padrão manda.
		if DEFAULTS.get(key) is int:
			v = int(v)
		_values[key] = v
	for path: String in data.get("dossier", []):
		var doc := load(path) as DocumentData
		if doc:
			dossier.append(doc)
	dossier_changed.emit()
