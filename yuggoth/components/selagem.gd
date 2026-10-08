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
## Ângulo da aba aberta (em torno da dobra, do lado de fora): deitada na mesa.
const ABA_ABERTA := 180.0
## Multiplica as durações (playtest 3: "levianamente mais rápido").
const RITMO := 0.8
## O campo de visão enquanto sela, sentado.
const FOV := 50.0

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

	# O envelope, de costas (a frente para baixo), com a aba aberta, deitada na
	# mesa: a folha passa por cima dela e entra no bolso (_bolso).
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
	var bolso := _bolso(env, envelope_mat)
	var aba := _aba(env, envelope_mat)
	# O envelope está de costas: o +Y dele é o chão. Aberta, a aba deita na mesa.
	var aba_fechada := aba.position.y
	aba.position.y = env.espessura() * 0.5 - 0.0006
	aba.rotation_degrees.x = ABA_ABERTA
	env.visible = false

	# Wilmarth senta à mesa (a cadeira, de frente para a folha) e olha para ela,
	# dali — não de onde estava de pé. Sentado, a cabeça desce devagar
	# (Player._update_head); andar o levanta.
	var cadeira := global_transform * Vector3(0, 0, 0.72)
	cadeira.y = player.global_position.y
	var t0 := player.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t0.tween_property(player, ^"global_position", cadeira, 1.2 * RITMO)
	player.seated = true
	# A vista se aperta na carta (como no diário); solta quando a carta sobe à mão.
	player.fov_forcado = FOV
	await player.olhar_para(global_transform * Vector3(0, 0, 0.14), 1.4 * RITMO, cadeira).finished
	if not is_inside_tree():
		return null

	await _girar(baixo, -177.0, 1.1)
	await _pausa(0.3)
	await _girar(cima, 175.0, 1.1)
	await _pausa(0.4)

	# O envelope chega pela esquerda e para junto da folha.
	env.visible = true
	var t := _tween()
	t.tween_property(env, ^"position", junto, 1.1 * RITMO).set_ease(Tween.EASE_OUT)
	_tocar(_som_papel)
	await t.finished
	await _pausa(0.3)

	# A folha dobrada vai até a boca do envelope, por cima da aba deitada, na
	# altura de dentro do bolso; e entra.
	var dentro := 0.003
	var boca := Vector3(junto.x, dentro, junto.z - Envelope.ALTURA * 0.5 - terco * 0.5 - 0.014)
	t = _tween()
	t.tween_property(folha, ^"position", boca, 0.9 * RITMO)
	await t.finished
	_tocar(_som_papel)
	t = _tween()
	t.tween_property(folha, ^"position", Vector3(junto.x, dentro, junto.z + 0.004), 1.2 * RITMO).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	folha.visible = false
	await _pausa(0.3)

	# A aba fecha por cima: sobe da mesa às costas do envelope enquanto dobra.
	_tocar(_som_papel)
	t = _tween().set_parallel()
	t.tween_property(aba, ^"rotation_degrees:x", 0.0, 0.8 * RITMO)
	t.tween_property(aba, ^"position:y", aba_fechada, 0.8 * RITMO)
	await t.finished
	# Fechado: o envelope volta a ser a peça inteira.
	bolso.queue_free()
	env.get_node(^"_Papel").visible = true
	await _pausa(0.4)

	# Vira o envelope: o endereço; e o selo, batido com a palma.
	t = _tween().set_parallel()
	t.tween_property(env, ^"position:y", junto.y + 0.06, 0.5 * RITMO)
	t.chain().tween_property(env, ^"rotation:z", 0.0, 0.8 * RITMO)
	t.chain().tween_property(env, ^"position:y", junto.y, 0.4 * RITMO)
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

	# Para a mão: ele ergue a cabeça junto (olhando a mesa, a mão ficaria dentro
	# dela), e o envelope sobe do tampo antes de vir.
	var camera := player.camera
	var de := env.global_transform
	var acima := de.translated(Vector3.UP * 0.12)
	player.fov_forcado = 0.0
	player.olhar_para(global_transform * Vector3(0, 0.45, -0.6), 1.3 * RITMO, cadeira)
	t = _tween()
	t.tween_method(func(k: float) -> void:
		var mao := camera.global_transform * Transform3D(Basis.from_euler(CartaSaida.MAO_ROTACAO * PI / 180.0), CartaSaida.MAO_POSICAO)
		var subido := de.interpolate_with(acima, minf(k * 2.0, 1.0))
		env.global_transform = subido.interpolate_with(mao, maxf(k * 2.0 - 1.0, 0.0)), 0.0, 1.0, 1.4 * RITMO).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	return env


func _tween() -> Tween:
	return create_tween().set_trans(Tween.TRANS_SINE)


func _pausa(segundos: float) -> void:
	await get_tree().create_timer(segundos * RITMO).timeout


func _girar(no: Node3D, graus: float, segundos: float) -> void:
	_tocar(_som_papel)
	var t := _tween().set_ease(Tween.EASE_IN_OUT)
	t.tween_property(no, ^"rotation_degrees:x", graus, segundos * RITMO)
	await t.finished


func _tocar(som: AudioStream) -> void:
	if som:
		AudioDirector.play_sfx(som, -5.0)


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


## Enquanto a folha entra, o envelope é oco: a frente (embaixo), as costas com a
## boca um pouco recuada da borda de cima, e as três bordas fechadas. O papel
## inteiro do Envelope some até a aba fechar.
func _bolso(env: Envelope, mat: Material) -> Node3D:
	env.get_node(^"_Papel").visible = false
	var b := Node3D.new()
	b.name = "Bolso"
	env.add_child(b)
	var e := env.espessura()
	var parede := 0.0008
	var recuo := 0.01
	var w := Envelope.LARGURA
	var h := Envelope.ALTURA
	for p: Array in [
			[Vector3(w, parede, h), Vector3(0, e * 0.5 - parede * 0.5, 0)],
			[Vector3(w, parede, h - recuo), Vector3(0, -e * 0.5 + parede * 0.5, recuo * 0.5)],
			[Vector3(parede, e, h), Vector3(-w * 0.5 + parede * 0.5, 0, 0)],
			[Vector3(parede, e, h), Vector3(w * 0.5 - parede * 0.5, 0, 0)],
			[Vector3(w, e, parede), Vector3(0, 0, h * 0.5 - parede * 0.5)]]:
		var mesh := BoxMesh.new()
		mesh.size = p[0]
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = p[1]
		b.add_child(mi)
	return b


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
