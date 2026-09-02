[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolName,

    [Parameter(Mandatory = $true)]
    [string]$PhysicalPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet("v4.0", "v2.0", "No Managed Code")]
    [string]$DotNetVersion,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Integrated", "Classic")]
    [string]$PipelineMode,

    [Parameter(Mandatory = $true)]
    [ValidateSet("REMAZAWEB\WebTrusted", "ApplicationPoolIdentity")]
    [string]$AppPoolIdentity,

    [Parameter(Mandatory = $true)]
    [string]$HostName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("HTTP", "HTTPS", "HTTP + HTTPS")]
    [string]$Protocol,

    [Parameter(Mandatory = $false)]
    [string]$BindingIP = "172.19.10.10",

    [Parameter(Mandatory = $false)]
    [string]$CertificateName = "*.remaza.com.br"
)

$ErrorActionPreference = "Stop"

Import-Module WebAdministration

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "        INICIANDO VALIDACAO E PROVISIONAMENTO IIS SEGURO"
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " [Parametros de Entrada]" -ForegroundColor DarkCyan
Write-Host "  - Nome do Site:     $SiteName"
Write-Host "  - App Pool:         $AppPoolName"
Write-Host "  - Caminho Físico:   $PhysicalPath"
Write-Host "  - Versão .NET:      $DotNetVersion"
Write-Host "  - Modo Pipeline:    $PipelineMode"
Write-Host "  - Identidade Pool:  $AppPoolIdentity"
Write-Host "  - Hostname / URL:   $HostName"
Write-Host "  - Protocolo:        $Protocol"
Write-Host "  - IP de Binding:    $BindingIP"
Write-Host "  - Certificado:      $CertificateName"
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

