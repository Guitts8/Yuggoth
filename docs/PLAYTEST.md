# Playtest — o que verificar

Lista de conferência do **playtest 12** (do Prólogo ao fim da demo — que agora vai
até a noite do telhado, na fazenda). Os testes
automáticos (`smoke_test`, `caminhos_test`, o macaco) garantem que **tudo se joga
até o fim sem travar**. Eles não julgam se está **bonito, claro, assustador ou fiel
ao livro**, e não usam o mouse no menu. Esta lista é para isso.

O que o playtest encontrar vira a **Fase 3m** em `docs/PLANO_ESCRITORIO.md` (e o que
for da fazenda, a fase seguinte de `docs/PLANO_FAZENDA.md`)
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
| **F2** | pula para o dia seguinte; na fazenda, pula a etapa em curso (a rotina, a preparação, a noite) |
| **F4** | direto ao Interlúdio, como Akeley (também do menu); na fazenda, volta ao escritório |
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

## 0. Prioridade máxima: o que mudou desde o playtest 11
**F4** leva direto à fazenda; **F2** lá pula a etapa em curso.

### A noite do telhado (nova: F7 e F8) — a carta de segunda, vivida
Depois da preparação (todos os lampiões, as venezianas, o rifle carregado, a lareira,
a porteira), a luz-guia aponta a poltrona junto ao fogo do escritório.
- [ ] **A espera:** "Sentar e esperar" — ele vai a pé e senta, o rifle no colo; o fogo
      e o lampião baixam, o relógio do consolo bate, as pálpebras pesam. Longa ou curta
      demais (uns 30 s)? Dá para sentir o cochilo? Os grilos param — percebe-se?
- [ ] **O telhado (só som e poeira):** o baque que o acorda (a poeira e a caliça caindo
      do forro), os cães correndo em volta da casa, as unhas correndo por cima do forro,
      a luta e o zumbido (o do disco), que sobe e se vai; o cheiro (a imagem turva).
      Os sons convencem vindo de cima? Assusta sem ser susto?
- [ ] **As balas:** um tiro no tabuado, a vidraça que estoura ao lado da poltrona (os
      cacos no chão; um passa rente ao rosto), a estante lascada. Ficou anunciado o
      bastante (não pode ser um jumpscare: os dois do jogo são do Ato III)?
- [ ] **Apagar a luz e atirar:** "Apagar o lampião" (o do escritório; o da sala, para
      atirar de lá) e "Atirar pela janela" em quatro janelas (o escritório a leste e ao
      sul, a sala de estar a leste e ao norte): a veneziana que abre, o cano que sobe
      sozinho, alto, o clarão que mostra o quintal por um instante, o coice, a alavanca,
      o cartucho no assoalho. No escuro, dá para achar as janelas (a luz-guia fica bem
      fraca)? O clarão mostra o bastante — as árvores, a cerca, os cães correndo?
- [ ] **O ganido no terceiro tiro** — o cão que fica caído. Lê-se, sem explicar?
- [ ] **O fim:** os latidos param um a um, o escuro, *"Isso pareceu encerrar a coisa"*,
      o cartão. É o ponto alto certo para cortar a demo?
- [ ] **As frases da carta:** cada uma aparece quando a coisa acontece (a seguinte
      espera a anterior sair da tela). O ritmo fica bom, ou as frases atrasam a ação?
- [ ] **As falas novas de Akeley** (compostas, a aprovar; parado uns 35 s): *"Agora,
      esperar. Junto ao fogo, com o rifle no colo."* · *"A luz. Com ela acesa, eles me
      veem e eu não os vejo."* · *"As janelas. Uma fresta na veneziana basta."*
- [ ] Falta (anotado): a tosse de Akeley no cheiro (não há gravação boa ainda).

### A fazenda reformada (o playtest 11) e a preparação (F6)
- [ ] **A luz-guia:** um brilho azul pálido sobre a próxima tarefa, que some quando você
      chega. Fraca o bastante? Ajuda?
