# Plano — a fazenda de Akeley (o Interlúdio na demo)

Diário de bordo da fazenda, no mesmo formato do `docs/PLANO_ESCRITORIO.md`: cada
fase, o porquê, o que foi feito (com o commit) e os próximos passos.
Legenda: ✅ feito · 🔧 claro, a fazer · ❓ espera resposta · 💭 nosso (o livro não diz).

## A decisão (2026-10-09)
Depois do playtest 8 (*"nos últimos dias, muitas cartas sem nada acontecer"*), o
usuário perguntou se o Interlúdio entrava na demo. Recomendado e escolhido: **um
recorte do Interlúdio na demo** — os beats 1 a 3 do GDD §5.1a (o entardecer, a
preparação, a noite do telhado), uns 8–10 minutos, e o "continua" no ponto mais alto.
O resto (a manhã do sangue e da gosma verde, "falaram comigo", a coisa morta no
galpão, a carta verdadeira escondida, o mensageiro) fica para o jogo completo.

**Por quê:** o GDD chama o Interlúdio de "o primeiro pico" (§4); a demo terminava
numa sequência de cartas. E a fazenda é o mapa mais caro e o maior risco (o Ato III
é a mesma planta): construí-la agora a valida cedo, com o playtest de 5+ pessoas.
**Custo aceito:** a demo sai mais tarde; a ordem de produção vira escritório →
**fazenda** → Ato II (era escritório → Ato II → fazenda). O GDD §12 foi atualizado.

**Quando começar:** depois do playtest 9 (a Fase 3j do escritório). As Fases 4–6 do
escritório (o mapa de Vermont, a sala que acumula, as estranhezas) continuam na
demo; a ordem entre elas e a fazenda se decide depois do playtest 9.

## O que o livro diz da fazenda (a planta serve aos dois capítulos)
Do conto (`docs/fonte/the_whisperer_in_darkness_1931.txt`), traduções nossas:
- **A casa** (a foto do Dia 2 e a chegada no cap. VI): *"uma casa branca, bem cuidada,
  de dois andares e sótão, de uns cento e vinte e cinco anos"*, *"de tamanho e
  elegância incomuns para a região"*; *"um gramado bem tratado e um caminho margeado
  de pedras até uma porta georgiana entalhada com gosto"*; o gramado vai até a
  estrada, com *"uma borda de pedras caiadas"*; a **caixa de correio de ferro
  galvanizado** com o nome de Henry Akeley, junto à estrada.
- **Atrás e à direita:** *"um amontoado de celeiros, galpões e um moinho de vento,
  contíguos ou ligados por arcadas"*; o **Ford velho** num abrigo grande e aberto; o
  **galpão de lenha**; o **canil**.
- **Atrás da casa:** *"um trecho plano de terreno pantanoso e de mata rala"*, e além
  dele *"uma encosta íngreme, de mata fechada, que termina numa crista recortada de
  folhas"* — **o cume da Dark Mountain**; a casa fica a meia encosta.
- **Por dentro** (cap. VI–VII e GDD §5.5): o vestíbulo colonial *"de muito bom gosto"*;
  à esquerda, a **porta branca de seis painéis com trinco de latão** do **escritório**
  (com a poltrona no canto); a sala de estar, a sala de jantar, a cozinha; em cima, o
  **quarto de hóspedes sobre o escritório**, o banheiro, o corredor.
- **A noite do telhado** (a carta de segunda, Dia 6): *"Depois da meia-noite algo
  pousou no telhado da casa, e os cães todos correram para ver o que era. [...] um
  deles conseguiu subir no telhado pulando do **puxado baixo**. Houve uma briga
  terrível lá em cima, e ouvi um zumbido medonho que nunca vou esquecer. E então um
  cheiro chocante. Mais ou menos ao mesmo tempo, balas entraram pela janela e quase
  me pegaram. [...] Apaguei a luz e usei as janelas como seteiras, e varri a casa
  toda com tiros de rifle mirados alto o bastante para não acertar os cães."* Céu
  fechado, sem chuva, sem lua; a noite de domingo, 2 de setembro de 1928.

