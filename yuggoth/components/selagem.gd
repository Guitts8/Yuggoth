class_name Selagem
extends Node3D
## Selar a carta na mesa, devagar (docs/PLANO_ESCRITORIO.md, Fase 3c): a folha
## escrita está deitada no mata-borrão; dobra-se em três, de baixo e de cima; o
## envelope desliza para junto dela, de costas, a aba aberta; a folha entra; a
## aba fecha; o envelope vira (o endereço de Akeley) e leva o selo; e sobe para a
## mão. Wilmarth senta à mesa para isso e não se mexe enquanto dura.
##
## `await Selagem.new().tocar(...)`: devolve o Envelope, já no lugar da mão (quem
## chama o troca pela CartaSaida). Peças montadas em código; nada vai para o .tscn.

const FOLHA := Vector2(0.18, 0.27)
const ESPESSURA := 0.0015
## Ângulo da aba aberta (em torno da dobra, do lado de fora).
const ABA_ABERTA := 172.0

var _som_papel: AudioStream
var _som_selo: AudioStream


## `onde`: a folha deitada (o envelope fica 0,25 m à frente, para +Z).
func tocar(pai: Node3D, onde: Transform3D, reply: ReplyData, player: Player, som_papel: AudioStream, som_selo: AudioStream) -> Envelope:
	_som_papel = som_papel
	_som_selo = som_selo
	name = "Selagem"
	pai.add_child(self)
	global_transform = onde

	var papel := _material("res://art/materials/papel.tres")
	var envelope_mat := _material("res://art/materials/envelope.tres")

	# A folha: três painéis; os de fora giram em torno das dobras.
	var folha := Node3D.new()
	folha.name = "Folha"
	add_child(folha)
	var terco := FOLHA.y / 3.0
	_painel(folha, Vector3.ZERO, terco, papel)
	var baixo := _dobra(folha, Vector3(0, ESPESSURA, terco / 2), terco / 2, papel)
	var cima := _dobra(folha, Vector3(0, ESPESSURA * 2, -terco / 2), -terco / 2, papel)

	# O envelope, de costas (a frente para baixo), com a aba aberta.
	var env := Envelope.new()
	env.name = "Envelope"
	env.volumoso = true
	env.selos = 0
	env.carimbo_data = ""
	env.destinatario = reply.endereco
	env.remetente = "A. N. Wilmarth\nMiskatonic University\nArkham, Mass."
	add_child(env)
	var junto := Vector3(0, env.espessura() * 0.5, 0.25)
	env.transform = Transform3D(Basis.from_euler(Vector3(0, 0, PI)), junto + Vector3(-0.5, 0.0, 0.0))
	var aba := _aba(env, envelope_mat)
	aba.rotation_degrees.x = ABA_ABERTA
	env.visible = false

	# Wilmarth senta à mesa (a cadeira, de frente para a folha) e olha para ela.
	# Sentado, a cabeça desce devagar (Player._update_head); andar o levanta.
	var cadeira := global_transform * Vector3(0, 0, 0.72)
	cadeira.y = player.global_position.y
	var t0 := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t0.tween_property(player, ^"global_position", cadeira, 1.2)
	player.seated = true
	var olhar := _olhar(player, global_transform * Vector3(0, 0, 0.12), 1.4)
	await olhar.finished
	if not is_inside_tree():
		return null

	await _girar(baixo, -177.0, 1.1)
	await _pausa(0.3)
	await _girar(cima, 175.0, 1.1)
	await _pausa(0.4)

	# O envelope chega pela esquerda e para junto da folha.
	env.visible = true
	var t := _tween()
	t.tween_property(env, ^"position", junto, 1.1).set_ease(Tween.EASE_OUT)
	_tocar(_som_papel)
	await t.finished
	await _pausa(0.3)

	# A folha dobrada desliza até a boca do envelope, na altura de dentro dele, e entra.
	var boca := junto + Vector3(0, -0.003, -Envelope.ALTURA * 0.5 - terco * 0.5 - 0.012)
	t = _tween()
	t.tween_property(folha, ^"position", boca, 0.9)
	await t.finished
	_tocar(_som_papel)
	t = _tween()
	t.tween_property(folha, ^"position", junto + Vector3(0, -0.003, 0.003), 1.2).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	folha.visible = false
	await _pausa(0.3)

	# A aba fecha por cima.
	await _girar(aba, 0.0, 0.8)
	await _pausa(0.4)

	# Vira o envelope: o endereço; e o selo, batido com a palma.
	t = _tween().set_parallel()
	t.tween_property(env, ^"position:y", junto.y + 0.06, 0.5)
	t.chain().tween_property(env, ^"rotation:z", 0.0, 0.8)
	t.chain().tween_property(env, ^"position:y", junto.y, 0.4)
	await t.finished
	aba.visible = false
	await _pausa(0.5)
	env.selos = 3 if reply.registrada else 1
	_tocar(_som_selo)
	t = _tween()
	t.tween_property(env, ^"position:y", junto.y - 0.003, 0.06)
	t.tween_property(env, ^"position:y", junto.y, 0.12)
	await t.finished
	await _pausa(0.9)

	# Para a mão.
	var camera := player.camera
	var de := env.global_transform
	t = _tween()
	t.tween_method(func(k: float) -> void:
		var mao := camera.global_transform * Transform3D(Basis.from_euler(CartaSaida.MAO_ROTACAO * PI / 180.0), CartaSaida.MAO_POSICAO)
		env.global_transform = de.interpolate_with(mao, k), 0.0, 1.0, 1.1).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	return env


