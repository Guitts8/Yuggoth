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
12. ✅ **Caligrafia copperplate.** Decidido: duas mãos — Wilmarth em copperplate
    legível (fonte livre OFL, p. ex. *Pinyon Script*; respostas, diário); Akeley em
    outra, apertada e arcaica ("cramped, archaic chirography"). Capturas no leitor
    antes de fechar. Feito, comparando seis no leitor (Segoe Script, Pinyon, Petit
    Formal, Tangerine, Mr De Haviland, Cedarville): **Wilmarth em Pinyon Script**
    (estilo novo `WILMARTH`: as respostas, o diário, o relato, o rascunho; ×1,2) e
    **Akeley em Tangerine** (estreita, antiga; ×1,5; o tremor de agosto por cima).
    Mr De Haviland não se lia; Cedarville era moderna demais. ⏳ O usuário confere
    no playtest.
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
19. ✅ **O sonho do disco: mais estranheza, um efeito de loucura.** Feito: `Espreita`
    (`components/espreita.gd`: muda só fora da vista — aparece, vira o rosto, anda
    para o próximo ponto) nos vultos (de costas; viram o rosto pálido), na lanterna
    (anda em volta dele e rumo aos vultos) e em quatro pedaços do escritório (a porta
    com a fresta acesa, o abajur verde, a cadeira, um pedaço da estante); `Respira`
    nas sete árvores mais perto da clareira; no `Fonografo`, `voz_por_tras` e
    `visao_dupla` (o global `psx_dupla` no pós) na voz zumbida. Decidido: todas — o escritório
    aparecendo em pedaços no bosque; a voz vindo de trás dele e não do fonógrafo; os
    vultos que viram a cabeça quando não olhados; as árvores respirando; a lanterna de
    Akeley andando sozinha; visão dupla nas vozes zumbidas.
20. ⏳ Por jogar: do Dia 3 de manhã (o save dele) ao fim da demo.

## Fase 3g — Ajustes do playtest 6 (2026-10-08)
O usuário jogou o playtest 6. Legenda: ✅ feito · 🔧 claro, a fazer · ❓ espera resposta.

1. ✅ **F8 fecha o jogo.** Rodando pelo editor, F8 é o "parar o projeto" do Godot
   (o jogo em execução repassa a tecla ao editor; o log da sessão acaba sem erro
   nenhum). Feito: **F2** pula o dia, **F3** recarrega — longe de F5–F12.
2. ✅ **Os títulos estão em letra bastão**, e a copperplate (Pinyon) é difícil de
   ler. Feito: comparadas cinco copperplates no papel do leitor (Pinyon, Petit
   Formal, Parisienne, Meddon, Italianno): **Wilmarth em Petit Formal Script**, de
   longe a mais clara, com entrelinha maior (`STYLE_ENTRELINHA`). Os títulos, a
   interface toda (fonte padrão do projeto) e o jornal em **Old Standard**, a
   serifada das publicações do começo do século XX. Akeley continua em Tangerine.
3. ✅ **No diário, a escrita não se lê.** Além da letra, era escala: o mundo é
   desenhado a ~480 linhas. Feito: corpo 21 → 25 e a vista debruçada mais
   apertada (FOV 38 → 30); a página enche a tela e a letra se lê.
4. ✅ **Ao abrir a porta, o personagem gira.** Medido: perto da maçaneta, o giro do
   caminho (no mínimo 0,5 s) ainda corria quando vinha o de olhar para fora; os
   dois tweens brigavam pela rotação e o corpo dava 352–441°. Feito: um giro novo
   substitui o anterior (`Player._giro`; quem esperava o velho segue) e parte do
   ângulo normalizado; `conduzir` espera o olhar terminar. Agora 45–81°.
5. ✅ **O corredor está simples demais.** Feito: almofadas no lambri (as duas
   paredes), cimalha no alto, passadeira vermelha com galões de latão, dois globos
   de luz com roseta, a janela de guilhotina do poço de luz no fim (vidro fosco)
   com o radiador de ferro embaixo, o quadro de avisos com papéis pregados e o
   banco, a porta 312 (vidro fosco aceso, bandeira) e a 308 do lado da sala
   (apagada), a plaqueta de latão *A. N. WILMARTH — LITERATURE* junto à porta, o
   cinzeiro de pé no alto da escada; lá embaixo, a porta da rua.
6. ✅ **O café está com a textura do chão.** Era a textura de papel pautado em
   coordenadas de mundo — no café e na porcelana (a xícara, o pires): as linhas
   pareciam tábuas. Feito: líquidos, porcelana e vidro fosco sobre o grão neutro.
7. ✅ **Começar o dia no pé da escada.** Feito: a escada é andável (rampas de
   colisão rentes aos narizes dos dois lanços, o patamar, o andar de baixo com as
   paredes do vão); a marca `Porta` está lá embaixo, junto à porta da rua — a
   manhã e a volta de Boston começam ali (~5 s de subida até a porta); o dia
   acaba descendo, no patamar (`%Escada`). O piso do corredor passava 20 cm sobre
   a boca da escada e virava um degrau invisível no alto. O teste sobe e desce
   andando, com a física.
8. ✅ **Abrir o pacote antes de tirar as coisas.** Feito: o pacote é uma caixa de
   papelão aberta em cima com duas abas (`Correspondencia.abas`, meta `aberta`);
   **"Abrir o pacote"**: o barbante cai, as abas se abrem, e o bilhete, a
   transcrição e o estojo se veem lá dentro até saírem, um a um.
9. ✅ **A poltrona perto demais das paredes.** Feito: de (1,7; 0,88) para (1,15;
   0,95), ainda virada para o fogo (−32°); a mesinha vai junto.
10. ✅ **O sonho estilhaçado, como o Vazio de *Dishonored*.** Feito: `Vazio`
    (`components/vazio.gd`) nas noites dentro da sala (2, 4, 5), mais a cada noite:
    as paredes leste e oeste e o teto viram estilhaços do mesmo material (UV do
    lugar original), com frestas escuras; perto das `brechas`, eles se soltam em
    ~7 s, giram e boiam para fora; pedaços de prédio boiam no escuro; livros
    (um em três aberto, batendo as folhas) e papéis flutuam. Acordado, as paredes
    voltam. A névoa do sonho ficou mais funda (até 12 m) para os destroços.
11. ✅ **A ondulação forte demais.** Era o redemoinho afim das texturas, que no
    sonho (e com exposição alta) ia a 5×. Feito: 2,5×; o tremor de vértices 2,5 →
    2,0; a onda da tela pela metade.
12. ✅ **O modelo da pedra.** Feito: no lugar de duas caixas, uma estela de faces
    irregulares (`_monolito`: anéis de 7 lados com arestas de talhe, mais larga
    embaixo, o alto em duas águas tortas, uma quina lascada) e a textura nova
    (128 px, veios, fileiras de hieróglifos entalhados — sulco escuro, borda clara
    —, meio gastos).
13. ✅ **Cartas que ainda se teletransportavam.** Eram duas: ao abrir um envelope, a
    carta de dentro surgia pronta na mesa; ao desamarrar um maço, as cartas soltas
    surgiam cada uma no seu lugar. Feito: aberto, tudo o que só aparece aberto sai
    de dentro do envelope (ou do maço), num arco, até o seu lugar, uma peça depois
    da outra (`Correspondencia._tirar_conteudo`).
