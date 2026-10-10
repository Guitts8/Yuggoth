# Playtest — o que verificar

Lista de conferência do **playtest 10** (do Prólogo ao fim da demo). Os testes
automáticos (`smoke_test`, `caminhos_test`, o macaco) garantem que **tudo se joga
até o fim sem travar**. Eles não julgam se está **bonito, claro, assustador ou fiel
ao livro**, e não usam o mouse no menu. Esta lista é para isso.

O que o playtest encontrar vira a **Fase 3k** em `docs/PLANO_ESCRITORIO.md`
(✅ feito · 🔧 claro, a fazer · ❓ espera resposta). Atualize este arquivo a cada
playtest: o que foi conferido sai, e entra o que mudou.

---

## Como jogar

```powershell
powershell -ExecutionPolicy Bypass -File .\comandos.ps1 jogar      # o jogo
powershell -ExecutionPolicy Bypass -File .\comandos.ps1 jogar-log  # com o console (os erros aparecem)
```

| Tecla | O quê (só no build de teste) |
|---|---|
| **F** (segurar) | tudo 8× mais rápido |
| **F2** | pula para o dia seguinte |
| **F3** | recarrega o dia (destrava; uma carta selada volta à mão) |
| **C** | troca a janela entre a cidade 3D e o painel antigo |
| **Espaço** | pula a fala |

Saves: `comandos.ps1 save-guardar <nome>` guarda o ponto atual, e `save-usar <nome>`
volta a ele.

**Se travar:** anote o dia, o que estava fazendo e as últimas 2–3 ações. Com o
`jogar-log`, copie as linhas vermelhas. Pelo editor, olhe o painel **Debugger**. F3
deve destravar; diga se não destravou.

**Como anotar:** um item por coisa, com o dia e o lugar. Ex.: *"Dia 3, mesa: a
transcrição some atrás do estojo"*. Se for gosto ("está escuro demais"), diga também
o que esperava.

---

## 0. Prioridade máxima: o que mudou desde o playtest 9 (a Fase 3j)
- [ ] **Os sons** do café (a tampa, o jorro, o gole, a xícara pousada), do uísque (a
      rolha, o fio no copo) e da carta descendo a calha.
- [ ] **O sonho do disco:** a boca da caverna (a rocha em arco, a fresta negra, o
      matacão) e, entre as árvores, a silhueta de pé de uma delas, olhando (aparece
      quando você não está olhando para lá).
- [ ] **Os livros:** os títulos dourados nas capas; "Ver os livros" e "Ler o livro
      aberto" (as notas do Necronomicon no chão do Dia 6).
- [ ] **A luz sobre o mapa** à noite.
- [ ] **A mesa:** a carta que acabou de chegar no meio, as outras perto, as dos dias
      anteriores na pilha da ponta esquerda.
- [ ] **A passagem do tempo:** ele lendo os livros da biblioteca à mesa — o livro fecha
      à noite (foi para casa) e abre de manhã. E a noite em claro: "Reler as notas até o
      dia", o livro aberto a noite toda. Agora fica claro quando ele não dormiu?

## 1. O que mudou desde o playtest 8 (a Fase 3i)

### Os últimos dias (o maior pedido)
- [ ] **Dia 5:** depois de **comparar a assinatura** e renovar a oferta, o dia acaba:
      o diário (a entrada nova, de 22 de agosto), o fogo, a poltrona e **o sonho do
      A-K-E-L-Y na mesma noite** da farsa. Vem cedo o bastante agora?
- [ ] **Dia 6:** começa com a carta de **28 de agosto** no chão (a "saída digna") e a
      resposta animadora; depois a carta calma, o ânimo, segunda e terça.
- [ ] **A noite em claro** (lida a carta de terça): o **meio toque** do telefone
      ("Tirar o fone do gancho": só um zumbido), **a janela que se abre sozinha** sem
      você ver (o vento, a cortina) — "Fechar a janela" —, a criatura no céu se você
      olhar, e **"Sentar e esperar o dia"**: a aurora, a carta de quarta pela fresta.
      Assusta o suficiente? Longa ou curta demais? Ficou claro o que fazer?
