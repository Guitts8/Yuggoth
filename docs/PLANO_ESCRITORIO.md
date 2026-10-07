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
- A cidade 3D, se aprovada, precisa das outras horas (dia, entardecer, chuva) e de
  substituir o painel de vez; se não, sai.

## Próximos passos (em ordem)
1. ✅ **A passagem para o sonho** (acima): diário + adormecer à mesa + acordar de manhã.
2. Playtest do usuário (Prólogo ao fim da demo) — inclusive comparar painel × cidade 3D (C),
   e o diário: o ritmo da escrita e do sono, e se a letra se lê.
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
