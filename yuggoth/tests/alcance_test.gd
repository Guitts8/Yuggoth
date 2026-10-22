extends "res://tests/smoke_test.gd"
## O alcance da fazenda (playtest 12: "a incapacidade de chegar até algumas
## venezianas e etc. A casa tem alguns locais inacessíveis por conta do modelo
## 3D"). O teste de fumaça põe Akeley diante de cada tarefa (teletransportado), e
## as venezianas que ele não fechava fecha de uma vez: não via os móveis no
## caminho. Este aqui não teletransporta nada:
##
## 1. Mapeia por onde o corpo anda, a partir do quintal: uma grade de 0,2 m em
##    que cada passo precisa de chão (subindo no máximo um degrau baixo ou uma
##    rampa) e da cápsula do Player inteira livre (camada `mundo`).
## 2. Para cada Interactable da fazenda (todas ligadas na física para o teste),
##    procura um lugar alcançável de onde o raio da mira (2 m, dos olhos de pé, ou
##    agachado) chega até ela sem o mundo no meio — as outras áreas não tampam,
##    como no Player (`_primeiro_utilizavel`).
## 3. Confere com a física de verdade: põe o Player uns metros antes pelo caminho
##    achado, anda até o lugar, mira, e vê se o raio do próprio Player a pega.
##
## Rodar com:  godot --headless --path . res://tests/alcance_test.tscn
## Sai com código = número de áreas fora de alcance. ALCANCE=Nome1,Nome2 limita
## às áreas com esses nomes.

const PASSO := 0.1
const SOBE := 0.12  ## o que o chão sobe de uma célula à seguinte (rampa, tapete)
## A cápsula se confere um tico acima do chão: a ponta redonda vence o que é mais
## baixo que isto (o pé de uma rampa, uma soleira), como o CharacterBody3D.
const SOBE_CAPSULA := 0.09
const DESCE := 1.2  ## de onde ainda se desce (a beira dos degraus)
const OLHOS := 1.62
const OLHOS_AGACHADO := 1.05
const ALCANCE := 2.0
## A região mapeada (a fazenda andável: LIMITE_X/LIMITE_Z do gerador).
const REGIAO_X := Vector2(-40.0, 34.0)
const REGIAO_Z := Vector2(-40.0, 32.0)
## Se o lugar mais perto de onde se alcança a área fica mais longe que isto (dos
## olhos ao meio dela), só se alcança da beira do alcance: na prática, não se acha.
const FOLGA := 1.6
## A distância à vontade para usar uma coisa (o lugar escolhido para andar até ela).
const CONFORTO := 1.1
## Quanto do caminho a física anda de verdade, antes do lugar achado.
const TRECHO := 7.0

var root: Node
var _space: PhysicsDirectSpaceState3D
var _player: Player
var _forma: CollisionShape3D
var _consulta := PhysicsShapeQueryParameters3D.new()
## Cada célula andável: chave → [posição do chão, chave de onde veio].
var _andavel: Dictionary[Vector3i, Array] = {}
## As células por coluna (x, z), para achar as perto de um ponto.
var _colunas: Dictionary[Vector2i, Array] = {}
var _todas: Array[Interactable] = []
## A normal (y) do chão achado pelo último `_chao`.
var _normal_y := 1.0


