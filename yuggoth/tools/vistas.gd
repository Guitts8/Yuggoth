extends RefCounted
## As vistas em 3D que não são Arkham (docs/PLANO_ESCRITORIO.md, Fase 3e: "o que
## acontece na janela do lado de fora nos sonhos também deve estar em 3D"; "a
## janelinha do apartamento do funcionário também"): o círculo de pedras da
## noite 2, a plataforma de Keene da noite 4 e os telhados de Boston. E o bosque
## do disco (noite 3), que toma o lugar da sala.
##
## O mesmo feitio da cidade (tools/cidade_arkham.gd): malhas low-poly de cor por
## vértice com o shader da cidade e a luz de cada vista. As coordenadas são as da
## sala: a janela fica a -Z. O bosque, que se atravessa a pé, usa o material PSX
## iluminado (a lanterna de Akeley e a lua o iluminam).

const Cidade = preload("res://tools/cidade_arkham.gd")

## A luz de cada vista, no formato de Cidade.HORAS.
const LUZES := {
	"lua": {
		sol_dir = Vector3(-0.35, 0.55, 0.5), sol_cor = Color(0.3, 0.36, 0.55), ambiente = Color(0.05, 0.06, 0.1),
		neblina_cor = Color(0.06, 0.07, 0.12), neblina_de = 25.0, neblina_ate = 130.0, neblina_max = 0.85,
		topo = Color(0.02, 0.03, 0.07), horizonte = Color(0.1, 0.11, 0.18), nuvens = 0.2, nuvem_cor = Color(0.14, 0.15, 0.2), estrelas = 1.0,
		acesas = 1.0, vidro = Color(0.03, 0.035, 0.05),
	},
	"estacao": {
		sol_dir = Vector3(0.1, 0.8, 0.6), sol_cor = Color(0.5, 0.42, 0.3), ambiente = Color(0.05, 0.05, 0.07),
		neblina_cor = Color(0.05, 0.05, 0.07), neblina_de = 12.0, neblina_ate = 60.0, neblina_max = 0.92,
		topo = Color(0.015, 0.02, 0.04), horizonte = Color(0.05, 0.05, 0.08), nuvens = 0.5, nuvem_cor = Color(0.07, 0.07, 0.09), estrelas = 0.4,
		acesas = 1.0, vidro = Color(0.02, 0.02, 0.03),
	},
	"boston": {
		sol_dir = Vector3(0.3, 0.6, 0.6), sol_cor = Color(0.3, 0.34, 0.48), ambiente = Color(0.06, 0.06, 0.09),
		neblina_cor = Color(0.08, 0.08, 0.11), neblina_de = 10.0, neblina_ate = 70.0, neblina_max = 0.85,
		topo = Color(0.02, 0.025, 0.05), horizonte = Color(0.12, 0.1, 0.12), nuvens = 0.35, nuvem_cor = Color(0.12, 0.11, 0.13), estrelas = 0.5,
		acesas = 1.0, vidro = Color(0.03, 0.03, 0.04),
	},
}

var _cidade = Cidade.new()


