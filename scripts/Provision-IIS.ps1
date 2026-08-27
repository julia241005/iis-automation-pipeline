param(
    [string]$SiteName = "PortalArtemys",
    [int]$Port = 8000,
    [string]$PhysicalPath = "C:\inetpub\wwwroot\PortalArtemys"
)

# Garante que a pasta física existe
if (-not (Test-Path $PhysicalPath)) {
    New-Item -ItemType Directory -Path $PhysicalPath -Force
}

# Usa o .NET ServerManager diretamente (não falha nunca)
$serverManager = New-Object Microsoft.Web.Administration.ServerManager

# 1. Configura o Application Pool
if ($serverManager.ApplicationPools[$SiteName] -eq $null) {
    Write-Host "Criando Application Pool: $SiteName"
    $appPool = $serverManager.ApplicationPools.Add($SiteName)
    $appPool.ManagedRuntimeVersion = "v4.0" # ou germanaged se for .NET Core/.NET 6+
} else {
    Write-Host "Application Pool $SiteName já existe."
}

# 2. Configura o Site no IIS
if ($serverManager.Sites[$SiteName] -eq $null) {
    Write-Host "Criando Site IIS na porta $Port..."
    $site = $serverManager.Sites.Add($SiteName, "http", "*:$Port:", $PhysicalPath)
    $site.ApplicationPoolName = $SiteName
} else {
    Write-Host "Site $SiteName já existe. Atualizando caminho..."
    $serverManager.Sites[$SiteName].Applications["/"].VirtualDirectories["/"].PhysicalPath = $PhysicalPath
}

# Salva as alterações no IIS
$serverManager.CommitChanges()
Write-Host "IIS provisionado com sucesso!"