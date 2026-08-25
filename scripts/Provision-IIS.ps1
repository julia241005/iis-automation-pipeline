Import-Module WebAdministration


param(
    [string]$SiteName = "PortalArtemys",
    [int]$Port = 8000,
    [string]$PhysicalPath = "C:\inetpub\wwwroot\PortalArtemys"
)

Import-Module WebAdministration

# O restante do seu código vem aqui embaixo...
# Parametros do ambiente
param (
    [string]$SiteName = "MeuAppIIS",
    [int]$Port = 8080,
    [string]$PhysicalPath = "C:\inetpub\wwwroot\MeuAppIIS"
)

# Garante que o modulo de administracao do IIS esteja carregado
Import-Module WebAdministration

Write-Host "--- Iniciando Provisionamento do Ambiente IIS ---" -ForegroundColor Cyan

# Step 1: Cria o diretorio fisico onde a aplicacao vai morar
if (-not (Test-Path $PhysicalPath)) {
    New-Item -ItemType Directory -Force -Path $PhysicalPath | Out-Null
    Write-Host "[+] Diretorio fisico criado: $PhysicalPath" -ForegroundColor Green
} else {
    Write-Host "[i] Diretorio fisico ja existe." -ForegroundColor Yellow
}

# Step 2: Cria o AppPool dedicado da aplicacao
if (-not (Get-WebAppPool -Name $SiteName -ErrorAction SilentlyContinue)) {
    New-WebAppPool -Name $SiteName
    Write-Host "[+] AppPool '$SiteName' criado." -ForegroundColor Green
} else {
    Write-Host "[i] AppPool '$SiteName' ja existe." -ForegroundColor Yellow
}

# Step 3: Cria o WebSite e vincula ao AppPool
if (-not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
    New-Website -Name $SiteName -Port $Port -PhysicalPath $PhysicalPath -ApplicationPool $SiteName
    Write-Host "[+] Site '$SiteName' criado e rodando na porta $Port!" -ForegroundColor Green
} else {
    Write-Host "[i] Site '$SiteName' ja existe no IIS." -ForegroundColor Yellow
}

Write-Host "--- Provisionamento Concluido com Sucesso ---" -ForegroundColor Cyan