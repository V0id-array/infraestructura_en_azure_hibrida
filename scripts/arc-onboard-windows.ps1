[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$Location = "westeurope",

    [Parameter(Mandatory = $false)]
    [string]$TenantId = ""
)

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Requiere permisos de administrador local."
    exit 1
}

# Comprobar si el agente ya corre
$agentService = Get-Service -Name "himds" -ErrorAction SilentlyContinue
if ($agentService -and $agentService.Status -eq "Running") {
    Write-Host "Agente Arc ya instalado."
    exit 0
}

$agentInstallerPath = "$env:TEMP\AzureConnectedMachineAgent.msi"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" -OutFile $agentInstallerPath -UseBasicParsing

$installArgs = "/i `"$agentInstallerPath`" /l*v `"$env:TEMP\AzureConnectedMachineAgent_install.log`" /qn"
$process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru

if ($process.ExitCode -ne 0) {
    Write-Error "Instalacion fallida con codigo $($process.ExitCode). Ver log en $env:TEMP\AzureConnectedMachineAgent_install.log"
    exit 1
}

$connectArgs = @(
    "connect"
    "--resource-group", $ResourceGroup
    "--subscription-id", $SubscriptionId
    "--location", $Location
    "--tags", "Entorno=prod", "GestionadoPor=AzureArc"
)

if ($TenantId -ne "") {
    $connectArgs += "--tenant-id"
    $connectArgs += $TenantId
}

$azcmagentPath = "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe"
& $azcmagentPath @connectArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Fallo en la conexion a Azure Arc."
    exit 1
}

Write-Host "Servidor $env:COMPUTERNAME conectado a Azure Arc en $ResourceGroup"
Remove-Item $agentInstallerPath -Force -ErrorAction SilentlyContinue