## Noite 2: pela janela, o círculo de pedras de pé no alto de um morro selvagem
## (a fotografia de Akeley), a grama gasta em volta, e o mar de montanhas atrás.
func circulo() -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var m := Cidade.Malha.new()
	var j := Cidade.Malha.new()
	# A janela dá para o alto de outro morro: o círculo um pouco abaixo dos olhos,
	# do outro lado de um vale.
	var chao := -14.0
	var topo := Vector3(0.0, -2.6, -30.0)
	# O morro: um cone baixo e torto de faces, subindo até o círculo.
	_morro(m, topo, 30.0, topo.y - chao, Color(0.16, 0.18, 0.12), rng)
	m.quad_h(Vector3(-140, chao, -2), Vector3(140, chao, -80), Color(0.1, 0.12, 0.09))
	# A grama batida em volta das pedras: um anel mais claro, de terra.
	for i in 14:
		var a0 := TAU * i / 14.0
		var a1 := TAU * (i + 1) / 14.0
		var p0 := topo + Vector3(cos(a0), 0, sin(a0)) * 6.5 + Vector3(0, 0.05, 0)
		var p1 := topo + Vector3(cos(a1), 0, sin(a1)) * 6.5 + Vector3(0, 0.05, 0)
		m.tri(topo + Vector3(0, 0.06, 0), p0, p1, Vector3.UP, Color(0.36, 0.32, 0.24))
	# As pedras de pé, como de druidas: lajes altas, um pouco tortas.
	for i in 11:
		var a := TAU * i / 11.0 + rng.randf_range(-0.08, 0.08)
		var p := topo + Vector3(cos(a), 0, sin(a)) * 5.0
		var alt := rng.randf_range(2.2, 3.6)
		m.caixa(Vector3(rng.randf_range(0.8, 1.2), alt, rng.randf_range(0.45, 0.7)), p + Vector3(0, alt / 2 - 0.3, 0), Color(0.5, 0.5, 0.48) * rng.randf_range(0.85, 1.1))
	# Uma pedra deitada no meio.
	m.caixa(Vector3(1.6, 0.5, 1.0), topo + Vector3(0, 0.2, 0), Color(0.42, 0.42, 0.4))
	# O mar de montanhas desabitadas, em cristas cada vez mais apagadas.
	for k in 4:
		_cristas(m, -70.0 - k * 22.0, chao, 10.0 + k * 6.0, Color(0.16, 0.2, 0.17) * (1.0 - k * 0.12), rng)
	# Pinheiros escuros no vale e subindo a encosta, deixando o alto pelado.
	for k in 70:
		var x := rng.randf_range(-60, 60)
		var z := rng.randf_range(-6, -40)
		var r := Vector2(x - topo.x, z - topo.z).length()
		if r < 14.0:
			continue
		var y := chao + maxf(0.0, (30.0 - r) / 30.0) * (topo.y - chao) * 0.9
		_abeto(m, Vector3(x, y, z), rng.randf_range(5.0, 9.0), Color(0.06, 0.09, 0.07), rng)
	return _montar(m, j, LUZES.lua, "Circulo", true)