func _ready() -> void:
	SaveSystem.save_path = "user://alcance_test_save.json"
	SaveSystem.delete_save()
	Settings.settings_path = "user://alcance_test_settings.cfg"
	root = load("res://main/game_root.tscn").instantiate()
	root.boot_to_menu = false
	root.start_level = load("res://levels/test/test_room.tscn")
	add_child(root)
	if SceneDirector.is_busy:
		await SceneDirector.level_changed
	GameState.reset()
	await SceneDirector.change_level("res://levels/fazenda/fazenda.tscn", &"Quintal", false)
	await _seconds(1.0)
	var faz := root.find_child("Fazenda", true, false) as Fazenda
	_player = faz.player
	_space = _player.get_world_3d().direct_space_state
	_forma = _player.get_node(^"CollisionShape3D") as CollisionShape3D
	_consulta.shape = _forma.shape
	_consulta.collision_mask = 1
	_consulta.exclude = [_player.get_rid()]

	var t0 := Time.get_ticks_msec()
	_mapear(_player.global_position)
	print("ALCANCE %d lugares andáveis (%.1f s)" % [_andavel.size(), (Time.get_ticks_msec() - t0) / 1000.0])

	var mapa := OS.get_environment("MAPA").split(",", false)
	if mapa.size() == 5:
		_desenhar(Vector2(float(mapa[0]), float(mapa[1])), Vector2(float(mapa[2]), float(mapa[3])), float(mapa[4]))
	for s in OS.get_environment("SONDA").split(";", false):
		var v := s.split(",")
		_sondar(Vector3(float(v[0]), float(v[1]), float(v[2])))
	# As portas, nos dois sentidos (playtest 12: "algumas portas só funcionam para
	# sair e não para entrar"). PORTAS=so roda só elas.
	await _portas(faz)
	if OS.get_environment("PORTAS") == "so":
		get_tree().quit(_failures)
		return
	var so := OS.get_environment("ALCANCE").split(",", false)
	for a: Interactable in faz.find_children("*", "Interactable", true, false):
		# A porteira de passar (no mesmo lugar que a de soltar os cães, que se alcança)
		# liga-se sozinha conforme o lado de Akeley; o teste de fumaça a usa.
		if a is PassarPorteira:
			continue
		if so.is_empty() or a.name in so:
			_todas.append(a)
	# Todas valem para o teste (cada uma só vale na sua hora: fora dela, sai da física).
	for a in _todas:
		a.collision_layer = Interactable.LAYER_INTERACAO
	await _frames(2)

	var fora: Array[String] = []
	for a in _todas:
		var nome := String(faz.get_path_to(a))
		var achado := _achar(a)
		if achado.is_empty():
			fora.append(nome)
			_check(false, "%s (\"%s\"): nenhum lugar de onde se alcance" % [nome, a.prompt])
			continue
		var de_verdade: String = await _andar_ate(a, achado)
		var agachado := " (só agachado)" if achado[2] else ""
		if achado[5] > FOLGA:
			fora.append(nome)
			_check(false, "%s (\"%s\"): só da beira do alcance — o mais perto é a %.2f m, de %s" % [nome, a.prompt, achado[5], achado[0].snappedf(0.01)])
		elif de_verdade.is_empty():
			_check(true, "%s (\"%s\")%s de %s, a %.2f m (o mais perto a %.2f m)" % [nome, a.prompt, agachado, achado[0].snappedf(0.01), achado[3], achado[5]])
			# Playtest 12, depois: "trancar as venezianas te deixa preso entre os
			# móveis". A cena o leva até a janela sem a física: depois, ele ainda sai dali?
			if a is Venezianas:
				var preso: String = await _depois_de_usar(a)
				_check(preso.is_empty(), "%s: depois de fechar, %s" % [nome, "sai dali andando" if preso.is_empty() else preso])
		else:
			fora.append(nome)
			_check(false, "%s (\"%s\"): achado de %s, mas andando: %s" % [nome, a.prompt, achado[0].snappedf(0.01), de_verdade])
	print("ALCANCE fora de alcance (%d): %s" % [fora.size(), ", ".join(fora)])
	_bolsoes()
	get_tree().quit(_failures)


# --- 1. Por onde o corpo anda -------------------------------------------------------

func _chave(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x / PASSO), roundi(p.z / PASSO), roundi(p.y))