- [ ] **Por dentro:** o papel de parede de cada cômodo, o assoalho largo, o lambri, os
      alizares, os móveis refeitos peça a peça (poltronas, estantes, a escrivaninha, as
      camas de ferro, a cozinha com o fogão). Algum cômodo ainda tosco?
- [ ] **Por fora:** as árvores (olmos, bordos, macieiras, cicutas), os lilases, o capim
      alto, o canil com a tela de arame, o galpão de lenha, o celeiro por dentro e a
      carroça, o moinho, as cercas, a estrada, a linha do telefone, o pântano.
- [ ] **A preparação (F6):** os quatro lampiões, as venezianas, o rifle (pegar no
      armário, carregar cartucho a cartucho), a lareira (Conan vem deitar), o telefone
      mudo, a porteira, a lua engolida pelas nuvens. O rifle diante dos olhos, o lampião
      torneado, o telefone de manivela — estão bons?

### O escritório (a Fase 3l)
- [ ] O mapa sem cintilar; a soleira da porta sem a faixa; o diário (a capa que cai com
      o próprio peso, as folhas que vergam, a escrita que continua na página certa); a
      segunda carta legível; a transcrição do disco; os grilos da noite 3 mais baixos; o
      mi-go de pé, recortado; as folhas da mesa em leque; o livro dos lapsos com as
      páginas impressas e outro volume a cada manhã; Boston saindo pela porta e pela
      escada; o cultista, o funcionário e os mi-go refeitos (`docs/PLANO_ESCRITORIO.md`,
      Fase 3l).

## Conferido no playtest 11 (a Fase 3k, para não se perder)
- [ ] **Dia 6, escrever a Akeley:** a pena sempre pega a carta do dia (as áreas já
      usadas tampavam). Alguma outra coisa no Dia 6 ainda não pega ou não avança?
- [ ] **O diário fechando:** a capa sobe e cai sobre o miolo, com um baque leve; sem o
      salto na parte de dentro da capa.
- [ ] **Selar a carta:** as folhas e o envelope que estavam no meio vão para o fundo da
      mesa e voltam depois; o envelope novo chega pela frente.
- [ ] **O café:** a xícara vazia antes de servir.
- [ ] **O sonho do disco:** o fonógrafo é a máquina da sala; o mi-go de pé, uma silhueta
      à esquerda da caverna, entre os troncos (olhe para trás e volte).
- [ ] **Boston:** sem "Voltar a Arkham" — descer a escada leva de volta.
- [ ] **Sentar à mesa** (os lapsos lendo, o diário, selar): ele vai até a cadeira a pé.
- [ ] **O correio depois dos lapsos:** batem à porta, os passos se afastam e a sombra
      passa na fresta. Fica claro que chegou carta? (A fala da primeira vez está
      aprovada.)

## Conferido no playtest 10 (a Fase 3j, para não se perder)
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

## 0b. Novo: a fazenda de Akeley (F1 a planta, F2 o entardecer)
A planta da fazenda (`docs/PLANO_FAZENDA.md`), ainda sem os cães nem os beats do
Interlúdio. **O fim do Dia 6 mudou:** postada a última carta, a tinta não vai mais
para o cartão do fim — ela se desfaz no céu do entardecer, e você está no quintal
como Akeley, com o balde de ração; uns 45 segundos depois vem o cartão do fim (até
os beats existirem). No build de teste, **F4** vai direto ao Interlúdio como Akeley
(de qualquer lugar, também do menu; `comandos.ps1 jogar-fazenda` já abre o jogo lá);
**Shift+F4** leva ao quintal só para andar; na fazenda, F4 volta ao escritório.
- [ ] **A passagem (refeita na F3, pedido do playtest 10):** a tinta seca em céu (sem
      os morros desenhados), a data escrita na letra de Akeley, e a câmera que desce do
      alto do vale até os olhos dele, diante do canil (dá para olhar em volta com o
      mouse durante a descida). Percebe-se que agora você é outra pessoa? Longa ou
      curta demais? O balde diante dos olhos lê como um balde (sem mãos)?
