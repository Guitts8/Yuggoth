# Sequência do jogo

O jogo do começo ao fim, na ordem em que o jogador vive. O que já está
**jogável** aparece em detalhe: o que há na sala, o que fazer, o que é dito e o
que muda no estado. O que ainda está **planejado** aparece resumido, conforme o
GDD v0.4.

- Design e regras: `docs/GDD.md` · Livro, situação por situação: `docs/FIDELIDADE.md` · Arte a modelar: `docs/ARTE.md`
- **Manter este arquivo atualizado a cada dia ou feature concluída.**

Legenda: ✅ jogável (arte e som provisórios) · ⏳ planejado

| # | Parte | Data na história | Estado | Livro |
|---|---|---|---|---|
| — | Menu principal | — | ✅ | — |
| 0 | Prólogo — "O Relato" | Arkham, 1930 | ✅ | cap. I (abertura) |
| 1 | Dia 1 — A primeira carta | 5–9 de maio de 1928 | ✅ | cap. I–II |
| 2 | Dia 2 — As fotografias | 22–28 de maio | ✅ | cap. II |
| 3 | Dia 3 — O disco | fim de junho – 3 de julho | ✅ | cap. III |
| 4 | Dia 4 — A pedra que não chega | 18–21 de julho | ✅ | cap. III |
| 5 | Dia 5 — O telegrama "AKELY" | 15–29 de agosto | ✅ | cap. IV |
| 6 | Dia 6 — As três últimas cartas | 5–7 de setembro | ⏳ | cap. IV |
| — | Interlúdio — "O Cerco" (como Akeley) | 4–7 de setembro | ⏳ | cap. IV (as cartas, vividas) |
| 7 | Dia 7 — A carta datilografada | 8–10 de setembro | ⏳ | cap. V |
| — | Moldura I | 1930 | ⏳ | — |
| — | Ato II — A Viagem | 12 de setembro | ⏳ | cap. VI |
| — | Moldura II | 1930 | ⏳ | — |
| — | Ato III — A Casa | 12–13 de setembro | ⏳ | cap. VII–VIII |
| — | Epílogo e finais | 1930 | ⏳ | cap. VIII (desfecho) |

A **demo** vai do Prólogo ao Dia 6 e termina ao ler a última carta manuscrita
(a entrada do Interlúdio).

---

## Menu principal ✅
Título **"Os que Sussurram"**, subtítulo *Vermont, 1928*. Continuar (só se há
save), Novo jogo (pede confirmação se há save), Opções (volumes, sensibilidade,
inverter eixo, tela cheia), Sair. **Esc** durante o jogo abre a pausa.

---

## 0. Prólogo — "O Relato" ✅
**Onde/quando:** o gabinete de Wilmarth em casa (Rua Saltonstall, 118), Arkham,
1930. Noite de chuva. A lamparina da mesa é a única luz quente.

1. **Tela preta**, som de pena, cartão com a primeira frase do livro:
   *"Tenham bem em mente que, no fim, eu não vi nenhum horror visual de fato."*
2. O jogador está **sentado** à escrivaninha, de frente para a janela com chuva.
   Tentar andar o faz levantar.
3. **Na sala:**
   - mesa: a **caixa das cartas de Akeley**, amarrada com barbante (examinável), a
     **folha do relato** (o começo do livro, 2 páginas; lida, não vai para o dossiê),
     tinteiro, pena, lamparina;
   - **lareira** apagada — *"As cinzas estão frias. Não acendo a lareira desde que voltei."*;
   - **janela** — *"Chove sobre Arkham desde o fim da tarde."*;
   - uma poltrona coberta por lençol, a estante, o relógio, a porta.
4. Depois de alguns segundos, o narrador: *"As cartas dele continuam sobre a mesa.
   Não desfaço o nó desde setembro."*
5. **Examinar a caixa e devolvê-la** → a sala se reorganiza: o **sonho** sobe (a
   estética crua do PS1), as luzes morrem, tela preta, cartão *"Maio de 1928."*, e a
   mesma sala volta como **o escritório da Miskatonic**, à luz da tarde.

