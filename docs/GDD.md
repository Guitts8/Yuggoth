# OS QUE SUSSURRAM
### Documento de Design de Jogo (GDD) — v0.4

> Terror psicológico em primeira pessoa · Godot 4.x · ~85 minutos
> Baseado em *The Whisperer in Darkness* (H. P. Lovecraft, 1931 — domínio público)

> **Regra de fidelidade (v0.4):** as situações do livro **acontecem no jogo**, jogadas ou vistas — não resumidas. Textos são tradução nossa e fiel do original inglês (`docs/fonte/`). O que este GDD inventa vale onde não contradiz o livro. Mapa completo, situação por situação: `docs/FIDELIDADE.md`.

---

## 1. Visão geral

| | |
|---|---|
| **Gênero** | Terror psicológico / horror cósmico narrativo (walking sim com investigação e escolhas) |
| **Perspectiva** | 3D, primeira pessoa |
| **Estética** | Low-poly estilo PS1: baixa resolução, vertex jitter, texturas 64–128px, névoa densa, paleta reduzida |
| **Duração alvo** | 80–90 min (primeira jogada), ~50 min (rejogada focada em outro final) |
| **Plataforma** | PC (Windows/Linux); controle e teclado/mouse |
| **Idioma** | PT-BR (principal), EN (localização) |
| **Combate** | Nenhum. Ameaça é sempre fuga, esconder-se ou escolha |

### 1.1 Pitch em uma frase
Um professor cético troca cartas com um fazendeiro isolado de Vermont que afirma ser vigiado por seres de outro mundo — até que as cartas começam a soar como se fossem escritas por outra pessoa.

### 1.2 Pitch estendido
Arkham, 1930. Albert N. Wilmarth, instrutor de literatura e estudioso de folclore da Universidade Miskatonic, escreve o relato do que viveu em 1928 — agora que os astrônomos anunciaram um nono planeta além de Netuno. O jogador revive esse relato: as cartas de Henry Akeley, as fotografias borradas, a pedra negra, o disco de fonógrafo com uma voz que zumbe em vez de falar. Depois, a viagem às colinas de Vermont e a noite na fazenda de Akeley, onde o anfitrião só consegue sussurrar e insiste que as luzes fiquem apagadas.

No meio do caminho, uma carta desesperada puxa o jogador para dentro dela: por quinze minutos ele **é Henry Akeley**, sozinho na fazenda com seus cães, na última noite em que ainda era ele mesmo. Quando Wilmarth chega à mesma casa, semanas depois, o jogador a conhece melhor do que o personagem — e sabe o que está faltando.

O jogo nunca confirma completamente o que é real. **A memória de Wilmarth é o nível** — e ela está sendo reescrita.

---

## 2. Pilares de design

1. **Dúvida acima de susto.** O medo vem de perceber inconsistências, não de coisas pulando na tela. Orçamento máximo: **2 jumpscares** no jogo inteiro.
2. **O que é dito vs. o que é visto.** O narrador (Wilmarth escrevendo o relato) descreve a cena; às vezes a cena discorda dele. O jogador aprende a desconfiar do texto.
3. **Escuridão como regra, não como filtro.** No Ato III a luz é uma escolha com consequência: acender revela, mas *ele percebe*.
4. **Fidelidade de espírito, liberdade de forma.** Os marcos do conto estão todos lá; a interatividade preenche os vazios que Lovecraft deixou implícitos.
5. **Escopo de uma hora.** Poucos ambientes, muito reaproveitados, cada um com densidade alta de detalhe narrativo.

---

## 3. Narrativa

### 3.1 Estrutura de moldura
O jogo abre e fecha em **Arkham, 1930** (o livro: "mais de dois anos" depois, já com Plutão descoberto), com Wilmarth à escrivaninha escrevendo seu relato à luz de lamparina. Cada capítulo é introduzido por uma frase que ele escreve (texto datilografado/manuscrito na tela, com som de pena). Essa moldura é o que permite o truque central:

- **Narração não confiável:** a frase de abertura de um trecho afirma algo ("a porta estava trancada") e o jogo mostra o contrário. Quanto mais o jogador se expõe ao sussurro, mais frequentes as discrepâncias.
- **Reescrita:** ao voltar à moldura entre capítulos, frases já escritas aparecem riscadas e corrigidas por outra caligrafia.
- **Regra de ritmo:** cada retorno à moldura dura **no máximo 1 minuto**. Ela existe para mostrar a reescrita, não para contar história.

### 3.2 Personagens

| Personagem | Papel | Notas de direção |
|---|---|---|
| **Albert N. Wilmarth** (jogador) | Professor cético, narrador | Nunca visto. Voz interna só em texto. Mãos visíveis ao segurar documentos. |
| **Henry Wentworth Akeley** | Fazendeiro erudito, correspondente | Presente via cartas (caligrafia manuscrita e nervosa). Em pessoa: "Akeley" na poltrona, no escuro, envolto em roupão, rosto rígido, mãos imóveis, voz sussurrada. |
| **Noyes** | Suposto amigo de Akeley, motorista | Cordial demais. Voz familiar — o jogador pode reconhecê-la do disco de fonógrafo (é a voz humana da gravação). |
| **Os de Fora / Mi-Go** | Os "fungos de Yuggoth" | Quase nunca vistos inteiros. Silhuetas, pegadas com garras, zumbido, asas membranosas sob luar. Fotografias sempre borradas. |
| **O cilindro** | Cérebro humano preservado num cilindro metálico | Fala por um aparelho de voz mecânica. Como no livro, o "cilindro novo e brilhante, **com o nome de Akeley**" — no qual "Akeley" manda não mexer — é o **verdadeiro Akeley**. |
| **Walter Brown** | Lavrador soturno, espião das criaturas | Só nas cartas: pegadas humanas dele entre as garras; some em setembro. |
| **"Stanley Adams"** | O homem de Keene | Magro, ruivo, rústico, voz grossa e zumbida que dá tontura e sono. Some com a pedra negra; manda o telegrama "AKELY". Só relatado. |
| **Nyarlathotep** (implícito) | O "Sussurrador" | Nunca nomeado diretamente como presente. O rosto e as mãos na poltrona são a revelação. |

### 3.3 Linha do tempo (fonte → jogo)

| Evento no conto | Como aparece no jogo |
|---|---|
| Enchentes de Vermont (nov. 1927), corpos estranhos nos rios | Recortes de jornal no quadro do escritório (Dia 1) |
| Wilmarth debate nos jornais, chamando tudo de mito | Rascunho ao *Arkham Advertiser* na mesa (Dia 1); abandonado no Dia 2 |
| Primeira carta de Akeley (5 de maio de 1928), na íntegra | Dia 1 |
| Segunda carta: fotografias (pegada, caverna, círculo de pedras, pedra negra, a casa) e a carta "enciclopédica" | Dia 2: fotos examináveis com lupa |
| O disco (1º de maio de 1915), a máquina emprestada, a transcrição | **Set piece** do Dia 3 |
| A pedra negra não chega: telefonemas, Keene, "Stanley Adams" | Dia 4, jogado no escritório; no Ato III o jogador **encontra a pedra** na casa |
| Agosto: tiros, cães mortos, cabo cortado; o telegrama "AKELY" e o desmentido | Dia 5 |
| As três últimas cartas manuscritas (5, 6 e 7 de setembro) | Dia 6 → **Interlúdio "O Cerco" (jogado como Akeley)**: as noites dessas cartas |
| O "mensageiro" humano admitido em casa (a carta datilografada o menciona) | Fim do Interlúdio: sinais, batidas, a voz de Noyes |
| Carta datilografada, calma, convidando; os telegramas; a valise | Dia 7 (fim do Ato I) |
| Viagem: trem, o relógio atrasado uma hora, Noyes, o West River, as pegadas na estrada | Ato II |
| Akeley no escuro, sussurrando; o lanche e o café; os cilindros; B-67; a revelação sobre Noyes | Ato III |
| A conferência noturna; Noyes roncando no sofá; rosto e mãos na poltrona; fuga no Ford | Clímax do Ato III |
| O xerife não acha nada; Brown desaparecido; Plutão | Epílogo (1930) |

### 3.4 Temas
- **Conhecimento como contaminação:** cada documento lido aproxima Wilmarth da verdade e do convite.
- **Identidade e corpo:** o cérebro sem corpo; o corpo sem dono; a voz que imita.
- **Ceticismo como defesa frágil:** o jogador escolhe o tom das respostas de Wilmarth; o ceticismo protege, mas também cega.

