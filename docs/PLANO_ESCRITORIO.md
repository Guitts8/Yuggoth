# Plano — Escritório v2 (visual + correio + mundo vivo)

Decidido em 2026-10-06, depois do playtest dos Dias 1–6: *"ficou MUITA leitura sem
fazermos nada"*. O escritório é refeito **uma vez só**, já com as mecânicas novas:

1. **Visual** no rumo da imagem de referência (escritório escuro de 1928, lâmpada de
   banqueiro verde como luz principal, objetos low-poly facetados, sala cheia).
2. **Correio pela fresta da porta**: receber, levar à mesa, abrir.
3. **Mapa de Vermont** na parede, que cresce a cada carta.
4. **A sala acumula** com os meses (a obsessão de Wilmarth fica visível).
5. **Estranhezas sutis**, ligadas à exposição — nenhum susto.

Fora do escopo (não escolhido): gente fora de cena (passos, colegas batendo).
Regras que continuam: sem barra de nada (exposição só por som/imagem), máximo de 2
jumpscares no jogo, pássaros só no Dia 1, fidelidade ao livro (o que é invenção
fica marcado 💭 e não pode contradizer o livro).

Cada fase termina com teste de fumaça passando e um commit.

---

## Fase 1 — Look-dev (aprovação antes de refazer tudo)
Prova do visual em **uma** sala, com capturas lado a lado (atual × nova) da tarde
do Dia 1 e da noite do Dia 6, para o usuário aprovar antes da Fase 2.

- `psx_lit`: luz **por pixel** (sai `vertex_lighting`), mantendo tremor de vértice e
  afim; **facetas** com normal por face (derivadas) — o low-poly aparece na luz.
- **Sombras**: a lâmpada da mesa e o sol da janela projetam sombra.
- Resolução interna: **480** (shrink inteiro: 540 linhas em 1080p; era 270). A UI continua nativa. ✅
- Ambiente: tonemap filmico, contraste e cor quentes, um pouco de brilho na lâmpada;
  escuro de verdade fora do círculo da luz.
- **Lâmpada de banqueiro** (cúpula de vidro verde) como luz-chave nas noites.
- O "sonho" (exposição alta / `sonho`) continua devolvendo o PS1 cru — com a
  realidade mais rica, o contraste entre os dois finalmente aparece (pendência antiga).

## Fase 2 — A sala nova (gerador v2)
`gerar_escritorio.gd` refeito com a sala da referência, em primitivas facetadas
(provisório que já tem a cara final; `.glb` à mão continua entrando como `Modelo`):
lambri de madeira até meia parede, tapete, estante cheia, arquivo de aço, cabideiro
com chapéu e sobretudo, cesto de papéis, xícaras, pilhas de livros, a torre da
Miskatonic na vista da janela, lâmpada de banqueiro, mata-borrão, espátula de
cartas. Atualizar `docs/ARTE.md` (o que vale modelar à mão muda).

✅ Feito: lambri com moldura (nos dois vestidos), estante cheia (livros soltos numa
malha só, `_lote` + cor de vértice), arquivo de aço com a máquina de escrever em
cima (canto nordeste), cabideiro com chapéu e sobretudo (canto sudeste — saiu de
dentro do armário), cesto de papéis, espátula, mata-borrão com cantoneiras,
cortinas de veludo abertas, lâmpada de banqueiro na mesa todos os dias (acesa só
nas noites) e a torre gótica da Miskatonic nas três vistas (mostrador aceso à
noite). Xícaras, pilhas de livros e planta ficaram para a Fase 5, que as faz
acumular por dia.

## Fase 3 — Correio pela fresta
Componente novo **`Correspondencia`** (estado em `GameState`, `correio_<id>`):

| Estado | Onde | Ação |
|---|---|---|
| 0 — no chão | junto à porta, caído pela fresta (som do envelope caindo) | "Pegar o correio" |
| 1 — na mão | preso à câmera, embaixo à direita | "Pôr na mesa" (na escrivaninha) |
| 2 — na mesa | no lugar dele | "Abrir com a espátula" (som de papel rasgando) |
| 3 — aberto | envelope rasgado; o conteúdo sai para a mesa | ler / examinar como hoje |

- Uma coisa na mão por vez. O conteúdo de cada dia (cartas, telegramas, bilhetes)
  passa a nascer **dentro** de um envelope em vez de já estar na mesa.
- **Fotos (Dia 2):** envelope grosso; "Tirar uma fotografia", uma por vez — cada
  uma vai para o seu lugar na mesa. Ninguém mais arrumou as fotos: foi você.
- **Saltos no tempo:** o envelope cai pela fresta no escuro; quando a luz volta,
  está no chão junto à porta.
- **Pacotes** que não passam na fresta (o disco do Dia 3, o caixote do fonógrafo)
  ficam no chão junto à porta, deixados pelo expresso — sem cena de entrega.
- Os testes de cada dia passam a abrir o correio antes de ler.

✅ Feito: `Correspondencia` (área filha do envelope/pacote, estende `Examinable`)
e `MesaCorreio` (o tampo, mirável só com algo na mão). Todo o correio dos Dias 1–6
chega pela fresta, inclusive o que cruza o correio no escuro dos saltos (o som
toca sob o cartão). O pacote do Dia 3 fica no chão junto à porta; cortado o
barbante, saem o bilhete, a transcrição e o estojo — e o fonógrafo só aceita o
cilindro depois disso. A foto do exército (Dia 4) sai do envelope de julho. Dois
telegramas vêm no envelope da Western Union. A luz do corredor entra pela fresta
embaixo da porta (uma linha acesa e um brilho no chão): sem ela, nas noites, o
correio no chão era invisível. Fotos não tiradas no Dia 2 (ou 4) aparecem na mesa
no dia seguinte. A mão não atravessa um load (volta ao chão); sair com algo na mão
o deixa na mesa.

