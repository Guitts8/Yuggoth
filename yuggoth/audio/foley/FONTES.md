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
| [50 RPG sound effects](https://opengameart.org/content/50-rpg-sound-effects) | Kenney (kenney.nl) | passos (o estalo grave), alfinete, porta_trinco, telefone_gancho, correio_fresta, pacote_chao, selo_batido, menu_capa, menu_baque |
| [Book Flip Sounds](https://opengameart.org/content/book-flip-sounds) | Voltiment555 | menu_folha |
| [Rain (loopable)](https://opengameart.org/content/rain-loopable) | Ylmir | chuva |
| [Fireplace Sound loop](https://opengameart.org/content/fireplace-sound-loop) | PagDev | lareira |
| [Fire Crackling](https://opengameart.org/node/16327) | AntumDeluge | lareira (os estalos) |
| [Various Paper Sound Effects](https://opengameart.org/node/127323) | Luckius | papel_pegar, papel_rasgando, correio_fresta |
| [Different steps on wood, stone, leaves, gravel and mud](https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud) | TinyWorlds | passo_madeira_1–3, lama |
| [Doorbell ring](https://opengameart.org/content/doorbell-ring) (Doorbell-old-tring, Wikimedia Commons) | — | campainha (o telefone de parede) |
| [Crickets Ambient Noise (loopable)](https://opengameart.org/content/crickets-ambient-noise-loopable) | Wolfgang_ | noite |
| [Wind](https://opengameart.org/content/wind) | IgnasD | noite (o vento por baixo), vento |
| [ticking clock](https://opengameart.org/content/ticking-clock) | bart | relogio |
| [Pencil Sounds](https://opengameart.org/node/132692) | NachtmahrTV (pencil_write) | pena, menu_pena, menu_risco |
| [100 CC0 metal and wood SFX](https://opengameart.org/content/100-cc0-metal-and-wood-sfx) | rubberduck | batidas_porta, pacote_chao, janela, menu_baque |
| [Various sound effects](https://opengameart.org/content/various-sound-effects) | laleksic | porta_rangendo, gaveta, fosforo, menu_fosforo |

Para refazer: baixe as fontes acima, extraia cada zip numa pasta `x/<nome do zip>/`
(os arquivos soltos em `zip/`) e rode `python -I tools/tratar_sons.py <pasta>` com
numpy, scipy e soundfile.