## Noite 4: pela janela, a plataforma da estação de Keene, de noite: a cobertura
## sobre os postes, os lampiões, os trilhos, o carrinho com o caixote — e um
## homem magro, de costas, junto dele.
func plataforma() -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var m := Cidade.Malha.new()
	var j := Cidade.Malha.new()
	# Como se a janela desse para os trilhos, no chão: do outro lado deles, a
	# plataforma, de frente, um pouco abaixo dos olhos.
	var chao := -1.4
	var plat := chao + 0.9
	m.quad_h(Vector3(-140, chao, -3), Vector3(140, chao, -90), Color(0.13, 0.12, 0.11))
	# Os trilhos e os dormentes, de lado a lado.
	for z in [-7.6, -9.1]:
		m.caixa(Vector3(140, 0.12, 0.08), Vector3(0, chao + 0.2, z), Color(0.36, 0.34, 0.34))
	for k in 70:
		m.caixa(Vector3(0.25, 0.08, 2.4), Vector3(-70.0 + k * 2.0, chao + 0.06, -8.35), Color(0.2, 0.16, 0.12))
	# A plataforma de tábuas, a borda de pedra virada para os trilhos.
	m.caixa(Vector3(44, 0.9, 5.0), Vector3(0, chao + 0.45, -13.0), Color(0.34, 0.27, 0.2))
	m.caixa(Vector3(44, 0.15, 0.4), Vector3(0, plat + 0.02, -10.6), Color(0.5, 0.48, 0.44))
	# A cobertura: postes no fundo da plataforma e o telhado de uma água,
	# descendo para os trilhos.
	for k in 8:
		m.caixa(Vector3(0.22, 3.2, 0.22), Vector3(-21.0 + k * 6.0, plat + 1.6, -14.6), Color(0.3, 0.24, 0.18))
	m.prisma(44.0, [Vector2(4.2, 2.9), Vector2(-1.0, 3.6)], Vector3(0, plat, -14.6), Color(0.2, 0.18, 0.18), Color(0.3, 0.24, 0.18))
	# Os lampiões pendurados da cobertura, acesos.
	for k in 4:
		var x := -15.0 + k * 10.0
		m.caixa(Vector3(0.05, 0.45, 0.05), Vector3(x, plat + 2.65, -12.0), Color(0.2, 0.2, 0.2))
		j.quad_v(Vector3(x, plat + 2.3, -11.95), Vector2(0.35, 0.45), Color(1.0, 0, 0))
	# A estação atrás da plataforma: a parede de tábuas, a porta, as janelas.
	m.caixa(Vector3(24, 5, 6), Vector3(-2, chao + 2.5, -18.6), Color(0.42, 0.33, 0.24))
	m.prisma(24.4, [Vector2(-3.2, 0), Vector2(0, 2.2), Vector2(3.2, 0)], Vector3(-2, chao + 5, -18.6), Color(0.18, 0.18, 0.2), Color(0.42, 0.33, 0.24))
	for k in 6:
		var acende := 0.8 if k == 2 or k == 4 else 0.0
		j.quad_v(Vector3(-11.0 + k * 3.6, plat + 1.5, -15.57), Vector2(1.0, 1.5), Color(acende, 0, 0))
	m.caixa(Vector3(1.2, 2.2, 0.1), Vector3(2.0, plat + 1.1, -15.58), Color(0.25, 0.18, 0.12))
	# O mato escuro e os morros atrás.
	for k in 30:
		_abeto(m, Vector3(rng.randf_range(-70, 70), chao, rng.randf_range(-24, -46)), rng.randf_range(5, 10), Color(0.05, 0.07, 0.06), rng)
	_cristas(m, -60.0, chao, 14.0, Color(0.06, 0.07, 0.07), rng)
	# O carrinho de carga com o caixote (o da pedra) e, junto dele, o homem
	# magro, de costas, olhando para a estação.
	var carro := Vector3(1.6, plat, -12.0)
	m.caixa(Vector3(1.2, 0.08, 0.7), carro + Vector3(0, 0.35, 0), Color(0.3, 0.22, 0.15))
	for s in [-1.0, 1.0]:
		m.caixa(Vector3(0.08, 0.3, 0.08), carro + Vector3(s * 0.45, 0.15, 0.25), Color(0.15, 0.15, 0.15))
	m.caixa(Vector3(0.8, 0.55, 0.55), carro + Vector3(0, 0.67, 0), Color(0.45, 0.36, 0.24))
	_homem(m, Vector3(0.4, plat, -12.4), Color(0.1, 0.1, 0.11))
	return _montar(m, j, LUZES.estacao, "Plataforma", false)