---

## 4. Estrutura e ritmo (~85 min)

```
Prólogo ─ Ato I (Dias 1–6) ─ Interlúdio: O Cerco ─ Ato I (Dia 7) ─ Moldura ─ Ato II ─ Moldura ─ Ato III ─ Epílogo
 3 min       20–24 min           13–15 min            3 min        1 min    8–10 min   1 min   25–30 min   3 min
```

Os "dias" do Ato I não têm todos o mesmo peso: alguns são curtos (uma carta, uma ação). O que importa é que cada situação do livro aconteça.

Curva de tensão planejada:

```
tensão
  ▲                                                                      ╭─╮ fuga
  │                            ╭─╮ batidas                        ╭──────╯ │
  │                          ╭─╯ │ na porta             ╭──╮  ╭───╯        │
  │           ╭─╮ fonógrafo ╭╯   │                 ╭───╯  ╰──╯ cilindros   ╰╮
  │         ╭─╯ ╰─╮  ╭─────╯     ╰╮carta     ╭────╯ chegada à fazenda       ╰ epílogo
  │  ╭─────╯      ╰──╯ cerco       ╰datilog.─╯ trem (respiro)
  └──┴────────────────────────────────────────────────────────────────────────▶ tempo
   Prólogo   Ato I   Interlúdio   Dia 7     Ato II            Ato III
```

O Interlúdio cria um **primeiro pico** antes da metade do jogo e faz a carta serena do Dia 7 cair como um golpe: o jogador acabou de ver como Akeley estava na noite anterior.

---

## 5. Roteiro por capítulo

### 5.0 Prólogo — "O Relato" (3 min)
**Local:** gabinete de Wilmarth em casa (Rua Saltonstall, 118), noite de chuva, **1930**.
**Objetivo:** ensinar controles (olhar, andar, interagir, examinar, ler) sem tutorial explícito.

Beats:
1. Tela preta. Som de pena. A primeira frase do livro: *"Tenham bem em mente que, no fim, eu não vi nenhum horror visual de fato."*
2. O jogador está sentado; levanta-se. Sala pequena: escrivaninha, caixa de cartas amarrada, a primeira folha do relato (o começo do livro), lareira apagada, janela com chuva.
3. Examinar a caixa de cartas → Wilmarth "abre as memórias". A sala se reorganiza em volta do jogador e vira o escritório da universidade, **maio de 1928**. **Sem loading visível** — troca de iluminação e props.

### 5.1 Ato I — "Correspondência" (20–24 min)
**Local:** escritório de Wilmarth na Miskatonic. **Um único ambiente reutilizado em 7 "dias".**
**Loop de cada dia:** chega correspondência → ler/examinar → (opcional) investigar o escritório → a ação do dia (resposta, telefonema, valise...) → ir para casa pela porta.

| Dia | Data | O que acontece (livro) | Interações | Ambiente |
|---|---|---|---|---|
| 1 | 5 de maio | A 1ª carta de Akeley, na íntegra | Ler; recortes no quadro (enchentes, o debate, o Pendrifter); rascunho ao *Arkham Advertiser*; **resposta** | Tarde ensolarada, pássaros |
| 2 | fim de maio | A 2ª carta, "quase por volta do correio": **as fotografias** e a carta "enciclopédica" (três horas de leitura) | Examinar as fotos com **lupa** (a caverna revela os rastros; no círculo de pedras não há nada; a pedra negra ao lado do busto de Milton; a casa e os cães); ler a carta — Wilmarth **se recusa** a transcrever certos trechos; **abandonar o rascunho do Advertiser** ("meu debate público acabou para sempre"); **resposta** | Anoitecer. O relógio da parede para de tocar 💭 |
| 3 | fim de junho | **O disco** chega, despachado de Brattleboro, com bilhete (medo das estradas, Walter Brown) | Pôr o cilindro na máquina **emprestada da administração** (uma máquina comercial, que chega montada); ler a **transcrição**; **tocar o disco** — quantas vezes quiser; **resposta** | Depois do disco: zumbido baixo permanente |
| 4 | 18–21 de julho | **A pedra não chega.** Telegrama de Bellows Falls: trem 5508. Wilmarth espera; telefona; interurbano para Boston; o relato do funcionário de Keene sobre **"Stanley Adams"** | **Telefone** de parede, ao lado da mesa: ligar para a agência de expresso, depois para a North Station; ditar o telegrama noturno a Akeley; ouvir o relato (voz que "dava tontura e sono"); cartão: a ida a Boston e a noite escrevendo cartas | Calor de julho; tarde passando no relógio parado |
| 5 | 15–29 de agosto | A carta do começo de agosto (tronco na estrada, tiro de raspão) e a frenética de 15/8 (3 dos 12 cães mortos, pegadas de Brown, cabo cortado), em letra trêmula; Wilmarth oferece ir a Vermont; o **telegrama "AKELY"**; o bilhete de Akeley: **ele nunca o mandou**; Wilmarth renova a oferta; a carta de 28/8 ("uma saída digna") | As cartas cruzam o correio: cada carta selada salta no tempo. A **oferta** e a **renovação** são cartas sem tom; telegrafar a resposta pelo telefone; **comparar a assinatura** do telegrama com as cartas → **primeira alteração de texto** (a carta de julho, relida); **resposta** do dia à carta de 28/8 ("a mais animadora que pude") | Noite, chuva. Um vulto passa pela janela (não confirmado) |
| 6 | 31 de agosto – 7 de setembro | Abre com a resposta mais calma de Akeley (só a lua cheia segura as criaturas; hospedar-se em Brattleboro). As **três últimas cartas manuscritas**: o telhado (segunda), "falaram comigo" (terça), a coisa morta que evapora e o filme vazio (quarta) | O ânimo (sem tom); cada carta lida traz a seguinte no dia seguinte (salto no tempo ao fechá-la); **resposta** (a carta registrada: "mude-se para Brattleboro"); selada, a letra da última carta enche a tela → **Interlúdio** (§5.1a) | Noite sem lua |
| 7 | 8–10 de setembro | A **carta datilografada**, serena, convidando; a noite em claro; os telegramas ("COMBINAÇÃO SATISFATÓRIA... NÃO ESQUEÇA DISCO CARTAS FOTOS") | Comparar com as cartas antigas (estilo, vocabulário, grafia); telegrafar a resposta; **arrumar a valise: leva tudo**, como no livro (§6.4) | Escritório "arrumado" sozinho 💭 |

> **Nota de ritmo:** os Dias 4 e 7 são curtos. O 7 vem logo depois do Interlúdio: o escritório calmo e a carta serena contra o que o jogador acabou de viver. Não alongar.

**Set piece: o fonógrafo (Dia 3)**
- A máquina comercial chega emprestada do prédio da administração; o jogador monta e prepara. O disco é um **cilindro de cera** gravado com ditafone ("cilindro de cera virgem", diz a 1ª carta).
- Antes, a transcrição de Akeley: 1º de maio de 1915, 1 da manhã, a boca fechada de uma caverna onde a encosta oeste da Montanha Escura sai do Pântano de Lee; véspera de maio, o Sabá.
- Áudio, na ordem do livro: ruídos, a **voz humana culta, bostoniana** ("...é o Senhor dos Bosques..." — "Iä! Shub-Niggurath! O Bode com Mil Crias!"), a resposta na **voz zumbida** ("Iä! Shub-Niggurath! O Bode Negro dos Bosques com Mil Crias!"), Azathoth, Yuggoth, Nyarlathotep, "a máscara de cera e o manto que esconde" — e o corte abrupto no fim.
- Durante a reprodução, a luz do escritório pulsa levemente no ritmo do zumbido. Os papéis na mesa tremem.
- 💭 Se o jogador parar e tocar de novo, a gravação **dura mais** — um trecho novo no fim: a voz zumbida diz "Wilmarth". (O livro: ele tocou "muitas outras vezes".)
- A voz humana do disco é a **mesma voz de Noyes** — no livro, quem revela isso é a voz do cilindro, no Ato III.

