[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SiteName,

    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "src",

    [Parameter(Mandatory=$false)]
    [string]$DestinationPath = "C:\inetpub\wwwroot\PortalArtemys"
)

Import-Module WebAdministration

$Timestamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir     = "C:\DeployBackups\$SiteName"
$CurrentBackup = Join-Path $BackupDir "Backup_$Timestamp"

Write-Host "--- Iniciando o Deploy automatizado para o $SiteName ---" -ForegroundColor Cyan

try {
    # 1. Backup Preventivo
    Write-Host "[i] Criando backup preventivo..." -ForegroundColor Yellow
    if (Test-Path $DestinationPath) {
        New-Item -ItemType Directory -Path $CurrentBackup -Force | Out-Null
        Copy-Item -Path "$DestinationPath\*" -Destination $CurrentBackup -Recurse -Force
        Write-Host "[+] Backup salvo em: $CurrentBackup" -ForegroundColor Green
    }

    # 2. Para o Application Pool
    Write-Host "[i] Parando o AppPool ($SiteName)..." -ForegroundColor Yellow
    Stop-WebAppPool -Name $SiteName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # 3. Copia os novos arquivos
    Write-Host "[i] Copiando arquivos novos..." -ForegroundColor Yellow
    Copy-Item -Path "$SourcePath\*" -Destination $DestinationPath -Recurse -Force

    # 4. Reinicia o Application Pool
    Write-Host "[i] Reiniciando o AppPool..." -ForegroundColor Yellow
    Start-WebAppPool -Name $SiteName

    Write-Host "--- Deploy concluído com sucesso para o $SiteName! ---" -ForegroundColor Green
}
catch {
    Write-Host "[-] ERRO NO DEPLOY: $_" -ForegroundColor Red
    # Aqui entraria a lógica de restaurar o backup se falhar
    exit 1
}