14. ✅ **O mi-go devagar e claro demais.** Feito: sobe na vertical, de baixo do
    peitoril até sumir no alto, em 1,1 s (era 2,6 s na horizontal), as asas mais
    rápidas, o clarão mais fraco.
15. ✅ **Travado depois de "Sentar diante do fogo".** Era no próprio sonho da noite
    5: ele adormece sentado na poltrona, e andar o levantava dentro da colisão
    dela. Feito: levantando-se andando, ele dá o passo até o lugar livre mais perto
    (`Player._desencaixar`, `Player.livre`); o teste confere.
16. ✅ **O menu como páginas de um livro.** Feito: `Livro` (`ui/menu/livro.gd`) — a
    capa de couro, as páginas com grão e a sombra da lombada, os números de página;
    o tema de tinta (botões como entradas de sumário, sublinhados no foco). Menu
    principal: à esquerda o título, *Vermont, 1928* e a epígrafe do conto; à
    direita o **Sumário**. As **Opções** são as páginas seguintes: a folha vira de
    verdade (a imagem da página que sai se levanta e deita do outro lado, a nova
    aparece por baixo) e volta ao fechar. A **pausa** no mesmo livro, com a data do
    dia (*Arkham, 18 de julho de 1928*).

## Fase 3h — Ajustes do playtest 7 (2026-10-09)
O usuário jogou o playtest 7. Legenda: ✅ feito · 🔧 claro, a fazer · ❓ espera resposta.
Aprovado: *"o sonho da marca da garra ficou EXCELENTE"* (o Vazio da noite 2) e o
corredor "ficou bonito". Commits: `7b1db7d` (5), `3e843c3` (3, 6), `079207b` (2, 7),
`aa2f564` (4), `b61b0f3` (1).

1. ✅ **O menu como o de *Castlevania: Lords of Shadow 2*** — *"é o Necronomicon
   afinal. Capa pesada, livro gigante, folhas velhas"*. Respondido: livro 3D numa
   cena. Feito: `Necronomicon` (`ui/menu/necronomicon.gd`) — um tomo de meio metro
   por página, aberto sobre uma mesa escura, entre duas velas grossas em pratos de
   latão (as chamas e a luz tremendo, sombras); a capa de couro quase negro com
   cantoneiras de metal, a moldura em relevo, os cravos e o medalhão com a estrela
   de cinco pontas e o olho; as correias dos fechos pendendo, as fitas marcadoras; o
   miolo grosso (o corte de centenas de folhas desiguais, `livro_corte.gdshader`); as
   páginas de papel velho, amarelado, manchado, com pintas de mofo, que sobem junto
   à lombada e escurecem no vinco e nas bordas (`livro_pagina.gdshader`). Ao abrir o
   jogo, o livro está fechado, a capa para cima, e ela se levanta e deita do outro
   lado. Os menus (principal, pausa, Opções) moram num SubViewport (`Paginas`) cuja
   tinta é impressa nas páginas; o mouse aponta para a página pelo raio da câmera.
   Passar às Opções vira uma folha de verdade, em 3D, que se curva (a frente com a
   página que sai, o verso com a que chega), e volta. A pausa abre o livro já aberto.
   A câmera respira e segue um pouco o mouse. O `Livro` de cada menu virou só o
   arranjo nas páginas e a ponte para o Necronomicon.
2. ✅ **Bugs visuais no corredor.** Os "batentes na frente das portas": o lambri, o
   rodapé e as almofadas corriam a parede inteira e passavam por cima das portas
   312 e 308 (e da calha); agora param nelas (`_trechos`). O "degrau mostrando o
   limbo": o piso do corredor terminava 18 cm acima do primeiro degrau sem espelho,
   e o patamar (12 cm) não descia até o primeiro degrau do segundo lanço — por esses
   vãos via-se o vazio. Fechados (o espelho do primeiro degrau, o patamar mais
   grosso); os narizes dos degraus foram para a borda da frente.
3. ✅ **O diário dá uma bugadinha ao fechar** (o caderno na mesa). Medido quadro a
   quadro: ao fechar, as páginas escritas sumiam de uma vez e no lugar ficava o
   corte riscado do miolo. Agora o alto do miolo é a própria página (em branco; a
   do dia, na fita, só depois que a última folha sai de cima dela), as folhas que
   correm são papel pautado, e a página escrita da esquerda sai com a última folha.
4. ✅ **Todos os sonhos com a estética do Vazio**, inclusive o do fonógrafo. As
   noites 2, 4 e 5 já se partiam (na sala); a noite 3 (o bosque do disco) agora
   também: além de 6 m da clareira (menos a faixa ao pé da encosta, com a caverna e
   os vultos), o chão se solta em ilhas de terra com a pedra em ponta por baixo,
   com as árvores, juncos e pedras que estavam nelas, e elas sobem, afundam, tombam
   e boiam (`Vazio.soltos`); pedaços de pedra e madeira boiam longe; livros e as
   folhas soltas flutuam na clareira; uma claridade fria vem de baixo, do vazio. A
   colisão segue o chão que ficou.
5. ✅ **Pular fala com E.** Com algo na mira, E interage; sem nada, pula a fala do
   narrador e a de quem fala numa conversa ou no telefone (`Narrator.pular`,
   `esperar_fala`); num modal, o E é do modal. Nas cenas sem controle não há mira,
   então E sempre pula.
6. ✅ **No diário, a vista presa à pena.** Escrevendo, os olhos ficam na linha (o
   meio da página, na altura dela), puxam só 30% para a pena e vão na metade da
   velocidade (`Diario.PUXAO_DA_PENA`) — em todas as entradas (é o mesmo código).
7. ✅ **Uma animação para acender o fogo.** `AcenderLareira`: ele vai até a
   lareira, ajoelha-se (`Player.abaixar`), risca um fósforo (a chama pequena na mão
   e a luz dela), leva-o ao jornal amassado sob as toras, e o fogo pega no meio e se
   espalha em ~6 s (`Fogo.intensidade`: as chamas, a luz e o crepitar crescem);
   sacode o fósforo e se levanta.

Também: o teste do vulto na janela (Dia 5) às vezes não pegava o mi-go visível
(passa em 1,1 s, 8× acelerado); agora anota quando ele aparece.

## Sessão de tester (2026-10-09, antes do playtest 8)
O usuário pediu: *"faça o papel de tester… passe por todos os dias testando
possibilidades e corrigindo bugs"*. Em vez de só o roteiro feliz do teste de
fumaça, um segundo teste, **`tests/caminhos_test.tscn`** (estende o de fumaça e
usa as mesmas ajudas), joga os caminhos que o jogador pode tomar fora dele, e um
**macaco** (`CAMINHOS=macaco`, `SEMENTE=n`) joga a demo inteira ao acaso: a cada
passo, uma das interações disponíveis (as menos usadas primeiro), mirando de
verdade; nas telas, qualquer abertura, carta amassada, folhear; no meio das cenas,
a pausa, o dossiê, E para pular. Todo erro no log (um `Logger`) vira falha.