**Escolha de resposta (Dias 1 a 6):** (no Dia 4, as cartas da noite em claro, depois do relato de Keene) Wilmarth escreve a Akeley escolhendo o tom. O tom do livro é sempre uma das opções. Uma escolha de tom por dia: quando o livro tem várias cartas no mesmo dia (Dia 5), as outras são escritas sem escolha (não mexem em `crenca`).
- *Cético* → `crenca -1` · *Cauteloso* → `crenca 0` · *Crédulo* → `crenca +1`

Isso altera o conteúdo das cartas seguintes (Akeley responde ao que foi dito — sem contradizer os fatos do livro) e, principalmente, **como "Akeley" trata o jogador no Ato III**.

### 5.1a Interlúdio — "O Cerco" (13–15 min)
**Personagem:** Henry Wentworth Akeley. **Local:** a fazenda de Akeley — o **mesmo mapa do Ato III**, habitado e iluminado. **Datas:** as noites de 2 a 6 de setembro de 1928 (as cartas são de segunda 3, terça 4 e quarta 5; chegam a Arkham dois dias depois) — **o que as três últimas cartas contam**, agora jogado.

**Transição de entrada:** no Dia 6, selada a carta registrada, o fim da última carta manuscrita volta à tela. A câmera aproxima do papel; a caligrafia nervosa preenche a tela; a tinta se espalha e vira o céu de fim de tarde sobre o vale. O jogador está parado no quintal, segurando um balde de ração. As mãos são outras: mais velhas, sujas de terra.

**Os cães:** **doze cães policiais** no começo (como no livro), já menos a cada noite. Quatro têm nome e comportamento próprio (nomes provisórios **Brutus, Nell, Sargento, Rolo**): seguir o jogador, deitar perto da lareira, latir para a mata, rosnar para a janela. Os outros são presença no canil e no quintal.

**Beats (cada um é uma frase das cartas, vivida):**
1. **Entardecer — a rotina (3 min).** Alimentar os cães. Recolher lenha. Trancar o galpão. O narrador agora é Akeley, em frases das cartas que Wilmarth acabou de ler. Pássaros ainda cantam (e param).
2. **Preparação (2 min).** Fechar venezianas, acender lampiões, carregar o rifle de caça grossa (ação diegética, sem mira livre). As **máscaras de gás** dele e dos cães prontas na despensa (carta de quarta).
3. **A noite do telhado (4–5 min) — carta de segunda.** Céu fechado, sem lua. Depois da meia-noite, **algo pousa no telhado**; os cães correm; um deles sobe pelo puxado baixo; briga lá em cima, um **zumbido** que ele nunca vai esquecer, um **cheiro** horrível. Tiros entram pela janela. O jogador **apaga a luz** e atira das janelas, "alto o bastante para não acertar os cães" (interação única, câmera fixa na escuridão; nunca se vê o que é atingido). 💭 **Rolo** dispara para a mata e não volta.
4. **Manhã seguinte (2 min).** Poças de sangue no quintal e poças de uma **gosma verde** de cheiro insuportável; mais gosma no telhado. **Cinco cães mortos — um com um tiro nas costas** ("acho que acertei um mirando baixo demais"). Trocar os vidros quebrados. Linha telefônica muda.
5. **"Falaram comigo" (2 min) — carta de terça.** À noite, sobre os latidos, as **vozes zumbidas** falam com ele — e uma voz humana ajuda. Legendas parciais. Ele responde que não vai.
6. **A coisa morta (2 min) — carta de quarta.** De manhã, junto ao canil, um cão pegou uma delas. Carregá-la para o **galpão de lenha**; **fotografá-la**. Em poucas horas ela **evapora**. (A foto revelada mostrará só o galpão — o jogador a verá no Dia 7 ou no Ato III.)
7. 💭 **A carta verdadeira (2 min).** Akeley escreve a carta que **nunca será enviada**: *"Não venha, Wilmarth. Se receber algo com meu nome depois disto, não acredite. Eles querem me levar — não inteiro. Vi os cilindros brilhando no galpão deles, na mata. Se eu desaparecer, não confie em nada que fale com a minha voz. Procure o cilindro com o meu nome."* O jogador **escolhe onde escondê-la** (atrás do relógio da sala, dentro de uma bota no quarto, sob uma tábua solta do galpão). → flag `esconderijo_carta`.
8. **Os sinais — o mensageiro (1–2 min).** A carta datilografada dirá: *"em resposta a certos sinais, admiti em casa um mensageiro dos de fora — um ser humano"*. Os cães restantes estão quietos. Quietos demais. Batidas na porta. Uma voz humana, cordial: *"Sr. Akeley? Somos amigos. Viemos só conversar."* É a **voz de Noyes** — a mesma do disco. Ao tocar na maçaneta, ou após 40 s, a lamparina se apaga sozinha. Silêncio. Corte para o escritório de Wilmarth, Dia 7, a carta datilografada sobre a mesa.

**Pontes com o Ato III:**
| Plantado como Akeley | Colhido como Wilmarth |
|---|---|
| Os doze cães, quatro com nome | Nenhum cão, silêncio total (livro); 💭 canil vazio, coleiras penduradas |
| Disposição dos móveis, lampiões acesos em cada cômodo | Casa escura; móveis fora do lugar — **o jogador percebe a diferença, Wilmarth não** |
| Esconderijo da carta verdadeira | O jogador sabe onde procurar na Cena D (e ela está lá — ou foi movida, se `suspeita` alta) |
| A gosma verde no telhado e no quintal | A estrada empoeirada com pegadas-garra frescas (livro) |
| O galpão de lenha | O galpão: o Ford velho de Akeley (a fuga); 💭 a pedra negra no caixote com etiqueta do expresso de Keene |
| Poltrona de Akeley perto da lareira, onde ele lia | É a poltrona do Ato III — agora no canto escuro |
| A voz nas batidas da porta | Noyes na estação: o jogador já sabe quem ele é |

**Regras de design do Interlúdio:**
- Nenhuma escolha do Interlúdio pode salvar Akeley. O jogador sabe o fim; o horror é viver até ele.
- Os fatos das cartas acontecem sempre (o cão baleado pelas costas, a coisa que evapora): o jogador vive o que leu.
- O HUD e os controles são idênticos, mas Akeley anda um pouco mais devagar e a câmera tem leve oscilação de respiração ofegante — o corpo é outro.
- Não há dossiê de documentos (Akeley não é investigador), só o objeto em mãos.

### 5.2 Moldura I (1 min)
De volta ao gabinete de 1930. O jogador lê o que "escreveu" até agora. Uma frase está riscada e reescrita em caligrafia diferente, rígida, quase datilográfica. Se `exposicao` alta, duas frases.

### 5.3 Ato II — "A Viagem" (8–10 min)
Capítulo de **respiro e pavor lento**. Pouca interação, muita atmosfera. Tudo do capítulo VI do livro.

**Cena A — O trem (3 min)**
- Quarta-feira, 12 de setembro. Boston → Greenfield → Brattleboro, de dia (Wilmarth trocou o trem para não chegar à noite). Placas das estações passando: Waltham, Concord, Ayer, Fitchburg, Gardner, Athol.
- Pode andar pelo vagão. 💭 Passageiros dormindo (poses estáticas); um jornal abandonado com notícia sobre as enchentes.
- A **valise** com o disco, as fotos e todas as cartas está no assento. 💭 Se o jogador sair de perto dela e voltar, está aberta. Nada falta.
- O rio Connecticut brilhando ao sol. O **condutor** avisa que já é Vermont e manda **atrasar o relógio uma hora** — o jogador gira os ponteiros do próprio relógio de bolso ("como se eu voltasse o calendário um século").
- Do outro lado do rio, o monte Wantastiquet. O trem para sob o longo telhado da estação de Brattleboro.

**Cena B — Estação de Brattleboro (2 min)**
- Fila de carros esperando. Noyes se adianta: jovem, bem vestido, bigode escuro; **voz culta, de uma familiaridade vaga e perturbadora**. Akeley teve uma crise de asma. O carro é novo, com placa de Massachusetts.
- Diálogo curto. Noyes faz perguntas sobre o que Wilmarth trouxe. **Se o jogador tocou o disco duas vezes, uma opção de diálogo extra aparece:** "Já ouvi sua voz antes." Noyes ri e muda de assunto.

