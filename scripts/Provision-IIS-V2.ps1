param(
    [Parameter(Mandatory = $true)]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolName,

    [Parameter(Mandatory = $true)]
    [string]$PhysicalPath,

    [Parameter(Mandatory = $true)]
    [string]$DotNetVersion,

    [Parameter(Mandatory = $true)]
    [string]$PipelineMode,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolIdentity,

    [Parameter(Mandatory = $true)]
    [string]$Hostname,

    [Parameter(Mandatory = $true)]
    [string]$Protocol,

    [Parameter(Mandatory = $true)]
    [string]$IPAddress,

    [Parameter(Mandatory = $false)]
    [string]$CertificateName
)

$ErrorActionPreference = "Stop"

Import-Module WebAdministration

Write-Host ""
Write-Host "============================================================"
Write-Host "        INICIANDO PROVISIONAMENTO IIS V2"
Write-Host "============================================================"

Write-Host ""
Write-Host "[PARAMETROS]"
Write-Host "Site Name:        $SiteName"
Write-Host "App Pool Name:    $AppPoolName"
Write-Host "Physical Path:    $PhysicalPath"
Write-Host ".NET Version:     $DotNetVersion"
Write-Host "Pipeline Mode:    $PipelineMode"
Write-Host "App Pool Identity:$AppPoolIdentity"
Write-Host "Hostname:         $Hostname"
Write-Host "Protocol:         $Protocol"
Write-Host "IP Address:       $IPAddress"
Write-Host "Certificate:      $CertificateName"

Write-Host ""
Write-Host "[1/5] Verificando diretorio fisico..."

if (!(Test-Path $PhysicalPath)) {

    Write-Host "Diretorio nao existe. Criando..."

    New-Item `
        -Path $PhysicalPath `
        -ItemType Directory `
        -Force | Out-Null

    Write-Host "[OK] Diretorio criado."

}
else {

    Write-Host "[OK] Diretorio ja existe."

}


Write-Host ""
Write-Host "[2/5] Configurando Application Pool..."

$appPoolPath = "IIS:\AppPools\$AppPoolName"

if (!(Test-Path $appPoolPath)) {

    Write-Host "Application Pool nao existe. Criando..."

    New-WebAppPool `
        -Name $AppPoolName | Out-Null

    Write-Host "[OK] Application Pool criado."

}
else {

    Write-Host "[OK] Application Pool ja existe. Reutilizando."

}


Set-ItemProperty `
    -Path $appPoolPath `
    -Name managedRuntimeVersion `
    -Value $DotNetVersion


Set-ItemProperty `
    -Path $appPoolPath `
    -Name managedPipelineMode `
    -Value $PipelineMode


Write-Host "[OK] .NET CLR configurado: $DotNetVersion"
Write-Host "[OK] Pipeline configurado: $PipelineMode"


Write-Host ""
Write-Host "[3/5] Configurando identidade do Application Pool..."

if ($AppPoolIdentity -eq "ApplicationPoolIdentity") {

    Set-ItemProperty `
        -Path $appPoolPath `
        -Name processModel.identityType `
        -Value "ApplicationPoolIdentity"

    Write-Host "[OK] Identidade configurada: ApplicationPoolIdentity"

}
elseif ($AppPoolIdentity -eq "REMAZAWEB\WebTrusted") {

    Write-Host "[AVISO] Identidade REMAZAWEB\WebTrusted selecionada."

    Set-ItemProperty `
        -Path $appPoolPath `
        -Name processModel.identityType `
        -Value "SpecificUser"

    Write-Host "[AVISO] Usuario especifico precisa estar configurado no servidor."

}
else {

    Write-Host "[AVISO] Identidade nao reconhecida: $AppPoolIdentity"

}


Write-Host ""
Write-Host "[4/5] Configurando Site IIS..."

$siteExists = Get-Website `
    -Name $SiteName `
    -ErrorAction SilentlyContinue


if (!$siteExists) {

    Write-Host "Site nao existe. Criando..."

    New-Website `
        -Name $SiteName `
        -PhysicalPath $PhysicalPath `
        -ApplicationPool $AppPoolName `
        -Port 80 `
        -IPAddress $IPAddress `
        -HostHeader $Hostname | Out-Null

    Write-Host "[OK] Site criado."

}
else {

    Write-Host "[OK] Site ja existe. Reutilizando."

    Set-ItemProperty `
        -Path "IIS:\Sites\$SiteName" `
        -Name physicalPath `
        -Value $PhysicalPath

    Set-ItemProperty `
        -Path "IIS:\Sites\$SiteName" `
        -Name applicationPool `
        -Value $AppPoolName

}


Write-Host ""
Write-Host "[5/5] Configurando Bindings..."


$httpBinding = "$IPAddress`:80:$Hostname"

$existingHttpBinding = Get-WebBinding `
    -Name $SiteName `
    -Protocol "http" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.bindingInformation -eq $httpBinding
    }


if (
    ($Protocol -eq "HTTP") -or
    ($Protocol -eq "HTTP + HTTPS")
) {

    if ($existingHttpBinding) {

        Write-Host "[OK] Binding HTTP ja existe. Mantendo."
        Write-Host "HTTP: $httpBinding"

    }
    else {

        Write-Host "Criando Binding HTTP..."

        New-WebBinding `
            -Name $SiteName `
            -Protocol "http" `
            -IPAddress $IPAddress `
            -Port 80 `
            -HostHeader $Hostname

        Write-Host "[OK] Binding HTTP criado."
    }

}


if (
    ($Protocol -eq "HTTPS") -or
    ($Protocol -eq "HTTP + HTTPS")
) {

    Write-Host ""
    Write-Host "Configuracao HTTPS selecionada."

    if ([string]::IsNullOrWhiteSpace($CertificateName)) {

        Write-Host "[AVISO] Nenhum certificado informado."
        Write-Host "[AVISO] HTTPS nao sera configurado automaticamente."

    }
    else {

        Write-Host "[AVISO] Certificado solicitado: $CertificateName"
        Write-Host "[AVISO] Configuracao automatica do certificado sera implementada posteriormente."

    }

}


Write-Host ""
Write-Host "============================================================"
Write-Host "      PROVISIONAMENTO IIS V2 CONCLUIDO COM SUCESSO"
Write-Host "============================================================"

Write-Host ""
Write-Host "Site: $SiteName"
Write-Host "App Pool: $AppPoolName"
Write-Host "Hostname: $Hostname"
Write-Host "Caminho: $PhysicalPath"