Commits: `b62e9b2` (itens 1–8) e `f479c18` (item 9). O macaco jogou a demo inteira, do
Dia 1 à tinta da última carta (~6.000 ações cada), com as sementes 1 e 2, sem
travar nem sair do mapa, depois das correções.

Bugs achados e corrigidos:
1. ✅ **A pausa (Esc) ou o dossiê (Tab) no meio de uma cena devolviam o controle.**
   Fechada a tela, o `Player` fazia `input_enabled = true` — no meio de selar a
   carta, do diário, da lareira, da porta, da calha, do lapso: ele andava sentado,
   levantava no meio do diário. Agora a tela aberta desliga por cima do que a cena
   quer (`Player._modal` × `_livre_na_cena`), e fechada volta o que a cena quer; as
   cenas devolvem com `input_enabled = true` (não mais `not is_modal_open`).
2. ✅ **A noite do Dia 5 sem a lareira acesa.** Acender o fogo não é obrigatório,
   mas "Sentar diante do fogo" só existe com ele: anotado o dia sem fogo, a fala
   dizia *"Fiquei diante do fogo, com o copo"* e nada aparecia — o jogador ficava
   sem saber o que fazer. Agora `sono_fogo` tem uma variante com a lareira apagada:
   *"…A sala esfriara; faltava acender a lareira e ficar diante do fogo, com o
   copo."* (💬 texto novo, esperando aprovação, como o resto de `sono_fogo`).
3. ✅ **Erros "Lambda capture was freed" no log** (2 por partida). Ler a carta
   enquanto ela ainda voava do envelope para a mesa (o `DocumentPickup` a tira da
   cena) deixava o tween chamando um lambda com o nó já liberado. Os tweens do
   conteúdo (`Correspondencia._sair`, `_retirar`) seguram a peça por referência fraca.
4. ✅ **No sonho, a porta oferecia "Ir para casa" e o caderno "Ler o diário"** (o
   sonho da poltrona, noite 5; a porta também nas noites 2 e 4) — e não faziam
   nada. Saem da mira enquanto `sonhando`.
5. ✅ **Lapso por cima de outra cena.** Uma ligação que salta no tempo (Dia 5, a
   resposta ao telegrama) podia acabar com ele ajoelhado acendendo a lareira: as duas
   cenas brigavam pelo corpo e pela cabeça, e a que acabava primeiro devolvia o
   controle no meio da outra. O lapso agora espera a cena em curso (`Player.em_cena`).
6. ✅ A lareira não conferia se a fase ainda existia antes de devolver o controle
   (sair para o menu no fim da animação).
8. ✅ **Preso sentado, entre a pausa e o diário** (achado pelo macaco, semente 1,
   Dia 2): "Ler o diário" → Tab (o dossiê) enquanto o caderno ainda abre → fechar o
   dossiê → Esc. "Há tela aberta" era um booleano só: fechar o dossiê o dava por
   falso com o diário ainda aberto, e o Esc seguinte abria a pausa em vez de fechar
   o caderno — e de novo, e de novo. Agora `Events.modal(dono, aberta)` registra
   quem tem tela aberta; `modal_changed` só sai quando abre a primeira ou fecha a
   última (e uma tela que some sem fechar, com a fase trocada, sai do registro).
9. ✅ **Examinando algo quando a ligação de Keene leva a Boston** (o macaco,
   semente 2, Dia 4): a fase trocava com o visualizador aberto sobre um objeto já
   liberado — erro a cada quadro, e a tela de exame presa sobre Boston. O
   `ExamineViewer` se fecha quando o alvo some. E "Escrever a Akeley" (Dia 4) aparecia
   na mesa uns segundos antes da troca (a ligação marca `ligou_relato_keene` antes de
   ir): agora só com `voltou_de_boston` — as cartas da noite, como no livro.
   (Gerador e cena: só essa condição; a cena não foi regenerada inteira para não
   mexer nos ids.)
7. ✅ No teste de fumaça, "levantar a agulha; o zumbido fica" falhava às vezes (o
   zumbido sobe num tween de processo; com o tempo 8×, dois quadros de física não
   bastavam). Espera o zumbido.

Conferido e sem bug: sair para o menu no meio do correio e no meio do sonho e
continuar (volta à manhã do checkpoint, nada pendurado na mão, sem a estética do
sonho); descer a escada com a carta na mão (o dia não acaba; volta, a porta fecha,
posta depois); folhear o diário vazio no Dia 1 (Esc fecha o caderno, não abre a
pausa); continuar no checkpoint de Boston; todo documento resolve texto em todo tom
de resposta, com as tags BBCode fechadas dentro do parágrafo.

## Sessão de tester 2 (2026-10-09, antes do playtest 8)
O usuário pediu: *"aplique testes nos dias e corrija possíveis bugs, também
verifique os possíveis bugs visuais e os corrija"*. Rodados a fumaça, os caminhos e o
macaco com sementes novas (3 a 13), e o macaco agora pode **forçar o tom** das
respostas (`TOM=-1/0/1`, `comandos.ps1 macaco <semente> <tom>`): a demo inteira
respondida sempre cética, neutra ou crédula. Caminhos novos em
`tests/caminhos_test.gd`: a legenda presa, F2/F3 no meio das cenas, o menu no cartão
do fim, o menu só pelo teclado, o diário aberto na ida a Boston. Para o visual, cada
dia capturado de vários pontos (`tests/_tmp_shot`: o pé da escada, a porta, a sala
nas quatro direções, a mesa, o cesto, o canto do armário; `SHOT_MODO=sonhos` as
noites 2–5, `SHOT_MODO=boston` a pensão; `SHOT_SONDA` lista as malhas numa caixa).

Commit: `50ea10c`.

Bugs achados e corrigidos:
1. ✅ **O jogo travava sem controle pelo resto da partida** (o macaco, semente 7, tom
   cético, Dia 5). O registro de telas abertas (`Events._modais`) era um
   `Dictionary[Object, bool]`: um dicionário tipado não apaga a chave de um objeto
   já liberado (o Godot recusa, com erro a cada quadro), então a tela que sumia
   sem fechar ficava "aberta" para sempre — o jogador parado, a pausa sem abrir.
   Quem sumia: o **diário**, aberto ("Ler o diário") enquanto a ligação de Keene
   acabava e levava a Boston (Dia 4). Agora a chave é o id da instância (a tela
   liberada sai do registro, com o aviso "Tela liberada sem fechar", que o
   `caminhos_test` conta como falha), e o diário fecha a sua tela no `_exit_tree`.
2. ✅ **A legenda de som ficava na tela depois de trocar de fase ou sair para o
   menu** (o disco, o telefone, a conversa em Boston) até o tempo dela acabar — e
   reaparecia por cima do jogo continuado. O SceneDirector apaga a legenda junto
   com a fala do narrador (`_calar`).
3. ✅ (depuração) **F3 no meio de selar perdia a carta**: a resposta ficava escrita
   e a carta sumia com o load — não havia mais o que postar. O F3 devolve à mão a
   carta selada e não postada (`Escritorio.carta_por_postar`).
4. ✅ (teste) O macaco se punha, ao mirar, além da fresta da porta do rapaz em
   Boston, onde não há chão (o jogador não chega lá a pé) e caía do mapa. Só se põe
   onde há chão.