**Cena C — A estrada (3–4 min, on-rails no carro)**
- Brattleboro na luz da tarde. Depois, o **West River** — Noyes comenta o nome, e Wilmarth lembra que foi ali que viram uma das coisas depois das enchentes. Pontes cobertas, a ferrovia meio abandonada, desfiladeiros. **Newfane**, "o último elo com o mundo que o homem pode chamar de seu".
- O jogador olha livremente (câmera livre, carro em trilho). Conversa com Noyes por escolhas; ele **sonda** o que Wilmarth sabe.
- 💭 Algo grande de pé entre as árvores numa curva (só aparece se o jogador estiver olhando para o lado certo).
- Chegada: casa branca de dois andares e meio, gramado com pedras caiadas, celeiros, moinho; a **caixa de correio com o nome de Akeley**; a Montanha Escura atrás. Noyes entra para avisar.
- Sozinho na estrada, o jogador olha a poeira: entre as pegadas confusas, junto ao caminho da casa, **três marcas de garra frescas** (examináveis — "as pegadas infernais dos fungos vivos de Yuggoth"). Nenhum cão. **Silêncio total** — nem galinhas, nem porcos. O Ford velho de Akeley no galpão aberto. Nenhum lampião aceso — a casa que o jogador deixou toda iluminada no Interlúdio.
- Noyes volta: Akeley fala só em sussurro, os pés inchados enfaixados, os olhos não suportam luz; está no escritório, à esquerda do vestíbulo, de venezianas fechadas. Noyes parte de carro para o norte.

### 5.4 Moldura II (1 min)
Wilmarth escreve: *"A casa de Akeley ficava no fundo de um vale, com a Montanha Escura atrás."* A tinta escorre. A lamparina do gabinete de 1930 diminui sozinha.

### 5.5 Ato III — "A Casa" (25–30 min)
**Local:** fazenda de Akeley. Térreo (vestíbulo, escritório escuro, sala de estar, sala de jantar, cozinha), 1º andar (quarto de hóspedes sobre o escritório, banheiro, corredor), exterior (estrada, quintal, canil, galpão de lenha, celeiros).

**Cena A — O anfitrião no escuro (6–8 min)**
- O vestíbulo colonial, de bom gosto; um **cheiro** estranho. A porta branca de seis painéis à esquerda. O escritório escuro: cheiro mais forte, uma **vibração** quase imaginária no ar.
- "Akeley" na poltrona do canto mais escuro: roupão, **lenço amarelo** envolvendo a cabeça e o pescoço; rosto rígido, olhar vidrado que não pisca; as mãos pousadas sem vida no colo.
- Ele fala **somente em sussurro** (áudio: voz sussurrada com leve zumbido em baixa frequência por baixo). O bigode esconde os lábios.
- Pede que Wilmarth **ponha as cartas, as fotos e o disco na mesa** antes de subir — "é aqui que vamos discuti-los"; o fonógrafo dele fica no suporte do canto. O quarto é o de cima; há um lanche na sala de jantar.
- O discurso do livro: Einstein está errado; Yuggoth, as torres de pedra negra sem janelas, os rios de piche sob pontes ciclópicas, K'n-yan, Yoth, N'kai.
- Tom conforme `crenca` (crença baixa: mais sedutor, insistente; crença alta: já trata o jogador como "um de nós").
- **Com `crenca ≥ 3`**, surge a opção *"Eu quero ir."* → **Final Yuggoth — O Estudioso** (§7). "Akeley" pede uma confirmação ("Tem certeza? Não há volta."); a segunda é definitiva. O jogo não sinaliza que é um final.
- **Mecânica da lamparina:** à noite, Wilmarth acende uma pequena lamparina, chama baixa, sobre a estante **ao lado do busto de Milton** — e se arrepende, porque ela faz o rosto e as mãos parecerem de cadáver. 💭 Se aumentar a chama durante a conversa, "Akeley" para de falar. Silêncio total. Então: "Por favor." Aumentar de novo → Noyes não está; a lamparina se apaga sozinha. `suspeita +1`.

**Cena B — Os cilindros (4–5 min)**
- "Akeley" explica como cérebros humanos viajam em cilindros. A mão inerte se ergue pela primeira vez e aponta: na prateleira, **mais de uma dúzia de cilindros** de um metal desconhecido, com três soquetes em triângulo; num canto, os aparelhos com fios e plugues.
- **Puzzle diegético = as instruções do livro:** pôr na mesa o aparelho alto com duas lentes, a caixa com válvulas e caixa de som, e o aparelho com o disco de metal; subir na **cadeira Windsor** e pegar o cilindro **B-67** ("Pesado? Não importa! Confira o número"); **"Não mexa no cilindro novo e brilhante ligado aos dois aparelhos de teste — o que tem o meu nome."** Ligar cada aparelho ao soquete certo, virar os interruptores todos para a direita, na ordem.
- A **voz mecânica**, plana e metálica: um homem cujo corpo descansa dentro de Round Hill; conheceu os seres no Himalaia; esteve em 37 corpos celestes. E então: *"Acho que o Sr. Noyes também vai — o homem que sem dúvida o trouxe até aqui. Suponho que o senhor tenha reconhecido a voz dele como uma das que estão no disco."*
- Desligar os interruptores ("o das lentes por último"). Wilmarth sobe com a lamparina; **revólver** na mão direita, lanterna na esquerda (não há combate: o revólver nunca é usado).

**Cena C — O lanche e o café (2 min)**
- Na sala de jantar: sanduíches, bolo, queijo e uma garrafa térmica de café. "Akeley" diz que não pode comer nada; mais tarde, só leite maltado.
- **Escolha:** beber / provar e recusar (o livro: uma colherada — "um gosto levemente desagradável, acre" — e joga o resto fora ao lavar a louça) / não tocar.
  - Beber → `drogado = true`: visão borra, passos pesados, lamparina treme; o tempo da Cena D fica **limitado** (~6 min; se não chegar à Cena E, adormece → **Final Yuggoth — O Despertar**).

**Cena D — A noite (8–10 min) — núcleo de exploração**
- Wilmarth se deita vestido. Um relógio tiquetaqueia; nenhum som de bicho. Cochila — pedaços de sonho com paisagens monstruosas.
- Acorda com **tábuas rangendo no corredor** e alguém **mexendo no trinco** da porta do quarto. Para logo.
- Lá embaixo, a **conferência** (texto do livro): duas vozes zumbidas, a voz mecânica de um cilindro, um homem rústico, Noyes; passos soltos, de casco, no assoalho. Fragmentos legendados, incluindo os nomes de Akeley e de Wilmarth. Depois: um **bater de asas**, um **carro dando a partida e se afastando**, silêncio. Um ronco.
- Exploração furtiva: tábuas que rangem (posição no chão importa), a lamparina pode ser apagada para esconder-se.
- No sofá da sala de estar, quem ronca **é Noyes**.
- **Coisas a descobrir (opcionais).** A carta (1) leva ao cilindro (4); essa **cadeia** abre o Final Testemunha. A pedra (2) e os cães (3) enriquecem o epílogo.
  1. 💭 **A carta verdadeira de Akeley** — no esconderijo que o **próprio jogador escolheu no Interlúdio** (`esconderijo_carta`). Se `suspeita ≥ 2`, ela foi movida: a carta aparece dobrada no bolso do roupão, na poltrona (Cena E).
  2. 💭 **A pedra negra** "perdida em Keene", no galpão, no caixote com etiqueta do expresso. (Prova de que interceptavam tudo.)
  3. **Os cães** — o jogador pode chamá-los pelo nome no quintal. Nenhum responde. 💭 Chamar Rolo faz algo responder da mata, com a voz errada.
  4. **O cilindro com o nome de Akeley:** sobre a mesa do escritório, com visão e audição ligadas e o aparelho de fala ao lado. **No livro, Wilmarth não liga a fala — e se arrepende para sempre.** O jogo deixa fazer o que ele não fez: ligado, o cilindro fala com dificuldade, reconhece Wilmarth pelas cartas e diz uma só coisa com clareza: *"Me tire daqui."* O que ele quer *de verdade* só é revelado no epílogo Testemunha (depende de `crenca`). Depois, pode ser **carregado** (ocupa as duas mãos: sem lamparina).
- **Ameaça ativa (leve):** se `suspeita` alta ou o jogador fizer barulho, a conversa lá embaixo para. Passos (não humanos) sobem a escada. O jogador precisa voltar ao quarto ou se esconder (armário, sob a cama). **Não há game over por captura** — ser pego leva ao **Final Yuggoth — O Despertar**.

