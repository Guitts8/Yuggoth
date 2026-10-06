# Arte — o que modelar

Lista viva do que vale a pena ser modelado à mão. Tudo que está no jogo hoje é
**provisório**, gerado por código (`yuggoth/tools/gerar_assets.gd` para texturas e
sons, `yuggoth/tools/gerar_escritorio.gd` para a sala). O provisório funciona e
pode ficar até o fim se for bom o bastante; esta lista é sobre o que **ganha
muito** sendo feito à mão.

Prioridade: **A** = aparece de perto e conta a história; **B** = presença
constante na sala; **C** = melhora, mas a caixa provisória aguenta.

---

## Regras técnicas (PS1, GDD §8.1)

- **Formato:** glTF 2.0 (`.glb`) exportado do Blender, em `yuggoth/art/models/`.
- **Escala:** 1 unidade = 1 metro. Pivô na base do objeto, centrado (no chão
  para móveis, na base para objetos de mesa). Frente do objeto virada para **-Z**.
- **Polígonos:** objetos de mão 100–400 tris; móveis 200–800; nada acima de
  ~1.500. Faces grandes **subdivididas a cada ~0,5 m**: o shader afim torce
  polígonos grandes.
- **Facetado:** a luz é por pixel e cada polígono usa a normal da própria face
  (`psx_lit`, `facetado`) — o low-poly aparece na luz, como na referência. Não
  adianta suavizar normais; a silhueta e as facetas são o desenho.
- **Texturas:** 64×64 ou 128×128 px, PNG, sem filtro (nearest), paleta
  dessaturada (ocre, verde-musgo, marrom de madeira, azul de noite). Atlas por
  objeto é bem-vindo. Sem normal map, sem PBR: o material é o `psx_lit`.
- **Detalhe pintado na textura**, não em geometria (puxadores, entalhes, letras).
- **Nomes** em PT-BR, como no resto do projeto (`caixa_cartas.glb`, `fonografo.glb`).
- Objetos **examináveis** (girados na mão pelo jogador) têm todos os lados
  acabados, inclusive o fundo.

---

## Escritório / gabinete (marco E)

### A — conta a história, visto de perto

| Objeto | Onde | Notas |
|---|---|---|
| **Caixa das cartas de Akeley** | mesa, Prólogo | Examinável. Caixa de madeira ou papelão gasto, amarrada com barbante. Abre as memórias: é o primeiro objeto que o jogador gira na mão. |
| **Fonógrafo** | armário, canto sudoeste | Set piece do Dia 3. Corneta de latão, prato, braço com agulha, **manivela removível** e **agulha separada** (o quebra-cabeça é achá-las). Prato e manivela giram: modelar como peças separadas. |
| **Disco de fonógrafo** | chega no Dia 3 | Examinável. Rótulo pintado à mão com a data de 1915. |
| **Fotografias de Akeley** | chegam no Dia 2 | Examináveis com lupa. Plano com espessura e borda de papel fotográfico; a imagem (pegadas, pedra negra) é textura — eu posso gerar uma versão borrada provisória. |
| **Mãos de Wilmarth** | primeira pessoa | GDD §3.2: "mãos visíveis ao segurar documentos". Segurando papel e segurando a lamparina. Low-poly, punho da camisa e paletó. Precisa de rig simples. |
| **Lamparina a querosene** | mesa (1928) e na mão (Ato III) | Tanque de latão, chaminé de vidro, botão da chama. É o objeto mais importante do jogo (GDD §8.1). |

### Correspondência e fotografias (prontas para receber modelo)
Envelopes e fotografias são **props com lógica separada do visual** (`yuggoth/props/`):
o modelo provisório é gerado por código, e basta pôr o seu `.glb` como filho
chamado **`Modelo`** para ele assumir — selos, carimbo, endereços (Label3D) e
os detalhes escondidos das fotos continuam funcionando por cima.

