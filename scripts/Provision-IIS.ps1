param(
    [string]$SiteName = "PortalArtemys",
    [int]$Port = 8000,
    [string]$PhysicalPath = "C:\inetpub\wwwroot\PortalArtemys"
)

try {
    # Carrega a biblioteca do IIS na memória do PowerShell
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null

    # Garante que a pasta física existe
    if (-not (Test-Path $PhysicalPath)) {
        New-Item -ItemType Directory -Path $PhysicalPath -Force
    }

    $serverManager = New-Object Microsoft.Web.Administration.ServerManager

    # 1. Configura o Application Pool
    if ($serverManager.ApplicationPools[$SiteName] -eq $null) {
        Write-Host "Criando Application Pool: $SiteName"
        $appPool = $serverManager.ApplicationPools.Add($SiteName)
        $appPool.ManagedRuntimeVersion = "v4.0"
    } else {
        Write-Host "Application Pool $SiteName já existe."
    }

    # 2. Configura o Site no IIS
    if ($serverManager.Sites[$SiteName] -eq $null) {
        Write-Host "Criando Site IIS na porta $Port..."
        $site = $serverManager.Sites.Add($SiteName, "http", "*:$($Port):", $PhysicalPath)
        $site.Applications["/"].ApplicationPoolName = $SiteName
    } else {
        Write-Host "Site $SiteName já existe. Atualizando caminho..."
        $serverManager.Sites[$SiteName].Applications["/"].VirtualDirectories["/"].PhysicalPath = $PhysicalPath
    }

    # Salva as alterações no IIS
    Write-Host "Salvando alterações no IIS..."
    $serverManager.CommitChanges()

    Write-Host "IIS provisionado com sucesso!" -ForegroundColor Green
}
catch {
    Write-Host "ERRO ao provisionar IIS:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}