try {

    # ------------------------------------------------------------------
    # PASSO 1: Bateria Completa de Validações Preventivas
    # ------------------------------------------------------------------

    Write-Host "[1/7] Executando verificações de segurança e integridade..." -ForegroundColor Yellow

    if ([string]::IsNullOrWhiteSpace($SiteName)) {
        throw "[ERRO DE VALIDAÇÃO] O parâmetro 'SiteName' está vazio ou em branco."
    }

    if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
        throw "[ERRO DE VALIDAÇÃO] O parâmetro 'AppPoolName' está vazio ou em branco."
    }

    if ([string]::IsNullOrWhiteSpace($PhysicalPath)) {
        throw "[ERRO DE VALIDAÇÃO] O parâmetro 'PhysicalPath' está vazio ou em branco."
    }

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        throw "[ERRO DE VALIDAÇÃO] O parâmetro 'HostName' está vazio ou em branco."
    }

    # Evita ambiguidade nome igual ao site
    if ($AppPoolName -eq $SiteName) {
        throw "[ERRO DE VALIDAÇÃO] O nome do App Pool ('$AppPoolName') não pode ser idêntico ao nome do Site. Utilize o padrão padronizado (Ex: App_$SiteName)."
    }

    # Trava rigorosa contra conflito de App Pool
    Write-Host "   -> Verificando se o App Pool '$AppPoolName' já existe no IIS..." -ForegroundColor DarkGray
    if (Test-Path "IIS:\AppPools\$AppPoolName") {
        throw "[CONFLITO CRÍTICO BLOQUEADO] O Application Pool '$AppPoolName' já está cadastrado no servidor por outro projeto ou processo. Operação abortada para preservar o ambiente de desenvolvimento."
    }

    # Trava rigorosa contra conflito de Site
    Write-Host "   -> Verificando se o Site '$SiteName' já existe no IIS..." -ForegroundColor DarkGray
    if (Test-Path "IIS:\Sites\$SiteName") {
        throw "[CONFLITO CRÍTICO BLOQUEADO] O Site do IIS '$SiteName' já existe e está configurado no servidor. Operação abortada para evitar sobrescrever dados de terceiros."
    }

    # Trava contra conflito de Hostname / Binding IP já em uso por outro site
    Write-Host "   -> Verificando se o Hostname '$HostName' já está em uso..." -ForegroundColor DarkGray
    $existingBinding = Get-WebBinding | Where-Object { 
        ($_.bindingInformation -like "*:$HostName*") -or 
        ($_.bindingInformation -like "$BindingIP*") 
    }
    if ($null -ne $existingBinding) {
        Write-Host "   [AVISO] Já existe um binding associado a esses parâmetros, certifique-se da exclusividade." -ForegroundColor Yellow
    }

    Write-Host "[OK] Todas as validações preventivas passaram com sucesso. Nenhum conflito detectado." -ForegroundColor Green
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 2: Pasta física
    # ------------------------------------------------------------------

    Write-Host "[2/7] Verificando diretório físico..." -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $PhysicalPath)) {
        Write-Host "   -> Criando nova pasta em: $PhysicalPath" -ForegroundColor DarkGray
        New-Item -ItemType Directory -Path $PhysicalPath -Force | Out-Null
        Write-Host "[OK] Diretório físico criado com sucesso." -ForegroundColor Green
    }
    else {
        Write-Host "[OK] Diretório físico já existe, mantendo estrutura intacta." -ForegroundColor Green
    }
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 3: Application Pool
    # ------------------------------------------------------------------

    Write-Host "[3/7] Provisionando Application Pool isolado..." -ForegroundColor Yellow
    Write-Host "   -> Criando App Pool: $AppPoolName" -ForegroundColor DarkGray
    New-WebAppPool -Name $AppPoolName | Out-Null
    $appPool = Get-Item "IIS:\AppPools\$AppPoolName"

    $appPool.managedRuntimeVersion = $DotNetVersion

    switch ($PipelineMode) {
        "Integrated" { $appPool.managedPipelineMode = "Integrated" }
        "Classic"    { $appPool.managedPipelineMode = "Classic" }
    }

    if ($AppPoolIdentity -eq "ApplicationPoolIdentity") {
        Write-Host "   -> Definindo identidade padrão: ApplicationPoolIdentity" -ForegroundColor DarkGray
        $appPool.processModel.identityType = 4
        $appPool.processModel.userName = ""
        $appPool.processModel.password = ""
    }
    elseif ($AppPoolIdentity -eq "REMAZAWEB\WebTrusted") {
        Write-Host "   -> Definindo identidade segura: REMAZAWEB\WebTrusted" -ForegroundColor DarkGray
        $password = $env:WEBTRUSTED_PASSWORD

        if ([string]::IsNullOrWhiteSpace($password)) {
            throw "[ERRO DE SEGURANÇA] A identidade 'REMAZAWEB\WebTrusted' exige a secret 'WEBTRUSTED_PASSWORD' no repositório do GitHub."
        }

        $appPool.processModel.identityType = 3
        $appPool.processModel.userName = "REMAZAWEB\WebTrusted"
        $appPool.processModel.password = $password
    }

    $appPool | Set-Item
    Write-Host "[OK] Application Pool configurado e ajustado com sucesso." -ForegroundColor Green
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 4: Site IIS
    # ------------------------------------------------------------------

    Write-Host "[4/7] Criando o Site no IIS..." -ForegroundColor Yellow
    New-Website -Name $SiteName -PhysicalPath $PhysicalPath -ApplicationPool $AppPoolName -IPAddress $BindingIP -Port 80 -HostHeader $HostName -Force | Out-Null
    Write-Host "[OK] Site registrado no IIS com sucesso." -ForegroundColor Green
    Write-Host ""

   # ------------------------------------------------------------------
    # PASSO 5: Binding HTTP (Protegido contra Duplicidade)
    # ------------------------------------------------------------------

    Write-Host "[5/7] Configurando portas e tráfego HTTP..." -ForegroundColor Yellow
    if ($Protocol -eq "HTTP" -or $Protocol -eq "HTTP + HTTPS") {
        Write-Host "   -> Verificando binding HTTP ($BindingIP`:80`:$HostName)..." -ForegroundColor DarkGray
        
        $existingBinding = Get-WebBinding -Name $SiteName -Protocol "http" -IPAddress $BindingIP -Port 80 -HostHeader $HostName -ErrorAction SilentlyContinue
        
        if ($null -eq $existingBinding) {
            New-WebBinding -Name $SiteName -Protocol "http" -IPAddress $BindingIP -Port 80 -HostHeader $HostName -Force | Out-Null
            Write-Host "[OK] Binding HTTP configurado." -ForegroundColor Green
        } else {
            Write-Host "[OK] Binding HTTP já existente, mantendo íntegro." -ForegroundColor Green
        }
    }
    else {
        Write-Host "   [IGNORADO] Protocolo HTTP não selecionado para este ambiente." -ForegroundColor DarkGray
    }
    Write-Host ""