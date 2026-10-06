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