- [ ] **Os cães (F4):** os doze no cercado; com o balde, juntam-se na tela do seu lado,
      olham, sentam e latem pedindo; Brutus te segue (anda pela fazenda e veja); Hércules
      late para a mata; Rambo fica olhando a mata, rosnando baixo. Leem como
      pastores-alemães (as proporções, a sela preta, as orelhas, a cauda)? Os latidos
      soam bem?
- [ ] **A rotina do entardecer (F5):** pôr a ração na gamela (os cães vêm comer lado a
      lado), encher o balde na bomba do poço e o bebedouro, a lenha do galpão até a
      lareira do escritório, fechar o portão do celeiro, a caixa de correio (vazia); e,
      feitas a lenha e o celeiro, os pássaros param e Yautja foge para a mata — chame
      por ele. Dá para saber o que fazer sem se perder? As falas curtas de Akeley
      (parado uns 35 s, ele lembra o que falta) ajudam ou atrapalham? Os sons (a ração,
      a bomba, a lenha, o portão)? **F2 na fazenda pula a rotina.**
- [ ] **As falas novas de Akeley** (compostas, a aprovar): *"Primeiro os cães. Estão
      com fome."* · *"Falta a água deles, da bomba do poço."* · *"A lenha para a noite,
      antes que escureça."* · *"A lenha vai para a lareira do escritório."* · *"O
      portão do celeiro ainda está aberto."* · *"Nada na caixa. É domingo."* · *"Os
      pássaros se calaram todos ao mesmo tempo, e Yautja disparou latindo para a
      mata."* · *"— Yautja! Yautja!"* · *"Não voltou."*
- [ ] **O corpo de Akeley:** mais lento, ofegante (a câmera respira); sem dossiê (Tab);
      a fala dele na letra das cartas. Incomoda, ou ajuda a sentir o corpo velho?
- [ ] **O entardecer** (uns 3 minutos): o sol baixo e as sombras compridas, a névoa
      dourada na montanha, o vale afogado; e o crepúsculo roxo no fim. Escuro demais,
      claro demais, rápido demais?
- [ ] **A escala:** a casa (dois andares e meio, o tabuado branco, as venezianas
      verdes), o gramado até a estrada com a borda de pedras caiadas, o caminho até a
      porta georgiana, a caixa de correio com o nome. Parece a casa da fotografia do
      Dia 2?
- [ ] **Por dentro:** o vestíbulo e a escada, o escritório à esquerda (a poltrona no
      canto escuro), a sala de jantar, o puxado da cozinha; em cima, o quarto de
      hóspedes sobre o escritório e o banheiro no alto da escada. Algo apertado, largo
      demais, ou faltando?
- [ ] **Atrás e à direita:** o galpão de lenha, a arcada, o celeiro, o moinho, o canil
      com os nomes dos doze cães nas plaquinhas, o abrigo do Ford; o pântano e a
      encosta da Dark Mountain.

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
preparação e a noite do telhado) — `docs/PLANO_FAZENDA.md`. As três perguntas foram
respondidas (sem mãos; Brutus, Conan, Hércules, Rambo e mais oito; corta no escuro
depois dos tiros), e a F1 (a planta) está feita — ver a seção 0b.
Fase 4 — o mapa de Vermont · Fase 5 — a sala acumula · Fase 6 — estranhezas sutis ·
Fase 7 — fechamento e o resto do marco Demo (a acessibilidade e o export já estão
feitos; falta o playtest com 5+ pessoas, com o .exe exportado). Detalhes em
`docs/PLANO_ESCRITORIO.md`.