**Cena E — A poltrona (2 min)**
- O escritório escuro. A poltrona vazia: o roupão escorrendo do assento ao chão, o **lenço amarelo** e as enormes **ataduras dos pés** no chão. O cheiro e a vibração **sumiram** — só existiam perto de Akeley.
- A luz volta ao assento: entre as dobras do roupão, **três objetos** — o **rosto e as mãos de Henry Akeley**, perfeitos, com presilhas metálicas engenhosas.
- Este é o **jumpscare nº 1** — não um susto sonoro, mas uma revelação lenta: a câmera não se move sozinha, é o jogador que aproxima a luz. Um grito abafado (o de Wilmarth). Noyes continua roncando.

**Cena F — A fuga (2–3 min)**
- 💭 **Escolha silenciosa (Final Cinzas):** na porta do escritório, se estiver com a lamparina na mão, o jogador pode **arremessá-la** contra as estantes. O prompt diz apenas "Arremessar". Quem carrega o cilindro não tem a lamparina — as duas escolhas se excluem naturalmente.
- O jogador corre para o galpão, o **Ford velho de Akeley** (porta destrancada "agora que o perigo parecia passado"). Se houve incêndio, a casa arde no retrovisor.
- Fuga pela estrada escura, sem lua, até Townshend: faróis revelam por um frame silhuetas aladas e árvores que se curvam. **Jumpscare nº 2**: algo bate no teto do carro (uma vez, só som e câmera).
- Corte para branco.

### 5.6 Epílogo (3 min)
Volta ao gabinete de 1930. Varia por final (§7). Base comum, do livro: o xerife foi à fazenda e não achou nada — nem cilindros, nem pegadas, nem as provas da valise; só o roupão, o lenço amarelo e as ataduras no chão, e marcas de bala. Uma semana em Brattleboro perguntando por Akeley; Walter Brown entre os desaparecidos da região. E a notícia: um nono planeta avistado além de Netuno — **Plutão**. "Nada menos que a noturna Yuggoth."

---

## 6. Mecânicas

### 6.1 Controles base
| Ação | Teclado/Mouse | Controle |
|---|---|---|
| Mover | WASD | Analógico esq. |
| Olhar | Mouse | Analógico dir. |
| Interagir | E / clique esq. | A / X |
| Examinar (girar objeto) | Segurar clique dir. + mouse | Segurar LT + analógico |
| Lamparina (ajustar chama) | Roda do mouse / Q | Direcional ↑↓ |
| Agachar / andar devagar | Ctrl | B / Círculo |
| Dossiê (inventário de documentos) | Tab | Select |

Sem corrida. Velocidade de caminhada baixa e constante (exceto na fuga).

### 6.2 Documentos e releitura
- Todos os documentos ficam no **Dossiê** e podem ser relidos a qualquer momento.
- Cada documento tem **variantes de texto** condicionadas a flags. Ao mudar de variante, não há aviso: o jogador descobre relendo.
- Alterações planejadas: palavras trocadas, datas que não batem, um parágrafo novo, assinatura com letra diferente, uma frase no fim que "sempre esteve lá".

### 6.3 Variáveis ocultas
| Variável | Faixa | Aumenta com | Efeito |
|---|---|---|---|
| `crenca` | -4 … +4 | Respostas crédulas no Ato I, escolhas de diálogo | Tom de "Akeley"; libera "Eu quero ir" (≥ 3); **decide o pedido final do cilindro no Final Testemunha** |
| `exposicao` | 0.0 … 1.0 | Tocar o disco, reler documentos alterados, ficar perto dos cilindros, ouvir as vozes da noite | Intensidade do zumbido, distorção de pós-processamento, frequência de discrepâncias do narrador, corrupção de texto |
| `suspeita` | 0 … 3 | Acender a lamparina no escuro, fazer barulho | Frequência de patrulhas na Cena D; comentários de Noyes |
| `drogado` | bool | Beber o café | Limite de tempo na Cena D, efeitos visuais |
| `provas` | conjunto | Itens encontrados na fazenda | Detalhes dos epílogos (pedra negra, cães, a carta verdadeira) |
| `esconderijo_carta` | enum (relógio / bota / tábua) | Escolha no Interlúdio | Onde a carta verdadeira está no Ato III |
| `carrega_cilindro` | bool | Pegar o cilindro com o nome de Akeley após conversar com ele | Mãos ocupadas (sem lamparina); abre o Final Testemunha |
| `incendio` | bool | Arremessar a lamparina na Cena F | Final Cinzas |
| `atirou_na_mata` | bool | Disparar o rifle no Interlúdio | Buracos de bala na casa no Ato III (o livro: "marcas de bala do lado de fora e de dentro"); "Akeley" comenta: "Você ainda tem medo de nós, Henry?" — dito a Wilmarth |

**Nada disso é exibido na tela.** Não há barra de sanidade. A `exposicao` é comunicada só por áudio e imagem.

### 6.4 O que levar (fim do Ato I)
Como no livro, Wilmarth **leva tudo** — o disco, as fotografias e todas as cartas — numa valise, e não conta a ninguém aonde vai. Arrumar a valise é a tarefa do Dia 7: cada item que o jogador guarda é uma última olhada (e uma última releitura, onde os textos podem ter mudado).
- Não há como esconder itens em Arkham (decisão de 2026-10-02, fidelidade ao livro).
- No Ato III, "Akeley" pede que ponha tudo na mesa do escritório; no epílogo, nada disso é encontrado pelo xerife.

### 6.5 Narrador não confiável
- Frases de narração aparecem como texto na tela ao entrar em áreas-chave.
- Com `exposicao` baixa: narrador e cena concordam.
- Com `exposicao` alta: discrepâncias (ex.: "Não havia ninguém na estrada" enquanto uma silhueta está na estrada). Não há confirmação. Máximo de ~6 discrepâncias por jogada.

---

## 7. Finais

### 7.1 Visão geral

| # | Final | Condição | Tom |
|---|---|---|---|
| 1 | **A Fuga** (canônico) | Fugir na Cena F sem o cilindro e sem incêndio | Sobrevivência amarga; nada acabou |
| 2a | **Yuggoth — O Despertar** (involuntário) | Adormecer drogado ou ser pego na Cena D | Pavor. Prisão sem corpo |
| 2b | **Yuggoth — O Estudioso** (voluntário) | Escolher "Eu quero ir" na Cena A (`crenca ≥ 3`) | Maravilhamento que apodrece em horror |
| 3 | **Testemunha** (verdadeiro) | Carta verdadeira → conversar com o cilindro sem nome → fugir **carregando-o** | Trágico; a escolha final é do jogador |
| 4 | **Cinzas** (opcional de escopo) | Arremessar a lamparina na Cena F (sem o cilindro) | Libertação ou assassinato — ambíguo |

**Precedência** (caso mais de uma condição seja verdadeira): 2b > 2a > 3 > 4 > 1. Na prática, 3 e 4 se excluem (mãos ocupadas), e 2a/2b interrompem o jogo antes da Cena F.

### 7.2 Final 1 — A Fuga
Gabinete de 1930. Wilmarth termina o relato — o final do próprio livro. O zumbido, baixo, ainda está lá. Uma batida na porta. Ninguém. No capacho, uma carta **datilografada**, assinada "H. W. Akeley", convidando-o a voltar. O jogador pode abri-la ou não; se abrir, o texto é idêntico à carta do Dia 7, palavra por palavra — exceto a data. Fim.

### 7.3 Final 2a — Yuggoth: O Despertar (~4 min)
**Wilmarth acorda em Yuggoth como um cérebro num cilindro. Apavorado.**