## A janelinha da pensão em Boston (Dia 4): telhados de tijolo de uma rua de
## sobrados, chaminés, caixas-d'água, janelas acesas aqui e ali, e ao longe a
## torre da alfândega com o relógio aceso.
func boston() -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1928
	var m := Cidade.Malha.new()
	var j := Cidade.Malha.new()
	var chao := -14.0
	m.quad_h(Vector3(-120, chao, -3), Vector3(120, chao, -120), Color(0.12, 0.12, 0.13))
	for fileira in 6:
		var z := -7.0 - fileira * 9.0
		var x := -40.0
		while x < 40.0:
			var w := rng.randf_range(5.0, 7.5)
			var alt := rng.randf_range(11.0, 15.0) - fileira * 0.4
			var tij: Color = Cidade.TIJOLOS[rng.randi_range(0, 2)] * rng.randf_range(0.75, 1.0)
			tij.a = 1.0
			var pos := Vector3(x + w / 2, chao, z - 3.5)
			m.caixa(Vector3(w, alt, 7.0), pos + Vector3(0, alt / 2, 0), tij)
			m.caixa(Vector3(w + 0.3, 0.4, 7.3), pos + Vector3(0, alt + 0.2, 0), tij * 0.75)
			# Chaminés de tijolo, em pares, e às vezes uma caixa-d'água.
			for k in rng.randi_range(1, 3):
				m.caixa(Vector3(0.7, 1.6, 1.1), pos + Vector3(rng.randf_range(-w / 2 + 0.6, w / 2 - 0.6), alt + 0.8, rng.randf_range(-2.5, 2.5)), tij * 0.9)
			if rng.randf() < 0.12:
				var cx := pos + Vector3(rng.randf_range(-1.5, 1.5), alt + 0.4, 0)
				for s in [-1.0, 1.0]:
					m.caixa(Vector3(0.1, 1.4, 0.1), cx + Vector3(s * 0.8, 0.7, 0), Color(0.15, 0.15, 0.15))
				m.caixa(Vector3(1.9, 1.8, 1.9), cx + Vector3(0, 2.3, 0), Color(0.3, 0.24, 0.18))
				m.piramide(1.1, 0.8, cx + Vector3(0, 3.2, 0), 8, Color(0.2, 0.2, 0.22))
			# As janelas da fachada (+Z).
			for a in int(alt / 3.0):
				for c in maxi(2, int(w / 2.0)):
					var acende := rng.randf_range(0.6, 1.0) if rng.randf() < 0.22 else 0.0
					j.quad_v(Vector3(pos.x - w / 2 + (c + 0.5) * w / maxi(2, int(w / 2.0)), chao + 1.8 + a * 3.0, pos.z + 3.53), Vector2(0.9, 1.4), Color(acende, 0, 0))
			x += w + (rng.randf_range(2.0, 4.0) if rng.randf() < 0.15 else 0.0)
	# A torre da alfândega, ao longe: o fuste, o relógio e a ponta.
	var torre := Vector3(-14.0, chao, -95.0)
	m.caixa(Vector3(7.0, 48.0, 7.0), torre + Vector3(0, 24.0, 0), Color(0.6, 0.58, 0.54))
	m.caixa(Vector3(8.0, 6.0, 8.0), torre + Vector3(0, 51.0, 0), Color(0.58, 0.56, 0.52))
	m.piramide(4.6, 9.0, torre + Vector3(0, 54.0, 0), 4, Color(0.3, 0.32, 0.3))
	j.quad_v(torre + Vector3(0, 51.0, 4.03), Vector2(3.4, 3.4), Color(1.0, 1.0, 0))
	for k in 8:
		j.quad_v(torre + Vector3(-1.5 + (k % 2) * 3.0, 8.0 + (k / 2) * 9.0, 3.53), Vector2(1.0, 2.0), Color(0.7 if k % 3 == 0 else 0.0, 0, 0))
	return _montar(m, j, LUZES.boston, "Boston", true)