**Estado:** `prologo_concluido`, `dia = 1`. **Checkpoint.**

---

## 1. Dia 1 — A primeira carta ✅ (5–9 de maio)
**Clima:** tarde ensolarada, pássaros, o relógio tiquetaqueando.
**Ao começar:** *"A carta chegou com o correio do meio-dia. Selo de Townshend, Vermont."*

**Na sala:**
- **Envelope de Townshend** (examinável): um selo de 2 centavos, carimbo
  *TOWNSHEND — MAY 5 1928*, endereçado a *Albert N. Wilmarth, Esq., 118 Saltonstall St.*
- **A carta de Akeley de 5 de maio, na íntegra** (cerca de 18 folhas): o forasteiro
  que discorda dele, as pegadas, a pedra negra de Round Hill, o fonógrafo com
  cilindro de cera, o espião que se matou, Brown, os cães policiais, o filho em
  San Diego, o *Necronomicon* guardado a chave, o P.S. das fotografias. → dossiê.
- **Rascunho de Wilmarth ao *Arkham Advertiser*** — inacabado, com palavras riscadas
  (Charles Fort, Arthur Machen). → dossiê, fica na mesa.
- **Quadro de cortiça**, três recortes legíveis (→ dossiê, ficam no quadro):
  *Brattleboro Reformer* (coisas vistas nos rios cheios), *Rutland Herald*
  (trechos do debate dos dois lados), *Reformer* de 23 de abril (o resumo de
  Wilmarth reproduzido, com o aplauso do "Pendrifter").

**O que fazer:** ler a carta → aparece **"Escrever a Akeley"** junto ao tinteiro →
escolher como começar:
| Tom | Abertura |
|---|---|
| cético (−1) | "Pegadas na lama e vozes à noite admitem explicações mais simples." |
| cauteloso (0) — o do livro | "Não o tomo por louco, mas preciso ver antes de crer." |
| crédulo (+1) | "Acredito no senhor. Conte-me tudo." |

A carta se escreve sozinha (som de pena) e vai para o dossiê. Narrador: *"Selei o
envelope. Vai amanhã cedo, com o primeiro correio."*

**Fim do dia:** a **porta** ("Ir para casa"). Antes da resposta: *"Ainda devo uma
resposta ao Sr. Akeley."* Depois: tela preta, cartão *"Fim de maio."*, **checkpoint**.

---

## 2. Dia 2 — As fotografias ✅ (22–28 de maio)
**Clima:** entardecer alaranjado. **O relógio da parede parou** (e não volta a tocar).
**Ao começar:** *"A resposta dele veio quase na volta do correio — e trazia, como prometido, várias fotografias."*

**Na sala:**
- **Envelope gordo de Townshend** (examinável): dois selos, carimbo *MAY 22 1928*.
- **A segunda carta** — 11 folhas de **letra cerrada ilegível**; o livro não a
  transcreve. As notas de Wilmarth (outra tinta) dizem o que havia: as transcrições
  do que se ouvia na mata, as formas rosadas, a narrativa cósmica, a lista de nomes
  (Yuggoth, Cthulhu, Nyarlathotep...). Ao fechá-la: *"Minha cabeça girava; e onde
  antes eu tentara explicar as coisas, comecei a acreditar..."*
- **As nove fotografias** (ficam na mesa nos dias seguintes; examináveis; zoom = lupa):
  | Foto | Detalhe de perto |
  |---|---|
  | **A pegada** — *"A pior de todas"* (exposição sobe ao examinar) | as pinças serrilhadas, "horrivelmente parecida com a de um caranguejo" |
  | A caverna fechada por um matacão | com a lupa, a rede de rastros no chão |
  | O círculo de pedras | nem com a lupa há pegadas |
  | A pedra negra, com o busto de Milton | os hieróglifos que dão um choque |
  | Pântano, colina, pântano | — |
  | A marca perto da casa (muito borrada) | "diabolicamente" parecida com a outra |
  | A casa de Akeley | os cães e Akeley com a pera do disparador |
