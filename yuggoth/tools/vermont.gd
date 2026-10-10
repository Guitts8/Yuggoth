extends RefCounted
## A geografia do mapa da parede (Fase 4): o condado de Windham, Vermont, onde
## quase tudo acontece (Townshend, Newfane, Brattleboro, Bellows Falls, e Keene do
## outro lado do Connecticut), num mapa de condado de época; e, num quadro no alto à
## direita, o estado inteiro (as enchentes do norte, do recorte). Em graus (latitude
## norte, longitude oeste), aproximados à mão. A textura (gerar_assets._mapa_vermont)
## e o gerador do escritório (os alfinetes, os nomes) leem daqui.

## O mapa grande: sul..norte e oeste..leste (longitude oeste em graus positivos).
const LAT := Vector2(42.7, 43.3)
const LON := Vector2(73.0, 72.12)
## O quadro do estado: onde fica no papel (uv: x0, y0, x1, y1) e o que mostra.
const QUADRO := Rect2(0.735, 0.035, 0.235, 0.405)
const Q_LAT := Vector2(42.6, 45.15)
const Q_LON := Vector2(73.55, 71.35)

## O contorno de Vermont, de noroeste no sentido horário: a fronteira do Canadá, o
## rio Connecticut descendo (a fronteira com New Hampshire), a de Massachusetts e a
## de Nova York, que sobe pelo lago Champlain.
const CONTORNO := [
	Vector2(45.013, 73.343), Vector2(45.013, 71.47), Vector2(44.93, 71.5), Vector2(44.82, 71.55),
	Vector2(44.72, 71.6), Vector2(44.62, 71.61), Vector2(44.53, 71.63), Vector2(44.46, 71.72),
	Vector2(44.39, 71.85), Vector2(44.33, 71.95), Vector2(44.25, 72.03), Vector2(44.15, 72.05),
	Vector2(44.05, 72.1), Vector2(43.95, 72.16), Vector2(43.85, 72.2), Vector2(43.75, 72.24),
	Vector2(43.65, 72.31), Vector2(43.55, 72.37), Vector2(43.45, 72.39), Vector2(43.35, 72.4),
	Vector2(43.25, 72.42), Vector2(43.2, 72.43), Vector2(43.13, 72.443), Vector2(43.08, 72.455),
	Vector2(43.03, 72.465), Vector2(42.98, 72.49), Vector2(42.93, 72.52), Vector2(42.89, 72.535),
	Vector2(42.86, 72.553), Vector2(42.82, 72.545), Vector2(42.78, 72.52), Vector2(42.727, 72.46),
	Vector2(42.745, 73.265), Vector2(43.0, 73.255), Vector2(43.3, 73.25), Vector2(43.57, 73.24),
	Vector2(43.62, 73.36), Vector2(43.8, 73.38), Vector2(44.0, 73.4), Vector2(44.2, 73.35),
	Vector2(44.4, 73.33), Vector2(44.6, 73.36), Vector2(44.8, 73.35),
]
## Do contorno, os índices do rio Connecticut (o primeiro e o último).
const CONNECTICUT := Vector2i(1, 31)

## O condado de Windham, de noroeste no sentido horário (aproximado).
const CONDADO := [
	Vector2(43.29, 72.98), Vector2(43.3, 72.82), Vector2(43.27, 72.7), Vector2(43.26, 72.55),
	Vector2(43.25, 72.42), Vector2(43.13, 72.443), Vector2(43.03, 72.465), Vector2(42.93, 72.52),
	Vector2(42.86, 72.553), Vector2(42.78, 72.52), Vector2(42.727, 72.46), Vector2(42.73, 72.95),
	Vector2(42.9, 72.94), Vector2(43.1, 72.96),
]