| Objeto | Medidas / orientação | Notas |
|---|---|---|
| **Envelope** (`Envelope`) | 19 × 11 cm, 4 mm (12 mm se `volumoso`); deitado, frente para +Y, topo do texto para −Z | Papel de 1928, aba no verso, cantos levemente gastos. Selos, carimbo e endereços **não** entram no modelo (são configurados por envelope: cidade, data, nº de selos, remetente). Uma versão "aberta" (aba rasgada) seria ótima. |
| **Selo de 2 centavos** | 2,2 × 2,75 cm | Hoje é textura gerada (`selo_2c.png`). Uma textura pintada à mão, de 64×80 px, com o carmim e o busto de perfil dos selos comuns de 1928, melhora muito o close. |
| **Carimbo do correio** | 7 × 3,5 cm | Círculo com dupla borda + linhas onduladas. Textura com alfa. |
| **Fotografia** (`Fotografia`) | Cartão 13 × 10 cm com borda branca; imagem 11,6 × 8,7 cm | O cartão pode ganhar cantos arredondados e um leve empenamento. As **imagens** (9, descritas no cap. II) são texturas — trocar `art/textures/foto_*.png` por versões melhores (128×96 ou 256×192, sépia) mantém tudo funcionando. |
| **Folha de carta** | 22 × 30 cm | Hoje é uma caixa com textura de papel pautado; a 2ª carta é um maço grosso. |

### B — presença constante

| Objeto | Notas |
|---|---|
| **Escrivaninha** | Com gavetas (peças separadas). Nenhum dia precisa abri-las: esconder itens saiu do GDD (§6.4). |
| **Cadeira da escrivaninha** | Madeira, encosto de ripas. O jogador começa sentado nela. |
| **Estante de livros** | Cheia: hoje cada livro é uma caixa (cor de vértice + `capa_livro.png`), numa malha só. Um modelo à mão pode manter isso ou trazer os livros como peças. |
| **Lâmpada de banqueiro** | Na mesa todos os dias; cúpula de vidro verde, base de latão, correntinha. É a luz-chave das noites: a cúpula precisa ser fechada em cima (a luz só desce). |
| **Arquivo de aço** | Quatro gavetas, verde-oliva, canto nordeste. A máquina de escrever fica guardada em cima (só decoração). |
| **Cabideiro** | Canto sudeste, com chapéu de feltro e sobretudo. O sobretudo provisório é um cilindro achatado: o que mais ganha com modelo. |
| **Lareira** | Tijolo, consolo de madeira, grelha de ferro. Funciona acesa e apagada. |
| **Poltrona** | Estofada, de leitura. Aparece também coberta por lençol (versão "drapeada" ajuda). |
| **Janela de guilhotina** | Caixilho de madeira com vidraças; a vista é um plano atrás. |
| **Relógio de parede** | Ponteiros e pêndulo como peças separadas (o relógio **para** no Dia 2). |
| **Porta** | Com almofadas, batente e maçaneta; não precisa abrir. |
| **Telefone de parede** | Caixa de madeira com duas campainhas de latão, bocal, fone no gancho e manivela (Dia 4). Fone e manivela como peças separadas. |

### C — a caixa provisória aguenta

Quadro de cortiça, armário do fonógrafo, tapete, tinteiro e pena, castiçais do
consolo, lambri (textura `lambri.png`), cortinas (faixas em zigue-zague), cesto de
papéis, espátula de cartas, mata-borrão, máquina de escrever. O **vulto da janela** (Dia 5) é um plano com textura
recortada e deve continuar vago: só melhorar a silhueta, nunca mostrá-lo nítido.

### Texturas que melhorariam muito
- **Papel de parede** (o atual é um padrão simples de listras e losangos).
- **Vista de Arkham** pela janela, de dia, ao entardecer e de noite (telhados de
  1928 e a torre gótica da Miskatonic, com o mostrador aceso à noite). Hoje são
  silhuetas geradas em 256×128; a torre fica um pouco à direita do centro.
- **Recortes de jornal** no quadro, legíveis de longe só como manchas de texto.

---

## Mais adiante (não precisa agora)
Fica registrado para não esquecer; detalhes quando chegarmos lá.
- **Ato II:** vagão de trem, plataforma da estação de Brattleboro, Ford modelo T, Noyes.
- **Fazenda:** casa de dois andares, cão pastor (o asset animado mais caro, GDD §11.4),
  rifle, cilindros e aparelhos, "Akeley" na poltrona, pedra negra.
- **Yuggoth:** Mi-Go completo, torres e pontes.