- **O debate:** o rascunho do Dia 1 e, agora, **três cartas de opositores** (carimbo
  de Arkham) e a carta datilografada de um leitor (Charles Fort).

**O que fazer:** ler a carta; olhar as fotos; **"Deixar sem resposta"** os opositores
(só depois de ler a 2ª carta) → rascunho e cartas somem, e o narrador: *"o meu
debate público sobre o horror de Vermont terminou para sempre."*; responder (28 de maio):
| Tom | Abertura |
|---|---|
| cético | "Uma fotografia verdadeira de uma marca na lama prova a marca, não o bicho." |
| cauteloso | "São fotografias de verdade. Comparemos as nossas notas." (o Mi-Go; silêncio, nem ao Prof. Dexter) |
| crédulo — o do livro | "Onde antes eu tentava explicar as coisas, agora começo a acreditar." |

**Fim do dia:** porta → *"Fim de junho."*

---

## 3. Dia 3 — O disco ✅ (fim de junho – 3 de julho)
**Clima:** noite. Abajur elétrico na mesa, lua na janela. Quase silêncio, vento fraco lá fora (nenhum pássaro — eles só cantam na tarde do Dia 1).
**Ao começar:** *"No fim de junho chegou o disco — despachado de Brattleboro, porque Akeley não confiava no ramal ao norte de lá."*

**Na sala:**
- **Pacote do American Railway Express**, aberto (etiqueta de Brattleboro a Arkham),
  com o **estojo do cilindro de cera** (examinável: *"1º de maio de 1915"*).
- **Bilhete de Akeley:** o medo das estradas, a Califórnia, e **Walter Brown** —
  suas pegadas viradas para a marca de garra.
- **A transcrição de Akeley, na íntegra** (onde e quando gravou; o texto completo).
  Ao fechá-la: *"A máquina da administração esperava no canto."*
- No canto, o **caixote da administração da Miskatonic** com as peças, e sobre o
  armário a **máquina emprestada** (fonógrafo de cilindro), desmontada.