func _mapear(de: Vector3) -> void:
	var chao := _chao(de.x, de.z, de.y)
	if chao == Vector3.INF:
		push_error("ALCANCE: o quintal sem chão")
		return
	var k0 := _chave(chao)
	_andavel[k0] = [chao, k0]
	var fila: Array[Vector3i] = [k0]
	var i := 0
	while i < fila.size():
		var k := fila[i]
		i += 1
		var aqui: Vector3 = _andavel[k][0]
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var x := (k.x + d.x) * PASSO
			var z := (k.y + d.y) * PASSO
			if x < REGIAO_X.x or x > REGIAO_X.y or z < REGIAO_Z.x or z > REGIAO_Z.y:
				continue
			var la := _chao(x, z, aqui.y)
			if la == Vector3.INF or la.y - aqui.y > SOBE or aqui.y - la.y > DESCE:
				continue
			var kl := _chave(la)
			if _andavel.has(kl) or not _cabe(la):
				continue
			_andavel[kl] = [la, k]
			var col := Vector2i(kl.x, kl.y)
			if not _colunas.has(col):
				_colunas[col] = []
			_colunas[col].append(kl)
			fila.append(kl)
	var col0 := Vector2i(k0.x, k0.y)
	if not _colunas.has(col0):
		_colunas[col0] = []
	_colunas[col0].append(k0)


## O chão em (x, z) logo abaixo de quem está na altura `y` (INF: nenhum, ou
## inclinado demais para ficar de pé).
func _chao(x: float, z: float, y: float) -> Vector3:
	# Um raio que cai bem na quina de uma laje volta com a normal da face do lado:
	# o segundo, um tico ao lado, desempata.
	for d: Vector2 in [Vector2.ZERO, Vector2(0.013, 0.017)]:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x + d.x, y + SOBE + 0.3, z + d.y), Vector3(x + d.x, y - DESCE - 0.1, z + d.y), 1, [_player.get_rid()])
		var r := _space.intersect_ray(q)
		if r.is_empty():
			return Vector3.INF
		_normal_y = (r["normal"] as Vector3).y
		if _normal_y >= cos(deg_to_rad(46.0)):
			var p: Vector3 = r["position"]
			return Vector3(x, p.y, z)
	return Vector3.INF


## Os cômodos onde se procuram bolsões: [nome, x, z, altura do piso].
const COMODOS := [
	["térreo da casa", Vector2(-2.8, 5.8), Vector2(-5.8, 5.8), 0.6],
	["cozinha e despensa", Vector2(-8.8, -3.0), Vector2(1.2, 5.8), 0.6],
	["primeiro andar", Vector2(-2.8, 5.8), Vector2(-5.8, 5.8), 3.75],
]
## Um bolsão maior que isto (m²) é um lugar da casa aonde não se chega.
const BOLSAO := 0.5


## Os lugares da casa aonde não se chega: chão livre, onde o corpo cabe, mas fora
## do mapa do que se anda. Os pequenos (atrás de uma cama, num canto) só se listam.
func _bolsoes() -> void:
	for c: Array in COMODOS:
		var nome: String = c[0]
		var cx: Vector2 = c[1]
		var cz: Vector2 = c[2]
		var y: float = c[3]
		var livres: Dictionary[Vector2i, bool] = {}
		for ix in range(ceili(cx.x / PASSO), floori(cx.y / PASSO) + 1):
			for iz in range(ceili(cz.x / PASSO), floori(cz.y / PASSO) + 1):
				if _andavel.has(Vector3i(ix, iz, roundi(y))):
					continue
				var chao := _chao(ix * PASSO, iz * PASSO, y)
				if chao != Vector3.INF and absf(chao.y - y) < 0.1 and _cabe(chao):
					livres[Vector2i(ix, iz)] = true
		var vistos: Dictionary[Vector2i, bool] = {}
		for k: Vector2i in livres:
			if vistos.has(k):
				continue
			var fila: Array[Vector2i] = [k]
			vistos[k] = true
			var de := Vector2(INF, INF)
			var ate := Vector2(-INF, -INF)
			var i := 0
			while i < fila.size():
				var q := fila[i]
				i += 1
				de = de.min(Vector2(q) * PASSO)
				ate = ate.max(Vector2(q) * PASSO)
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n := q + d
					if livres.has(n) and not vistos.has(n):
						vistos[n] = true
						fila.append(n)
			var area := fila.size() * PASSO * PASSO
			var onde := "%s: x %.1f..%.1f, z %.1f..%.1f (%.2f m²)" % [nome, de.x, ate.x, de.y, ate.y, area]
			if area > BOLSAO:
				_check(false, "um lugar aonde não se chega — " + onde)
			elif area > 0.1:
				print("  (um cantinho aonde não se chega — %s)" % onde)


