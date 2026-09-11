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
    [ValidateSet("DOMINIO\AppPoolUser", "ApplicationPoolIdentity")]
    [string]$AppPoolIdentity,

    [Parameter(Mandatory = $true)]
    [string]$HostName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("HTTP", "HTTPS", "HTTP + HTTPS")]
    [string]$Protocol,

    [Parameter(Mandatory = $false)]
    [string]$BindingIP = "192.168.1.10",

    [Parameter(Mandatory = $false)]
    [string]$CertificateName = "*.exemplo.com.br"
)

$ErrorActionPreference = "Stop"

Import-Module WebAdministration

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "        INICIANDO VALIDACAO E PROVISIONAMENTO IIS SEGURO" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " [Parametros de Entrada]" -ForegroundColor DarkCyan
Write-Host "  - Nome do Site:      $SiteName"
Write-Host "  - App Pool:          $AppPoolName"
Write-Host "  - Caminho Físico:    $PhysicalPath"
Write-Host "  - Versão .NET:       $DotNetVersion"
Write-Host "  - Modo Pipeline:     $PipelineMode"
Write-Host "  - Identidade Pool:   $AppPoolIdentity"
Write-Host "  - Hostname / URL:    $HostName"
Write-Host "  - Protocolo:         $Protocol"
Write-Host "  - IP de Binding:     $BindingIP"
Write-Host "  - Certificado:       $CertificateName"
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

