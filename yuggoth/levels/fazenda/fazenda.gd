class_name Fazenda
extends Node3D
## A fazenda de Henry Akeley, na encosta da Dark Mountain (docs/PLANO_FAZENDA.md).
## A mesma planta serve ao Interlúdio (habitada, setembro de 1928, jogando como
## Akeley) e ao Ato III (abandonada, Wilmarth).
##
## F2, o entardecer de 2 de setembro: o sol baixo a oeste vai para trás da
## montanha, o quintal escurece e o céu passa do laranja ao crepúsculo
## (`entardecer`, 0 → 1 em `duracao_entardecer`). Vinda do escritório (a flag
## `interludio`, posta quando a última carta é postada), a tinta da carta cai no
## quintal (TintaTransicao.revelar): Akeley está diante do canil com o balde de
## ração. Até os beats existirem (F5–F8), a demo acaba aqui depois de
## `fim_provisorio` segundos. Pelo F4 de teste, a fazenda é só para andar.
##
## Cena gerada por tools/gerar_fazenda.gd.

@export var som: AudioStream
@export var linha_fim: NarrationLine
## Segundos no quintal antes do fim provisório da demo (só no Interlúdio).
@export var fim_provisorio := 45.0
## Segundos do sol baixo ao crepúsculo.
@export var duracao_entardecer := 180.0

@export_group("Entardecer: começo e fim")
@export var sol_energia := Vector2(1.3, 0.0)
@export var sol_cor := Color(1.0, 0.62, 0.36)
@export var ceu_alto: Array[Color] = [Color(0.16, 0.18, 0.34), Color(0.035, 0.045, 0.1)]
@export var ceu_horizonte: Array[Color] = [Color(0.88, 0.5, 0.3), Color(0.36, 0.2, 0.19)]
@export var neblina: Array[Color] = [Color(0.62, 0.46, 0.38), Color(0.12, 0.12, 0.17)]
@export var ambiente := Vector2(0.5, 0.16)

## 0 = o sol baixo; 1 = o crepúsculo.
var entardecer := 0.0
var _env: Environment
var _ceu: ProceduralSkyMaterial
var _aplicado := -1.0

@onready var player: Player = $Player
@onready var sol: DirectionalLight3D = $Sol
@onready var balde: NaMao = $Balde


func _ready() -> void:
	player.lamp.available = false
	# O Environment é recurso da cena (compartilhado com a próxima instância):
	# o entardecer mexe numa cópia.
	var we := $WorldEnvironment as WorldEnvironment
	_env = we.environment.duplicate(true)
	we.environment = _env
	_ceu = _env.sky.sky_material as ProceduralSkyMaterial
	_aplicar(0.0)
	if som:
		AudioDirector.play_ambience(som)
	var akeley := GameState.has_flag(&"interludio")
	balde.visible = akeley
	balde.process_mode = Node.PROCESS_MODE_INHERIT if akeley else Node.PROCESS_MODE_DISABLED
	if akeley:
		_interludio()


func _process(delta: float) -> void:
	entardecer = minf(1.0, entardecer + delta / duracao_entardecer)
	# O céu refaz a radiância quando muda: só a cada passo visível.
	if absf(entardecer - _aplicado) > 0.004:
		_aplicar(entardecer)


func _aplicar(p: float) -> void:
	_aplicado = p
	var some := smoothstep(0.0, 0.6, p)
	sol.light_energy = lerpf(sol_energia.x, sol_energia.y, some)
	sol.light_color = sol_cor.lerp(Color(0.9, 0.42, 0.3), some)
	sol.visible = sol.light_energy > 0.01
	_ceu.sky_top_color = ceu_alto[0].lerp(ceu_alto[1], p)
	_ceu.sky_horizon_color = ceu_horizonte[0].lerp(ceu_horizonte[1], smoothstep(0.2, 1.0, p))
	_ceu.ground_horizon_color = _ceu.sky_horizon_color.darkened(0.5)
	_env.fog_light_color = neblina[0].lerp(neblina[1], p)
	_env.ambient_light_energy = lerpf(ambiente.x, ambiente.y, p)


## O Interlúdio na demo, por enquanto: um tempo no quintal ao entardecer, e o fim.
func _interludio() -> void:
	# Parado na pausa (o timer não corre com a árvore pausada).
	await get_tree().create_timer(fim_provisorio, false).timeout
	if not is_inside_tree():
		return
	await SceneDirector.fade_out(2.0)
	if not is_inside_tree():
		return
	SceneDirector.hold_black = true
	await Narrator.say(linha_fim, Narrator.Style.CARTAO)
	if not is_inside_tree():
		return
	Events.quit_to_menu_requested.emit()