## MAPA=x0,z0,x1,z1,y: o que se anda no retângulo, no andar da altura y (o norte em
## cima): "." andável, "#" o corpo não cabe, " " fora do mapa.
func _desenhar(de: Vector2, ate: Vector2, y: float) -> void:
	print("MAPA x %.1f..%.1f (esquerda → direita), z %.1f..%.1f (cima → baixo), y %.2f" % [de.x, ate.x, de.y, ate.y, y])
	for iz in range(roundi(de.y / PASSO), roundi(ate.y / PASSO) + 1):
		var linha := "%6.1f " % (iz * PASSO)
		for ix in range(roundi(de.x / PASSO), roundi(ate.x / PASSO) + 1):
			var chao := _chao(ix * PASSO, iz * PASSO, y)
			if _andavel.has(Vector3i(ix, iz, roundi(y))):
				linha += "."
			elif chao != Vector3.INF and absf(chao.y - y) < 0.3 and not _cabe(chao):
				linha += "#"
			else:
				linha += " "
		print(linha)


## SONDA=x,y,z;...: o que não deixa o corpo caber em cada ponto (a forma de
## colisão: o nó, o centro, o tamanho).
func _sondar(chao: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(chao + Vector3.UP * (SOBE + 0.3), chao - Vector3.UP * (DESCE + 0.1), 1, [_player.get_rid()])
	var c := _space.intersect_ray(q)
	_normal_y = (c.get("normal", Vector3.UP) as Vector3).y
	_cabe(chao)
	var r := _space.intersect_shape(_consulta, 8)
	print("SONDA %s: %d; chão %s %s; no mapa: %s" % [chao, r.size(), c.get("position", "nenhum"), c.get("normal", ""), _andavel.has(_chave(chao))])
	for h in r:
		var co := h["collider"] as CollisionObject3D
		var dono := co.shape_find_owner(h["shape"])
		var cs := co.shape_owner_get_owner(dono) as CollisionShape3D
		var box := cs.shape as BoxShape3D if cs else null
		print("   %s %s %s" % [co.name, cs.global_position.snappedf(0.01) if cs else "?", box.size.snappedf(0.01) if box else cs.shape if cs else "?"])


func _cabe(chao: Vector3) -> bool:
	# Numa rampa, a ponta redonda da cápsula encostaria no chão inclinado: sobe o
	# que a inclinação pede (`_normal_y`, do último `_chao`).
	var folga := maxf(SOBE_CAPSULA, 0.05 + 0.3 * (1.0 / maxf(_normal_y, 0.5) - 1.0))
	_consulta.transform = Transform3D(Basis.IDENTITY, chao + Vector3.UP * folga) * _forma.transform
	return _space.intersect_shape(_consulta, 1).is_empty()


# --- As portas ---------------------------------------------------------------------

## Cada porta da fazenda: [nome, de fora, o vão, de dentro] (x, z; a altura vem do
## chão achado perto de `y`, que é a do andar). O mapa do passo 1 sai do quintal e
## só precisa de UMA entrada para chegar a cada cômodo: uma porta que só se desce
## (sem rampa de verdade do lado de fora) passava despercebida.
func _lista_portas(faz: Fazenda) -> Array:
	var t0 := 0.6
	var t1 := 3.75
	var lista := [
		["a porta da frente", Vector3(9.0, 0, 0.0), Vector3(6.0, t0, 0.0), Vector3(4.2, t0, 0.0)],
		["a porta dos fundos", Vector3(-5.6, 0, -0.3), Vector3(-3.0, t0, 0.0), Vector3(-1.6, t0, 0.0)],
		["a porta da cozinha (quintal)", Vector3(-6.5, 0, -1.6), Vector3(-6.5, t0, 1.0), Vector3(-6.2, t0, 2.4)],
		["a porta da cozinha (galpão)", Vector3(-10.8, 0, 4.6), Vector3(-9.0, t0, 4.6), Vector3(-7.6, t0, 4.4)],
		["a sala de jantar e a cozinha", Vector3(-4.6, t0, 3.7), Vector3(-3.0, t0, 3.7), Vector3(-2.2, t0, 2.6)],
		["o escritório", Vector3(5.1, t0, 0.3), Vector3(5.1, t0, 1.4), Vector3(5.1, t0, 2.5)],
		["a sala de estar", Vector3(5.1, t0, -0.3), Vector3(5.1, t0, -1.4), Vector3(5.1, t0, -2.5)],
		["a sala de jantar", Vector3(-1.5, t0, 0.3), Vector3(-1.5, t0, 1.4), Vector3(-1.5, t0, 2.5)],
		["a sala dos fundos", Vector3(-1.5, t0, -0.3), Vector3(-1.5, t0, -1.4), Vector3(-1.5, t0, -2.5)],
		["o escritório e a sala de jantar", Vector3(1.9, t0, 2.15), Vector3(1.0, t0, 2.15), Vector3(0.0, t0, 2.15)],
		["o quarto de hóspedes", Vector3(3.0, t1, 0.4), Vector3(3.0, t1, 1.4), Vector3(3.0, t1, 2.5)],
		["o quarto de Akeley", Vector3(5.1, t1, 0.2), Vector3(5.1, t1, -1.4), Vector3(5.1, t1, -2.5)],
		["o quarto do sul, de trás", Vector3(-0.38, t1, 0.4), Vector3(-0.38, t1, 1.4), Vector3(-0.38, t1, 2.5)],
		["o quarto do norte, de trás", Vector3(-0.38, t1, 0.0), Vector3(-0.38, t1, -1.4), Vector3(-0.38, t1, -2.5)],
		["o banheiro", Vector3(-0.3, t1, 0.0), Vector3(-1.0, t1, 0.0), Vector3(-1.55, t1, 0.0)],
	]
	# As das dependências: de onde o gerador as pôs (metas da cena).
	for n: Node3D in faz.find_children("*", "Node3D", true, false):
		if n.has_meta(&"porta_teste"):
			var p: Array = n.get_meta(&"porta_teste")
			lista.append([p[0], p[1], p[2], p[3]])
	return lista


func _portas(faz: Fazenda) -> void:
	var p := _player
	# A porteira do cercado só se passa aberta (a preparação a abre).
	var porteira := faz.get_node_or_null(^"Porteira") as Node3D
	if porteira:
		porteira.rotation_degrees.y = 100.0
		await _frames(2)
	for porta: Array in _lista_portas(faz):
		var nome: String = porta[0]
		for sentido in 2:
			var de: Vector3 = porta[1] if sentido == 0 else porta[3]
			var ate: Vector3 = porta[3] if sentido == 0 else porta[1]
			var chao := _chao(de.x, de.z, de.y)
			if chao == Vector3.INF:
				_check(false, "%s: sem chão em %s" % [nome, de])
				continue
			p.global_position = chao + Vector3.UP * 0.05
			p.velocity = Vector3.ZERO
			p.look_at(Vector3(porta[2].x, p.global_position.y, porta[2].z))
			await _frames(3)
			var erro: String = await _andar_reto(p, [porta[2], ate])
			var verbo := "entrar" if sentido == 0 else "sair"
			_check(erro.is_empty(), "PORTA %s: %s%s" % [nome, verbo, "" if erro.is_empty() else " — " + erro])
	Input.action_release(&"mover_frente")
	if porteira:
		porteira.rotation_degrees.y = 0.0
		await _frames(2)


## Anda pelos `pontos` (x, z; y é o andar esperado) como o jogador, com a física;
## "" se chega ao último no andar certo.
func _andar_reto(p: Player, pontos: Array) -> String:
	var t := 0.0
	var parado := 0.0
	for alvo: Vector3 in pontos:
		while true:
			var q := p.global_position
			if Vector2(q.x - alvo.x, q.z - alvo.z).length() < 0.2:
				break
			p.look_at(Vector3(alvo.x, q.y, alvo.z))
			Input.action_press(&"mover_frente")
			await get_tree().physics_frame
			var dt := get_physics_process_delta_time()
			t += dt
			parado = parado + dt if p.global_position.distance_to(q) < 0.004 else 0.0
			if parado > 1.2 or t > 25.0:
				Input.action_release(&"mover_frente")
				return "preso em %s indo para %s" % [p.global_position.snappedf(0.01), alvo.snappedf(0.01)]
	Input.action_release(&"mover_frente")
	await _frames(4)
	var fim: Vector3 = pontos[-1]
	if absf(p.global_position.y - fim.y) > 0.2:
		return "chegou na altura errada (%.2f, esperava %.2f)" % [p.global_position.y, fim.y]
	return ""


# --- 2. De onde se alcança cada área -----------------------------------------------

## Os pontos da área para onde se mira: o meio e o meio de cada face, um pouco
## para dentro.
func _pontos(a: Interactable) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for c in a.get_children():
		var cs := c as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var t := cs.global_transform
		pts.append(t.origin)
		var box := cs.shape as BoxShape3D
		if box:
			var m := box.size * 0.35
			for e: Vector3 in [Vector3(m.x, 0, 0), Vector3(-m.x, 0, 0), Vector3(0, m.y, 0), Vector3(0, -m.y, 0), Vector3(0, 0, m.z), Vector3(0, 0, -m.z)]:
				pts.append(t * e)
	return pts


## O raio da mira dos `olhos` ao `ponto` (até ALCANCE) pega a área `a` primeiro?
func _ve(olhos: Vector3, ponto: Vector3, a: Interactable, excluir: Array[RID]) -> bool:
	var dir := (ponto - olhos).normalized()
	var fim := olhos + dir * ALCANCE
	var ex := excluir.duplicate()
	for i in 8:
		var q := PhysicsRayQueryParameters3D.create(olhos, fim, 3, ex)
		q.collide_with_areas = true
		var r := _space.intersect_ray(q)
		if r.is_empty():
			return false
		var c: Object = r["collider"]
		if c == a:
			return true
		if c is Interactable:
			ex.append((c as CollisionObject3D).get_rid())
			continue
		return false
	return false


## [chão de onde, ponto mirado, agachado?, distância, chave, a distância do lugar mais
## perto] do lugar mais à vontade (a distância mais perto de CONFORTO, de pé antes de
## agachado); vazio se nenhum.
func _achar(a: Interactable) -> Array:
	var pts := _pontos(a)
	if pts.is_empty():
		return []
	var centro := pts[0]
	var excluir: Array[RID] = [_player.get_rid()]
	var raio := ALCANCE + 0.8
	var r := ceili(raio / PASSO)
	var cx := roundi(centro.x / PASSO)
	var cz := roundi(centro.z / PASSO)
	var melhor := []
	var perto := INF
	for olhos_h: float in [OLHOS, OLHOS_AGACHADO]:
		for ix in range(cx - r, cx + r + 1):
			for iz in range(cz - r, cz + r + 1):
				var col := Vector2i(ix, iz)
				if not _colunas.has(col):
					continue
				for k: Vector3i in _colunas[col]:
					var chao: Vector3 = _andavel[k][0]
					var olhos := chao + Vector3.UP * olhos_h
					var dist := olhos.distance_to(centro)
					if dist > raio:
						continue
					# Só interessa um lugar mais perto do que o mais perto já visto,
					# ou mais à vontade (mais perto de CONFORTO) do que o escolhido.
					var conforto := absf(dist - CONFORTO)
					if dist >= perto and not melhor.is_empty() and conforto >= absf(melhor[3] - CONFORTO):
						continue
					for p in pts:
						if _ve(olhos, p, a, excluir):
							perto = minf(perto, dist)
							if melhor.is_empty() or conforto < absf(melhor[3] - CONFORTO):
								melhor = [chao, p, olhos_h < OLHOS, dist, k]
							break
		if not melhor.is_empty():
			return melhor + [perto]
	return melhor


# --- 3. Com a física de verdade -----------------------------------------------------

## Usa `a` (o Player já diante dela) e espera a cena devolver o controle; "" se ele
## fica num lugar do mapa, cabe ali e anda 1,5 m pelo caminho do mapa até o quintal.
func _depois_de_usar(a: Interactable) -> String:
	var p := _player
	p.input_enabled = true
	a.interact(p)
	var t := 0.0
	while not p.input_enabled and t < 20.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	if not p.input_enabled:
		return "a cena não devolveu o controle"
	await _frames(3)
	var aqui := p.global_position
	if not p.livre(aqui):
		return "parou dentro de algo em %s" % aqui.snappedf(0.01)
	var k := _chave(aqui)
	var achou := Vector3i.MAX
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var kk := k + Vector3i(dx, dz, 0)
			if _andavel.has(kk):
				achou = kk
	if achou == Vector3i.MAX:
		return "parou fora do que se anda (num canto fechado) em %s" % aqui.snappedf(0.01)
	var pontos := []
	for passo in 15:
		var c: Array = _andavel[achou]
		if c[1] == achou:
			break
		achou = c[1]
		if passo % 3 == 2:
			pontos.append(_andavel[achou][0])
	if pontos.is_empty():
		return ""
	var erro: String = await _andar_reto(p, pontos)
	return "" if erro.is_empty() else "não sai dali: " + erro

## Põe o Player TRECHO metros antes pelo caminho achado, anda até o lugar e mira;
## "" se o raio do Player pega a área, senão o que deu errado.
func _andar_ate(a: Interactable, achado: Array) -> String:
	var caminho: Array[Vector3] = []
	var k: Vector3i = achado[4]
	var andado := 0.0
	while true:
		var c: Array = _andavel[k]
		caminho.push_front(c[0])
		if c[1] == k or andado > TRECHO:
			break
		andado += PASSO
		k = c[1]
	var p := _player
	p.input_enabled = true
	p.global_position = caminho[0]
	p.velocity = Vector3.ZERO
	await _frames(3)
	var parado := 0.0
	var t := 0.0
	var i := 1
	while i < caminho.size():
		var alvo := caminho[mini(i + 2, caminho.size() - 1)]
		var q := p.global_position
		if Vector2(q.x - alvo.x, q.z - alvo.z).length() < 0.15:
			i += 3
			continue
		p.look_at(Vector3(alvo.x, q.y, alvo.z))
		Input.action_press(&"mover_frente")
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		parado = parado + dt if p.global_position.distance_to(q) < 0.003 else 0.0
		if parado > 1.0 or t > 40.0:
			Input.action_release(&"mover_frente")
			return "preso em %s indo para %s" % [p.global_position.snappedf(0.01), alvo.snappedf(0.01)]
	Input.action_release(&"mover_frente")
	await _frames(4)
	if achado[2]:
		Input.action_press(&"agachar")
		await _seconds(0.8)
	await _mirar(p, achado[1])
	var olhos := p.camera.global_position
	var ok := _ve(olhos, achado[1], a, [p.get_rid()] as Array[RID])
	Input.action_release(&"agachar")
	if not ok:
		var c: Object = p.ray.get_collider()
		return "parou em %s e a mira pegou %s" % [p.global_position.snappedf(0.01), c.name if c else "nada"]
	return ""