A planta é feita **inteira** de uma vez (o exterior, o térreo e o primeiro andar,
mesmo o que a demo não usa), já sabendo o que o Ato III pede (§5.5: o escritório
escuro com a poltrona, a sala de estar com o sofá de Noyes, as tábuas que rangem no
corredor de cima, o quarto de hóspedes, o abrigo do Ford, a estrada). O que a demo
usa ganha o acabamento primeiro.

## As fases (em ordem)
1. ✅ **F1 — A planta em bloco** (2026-10-10, enquanto o usuário não podia jogar o
   playtest 10; commit `3e1c666`). `tools/gerar_fazenda.gd` (+ `.tscn`; `comandos.ps1 gerar-fazenda`)
   monta `levels/fazenda/fazenda.tscn` (script `Fazenda`, `levels/fazenda/fazenda.gd`);
   as malhas grandes vão em `levels/fazenda/malhas/*.res` (binárias: em texto a cena
   passava de 19 MB). Tudo o que é fixo vira **uma malha por material** (`_bloco`,
   `_parede`, com as faces partidas em células de até 0,75 m, cor por vértice); só o
   que vai se mexer é nó à parte (as folhas das portas, as venezianas — com a meta
   `aberta`, para a F6 fechar). A colisão é uma lista de caixas (`_col`) e, no chão,
   a malha do terreno.
   - **Onde fica cada coisa** (o livro: a casa à esquerda de quem sobe a estrada para
     o norte; os celeiros "atrás e à direita"): a estrada de terra corre de norte a
     sul a leste (x 28..33); a casa, de frente para ela, em x −3..6, z −6..6. O
     gramado até a estrada com a **borda de pedras caiadas** e o **caminho de lajes
     margeado de pedras** até a **porta georgiana** (as pilastras, o frontão, a
     bandeira em leque; a folha branca de seis almofadas). A **caixa de correio de
     ferro galvanizado** com "H. W. AKELEY" junto à estrada. Atrás e à direita
     (noroeste): o **puxado baixo** da cozinha (de um andar, com a despensa), o
     **galpão de lenha** encostado nele (a lenha empilhada, o cepo, o machado), a
     **arcada** coberta até o **celeiro** grande de tábuas vermelhas (o portão de
     correr aberto, o palheiro, as baias, a carroça), o galinheiro e o chiqueiro, o
     **moinho** de torre de madeira; o **canil** comprido de doze baias com as
     plaquinhas dos nomes e o cercado de tela; ao norte da casa, o **abrigo grande e
     aberto do Ford** (o Modelo T), com a entrada de carro. Atrás (oeste), o
     **pântano** de mata rala (as poças, as bétulas, os troncos mortos, os juncos) e,
     além de um muro de pedra, a **encosta da Dark Mountain**, de mata fechada até a
     crista; a leste, depois da estrada, o vale e os morros do outro lado. A área de
     andar é cercada por **muros de pedra seca**.
   - **A casa por dentro** (centro-hall georgiano, de frente para o leste): o
     **vestíbulo** de ponta a ponta, com a **escada** subindo para oeste rente à
     parede norte (andável, com o corrimão e o pilar no pé) e a porta dos fundos
     para o pântano; à esquerda de quem entra (sul) o **escritório** — a mesa grande
     do meio, a **poltrona no canto mais escuro** (sudoeste), as estantes, o suporte
     no canto, a lareira; a **sala de jantar** logo depois dele (a porta entre os
     dois), e o **puxado da cozinha** mais além na mesma direção (o livro); ao norte,
     a **sala de estar** (o sofá de Noyes, as poltronas) e a sala dos fundos (o
     armário dos rifles, a bancada). Duas chaminés de tijolo na parede do meio, com
     as lareiras costas com costas. Em cima: o **quarto de hóspedes sobre o
     escritório**, o quarto de Akeley, os dois de trás, e o **banheiro no alto da
     escada**, no fim do corredor; o sótão (a "meia" casa) fica fechado. O telhado
     de duas águas, a cumeeira de norte a sul, mais alto que o do puxado — de onde o
     cão pula para ele.
   - **Janelas** de guilhotina, seis por seis, **sem vidro** (o vidro opaco do PSX
     não deixava ver lá fora; na noite do telhado elas são seteiras); as venezianas
     verdes abertas contra a parede.
   - **Provisório:** a luz (uma tarde qualquer; a de verdade é a F2), as cores do
     interior (reboco claro em tudo), os móveis em bloco.
   - **Para ver:** a fazenda ainda não está no roteiro. No build de teste, **F4** vai
     ao quintal e volta ao escritório (`Depuracao.fazenda()`).
   - **Teste:** o de fumaça anda do quintal pelos degraus ao vestíbulo, sobe a escada
     até o quarto de hóspedes, desce, sai pelos fundos e entra no celeiro (0 falhas).
   - **Próximo: a F2** (o entardecer de setembro, e a tinta da última carta caindo no
     quintal). O usuário confere a planta no playtest 10 (`docs/PLAYTEST.md` §0b).