- [ ] **As passadas de dia:** metade do tempo e três jeitos — **dias de chuva** (Dia
      5), **de dia em dia** e **uma noite só** (a carta de terça). Ainda cansa?

### Os sons (gravações reais, CC0)
- [ ] **O menu:** a folha grossa virando, a capa de couro rangendo, o baque na mesa,
      o fósforo das velas, o risco da pena ao passar pelas entradas.
- [ ] **No jogo:** os passos no assoalho, as portas, a gaveta, a lareira, a chuva na
      janela, a noite (grilos e vento), o relógio, a campainha do telefone, o papel,
      a carta pela fresta, o selo, a pena. Algum ficou alto, baixo ou estranho?
      (Ainda sintetizados: o disco, o zumbido, as vozes, o sonho, a tarde com
      pássaros, a manivela, a linha, a calha e o café.)

### Feito enquanto você não jogava (as Fases 4 a 6)
- [ ] **O mapa do condado** (parede oeste, acima do armário): lida uma carta que cita
      lugares, "Marcar no mapa" — os alfinetes, o fio vermelho, os nomes à mão. Examine
      e aproxime (roda): lê-se? O fio ajuda a ver a história no mapa?
- [ ] **A sala acumula** (dia a dia): os livros de folclore no armário e no chão, as
      xícaras usadas, a planta do peitoril que amarela e morre, a cortina meio fechada
      no Dia 6, as bolas de papel no cesto (amasse uma carta com Esc). Nota-se sem
      ninguém dizer? Algo atrapalha o caminho?
- [ ] **As estranhezas** (só com a exposição alta: examine os detalhes das fotos,
      ouça o disco de novo): no Dia 4, o cilindro fora da máquina e o relógio noutra
      hora; no Dia 5, depois do bilhete, uma foto virada para baixo. Percebeu? Ficou
      sutil demais, ou de menos?

### O resto da lista do playtest 8
- [ ] **O nome:** *Yuggoth*, no menu (em gótica rubra) e no .exe.
- [ ] **Espaço pula as falas** (o E só interage). Y no controle.
- [ ] **Os diplomas** na parede leste e **os avisos do mural** do corredor:
      "Examinar"/"Ler o aviso", e de perto (roda do mouse) lê-se o inglês; a tradução
      vem embaixo.
- [ ] **O estojo do cilindro** (Dia 3): tampa, cintas, a etiqueta *Dictaphone*, a
      letra de Akeley na tampa.
- [ ] **A pedra de Round Hill** (noite 4): a estela de faces planas, o alto partido.
- [ ] **Boston:** a escada de verdade; descer até o patamar volta a Arkham.
- [ ] **O mi-go do sonho do disco:** agora só uma silhueta no alto da encosta, na névoa.
- [ ] **Nenhum mi-go em pleno sol** nas passadas de dia.

## 2. Roteiro, do começo ao fim

### Menu
- [ ] Mouse: cada entrada acende sob o cursor? O clique responde no lugar certo?
- [ ] Opções: volumes, sensibilidade, inverter Y, tela cheia, campo de visão, tremor
      e ondulação — gravam e voltam?
- [ ] Teclado/controle: setas, Enter, Esc (testado automaticamente, mas confira a sensação).

### Prólogo (1930)
- [ ] O cartão inicial, sentado à mesa, a chuva; levantar ao tentar andar.
- [ ] A folha do relato, depois a caixa das cartas; a sala virando o escritório de 1928.

### Dia 1 — a primeira carta (maio)
- [ ] De manhã: o pé da escada, subir, "Abrir a porta", o correio no chão.
- [ ] Pegar, pôr na mesa, abrir com a espátula; a carta saindo do envelope.
- [ ] Os recortes no quadro; o rascunho.
- [ ] Escrever a Akeley: as três aberturas, amassar (Esc), a selagem 3D na mesa.
- [ ] A porta em duas ações: abrir, pôr a carta na calha, voltar (a porta fecha sozinha).
- [ ] O diário (entrada do dia 1); "Ir para casa" pelo corredor e escada.
- [ ] Só o Dia 1 tem pássaros.