func _tween() -> Tween:
	return create_tween().set_trans(Tween.TRANS_SINE)


func _pausa(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


func _girar(no: Node3D, graus: float, segundos: float) -> void:
	_tocar(_som_papel)
	var t := _tween().set_ease(Tween.EASE_IN_OUT)
	t.tween_property(no, ^"rotation_degrees:x", graus, segundos)
	await t.finished


func _tocar(som: AudioStream) -> void:
	if som:
		AudioDirector.play_sfx(som, -5.0)


## Vira o corpo e a cabeça do jogador, devagar, para `ponto`.
static func _olhar(player: Player, ponto: Vector3, segundos: float) -> Tween:
	var de := player.global_position
	var yaw := atan2(-(ponto.x - de.x), -(ponto.z - de.z))
	var olho := player.camera.global_position
	var pitch := atan2(ponto.y - olho.y, Vector2(ponto.x - olho.x, ponto.z - olho.z).length())
	var t := player.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, ^"rotation:y", player.rotation.y + angle_difference(player.rotation.y, yaw), segundos)
	t.tween_property(player.head, ^"rotation:x", clampf(pitch, deg_to_rad(-85.0), deg_to_rad(85.0)), segundos)
	return t


## Um terço da folha, deitado, centrado em `pos`.
func _painel(pai: Node3D, pos: Vector3, fundo: float, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(FOLHA.x, ESPESSURA, fundo)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)
	return mi


## A dobra: um pivô na linha da dobra, com o painel do lado de fora dela.
func _dobra(pai: Node3D, pivo: Vector3, para_fora: float, mat: Material) -> Node3D:
	var p := Node3D.new()
	p.position = pivo
	pai.add_child(p)
	_painel(p, Vector3(0, -ESPESSURA * (2 if para_fora < 0 else 1), para_fora), absf(para_fora) * 2.0, mat)
	return p


## A aba triangular nas costas do envelope (o -Y do Envelope), presa na borda de
## cima (-Z); fechada, aponta para o meio.
func _aba(env: Envelope, mat: Material) -> Node3D:
	var pivo := Node3D.new()
	pivo.name = "Aba"
	pivo.position = Vector3(0, -env.espessura() * 0.5 - 0.0006, -Envelope.ALTURA * 0.5)
	env.add_child(pivo)
	var w := Envelope.LARGURA * 0.5
	var ponta := Envelope.ALTURA * 0.62
	var verts := PackedVector3Array([Vector3(-w, 0, 0), Vector3(w, 0, 0), Vector3(0, 0, ponta),
		Vector3(w, 0, 0), Vector3(-w, 0, 0), Vector3(0, 0, ponta)])
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1), Vector2(1, 0), Vector2(0, 0), Vector2(0.5, 1)])
	var normais := PackedVector3Array([Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector3.UP, Vector3.UP, Vector3.UP])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normais
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	pivo.add_child(mi)
	return pivo


## O material da sala sem a UV de mundo (peças que se movem não podem "nadar"
## na textura).
static func _material(caminho: String) -> Material:
	var mat := (load(caminho) as ShaderMaterial).duplicate() as ShaderMaterial
	mat.set_shader_parameter(&"world_uv", false)
	return mat
