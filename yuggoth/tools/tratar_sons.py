"""Trata as gravações CC0 (playtest 8: "os efeitos sonoros estão bastante
genéricos"; os do menu, "muito toscos") e as grava em audio/foley/, com o mesmo
nome do som provisório que substituem (os geradores preferem audio/foley/ —
gerador_base._sfx). O sobrenatural (o zumbido, o disco, as vozes, o sonho)
continua sintetizado por gerar_assets.gd.

As fontes (todas CC0, de opengameart.org; lista em audio/foley/FONTES.md) não
vão para o repositório: baixe-as e extraia numa pasta, e rode

    python -I tools/tratar_sons.py <pasta das fontes>

com numpy, scipy e soundfile instalados (de preferência num venv). Determinístico:
as mesmas fontes dão os mesmos arquivos.
"""

import os
import sys

import numpy as np
import soundfile as sf
from scipy import signal

RATE = 44100
AQUI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(AQUI, "..", "audio", "foley"))
FONTE = ""


# --- leitura e utilidades --------------------------------------------------------

def ler(rel, ini=0.0, fim=None):
    """Mono, 44,1 kHz, de `ini` a `fim` segundos."""
    d, sr = sf.read(os.path.join(FONTE, rel), always_2d=True)
    x = d.mean(axis=1)
    if sr != RATE:
        g = np.gcd(RATE, sr)
        x = signal.resample_poly(x, RATE // g, sr // g)
    a = int(ini * RATE)
    b = len(x) if fim is None else int(fim * RATE)
    return x[a:b].astype(np.float64)


def seg(s):
    return int(s * RATE)


def pico(x, alvo=0.9):
    m = np.abs(x).max()
    return x if m == 0 else x * (alvo / m)


def rms(x, alvo):
    r = np.sqrt((x ** 2).mean())
    return x if r == 0 else x * (alvo / r)


def aparar(x, limiar=0.02, antes=0.01):
    """Corta o silêncio do começo e do fim (relativo ao pico)."""
    env = np.abs(x)
    lim = env.max() * limiar
    idx = np.where(env > lim)[0]
    if len(idx) == 0:
        return x
    a = max(0, idx[0] - seg(antes))
    b = min(len(x), idx[-1] + seg(0.05))
    return x[a:b]


def fades(x, a=0.004, b=0.03):
    x = x.copy()
    na, nb = min(seg(a), len(x)), min(seg(b), len(x))
    if na:
        x[:na] *= np.linspace(0, 1, na)
    if nb:
        x[-nb:] *= np.linspace(1, 0, nb)
    return x


def passa_baixa(x, hz, ordem=2):
    b, a = signal.butter(ordem, hz / (RATE / 2), "low")
    return signal.lfilter(b, a, x)


def passa_alta(x, hz, ordem=2):
    b, a = signal.butter(ordem, hz / (RATE / 2), "high")
    return signal.lfilter(b, a, x)


def tom(x, fator):
    """Muda a altura (e a duração): fator < 1 = mais grave e mais pesado."""
    return signal.resample_poly(x, 1000, int(round(1000 * fator)))


def sala(x, rt=0.35, mistura=0.12, brilho=3500.0, semente=1, cortar=True):
    """Uma reverberação curta de sala, por convolução com uma resposta sintética
    (ruído que decai, abafado): a madeira do escritório, o corredor."""
    rng = np.random.default_rng(semente)
    n = seg(rt * 1.4)
    t = np.arange(n) / RATE
    ir = rng.standard_normal(n) * np.exp(-6.9 * t / rt)
    ir = passa_baixa(ir, brilho)
    ir[: seg(0.004)] = 0.0  # o pré-atraso: as paredes estão a uns metros
    ir /= np.sqrt((ir ** 2).sum())
    molhado = signal.fftconvolve(x, ir)
    seco = np.concatenate([x, np.zeros(len(molhado) - len(x))])
    y = seco * (1 - mistura) + molhado * mistura * 2.0
    # Num laço, o tamanho é o do laço (a cauda volta pelo começo, não se corta).
    if not cortar:
        cauda = y[len(x):]
        y = y[: len(x)].copy()
        y[: len(cauda)] += cauda[: len(x)]
        return y
    return aparar(y, 0.002)


def misturar(*partes):
    """(sinal, início em segundos, ganho)."""
    fim = max(seg(t) + len(s) for s, t, _ in partes)
    y = np.zeros(fim)
    for s, t, g in partes:
        a = seg(t)
        y[a : a + len(s)] += s * g
    return y


def laco(x, cruz=1.5):
    """Um laço sem emenda: o fim se funde ao começo (potência constante)."""
    n = seg(cruz)
    corpo = x[:-n].copy()
    k = np.linspace(0, np.pi / 2, n)
    corpo[:n] = corpo[:n] * np.sin(k) + x[-n:] * np.cos(k)
    return corpo


def salvar(nome, x, laco_=False, alvo=0.9):
    x = pico(x, alvo)
    if not laco_:
        x = fades(x)
    caminho = os.path.join(OUT, nome + ".wav")
    sf.write(caminho, x.astype(np.float32), RATE, subtype="PCM_16")
    imp = caminho + ".import"
    if laco_ and not os.path.exists(imp):
        with open(imp, "w", encoding="utf-8", newline="\n") as f:
            f.write('[remap]\n\nimporter="wav"\ntype="AudioStreamWAV"\n\n[params]\n\n'
                    "edit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n")
    print(f"{nome:22s} {len(x) / RATE:6.2f} s{'  (laço)' if laco_ else ''}")


# --- os sons ---------------------------------------------------------------------

def passos():
    # O assoalho de tábuas: os passos na madeira (TinyWorlds), com a sala e o
    # estalo grave das tábuas (um pouco do passo da Kenney, mais grave, embaixo).
    for i, (f, k) in enumerate([("wood01.ogg", "footstep02.ogg"), ("wood02.ogg", "footstep06.ogg"), ("wood03.ogg", "footstep09.ogg")]):
        a = pico(aparar(ler("x/[kdd]DifferentSteps_0/" + f)))
        b = pico(passa_baixa(tom(aparar(ler("x/RPGsounds_Kenney/OGG/" + k)), 0.8), 1800))
        y = misturar((a, 0, 1.0), (b, 0.0, 0.35))
        salvar("passo_madeira_%d" % (i + 1), sala(passa_baixa(y, 9000), 0.3, 0.14, semente=10 + i), alvo=0.7)


def portas():
    salvar("porta_rangendo", sala(passa_baixa(aparar(ler("x/sounds_8/door_creak_open.wav")), 8000), 0.45, 0.12, semente=3))
    salvar("porta_trinco", sala(aparar(ler("x/RPGsounds_Kenney/OGG/doorClose_2.ogg")), 0.4, 0.14, semente=4), alvo=0.8)
    salvar("gaveta", sala(aparar(ler("x/sounds_8/drawer_open.wav")), 0.3, 0.1, semente=5))
    # A janela de guilhotina correndo no caixilho (a noite em claro).
    salvar("janela", sala(passa_baixa(tom(aparar(ler("x/100-CC0-wood-metal-SFX/wood_squeak_02.ogg")), 0.8), 6000), 0.35, 0.12, semente=6), alvo=0.7)
    # Bater à porta da pensão (Boston): três nós de dedo na madeira, no corredor.
    nos = [aparar(ler("x/100-CC0-wood-metal-SFX/wood_hit_0%d.ogg" % n)) for n in (5, 1, 6)]
    nos = [pico(passa_baixa(tom(n, 0.9), 4000)) for n in nos]
    y = misturar((nos[0], 0.0, 1.0), (nos[1], 0.3, 0.85), (nos[2], 0.58, 0.95))
    salvar("batidas_porta", sala(y, 0.7, 0.18, semente=7), alvo=0.85)


def fogo():
    salvar("fosforo", sala(aparar(ler("x/sounds_8/match.wav")), 0.3, 0.08, semente=8), alvo=0.8)
    # A lareira: o fogo de verdade (PagDev), com os estalos de outro (AntumDeluge).
    base = rms(ler("zip/fire.wav", 1.0, 27.0), 0.06)
    estalos = rms(ler("zip/fire-1.wav"), 0.05)
    y = base.copy()
    for t in (3.0, 11.5, 19.0):
        a = seg(t)
        y[a : a + len(estalos)] += estalos[: len(y) - a] * 0.6
    salvar("lareira", laco(passa_baixa(y, 9000), 2.0), True, alvo=0.6)


def chuva_e_noite():
    # A chuva na janela (Ylmir: gravada junto a uma janela).
    salvar("chuva", laco(passa_baixa(ler("x/Rain OGG/1.ogg", 0.5, 26.5), 10000), 2.0), True, alvo=0.6)
    # A noite: grilos (Wolfgang_), duas voltas, e um vento baixo por baixo.
    g = rms(ler("zip/crickets_1.mp3"), 0.04)
    grilos = np.concatenate([g, g[seg(1.0):]])
    v = rms(passa_baixa(ler("x/wind/wind/Wind.ogg"), 1200), 0.012)
    vento = np.tile(v, int(np.ceil(len(grilos) / len(v))) + 1)[: len(grilos)]
    salvar("noite", laco(grilos + vento, 1.5), True, alvo=0.4)
    # O vento frio pela janela entreaberta (a noite em claro).
    w = np.concatenate([ler("x/wind/wind/Wind.ogg"), ler("x/wind/wind/Wind2.ogg")])
    salvar("vento", laco(passa_baixa(w, 4000), 1.5), True, alvo=0.6)


def relogio():
    # O relógio de mesa: tique e taque a cada meio segundo (bart), 8 s de laço,
    # cada batida um pouco diferente.
    ticks = [pico(aparar(ler("x/ticks/ticking clock - tick%d.wav" % n))) for n in (1, 2, 3, 4)]
    partes = []
    for k in range(16):
        partes.append((ticks[k % 4], k * 0.5 + (0.006 if k % 2 else 0.0), 1.0 if k % 2 == 0 else 0.8))
    y = np.zeros(seg(8.0))
    m = misturar(*partes)
    y[: min(len(m), len(y))] += m[: len(y)]
    salvar("relogio", sala(y, 0.3, 0.1, semente=9, cortar=False), True, alvo=0.5)


def telefone():
    # A campainha de parede: o "tring" velho (Wikimedia, via OGA), e a pausa.
    tring = aparar(ler("zip/doorbell-old-tring.ogg"))
    y = np.concatenate([tring, np.zeros(seg(1.8))])
    salvar("campainha", sala(y, 0.35, 0.08, semente=11, cortar=False), True, alvo=0.7)
    salvar("telefone_gancho", sala(aparar(ler("x/RPGsounds_Kenney/OGG/metalLatch.ogg")), 0.3, 0.1, semente=12), alvo=0.7)


def papel():
    salvar("papel_pegar", sala(aparar(ler("x/sounds_6/WAV/Paper Sound - 1.wav")), 0.25, 0.08, semente=13), alvo=0.7)
    # A folha amassada (Esc ao escrever: vai para o cesto).
    salvar("papel_amassado", sala(aparar(ler("x/sounds_6/WAV/Paper Crushed - 2.wav")), 0.25, 0.08, semente=27), alvo=0.75)
    salvar("papel_rasgando", sala(aparar(ler("x/sounds_6/WAV/Paper Ripped - 1.wav")), 0.25, 0.08, semente=14), alvo=0.8)
    # A carta pela fresta: o papel que escorrega e o tapa no chão.
    desliza = aparar(ler("x/sounds_6/WAV/Paper Sound - 3.wav"))
    tapa = pico(passa_baixa(aparar(ler("x/RPGsounds_Kenney/OGG/bookPlace1.ogg")), 2500))
    y = misturar((pico(desliza), 0.0, 0.8), (tapa, len(desliza) / RATE - 0.08, 0.25))
    salvar("correio_fresta", sala(y, 0.3, 0.1, semente=15), alvo=0.7)
    # O pacote no chão: couro e papelão, pesado.
    a = pico(aparar(ler("x/RPGsounds_Kenney/OGG/dropLeather.ogg")))
    b = pico(passa_baixa(tom(aparar(ler("x/100-CC0-wood-metal-SFX/wood_falling_04.ogg")), 0.85), 3000))
    salvar("pacote_chao", sala(misturar((a, 0, 0.8), (b, 0.01, 0.6)), 0.35, 0.12, semente=16))
    # O selo batido na mesa: um baque abafado.
    s = pico(passa_baixa(aparar(ler("x/RPGsounds_Kenney/OGG/bookPlace3.ogg")), 2200))
    salvar("selo_batido", sala(s, 0.3, 0.12, semente=17), alvo=0.8)
    # A pena no papel (o lápis de NachtmahrTV, mais áspero e fino).
    pena = passa_alta(ler("x/pencil/ogg/pencil_write.ogg"), 1200)
    salvar("pena", sala(pena, 0.25, 0.06, semente=18), alvo=0.6)


def alfinete():
    # O alfinete entrando no mapa (Fase 4): um clique de metal pequeno, seco.
    a = passa_alta(aparar(ler("x/RPGsounds_Kenney/OGG/metalClick.ogg")), 1500)
    salvar("alfinete", sala(a[: seg(0.25)], 0.25, 0.08, semente=26), alvo=0.6)


def bebida():
    """Playtest 9: o café e o uísque (MoreSounds de OwlishMedia, Tinysized SFX, 100 CC0 SFX)."""
    # O café da garrafa térmica na xícara: um jorro grosso, curto.
    cafe = passa_baixa(aparar(ler("x/tinysized/sfx-cc0/water-pour-01.wav")), 5000)
    salvar("servir", sala(cafe, 0.3, 0.08, semente=30), alvo=0.6)
    # O uísque no copo: fino, de vidro, mais curto.
    uisque = aparar(ler("x/tinysized/sfx-cc0/water-vial-fill-01.wav"))[: seg(1.4)]
    salvar("servir_uisque", sala(uisque, 0.3, 0.08, semente=31), alvo=0.55)
    # A tampa da garrafa térmica; a rolha do frasco.
    salvar("destampar_garrafa", sala(aparar(ler("x/tinysized/sfx-cc0/bottle-clay-uncork-01.wav")), 0.3, 0.08, semente=32), alvo=0.5)
    salvar("destampar_frasco", sala(aparar(ler("x/tinysized/sfx-cc0/bottle-glass-uncork-01.wav")), 0.3, 0.08, semente=33), alvo=0.5)
    # Um gole (baixo, perto da boca).
    salvar("gole", passa_baixa(aparar(ler("x/MoreSounds/Drink/Drink_06.wav")), 6000), alvo=0.5)
    # A xícara (ou o copo) pousada de volta: um tilintar de louça, abafado.
    salvar("pousar_xicara", sala(passa_baixa(aparar(ler("x/100-CC0-SFX_0/dishes_04.ogg")), 5000), 0.3, 0.08, semente=34), alvo=0.45)


def calha():
    """A carta descendo a calha de correio de latão: o papel na fenda e o deslizar no tubo."""
    fenda = pico(aparar(ler("x/sounds_6/WAV/Paper Sound - 2.wav")))
    tubo = pico(passa_baixa(tom(aparar(ler("x/tinysized/sfx-cc0/tube-plastic-whoosh-02.wav")), 0.55), 2500))
    tique = pico(passa_alta(aparar(ler("x/RPGsounds_Kenney/OGG/metalClick.ogg")), 800))
    y = misturar((fenda, 0.0, 0.8), (tubo, 0.25, 0.7), (tique, 0.9, 0.25))
    salvar("calha_correio", sala(y, 0.6, 0.18, semente=35), alvo=0.6)


def lama():
    m = pico(aparar(ler("x/[kdd]DifferentSteps_0/mud02.ogg")))
    salvar("lama", sala(passa_baixa(tom(m, 0.75), 2500), 0.4, 0.12, semente=19), alvo=0.8)


def menu():
    """O Necronomicon (playtest 8: "os efeitos sonoros do menu estão muito toscos")."""
    # Uma folha grossa virando (Voltiment555), com o ar dela.
    salvar("menu_folha", sala(passa_baixa(aparar(ler("x/BookFlip_SFX/BookFlip12.wav")), 9000), 0.5, 0.12, semente=20), alvo=0.7)
    # A capa pesada se levantando: o couro que range, devagar e grave.
    rangido = pico(passa_baixa(tom(aparar(ler("x/RPGsounds_Kenney/OGG/creak2.ogg")), 0.7), 3000))
    ar = pico(passa_baixa(tom(aparar(ler("x/RPGsounds_Kenney/OGG/bookFlip1.ogg")), 0.6), 2500))
    salvar("menu_capa", sala(misturar((rangido, 0.0, 0.9), (ar, 0.35, 0.6)), 0.8, 0.18, semente=21), alvo=0.7)
    # O baque da capa na mesa: o livro, o tampo e o peso, numa sala de pedra.
    livro = pico(tom(aparar(ler("x/RPGsounds_Kenney/OGG/bookClose.ogg")), 0.8))
    tampo = pico(passa_baixa(tom(aparar(ler("x/100-CC0-wood-metal-SFX/wood_slam_02.ogg")), 0.7), 1500))
    salvar("menu_baque", sala(misturar((livro, 0.0, 0.8), (tampo, 0.0, 0.9)), 1.2, 0.22, brilho=2500.0, semente=22), alvo=0.9)
    salvar("menu_fosforo", sala(aparar(ler("x/sounds_8/match.wav")), 0.9, 0.2, semente=23), alvo=0.7)
    # A pena: um risco curto ao passar de uma entrada a outra, e um mais longo ao escolher.
    p = passa_alta(ler("x/pencil/ogg/pencil_write.ogg"), 1500)
    salvar("menu_pena", sala(p[seg(0.35) : seg(0.55)], 0.6, 0.15, semente=24), alvo=0.5)
    salvar("menu_risco", sala(p[seg(0.2) : seg(0.75)], 0.7, 0.15, semente=25), alvo=0.6)


def main():
    global FONTE
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    FONTE = sys.argv[1]
    os.makedirs(OUT, exist_ok=True)
    passos()
    portas()
    fogo()
    chuva_e_noite()
    relogio()
    telefone()
    papel()
    lama()
    alfinete()
    bebida()
    calha()
    menu()


if __name__ == "__main__":
    main()
