# Sons gravados (audio/foley)

Playtest 8: *"melhorar os efeitos sonoros como um todo, estão bastante genéricos"*
e *"os efeitos sonoros do menu estão muito toscos"*. Gravações reais, todas **CC0**
(domínio público; nenhum crédito exigido — damos assim mesmo), baixadas de
opengameart.org em 2026-10-09 e tratadas por `tools/tratar_sons.py` (cortes, nível,
uma reverberação curta de sala, laços sem emenda, mudanças de altura). O
sobrenatural — o zumbido, o disco, as vozes, o sonho — continua sintetizado por
`tools/gerar_assets.gd` em `audio/placeholder/`.

| Fonte (CC0) | Autor | Usado em |
|---|---|---|
| [50 RPG sound effects](https://opengameart.org/content/50-rpg-sound-effects) | Kenney (kenney.nl) | passos (o estalo grave), alfinete, calha_correio, porta_trinco, telefone_gancho, correio_fresta, pacote_chao, selo_batido, menu_capa, menu_baque |
| [Book Flip Sounds](https://opengameart.org/content/book-flip-sounds) | Voltiment555 | menu_folha |
| [Rain (loopable)](https://opengameart.org/content/rain-loopable) | Ylmir | chuva |
| [Fireplace Sound loop](https://opengameart.org/content/fireplace-sound-loop) | PagDev | lareira |
| [Fire Crackling](https://opengameart.org/node/16327) | AntumDeluge | lareira (os estalos) |
| [Various Paper Sound Effects](https://opengameart.org/node/127323) | Luckius | papel_pegar, papel_amassado, papel_rasgando, correio_fresta, calha_correio |
| [Different steps on wood, stone, leaves, gravel and mud](https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud) | TinyWorlds | passo_madeira_1–3, lama |
| [Doorbell ring](https://opengameart.org/content/doorbell-ring) (Doorbell-old-tring, Wikimedia Commons) | — | campainha (o telefone de parede) |
| [Crickets Ambient Noise (loopable)](https://opengameart.org/content/crickets-ambient-noise-loopable) | Wolfgang_ | noite |
| [Wind](https://opengameart.org/content/wind) | IgnasD | noite (o vento por baixo), vento |
| [ticking clock](https://opengameart.org/content/ticking-clock) | bart | relogio |
| [Pencil Sounds](https://opengameart.org/node/132692) | NachtmahrTV (pencil_write) | pena, menu_pena, menu_risco |
| [100 CC0 metal and wood SFX](https://opengameart.org/content/100-cc0-metal-and-wood-sfx) | rubberduck | batidas_porta, pacote_chao, janela, menu_baque |
| [Various sound effects](https://opengameart.org/content/various-sound-effects) | laleksic | porta_rangendo, gaveta, fosforo, menu_fosforo |
| [202 More Sound Effects](https://opengameart.org/content/202-more-sound-effects) | OwlishMedia | gole |
| [Fantasy Sound Effects (Tinysized SFX)](https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx) | Vehicle | servir, servir_uisque, destampar_garrafa, destampar_frasco, calha_correio |
| [100 CC0 SFX](https://opengameart.org/content/100-cc0-sfx) | rubberduck | pousar_xicara |
| [Dog barking mono](https://opengameart.org/content/dog-barking-mono) (OGA-BY 3.0 e CC0; usado como CC0) | Brandon Morris | cao_latido_1–4, cao_latidos_longe (baixado em 2026-10-11, F4 da fazenda) |
| [Dog sounds](https://opengameart.org/content/dog-sounds) | pauliuw | cao_latido_5–6, cao_choramingo, cao_ganido |
| [Dog Snarl Grunt Grumble](https://opengameart.org/content/dog-snarl-grunt-grumble) | qubodup | cao_rosnado, cao_arreganho |

A rotina do entardecer (F5, `tratar_sons.py rotina`) usa as fontes que já estavam aqui:
racao (Tinysized coins-shake, mais grave, e rubberduck wood_misc), bomba_poco (rubberduck
wood_squeak e metal_hit, Tinysized water-pour), agua_bebedouro (rubberduck splash),
lenha_pegar/lenha_largar (rubberduck wood_hit, wood_falling), portao_correr (Kenney creak3,
rubberduck metal_sheet e wood_slam), caixa_correio (rubberduck metal_open).

A noite do telhado (F7, `tratar_sons.py telhado`) também usa só as fontes daqui:
baque_telhado (rubberduck explosion, wood_slam e wood_cracking, graves e abafados pelo
forro), unhas_telhado (rubberduck wood_hit e wood_misc em galope, laço), luta_telhado
(qubodup snarl/growl/grumble, Brandon Morris, rubberduck wood_hit), tiro_rifle (rubberduck
shot_01 e explosion), tiro_longe (rubberduck shot_02, com o eco do vale), vidro_estoura
(rubberduck glass_01/04/05 e hit_03), estilhaco_madeira (rubberduck wood_breaking_01 e
hit_01), cartucho_chao (Kenney metalClick, mais agudo, quicando) e poeira (sintetizada:
ruído filtrado e grãozinhos).

Para refazer: baixe as fontes acima, extraia cada zip numa pasta `x/<nome do zip>/`
(os arquivos soltos em `zip/`; os .7z dos cães em `x/dog_pauliuw/`, `x/dog_qubodup/`,
e os .wav de Brandon Morris em `x/dog_morris/`) e rode `python -I tools/tratar_sons.py
<pasta> [grupo ...]` com numpy, scipy e soundfile (ex.: `... <pasta> caes` refaz só os
cães).