### Dia 2 — as fotografias
- [ ] O envelope gordo; as nove fotos saindo uma a uma; os detalhes escondidos (lupa).
- [ ] O debate: o rascunho, a carta do leitor, "Deixar sem resposta" (ver §3).
- [ ] O diário; a noite 2 (a sala estilhaçada, as pegadas) e o acordar debruçado.

### Dia 3 — o disco
- [ ] O pacote abrindo (abas), tirar o bilhete, a transcrição, o estojo.
- [ ] O fonógrafo junto à estante: pôr o cilindro, tocar, as legendas, o zumbido que fica.
- [ ] "Ouvir o disco outra vez" → a noite 3 no bosque (os vultos, a lanterna, as ilhas).

### Dia 4 — a pedra que não chega
- [ ] O telegrama, a carta de julho, a foto do exército.
- [ ] As ligações (agência, Boston, telegrama noturno), o lapso pela janela até sexta.
- [ ] O relato de Keene → **Boston**: bater, a fresta, a conversa com opções, a sala amolecendo na pergunta da voz.
- [ ] A volta: o escritório já de noite, as cartas da noite; a noite 4 (a pedra).

### Dia 5 — o telegrama "AKELY" (15–22 de agosto)
- [ ] O maço amarrado; desamarrar; as cartas que cruzam o correio (oferta, renovação).
- [ ] O bilhete e comparar a assinatura; o mi-go rente à janela (de relance).
- [ ] O uísque escondido na gaveta (Lei Seca); a lareira; a noite 5 (o telefone do sonho).
- [ ] Sem acender a lareira: a fala lembra que falta o fogo.

### Dia 6 — de 28 de agosto às três últimas cartas
- [ ] Cada carta lida traz a seguinte (os saltos no tempo); a criatura no céu.
- [ ] A última carta → a tinta enchendo a tela, o céu de Vermont, o cartão do fim, o menu.

---

## 3. Decisões pendentes (respostas que só você pode dar)

**Do playtest 8**
- [ ] **"O modelo da janela do epílogo está bastante diferente."** Não achei a
      diferença: a janela do gabinete de 1930 (o Prólogo) é o mesmo modelo da de
      1928; mudam a vista (noite de chuva) e a falta das cortinas. Era o Prólogo? Ou
      o fim da demo (a tinta e o céu de Vermont)? O que estava diferente?

**Textos esperando aprovação**
- [ ] As **entradas do diário** dos Dias 1–5 (`narrative/documents/diario_dia_N`; a 3 e a 5 mudaram na Fase 3d).
- [ ] As falas **`sono_disco`** (noite 3) e **`sono_fogo`** (noite 5), incluindo a
      variante nova de quando a lareira está apagada: *"…A sala esfriara; faltava
      acender a lareira e ficar diante do fogo, com o copo."*
- [ ] **"Deixar sem resposta"** (Dia 2) confundiu no playtest 2. Trocar por algo como
      *"Encerrar o debate nos jornais"*?

**Visual e conteúdo**
- [ ] **O visual dos sonhos** (pendência antiga): o que ainda falta neles?
- [ ] **O bosque do disco** (os vultos, a criatura) está marcado 💭. Fica assim?

**Antigo, nunca reproduzido**
- [ ] O congelamento do playtest 4 "ao mexer num envelope" (Dia 5). Se voltar, olhe o Debugger.

---

## 4. Depois do playtest 9 (para não se perder)
**Decidido:** a demo vai ganhar o começo do Interlúdio (como Akeley: o entardecer, a
preparação e a noite do telhado) — `docs/PLANO_FAZENDA.md`, com três perguntas para
você antes de começar (as mãos, os nomes dos cães, onde a demo corta).
Fase 4 — o mapa de Vermont · Fase 5 — a sala acumula · Fase 6 — estranhezas sutis ·
Fase 7 — fechamento e o resto do marco Demo (a acessibilidade e o export já estão
feitos; falta o playtest com 5+ pessoas, com o .exe exportado). Detalhes em
`docs/PLANO_ESCRITORIO.md`.