## Noite 3, o disco revivido (Fase 3e): a 1 da manhã de 1º de maio de 1915, junto
## à boca fechada de uma caverna, onde a encosta oeste e arborizada da Dark
## Mountain sobe do pântano de Lee (livro, cap. III). Toma o lugar da sala, em
## volta de onde ele adormeceu: o chão úmido, pinheiros e bétulas, a encosta com
## a boca da caverna entupida por um matacão arredondado, o toco onde Akeley pôs
## o fonógrafo, a lanterna dele no chão. Em malhas com o material PSX iluminado.
## `mat` é esse material (cor de vértice × textura); `clareira`, o meio do
## espaço livre (onde ele está); `boca`, a boca da caverna, ao norte. A meta
## `troncos` lista onde há tronco (para a colisão).
func bosque(mat: Material, clareira: Vector3, boca: Vector3) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1915
	var m := Cidade.Malha.new()
	var raiz := Node3D.new()
	raiz.name = "Bosque"
	var troncos := PackedVector3Array()
	# O chão: musgo e lama, em ladrilhos de 1 m (o afim não torce), com poças.
	for x in range(-13, 13):
		for z in range(-13, 11):
			var cor := Color(0.17, 0.2, 0.12) * rng.randf_range(0.8, 1.15)
			if rng.randf() < 0.06:
				cor = Color(0.08, 0.09, 0.08)
			var c := Vector3(roundf(clareira.x) + x, 0, roundf(clareira.z) + z)
			m.quad_h(c, c + Vector3(1, 0, 1), cor)
	# A encosta da montanha, ao norte da boca, subindo; e a boca da caverna
	# nela, entupida pelo matacão de uma regularidade arredondada.
	for k in 9:
		var x0 := boca.x - 15.0 + k * 3.5
		var a := Vector3(x0, 0, boca.z - 0.5 + absf(x0 - boca.x) * 0.08)
		var b := Vector3(x0 + 3.5, 0, boca.z - 0.5 + absf(x0 + 3.5 - boca.x) * 0.08)
		m.quad(a, b, b + Vector3(0, 9.0, -6.0), a + Vector3(0, 9.0, -6.0), Vector3(0, 0.55, 1).normalized(), Color(0.2, 0.2, 0.17) * rng.randf_range(0.85, 1.1))
	m.caixa(Vector3(2.6, 2.2, 1.0), boca + Vector3(0, 1.1, -0.2), Color(0.06, 0.06, 0.06))
	_bola(m, boca + Vector3(0, 1.0, 0.35), Vector3(1.15, 1.05, 0.7), Color(0.4, 0.4, 0.38), rng)
	for s in [-1.0, 1.0]:
		m.caixa(Vector3(1.0, 2.6, 1.2), boca + Vector3(s * 1.7, 1.2, 0.0), Color(0.3, 0.3, 0.28))
	# Vultos parados na névoa, diante da caverna, de mantos escuros: não se
	# chega perto (o sonho acaba antes).
	for k in 3:
		var p := boca + Vector3(-2.0 + k * 2.0, 0, 0.9 + (k % 2) * 0.4)
		_vulto(m, p, Color(0.02, 0.02, 0.025))
	# As árvores: pinheiros-cicuta escuros e bétulas pálidas, em volta, deixando
	# a clareira e o caminho até a caverna.
	for k in 80:
		var p := clareira + Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-11, 9))
		var ate_boca := Vector2(boca.x - clareira.x, boca.z - clareira.z)
		var rel := Vector2(p.x - clareira.x, p.z - clareira.z)
		var no_caminho := rel.dot(ate_boca.normalized()) > 0.0 and absf(rel.cross(ate_boca.normalized())) < 2.4 and rel.length() < ate_boca.length() + 1.0
		if rel.length() < 3.4 or no_caminho or p.z < boca.z + 0.5:
			continue
		troncos.append(p)
		if rng.randf() < 0.3:
			_betula(m, p, rng.randf_range(5.0, 8.0), rng)
		else:
			_abeto(m, p, rng.randf_range(6.0, 11.0), Color(0.08, 0.13, 0.09) * rng.randf_range(0.8, 1.2), rng)
	# Juncos e moitas do pântano, ao sul.
	for k in 40:
		var p := clareira + Vector3(rng.randf_range(-11, 11), 0, rng.randf_range(3, 9))
		m.piramide(rng.randf_range(0.2, 0.45), rng.randf_range(0.5, 1.2), p, 4, Color(0.2, 0.24, 0.12))
	var mi := MeshInstance3D.new()
	mi.name = "Malha"
	mi.mesh = m.fechar()
	mi.material_override = mat
	raiz.add_child(mi)
	raiz.set_meta(&"troncos", troncos)
	return raiz


# --- As peças ----------------------------------------------------------------------

