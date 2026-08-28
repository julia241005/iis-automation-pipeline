[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolName,

    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
)

$ErrorActionPreference = "Stop"

Import-Module WebAdministration

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$SafeSiteName = $SiteName -replace '[\\/:*?"<>|]', '_'

$BackupDir = "C:\DeployBackups\$SafeSiteName"

$CurrentBackup = Join-Path `
    $BackupDir `
    "Backup_$Timestamp"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "          DEPLOY AUTOMATIZADO IIS"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Site:          $SiteName"
Write-Host "App Pool:      $AppPoolName"
Write-Host "Origem:        $SourcePath"
Write-Host "Destino:       $DestinationPath"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

try {

    # ---------------------------------------------------------
    # 1. Validar Site
    # ---------------------------------------------------------

    Write-Host "[1/5] Validando Site e App Pool..." -ForegroundColor Yellow

    $site = Get-Website `
        -Name $SiteName `
        -ErrorAction Stop

    $pool = Get-WebAppPoolState `
        -Name $AppPoolName `
        -ErrorAction Stop

    Write-Host "[OK] Site e App Pool encontrados." -ForegroundColor Green

    # ---------------------------------------------------------
    # 2. Backup
    # ---------------------------------------------------------

    Write-Host "[2/5] Criando backup preventivo..." -ForegroundColor Yellow

    if (Test-Path -LiteralPath $DestinationPath) {

        New-Item `
            -ItemType Directory `
            -Path $CurrentBackup `
            -Force | Out-Null

        Copy-Item `
            -Path "$DestinationPath\*" `
            -Destination $CurrentBackup `
            -Recurse `
            -Force

        Write-Host "[OK] Backup salvo em: $CurrentBackup" -ForegroundColor Green
    }
    else {

        New-Item `
            -ItemType Directory `
            -Path $DestinationPath `
            -Force | Out-Null

        Write-Host "[OK] Pasta de destino criada." -ForegroundColor Green
    }

    # ---------------------------------------------------------
    # 3. Parar App Pool
    # ---------------------------------------------------------

    Write-Host "[3/5] Parando App Pool..." -ForegroundColor Yellow

    if ((Get-WebAppPoolState -Name $AppPoolName).Value -eq "Started") {

        Stop-WebAppPool `
            -Name $AppPoolName

        Start-Sleep -Seconds 2
    }

    Write-Host "[OK] App Pool parado." -ForegroundColor Green

    # ---------------------------------------------------------
    # 4. Copiar arquivos
    # ---------------------------------------------------------

    Write-Host "[4/5] Copiando arquivos..." -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "SourcePath não encontrado: $SourcePath"
    }

    Copy-Item `
        -Path "$SourcePath\*" `
        -Destination $DestinationPath `
        -Recurse `
        -Force

    Write-Host "[OK] Arquivos copiados." -ForegroundColor Green

    # ---------------------------------------------------------
    # 5. Iniciar App Pool
    # ---------------------------------------------------------

    Write-Host "[5/5] Iniciando App Pool..." -ForegroundColor Yellow

    Start-WebAppPool `
        -Name $AppPoolName

    Write-Host "[OK] App Pool iniciado." -ForegroundColor Green

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "       DEPLOY CONCLUÍDO COM SUCESSO"
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "Site:     $SiteName"
    Write-Host "App Pool: $AppPoolName"
    Write-Host "==============================================" -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host "            ERRO NO DEPLOY"
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    exit 1
}