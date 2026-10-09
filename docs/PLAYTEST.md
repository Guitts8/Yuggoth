# Playtest — o que verificar

Lista de conferência do **playtest 8** (do Prólogo ao fim da demo). Os testes
automáticos (`smoke_test`, `caminhos_test`, o macaco) garantem que **tudo se joga
até o fim sem travar**. Eles não julgam se está **bonito, claro, assustador ou fiel
ao livro**, e não usam o mouse no menu. Esta lista é para isso.

O que o playtest encontrar vira a **Fase 3i** em `docs/PLANO_ESCRITORIO.md`
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

## 1. Prioridade: o que mudou desde o playtest 7

### O menu refeito (sessão do menu, com as imagens de referência)
- [ ] **A abertura** ao iniciar o jogo: o escuro, as velas acendendo, a câmera se
      afastando da capa, a capa caindo (o baque, a poeira), a tinta brotando nas
      páginas. Longa demais? Uma tecla pula — pula bem?
- [ ] **O livro em si:** a moldura de ferro rebitada, o papel queimado com as
      manchas cor de ferrugem, a moldura impressa, a gravura da pedra negra, o
      título em fraktur. Está à altura da referência? Algo a mais (ou a menos)?
- [ ] **O grão:** o livro agora tem o pontilhado e a resolução do jogo. Ficou bom
      ou o texto ficou difícil de ler?
- [ ] **As entradas:** as pontas rubras deslizando, o pulso, o mouse que escolhe, o
      cursor de pena, a dica embaixo.
- [ ] **Continuar / Novo jogo:** a tinta tomando a tela antes de o jogo começar.
- [ ] **Opções:** a seção nova de **acessibilidade** — campo de visão, tremor das
      formas, ondulação das texturas. Funcionam como se espera no jogo?
- [ ] **A pausa** chegando deslizando; a folha virando para as Opções (com sombra).
- [ ] **O jogo exportado:** `comandos.ps1 exportar` e `jogar-exportado` — o mesmo
      jogo, sem os atalhos de teste (F, F2, F3, C). Algo diferente do editor?

### Da Fase 3h (os pedidos do playtest 7)
- [ ] **O corredor e a escada:** as portas 312/308 e a calha sem lambri na frente;
      a escada sem vãos (o "limbo" debaixo dos degraus).
- [ ] **O diário fechando** sem o salto das páginas; **escrevendo**, a vista mais
      solta (os olhos na linha, só um pouco na pena).
- [ ] **O sonho do disco (noite 3)** partido em ilhas que boiam; os das noites 2, 4 e 5.
- [ ] **E para pular** falas (narrador, telefone, conversa).
- [ ] **Acender a lareira** (Dias 5 e 6): ajoelhar, o fósforo, o fogo crescendo.

### Das sessões de tester (o jogador nota sem saber)
- [ ] **O armário do canto sudoeste** (junto à porta) agora tem portas e puxadores;
      à noite, não brilha mais de laranja com a luz da fresta. Ficou escuro demais?
- [ ] **O cesto de papéis** (ao lado da mesa) agora é aberto (tinha tampa).
- [ ] **Dia 2, à direita do mata-borrão:** a carta do leitor e os três envelopes dos
      opositores não atravessam mais a base da lâmpada. Ainda se lê o que é cada coisa?
- [ ] **Boston, virado para a escada:** o corrimão agora aparece numa luz fraca de baixo.
- [ ] **Sair para o menu e continuar** no meio de qualquer coisa (o disco tocando, o
      telefone, um sonho): a legenda não fica na tela; nada fica "lembrado" errado
      (luz, cor do céu, o sonho). As fases agora ficam na memória entre trocas: se
      algo voltar diferente do que era depois do menu ou de Boston, anote.
- [ ] **A volta de Boston** ("Voltar a Arkham"): sem congelar. Era intermitente; se
      congelar, anote.
- [ ] **Ler o diário durante a ligação de Keene** (Dia 4): ao ir a Boston, o controle
      continua normal (antes, o jogo travava para sempre).

---

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

### Dia 5 — o telegrama "AKELY"
- [ ] O maço amarrado; desamarrar; as cartas que cruzam o correio (oferta, renovação).
- [ ] O bilhete e comparar a assinatura; o mi-go rente à janela (de relance).
- [ ] O uísque escondido na gaveta (Lei Seca); a lareira; a noite 5 (o telefone do sonho).
- [ ] Sem acender a lareira: a fala lembra que falta o fogo.

### Dia 6 — as três últimas cartas
- [ ] Cada carta lida traz a seguinte (os saltos no tempo); a criatura no céu.
- [ ] A última carta → a tinta enchendo a tela, o céu de Vermont, o cartão do fim, o menu.

---

## 3. Decisões pendentes (respostas que só você pode dar)

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

## 4. Depois do playtest 8 (para não se perder)
Fase 4 — o mapa de Vermont · Fase 5 — a sala acumula · Fase 6 — estranhezas sutis ·
Fase 7 — fechamento e o resto do marco Demo (a acessibilidade e o export já estão
feitos; falta o playtest com 5+ pessoas, com o .exe exportado). Detalhes em
`docs/PLANO_ESCRITORIO.md`.
