# Atalhos do projeto (ver COMANDOS.md). Uso, da pasta do projeto:
#
#   powershell -ExecutionPolicy Bypass -File .\comandos.ps1 <acao> [argumento]
#
# Sem ação, lista as ações. Tudo roda o Godot com tempo limite: uma cena com
# erro de script não sai sozinha, e o --import às vezes trava.

param(
	[string]$acao = "ajuda",
	[string]$arg = ""
)

$ErrorActionPreference = "Stop"
$godotDir = "C:\Users\raul.silva\Downloads\Godot_v4.7.2-stable_win64.exe"
$godot = Join-Path $godotDir "Godot_v4.7.2-stable_win64_console.exe"
$godotJanela = Join-Path $godotDir "Godot_v4.7.2-stable_win64.exe"
$raiz = $PSScriptRoot
$projeto = Join-Path $raiz "yuggoth"
$userDir = Join-Path $env:APPDATA "Godot\app_userdata\Yuggoth"
$save = Join-Path $userDir "save.json"
$saves = Join-Path $userDir "saves_guardados"
$logs = Join-Path $raiz ".logs"

# Roda o Godot (console) com tempo limite; a saída vai para .logs\<nome>.txt.
function Godot-Com-Limite([string[]]$argumentos, [int]$segundos, [string]$nome) {
	New-Item -ItemType Directory -Force $logs | Out-Null
	$saida = Join-Path $logs "$nome.txt"
	$erros = Join-Path $logs "$nome.erros.txt"
	Write-Host "-> godot $($argumentos -join ' ')  (limite: $segundos s)"
	$p = Start-Process $godot -ArgumentList $argumentos -WorkingDirectory $projeto -NoNewWindow -PassThru `
		-RedirectStandardOutput $saida -RedirectStandardError $erros
	if (-not $p.WaitForExit($segundos * 1000)) {
		$p.Kill()
		Write-Host "TEMPO ESGOTADO ($segundos s). Saída em $saida" -ForegroundColor Red
		return -1
	}
	$p.WaitForExit()
	$falhas = Select-String -Path $saida, $erros -Pattern 'SCRIPT ERROR|Parse Error|FALHOU' -ErrorAction SilentlyContinue
	if ($falhas) {
		$falhas | Select-Object -First 20 | ForEach-Object { Write-Host $_.Line -ForegroundColor Yellow }
	}
	Write-Host "código de saída: $($p.ExitCode)   (saída completa em $saida)"
	return $p.ExitCode
}

function Ajuda {
	@"
Ações (powershell -ExecutionPolicy Bypass -File .\comandos.ps1 <ação>):

  JOGAR
    jogar              abre o jogo (janela própria; F2 pula o dia, F3 recarrega)
    jogar-log          abre o jogo e mostra o console (erros aparecem aqui)
    editor             abre o projeto no editor do Godot

  TESTAR
    teste              teste de fumaça (~5 min; código = número de falhas)
    importar           reimporta o projeto (depois de class_name nova ou asset gerado)
    captura <tag>      roda tests/_tmp_shot (capturas em .logs\capturas)

  GERAR (sobrescrevem arquivos gerados)
    gerar-assets       texturas e sons provisórios (+ importar)
    gerar-escritorio   materiais + levels/escritorio/escritorio.tscn
    gerar-boston       levels/boston/boston.tscn
    gerar-tudo         assets, importar, escritório e Boston, nessa ordem

  SAVE (user://save.json)
    save-ver           mostra dia, data e as principais flags do save atual
    save-guardar <nome>    copia o save atual para saves_guardados\<nome>.json
    save-listar        lista os saves guardados
    save-usar <nome>   põe um save guardado no lugar do atual (o atual vai para _anterior)
    save-apagar        tira o save atual do caminho (guardado como _apagado)
    save-pasta         abre a pasta de dados do jogo no Explorer

  OUTROS
    log                últimas linhas do log do Godot da última partida
    estado             git status + últimos commits
"@ | Write-Host
}

# O save é JSON.from_native: listas "args" com chave e valor alternados ("sn:dia", "i:3").
function Pares($no) {
	$d = [ordered]@{}
	for ($k = 0; $k + 1 -lt $no.args.Count; $k += 2) {
		$d[($no.args[$k] -replace '^s[n]?:', '')] = $no.args[$k + 1]
	}
	return $d
}

function Valor($v) {
	if ($v -is [string]) { return ($v -replace '^[a-z]+:', '') }
	return $v
}

function Save-Ver {
	if (-not (Test-Path $save)) { Write-Host "Sem save em $save"; return }
	$raizSave = Pares (Get-Content $save -Raw -Encoding UTF8 | ConvertFrom-Json)
	$valores = Pares (Pares $raizSave["state"])["values"]
	Write-Host "Save: $save  ($((Get-Item $save).LastWriteTime))"
	Write-Host "Fase: $(Valor $raizSave['level'])"
	foreach ($chave in @("dia", "data", "crenca", "exposicao", "suspeita", "discrepancias")) {
		if ($valores.Contains($chave)) { Write-Host ("  {0,-14} {1}" -f $chave, (Valor $valores[$chave])) }
	}
	$feitos = $valores.Keys | Where-Object { $_ -match '^(escreveu_resposta_dia_|anotou_dia_|acordou_noite_|tocou_disco|voltou_de_boston)' -and $valores[$_] -eq $true }
	Write-Host "  feitos: $($feitos -join ', ')"
	$respostas = $valores.Keys | Where-Object { $_ -match '^resposta_dia_\d$' } | ForEach-Object { "$_=$(Valor $valores[$_])" }
	Write-Host "  tons das respostas: $($respostas -join ', ')"
}

switch ($acao) {
	"ajuda" { Ajuda }
	"jogar" { Start-Process $godotJanela -ArgumentList "--path", "`"$projeto`"" }
	"jogar-log" { & $godot --path $projeto }
	"editor" { Start-Process $godotJanela -ArgumentList "-e", "--path", "`"$projeto`"" }
	"teste" { exit (Godot-Com-Limite @("--headless", "--path", ".", "res://tests/smoke_test.tscn") 600 "teste") }
	"importar" { exit (Godot-Com-Limite @("--headless", "--path", ".", "--import") 300 "importar") }
	"captura" {
		$env:SHOT_DIR = Join-Path $logs "capturas"
		$env:SHOT_TAG = if ($arg) { $arg } else { "shot" }
		New-Item -ItemType Directory -Force $env:SHOT_DIR | Out-Null
		# Sem --headless: precisa renderizar.
		exit (Godot-Com-Limite @("--path", ".", "res://tests/_tmp_shot.tscn") 300 "captura")
	}
	"gerar-assets" {
		Godot-Com-Limite @("--headless", "--path", ".", "--script", "res://tools/gerar_assets.gd") 300 "gerar_assets" | Out-Null
		exit (Godot-Com-Limite @("--headless", "--path", ".", "--import") 300 "importar")
	}
	"gerar-escritorio" { exit (Godot-Com-Limite @("--headless", "--path", ".", "res://tools/gerar_escritorio.tscn") 300 "gerar_escritorio") }
	"gerar-boston" { exit (Godot-Com-Limite @("--headless", "--path", ".", "res://tools/gerar_boston.tscn") 300 "gerar_boston") }
	"gerar-tudo" {
		Godot-Com-Limite @("--headless", "--path", ".", "--script", "res://tools/gerar_assets.gd") 300 "gerar_assets" | Out-Null
		Godot-Com-Limite @("--headless", "--path", ".", "--import") 300 "importar" | Out-Null
		Godot-Com-Limite @("--headless", "--path", ".", "res://tools/gerar_escritorio.tscn") 300 "gerar_escritorio" | Out-Null
		exit (Godot-Com-Limite @("--headless", "--path", ".", "res://tools/gerar_boston.tscn") 300 "gerar_boston")
	}
	"save-ver" { Save-Ver }
	"save-guardar" {
		if (-not (Test-Path $save)) { Write-Host "Sem save atual."; exit 1 }
		$nome = if ($arg) { $arg } else { Get-Date -Format "yyyy-MM-dd_HHmm" }
		New-Item -ItemType Directory -Force $saves | Out-Null
		Copy-Item $save (Join-Path $saves "$nome.json") -Force
		Write-Host "Guardado: $nome"
	}
	"save-listar" {
		if (Test-Path $saves) { Get-ChildItem $saves -Filter *.json | ForEach-Object { "{0,-30} {1}" -f $_.BaseName, $_.LastWriteTime } }
		else { Write-Host "Nenhum save guardado." }
	}
	"save-usar" {
		$origem = Join-Path $saves "$arg.json"
		if (-not $arg -or -not (Test-Path $origem)) { Write-Host "Não achei '$arg'. Veja: save-listar"; exit 1 }
		New-Item -ItemType Directory -Force $saves | Out-Null
		if (Test-Path $save) { Copy-Item $save (Join-Path $saves "_anterior.json") -Force }
		Copy-Item $origem $save -Force
		Write-Host "Save atual agora é '$arg' (o anterior ficou em _anterior). Use 'Continuar' no menu."
	}
	"save-apagar" {
		if (-not (Test-Path $save)) { Write-Host "Sem save atual."; exit 0 }
		New-Item -ItemType Directory -Force $saves | Out-Null
		Move-Item $save (Join-Path $saves "_apagado.json") -Force
		Write-Host "Save tirado do caminho (guardado como _apagado). O próximo jogo começa do zero."
	}
	"save-pasta" { Start-Process explorer.exe $userDir }
	"log" {
		$log = Join-Path $userDir "logs\godot.log"
		if (Test-Path $log) { Get-Content $log -Tail 60 } else { Write-Host "Sem log em $log" }
	}
	"estado" { git -C $raiz status --short; git -C $raiz log --oneline -10 }
	default { Write-Host "Ação desconhecida: $acao`n"; Ajuda; exit 1 }
}