- **Despertar:** tela preta total, sem som. Um estalo; a "audição" liga primeiro — chiado de microfone, zumbidos próximos. Depois a "visão": imagem monocromática em **baixíssima resolução** (≈160×90), com granulação e atraso, vinda de um sensor preso numa estante.
- **Controles:** só é possível **girar o sensor** num arco limitado e **tentar falar**. Não há corpo, não há movimento.
- **O vislumbre de Yuggoth:** pela abertura da galeria onde o cilindro está guardado, a paisagem descrita no conto — **torres em terraços, sem janelas**, pontes ciclópicas de uma raça mais antiga, **rios negros de piche** correndo sob elas, o céu sem estrelas próximas e o Sol reduzido a um ponto mais brilhante entre os outros. Mi-Go cruzam o ar, pousam, dobram as asas. A resolução do sensor nunca deixa ver com nitidez — o jogador vê *o bastante*.
- **Tentar falar:** o jogador escolhe frases desesperadas (*"Onde estou?"*, *"Me tirem daqui"*, *"Socorro"*). O aparelho de voz as reproduz em **tom mecânico, plano, calmo**. O grito sai como informação.
- **O vizinho:** um Mi-Go gira o sensor para a estante ao lado. Outro cilindro fala, com a mesma voz mecânica: *"Bem-vindo, professor. Eu também tive medo."* (Se o jogador não conversou com Akeley na Cena D, a voz não diz quem é.)
- **Fim:** o Mi-Go desconecta o sensor. Tela preta. Só o chiado da audição, que continua ligada. Depois, silêncio.
- **Epílogo curto:** gabinete de 1930. Alguém está sentado à escrivaninha, datilografando o relato. Rígido. Com o rosto de Wilmarth. As mãos não se movem como mãos.

### 7.4 Final 2b — Yuggoth: O Estudioso (~6 min)
**Wilmarth desperta em Yuggoth no corpo de um Mi-Go. Como estudioso, maravilhado.**

- **Despertar:** sem transição de horror — uma respiração que não é respiração, e o mundo se abre com **cores que não existem na Terra** (pós-processamento de falsa cor; paleta totalmente diferente do resto do jogo). A primeira música melódica do jogo começa aqui.
- **Controles:** andar, e **planar** entre terraços com as asas (saltos curtos guiados — não é voo livre). A voz do jogador, quando fala, é o zumbido que ele ouviu no disco do fonógrafo.
- **O que explorar (pequeno hub, 3 pontos de interesse):**
  1. **O observatório:** o Sol como uma estrela fraca. Ao focar, é possível achar a Terra — invisível. O narrador (agora sereno, sem discrepâncias) escreve: *"Nunca estive tão longe de casa, e nunca me senti menos perdido."*
  2. **A inscrição:** uma parede com os mesmos hieróglifos da **pedra negra**. Pela primeira vez o jogador consegue **lê-los** — o texto é revelado (payoff do Ato I). Se o jogador trouxe/encontrou a pedra, há um trecho extra.
  3. **O arquivo de cilindros:** estantes infinitas de cérebros de muitas espécies e eras, catalogados. Um deles, novo, recém-chegado, tem uma etiqueta em letras humanas: **"A. N. WILMARTH — ARKHAM — 1928"**.
- **O golpe final:** conectar o sensor ao cilindro de Wilmarth é opcional, mas o prompt pulsa. Ao conectar, ouve-se a **mesma voz mecânica e desesperada do Final 2a**: *"Onde estou? Me tirem daqui."* — o jogador que já viu o 2a reconhece a cena de dentro.
  - A pergunta nunca é respondida: **quem é o estudioso?** Wilmarth transplantado? Um Mi-Go que absorveu as memórias dele? O jogo não diz.
- **Escolha:** *desconectar* (o estudioso volta ao observatório, em paz; o narrador conclui o relato) ou *responder* ao cilindro (a voz zumbida do jogador diz: *"Bem-vindo, professor. Eu também tive medo."* — a mesma fala que o Final 2a ouviu).
- **Epílogo:** nenhum retorno a 1930. O relato termina escrito com os hieróglifos da pedra negra.

> **Por que funciona:** 2a e 2b são **a mesma cena vista dos dois lados**. Quem joga os dois descobre que o "vizinho" que o recebeu no 2a pode ter sido ele mesmo, no 2b.

### 7.5 Final 3 — Testemunha (verdadeiro)
**Cadeia:** carta verdadeira ("procure o cilindro com o meu nome") → ligar a fala do cilindro com o nome de Akeley (o que Wilmarth, no livro, não teve coragem de fazer) → carregá-lo na fuga. A pedra negra e os cães não são exigidos; só alteram frases do epílogo.

- Gabinete de 1930. O cilindro está na mesa, conectado a aparelhos improvisados. Meses se passaram; o relato está quase pronto.
- Akeley pede uma última coisa. **O pedido depende de `crenca`:**
  - **Crença baixa (≤ 0) — "Destrua-me."** Você nunca acreditou totalmente nele, e ele também já não acredita em salvação. Quer que acabe.
  - **Crença alta (≥ 1) — "Leve-me de volta."** Depois de meses de escuridão na mesa de um professor, Yuggoth é a única coisa que ele ainda consegue imaginar. Quer voltar para a fazenda, para *eles*.
- **Escolha do jogador:** atender ou recusar. Quatro desfechos curtos (texto final + uma imagem):
  | Pedido | Atender | Recusar |
  |---|---|---|
  | Destrua-me | O zumbido do jogo inteiro cessa por um instante. Luto. | Akeley passa a falar só com a voz mecânica, sem palavras. Wilmarth mantém uma testemunha que não quer mais testemunhar. |
  | Leve-me de volta | Wilmarth deixa o cilindro na estrada de Vermont, de madrugada. Algo pousa na mata. | Akeley repete o pedido todas as noites. A última página do relato é datilografada, não manuscrita. |
- A última frase do relato é escrita pelas duas mãos — a pena de Wilmarth e, ao fundo, o som de uma máquina de escrever.

### 7.6 Final 4 — Cinzas (opcional, último item antes do polimento)
- A casa queima no retrovisor durante a fuga. Epílogo: gabinete de 1930, um recorte de jornal — *"Incêndio destrói fazenda em Townshend; nenhum corpo encontrado."* Na foto granulada, em volta das cinzas, pegadas que não são de gente.
- **Pela primeira vez no jogo, o zumbido some completamente.** Silêncio absoluto por 20 segundos antes dos créditos.
- Ambiguidade: foi libertação para todos os cérebros, ou Wilmarth matou Akeley? O narrador não comenta. Se o jogador falou com o cilindro sem nome na Cena D, uma linha extra: *"Ele me pediu para tirá-lo de lá. Eu tirei."*

### 7.7 Rejogabilidade
Todos os finais são alcançáveis em ~45 min numa segunda jogada com conhecimento prévio. Uma tela de "fragmentos encontrados" no menu principal (sem conquistas numéricas) incentiva procurar o que faltou.

---

## 8. Direção de arte

### 8.1 Visual
- **Resolução de renderização:** 480×270 (16:9) ou 426×240, escalada em inteiros; a UI de documentos em resolução nativa para legibilidade.
- **Shaders:** vertex snapping (jitter), mapeamento de textura afim simulado, pós-processamento com dithering Bayer 4×4 e redução de cor (~15 bits → ajustável para 5 bits por canal).
- **Texturas:** 64×64 a 128×128, filtro nearest, sem mipmaps (ou mipmaps nearest). Paleta dessaturada: ocre, verde-musgo, marrom de madeira, azul de noite.
- **Névoa:** distância curta (8–25 m), cor mudando por cena. Esconde o limite dos cenários e o pop-in.
- **Luz:** 1–3 luzes dinâmicas por cena no máximo. A lamparina é a luz mais importante do jogo (OmniLight3D com flicker via ruído).
- **Personagens:** baixíssimo poly, rostos pintados em textura; "Akeley" com rosto deliberadamente rígido (é, literalmente, uma máscara).
- **Mi-Go:** nunca mostrados em luz direta. Silhueta rosada/crustácea com asas membranosas, sempre em movimento, sempre parcialmente oculta.

### 8.2 Referências
- Jogos: *Signalis*, *Iron Lung*, *Paratopic*, *Lost in Vivo*, *Faith*, *Buckshot Roulette* (atmosfera PS1 contida), *Return of the Obra Dinn* (documentos e dedução).
- Fotografia: fotos rurais da Nova Inglaterra dos anos 1920; enchentes de Vermont de 1927 (acervos públicos).
- Tipografia: máquina de escrever para cartas datilografadas; manuscrito cursivo para Akeley real; fonte serifada de época para o narrador.

### 8.3 Interface
- Diegética sempre que possível: documentos são objetos segurados nas mãos de Wilmarth, com versão "transcrita" legível alternável (tecla).
- Nenhum HUD permanente. Retícula: ponto discreto que muda sutilmente sobre interagíveis.
- Legendas sempre disponíveis, incluindo descrição de sons (`[zumbido distante]`).

---

## 9. Direção de som

