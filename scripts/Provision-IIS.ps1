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
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "      PROVISIONAMENTO AUTOMATIZADO IIS"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Site:             $SiteName"
Write-Host "App Pool:         $AppPoolName"
Write-Host "Physical Path:    $PhysicalPath"
Write-Host ".NET CLR:         $DotNetVersion"
Write-Host "Pipeline:         $PipelineMode"
Write-Host "Identity:         $AppPoolIdentity"
Write-Host "Hostname:         $HostName"
Write-Host "Protocolo:        $Protocol"
Write-Host "IP Binding:       $BindingIP"
Write-Host "Certificado:      $CertificateName"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

try {

    # ---------------------------------------------------------
    # 1. Validações
    # ---------------------------------------------------------

    Write-Host "[1/7] Validando parâmetros..." -ForegroundColor Yellow

    if ([string]::IsNullOrWhiteSpace($SiteName)) {
        throw "SiteName não pode estar vazio."
    }

    if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
        throw "AppPoolName não pode estar vazio."
    }

    if ([string]::IsNullOrWhiteSpace($PhysicalPath)) {
        throw "PhysicalPath não pode estar vazio."
    }

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        throw "HostName não pode estar vazio."
    }

    # Evita que o erro original volte a acontecer:
    # App Pool não deve ser igual ao Site.
    if ($AppPoolName -eq $SiteName) {
        throw "O nome do App Pool não pode ser igual ao nome do Site. Use o padrão App_..."
    }

    # ---------------------------------------------------------
    # 2. Pasta física
    # ---------------------------------------------------------

    Write-Host "[2/7] Verificando pasta física..." -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $PhysicalPath)) {
        Write-Host "Criando pasta: $PhysicalPath"

        New-Item `
            -ItemType Directory `
            -Path $PhysicalPath `
            -Force | Out-Null

        Write-Host "[OK] Pasta criada." -ForegroundColor Green
    }
    else {
        Write-Host "[OK] Pasta já existe." -ForegroundColor Green
    }

    # ---------------------------------------------------------
    # 3. Application Pool
    # ---------------------------------------------------------

    Write-Host "[3/7] Configurando Application Pool..." -ForegroundColor Yellow

    $appPool = Get-Item "IIS:\AppPools\$AppPoolName" -ErrorAction SilentlyContinue

    if ($null -eq $appPool) {

        Write-Host "Criando Application Pool: $AppPoolName"

        New-WebAppPool -Name $AppPoolName | Out-Null

        $appPool = Get-Item "IIS:\AppPools\$AppPoolName"
    }
    else {
        Write-Host "Application Pool já existe: $AppPoolName"
    }

    # .NET CLR
    $appPool.managedRuntimeVersion = $DotNetVersion

    # Pipeline
    switch ($PipelineMode) {
        "Integrated" {
            $appPool.managedPipelineMode = "Integrated"
        }

        "Classic" {
            $appPool.managedPipelineMode = "Classic"
        }
    }

    # Identity
    if ($AppPoolIdentity -eq "ApplicationPoolIdentity") {

        Write-Host "Configurando Identity: ApplicationPoolIdentity"

        $appPool.processModel.identityType = 4
        $appPool.processModel.userName = ""
        $appPool.processModel.password = ""
    }
    elseif ($AppPoolIdentity -eq "REMAZAWEB\WebTrusted") {

        Write-Host "Configurando Identity: REMAZAWEB\WebTrusted"

        $password = $env:WEBTRUSTED_PASSWORD

        if ([string]::IsNullOrWhiteSpace($password)) {
            throw @"
A identidade REMAZAWEB\WebTrusted foi selecionada,
mas a variável WEBTRUSTED_PASSWORD não foi fornecida.

Cadastre a senha como GitHub Actions Secret:
WEBTRUSTED_PASSWORD
"@
        }

        $appPool.processModel.identityType = 3
        $appPool.processModel.userName = "REMAZAWEB\WebTrusted"
        $appPool.processModel.password = $password
    }

    # Salva as configurações do App Pool
    $appPool | Set-Item

    Write-Host "[OK] Application Pool configurado." -ForegroundColor Green

    # ---------------------------------------------------------
    # 4. Site IIS
    # ---------------------------------------------------------

    Write-Host "[4/7] Configurando Site IIS..." -ForegroundColor Yellow

    $site = Get-Website -Name $SiteName -ErrorAction SilentlyContinue

    if ($null -eq $site) {

        Write-Host "Criando Site: $SiteName"

        New-Website `
            -Name $SiteName `
            -PhysicalPath $PhysicalPath `
            -ApplicationPool $AppPoolName `
            -IPAddress $BindingIP `
            -Port 80 `
            -HostHeader $HostName `
            -Force | Out-Null
    }
    else {

        Write-Host "Site já existe. Atualizando configuração..."

        Set-ItemProperty `
            "IIS:\Sites\$SiteName" `
            -Name physicalPath `
            -Value $PhysicalPath

        Set-ItemProperty `
            "IIS:\Sites\$SiteName" `
            -Name applicationPool `
            -Value $AppPoolName
    }

    Write-Host "[OK] Site configurado." -ForegroundColor Green

    # ---------------------------------------------------------
    # 5. Binding HTTP
    # ---------------------------------------------------------

    Write-Host "[5/7] Configurando bindings..." -ForegroundColor Yellow

    $httpBinding = Get-WebBinding `
        -Name $SiteName `
        -Protocol "http" `
        -Port 80 `
        -ErrorAction SilentlyContinue

    if ($Protocol -eq "HTTP" -or $Protocol -eq "HTTP + HTTPS") {

        if ($null -eq $httpBinding) {

            Write-Host "Criando HTTP $BindingIP`:80`:$HostName"

            New-WebBinding `
                -Name $SiteName `
                -Protocol "http" `
                -IPAddress $BindingIP `
                -Port 80 `
                -HostHeader $HostName `
                -Force | Out-Null
        }
        else {
            Write-Host "HTTP binding já existe."
        }
    }

    # ---------------------------------------------------------
    # 6. Binding HTTPS + certificado
    # ---------------------------------------------------------

    if ($Protocol -eq "HTTPS" -or $Protocol -eq "HTTP + HTTPS") {

        Write-Host "[6/7] Configurando HTTPS e certificado..." -ForegroundColor Yellow

        $certificate = Get-ChildItem `
            -Path "Cert:\LocalMachine\My" |
            Where-Object {
                $_.Subject -like "*$CertificateName*" -and
                $_.HasPrivateKey -eq $true
            } |
            Sort-Object NotAfter -Descending |
            Select-Object -First 1

        if ($null -eq $certificate) {
            throw "Certificado '$CertificateName' não encontrado em Cert:\LocalMachine\My com chave privada."
        }

        Write-Host "Certificado encontrado:"
        Write-Host "  Subject:    $($certificate.Subject)"
        Write-Host "  Thumbprint: $($certificate.Thumbprint)"
        Write-Host "  Expira:     $($certificate.NotAfter)"

        $httpsBinding = Get-WebBinding `
            -Name $SiteName `
            -Protocol "https" `
            -Port 443 `
            -ErrorAction SilentlyContinue

        if ($null -eq $httpsBinding) {

            Write-Host "Criando HTTPS $BindingIP`:443`:$HostName com SNI..."

            New-WebBinding `
                -Name $SiteName `
                -Protocol "https" `
                -IPAddress $BindingIP `
                -Port 443 `
                -HostHeader $HostName `
                -SslFlags 1 `
                -Force | Out-Null
        }

        $httpsBinding = Get-WebBinding `
            -Name $SiteName `
            -Protocol "https" `
            -Port 443 `
            -ErrorAction Stop

        $httpsBinding.AddSslCertificate(
            $certificate.Thumbprint,
            "MY"
        )

        Write-Host "[OK] HTTPS configurado com SNI." -ForegroundColor Green
    }
    else {
        Write-Host "[6/7] HTTPS não solicitado." -ForegroundColor DarkGray
    }

    # ---------------------------------------------------------
    # 7. Finalização e validação
    # ---------------------------------------------------------

    Write-Host "[7/7] Validando provisionamento..." -ForegroundColor Yellow

    $finalPool = Get-Item "IIS:\AppPools\$AppPoolName" -ErrorAction Stop
    $finalSite = Get-Website -Name $SiteName -ErrorAction Stop

    Write-Host ""
    Write-Host "RESULTADO:" -ForegroundColor Cyan
    Write-Host "Site:             $($finalSite.Name)"
    Write-Host "App Pool:         $($finalSite.applicationPool)"
    Write-Host "Physical Path:    $($finalSite.physicalPath)"
    Write-Host "Pool CLR:         $($finalPool.managedRuntimeVersion)"
    Write-Host "Pool Pipeline:    $($finalPool.managedPipelineMode)"
    Write-Host ""

    if ($finalSite.applicationPool -ne $AppPoolName) {
        throw "O Site não está associado ao App Pool esperado: $AppPoolName"
    }

    if ($finalSite.physicalPath -ne $PhysicalPath) {
        throw "O Physical Path final não corresponde ao informado."
    }

    # Inicia o App Pool
    if ((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Started") {
        Start-WebAppPool -Name $AppPoolName
    }

    # Inicia o Site
    if ((Get-WebsiteState -Name $SiteName).Value -ne "Started") {
        Start-Website -Name $SiteName
    }

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host " IIS PROVISIONADO COM SUCESSO"
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "Site:     $SiteName"
    Write-Host "App Pool: $AppPoolName"
    Write-Host "URL:      $HostName"
    Write-Host "==============================================" -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host " ERRO NO PROVISIONAMENTO DO IIS"
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    exit 1
}