## Os rios: o West (do livro: as enchentes "no West, no condado de Windham, além de
## Newfane"; passa por Jamaica, Townshend e Newfane até Brattleboro), o Saxtons e o
## Williams (que descem a Bellows Falls), o Rock, o Green; e, no quadro do estado, o
## Winooski ("perto de Montpelier") e o Passumpsic ("acima de Lyndonville").
const RIOS := {
	"West": [Vector2(43.27, 72.83), Vector2(43.2, 72.81), Vector2(43.15, 72.79), Vector2(43.11, 72.77),
		Vector2(43.08, 72.73), Vector2(43.06, 72.7), Vector2(43.04, 72.672), Vector2(43.01, 72.66),
		Vector2(42.985, 72.65), Vector2(42.95, 72.63), Vector2(42.91, 72.6), Vector2(42.88, 72.575), Vector2(42.86, 72.556)],
	"Saxtons": [Vector2(43.17, 72.63), Vector2(43.15, 72.58), Vector2(43.13, 72.52), Vector2(43.12, 72.46)],
	"Williams": [Vector2(43.27, 72.65), Vector2(43.22, 72.57), Vector2(43.18, 72.49), Vector2(43.17, 72.44)],
	"Rock": [Vector2(43.04, 72.82), Vector2(43.0, 72.76), Vector2(42.97, 72.7), Vector2(42.955, 72.66)],
	"Green": [Vector2(42.77, 72.72), Vector2(42.8, 72.66), Vector2(42.83, 72.6), Vector2(42.85, 72.565)],
	"Deerfield": [Vector2(43.0, 72.88), Vector2(42.9, 72.87), Vector2(42.8, 72.89), Vector2(42.71, 72.88)],
}
const RIOS_ESTADO := {
	"West": [Vector2(43.27, 72.83), Vector2(43.1, 72.75), Vector2(42.98, 72.65), Vector2(42.86, 72.556)],
	"Winooski": [Vector2(44.28, 72.42), Vector2(44.27, 72.57), Vector2(44.33, 72.75), Vector2(44.38, 72.9),
		Vector2(44.45, 73.05), Vector2(44.49, 73.19), Vector2(44.53, 73.3)],
	"Passumpsic": [Vector2(44.78, 72.02), Vector2(44.65, 72.03), Vector2(44.53, 72.0), Vector2(44.42, 72.02),
		Vector2(44.34, 72.0), Vector2(44.31, 71.97)],
}

## As cidades impressas (inglês, como tudo o que é impresso): [nome, lat, lon].
const CIDADES := [
	["Brattleboro", 42.851, 72.558], ["Newfane", 42.986, 72.656], ["Townshend", 43.047, 72.667],
	["W. Townshend", 43.08, 72.735], ["Jamaica", 43.1, 72.78], ["Wardsboro", 43.04, 72.79],
	["W. Dover", 42.94, 72.85], ["Wilmington", 42.868, 72.872], ["Marlboro", 42.86, 72.73],
	["Dummerston", 42.92, 72.615], ["Putney", 42.975, 72.52], ["Westminster", 43.07, 72.46],
	["Bellows Falls", 43.134, 72.444], ["Grafton", 43.17, 72.61], ["Athens", 43.11, 72.59],
	["Brookline", 43.025, 72.6], ["Guilford", 42.79, 72.6], ["Vernon", 42.76, 72.51],
	["Halifax", 42.77, 72.75], ["Whitingham", 42.79, 72.89], ["Stratton", 43.04, 72.92],
	["S. Londonderry", 43.19, 72.81], ["Keene", 42.934, 72.278], ["Walpole", 43.08, 72.43],
	["Chesterfield", 42.89, 72.47], ["Hinsdale", 42.79, 72.49], ["Westmoreland", 42.96, 72.44],
]

## Os morros em hachura (os mais conhecidos e os da serra, a oeste).
const MORROS := [
	Vector2(43.12, 72.93), Vector2(43.06, 72.9), Vector2(42.98, 72.92), Vector2(43.2, 72.88),
	Vector2(43.0, 72.71), Vector2(42.99, 72.73), Vector2(43.01, 72.69), Vector2(43.06, 72.63),
	Vector2(43.15, 72.7), Vector2(42.9, 72.68), Vector2(42.93, 72.76), Vector2(43.22, 72.68),
	Vector2(42.82, 72.8), Vector2(43.1, 72.55), Vector2(42.95, 72.57),
]


## (0..1, 0..1) no papel, de cima à esquerda, para (lat, lon oeste), no mapa grande.
static func uv(lat: float, lon: float) -> Vector2:
	return Vector2((LON.x - lon) / (LON.x - LON.y), (LAT.y - lat) / (LAT.y - LAT.x))


## O mesmo, no quadro do estado.
static func uv_quadro(lat: float, lon: float) -> Vector2:
	var q := Vector2((Q_LON.x - lon) / (Q_LON.x - Q_LON.y), (Q_LAT.y - lat) / (Q_LAT.y - Q_LAT.x))
	return QUADRO.position + q * QUADRO.size


## Largura / altura do papel, para que um grau tenha o mesmo tamanho nos dois
## sentidos (na latitude do meio).
static func proporcao() -> float:
	return (LON.x - LON.y) * cos(deg_to_rad((LAT.x + LAT.y) / 2.0)) / (LAT.y - LAT.x)