2. 🔧 **F2 — O entardecer de setembro.** A luz, o céu e a névoa do vale (reusar
   `tools/vistas.gd` e o céu da `TintaTransicao`, que já seca num fim de tarde sobre
   os morros): a tinta da última carta passa a cair no quintal, com Akeley parado,
   segurando o balde de ração (GDD: *"as mãos são outras"*).
3. 🔧 **F3 — Akeley.** O mesmo Player, mais lento, com a respiração ofegante na câmera
   (GDD §5.1a: "o corpo é outro"); sem dossiê; o narrador passa a ser Akeley, com
   frases das cartas (tradução nossa). Os objetos na mão como a carta do escritório
   (`CartaSaida`), sem corpo (ver ❓ abaixo).
4. 🔧 **F4 — Os cães.** Um cão pastor provisório de primitivas (como o `Migo`), quatro
   com nome e comportamento (seguir, deitar junto ao fogo, latir para a mata, rosnar
   para a janela) numa máquina de estados simples; os outros, presença no canil e no
   quintal (doze no começo, como no livro). O asset animado mais caro: manter simples.
5. 🔧 **F5 — Beat 1, a rotina** (~3 min): alimentar os cães, recolher a lenha, trancar
   o galpão; os pássaros que cantam e param.
6. 🔧 **F6 — Beat 2, a preparação** (~2 min): fechar as venezianas, acender os
   lampiões, carregar o rifle (diegético, sem mira livre); as máscaras de gás na
   despensa (a carta de quarta).
7. 🔧 **F7 — Beat 3, a noite do telhado** (~4–5 min): céu fechado, sem lua; depois
   da meia-noite, algo pousa no telhado (só som e a poeira caindo do forro), os cães
   correm, um sobe pelo puxado baixo, a briga lá em cima, o zumbido, o cheiro; balas
   entram pela janela; **apagar a luz** e atirar das janelas, alto (uma interação,
   no escuro; nunca se vê o que é atingido). Nenhum susto além dos dois do jogo.
8. 🔧 **F8 — O fim da demo.** Depois dos tiros, o silêncio, e o cartão *"Fim da
   demonstração. A história continua."* (sai do fim do Dia 6 e vem para cá); o
   checkpoint no começo do Interlúdio; o teste de fumaça joga o recorte inteiro.

## Perguntas para o usuário (respondidas em 2026-10-10)
- ✅ **As mãos: sem corpo.** Os objetos seguram-se diante da câmera, como a carta no
  escritório, sem mãos (a recomendação, aceita). O rifle é o caso mais difícil
  (apontar pela janela).
- ✅ **Os nomes dos cães.** O livro não dá nome a nenhum: são só *"my great police
  dogs"* (pastores-alemães, "cães policiais" na época), doze no começo, três mortos
  a tiro no começo de agosto, quatro novos comprados em Brattleboro, cinco mortos
  na noite do telhado, mais seis depois. O usuário pediu nomes de cães de proteção
  com referências: **Brutus, Conan, Hércules e Rambo** são os quatro com nome e
  comportamento (seguir, deitar junto ao fogo, latir para a mata, rosnar para a
  janela); os outros oito, nas plaquinhas do canil: **Yautja, Dutch, Kull, Kurgan,
  Ripley, Snake, Riddick e Sansão**. 💭 O que dispara para a mata e não volta (era
  Rolo no GDD) passa a ser **Yautja** — o caçador que some no mato. Anacronismo de
  propósito (piscadela), pedido do usuário: os nomes só aparecem nas plaquinhas e
  nas falas de Akeley.
- ✅ **Onde a demo corta: no escuro depois dos tiros.**