**O que fazer:**
1. **Montar** a corneta, a manivela e a agulha (cada uma tirada do caixote).
2. **Pôr o cilindro de cera** na máquina (sai do estojo).
3. **"Dar corda e baixar a agulha"** → o disco toca (~1 min), com **legendas**:
   ruídos; a voz humana culta ("...é o Senhor dos Bosques..." — "Iä!
   Shub-Niggurath!"); a **imitação zumbida** da fala; Azathoth, Yuggoth,
   Nyarlathotep, "a máscara de cera e o manto que esconde"; **a fala cortada pelo
   fim do disco**. Na voz zumbida, a luz pulsa e os papéis tremem.
   **"Levantar a agulha"** para a qualquer momento.
4. Na primeira vez: exposição sobe bastante e **o zumbido fica para sempre** no
   ambiente. Narrador: *"Ainda hoje, a todo momento, ouço aquele zumbido fraco e
   diabólico..."*
5. **"Tocar de novo"**: a gravação **dura mais** — no fim, a voz zumbida diz
   *"...Wil... marth..."* (não está na transcrição).
6. Responder (3 de julho), só depois de ouvir:
   | Tom | Abertura |
   |---|---|
   | cético | "Um ditafone grava o que um homem quiser pôr diante dele." |
   | cauteloso | "A segunda voz, não sei descrever. Comparemos as notas." |
   | crédulo — o do livro | "Encontramos uma pista de alianças antigas entre eles e certos homens." |

**Fim do dia:** porta → *"18 de julho de 1928."* A máquina fica montada, com o
cilindro, nos dias seguintes.

---

## 4. Dia 4 — A pedra que não chega ✅ (18–21 de julho)
**Clima:** dia claro de julho.
**Ao começar:** *"Na manhã de quarta-feira, 18 de julho, chegou um telegrama de Bellows Falls."*

**Na sala:**
- **Telegrama (Western Union):** a pedra vai no B. & M., trem nº 5508, sai de
  Bellows Falls às 12h15, chega à North Station às 16h12.
- **Carta de Akeley de julho** e o **envelope de Brattleboro** (carimbo *JUL 12*):
  outra carta extraviada; escreva para a Posta-Restante de Brattleboro; o homem
  suspeito na agência do expresso; a rota da pedra por Keene.
- **A foto do "exército" de pegadas** diante de uma linha de pegadas de cães (fica
  com as outras nos dias seguintes).
- **O telefone de parede**, ao lado da escrivaninha.

**O que fazer:**
1. Ler o telegrama → *"...Fiquei a quinta-feira inteira de manhã à espera dela —
   mas o meio-dia chegou e passou."* O telefone passa a ter uma ligação.
2. **"Telefonar à agência do expresso"** → *"Nenhuma remessa para o senhor, professor."*
3. **"Pedir um interurbano para Boston"** → o 5508 chegou só 35 minutos atrasado,
   sem caixa nenhuma; vão investigar. *"E mal me surpreendi..."*
4. **"Ditar um telegrama noturno a Akeley"** → tela preta: *"Sexta-feira, 20 de julho. À tarde."*
5. **O telefone toca** → **"Atender o telefone"**: o funcionário do 5508 lembra de
   uma discussão em **Keene** com um homem magro, ruivo, de jeito de roceiro, que
   deu o nome de **Stanley Adams** e tinha uma voz tão grossa e zumbida que o
   deixava tonto e sonolento.
6. Cartão: a ida a Boston para falar com o funcionário. Narrador: a noite em claro
   escrevendo cartas.
7. **As cartas da noite** (resposta, 21 de julho):
   | Tom | Abertura |
   |---|---|
   | cético | "Caixas pesadas se extraviam todos os dias." |
   | cauteloso — o do livro | "Esse homem de voz estranha há de ter um lugar central neste negócio." |
   | crédulo | "A pedra não chegou, e o senhor já sabe por quê." |

   Depois: *"Devo admitir, porém, que todas as minhas investigações não deram em nada."*

**Fim do dia:** porta → *"Agosto de 1928."*

---

## 5. Dia 5 — O telegrama "AKELY" ✅ (15–29 de agosto)
**Clima:** noite de chuva. Abajur na mesa, chuva na janela (som de chuva no lugar
da tarde). As cartas de Akeley agora vêm em **letra trêmula** (o texto treme no
leitor, mais a cada carta).
**Ao começar:** *"As cartas de Akeley vinham agora numa letra que se tornara
lamentavelmente trêmula. No dia 15 de agosto recebi uma carta frenética, que me
perturbou muito."*

As cartas cruzam o correio: cada carta selada **salta no tempo** (tela preta e
cartão), e o que chega depois já está na mesa quando a luz volta.

**Na sala (15 de agosto):**
- **Carta do começo de agosto**: a pedra "não está mais nesta terra"; o tronco
  atravessado na estrada (dia 2), o tiro de raspão e as presenças na mata (5 e 6);
  nunca sai sem dois cães.
- **Carta de 15 de agosto**, escrita no correio de Brattleboro, e o **envelope**
  (carimbo *AUG 14*): a noite de 12 para 13, **3 dos 12 cães** mortos a tiro, as
  pegadas de **Brown** entre as garras, o cabo telefônico cortado ao norte de
  Newfane, quatro cães novos e munição. Ao fechá-la: *"Minha atitude diante do caso
  passava depressa do científico para um alarme pessoal..."*

**O que fazer:**
1. **"Escrever a Akeley"** — a oferta (sem tom a escolher): *"Procure ajuda, e
   chame a lei em seu socorro."*; ir a Vermont, falar com as autoridades. Narrador:
   *"A coisa se estendia assim. Haveria de me sugar para dentro dela, e me engolir?"*
   Cartão: *"Em resposta, porém, recebi apenas um telegrama de Bellows Falls."*
2. **O telegrama** (Western Union, 17 de agosto): *"COMPREENDO SUA POSIÇÃO MAS NADA
   POSSO FAZER. NÃO TOME NENHUMA PROVIDÊNCIA PORQUE ISSO SÓ PODERIA PREJUDICAR A
   AMBOS. AGUARDE EXPLICAÇÃO."* — assinado **HENRY AKELY** (o de julho dizia AKELEY).
3. **"Telegrafar a resposta a Akeley"** pelo telefone de parede → cartão: *"Mas o
   caso se aprofundava sem parar."*
4. **O bilhete de Akeley** (22 de agosto, a letra mais trêmula de todas): ele
   **nunca mandou** o telegrama nem recebeu a carta; em Bellows Falls, quem o deixou
   foi um **estranho ruivo de voz grossa e zumbida**; o original a lápis, letra
   desconhecida, **A-K-E-L-Y**; mais cães mortos, tiros toda noite sem lua, as
   pegadas de Brown e de mais um ou dois homens calçados; talvez a Califórnia.
   Narrador: *"Certas conjecturas eram inevitáveis. O telegrama ainda estava sobre a mesa."*
5. **"Comparar a assinatura com as cartas"** (no telegrama): *"HENRY AKELY. Sem o
   segundo E..."* → **primeira alteração de texto**: relida a partir daí, a **carta
   de julho** descreve o homem da agência do expresso como *"magro, ruivo, com jeito
   de roceiro"* — o que antes não dizia. Nenhum aviso.
6. Depois do bilhete, quem olhar para a **janela** vê **um vulto passar** lá fora,
   uma vez, sem som. "Olhar" a janela: *"Só a chuva, escorrendo no vidro."*
7. **"Escrever a Akeley"** de novo — renovar a oferta (sem tom) → cartão: *"A
   resposta dele chegou a 28 de agosto."*
8. **Carta de 28 de agosto**: já não é tão contra o plano; quer pôr as coisas em
   ordem; *"quero uma saída digna, se puder."*
9. **A resposta do dia** (29 de agosto):
   | Tom | Abertura |
   |---|---|
   | cético | "Vá à polícia. Homens de carne e osso cortam fios e mandam telegramas." |
   | cauteloso — o do livro | "Uma saída digna é perfeitamente possível, e conte comigo para ela." |
   | crédulo | "Não espere pôr as coisas em ordem." |

   Depois: *"Preparei e pus no correio a resposta mais animadora que pude."* (varia com o tom)

**Fim do dia:** porta → *"Setembro de 1928."*

## 6. Dia 6 — As três últimas cartas ⏳ (5–7 de setembro)
Abre com o que faltou de agosto: Akeley responde com menos terrores (só a lua
cheia, acha ele, segura as criaturas; fala em se hospedar em Brattleboro quando a
lua minguar) e Wilmarth o anima de novo. Depois, as cartas de **segunda** (algo pousa no telhado, briga dos cães, gosma verde, 5
cães mortos, um por ele mesmo), **terça** ("falaram comigo"; "fique fora disso,
Wilmarth"; quebre o disco) e **quarta** (a coisa morta que evapora no galpão; o
filme que sai vazio; Brown sumiu; o filho George; gás e máscaras; o xerife).
Resposta: a carta registrada ("mude-se para Brattleboro"). Ao terminar a última
carta, a tinta se espalha e vira o céu de Vermont → **Interlúdio**. *(Fim da demo.)*

## Interlúdio — "O Cerco" ⏳ (como Akeley, 4–7 de setembro)
As noites das três cartas, vividas na fazenda (mesmo mapa do Ato III, habitado):
a rotina com os **doze cães** (quatro com nome), a noite do telhado (atirar das
janelas no escuro), a manhã do sangue e da gosma verde, "falaram comigo", a coisa
morta no galpão e a foto que sai vazia, a carta verdadeira escondida (relógio,
bota ou tábua), e os **sinais**: batidas, a voz de Noyes, a lamparina que se apaga.

## 7. Dia 7 — A carta datilografada ⏳ (8–10 de setembro)
A carta calma, datilografada numa Corona nova, convidando — comparar estilo,
vocabulário e grafia com as antigas. Noite em claro; os telegramas (*"COMBINAÇÃO
SATISFATÓRIA... NÃO ESQUEÇA DISCO CARTAS FOTOS"*). Arrumar a **valise: leva tudo**.

## Moldura I ⏳ (1930)
De volta ao gabinete: uma frase do relato riscada e reescrita em outra caligrafia.

## Ato II — A Viagem ⏳ (12 de setembro)
O trem (Waltham, Concord... Greenfield), o rio Connecticut, o condutor manda
**atrasar o relógio uma hora**; Brattleboro: **Noyes** no lugar de Akeley; a estrada
pelo West River, as pontes cobertas, Newfane; a casa, as **pegadas-garra frescas na
estrada**, nenhum cão, silêncio total.

## Moldura II ⏳ (1930)
*"A casa de Akeley ficava no fundo de um vale, com a Montanha Escura atrás."*

## Ato III — A Casa ⏳ (12–13 de setembro)
"Akeley" no escuro, de lenço amarelo, sussurrando; o lanche e o **café amargo**;
os cilindros, o **B-67** e a voz que revela Noyes no disco; a noite: o trinco da
porta, a conferência lá embaixo, o carro que parte, **Noyes roncando no sofá**, o
**cilindro com o nome de Akeley** na mesa; a poltrona: **o rosto e as mãos**; a fuga
no Ford.

## Epílogo e finais ⏳ (1930)
O xerife não acha nada; Brown desaparecido; **Plutão**. Finais: A Fuga (o do livro),
Yuggoth — O Despertar, Yuggoth — O Estudioso, Testemunha, Cinzas (GDD §7).

---

## Referência: estado narrativo usado até agora

| Chave | O que é |
|---|---|
| `prologo_concluido` | o Prólogo terminou |
| `dia` | 1–7 no escritório |
| `crenca` | soma dos tons das respostas (−4…+4) |
| `resposta_dia_N` | tom da resposta do dia N: −1, 0 ou 1 |
| `escreveu_resposta_dia_N` | resposta do dia escrita (libera a porta) |
| `leu_<documento>` | documento lido (ex.: `leu_carta_akeley_1`) |
| `debate_encerrado` | Dia 2: deixou os opositores sem resposta |
| `viu_*` | detalhes vistos nas fotos (`viu_garra_foto`, `viu_rastros_caverna`, `viu_circulo`, `viu_hieroglifos`, `viu_marca_casa`, `viu_akeley_foto`, `viu_foto_pegada`, `viu_foto_exercito`) |
| `fono_corneta`, `fono_manivela`, `fono_agulha`, `fono_cilindro` | montagem do fonógrafo |
| `tocou_disco`, `vezes_disco`, `ouviu_wilmarth_no_disco` | o disco |
| `ligou_<id>` | telefonemas (Dia 4: `agencia_arkham`, `boston`, `telegrama_noturno`, `relato_keene`; Dia 5: `resposta_telegrama`) |
| `escreveu_oferta_dia_5`, `escreveu_renovacao_dia_5` | Dia 5: as cartas sem tom (a oferta; a renovação) |
| `narrou_<cartão>` | cartão de salto no tempo já mostrado; no Dia 5 decide o que está na mesa (`cartao_telegrama_akely`, `cartao_aprofundava`, `cartao_28_agosto`) |
| `comparou_assinatura` | Dia 5: comparou o telegrama com as cartas (liga a 1ª alteração de texto) |
| `leu_carta_akeley_julho_ruivo` | releu a carta de julho alterada |
| `viu_sombra_janela` | Dia 5: o vulto passou pela janela |
| `exposicao` | 0–1; nunca aparece na tela |
| `sonho` | 0–1; visual onírico em sequências (Prólogo) |

**De onde vem a exposição até o Dia 5:** carta 1 (+0,05), carta 2 (+0,20),
foto da pegada (+0,05, e +0,05 nas pinças), rastros da caverna (+0,03),
hieróglifos (+0,05), marca perto da casa (+0,02), transcrição (+0,05), o disco
(+0,15 na primeira vez, +0,03 nas outras), carta de julho (+0,04), foto do
exército (+0,04); carta do começo de agosto (+0,02), carta de 15 de agosto
(+0,04), bilhete (+0,05), comparar a assinatura (+0,03), reler a carta de julho
alterada (+0,05), o vulto na janela (+0,03).