## Fase 3b — Ajustes do playtest (2026-10-06)
Depois de jogar a Fase 3. ✅ já feito: a assinatura ("H. W. A.") não fica mais
sozinha numa folha. Decidido com o usuário, nesta ordem:

1. **Correio de saída — a porta é o correio.** Selar tem animação (dobrar a folha,
   envelopar, selo) e a carta vai **para a mão**. Na porta, "Pôr no correio": a
   resposta do dia encerra o dia; as cartas intermediárias (oferta, renovação,
   ânimo) disparam o salto no tempo; a carta registrada do Dia 6 leva à tinta.
   Todo dia termina igual — saindo pela porta com a carta. (Resolve "uns dias
   acabam sozinhos, outros pela porta".) ✅ `ReplyWriter` anima a selagem;
   `CartaSaida` na mão; endereço por `ReplyData.endereco` (Brattleboro a partir de
   julho), carta registrada com três selos.
2. **Cartas do mesmo dia chegam amarradas** num maço com barbante (Dias 4 e 5);
   desamarrado na mesa, os envelopes se separam. **Modelos refeitos:** a caixa de
   cartas do Prólogo e o pacote do expresso (papel pardo, barbante de verdade).
   ✅ Maço no Dia 5 (`Correspondencia.soltar`); no Dia 4 o telegrama segue avulso
   (vem por mensageiro, não pelo correio). O Prólogo virou um maço de 14 cartas
   com laço; o pacote, papel pardo com barbante e etiqueta na tampa. Sai a textura
   `caixa_cartas`.
3. **Telefone com som:** chiado da linha, a telefonista, murmúrio de voz filtrada
   sob cada legenda, o clique do gancho. ✅ (sons sintetizados provisórios)
4. **Lareira acesa pelo jogador** nas noites frias (Dias 5 e 6): "Acender a
   lareira" — luz quente e trêmula, estalos. As noites deixam de ser difíceis de ver.
   ✅ `Fogo` (luz que pisca, chamas em billboard, crepitar); `lareira_dia_<N>`.
5. **Lapso na própria sala** no lugar do corte seco dos saltos no tempo: sem tela
   preta, a luz da janela passa de noite a manhã a noite, uma **folhinha** de
   calendário na mesa perde as folhas (com som), e o texto do cartão aparece como
   legenda sobre a cena. ✅ `Lapso` (SceneDirector.tempo → `Escritorio.passar_tempo`);
   a folhinha fica no peitoril, as datas em `datas_dia`/`datas_cartao` (1928).
6. **Vinheta jogável de Boston** (Dia 4, livro cap. III): uma cena curta e fechada
   fora do escritório — a conversa em pessoa com o funcionário do expresso — e de
   volta à sala. Serve de molde para outras saídas do livro. ✅ `levels/boston/`
   (gerar_boston): o quarto de pensão, o rapaz (Interlocutor, 3 perguntas; a da voz
   amolece a sala), a volta ao escritório já de noite. Os geradores dividem
   `tools/gerador_base.gd`.
7. **Sonho ou aparição em todos os dias** (2 a 6), para nenhum dia ficar morno;
   sem susto (o limite de 2 jumpscares continua). Já certo: o **Mi-Go cruzando o
   painel da cidade** à noite (silhueta 2D, uma vez, sem som). Os sonhos usam a
   estética crua (`sonho`). Propostas a detalhar antes de fazer, uma por dia.
   ✅ A criatura no céu: Dia 3 (depois do disco) e Dia 6 (depois de "falaram
   comigo"), `Aparicao` com asas batendo (`batida`), silhueta rosada apagada.
   ✅ Os sonhos na noite entre os dias (2→3, 3→4, 4→5, 5→6): `Escritorio._sonhar`,
   `Sonhos/NoiteN` com `sonhando == N` (o grupo `Dias` some), `sonhos[N]` = a flag
   que acorda. Fase 3b concluída e jogada pelo usuário (→ Fase 3c).

## Fase 3c — Ajustes do playtest 2 (2026-10-06)
O usuário jogou a Fase 3b. O que pediu, o porquê, e o que foi feito:

1. ✅ **Pular, só para testes** — os testes dele demoravam nas conversas e
   cartões. Segurar **F** acelera tudo 8× (`autoload/depuracao.gd`, some fora de
   build de depuração). Commit `3c6062c`.
2. ✅ **Papéis invisíveis** — o telegrama (e a foto do exército) ficavam dentro do
   mata-borrão. O mata-borrão ficou rente ao tampo; o teste de fumaça agora confere
   em todo momento que nenhum papel visível fica abaixo dele. `3c6062c`.
3. ✅ **O correio de uma vez** — "pegar uma carta por vez não faz sentido". Pegar o
   correio junta tudo o que caiu (uma pilha na mão); pôr na mesa pousa tudo.
   `Correspondencia.na_mao` virou lista. `3c6062c`.
4. ✅ **Zoom da visão** — não dava para ler a folhinha. Segurar botão direito / Z /
   analógico esquerdo aperta o FOV (ação `zoom_visao`). `3c6062c`.
5. ✅ **Cartas escritas "quebradas"** — no dossiê, a letra é maior que no papel de
   escrita: as respostas se partiam em duas folhas, a segunda só com o fim e a
   assinatura; e o itálico (o latim) não aparecia na letra de mão. O leitor aperta
   a letra (até 80%) quando sobraria uma folha; [i]/[b] viram FontVariation
   (inclinada/engrossada). `0a1ddf5`.
6. ✅ **Vozes do telefone ≠ vozes do disco** — o murmúrio usava a receita da voz
   humana do disco, e o disco precisa impactar. Agora é voz soprada, abafada, com
   o chiado do microfone de carvão. `eec287d`.
7. ✅ **A pedra do sonho** longe demais no exame — o enquadramento contava a luz
   junto da pedra. O ExamineViewer enquadra só geometria e tira luzes/sons da
   cópia. `eec287d`.
8. ✅ **O lapso** — Wilmarth ficava travado olhando para onde estava, e passava
   rápido demais. Agora vira devagar para a janela, e cada dia nasce (rosado),
   clareia, entardece (laranja) e anoitece; 7 s por dia (vários dias dividem 15 s,
   mínimo 3,5 s cada). `eec287d`.
9. ✅ **Selar em 3D, devagar** — a animação 2D "parecia slide de PowerPoint" (o
   envelope na mão, ao contrário, foi aprovado como "EXCELENTE"). `Selagem`: Wilmarth
   senta à mesa, a folha dobra em três, o envelope chega de costas, a folha entra,
   a aba fecha, vira, o selo é batido, sobe para a mão; ele se levanta. `0252bf6`.
10. ✅ **Boston** — "não imagino ele nos recebendo": o rapaz agora responde pela
    porta entreaberta, no corredor da pensão, franco e gentil, sem convidar.
    `a7b9c41`.
11. ✅ **A criatura** — "menos rosa e claro": cinza-violáceo escuro. `eec287d`.
12. ✅ (experimento) **A cidade da janela em 3D**, pequena e longe, para comparar com
    o painel: tecla **C** em build de depuração; só de noite. **O usuário ainda vai
    comparar e decidir** qual fica. `3ce2f91`.
13. ✅ **A passagem para o sonho** — no playtest, o sonho "começa muito
    abruptamente", sem parecer sonho: nada mostrava que Wilmarth foi dormir.
    **Decidido (opção 2 + 3): a preparação no escritório + o diário.** Ver abaixo.
    Feito em 2026-10-07 (commit "Escritório v2: o diário e a passagem para o sonho").

### A passagem para o sonho (feita)
Opções que foram consideradas: (1) uma cena em casa, indo dormir — a mais clara,
mas um cenário novo, mais caro e longo; (2) a preparação, adormecer à mesa no
próprio escritório — barata e contínua (a sala vira sonho sem corte), mas
sozinha é sutil; (3) um diário — dá voz interior a Wilmarth e reaproveita a
linguagem da tinta, mas é mais leitura e não mostra o sono. **Escolhida: 2 + 3.**

- **Um ritual fixo, toda noite:** postada a resposta do dia, a porta não encerra
  o dia de imediato — Wilmarth volta à mesa para **anotar o dia no diário**
  (um caderno na escrivaninha; "Anotar o dia"). Assim todo dia termina do mesmo
  jeito e o jogador nunca sabe se aquela noite terá sonho.
- **A entrada é curta:** uma ou duas linhas que se escrevem sozinhas (som de
  pena), compostas com frases do conto quando der (💭 no que for invenção). Sem
  escolha de tom — não é mais leitura do que precisa.
- **Noite sem sonho:** a última linha termina; ele fecha o caderno, levanta, e o
  dia acaba (fade, cartão do dia seguinte), como hoje.
- **Noite com sonho (depois dos Dias 2–5):** a última linha **falha** — a letra
  cai, a pena para, a tinta escorre; a visão pesa (pálpebra: escurece e abre
  devagar), a lâmpada baixa, **o relógio parado volta a bater**; ele encosta na
  cadeira, e a sala vira o sonho em volta dele, **sem tela preta**
  (`Escritorio._sonhar` passa a começar daqui, sentado).
- **Ao acordar:** de manhã, debruçado na mesa, o diário aberto com a linha
  borrada — fica claro que foi sonho. Só então o cartão/o dia seguinte.
- O diário vai para o dossiê (as entradas acumulam); no jogo completo pode virar
  peça narrativa (a moldura de 1930).
- A porta continua sendo o correio: **postar a resposta do dia não encerra mais o
  dia — leva à mesa, ao diário** (a última coisa do dia, Dias 1–5). No Dia 6 (o
  fim da demo) não há diário: a carta registrada leva à tinta, como hoje.

**Como ficou** (conferido em captura; o teste de fumaça cobre os Dias 1–5):
- `components/diario.gd` (`Diario`): o caderno vermelho à esquerda do mata-borrão,
  com a área `Anotar` (condição `diario >= 1`; fora da física quando não vale).
  Aberto, vem para diante da cadeira; as duas páginas são uma textura
  (SubViewport) com pautas, a entrada anterior à esquerda e a do dia à direita,
  escrita letra a letra pela **pena da mesa**, que segue a última letra. Debruçado
  (`Player.debrucado`) e com a vista apertada (`Player.fov_forcado`), a letra se lê
  na resolução do mundo.
- As entradas: `narrative/documents/diario_dia_1..5` (vão para o dossiê). Nas noites
  de sonho a última linha vem em `[queda]` (`QuedaTextEffect`: cada letra mais
  baixa, torta e clara — também no dossiê); a escrita desacelera e para no meio da
  palavra, a pena tomba, a tinta se espalha e escorre (`Diario.Mancha`).
- O sono (`Escritorio._adormecer`): `Palpebras` (`ui/`, sombras curvas que fecham
  sem chegar ao preto) piscam pesadas; o relógio volta a bater; as luzes baixam e a
  estética crua sobe; ele encosta na cadeira; no quase escuro, de olhos quase
  fechados, troca-se para o sonho (`sonhando`), e as luzes do sonho sobem enquanto os
  olhos abrem. O sonho começa sentado (a marca `Sonho` saiu).
- Ao acordar (`_acordar`): na tela preta do fim do sonho, a sala do dia, ele
  debruçado sobre o diário aberto com a linha borrada, e a aurora pela janela
  (`Lapso.amanhecer`). Os olhos abrem, ele ergue a cabeça, e vem o cartão.
- Ajustes nos sonhos: a Noite 2 acorda ao seguir as marcas **de volta até a porta**
  (o gatilho ficava ao pé da cadeira, onde ele agora começa); o fonógrafo da Noite 3
  foi para o fundo da mesa, atrás do diário aberto.

### Pendências pequenas, anotadas no playtest 2
- "Deixar sem resposta" (Dia 2) confundiu: o texto da ação pode virar algo como
  "Encerrar o debate nos jornais" (o usuário ainda não pediu a troca).
- ~~A cidade 3D, se aprovada, precisa das outras horas e de substituir o painel~~ —
  resolvido na 3d (item 8): fica a 3D em todas as horas.

## Fase 3d — Ajustes do playtest 3 (2026-10-08)
O usuário jogou o diário e a passagem para o sonho. Aprovou: a animação de
selar ("ótima"), a do diário, a transição para o sonho (a letra que falha é de
propósito). Mas: *"as animações estão tão boas e elegantes que o escritório e a
parte externa estão parecendo feitas nas coxas"*. O que pediu, o porquê, e o que
foi feito. Commits: `30e90f6` (itens 1–5), `8385fa6` (6), `d2e98ce` (7), `6560d44` (8);
`b0c89f1` é só a reimportação das texturas novas (quadro, diploma) como VRAM, igual às demais.

1. ✅ **Selar** — um pouco mais rápido; a folha dobrada brigava com o envelope ao
   entrar (os modelos se cruzavam); a vista ficava para onde o mouse estava, e não
   de frente para a carta; e o envelope selado, subindo para a mão, atravessava a mesa.
   Agora: 20% mais rápido (`Selagem.RITMO`); o envelope é oco enquanto a folha entra
   (frente, costas com a boca recuada, bordas) e a aba aberta deita na mesa, sob a
   folha; a vista é calculada **da cadeira** (`Player.olhar_para(ponto, s, de)`; antes
   saía de onde ele estava de pé) e aperta na carta (FOV 50); ao subir para a mão, ele
   ergue a cabeça e o envelope sobe do tampo antes de vir.
2. ✅ **A vista no diário** — esquisita; e parada demais enquanto ele escreve (a
   câmera deve acompanhar a escrita). Era o mesmo erro do selar (o ângulo vinha de
   onde ele estava de pé), e os olhos baixos demais, a 17 cm da folha. Debruçado agora
   desce 8 cm e avança 28 (`Player.DEBRUCAR_*`), FOV 38; escrevendo, os olhos seguem a
   pena com atraso e a cabeça respira (`Diario._seguir_a_pena`).
3. ✅ **O diário na mesa desde o começo**, e dá para **lê-lo e folheá-lo** ali. (Ele já
   ficava na mesa todos os dias; só a área aparecia depois de postar.) "Ler o diário"
   fora da hora de anotar: ele senta, o caderno abre no último par, [A] [D] (ou as
   setas) viram a folha — uma folha 3D que gira na lombada, com o par antigo de um lado
   e o novo do outro —, [E] fecha. A primeira página é a folha de rosto.
4. ✅ **Ao acordar, o olho abre como fechou**, ao contrário (`Palpebras`, sem fade).
5. ✅ **Boston**: o 7 da porta do quarto não acompanhava a porta (era da parede).
6. ✅ **Quem posta a carta?** — postar antes do diário deixou um buraco: a carta sumia
   da mão na porta e ele continuava na sala. **Decidido: a calha de correio** de
   latão no corredor, junto à porta (os prédios dos anos 1920 tinham): ele abre a
   porta, põe a carta na calha, ouve-a descer, volta à mesa e ao diário.
   Feito: `CalhaCorreio`; a parede sul ganhou o vão e a folha gira na dobradiça; o
   corredor (piso, reboco, lambri, um globo no teto, a porta fosca de outra sala) só
   existe com a porta aberta; a calha vai de piso a teto, frente de vidro com faixas
   de latão, plaqueta "LETTERS / U.S. MAIL"; a carta entra deitada pela borda curta e
   se vê descer atrás do vidro. Sons novos: `calha_correio`, `porta_trinco`.
7. ✅ **Dormir escrevendo toda noite fica estranho** (4 noites de sonho seguidas).
   **Decidido: bebida + lugar varia.** Antes do diário, um gesto: café nos primeiros
   dias, uísque nos últimos (💭 Lei Seca: um frasco na gaveta, para os nervos); a
   xícara e o copo ficam na mesa (acumulam, Fase 5). E o sono vem em lugares
   diferentes: no diário, na poltrona diante da lareira, ouvindo o fonógrafo.
   Feito: `Bebida` (café nos Dias 1–3, a garrafa serve pela boca; no Dia 4 a gaveta
   de cima à direita abre e o frasco sai e fica na mesa, `frasco_na_mesa`) e
   `LugarSono`: noite 2 no diário; **noite 3** a entrada termina ("Vou ouvi-lo mais
   uma vez") e "Ouvir o disco outra vez" o senta na cadeira de leitura nova, virada
   para o fonógrafo; noite 4 no diário (depois do uísque); **noite 5** "Sentar diante
   do fogo" (com o fogo aceso) na poltrona, agora virada para a lareira, com o copo.
   Acorda onde dormiu; o fogo, de manhã, apagado. Sentado, o Player não passa pela
   física (a poltrona o empurraria). Sons novos: `servir`, `gaveta`. As entradas 3 e
   5 do diário perderam a última linha caída (ver FIDELIDADE).
8. ✅ (primeira passada) **O escritório e a vista lá fora** parecem toscos perto das
   animações: **materiais e texturas, móveis e objetos, a vista da janela.** (A luz e
   a composição não incomodaram.) Uma passada de acabamento com capturas antes/depois.
   Feito:
   - **A vista é Arkham em 3D** em todas as horas (`tools/cidade_arkham.gd`,
     `shaders/cidade.gdshader` e `ceu.gdshader`): casas coloniais de empena e de
     telhado holandês, de tábuas pintadas, com chaminés; sobrados de tijolo no
     centro; duas igrejas brancas com campanário; a torre gótica e um prédio da
     universidade; olmos; o rio e os morros; céu com nuvens que correm e estrelas à
     noite; névoa de distância por hora (dia, entardecer, noite, chuva); janelas que
     acendem à noite. Isso decide o painel × cidade 3D: fica a 3D, e o painel antigo
     só aparece com a tecla C (depuração, flag `painel`), para comparar.
   - **Texturas** em 128 px: madeira de veio fino (sem as juntas pretas), assoalho de
     tábuas estreitas com emendas desencontradas, papel de parede com ornamento de folha.
   - **Móveis:** a escrivaninha com borda moldurada, rodapé e frentes de gaveta; a
     cadeira de banqueiro (pé giratório, braços, balaústres); a poltrona de clube
     (pés torneados, braços rolados, orelhas).
   - **A sala:** cornija em volta do teto, florão e lustre de globo, alizar na porta,
     uma paisagem a óleo sobre a lareira e dois diplomas na parede leste.
   Ainda por ver com o usuário: o que mais parece tosco depois desta passada.

## Fase 3e — Ajustes do playtest 4 (2026-10-08)
O usuário jogou do Prólogo ao começo do Dia 5, onde o jogo congelou. Aprovou: a
cidade em 3D (*"ficou lindo"*), o chão, a ideia da calha. O princípio que vale para
tudo daqui em diante: **a câmera nunca fica presa** — *"a cabeça deve dar liberdade
para o jogador, pois é quase a única que ele tem"*. Cenas que sentam ou aproximam
Wilmarth podem levar o olhar até a ação, mas o mouse continua mexendo a cabeça.
O que pediu, o porquê, e o que foi feito. Commits: `9410cbd` (1), `d79096b` (3, 4),
`f2b10c4` (5, 6, parte do 7), `410b6f0` (7, 9, 10), `9d69712` (10, 11), `74dc05b`
(8), `e6052c8` (12) e o do acabamento (13).

1. ✅ **Bug: a noite 5 quebrou** — sem como acender a lareira; sem fogo, nem o copo
   nem a poltrona. Causa: a caixa de colisão da lareira cobria a boca e a lenha, e o
   raio da mira batia nela antes de chegar a "Acender a lareira". O teste de alcance
   não via porque disparava raios de dentro da caixa. Feito: a colisão em pedaços (a
   boca livre); o teste conta raios que partem de dentro de um móvel
   (`hit_from_inside`). Conferido com o save dele.
2. ⏳ **Bug: congelou ao mexer no envelope** (Dia 5, logo depois da lareira; a
   janela parou). O jogo rodava embutido no editor (`--remote-debug`); um erro de
   script pausa o jogo no depurador e a janela parece congelada. **Não reproduzido**:
   com o save dele, o maço, as cartas soltas, o exame e a leitura funcionam pela
   mira e pela tecla de verdade. O processo do jogo ainda estava aberto, mas ele já
   tinha fechado o editor sem ver o Depurador. Se acontecer de novo: olhar o painel
   Depurador → Erros/Pilha do editor antes de fechar.
3. ✅ **Câmera livre no diário** — fica na distância de escrever, mas o mouse olha.
   Feito no Player, para todas as cenas: com `input_enabled` falso e o mouse preso,
   o mouse soma um desvio (`_olhar_extra`) à direção que a cena dá; `olhar_para` o
   desfaz quando a cena leva o olhar a algo novo; devolvido o controle, o desvio vira
   a direção do corpo. Escrevendo, os olhos deixam de seguir a pena assim que o
   jogador mexe a cabeça. Folheando (modal, mas com o mouse preso), também.
4. ✅ **Selar**: a folha ainda passava por cima do envelope ao entrar — as dobras
   ficavam a 3–5° do plano e a ponta subia mais que a espessura do envelope; agora
   rentes (180°). Câmera livre (item 3). O fecho (aba, virar, selo) mais ligeiro.
5. ✅ **A calha**: a porta atravessava Wilmarth e ele punha a carta de muito longe.
   Agora ele abre a porta parado ao lado da maçaneta, fora do arco da folha,
   atravessa a soleira até a calha, põe a carta de perto, a acompanha descendo pelo
   vidro, volta e fecha a porta (`Player.conduzir`: a cena o leva a pé, com passos,
   sem a física).
6. ✅ **Ir para casa pelo corredor**: acabado o dia (o diário sem sonho, ou de
   manhã depois do sonho), "Ir para casa" abre a porta e o corredor é do jogador; a
   escada no fim, a leste, desce para a rua — chegar nela vira o dia. O corredor
   ganhou a escada (degraus, corrimão, a luz de baixo), o lado do corredor da parede
   da sala, o vão com montantes e alizar, e as colisões; a folha da porta tem a dela.
7. ✅ **A poltrona e a cadeira**: a cadeira de leitura (no meio da sala) saiu; a
   poltrona foi para o lado da lareira, virada para ela, com uma mesinha de apoio
   (tampo redondo, pé de três garras, cinzeiro, um livro); o copo da noite do fogo
   fica na mesinha. O uísque é escondido: o frasco sai da gaveta só para servir e
   volta para ela; só o copo fica na mesa (`serviu_uisque`).
8. ✅ **Diário**: a entrada tinha 11 linhas numa página que cabe 10. Cada página é
   uma janela que recorta, com o texto inteiro dentro, que sobe uma folha por vez:
   cheia a folha, a pena se ergue, a folha vira (a cheia vai para a esquerda) e a
   escrita continua no alto da nova página. Folheando, cada entrada ocupa quantas
   folhas precisar.
9. ✅ **A noite do disco**: ele vai ao fonógrafo, baixa a agulha, senta na poltrona
   olhando a lareira fria e ouve (~14 s, com as legendas); então o sono. O sonho sai
   da sala (`Escritorio.sonhos_fora`): é a 1 da manhã de 1º de maio de 1915, junto à
   boca fechada de uma caverna na encosta da Dark Mountain, sobre o pântano de Lee
   (cap. III) — pinheiros e bétulas, o matacão arredondado, vultos de manto na névoa,
   a lanterna de Akeley, o fonógrafo dele num toco tocando o disco de onde parou na
   sala; uma das criaturas passa entre as árvores, de relance. Levantar a agulha (ou
   o fim do disco) acorda, na poltrona. 💭 (os vultos e a criatura: o livro só tem as
   vozes; nada é confirmado).
10. ✅ **3D em vez de painel** (`tools/vistas.gd`, no feitio da cidade): a janela da
    noite 2 (o círculo de pedras no alto de um morro, sob a lua, o mar de montanhas
    atrás), a da noite 4 (a plataforma de Keene, os lampiões, o carrinho com o
    caixote e o homem magro de costas), a noite 5 com Arkham na chuva; a janelinha da
    pensão em Boston (telhados de tijolo, chaminés, caixas-d'água, a torre da
    alfândega). O mi-go em 3D (`props/migo.gd`, do cap. I: rosado, corpo de
    crustáceo, asas membranosas que batem, membros articulados com pinças, o elipsoide
    convoluto de antenas curtas): passa pela janela no Dia 5 e cruza o céu nos Dias 3
    e 6, em silhueta.
11. ✅ **Conversa com opções** (`ui/opcoes_conversa.gd`): em pessoa
    (`Interlocutor.com_opcoes`), as perguntas disponíveis aparecem numa coluna embaixo
    da tela (W/S, setas ou mouse; E/Enter/clique; Esc sai), com a despedida; depois de
    cada conversa, as que restam. Boston: depois do homem de Keene, a voz e o
    reconhecimento viram duas escolhas, e já se pode ir. O telefone continua igual.
12. ✅ **Lapso — a janela viva**: ele se volta para a janela (a cabeça é dele), e
    Arkham passa as horas em 3D — a cidade do lapso tem materiais só dela, animados de
    segmento em segmento (noite, aurora, dia, entardecer, noite; o último volta à hora
    do dia corrente): céu, luz, névoa, as janelas acendendo e apagando, as nuvens
    correndo; o sol cruza e a sombra do caixilho varre a mesa e o assoalho. Uma folha
    da folhinha por dia; o cartão no escuro. Acordar de manhã usa a mesma cidade.
13. ✅ **Acabamento, segunda passada**: a **lareira** (consolo de madeira com
    pilastras, friso, prateleira com cimalha e mísulas; azulejos verdes em volta da
    boca; a fornalha com faces inclinadas e fuligem; a grelha de barras; o piso de
    pedra e o guarda-fogo de latão; ferramentas, cesto de lenha; relógio de mesa,
    castiçais com velas, pote de fumo); a **estante** (montantes, bordas, rodapé,
    cimalha; lombadas com frisos dourados e etiquetas; livros de série; em cima, uma
    caixa e um rolo de mapas); a **janela** (duas de guilhotina com pinázios, o trilho
    com a tranca, o alizar com cimalha, o peitoril com avental, o vão forrado, um
    vidro); a disposição (item 7); a cidade à noite um pouco mais clara.
14. ⏳ Por validar no playtest 5: tudo acima, e do Dia 5 ao fim da demo.

## Fase 3f — Ajustes do playtest 5 (2026-10-08)
O usuário jogou até a noite 3 (o sonho do disco): ao acordar, Wilmarth travou diante
da poltrona e nada mais se fazia. Gostou da cena do mi-go (*"caramba! o mi-go lá"*) e
do sonho do bosque. Pediu, antes de tudo, um jeito de pular dias em caso de bug e um
arquivo com os comandos. Legenda: ✅ feito · 🔧 claro, a fazer · ❓ espera resposta.

1. ✅ **Pular dia (depuração)**: **F8** dá o dia por feito (correio aberto com tudo
   tirado, resposta escrita, dia anotado; no Dia 3 o fonógrafo montado e tocado) e
   abre o escritório na manhã seguinte; no Prólogo, vai ao Dia 1; não passa do Dia 6.
   **F9** recarrega o escritório no mesmo dia (destrava sem pular). Em
   `autoload/depuracao.gd`, some no jogo exportado.
2. ✅ **`COMANDOS.md` e `comandos.ps1`** (raiz): jogar, editor, teste, importar,
   geradores, captura, ver/guardar/trocar saves, log, git; as teclas do jogo e as de
   depuração.
3. ✅ **Bug: travava diante da poltrona ao acordar** (noite 3; a 5 também). Causa:
   ele sentava no centro da colisão da poltrona; ao levantar, a física o prendia
   dentro dela. E acordava na altura do chão do sonho (o bosque), não da sala. Feito:
   ao levantar, ele dá um passo à frente até um lugar livre (consulta de forma com a
   cápsula dele: `_saida_do_assento`); acorda na altura do marcador.
4. ✅ **Ele atravessava a poltrona para sentar** (vindo do fonógrafo, por trás dela).
   Agora chega pela frente, contornando pelo canto mais perto (`_caminho_ao_assento`),
   e só então desliza para o assento.
5. ✅ **Dia 2: dava para escrever a carta com as fotos ainda no envelope.** "Escrever
   a Akeley" só aparece depois de tiradas as nove (`correio_dia_2_tiradas`).
6. ✅ **A calha: "a tela deve ficar solta ao colocarmos a carta no correio, talvez,
   duas ações?"** Decidido: duas ações — "Abrir a porta" (cena curta) e o corredor é
   dele; anda até a calha e "Pôr a carta na calha" (`%PorNaCalha`); volta, e a porta
   fecha sozinha quando ele entra, fora do arco da folha (`_fechar_atras`). O salto
   no tempo das cartas do meio do dia espera a porta fechar (`_salto_pendente`).
7. ✅ **A xícara, com o café à vista**: decidido — a xícara de porcelana fica. Era
   uma copa fechada: o café ficava escondido dentro. Agora aberta (sem tampa, a parede
   de dentro, a borda), e o café alarga ao subir, rente à parede (meta `afunila`).
8. ✅ **O diário**: o modelo mais agradável (capa de couro com cantos, lombada com
   nervuras, fita marcadora, páginas com bordas); a abertura com sentido — a capa abre,
   as folhas correm até a fita (a página do dia), e não uma página só caindo no meio;
   fechar ao contrário. Feito em `Diario._pose(capa, folhas)`: a capa gira e desce à
   mesa; nove folhas correm da pilha da direita à da esquerda enquanto o miolo passa
   de um lado ao outro; a fita sai pelo pé e, aberto, deita no par do dia.
9. ✅ **Ao clicar na porta, ele dá um girinho** em algumas situações. Causa: o
   `olhar_para` girava o corpo pelo lado curto e desfazia o desvio do mouse à parte;
   somados, davam a volta longa. Agora o desvio vira a direção do corpo antes do giro.
10. ✅ **Voltar ao prédio de manhã**: decidido — todo dia (e a volta de Boston) começa
    no corredor, no alto da escada (a marca `Porta`); "Abrir a porta" (`%EntrarPorta`)
    e o correio está no chão, caído pela fresta; a fala do correio vem quando a porta
    abre.
11. ✅ **A escada não leva a lugar nenhum**: o vão da escada com patamar, a volta do
    corrimão, o andar de baixo sumindo na penumbra (luz fraca lá embaixo). Feito: o
    primeiro lanço até o patamar (lambri, uma arandela fraca), o segundo vira para o
    sul e desce ao andar de baixo; o corrimão faz a volta no pilar do patamar.
12. 🔧 **Caligrafia copperplate.** Decidido: duas mãos — Wilmarth em copperplate
    legível (fonte livre OFL, p. ex. *Pinyon Script*; respostas, diário); Akeley em
    outra, apertada e arcaica ("cramped, archaic chirography"). Capturas no leitor
    antes de fechar.
13. ✅ **Selos de cera**: em 1928, carta comum nos EUA era fechada pela goma do
    envelope e franqueada com selo postal (2 centavos). Decidido: sem lacre; fica
    goma + selo postal (como já está).
14. ✅ **O sonho da noite 2: as pegadas pouco visíveis**; mais sinistro (mais marcas,
    frescas, úmidas, em volta do círculo e chegando perto dele; talvez se formando).
    Feito: a textura nova (64 px, a lama escura com a borda molhada que brilha,
    respingos), 20 marcas em duas fileiras; e um `Rastro` (`components/rastro.gd`):
    13 marcas que se formam uma a uma em volta da cadeira, cada vez mais perto, com
    um estalo úmido (`lama.wav`) no lugar de cada uma.
15. ✅ **Pôr as coisas na mesa à mão, em vez de teletransportar** (abrir o pacote e
    tirar as coisas). Decidido: o objeto viaja da mão até o lugar dele na mesa (sem
    lugar livre), e o pacote do Dia 3 se esvazia peça por peça como o envelope das
    fotos. Feito: pego, sobe do chão à mão; pousado, viaja num arco até o lugar
    (`Correspondencia._pousar`); o pacote: "Tirar o bilhete", "Tirar a transcrição",
    "Tirar o estojo do cilindro" (`prompts_retirar`); o cilindro só se põe depois
    do estojo fora.
16. ✅ **O fonógrafo**: modelo muito melhor (um fonógrafo de cilindro comercial: caixa
    de carvalho, mecanismo à vista, a corneta grande no braço) e um lugar digno (não no
    armário do canto). Feito: na sua mesinha (prateleira com estojos de cilindros),
    junto à estante na parede oeste, onde chega a luz da janela; a caixa de carvalho
    com a placa preta, mancais, mandril, a rosca do carro, o diafragma, a manivela, e
    a corneta oca de latão no guindaste, virada para a sala. (No canto sudeste, ao
    lado da poltrona, ficava no escuro.)
17. ✅ **Já montado**: o livro diz que Wilmarth pediu emprestada uma máquina comercial
    à administração da universidade — chega pronta; só falta o cilindro. Sai o caixote
    de peças (e com ele a porta entrando na caixa). As flags `fono_*` não valem mais.
18. ✅ **O mi-go mais visível**: mais perto, maior na janela. Feito: a uns 2 m do vidro
    (a 1,25 m a asa atravessava a parede), escala 1,4, 2,6 s para cruzar.
19. 🔧 **O sonho do disco: mais estranheza, um efeito de loucura.** Decidido: todas — o escritório
    aparecendo em pedaços no bosque; a voz vindo de trás dele e não do fonógrafo; os
    vultos que viram a cabeça quando não olhados; as árvores respirando; a lanterna de
    Akeley andando sozinha; visão dupla nas vozes zumbidas.
20. ⏳ Por jogar: do Dia 3 de manhã (o save dele) ao fim da demo.

## Onde estamos (revisão de 2026-10-08, depois da 3e)
**Ok (feito e commitado):** fases 1, 2, 3, 3b, 3c, a passagem para o sonho, a 3d e a
**3e** (itens 1 e 3–13; o 2 não reproduzido). Teste de fumaça com 0 falhas. Nenhum
push feito (nem pedido).

**Esperando o usuário — o playtest 5** (do Prólogo ao fim; ou do save do Dia 5). O
que olhar:
1. A cabeça livre em todas as cenas (selar, diário, calha, lapso, sono).
2. A calha a pé (porta → calha → volta) e o fim do dia pelo corredor e a escada:
   cansa em 5–6 repetições?
3. O diário virando a folha ao encher; folhear entradas de duas folhas.
4. A poltrona e a mesinha ao lado da lareira; o uísque voltando para a gaveta.
5. A noite do disco: o disco antes do sono e o sonho no bosque da Dark Mountain.
6. As janelas dos sonhos (noites 2 e 4), o mi-go na janela (Dia 5) e no céu (3 e 6).
7. Boston: o menu de perguntas embaixo; a janelinha.
8. O lapso pela janela viva.
9. O acabamento: lareira, estante, janela, a noite da cidade.
10. Do Dia 5 ao fim da demo (não jogado no playtest 4) — e se o congelamento voltar,
    o Depurador do editor antes de fechar.

**Decisões de texto pendentes:** as entradas do diário (as 3 e 5 mudaram na 3d) e as
falas `sono_disco`/`sono_fogo`; o visual do sonho (pendência antiga); "Deixar sem
resposta" (Dia 2). O bosque do disco (os vultos, a criatura) é 💭.

**Como retomar numa sessão nova:** ler este arquivo (a 3e e esta seção), esperar a
lista do playtest 5 e registrá-la como **Fase 3f**, no mesmo formato. Não começar a
Fase 4 antes dela.

**A fazer, no código:** fases 4, 5, 6 e 7 (abaixo); depois o resto do marco Demo
(GDD §12): opções de acessibilidade (tremor, afim, FOV — ainda não há nenhuma em
`Settings`), presets de export (ainda não há `export_presets.cfg`) e o playtest com
5+ pessoas. Fora do código e ainda sem dono: arte final (`docs/ARTE.md`, nenhum
`.glb` ainda), som final e a voz de Noyes no disco.

## Próximos passos (em ordem)
1. ✅ **A passagem para o sonho** (acima): diário + adormecer à mesa + acordar de manhã.
2. ✅ Playtest 3 → **Fase 3d** (acima). Painel × cidade 3D: decidido pela 3D.
2b. ✅ Playtest 4 (até o começo do Dia 5) → **Fase 3e** (acima).
2c. ✅ O usuário jogou o **playtest 5** (até a noite 3); a lista virou a **Fase 3f**.
2d. **← AQUI.** Fase 3f: feitos os itens 1–11 e 13–18; o usuário respondeu os ❓
   (todas as recomendações); a fazer: 12 (as duas mãos) e 19 (a loucura do sonho do
   disco).
3. **Fase 4** — o mapa de Vermont. **Fase 5** — a sala acumula. **Fase 6** — estranhezas.
4. **Fase 7** — fechamento (docs) e o resto do marco Demo (acessibilidade, export).

## Fase 4 — O mapa de Vermont
Um mapa grande na parede oeste, junto ao quadro de recortes (vira o **quadro da
investigação**, como na referência). Textura gerada: contorno de Vermont, o
Connecticut, o West River, as cidades do livro.

- Lida uma carta que cita lugares novos, aparece **"Marcar no mapa"**: um alfinete
  por lugar e o **fio vermelho** liga o novo ao anterior. Não trava a porta.
- 💭 As **fotografias** podem ser presas no mapa, no lugar onde foram tiradas
  ("Prender no quadro"); continuam examináveis lá.

| Dia | Lugares (o que a carta/o dia cita) |
|---|---|
| 1 | Townshend (a fazenda), Montanha Escura, West River; dos recortes: Winooski, Passumpsic |
| 2 | Round Hill (as fotos), a caverna na Montanha Escura |
| 3 | Pântano de Lee (o disco), Brattleboro (de onde ele despacha) |
| 4 | Bellows Falls (o telegrama), Keene (Stanley Adams) |
| 5 | Newfane (o cabo cortado), Bellows Falls de novo (o telegrama "AKELY") |
| 6 | — (os fios convergem em Townshend; nenhuma marca nova) |

## Fase 5 — A sala acumula (por dia, `dia >= N`)
| | Dia 1 | Dia 2 | Dia 3 | Dia 4 | Dia 5 | Dia 6 |
|---|---|---|---|---|---|---|
| Livros de folclore da biblioteca | — | 2 na mesa | pilha | pilha no chão | duas pilhas | por toda parte |
| Xícaras | — | 1 | 1 | 2 | 3 | 4, uma caída |
| Planta na janela | verde | verde | verde | amarelando | seca | morta |
| Cortina | aberta | aberta | aberta | aberta | meio fechada (depois do vulto) | fechada |
| Cesto de papéis | vazio | cada folha **amassada** ao escrever (Esc) vira uma bola de papel no cesto (`folhas_amassadas`) |||||

A vista da janela já muda por dia (maio verde, entardecer, noite, julho, chuva,
noite sem lua); na Fase 2 ela ganha a torre da Miskatonic.

## Fase 6 — Estranhezas sutis 💭
Uma vez cada, sem som de susto, sem narração que confirme. Só acontecem com
exposição acima de um limiar — quem acreditou menos vê menos. Nenhuma contradiz o livro.

| Quando | O quê |
|---|---|
| Dia 4, ao entrar | O cilindro de cera fora da caixa, sobre o fonógrafo — ninguém o tirou |
| Dia 4 | O relógio parado mostra outra hora, não a de quando parou |
| Dia 5, depois do bilhete | Uma das fotografias virada para baixo na mesa |
| Dia 6, depois da carta de terça | O telefone dá meio toque e cala; atendido, só um zumbido na linha |
| Dia 6, quarta | A janela entreaberta, a cortina mexendo — estava fechada |

O vulto da janela (Dia 5) já existe e entra nesta lista.

## Fase 7 — Fechamento
SEQUENCIA (cada dia com correio, mapa e sala), FIDELIDADE (💭 novas), ARTE, CLAUDE.md;
playtest do usuário do Prólogo ao fim da demo.