O som carrega metade do terror. Prioridade de produção igual à do visual.

| Elemento | Descrição |
|---|---|
| **O zumbido** | Leitmotiv. Tom grave com modulação de insetos e formantes vocais. Controlado por `exposicao`: volume, filtro e quanto ele "forma palavras". |
| **O disco de fonógrafo** | Gravação cerimonial com chiado de 78 rpm, banda estreita (300 Hz–3 kHz), voz humana + voz zumbida. Peça de áudio mais importante do jogo. |
| **O sussurro de "Akeley"** | Voz sussurrada sem sonoridade vocal, com uma camada subsônica de zumbido quase inaudível. |
| **Voz mecânica dos cilindros** | Plana, monotônica, com artefatos de vocoder e ritmo levemente errado. |
| **Ambiente** | Arkham: chuva, relógio, cidade distante. Vermont: rios, vento em pinheiros, **ausência de pássaros** (notar o silêncio). **Pássaros só nas poucas cenas de dia que transmitem tranquilidade** (no escritório, só o Dia 1); à noite e nos dias tensos eles cessam. |
| **Música** | Mínima. Drones e cordas preparadas só em transições e no clímax. Silêncio é o padrão. |

Buses no Godot: `Master → Music, Ambience, SFX, Voice, Whisper` — `Whisper` com cadeia de efeitos própria (filtro, distorção, pitch) animada por código.

---

## 10. Arquitetura técnica (Godot 4.x)

### 10.1 Configuração do projeto
- **Renderer:** Forward+ (ou Mobile, se o alvo incluir hardware fraco). O visual PS1 é feito com shaders próprios, não depende de recursos avançados.
- **Renderização em baixa resolução:** mundo 3D dentro de `SubViewport` (480×270, `canvas_item` nearest) exibido por `TextureRect` escalado; UI numa `CanvasLayer` separada em resolução nativa. Evita que o texto dos documentos fique ilegível (o que aconteceria com `stretch_mode = viewport` global).
- **Física:** padrão (ou Jolt, se incluído na versão usada) — pouca física no jogo.
- **Input Map** definido no projeto; suporte a remapeamento no menu de opções.

### 10.2 Estrutura de pastas
```
res://
├─ addons/                  # plugins (ex.: Dialogue Manager)
├─ autoload/                # singletons
├─ components/              # nós reutilizáveis (Interactable, Examinable, Door, Hideout...)
├─ player/
├─ ui/                      # dossiê, leitor de documentos, legendas, menus
├─ narrative/
│  ├─ documents/            # .tres de DocumentData
│  ├─ dialogue/             # .dialogue
│  └─ narration/            # linhas do narrador (CSV/Resource)
├─ levels/
│  ├─ prologue/  act1_office/  act2_train/  act2_station/  act2_road/  act3_farm/  epilogue/
├─ sequences/               # scripts de cutscene
├─ shaders/                 # psx_lit, psx_unlit, post_dither, whisper_distort
├─ audio/  (music/ ambience/ sfx/ voice/)
├─ art/    (models/ textures/ materials/ fonts/)
└─ localization/            # pt_BR.csv, en.csv
```

### 10.3 Autoloads
| Autoload | Responsabilidade |
|---|---|
| `GameState` | Flags (`Dictionary[StringName, Variant]`), variáveis (`crenca`, `exposicao`, `suspeita`...), conjunto `provas`. Emite `flag_changed(name, value)`. |
| `Events` | Barramento de sinais globais (documento lido, capítulo iniciado, lamparina alterada...). |
| `SceneDirector` | Troca de cenas com transição (fade, "reorganização" da sala), carregamento assíncrono com `ResourceLoader.load_threaded_request`. |
| `AudioDirector` | Camadas de ambiente, crossfades, controle do bus `Whisper` a partir de `exposicao`. |
| `Narrator` | Exibe linhas do narrador; resolve variantes e discrepâncias. |
| `SaveSystem` | Checkpoint por capítulo/cena. Serializa `GameState` em JSON em `user://`. |

### 10.4 Sistemas-chave

**Interação**
- `RayCast3D` na câmera (alcance ~2 m) → nó com componente `Interactable` (script em `Area3D`/`StaticBody3D`) com `prompt`, `enabled`, sinal `interacted(player)`.
- `Examinable` estende `Interactable`: move uma cópia do mesh para um `SubViewport` de inspeção, rotação por input, zoom, e pontos de interesse (hotspots) que disparam flags.

**Documentos**
```gdscript
# narrative/document_data.gd
class_name DocumentData extends Resource
@export var id: StringName
@export var title: String
@export var style: Style            # MANUSCRITO, DATILOGRAFADO, JORNAL, TELEGRAMA
@export var pages: Array[String]    # BBCode (suporta tags customizadas)
@export var variants: Array[DocumentVariant]  # avaliadas por prioridade

func resolve_pages() -> Array[String]:
    for v in variants:
        if v.condition.is_met(GameState):
            return v.pages
    return pages
```
- `DocumentVariant.condition` é um Resource de condição (flag == valor, variável ≥ limiar, AND/OR) reaproveitado por diálogos, narrador e gatilhos.

**Texto corrompido**
- `RichTextEffect` customizado (`[sussurro]...[/sussurro]`) que faz jitter de caracteres e troca glifos ocasionalmente, intensidade ligada a `exposicao`.

**Diálogo**
- Recomendado: plugin **Dialogue Manager** (Nathan Hoad) — sintaxe em texto, condições e mutações chamando `GameState` diretamente, fácil de localizar. Alternativa: sistema próprio sobre `Resource` se quiser controle total.

**Sequências / cutscenes**
- Scripts `await`-based (`Sequence.gd` com utilitários `wait()`, `move_to()`, `look_at_target()`, `say()`), combinados com `AnimationPlayer` quando há câmera coreografada. Mantém a lógica de cena legível e testável.

**Lamparina**
- `OmniLight3D` com energia/alcance interpolados, flicker via `FastNoiseLite`. Emite `Events.lamp_changed(intensity)` → a IA de "Akeley"/Noyes escuta.

**Furtividade (Ato III, Cena D)**
- Pontos de ruído: tábuas marcadas por `Area3D` com peso de ruído. Ruído acumulado decai com o tempo; limiar dispara a patrulha.
- A "patrulha" é um roteiro, não IA de busca: passos percorrem um `Path3D` predefinido até o quarto; o jogador precisa estar em um `Hideout` ou na cama. Simples, previsível, confiável.

**Pós-processamento por exposição**
- `ShaderMaterial` no `TextureRect` do mundo: dithering + redução de cor fixos; parâmetros `distortion`, `chromatic`, `vignette` ligados a `exposicao` e picos pontuais.

### 10.5 Shaders PSX (resumo)
- **Vertex snapping:** no `vertex()`, levar posição a clip space, dividir por `w`, arredondar para a grade da resolução alvo, multiplicar de volta.
- **Textura afim:** passar `UV * w` e `w` como varyings e dividir no `fragment()` (emula ausência de correção de perspectiva). Intensidade ajustável para não enjoar o jogador.
- **Iluminação:** `render_mode vertex_lighting` ou iluminação simplificada para o visual Gouraud.
- Opção de acessibilidade no menu: reduzir jitter/efeitos afins/distorção.

### 10.6 Salvamento
- Checkpoints automáticos no início de cada cena. Um único slot + "continuar".
- Salva: cena atual, `GameState` completo, documentos no dossiê e variantes já vistas.

---

## 11. Conteúdo a produzir

### 11.1 Ambientes
| Ambiente | Reuso | Complexidade |
|---|---|---|
| Gabinete 1930 / escritório Miskatonic | Mesma planta, dois "vestidos" (+ variações por dia) | Alta (muitos props interativos) |
| Vagão de trem | Um vagão modular | Baixa |
| Estação de Brattleboro | Plataforma + fachada | Baixa |
| Estrada das colinas | Trilho com módulos de terreno repetidos | Média |
| Fazenda de Akeley (interior 2 andares + exterior) | Interlúdio (habitada, dia/noite) + Ato III (abandonada). Mesma geometria; dois conjuntos de iluminação e dressing de props | **Alta** (mas paga dois capítulos) |
| **Yuggoth** (Finais 2a e 2b) | Mesmo cenário nos dois: 2a vê de um ponto fixo em baixa resolução; 2b explora um hub pequeno (observatório, parede de inscrições, arquivo). Silhuetas e névoa escondem a escala | Média |
| Fazenda em chamas (Final 4) | Mesmo mapa, visto do carro; fogo com partículas + luzes | Baixa–média |