5. ✅ (teste) Quatro conferências do teste de fumaça falhavam às vezes, pelo tamanho
   do quadro: "pegar o correio" e "pôr na mesa" (sob carga, a 8×, o arco inteiro
   cabia num quadro), a primeira legenda do disco (o áudio não acelera com o tempo)
   e "sonho liga a estética crua" (sai no `_process`; esperava quadros de física);
   e a conferência de alcance da mira logo depois de algo sair do envelope (as
   peças ainda no arco): `_check_alcance` espera 1 s de jogo. Depois disso, 14
   fumaças com 0 falhas (9 delas com outros testes rodando junto).
5b. ✅ **O jogo às vezes travava de vez na volta de Boston** (2 em ~12 testes de
   fumaça, sempre em "Voltar a Arkham", o processo vivo e nenhum quadro mais). Só
   essa troca recarregava do zero, num thread, centenas de recursos do escritório
   (liberados junto com a fase velha) — o padrão de um impasse entre o carregamento
   em thread e o thread principal. A causa exata no motor não foi isolada. O
   SceneDirector agora guarda as fases já carregadas (`_cenas`: o escritório e
   Boston), e a troca para uma delas é imediata, sem carregar nada.

Bugs visuais corrigidos (nos geradores; as cenas regeneradas só mudam de ids):
6. ✅ **O armário do canto sudoeste era um bloco liso**, com a junção das portas
   virada para a parede; à noite, a luz da fresta da porta o acendia inteiro, alaranjado,
   no escuro. Agora tem rodapé, tampo, duas portas almofadadas e puxadores de latão,
   e fica fora da luz da fresta (camada de render 2, fora do cull dela).
7. ✅ **O cesto de papéis tinha tampa**: o aro era um cilindro com tampas e fechava a
   boca. Agora é só a faixa (o cesto vai receber as folhas amassadas na Fase 5).
8. ✅ **Dia 2: os envelopes dos opositores passavam por baixo da base da lâmpada**, e
   a carta do leitor, por baixo dela e do rascunho. A carta fica por cima do
   rascunho, à direita do tinteiro; os envelopes, no fundo dela, longe da lâmpada.
9. ✅ **Boston: virado para a escada, um retângulo todo preto** — a única luz do
   corredor ficava a 3 m e nem o corrimão aparecia. Uma luz fraca do andar de baixo,
   junto ao vão: o corrimão e os balaústres se leem.

Conferido e sem bug: as manhãs dos seis dias (escada, porta, sala, mesa), as noites
2–5 (o visual do sonho segue pendente, como antes), Boston; F2/F3 escrevendo o
diário, adormecendo, ao telefone, no meio do lapso, acendendo a lareira (nada
pendurado: pálpebras, sonho, legenda, pausa); durante a tinta do fim a pausa não
abre, e no cartão do fim abre — sair para o menu e continuar volta à manhã do Dia 6;
o Necronomicon só pelo teclado (setas, Enter nas Opções, Esc de volta, Continuar).

## Sessão do menu e do marco Demo (2026-10-09, antes do playtest 8)
O usuário pediu: *"faça o que disse que pode fazer sem mim [acessibilidade, export,
testes] e dê MUITA atenção e carinho para o nosso menu, deixe ele fenomenal [...]
mantendo nosso gráfico característico, mas com boas animações"*, com três imagens
de *Castlevania: Lords of Shadow* (o livro do menu: moldura de ferro rebitada,
papel queimado nas bordas com manchas rubras, gravura grande à esquerda, título
gótico e sumário à direita, setas rubras na entrada escolhida, a dica de controle
embaixo). Commit: `cc98f0a`.

O Necronomicon refeito (`ui/menu/`):
1. ✅ **No grão do jogo.** O livro agora é renderizado em ~540 linhas, com o
   pontilhado e as cores do PS1 (`psx_post`) e uma vinheta funda — antes era a
   única coisa do jogo em alta resolução, lisa demais.
2. ✅ **A encadernação** (à maneira da referência): a capa de couro quase negro
   com uma **moldura de ferro rebitada** dos dois lados das tábuas (barras com
   rebites de latão, cantoneiras com cravo de diamante), fechos com dobradiça,
   chapa e argola nas bordas, o medalhão com a estrela e o olho, a lombada com as
   nervuras de ferro; a fita marcadora de veludo rubro que sai do vinco, dobra no
   miolo e corre na mesa com a ponta em V.
3. ✅ **O papel** (`livro_pagina.gdshader`): fibras, a borda gasta e **queimada**
   em contorno irregular, as **manchas cor de ferrugem** que sobem das bordas em
   línguas, o vinco fundo; a tinta assenta e se espalha um pouco nas fibras.
4. ✅ **O que está impresso nas páginas** (`OrnamentoPagina`): a moldura de filete
   duplo com florões rubros nos cantos e no meio das bordas, os números em
   versalete rubro, uma escrita de outra mão apagada pelo tempo num canto, e um
   círculo de invocação desbotado atrás do texto.
5. ✅ **A gravura** (`Gravura`, como a cruz radiante da referência): a **pedra
   negra de Round Hill** — a estela quebrada no alto, com os hieróglifos em
   colunas e uma rachadura — num anel de sinais, com a coroa de raios rubros e
   negros; embaixo, dois medalhões com a **marca de garra** das fotografias de
   Akeley. Também na pausa (sem os medalhões).
6. ✅ **A letra:** o título em fraktur (UnifrakturMaguntia, "Os que" em tinta e
   **"Sussurram" em rubro**), as entradas do sumário em gótica (Grenze Gotisch), o
   texto em IM Fell English (a letra de livro do séc. XVII; itálico e versalete).
   Fontes OFL em `art/fonts`, com as licenças.
7. ✅ **A entrada escolhida** (`MarcadorFoco`): duas pontas de lança rubras com
   voluta a ladeiam (como as setas da referência), **deslizam** de uma entrada à
   outra e respiram; a escolhida avermelha e dá um pulso; a pena risca baixinho.
   O mouse sobre uma entrada a escolhe (nunca duas grifadas). Nos controles
   deslizantes, a ponta só à esquerda e a marca rubra.
8. ✅ **A abertura** (o jogo começando): o escuro; as **velas se acendem** uma e
   outra (o fósforo); a câmera, perto da capa fechada, se afasta enquanto a
   **capa pesada se levanta e cai** do outro lado — **o baque**, a câmera estremece,
   **a poeira sobe** das páginas; as páginas assentam com um tremor, e **a tinta
   brota** no papel, do meio para fora, com a borda molhada e brilhante. Qualquer
   tecla ou clique pula. De volta do jogo, o livro já aberto, a tinta brotando.
9. ✅ **A pausa** chega deslizando, já aberta, e assenta na mesa.
10. ✅ **A folha que vira** faz **sombra** na página que descobre e na que vai cobrir.
11. ✅ **Começar ou continuar: o mergulho.** A tinta da entrada escolhida se
    derrama pela página e toma a tela (borda irregular com debrum rubro,
    `tinta_espalha.gdshader`) enquanto a câmera desce para dentro dela; o jogo
    começa no escuro.
