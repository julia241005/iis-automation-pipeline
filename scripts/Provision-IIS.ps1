param(
    [string]$SiteName = "PortalArtemys",
    [int]$Port = 8000,
    [string]$PhysicalPath = "C:\inetpub\wwwroot\PortalArtemys"
)

Import-Module WebAdministration

# O restante do seu código continua aqui embaixo...

if (-not (Test-Path $PhysicalPath)) {
    New-Item -ItemType Directory -Path $PhysicalPath -Force
}

if (-not (Get-WebAppPool -Name $SiteName -ErrorAction SilentlyContinue)) {
    New-WebAppPool -Name $SiteName
}

if (-not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
    New-WebSite -Name $SiteName -Port $Port -PhysicalPath $PhysicalPath -ApplicationPool $SiteName
}