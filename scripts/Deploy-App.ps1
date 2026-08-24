param (
    [string]$SiteName = "PortalArtemys",
    [string]$SourcePath = "..\src",
    [string]$DestinationPath = "C:\inetpub\wwwroot\PortalArtemys"
)

Import-Module WebAdministration

Write-Host "--- Iniciando o Deploy automatizado para o $SiteName ---" -ForegroundColor Cyan

# 1. Para o Application Pool para evitar conflito de arquivos em uso
Write-Host "[i] Parando o AppPool..." -ForegroundColor Yellow
Stop-WebAppPool -Name $SiteName

# 2. Copia os novos arquivos do código para a pasta oficial do IIS na VM
Write-Host "[i] Copiando arquivos novos..." -ForegroundColor Yellow
Copy-Item -Path "$SourcePath\*" -Destination $DestinationPath -Recurse -Force

# 3. Reinicia o Application Pool para aplicar as alterações
Write-Host "[i] Iniciando o AppPool..." -ForegroundColor Yellow
Start-WebAppPool -Name $SiteName

Write-Host "--- Deploy concluído com sucesso para o PortalArtemys! ---" -ForegroundColor Green