func _montar(m: Cidade.Malha, j: Cidade.Malha, luz: Dictionary, nome: String, lua: bool) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = nome
	var mats: Dictionary = _cidade.materiais_para(luz)
	for parte: Array in [["Solido", m, mats.solido], ["Janelas", j, mats.janelas]]:
		if (parte[1] as Cidade.Malha).vazio:
			continue
		var mi := MeshInstance3D.new()
		mi.name = parte[0]
		mi.mesh = (parte[1] as Cidade.Malha).fechar()
		mi.material_override = parte[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi)
	var ceu := MeshInstance3D.new()
	ceu.name = "Ceu"
	var q := QuadMesh.new()
	q.size = Vector2(420.0, 170.0)
	ceu.mesh = q
	ceu.material_override = mats.ceu
	ceu.position = Vector3(0, 30.0, -125.0)
	ceu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(ceu)
	if lua:
		# A lua: um disco pálido na frente do céu.
		var disco := MeshInstance3D.new()
		disco.name = "Lua"
		var esfera := SphereMesh.new()
		esfera.radius = 3.2
		esfera.height = 6.4
		esfera.radial_segments = 12
		esfera.rings = 6
		disco.mesh = esfera
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/psx_unlit.gdshader")
		mat.set_shader_parameter(&"albedo_tex", load("res://art/textures/grao.png"))
		mat.set_shader_parameter(&"albedo_color", Color(0.86, 0.86, 0.78))
		disco.material_override = mat
		disco.position = Vector3(26.0, 40.0, -118.0)
		disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(disco)
	return raiz


## Um morro: um cone baixo de faces, com o topo achatado em `topo`.
func _morro(m: Cidade.Malha, topo: Vector3, raio: float, alt: float, cor: Color, rng: RandomNumberGenerator) -> void:
	var lados := 12
	var base := topo - Vector3(0, alt, 0)
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var r0 := raio * rng.randf_range(0.8, 1.2)
		var r1 := raio * rng.randf_range(0.8, 1.2)
		var p0 := base + Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var p1 := base + Vector3(cos(a1) * r1, 0, sin(a1) * r1)
		var q0 := topo + Vector3(cos(a0), 0, sin(a0)) * 7.0
		var q1 := topo + Vector3(cos(a1), 0, sin(a1)) * 7.0
		var n := ((p0 + p1) / 2 - base).normalized() + Vector3(0, 1.2, 0)
		m.quad(p0, p1, q1, q0, n.normalized(), cor * rng.randf_range(0.9, 1.1))
		m.tri(topo, q0, q1, Vector3.UP, cor * 1.05)


## Uma crista de montanhas de leste a oeste, em `z`, de altura média `alt`.
func _cristas(m: Cidade.Malha, z: float, chao: float, alt: float, cor: Color, rng: RandomNumberGenerator) -> void:
	var x := -170.0
	var alt_ant := alt
	while x < 170.0:
		var prox := x + rng.randf_range(12.0, 26.0)
		var h := alt * rng.randf_range(0.6, 1.5)
		var a := Vector3(x, chao, z)
		var b := Vector3(prox, chao, z)
		m.quad(a, b, b + Vector3(0, h, -5), a + Vector3(0, alt_ant, -5), Vector3(0, 0.45, 1).normalized(), cor * rng.randf_range(0.9, 1.1))
		alt_ant = h
		x = prox


## Um pinheiro-cicuta escuro: o tronco e quatro andares de cones estreitos,
## cada um caindo um pouco sobre o de baixo.
func _abeto(m: Cidade.Malha, base: Vector3, alt: float, cor: Color, rng: RandomNumberGenerator) -> void:
	m.caixa(Vector3(0.18, alt * 0.35, 0.18) * Vector3(alt / 6.0, 1, alt / 6.0), base + Vector3(0, alt * 0.175, 0), Color(0.16, 0.12, 0.09))
	for k in 4:
		var y := alt * (0.25 + k * 0.17)
		var r := alt * (0.17 - k * 0.03) * rng.randf_range(0.9, 1.1)
		m.piramide(r, alt * 0.3, base + Vector3(0, y, 0), 7, cor * (1.0 + k * 0.06))


