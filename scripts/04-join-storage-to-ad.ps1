[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "",

    [Parameter(Mandatory = $false)]
    [string]$OUName = "StorageAccounts"
)

$ErrorActionPreference = "Stop"

# Comprobar que corre en un domain controller
$adService = Get-Service -Name "NTDS" -ErrorAction SilentlyContinue
if (-not $adService -or $adService.Status -ne "Running") {
    Write-Error "Este script debe ejecutarse dentro de un Domain Controller."
    exit 1
}

$domain = Get-ADDomain

if ($SubscriptionId -eq "") {
    $SubscriptionId = (az account show --query 'id' -o tsv)
}

# Crear OU si no existe
$ouPath = "OU=$OUName,$($domain.DistinguishedName)"
try {
    Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction Stop | Out-Null
}
catch {
    New-ADOrganizationalUnit -Name $OUName -Path $domain.DistinguishedName -ProtectedFromAccidentalDeletion $true
}

# Descargar AzFilesHybrid para registrar la cuenta de almacenamiento en AD
$azFilesHybridPath = "$env:TEMP\AzFilesHybrid"
if (-not (Test-Path $azFilesHybridPath)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zipPath = "$env:TEMP\AzFilesHybrid.zip"
    Invoke-WebRequest -Uri "https://github.com/Azure-Samples/azure-files-samples/releases/latest/download/AzFilesHybrid.zip" -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $azFilesHybridPath -Force
    Remove-Item $zipPath
}

Set-Location $azFilesHybridPath
.\CopyToPSPath.ps1
Import-Module -Name AzFilesHybrid -Force

Connect-AzAccount
Select-AzSubscription -SubscriptionId $SubscriptionId

Join-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -DomainAccountType "ComputerAccount" `
    -OrganizationalUnitDistinguishedName $ouPath `
    -OverwriteExistingADObject

$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$adProperties = $storageAccount.AzureFilesIdentityBasedAuth

if ($adProperties.DirectoryServiceOptions -eq "AD") {
    Write-Host "Storage account '$StorageAccountName' unido a $($adProperties.ActiveDirectoryProperties.DomainName)"
} else {
    Write-Warning "Estado inesperado: $($adProperties.DirectoryServiceOptions)"
}