12. ✅ **A vida no livro:** poeira boiando na luz; as velas (fora do quadro, só a
    luz delas) tremem cada uma no seu ritmo; o canto da página da direita levanta
    na corrente de ar; a câmera respira e segue um pouco o mouse.
13. ✅ **O cursor é uma pena** enquanto o livro está à vista.
14. ✅ **A dica de controle** embaixo, à direita (*Selecionar [Enter]*, *Voltar ao
    jogo [Esc]*, *Ajustar ◂ ▸*), como na referência.
15. ✅ As Opções em três seções (o som; a tela e os controles; a acessibilidade),
    o título em fraktur rubro; a confirmação ("Começar de novo apaga...") com as
    escolhas afastadas para o marcador não invadir a vizinha.

O resto do marco Demo (o que dava para fazer sem o usuário):
16. ✅ **Acessibilidade** (GDD §12): em Opções, **campo de visão** (60–95°, ao vivo
    na câmera do jogador), **tremor das formas** e **ondulação das texturas** (0–100%:
    multiplicam o `psx_jitter` e o `psx_affine` do GameRoot, inclusive no sonho).
    `Settings`: `campo_visao`, `tremor`, `distorcao`.
17. ✅ **Export:** `export_presets.cfg` com o preset **Windows** (sem `tests/`,
    `tools/` e a sala de teste; o pacote embutido no .exe), `comandos.ps1 exportar`
    → `build/windows/OsQueSussurram.exe` (fora do git) e `jogar-exportado`.
    Instalados os templates de export do 4.7.2 (só os de Windows) em
    `%APPDATA%\Godot\export_templates\4.7.2.stable`. O exportado (release, sem os
    atalhos de teste) abre no menu sem erro de script.
18. ✅ **Testes:** `caminhos_test` ganhou a abertura do livro (uma tecla pula; sem
    tecla, acaba sozinha) e a acessibilidade (o campo de visão chega à câmera; tremor
    e ondulação a zero desligam, até no sonho). `tests/_tmp_shot` com `SHOT_MODO=menu`
    captura a abertura, o marcador andando, a folha virando, as Opções, a pausa
    chegando, a confirmação e o mergulho.

## Fase 3i — Ajustes do playtest 8 (2026-10-09)
O usuário jogou o playtest 8 (do Dia 1 ao fim da demo). Legenda: ✅ feito · 🔧 claro,
a fazer · ❓ espera resposta. Aprovado: *"o cuidado que tivemos com o livro do menu
[...] está muito bom"* — e o pedido é **esse cuidado em tudo** (item 12). Decisões
tomadas na hora (o usuário escolheu entre opções): o nome **Yuggoth**; **sem corpo**
visível; os sons com **gravações CC0 tratadas**; os últimos dias com **o sonho logo
depois da farsa e uma noite em claro** (item 13). Commits: `b755e51` (1, 7, 14),
`1c6019c` (4, 6, 8, 9, 10, 11), `2dc3625` (13), `252b161` (2).

1. ✅ **O nome.** *"temos que escolher um nome melhor do que 'Os que sussurram'"*.
   Decidido: **Yuggoth** (já é o nome do projeto; uma palavra, PT e EN, em fraktur no
   Necronomicon). Feito: no menu, "Yuggoth" em gótica rubra (a Grenze Gotisch — na
   fraktur o Y se lia N); na pausa, *yuggoth*; o export sai em `build/windows/Yuggoth.exe`.
2. ✅ **Os sons do menu "muito toscos"** e **os efeitos como um todo "bastante
   genéricos"**. Decidido: trocar a síntese por **gravações CC0** (licença livre
   para o repositório público), tratadas — a reverberação de cada lugar, variações
   a cada toque —; a síntese fica só para o sobrenatural (o zumbido, as vozes do disco).
   Feito: 19 fontes CC0 do OpenGameArt (Kenney — o kenney.nl está bloqueado nesta
   rede, mas os pacotes dele estão espelhados lá —, Voltiment555, Ylmir, PagDev,
   Luckius, TinyWorlds e outros; lista em `audio/foley/FONTES.md`), tratadas por
   `tools/tratar_sons.py` (num venv com numpy/scipy/soundfile: corte, nível, uma
   reverberação curta de sala por convolução, laços sem emenda, mudanças de altura)
   em `audio/foley/`, 29 sons: os passos no assoalho, as portas, a gaveta, a janela,
   bater à porta, o fósforo, a lareira, a chuva na janela, a noite (grilos e vento),
   o vento, o relógio, a campainha do telefone e o gancho, o papel, a carta pela
   fresta, o pacote, o selo, a pena, a lama; e os do **Necronomicon** (a folha grossa
   virando, a capa de couro rangendo, o baque grave na mesa, o fósforo das velas, o
   risco da pena ao passar e ao escolher). Os geradores preferem `audio/foley/`
   (`gerador_base._sfx`); `AudioDirector.play_sfx` varia a altura de cada toque
   (±4%). Ficaram sintetizados: o disco, o zumbido, as vozes, o sonho, a tarde com
   pássaros, o dia quieto, a manivela, a linha do telefone, a calha, servir.
3. ❓ **"O modelo da janela do epílogo está bastante diferente."** Conferido em
   captura: a janela do gabinete de 1930 (o Prólogo) é o mesmo modelo da de 1928
   (`_janela`, na `Estrutura`); mudam só a vista (noite de chuva) e as cortinas (que
   o gabinete não tem). Perguntado ao usuário o que estava diferente (e se
   "epílogo" é o Prólogo ou o fim da demo) — em `docs/PLAYTEST.md` §3.
4. ✅ **Os certificados na parede legíveis.** Feito: os dois diplomas têm o texto de
   verdade (Label3D, em inglês como tudo o que é impresso: *Miskatonic University*
   em fraktur, o nome dele em caligrafia, *Bachelor of Arts* 1911 e *Master of Arts*
   1914 — os graus são nossos, o livro só diz "instrutor de literatura"), o
   pergaminho novo (filete duplo, o selo de lacre com a fita) e são examináveis,
   com a tradução embaixo; de perto, no exame, lê-se tudo. `_impresso()` no gerador
   encolhe a linha que não cabe no papel.
5. ✅ **Um corpo visível ao olhar para baixo?** O usuário pediu ajuda para decidir;
   escolheu **sem corpo** (como os jogos de PS1): nada muda.
6. ✅ **Os papéis do mural do corredor com algo para ler.** Feito: seis avisos da
   Miskatonic em 1928, em inglês, em papel liso (`AVISOS` no gerador), cada um
   examinável ("Ler o aviso") com a tradução: o socorro às vítimas das enchentes de
   Vermont (com que o livro começa), o horário de atendimento de Wilmarth (sala
   310, e a nota dele: a Sociedade de Folclore), a biblioteca de Henry Armitage, uma
   palestra sobre lendas das colinas, achados, um quarto para alugar.