## Uma bétula: o tronco fino e pálido, com nós escuros, e a copa rala.
func _betula(m: Cidade.Malha, base: Vector3, alt: float, rng: RandomNumberGenerator) -> void:
	m.caixa(Vector3(0.14, alt, 0.14), base + Vector3(0, alt / 2, 0), Color(0.78, 0.76, 0.7))
	for k in 3:
		m.caixa(Vector3(0.15, 0.06, 0.15), base + Vector3(0, rng.randf_range(0.8, alt - 1.0), 0), Color(0.12, 0.12, 0.12))
	m.bipiramide(alt * 0.22, alt * 0.35, base + Vector3(rng.randf_range(-0.3, 0.3), alt * 0.85, 0), 5, Color(0.2, 0.26, 0.14), rng.randf() * TAU)


## Um seixo grande arredondado (o matacão da caverna).
func _bola(m: Cidade.Malha, c: Vector3, r: Vector3, cor: Color, rng: RandomNumberGenerator) -> void:
	var lados := 8
	var aneis := 5
	var pontos: Array = []
	for jj in aneis + 1:
		var fila: Array = []
		var v := PI * jj / aneis
		for i in lados:
			var u := TAU * i / lados
			fila.append(c + Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u)) * r * rng.randf_range(0.95, 1.05))
		pontos.append(fila)
	for jj in aneis:
		for i in lados:
			var a: Vector3 = pontos[jj][i]
			var b: Vector3 = pontos[jj][(i + 1) % lados]
			var cc: Vector3 = pontos[jj + 1][i]
			var d: Vector3 = pontos[jj + 1][(i + 1) % lados]
			var n := ((a + b + cc + d) / 4.0 - c).normalized()
			m.quad(a, b, d, cc, n, cor * rng.randf_range(0.9, 1.08))


## Um vulto de manto, de pé, o capuz baixo: um cone alongado e a cabeça.
func _vulto(m: Cidade.Malha, pe: Vector3, cor: Color) -> void:
	m.piramide(0.32, 1.7, pe, 7, cor)
	m.caixa(Vector3(0.36, 0.5, 0.3), pe + Vector3(0, 1.15, 0), cor * 1.2)
	m.bipiramide(0.16, 0.38, pe + Vector3(0, 1.6, 0.02), 6, cor * 1.4, 0.3)


## Um homem magro de pé, de costas para quem olha (+Z): o sobretudo comprido,
## os ombros estreitos, o chapéu.
func _homem(m: Cidade.Malha, pe: Vector3, cor: Color) -> void:
	m.caixa(Vector3(0.12, 0.85, 0.14), pe + Vector3(-0.09, 0.42, 0), cor * 0.8)
	m.caixa(Vector3(0.12, 0.85, 0.14), pe + Vector3(0.09, 0.42, 0), cor * 0.8)
	m.caixa(Vector3(0.42, 0.9, 0.26), pe + Vector3(0, 1.05, 0), cor)
	m.caixa(Vector3(0.36, 0.3, 0.24), pe + Vector3(0, 1.55, 0), cor)
	for s in [-1.0, 1.0]:
		m.caixa(Vector3(0.09, 0.7, 0.11), pe + Vector3(s * 0.23, 1.3, 0.02), cor * 0.9)
	m.caixa(Vector3(0.11, 0.1, 0.11), pe + Vector3(0, 1.74, 0), Color(0.55, 0.45, 0.4))
	m.caixa(Vector3(0.2, 0.22, 0.22), pe + Vector3(0, 1.88, 0), Color(0.5, 0.42, 0.38))
	m.caixa(Vector3(0.38, 0.03, 0.36), pe + Vector3(0, 1.98, 0), cor * 0.6)
	m.caixa(Vector3(0.22, 0.12, 0.22), pe + Vector3(0, 2.05, 0), cor * 0.6)
