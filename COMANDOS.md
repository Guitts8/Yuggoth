# Comandos

Tudo o que usamos até aqui para rodar, testar e gerar o jogo, mais alguns atalhos.
A forma curta é o `comandos.ps1` (na raiz do projeto); embaixo, os comandos crus que
ele roda, para copiar e colar.

## Atalho: `comandos.ps1`

Do PowerShell, na pasta do projeto (`Jogonovomaissimplesprasairdopapel`):

```powershell
powershell -ExecutionPolicy Bypass -File .\comandos.ps1            # lista as ações
powershell -ExecutionPolicy Bypass -File .\comandos.ps1 jogar      # abre o jogo
```

O `-ExecutionPolicy Bypass` é porque o Windows bloqueia scripts `.ps1` por padrão; vale
só para aquele comando. A saída do Godot de cada ação fica em `.logs\` (fora do git).

| Ação | O que faz |
|---|---|
| `jogar` | Abre o jogo numa janela |
| `jogar-log` | Abre o jogo com o console junto (os erros aparecem nele) |
| `editor` | Abre o projeto no editor do Godot |
| `teste` | Teste de fumaça (~5 min). O código de saída é o número de falhas |
| `caminhos` | Os caminhos fora do roteiro (~5 min): a pausa e o dossiê no meio das cenas, sair para o menu e continuar no meio do dia e do sonho, descer a escada com a carta, o diário vazio, a noite do Dia 5 sem fogo, continuar em Boston, os textos em todo tom; a legenda que ficava na tela ao trocar de fase, F2/F3 no meio das cenas, sair para o menu no cartão do fim, o menu só pelo teclado, o diário aberto na ida a Boston (~10 min) |
| `macaco [semente] [tom]` | Um jogador ao acaso joga a demo inteira (~15 min): ações em qualquer ordem, telas no meio das cenas, cartas amassadas. Acusa travamentos (com as últimas ações), quedas do mapa e erros no log. Com a semente, repete (quase sempre) as mesmas escolhas; com o tom (-1, 0 ou 1), toda resposta a Akeley sai nesse tom |
| `importar` | Reimporta o projeto (depois de uma `class_name` nova ou de gerar assets) |
| `captura <tag>` | Roda `tests/_tmp_shot` e salva as capturas em `.logs\capturas` |
| `gerar-assets` | Texturas e sons provisórios, e importa |
| `gerar-escritorio` | Materiais e `levels/escritorio/escritorio.tscn` (sobrescreve) |
| `gerar-boston` | `levels/boston/boston.tscn` (sobrescreve) |
| `gerar-tudo` | Assets → importar → escritório → Boston |
| `save-ver` | Mostra o dia, a data e o que já foi feito no save atual |
| `save-guardar <nome>` | Copia o save atual para `saves_guardados\<nome>.json` |
| `save-listar` | Lista os saves guardados |
| `save-usar <nome>` | Põe um save guardado no lugar do atual (o atual fica em `_anterior`) |
| `save-apagar` | Tira o save atual do caminho (fica guardado como `_apagado`) |
| `save-pasta` | Abre a pasta de dados do jogo no Explorer |
| `log` | Últimas linhas do log do Godot da última partida |
| `estado` | `git status` e os últimos commits |

Uma dica para o playtest: antes de um dia que costuma dar problema,
`save-guardar dia3`; se travar, `save-usar dia3` e **Continuar** no menu.

## Teclas dentro do jogo

| Tecla | O quê |
|---|---|
| W A S D | Andar (com o personagem sentado, andar faz ele levantar) |
| Mouse | Olhar. A cabeça fica livre mesmo durante as cenas |
| E | Interagir |
| Botão direito / Z | Zoom (para ler de longe) |
| Ctrl | Agachar |
| Tab | Dossiê |
| ← → | Páginas (no leitor) |
| Esc | Pausa / fechar janelas / amassar a folha da resposta |

**Só em build de depuração** (rodando pelo editor ou pelo `jogar`; não existem no jogo
exportado):

| Tecla | O quê |
|---|---|
| **F** (segurar) | Acelera tudo 8× (falas, lapsos, sonhos, animações) |
| **F2** | **Pula para o dia seguinte**: dá o dia corrente por feito (correio aberto, resposta escrita, dia anotado) e abre o escritório na manhã seguinte. No Prólogo, pula para o Dia 1. Não passa do Dia 6 (o último da demo). Feche janelas abertas antes |
| **F3** | **Recarrega o dia**: abre o escritório de novo no mesmo dia, com o que já foi feito. Serve para destravar sem pular |
| C | Troca a vista da janela entre a cidade 3D e o painel antigo |

## Os comandos crus

O Godot não está no PATH. O binário é uma **pasta** com nome de `.exe`; os executáveis
estão dentro dela. A versão `_console` mostra a saída e devolve o código de retorno.

```powershell
$godot = "C:\Users\raul.silva\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
cd yuggoth

& $godot --path .                                   # jogar
& $godot -e --path .                                # editor
& $godot --headless --path . res://tests/smoke_test.tscn   # teste de fumaça (~5 min)
& $godot --headless --path . res://tests/caminhos_test.tscn   # caminhos fora do roteiro (~5 min)
$env:CAMINHOS = "macaco"; $env:SEMENTE = "1"                  # o macaco: a demo inteira ao acaso
$env:TOM = "-1"                                               # (opcional) toda resposta nesse tom
& $godot --headless --path . res://tests/caminhos_test.tscn   # (~15 min; sem SEMENTE, uma nova)
& $godot --headless --path . --import               # importar

# Geradores (arte e sons provisórios, determinísticos)
& $godot --headless --path . --script res://tools/gerar_assets.gd   # texturas e sons
& $godot --headless --path . --import                               # importar o que foi gerado
& $godot --headless --path . res://tools/gerar_escritorio.tscn      # materiais + escritorio.tscn
& $godot --headless --path . res://tools/gerar_boston.tscn          # boston.tscn

# Captura de tela (sem --headless; o script lê SHOT_DIR e SHOT_TAG)
$env:SHOT_DIR = "$PWD\..\.logs\capturas"; $env:SHOT_TAG = "teste"
& $godot --path . res://tests/_tmp_shot.tscn
```

Rode com tempo limite quando for automático (uma cena com erro de script não sai
sozinha, e o `--import` às vezes trava):

```powershell
$p = Start-Process $godot -ArgumentList '--headless','--path','.','res://tests/smoke_test.tscn' -NoNewWindow -PassThru
if (-not $p.WaitForExit(600000)) { $p.Kill(); "TEMPO ESGOTADO" } else { "falhas: $($p.ExitCode)" }
```

### Onde ficam os dados

- Save: `%APPDATA%\Godot\app_userdata\Yuggoth\save.json` (um slot só; checkpoint a cada troca de fase e começo de dia)
- Preferências: `...\Yuggoth\settings.cfg`
- Log da última partida: `...\Yuggoth\logs\godot.log`
- Os testes usam `smoke_test_save.json` e `smoke_test_settings.cfg`, sem mexer no seu save.

### Git

```powershell
git status --short
git log --oneline -10
git diff --stat
git add <arquivos>; git commit -m "..."     # um commit por feature
git push                                    # sempre logo depois de cada commit
```