try {

    # ------------------------------------------------------------------
    # PASSO 1: Validações e Limpeza Preventiva Automática
    # ------------------------------------------------------------------

    Write-Host "[1/7] Executando verificações de segurança e integridade..." -ForegroundColor Yellow

    if ([string]::IsNullOrWhiteSpace($SiteName)) { throw "[ERRO] O parâmetro 'SiteName' está vazio." }
    if ([string]::IsNullOrWhiteSpace($AppPoolName)) { throw "[ERRO] O parâmetro 'AppPoolName' está vazio." }
    if ([string]::IsNullOrWhiteSpace($PhysicalPath)) { throw "[ERRO] O parâmetro 'PhysicalPath' está vazio." }
    if ([string]::IsNullOrWhiteSpace($HostName)) { throw "[ERRO] O parâmetro 'HostName' está vazio." }

    if ($AppPoolName -eq $SiteName) {
        throw "[ERRO] O nome do App Pool não pode ser idêntico ao nome do Site."
    }

    if (Test-Path "IIS:\AppPools\$AppPoolName") {
        Write-Host "   [AVISO] App Pool já existe. Removendo versão anterior..." -ForegroundColor Yellow
        Stop-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
        Remove-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
    }

    if (Test-Path "IIS:\Sites\$SiteName") {
        Write-Host "   [AVISO] Site já existe. Removendo versão anterior..." -ForegroundColor Yellow
        Stop-Website -Name $SiteName -ErrorAction SilentlyContinue
        Remove-Website -Name $SiteName -ErrorAction SilentlyContinue
    }

    Write-Host "[OK] Validações e limpeza concluídas." -ForegroundColor Green
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 2: Diretório Físico
    # ------------------------------------------------------------------

    Write-Host "[2/7] Verificando diretório físico..." -ForegroundColor Yellow
    if (-not (Test-Path -LiteralPath $PhysicalPath)) {
        New-Item -ItemType Directory -Path $PhysicalPath -Force | Out-Null
        Write-Host "[OK] Diretório criado." -ForegroundColor Green
    } else {
        Write-Host "[OK] Diretório já existe." -ForegroundColor Green
    }
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 3: Application Pool
    # ------------------------------------------------------------------

    Write-Host "[3/7] Provisionando Application Pool isolado..." -ForegroundColor Yellow
    New-WebAppPool -Name $AppPoolName | Out-Null
    $appPool = Get-Item "IIS:\AppPools\$AppPoolName"
    $appPool.managedRuntimeVersion = $DotNetVersion
    $appPool.managedPipelineMode = $PipelineMode

    if ($AppPoolIdentity -eq "ApplicationPoolIdentity") {
        $appPool.processModel.identityType = 4
        $appPool.processModel.userName = ""
        $appPool.processModel.password = ""
    }
    elseif ($AppPoolIdentity -eq "DOMINIO\AppPoolUser") {
        $password = $env:CUSTOM_APP_PASSWORD
        if ([string]::IsNullOrWhiteSpace($password)) {
            throw "[ERRO] A secret 'CUSTOM_APP_PASSWORD' não foi encontrada no repositório."
        }
        $appPool.processModel.identityType = 3
        $appPool.processModel.userName = "DOMINIO\AppPoolUser"
        $appPool.processModel.password = $password
    }
    $appPool | Set-Item
    Write-Host "[OK] Application Pool configurado." -ForegroundColor Green
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 4: Criação do Site IIS
    # ------------------------------------------------------------------

    Write-Host "[4/7] Criando o Site no IIS..." -ForegroundColor Yellow
    New-Website -Name $SiteName -PhysicalPath $PhysicalPath -ApplicationPool $AppPoolName -Force | Out-Null
    Write-Host "[OK] Site registrado no IIS." -ForegroundColor Green
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 5: Binding HTTP (Blindado contra duplicidade)
    # ------------------------------------------------------------------

    Write-Host "[5/7] Configurando portas e tráfego HTTP..." -ForegroundColor Yellow
    if ($Protocol -eq "HTTP" -or $Protocol -eq "HTTP + HTTPS") {
        $existingBinding = Get-WebBinding -Name $SiteName -Protocol "http" -IPAddress $BindingIP -Port 80 -HostHeader $HostName -ErrorAction SilentlyContinue
        if ($null -eq $existingBinding) {
            New-WebBinding -Name $SiteName -Protocol "http" -IPAddress $BindingIP -Port 80 -HostHeader $HostName -Force | Out-Null
            Write-Host "[OK] Binding HTTP configurado." -ForegroundColor Green
        } else {
            Write-Host "[OK] Binding HTTP já existente, mantendo íntegro." -ForegroundColor Green
        }
    } else {
        Write-Host "[IGNORADO] HTTP não selecionado." -ForegroundColor DarkGray
    }
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 6: Binding HTTPS e Certificado SSL
    # ------------------------------------------------------------------

    Write-Host "[6/7] Configurando portas e tráfego HTTPS..." -ForegroundColor Yellow
    if ($Protocol -eq "HTTPS" -or $Protocol -eq "HTTP + HTTPS") {
        $existingHttps = Get-WebBinding -Name $SiteName -Protocol "https" -IPAddress $BindingIP -Port 443 -HostHeader $HostName -ErrorAction SilentlyContinue
        if ($null -eq $existingHttps) {
            New-WebBinding -Name $SiteName -Protocol "https" -IPAddress $BindingIP -Port 443 -HostHeader $HostName -Force | Out-Null
            
            # Vinculando Certificado SSL
            $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*$CertificateName*" } | Select-Object -First 1
            if ($null -ne $cert) {
                $binding = Get-WebBinding -Name $SiteName -Protocol "https" -IPAddress $BindingIP -Port 443 -HostHeader $HostName
                $binding.AddSslCertificate($cert.Thumbprint, "my")
                Write-Host "[OK] Binding HTTPS e Certificado SSL configurados." -ForegroundColor Green
            } else {
                Write-Host "[AVISO] Certificado '$CertificateName' não encontrado, mas o binding HTTPS foi criado." -ForegroundColor Yellow
            }
        } else {
            Write-Host "[OK] Binding HTTPS já existente." -ForegroundColor Green
        }
    } else {
        Write-Host "[IGNORADO] HTTPS não selecionado." -ForegroundColor DarkGray
    }
    Write-Host ""

    # ------------------------------------------------------------------
    # PASSO 7: Inicialização do Site
    # ------------------------------------------------------------------

    Write-Host "[7/7] Iniciando o site no IIS..." -ForegroundColor Yellow
    Start-Website -Name $SiteName
    Write-Host "[OK] Site iniciado com sucesso." -ForegroundColor Green
    Write-Host ""

    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: PROVISIONAMENTO CONCLUIDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green

}
catch {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "       FALHA CRITICA NO PROVISIONAMENTO - EXECUCAO ABORTADA" -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "Detalhe do Erro:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    exit 1
}