### 11.2 Documentos (estimativa)
- ~8 cartas de Akeley (+ variantes), 4 respostas de Wilmarth (por escolha), 1 telegrama, 3 recortes de jornal, 4 fotografias, 3 cartas verdadeiras não enviadas, páginas do relato (moldura).
- Texto todo **original**, adaptado do conto em inglês (domínio público). Evitar copiar traduções publicadas em português, que podem ter direitos próprios.

### 11.3 Áudio
- ~15 minutos de ambiente em loop, ~120 SFX, disco de fonógrafo (~90 s), vozes: Noyes, sussurro de "Akeley", cilindro (voz mecânica), Akeley real no cilindro, cultistas no disco.

### 11.4 Personagens 3D
- Noyes (animações: andar, gesticular, servir), "Akeley" sentado (quase sem animação — proposital), silhueta de Mi-Go (voo, pouso), mãos de Wilmarth (segurar documento, segurar lamparina).
- **Mi-Go completo** (para Yuggoth): antes só visto em silhueta; agora aparece inteiro, mas sempre filtrado pelo sensor (2a) ou pela falsa cor (2b). Animações: pousar, andar, ajustar aparelhos, planar. No 2b também serve de corpo do jogador (só as "mãos"/garras em primeira pessoa).
- **Novo (Interlúdio):** mãos de Akeley (balde, lenha, rifle, pena); **cão pastor** low-poly — um modelo, 4 texturas/tamanhos, animações: idle, andar, correr, deitar, latir, rosnar. É o asset animado mais caro do jogo; manter comportamento com máquina de estados simples + `NavigationAgent3D` só para seguir o jogador.

---

## 12. Plano de produção

**Estratégia: por lugar, em ordem.** Cada bloco é terminado (jogabilidade, arte, som) antes de começar o próximo. A ordem da *história* não muda (§4); só a ordem de *construção*. A fazenda é um mapa só, então Interlúdio e Ato III são construídos juntos, já sabendo tudo o que ela precisa.

| Marco | Conteúdo | Critério de pronto |
|---|---|---|
| **M0 — Protótipo** ✅ | Player, interação, leitor de documentos com variantes, `GameState`, shader PSX, pipeline de SubViewport | Andar numa sala cinza, ler uma carta que muda após um flag |
| **E — Escritório** | Fundação (`SaveSystem`, `SceneDirector`, `AudioDirector`, `Narrator`, `Examinable`, menu e opções mínimas); Prólogo, Dias 1–6, fonógrafo, telefone, respostas; arte e som finais do escritório; voz de Noyes no disco | Prólogo → Dia 6 jogável com aparência e som de lançamento |
| **Demo** | Tela final "continua" na transição do Dia 6 (tinta → céu de Vermont); acessibilidade (jitter/afim/FOV), legendas, export, playtest 5+ pessoas | Build publicada |
| **E2 — Escritório (resto)** | Dia 7 e a valise (§6.4), Molduras I e II, epílogo de 1930 (base comum aos finais) | Todo o conteúdo do escritório pronto |
| **B — Ato II** | Trem, estação, estrada, Noyes 3D | Dia 7 → Ato II contínuos |
| **F — Fazenda** | Planta única; Interlúdio (habitada, cães, rifle, carta verdadeira); Ato III (abandonada, cenas A–F, lamparina, furtividade, cilindros); finais 1, 2a, 2b, 3 e Yuggoth | Jogo completo |
| **F.5 — Final Cinzas** | Arremesso da lamparina, incêndio, epílogo | Só entra se F fechar no prazo; senão vira atualização pós-lançamento |
| **D — Polimento** | Localização EN, performance, ajuste de ritmo | Playtest do jogo completo |

**Regras da demo:**
- Termina no Dia 6, ao ler a última carta manuscrita. O Interlúdio (e os cães) ficam para o jogo completo.
- Saves da demo **não** são garantidos no jogo completo. Nenhum flag precisa ser congelado.
- A voz de Noyes entra na demo (disco do Dia 3); a mesma pessoa é reaproveitada no Interlúdio e nos Atos II e III.

**Risco aceito:** o Ato III, maior risco de design, é validado por último. Como nada da demo depende da fazenda, mudanças nele não afetam o que já foi lançado.

**Estado (2026-10-08):** M0 ✅. Marco E em andamento — fundação ✅; Prólogo e Dias 1–6 jogáveis com o fim da demo (a tinta → o céu de Vermont → menu). O **escritório v2** (`docs/PLANO_ESCRITORIO.md`, o diário de bordo) já fez o look-dev (luz por pixel, facetas, lâmpada de banqueiro, 480 linhas), a sala nova, o correio pela fresta, a selagem em 3D, a carta postada na calha de correio do corredor, o telefone com som, a lareira, o lapso na própria sala, a vinheta de Boston, a criatura no céu, os sonhos entre os dias, o diário que leva a eles (e que se folheia), café e uísque antes de escrever, o sono em lugares diferentes, e uma primeira passada de acabamento (Arkham em 3D pela janela, texturas, móveis). Tudo ainda com arte e som provisórios (gerados por script). Falta no marco E: o playtest 4 do v2 (o que ainda parece tosco), o mapa de Vermont, a sala que acumula, as estranhezas, a arte e o som finais (`docs/ARTE.md`) e a voz de Noyes no disco. Falta no marco Demo: opções de acessibilidade (jitter/afim/FOV — ainda não existem em `Settings`), presets de export (ainda não há `export_presets.cfg`) e o playtest com 5+ pessoas. O que cada parte já tem: `docs/SEQUENCIA.md`.

### 12.1 Riscos
| Risco | Mitigação |
|---|---|
| Ato III virar grande demais | Casa com no máximo ~10 cômodos; exploração opcional limitada a 4 descobertas |
| Interlúdio crescer e virar um segundo jogo | Teto fixo de 15 min; sem novas mecânicas além de cães e rifle diegético; tudo que não planta algo para o Ato III é cortado |
| Yuggoth decepcionar depois de uma hora de sugestão | Nunca mostrar com nitidez: 2a limitado pelo sensor, 2b pela falsa cor e névoa; escala por silhuetas, não por detalhe |
| Final 2b ser raro demais (exige `crenca ≥ 3`) | Garantir que respostas crédulas no Ato I somem +4 com folga; testar se jogadores encontram a opção |
| Cães parecerem robóticos e quebrarem o clima | Poucos comportamentos, bem animados; em dúvida, deixá-los deitados e latindo, que é o que mais importa |
| Discrepâncias do narrador passarem despercebidas | Playtest específico; pelo menos 1 discrepância "obrigatória" e evidente no Ato II |
| Jogo parecer só leitura | Todo documento importante tem um objeto físico examinável associado; alternar leitura com ação espacial |
| Visual PSX causar enjoo | Opções de acessibilidade para jitter/afim/FOV |
| Áudio de qualidade (vozes) | Poucas vozes; sussurro e voz mecânica escondem limitações de gravação; o disco pode ser totalmente processado |

---

## 13. Questões em aberto
- [x] Nome final do jogo: **Yuggoth** (playtest 8; antes *Os que Sussurram*).
- [x] ~~Pedido do cilindro de Akeley~~ → depende de `crenca` (§7.5).
- [x] ~~Yuggoth voluntário~~ → dois finais separados, 2a e 2b (§7.3–7.4).
- [ ] Texto da inscrição da pedra negra revelada no Final 2b.
- [ ] No 2b, o planar entre terraços precisa de física própria ou basta um salto guiado por `Path3D`?
- [ ] Haverá dublagem das cartas (leitura em voz alta opcional) ou apenas texto?
- [ ] Usar Dialogue Manager ou sistema de diálogo próprio?
- [x] ~~Resolução de renderização definitiva~~ → ~480 linhas (shrink inteiro: 540 em 1080p), decidido no look-dev do escritório v2.
- [ ] Nomes definitivos dos cães (o conto não os nomeia).
- [ ] No Interlúdio, abrir a porta mostra algo (uma silhueta, por um frame) ou a lamparina apaga antes?
- [ ] Extras se sobrar tempo: biblioteca da Miskatonic (*Necronomicon*) e agência de transporte em Keene (a pedra some).