7. ✅ **Pular falas não pode ser o E** (*"acabei pulando algumas mensagens que não
   deveria"*): um botão próprio, longe da ação. Feito: **Espaço** (Y no controle), a
   ação `pular_fala`; o E só interage.
8. ✅ **O estojo do cilindro** (Dia 3): um modelo melhor. Feito: `_estojo_cilindro()`
   — o tubo de papelão pardo, a tampa de papelão envernizado com a borda, o fundo,
   duas cintas, a etiqueta impressa que dá a volta (*DICTAPHONE · WAX CYLINDER
   RECORD*) e, na tampa, um disco de papel com a letra de Akeley (*May 1, 1915*).
   O mesmo modelo dentro do pacote e nos estojos da prateleira do fonógrafo.
9. ✅ **O mi-go do sonho do disco "muito expositivo"** (o usuário não tinha certeza).
   Recomendado e adotado: mais sugestão — longe, na névoa, por trás das árvores, só a
   silhueta e o som das asas. No livro, Wilmarth nunca vê uma delas viva; a única
   vista clara do jogo continua sendo o relance na janela, no Dia 5. Feito: a
   `Aparicao` passa no alto da encosta, atrás da boca da caverna, mais longe (na
   névoa), em 1,7 s, como silhueta escura com as asas batendo.
10. ✅ **Boston: a saída é uma parede lisa** com "Voltar a Arkham". Uma escada de verdade.
    Feito (`gerar_boston._escada`): um lanço de 8 degraus desce para o sul entre as
    paredes, com a passadeira presa por varetas de latão, os narizes, os rodapés
    inclinados, o corrimão na parede em suportes de ferro e o pilar no alto; no
    patamar, um quadro velho, e o resto da escada vira para oeste e some no andar
    de baixo, de onde sobe a luz amarela de uma arandela. Andável (rampas); descer
    até o patamar, com a conversa feita, volta a Arkham (`%Descida`), e "Voltar a
    Arkham" no alto da escada continua valendo.
11. ✅ **A pedra de Round Hill (noite 4) com o modelo quebrado.** Os anéis torcidos
    do `_monolito` dobravam as faces umas sobre as outras, e as normais suaves
    espalhavam a textura como pano. Agora uma estela como a gravura do menu: a laje
    de faces planas, mais larga embaixo, o alto partido em dentes, as arestas
    chanfradas; os hieróglifos com a borda de baixo mais clara (pegam a luz).
12. 🔧 **"O cuidado que tivemos com o livro do menu em tudo."** (contínuo) A diretriz da fase: cada
    peça mexida aqui sai no nível do Necronomicon (forma, material, desgaste,
    animação, som), a começar pelo que o jogador mais vê de perto. Nesta fase: a
    pedra, o estojo, os diplomas e os avisos, a escada de Boston, os sons. Fica
    como regra para as próximas.
13. ✅ **Os últimos dias: "só carta e ler carta"**, as passadas de dia (*"sempre a mesma
    animação, e ela demora"*) e o sonho do A-K-E-L-Y que *"demora para acontecer
    depois de ele perceber a farsa"*. Decidido:
    - o **Dia 5 se parte no bilhete**: comparada a assinatura e posta a renovação da
      oferta, o diário e **o sonho AKELY nessa mesma noite** (22 de agosto); de manhã,
      a carta de 28 de agosto no correio, a resposta, o diário (sem sonho);
    - no **Dia 6**, depois da carta de terça (*"Não dormi nada naquela noite"*), **uma
      noite em claro jogável** na sala, com as estranhezas da Fase 6 (o telefone que dá
      meio toque e só zumbe na linha, a janela entreaberta, a criatura no céu sem lua),
      no lugar de um lapso;
    - **o lapso mais curto e diferente a cada vez**.

    Feito:
    - **Dia 5 (15–22 de agosto)** acaba na renovação da oferta: `Escritorio.respostas_do_dia`
      (`{5: renovacao_dia_5}`, `id_resposta()`) diz qual resposta fecha o dia; postada,
      não há salto — o diário (a entrada nova, de 22 de agosto), o fogo, a poltrona e
      o sonho do AKELY, na noite da farsa.
    - **Dia 6 (28 de agosto – 7 de setembro)** abre com a carta de 28 de agosto no chão
      (*"A resposta dele chegou a 28 de agosto."*, o cartão do dia *"Fim de agosto de
      1928."*); a resposta animadora (com tom; `resposta_dia_5`, o mesmo id) cruza o
      correio até a carta calma (`cartao_31_agosto`, o que era a fala do correio).
    - **A noite em claro** (`components/vigilia.gd`, `Vigilia`): fechada a carta de
      terça (`Escritorio.vigilia_depois_de`), *"Não dormi nada naquela noite..."*, e a
      noite é jogável: o telefone dá meio toque e cala (a `Ligacao` `vigilia_linha`,
      "Tirar o fone do gancho", sem manivela — `com_manivela`: só um zumbido); sem
      ninguém ver, a janela que estava fechada aparece entreaberta (a folha sobe um
      palmo, o vento, as cortinas balançam presas no varão) — "Fechar a janela"; a
      criatura no céu para quem olhar; então "Sentar e esperar o dia": a aurora entra
      devagar (`Lapso.raiar`), a folhinha cai para 7 de setembro, *"A resposta veio,
      de fato, no dia seguinte."* e a carta de quarta cai pela fresta.
    - **O lapso** dura metade (`DURACAO_TOTAL` 9 s, ~5 s por dia) e tem estilos
      (`Lapso.ESTILOS`, `Escritorio.estilos_lapso` por cartão): "chuva" (os dois do
      Dia 5: a cidade na chuva o tempo todo, sem sol, a chuva não para), "dias" e
      "noite" (a carta de terça, *"na manhã seguinte"*: a cidade apaga, um fio de
      aurora, e já é a noite seguinte). Nos Dias 4–6, de 7 lapsos de 18 s para 6 de
      ~5–9 s, e a noite em claro no lugar do sétimo (a contagem de 4, prevista ao
      registrar, não fechou: tirar mais um pularia uma carta que o livro manda).
    - O F2 (depuração) usa o `respostas_do_dia`; o teste de fumaça joga a noite em
      claro inteira e mede o lapso (< 14 s).
14. ✅ **Um mi-go passa em pleno sol** numa passada de dia: a criatura do céu (Dias 3
    e 6) valia durante o lapso, com a cidade de dia. Feito: nenhuma `Aparicao` passa
    enquanto um lapso corre (`Lapso.em_curso`).

## Fase 3j — Ajustes do playtest 9 (2026-10-09)
O usuário jogou o playtest 9. Legenda: ✅ feito · 🔧 claro, a fazer · ❓ espera resposta.

1. ✅ **Sons bobos:** pôr o café, tomar o café, pôr a carta na calha, pôr e tomar o
   uísque (ainda sintetizados). Feito, com gravações CC0 (MoreSounds de OwlishMedia,
   Tinysized SFX, 100 CC0 SFX): o jorro do café e o fio do uísque no copo, a tampa
   da garrafa térmica e a rolha do frasco, um gole, a xícara pousada; a calha é o
   papel na fenda e o deslizar no tubo, com um tique de metal no fim.
2. ✅ **O sonho do disco (noite 3): a entrada da caverna** onde hoje estão o matacão
   (a "bola") e os dois blocos (os "pilares") — uma boca de caverna de verdade na
   encosta, entupida pelo matacão arredondado (como na fotografia do Dia 2). Feito
   (`vistas._caverna`): um afloramento de pedras tortas empilhadas em arco em volta
   de uma abertura negra que entra na encosta, o matacão quase a fechando (a fresta
   em meia-lua), raízes caindo do alto, musgo e samambaias ao pé.
3. ✅ **Entre as árvores distantes, a silhueta de um mi-go observando** — de pé, no
   chão, não voando. Feito: a `Vigia` (uma `Espreita` que aparece fora da vista, depois
   de 14 s de sonho), um `Migo` em silhueta, de pé, as asas recolhidas ao longo do
   corpo (`Migo.recolhidas`), a uns dez metros, meio atrás de um tronco, na névoa.
4. ✅ **Os livros espalhados** (Fase 5): mais claramente de ocultismo e folclore, ou
   examináveis com essa informação. O livro dá os nomes: as autoridades que Akeley
   cita (*"Tylor, Lubbock, Frazer, Quatrefages, Murray, Osborn, Keith, Boule, G.
   Elliot Smith"*) e o *Necronomicon*, que a biblioteca guarda a sete chaves. Feito
   (`LIVROS` no gerador): o título dourado na capa de cima de cada pilha, e cada
   pilha examinável ("Ver os livros": os títulos e o que ele tira do de cima); os
   abertos têm o cabeçalho e as linhas impressas, e se leem ("Ler o livro aberto").
   O aberto no chão do Dia 6 são as notas de Wilmarth do *Necronomicon*, copiadas na
   sala do Dr. Armitage (o livro não sai do armário trancado — o aviso do corredor).
   As descrições são nossas e só afirmam o que os livros de fato tratam.
5. ✅ **Uma luz sobre o mapa**, para ele se ver à noite. Feito: uma luminária de
   quadro, de latão, presa no alto da moldura, com a luz quente sobre o papel.
6. ❓ **A folha principal do dia sempre no meio** da mesa, as outras perto, e as dos
   dias anteriores ficando nas extremidades.
7. ❓ **A passagem do tempo ligada aos livros lidos** (*"para justificar? o take
   talvez?"*), e **"Sentar e esperar o dia" não faz sentido**: se só a noite em claro
   for assim, todos os outros saltos parecem noites sem dormir. Achar uma solução
   para a passagem do tempo que sirva também à noite virada.

## Onde estamos (revisão de 2026-10-09, depois da 3h)
**Ok (feito e commitado):** fases 1, 2, 3, 3b, 3c, a passagem para o sonho, a 3d, a
3e, a 3f, a 3g e a **3h** (itens 1–7). Teste de fumaça com 0 falhas. Tudo enviado
ao GitHub (push). **Regra (2026-10-09):** cada commit é seguido de `git push`, e os
arquivos de coordenação (este, `SEQUENCIA.md`, `FIDELIDADE.md`, `CLAUDE.md`, a
memória) são atualizados junto com o trabalho — ver "Fluxo de trabalho" no
`CLAUDE.md`.

**Sessão de tester feita** (acima, `b62e9b2`): pausa e dossiê no meio das cenas,
telas sobrepostas, a noite sem fogo, a porta no sonho; `caminhos_test` e o macaco.
**Sessão de tester 2 feita** (acima): o travamento pela tela liberada sem fechar (o
diário na ida a Boston), a legenda presa, o F3 que perdia a carta; no visual, o
armário, o cesto, os papéis sob a lâmpada (Dia 2), o vão da escada em Boston; o
macaco com o tom forçado.

**Fase 3i feita** (o playtest 8, acima): menos o item 3 (❓ a janela do
"epílogo", perguntado). Testes: fumaça e caminhos com 0 falhas, e o macaco (semente
3) jogou a demo inteira sem falha, depois da reestruturação dos Dias 5 e 6.

**Esperando o usuário — o playtest 9.** A lista de conferência está em
**`docs/PLAYTEST.md`**: os últimos dias (o sonho do AKELY na noite da farsa, o Dia 6
desde 28 de agosto, a noite em claro, os lapsos), os sons gravados, e o resto da
lista do playtest 8.

**Decisões de texto pendentes:** as entradas do diário (as 3 e 5 mudaram na 3d) e as
falas `sono_disco`/`sono_fogo`; o visual do sonho (pendência antiga); "Deixar sem
resposta" (Dia 2). O bosque do disco (os vultos, a criatura) é 💭. O
congelamento do playtest 4 (envelope, Dia 5) nunca foi reproduzido; se voltar,
olhar o painel Debugger do editor. `art/textures/grao.png.import` aparece
modificado no git desde antes da 3g (reimportação do Godot); deixado de fora dos
commits.

**Como retomar numa sessão nova:** ler este arquivo (a 3i, as sessões de tester e
esta seção). Se o usuário pedir mais testes: `comandos.ps1 caminhos`,
`comandos.ps1 macaco <semente> [tom]` (as sementes 1 a 13 já passam; o tom -1/0/1
força as respostas), capturas com `tests/_tmp_shot` (`SHOT_MODO`, `SHOT_DIAS`), e
cada bug achado vira um item novo de uma sessão de tester, com o commit. Ainda não
testado: o menu e as Opções pelo mouse (o raio da câmera até a página), o Prólogo
fora do roteiro (pausa no cartão, andar sentado), Boston pelo macaco com a conversa
inteira em todas as ordens. Quando vier a lista do playtest 9, registrá-la como
**Fase 3j**, no mesmo formato. Não começar a Fase 4 antes dela.

**A fazer, no código:** fases 4, 5, 6 e 7 (abaixo); do marco Demo (GDD §12), a
acessibilidade e o export já estão feitos (sessão do menu); falta o playtest com
5+ pessoas (com o .exe de `comandos.ps1 exportar`). Fora do código e ainda sem dono: arte final (`docs/ARTE.md`, nenhum
`.glb` ainda), som final e a voz de Noyes no disco.

## Próximos passos (em ordem)
1. ✅ **A passagem para o sonho** (acima): diário + adormecer à mesa + acordar de manhã.
2. ✅ Playtest 3 → **Fase 3d** (acima). Painel × cidade 3D: decidido pela 3D.
2b. ✅ Playtest 4 (até o começo do Dia 5) → **Fase 3e** (acima).
2c. ✅ O usuário jogou o **playtest 5** (até a noite 3); a lista virou a **Fase 3f**.
2d. ✅ Fase 3f: feitos os itens 1–19 (o usuário respondeu os ❓ com as
   recomendações).
2e. ✅ O usuário jogou o **playtest 6**; a lista virou a **Fase 3g**, toda feita.
2f. ✅ O usuário jogou o **playtest 7**; a lista virou a **Fase 3h**, toda feita.
2g. ✅ **Sessão de tester** (acima): `caminhos_test` e o macaco; 9 bugs corrigidos.
2h. ✅ **Sessão de tester 2** (acima): o travamento da tela liberada, a legenda
   presa, o F3; o armário, o cesto, o Dia 2, Boston; o macaco com tom.
2h2. ✅ **Sessão do menu e do marco Demo** (acima): o Necronomicon refeito à maneira
   de *Lords of Shadow*, a acessibilidade, o export para Windows.
2i. ✅ O usuário jogou o **playtest 8**; a lista virou a **Fase 3i** (acima), feita
   menos o item 3 (❓).
2j. **← AQUI.** O usuário joga o **playtest 9** (`docs/PLAYTEST.md`); a lista vira a
   Fase 3j. Não começar a Fase 4 antes dela.
2j2. ✅ **As Fases 4, 5 e 6 feitas antes do playtest 9** (a pedido do usuário: "o que
   você pode fazer enquanto eu não consigo jogar"): o mapa do condado, a sala que
   acumula, as estranhezas. Entram na lista do playtest 9.
2k. **Decidido em 2026-10-09: o recorte do Interlúdio entra na demo** (os beats 1–3:
   o entardecer, a preparação, a noite do telhado; o "continua" depois dos tiros).
   A fazenda tem diário de bordo próprio: **`docs/PLANO_FAZENDA.md`** (o que o livro
   diz da casa, as fases F1–F8, as perguntas). A ordem entre ela e as Fases 4–6
   daqui se decide depois do playtest 9.
3. **Fase 4** — o mapa de Vermont. **Fase 5** — a sala acumula. **Fase 6** — estranhezas.
4. **Fase 7** — fechamento (docs) e o resto do marco Demo (acessibilidade, export).

## Fase 4 — O mapa de Vermont ✅ (2026-10-09, antes do playtest 9)
Feito a pedido do usuário enquanto o playtest 9 não vinha. O mapa do estado inteiro
encolhia a região da história (Townshend, Newfane, Brattleboro, Bellows Falls cabem
em poucos centímetros) e ficava ilegível a 540 linhas; virou um **mapa de condado
de época, o de Windham** (1925), com **o estado inteiro num quadro** no alto à
direita (o condado em destaque, e o Winooski e o Passumpsic do recorte). Na parede
oeste, acima do armário, ao lado do quadro de recortes. A geografia está em
`tools/vermont.gd` (o contorno, o condado, os rios — o West, o Saxtons, o Williams,
o Rock, o Green, o Deerfield —, 27 cidades, os morros), lida pela textura
(`gerar_assets._mapa_vermont`: papel velho, Vermont mais quente que New Hampshire, a
borda do condado tracejada, a grade a cada dez minutos, os morros em hachura) e pelo
gerador (`_mapa`: os nomes impressos em Label3D, em inglês; o título *Windham
County*). O `MapaInvestigacao` (`components/`, um Examinable): lida uma carta que
cita lugares, "Marcar no mapa" — os alfinetes entram um a um (o clique do
`alfinete.wav`), o fio vermelho corre do anterior, e os lugares que o mapa não
imprime ganham o nome na letra de Wilmarth (*Akeley*, *Montanha Escura*, *Round
Hill*, *a caverna*, *Pântano de Lee*, *o fio cortado*); as enchentes do recorte são
alfinetes pretos, fora do fio. Sem nada a marcar, "Examinar o mapa" (de perto, lê-se
tudo). Não trava nada. Marcado fica `mapa_<id>`. O teste de fumaça marca os três do
Dia 1.

- Lida uma carta que cita lugares novos, aparece **"Marcar no mapa"**: um alfinete
  por lugar e o **fio vermelho** liga o novo ao anterior. Não trava a porta.
- 💭 As **fotografias** podem ser presas no mapa, no lugar onde foram tiradas
  ("Prender no quadro"); continuam examináveis lá.

| Dia | Lugares (a carta que os cita) |
|---|---|
| 1 | a fazenda de Akeley, a Montanha Escura, Round Hill (a 1ª carta); o West, o Winooski, o Passumpsic (o recorte das enchentes) |
| 2 | a caverna (a 2ª carta) |
| 3 | o Pântano de Lee (a transcrição do disco), Brattleboro (o bilhete) |
| 4 | Bellows Falls (o telegrama), Keene (a carta de julho) |
| 5 | o fio cortado ao norte de Newfane (a carta de 15 de agosto) |
| 6 | — |

## Fase 5 — A sala acumula (por dia, `dia >= N`) ✅ (2026-10-09, antes do playtest 9)
Feito (`gerar_escritorio._acumula`), sem fala nenhuma: os livros de folclore da
biblioteca (dois no armário no Dia 2; uma pilha no chão a noroeste no 3; outra junto à
mesa e um aberto no armário no 4; duas junto à parede oeste no 5; no 6, abertos no chão
e no peitoril, pilhas junto à porta e em cima do arquivo); as xícaras usadas, com o
fundo de café (no peitoril no 2; no armário no 4; no chão no 5; no 6, uma caída com a
mancha); a planta no peitoril, à esquerda (verde até o 3, amarelando no 4, seca no 5,
morta no 6, com as folhas caídas); a cortina da direita meio fechada no Dia 6 (a vigília
balança também ela); e no cesto as bolas de papel: cada Esc ao escrever amassa a folha
(`folhas_amassadas`, com o som de papel amassado, CC0) e uma bola aparece no cesto (até
oito; mais duas no chão). Diferenças da tabela: os livros do Dia 2 ficam no armário, não
na mesa (a mesa já está cheia de correio); a cortina fecha na troca de dia (no Dia 5 ela
pularia de lugar diante do jogador).
| | Dia 1 | Dia 2 | Dia 3 | Dia 4 | Dia 5 | Dia 6 |
|---|---|---|---|---|---|---|
| Livros de folclore da biblioteca | — | 2 na mesa | pilha | pilha no chão | duas pilhas | por toda parte |
| Xícaras | — | 1 | 1 | 2 | 3 | 4, uma caída |
| Planta na janela | verde | verde | verde | amarelando | seca | morta |
| Cortina | aberta | aberta | aberta | aberta | meio fechada (depois do vulto) | fechada |
| Cesto de papéis | vazio | cada folha **amassada** ao escrever (Esc) vira uma bola de papel no cesto (`folhas_amassadas`) |||||

A vista da janela já muda por dia (maio verde, entardecer, noite, julho, chuva,
noite sem lua); na Fase 2 ela ganha a torre da Miskatonic.

## Fase 6 — Estranhezas sutis 💭 ✅ (2026-10-09, antes do playtest 9)
Feito: `components/estranheza.gd` (`Estranheza`) — com a `condition` (o dia) valendo
e `exposicao` acima do `limiar`, os alvos mudam **só fora da vista** (longe do centro
da tela, ou com parede no meio: um raio na camada `mundo`), uma vez, sem som nem fala;
marca a flag; o dia acabando, tudo volta; usar `desfazer_com` também põe de volta (e
não acontece mais). Três, montadas no fim do gerador (`_estranhezas`): **Dia 4** — o
cilindro de cera fora da máquina, de pé no canto da mesinha (tocar o disco o põe de
volta) e **o relógio parado noutra hora** (limiar 0,55); **Dia 5, depois do bilhete** —
**uma das fotografias virada para baixo** na mesa (0,68). Os limiares partem do mínimo
de quem joga só o necessário (as cartas e o disco somam ~0,45 no Dia 4 e ~0,6 depois
do bilhete): quem examina detalhes, reouve o disco e vê o que passa na janela as vê.
As duas do Dia 6 (o meio toque do telefone, a janela entreaberta) viraram a noite em
claro (Fase 3i) e acontecem para todos. O `caminhos_test` tem o caso `_estranhezas`.
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
